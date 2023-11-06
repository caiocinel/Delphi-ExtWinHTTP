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
  public
    constructor Create;
    property URL: String read _url write _url;
    property Method: String read _method write _method;
    property ContentType: String read _contenttype write _contenttype;
    property QueryParams: TQueryString read _queryparams;
    property Headers: THeaders read _headers;
    property Body: String read _body write _body;

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
    property AsText: string read _body;
    property AsObject: ISuperObject read _getBodyAsObject;
    property IsSuccessStatusCode: boolean read _getSuccessStatusCode;
  end;


type
  THttpRequest = class(TRequest)
  private
    _client: OleVariant;
    _response: TResponse;
  public
    constructor Create;
    function Execute: TResponse;
    property Response: TResponse read _response write _response;
  end;
implementation

uses
  Classes, ComObj, ActiveX, StrUtils, SysUtils;

constructor THttpRequest.Create;
begin
  inherited;
  CoInitialize(nil); 

  _client := CreateOleObject('WinHttp.WinHttpRequest.5.1');
end;

function THttpRequest.Execute: TResponse;
var
  I: integer;
begin
  if(Self.Method = '') then
    Self.Method := 'GET';

  _client.Open(Self.Method, Self.URL + Self.QueryParams.AsString, False);

  for I := 0 to Self.Headers.Count - 1 do
    _client.SetRequestHeader(Self.Headers.Keys[I], Self.Headers.Values[I]);

  if(Self.ContentType <> '') then
    _client.SetRequestHeader('Content-Type', Self.ContentType);

  _client.Send(Self.Body);

  _response := TResponse.Create(_client);

  Result := _response;
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
  _contenttype := Copy(pObj.Getresponseheader('Content-Type'), 1, Pos(';',pObj.Getresponseheader('Content-Type'))-1);

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

  SetLength(_keys, Length(self._keys));
  SetLength(_values, Length(self._values));

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
    Result := _keys[I]+'='+_values[I] + '&';
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

end.
