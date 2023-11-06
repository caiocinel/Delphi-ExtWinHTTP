program DevProj;

{$APPTYPE CONSOLE}

uses
  SysUtils,
  HttpRequest in 'ExtWinHTTP\HttpRequest.pas';

var
  Client: THttpRequest;
  Response: TResponse;

begin
  Client := THttpRequest.Create;
  Client.URL := 'https://google.com';
  Client.Headers.Add('Accept','text/css');
  Response := Client.Execute;

  WriteLn(Response.Status);
  WriteLn('EOF');
  Sleep(3000000);
end.
