program DevProj;

{$APPTYPE CONSOLE}

uses
  SysUtils,
  HttpRequest in 'ExtWinHTTP\HttpRequest.pas';

var
  Headers: THeaders;
  Query: TQueryString;
  Request: THttpRequest;
  Response: TResponse;
begin
  Sleep(30000);
end.
