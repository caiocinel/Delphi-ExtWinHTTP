unit HttpRequest;

interface

uses
  Classes, SysUtils, StrUtils, Variants, ComObj, SuperObject;

type
  THttpRequest = class
  private
    {None}
  public
    function ToDo: integer;
  end;



type
  TRequest = class
  private
    URL: string;
    Method: string;
    ContentType: string;
    QueryParams: TURLParams;

  public
    function ToDo: integer;
  end;

implementation

function THttpRequest.ToDo: integer;
begin
  Result := 0;
end;

end.
