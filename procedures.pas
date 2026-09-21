unit procedures;
{$mode objfpc}{$H+}

interface

uses fphttpapp, httpdefs, httproute, {server}
Classes, 
SysUtils, {more pascal feauters}
fpjson, jsonparser; {json}

type
  TServerThread = class(TThread)
  protected
    procedure Execute; override;
  end;

  Task = record
    id: Integer;
    nameTask: string;
    Done: Boolean;
  end;
  
var
  TimeInSec, OriginalTimeInSec: Integer;
  Minutes, Seconds: Real;
  IsPaused, SkipRequested, ResetRequested: Boolean;
  CurrentMode, SessionCount: Integer;
  ServerThread: TServerThread;
  list: array of Task;
  nextId: Integer;
  GraphicJson: TJSONObject;
  StringList: TStringList;

function ReadFileAsString(const FileName: string): string;
procedure MainPage(aReq: TRequest; aResp: TResponse);
procedure StylePage(aReq: TRequest; aResp: TResponse);
procedure TimerStatus(aReq: TRequest; aResp: TResponse);
procedure StartPauseAction(aReq: TRequest; aResp: TResponse);
procedure Skip(aReq: TRequest; aResp: TResponse);
procedure ResetAction(aReq: TRequest; aResp: TResponse);
procedure ModeStatus(aReq: TRequest; aResp: TResponse);
procedure SessionRequested(aReq: TRequest; aResp: TResponse);
procedure Conic(aReq: TRequest; aResp: TResponse);

procedure CreateTask(newText: string);
procedure ShowTask;
procedure taskDone(taskID: Integer);
procedure DeleteTask(taskID: Integer);
procedure InitProcedures;


procedure AddTaskAction(aReq: Trequest; aResp: TResponse);
procedure TaskJSON(aReq: Trequest; aResp: TResponse);
procedure TaskDoneAction(aReq: TRequest; aResp: TResponse);
procedure DeleteTaskAction(aReq: TRequest; aResp: TResponse);

procedure GraphicData(AReq: TRequest; AResp: TResponse);

{==========================for==timer===========================}
implementation

procedure TServerThread.Execute;
begin
  Application.Port := 8080;
  Application.Initialize;
  Application.Run;
end;

function ReadFileAsString(const FileName: string): string;
var
  FileContent: TStringList;
begin
  FileContent := TStringList.Create;
  try
    FileContent.LoadFromFile(FileName);
    Result := FileContent.Text;
  finally
    FileContent.Free;
  end;
end;

procedure MainPage(aReq: TRequest; aResp: TResponse);
begin
  aResp.ContentType := 'text/html; charset=utf-8';
  aResp.Content := ReadFileAsString('index.html');
end;

procedure StylePage(aReq: TRequest; aResp: TResponse);
begin
  aResp.ContentType := 'text/css';
  aResp.Content := ReadFileAsString('style.css');
end;

procedure TimerStatus(aReq: TRequest; aResp: TResponse);
var
  TimeText: string;
begin
  if Seconds < 10 then
    TimeText := IntToStr(Round(Minutes)) + ':0' + IntToStr(Round(Seconds))
  else
    TimeText := IntToStr(Round(Minutes)) + ':' + IntToStr(Round(Seconds));

  aResp.ContentType := 'text/plain';
  aResp.Content := TimeText;
end;

procedure StartPauseAction(aReq: TRequest; aResp: TResponse);
begin
  IsPaused := not IsPaused;
  aResp.ContentType := 'text/plain';
  aResp.Content := 'ok';
end;

procedure Skip(aReq: TRequest; aResp: TResponse); {сам пишу бєєє}
begin
    SkipRequested := true;
    aResp.ContentType := 'text/plain';
    aResp.Content := '.';
end;

procedure ResetAction(aReq: TRequest; aResp: TResponse);
begin
  ResetRequested := true;
  aResp.ContentType := 'text/plain';
  aResp.Content := 'ok';
end;

procedure ModeStatus(aReq: TRequest; aResp: TResponse);
begin
  aResp.ContentType := 'text/plain';
  aResp.Content := IntToStr(CurrentMode);
end;

procedure SessionRequested(aReq: TRequest; aResp: TResponse);
begin
  aResp.ContentType := 'text/plain';
  aResp.Content := IntToStr(SessionCount);
end;

procedure Conic(aReq: TRequest; aResp: TResponse);
var Percent: Integer;
begin
  Percent := Round((1 -(timeInSec / OriginalTimeInSec)) * 100);
  aResp.ContentType := 'text/plain';
  aResp.Content := IntToStr(Percent);
end;

{==========================for==timer===========================}


{==========================to do list ===========================}


procedure CreateTask(newText: string);
begin
    SetLength(list, Length(list) + 1); {length(array) читає який розмір є зараз}
    list[Length(list) - 1].id := nextId;
    list[Length(list) - 1].nameTask := newText; 
    list[Length(list) - 1].Done := false;

    nextId := nextId + 1;
end;

procedure ShowTask;
var i: Integer;
begin
    WriteLn;
    for i := 0 to Length(list) - 1 do
    begin
        Write(i + 1, '. ');
        WriteLn(list[i].nameTask);
    end;
end;

procedure taskDone(taskID: Integer);
var i: Integer;
begin
for i := 0 to Length(list) - 1 do
    if list[i].id = taskID then
    list[i].Done := true;
end;

procedure DeleteTask(taskID: Integer);
var i, idx: Integer;
begin
  idx := -1;
    for i := 0 to Length(list) - 2 do
        if list[i].id = taskID then
        idx := i;

        if idx = -1 then Exit;

        for i := idx to Length(list) - 2 do
        list[i] := list[i + 1];
    
    SetLength(list, Length(list) - 1);
end;

procedure InitProcedures;
begin
  nextId := 1;
end;

procedure TaskJSON(aReq: TRequest; aResp: TResponse);
  var
    i: Integer;
    arr: TJSONArray;
    obj: TJSONObject;
  begin
    arr := TJSONArray.Create;

    for i := 0 to Length(list) - 1 do
      begin
        obj := TJSONObject.Create;
        obj.Add('id', list[i].id);
        obj.Add('nameTask', list[i].nameTask);
        obj.Add('Done', list[i].Done);

        arr.Add(obj); {i dont need to clean, only in the end}
      end;

      aResp.ContentType := 'application/json';
      aResp.Content := arr.AsJSON;

      arr.Free;
  end;

procedure AddTaskAction(aReq: TRequest; aResp: TResponse);
var
  jsonData: TJSONData;
  taskName: string;
begin
  jsonData := GetJSON(aReq.Content);
  taskName := jsonData.FindPath('nameTask').AsString;

  CreateTask(taskName);

  jsonData.Free;

  aResp.ContentType := 'text/plain';
  aResp.Content := 'k';
end;


procedure TaskDoneAction(aReq: TRequest; aResp: TResponse);
var
  jsonData: TJSONData;
  id: Integer;
begin
  jsonData := GetJSON(aReq.Content);
  id := jsonData.FindPath('id').AsInteger;
  jsonData.Free;

  taskDone(id);

  aResp.ContentType := 'text/plain';
  aResp.Content := 'k';
end;

procedure DeleteTaskAction(aReq: TRequest; aResp: TResponse);
var
  jsonData: TJSONData;
  id: Integer;
begin
  jsonData := GetJSON(aReq.Content);
  id := jsonData.FindPath('id').AsInteger;
  jsonData.Free;

  DeleteTask(id);

  aResp.ContentType := 'text/plain';
  aResp.Content := 'k';
end;

procedure GraphicData(AReq: TRequest; AResp: TResponse);
var
  ResJSON: TJSONArray;
  DayObj: TJSONObject;
  i: Integer;
  TargetDate: TDateTime;
  DateStr: string;
  Count: Integer;
begin
  ResJSON := TJSONArray.Create;
  try
    // Проходимо від 6 днів тому до сьогодні (сьогоденні — 0)
    for i := 6 downto 0 do
    begin
      TargetDate := Now - i;
      DateStr := FormatDateTime('yyyy-mm-dd', TargetDate);
      
      // Перевіряємо, чи є такий день у нашій базі GraphicJson
      if GraphicJson.Find(DateStr) <> nil then
        Count := GraphicJson.Integers[DateStr]
      else
        Count := 0; // Якщо дня не було — ставимо 0
        
      // Створюємо маленький об'єкт для конкретного дня
      DayObj := TJSONObject.Create;
      DayObj.Add('date', DateStr);
      DayObj.Add('sessions', Count);
      ResJSON.Add(DayObj);
    end;
    
    // Відправляємо результат у браузер у форматі JSON
    AResp.ContentType := 'application/json';
    AResp.Content := ResJSON.FormatJSON();
    AResp.SendContent;
  finally
    ResJSON.Free; // Очищаємо тимчасовий масив у пам'яті
  end;
end;

end.
