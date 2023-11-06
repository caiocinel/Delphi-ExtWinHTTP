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
  Client.URL := 'https://api.myip.com/';
  Response := Client.Execute;

  WriteLn(Client.Response.JSON.S['ip']);
  WriteLn('EOF');
  Sleep(3000000);
end.
