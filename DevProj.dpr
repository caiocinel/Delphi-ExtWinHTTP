program DevProj;

{$APPTYPE CONSOLE}

uses
  SysUtils,
  HttpRequest in 'ExtWinHTTP\HttpRequest.pas', Classes;

var
  Client: THttpRequest;
  Response: TResponse;
begin
  Client := THttpRequest.Create;
  Client.URL := 'http://localhost:3000/api/others/testMultiPartFormData';
  
  Client.Method := 'POST';
  Client.AddFile('request', 'C:\Users\caioc\Desktop\TestFile.txt', 'text/plain');
  Client.AddField('teste', 'valor');
  Response := Client.Execute;

  WriteLn(Client.Response.Status);
  WriteLn('EOF');
  Sleep(30000);
  
end.
