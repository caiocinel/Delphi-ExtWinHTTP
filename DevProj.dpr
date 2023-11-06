program DevProj;

{$APPTYPE CONSOLE}

uses
  SysUtils,
  HttpRequest in 'ExtWinHTTP\HttpRequest.pas', Classes;

var
  Client: THttpRequest;
  Response: TResponse;
  StringStream: TStringStream;
  FileStream : TFileStream;
  Body: String;
  FileBuffer: String;
  Boundary: Extended;

begin
  Client := THttpRequest.Create;
  Client.URL := 'http://localhost:3000/api/others/testMultiPartFormData';


  StringStream := TStringStream.Create('');
  FileStream := TFileStream.Create('C:\Users\caioc\Desktop\a.png', fmOpenRead);
  StringStream.CopyFrom(FileStream, FileStream.Size);

  FileStream.Seek(0, soBeginning);
  StringStream.CopyFrom(FileStream, 0);

  Boundary := Now;


  Body := '----------------------------'+FormatDateTime('mmddyyhhnnsszzzzzzzzzzzz', Boundary)+#13#10+
  'Content-Disposition: form-data; name="request"; filename="'+ExtractFileName(FileStream.FileName)+'"'+#13#10+
  'Content-Type: image/png'+#13#10#13#10+
  StringStream.DataString+#13#10+
  '----------------------------'+FormatDateTime('mmddyyhhnnsszzzzzzzzzzzz', Boundary)+'--'+#13#10;

  Client.ContentType := 'multipart/form-data; boundary=--------------------------'+FormatDateTime('mmddyyhhnnsszzzzzzzzzzzz', Now);
  Client.Body := Body;
  Client.Method := 'POST';
  Client.Headers.Add('Content-Length', IntToStr(Length(Client.Body)));

  Writeln(StringStream.DataString);

  Response := Client.Execute;

  WriteLn(Client.Response.Status);
  WriteLn('EOF');
  Sleep(30000);
  
end.
