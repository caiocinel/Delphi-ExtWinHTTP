# ExtWinHTTP - WinHttpRequest to Legacy Delphi

## Requirements

[https://github.com/hgourvest/superobject](SuperObject)


## Usage

```
var 
  Request: THttpRequest;
  Response: TResponse;

Request := THttpRequest.Create;
Request.URL := 'https://jsonplaceholder.typicode.com/todos/1';
Response := Request.Execute;

Response.Text => '{"userId": 1,  "id": 1,  "title": "delectus aut autem",  "completed": false }'
Response.JSON.S['title'] => 'delectus aut autem'
Response.Status => 200
```
