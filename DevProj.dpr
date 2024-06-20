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

  Request := THttpRequest.Create;
  try
    Request.URL := 'https://archive.org/download/windows-xp-bliss-4k-lu-3840x2400/windows-xp-bliss-4k-lu-3840x2400.jpg';
    Request.Execute;
    Request.Response.SaveToFile('nomeimage.jpg');
    Request.Destroy;

  except on E:Exception do
    WriteLn(E.Message);
  end;

  WriteLn('Fim');
end.
