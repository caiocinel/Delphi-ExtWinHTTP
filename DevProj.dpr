program DevProj;

{$APPTYPE CONSOLE}

uses
  SysUtils,
  HttpRequest in 'ExtWinHTTP\HttpRequest.pas';
begin
  Write(HttpRequest.Get('http://localhost:3000/api/others/testMultiPartFormData').JSON.S['campo1']);

  Sleep(90000);                                                                                       
end.
