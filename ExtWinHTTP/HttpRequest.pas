unit HttpRequest;

interface

uses
  Classes, SysUtils, StrUtils, Variants, ComObj;

type
  THttpRequest = class
  private
    Client: OleVariant;
    fMethod: string;
    fURL: string;
    fRequestBody: string;
    fHeadersKey: array of string;
    fHeadersValue: array of string;
  public
    property Method: String read fMethod write fMethod;
    property URL: String read fMethod write fMethod;
    property RequestBody: String read fRequestBody write fRequestBody;
    constructor Create;
    destructor Destroy;
    procedure AddHeader(Key: string; Value: string);
    procedure AddCertificate(Path: string);
    procedure SetContentType(ctype: string);
    function Status: integer;
    function ResponseBody: string;
    function ResponseBodyAsJson: ISuperObject;
    function GetHeaderValue(Key: string): string;
    function Send(pMethod: string = ''; pURL: string = ''; pBody: string = ''): Boolean;
  end;

implementation

uses
  superobject;

function THttpRequest.Send(pMethod: string = ''; pURL: string = ''; pBody: string = ''): Boolean;
var
  I: integer;
begin

  if(pMethod = '') then
    pMethod := fMethod;

  if(pURL = '') then
    pURL := fURL;

  if(pBody = '') then
    pBody := fRequestBody;

  if(Length(pMethod) < 3) then
    Exception.Create('Http Request Invalid Method');

  if(Length(pURL) < 10) then
    Exception.Create('Http Request Invalid URL');


  Self.Client.open(pMethod, pURL, false);

  for I := 0 to Length(fHeadersKey) - 1 do
    Self.Client.setRequestHeader(fHeadersKey[I], fHeadersValue[I]);

  if(pBody <> '') then
    Self.Client.send(pBody)
  else
    Self.Client.Send;

end;

procedure THttpRequest.SetContentType(ctype: string);
begin
  Self.AddHeader('Content-Type', ctype);
end;

function THttpRequest.GetHeaderValue(Key: string): string;
begin
  Result := Self.Client.GetResponseHeader(Key);
end;

function THttpRequest.ResponseBodyAsJson: ISuperObject;
begin
  try
    Result := SO(Self.ResponseBody);
  except
    Result := SO('{}')
  end                             
end;

function THttpRequest.ResponseBody: string;
begin
  Result := Self.Client.ResponseText;
end;

constructor THttpRequest.Create;
begin
  Self.Client := CreateOleObject('WinHttp.WinHttpRequest.5.1');
end;

destructor THttpRequest.Destroy;
begin
  Self.Client := Unassigned;
end;

procedure THttpRequest.AddHeader(Key: string; Value: string);
var
  I: Integer;
begin
  SetLength(Self.fHeadersKey, Length(fHeadersKey) + 1);
  SetLength(Self.fHeadersValue, Length(fHeadersValue) + 1);

  Self.fHeadersKey[I-1] := Key;
  Self.fHeadersValue[I-1] := Value;
end;

procedure THttpRequest.AddCertificate(Path: string);
begin
  Self.Client.SetCredentials(Path);
end;

function THttpRequest.Status: integer;
begin
  Result := Self.Client.Status
end;

end.
