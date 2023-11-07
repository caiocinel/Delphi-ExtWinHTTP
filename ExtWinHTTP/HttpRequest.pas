unit HttpRequest;

interface

uses SuperObject;

type
  TQueryString = class
  private
    _keys: array of string;
    _values: array of string;
  public
    procedure Add(pKey: String; pValue: String);
    function AsString: String;
  end;

type
  TFormFile = class
  private
    _field: string;
    _datastring: string;
    _contenttype: string;
  public
    constructor Create(pField, pDataString, pContentType: string);
  end;

type
  TFormField = class
  private
    _field: string;
    _value: string;
  public
    constructor Create(pField, pValue: string);
  end;

type
  THeaders = class
  private
    _keys: array of string;
    _values: array of string;
    _count: integer;
    function _getKey(index: integer): string;
    function _getValue(index: integer): string;
  public
    property Keys[index: integer]: string read _getKey;
    property Values[index: integer]: string read _getValue;
    property Count: integer read _count;
    procedure Add(pKey: String; pValue: String);
    function Get(pKey: String): String;
  end;

type
  TRequest = class
  private
    _url: string;
    _method: string;
    _contenttype: string;
    _queryparams: TQueryString;
    _headers: THeaders;
    _body: string;
    _boundary: string;
    _files: array of TFormFile;
    _fields: array of TFormField;
    _sendOnly: boolean;
    function _getBearer: string;
    procedure _setBearer(const Value: string);
    function _getBodyAsObject: ISuperObject;
    procedure _setBodyAsObject(const Value: ISuperObject);
    procedure _mountMultipartFormData;
    procedure _mountUrlEncodedForm;
    procedure _mountBody;
  public
    constructor Create;
    procedure AddFile(pFieldName, pDir, pContentType: String);
    procedure AddField(pFieldName, pValue: String);
    property URL: String read _url write _url;
    property Method: String read _method write _method;
    property ContentType: String read _contenttype write _contenttype;
    property QueryParams: TQueryString read _queryparams write _queryparams;
    property Headers: THeaders read _headers write _headers;
    property Bearer: string read _getBearer write _setBearer;
    property Body: String read _body write _body;
    property JSON: ISuperObject read _getBodyAsObject write _setBodyAsObject;
    property SendOnly: boolean read _sendOnly write _sendOnly;
  end;

type
  TResponse = class
  private
    _status: integer;
    _body: string;
    _contenttype: string;
    _headers: THeaders;
    function _getSuccessStatusCode: boolean;
    function _getBodyAsObject: ISuperObject;
  public
    constructor Create(pObj: OleVariant);
    property Status: integer read _status;
    property Headers: THeaders read _headers;
    property Body: string read _body;
    property Text: string read _body;
    property AsString: string read _body;
    property JSON: ISuperObject read _getBodyAsObject;
    property O: string read _body;
    property AsObject: string read _body;
    property IsSuccessStatusCode: boolean read _getSuccessStatusCode;
  end;


type
  THttpRequest = class(TRequest)
  private
    _client: OleVariant;
    _response: TResponse;
  public
    constructor Create;
    destructor Destroy; override;
    function Execute: TResponse;
    property Response: TResponse read _response write _response;
  end;

function Get(pURL: string; pQueryParams: TQueryString = nil; pHeaders: THeaders = nil): TResponse;
function Post(pURL: string; pBody: string = ''; pQueryParams: TQueryString = nil; pHeaders: THeaders = nil): TResponse;
function Put(pURL: string; pBody: string = ''; pQueryParams: TQueryString = nil; pHeaders: THeaders = nil): TResponse;
function Delete(pURL: string; pBody: string = ''; pQueryParams: TQueryString = nil; pHeaders: THeaders = nil): TResponse;
  
implementation

uses
  Classes, ComObj, ActiveX, StrUtils, SysUtils, Variants;

constructor THttpRequest.Create;
begin
  inherited;
  CoInitialize(nil); 

  _client := CreateOleObject('WinHttp.WinHttpRequest.5.1');
end;

destructor THttpRequest.Destroy;
begin
  CoUninitialize;
  _client := Unassigned;
  FreeAndNil(Self._response);
  FreeAndNil(Self);
end;

function THttpRequest.Execute: TResponse;
var
  I: integer;
begin
  if(Self.Method = '') then
    Self.Method := 'GET';

  if(Self.Method <> 'GET') then
    Self._mountBody;

  _client.Open(Self.Method, Self.URL + Self.QueryParams.AsString, Self._sendOnly);

  for I := 0 to Self.Headers.Count - 1 do
    _client.SetRequestHeader(Self.Headers.Keys[I], Self.Headers.Values[I]);

  if(Self.ContentType <> '') then
    _client.SetRequestHeader('Content-Type', Self.ContentType);

  _client.Send(Self.Body);

  if(Self._sendOnly) then
  begin
    Self.Destroy;
    Result := nil;
    Exit;
  end;

  _response := TResponse.Create(_client);

  Result := _response;
end;

procedure TRequest.AddField(pFieldName, pValue: String);
begin
  SetLength(_fields, Length(self._fields)+1);
  _fields[Length(self._fields)-1] := TFormField.Create(pFieldName, pValue);
end;

procedure TRequest.AddFile(pFieldName, pDir, pContentType: String);
var
  vStringStream: TStringStream;
  vFileStream: TFileStream;
begin
  try
    vStringStream := TStringStream.Create('');
    vFileStream := TFileStream.Create(pDir, fmOpenRead);
    vFileStream.Seek(0, soBeginning);
    vStringStream.CopyFrom(vFileStream, 0);

    SetLength(_files, Length(self._files)+1);
    _files[Length(self._files)-1] := TFormFile.Create(pFieldName, vStringStream.DataString, pContentType);
  finally
    FreeAndNil(vStringStream);
    FreeAndNil(vFileStream);
  end;
end;

constructor TRequest.Create;
begin
  _queryparams := TQueryString.Create;
  _headers := THeaders.Create;
end;

constructor TResponse.Create(pObj: OleVariant);
var
  vHeaders, vItem: TStringList;
  vHeader: String;
begin
  _headers := THeaders.Create;
  _status := pObj.Status;
  _body := pObj.ResponseText;
  try
    if(Pos('Content-Type',pObj.Getallresponseheaders()) <> 0) then
      _contenttype := Copy(pObj.Getresponseheader('Content-Type'), 1, Pos(';',pObj.Getresponseheader('Content-Type'))-1);
  except
    _contenttype := '';
  end;

  vHeaders := TStringList.Create;
  vHeaders.StrictDelimiter := True;
  vHeaders.Delimiter := #13;
  vHeaders.DelimitedText := pObj.Getallresponseheaders();

  for vHeader in vHeaders do
  begin
    vItem := TStringList.Create;
    vItem.StrictDelimiter := True;
    vItem.Delimiter := ':';
    vItem.DelimitedText := StringReplace(vHeader, #$A, '', [rfReplaceAll]);
    if(vItem.Count < 2) then
      continue;
    _headers.Add(vItem[0], vItem[1]);    
  end;
end;

procedure THeaders.Add(pKey: String; pValue: String);
begin
  if (IndexStr(pKey, self._keys) <> -1) then
  begin
    self._values[IndexStr(pKey, self._keys)] := pValue;
    Exit;
  end;

  SetLength(_keys, Length(self._keys)+1);
  SetLength(_values, Length(self._values)+1);

  _keys[Length(self._keys)-1] := pKey;
  _values[Length(self._values)-1] := pValue;

  _count := Length(_keys);
end;

function THeaders.Get(pKey: String): String;
begin
  if (IndexStr(pKey, self._keys) = -1) then
  begin
    Result := '';
    Exit;
  end;

  Result := _values[IndexStr(pKey, self._keys)];
end;

function THeaders._getKey(index: integer): string;
begin
  try
    Result := _keys[index];
  except
    Result := '';
  end;
end;

function THeaders._getValue(index: integer): string;
begin
  try
    Result := _values[index];
  except
    Result := '';
  end;
end;


procedure TQueryString.Add(pKey: String; pValue: String);
begin
  if (IndexStr(pKey, self._keys) <> -1) then
  begin
    self._values[IndexStr(pKey, self._keys)] := pValue;
    Exit;
  end;

  SetLength(_keys, Length(self._keys)+1);
  SetLength(_values, Length(self._values)+1);

  _keys[Length(self._keys)-1] := pKey;
  _values[Length(self._values)-1] := pValue;
end;

function TQueryString.AsString: String;
var
  I: integer;
begin
  if(Length(_keys) = 0) then
  begin
    Result := '';
    Exit;
  end;    

  Result := '?';

  for I := 0 to Length(_keys) - 1 do
  begin
    Result := Result + _keys[I]+'='+_values[I] + '&';
  end;    

  Result := copy(Result, 1, Length(Result) - 1);
end;

function TResponse._getBodyAsObject: ISuperObject;
begin
  try
    Result := SO(self._body)
  except
    Result := nil;
  end;
end;

function TResponse._getSuccessStatusCode: boolean;
begin
  Result := ((Self._status >= 200) and (Self._status <= 299))
end;

function TRequest._getBearer: string;
begin
  StringReplace(Self.Headers.Get('Authorization'), 'Bearer ', '', [rfReplaceAll]);
end;

function TRequest._getBodyAsObject: ISuperObject;
begin
  try
    Result := SO(Self._body);
  except
    Result := nil;
  end;
end;

procedure TRequest._mountBody;
begin
  if(Pos('multipart/form-data', self._contenttype) <> 0) then
  begin
    Self._mountMultipartFormData;
    Exit;
  end;

  if(Pos('x-www-form-urlencoded', self._contenttype) <> 0) then
  begin
    Self._mountUrlEncodedForm;
    Exit;
  end;

  if(Length(_files) > 0) then
  begin
    Self._mountMultipartFormData;
    Exit;
  end;

  if(Length(_fields) > 0) then
  begin
    Self._mountUrlEncodedForm;
    Exit;
  end;    
end;

procedure TRequest._mountMultipartFormData;
var
  vTemp: String;
  FormFile: TFormFile;
  FormField: TFormField;
begin
  if(Self._boundary = '') then
    Self._boundary := FormatDateTime('mmddyyhhnnsszzz', Now);

  Self._body := '';

  for FormFile in Self._files do
  begin
    vTemp := '----------------------------'+Self._boundary+#13#10+
    'Content-Disposition: form-data; name="'+FormFile._field+'"; filename="'+FormFile._field+'"'+#13#10+
    'Content-Type: '+FormFile._contenttype+''+#13#10#13#10+
    FormFile._datastring+#13#10;
    Self._body := Self._body + vTemp;
  end;

  for FormField in Self._fields do
  begin
    vTemp := '----------------------------'+Self._boundary+#13#10+
    'Content-Disposition: form-data; name="'+FormField._field+'"'+#13#10#13#10+
    FormField._value+#13#10;
    Self._body := Self._body + vTemp;
  end;

  Self._body := Self._body + '----------------------------'+Self._boundary+'--'+#13#10;

  Self._contenttype := 'multipart/form-data; boundary=--------------------------'+Self._boundary+#13#10;
  Self.Headers.Add('Content-Length', IntToStr(Length(Self._body)));
end;

procedure TRequest._mountUrlEncodedForm;
var
  FormField: TFormField;
begin
  Self._body := '';

  for FormField in Self._fields do
    Self._body := FormField._field+'='+FormField._value+'&';

  Self._body := copy(Self._body, 1, Length(Self._body) - 1);
  
  Self._contenttype := 'application/x-www-form-urlencoded';
  Self.Headers.Add('Content-Length', IntToStr(Length(Self._body)));
end;

procedure TRequest._setBearer(const Value: string);
begin
  Self.Headers.Add('Authorization', 'Bearer '+Value);
end;

procedure TRequest._setBodyAsObject(const Value: ISuperObject);
begin
  Self._body := Value.AsString;
  Self._contenttype := 'application/json';
end;

constructor TFormFile.Create(pField, pDataString, pContentType: string);
begin
  Self._field := pField;
  Self._datastring := pDataString;
  Self._contenttype := pContentType;
end;

constructor TFormField.Create(pField, pValue: string);
begin
  Self._field := pField;
  Self._value := pValue;
end;

function Get(pURL: string; pQueryParams: TQueryString = nil; pHeaders: THeaders = nil): TResponse;
var
  Req: THttpRequest;
begin
  Req := THttpRequest.Create;
  Req.URL := pURL;

  if(pQueryParams <> nil) then
    Req.QueryParams := pQueryParams;

  if(pHeaders <> nil) then
    Req.Headers := pHeaders;

  Result := Req.Execute;
end;

function Post(pURL: string; pBody: string = ''; pQueryParams: TQueryString = nil; pHeaders: THeaders = nil): TResponse;
var
  Req: THttpRequest;
begin
  Req := THttpRequest.Create;
  Req.URL := pURL;

  if(pQueryParams <> nil) then
    Req.QueryParams := pQueryParams;

  if(pHeaders <> nil) then
    Req.Headers := pHeaders;

  if(pBody <> '') then
    Req.Body := pBody;

  Req.Method := 'POST';

  Result := Req.Execute;
end;

function Put(pURL: string; pBody: string = ''; pQueryParams: TQueryString = nil; pHeaders: THeaders = nil): TResponse;
var
  Req: THttpRequest;
begin
  Req := THttpRequest.Create;
  Req.URL := pURL;

  if(pQueryParams <> nil) then
    Req.QueryParams := pQueryParams;

  if(pHeaders <> nil) then
    Req.Headers := pHeaders;

  if(pBody <> '') then
    Req.Body := pBody;

  Req.Method := 'PUT';

  Result := Req.Execute;
end;

function Delete(pURL: string; pBody: string = ''; pQueryParams: TQueryString = nil; pHeaders: THeaders = nil): TResponse;
var
  Req: THttpRequest;
begin
  Req := THttpRequest.Create;
  Req.URL := pURL;

  if(pQueryParams <> nil) then
    Req.QueryParams := pQueryParams;

  if(pHeaders <> nil) then
    Req.Headers := pHeaders;

  if(pBody <> '') then
    Req.Body := pBody;

  Req.Method := 'DELETE';

  Result := Req.Execute;
end;


end.
