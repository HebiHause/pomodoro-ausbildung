program Pomodoro;
{$mode objfpc}{$H+}

uses crt, fphttpapp, httpdefs, httproute, {server}
Classes, SysUtils, procedures, {more detaild for language}
fpjson, {json}
fphttpclient, opensslsockets; {api}

var
    DateStr: string;

begin 

    InitProcedures;
    GraphicJson := TJSONObject.Create;

    begin
        if FileExists('graphic.json') then
            begin
                StringList := TStringList.Create;
                    try
                        StringList.LoadFromFile('graphic.json');
                        GraphicJson := TJSONObject(GetJSON(StringList.Text));
                    finally
                        StringList.Free;
                end;
            end
        else
            GraphicJson := TJSONObject.Create; // Якщо файлу ще немає
        end;

    {=====================================Sever stuff=========================================}
    ServerThread := TServerThread.Create(false); {...}

    HTTPRouter.RegisterRoute('/', @MainPage, true); {...}
    HTTPRouter.RegisterRoute('/style.css', @StylePage); {...}
    HTTPRouter.RegisterRoute('/timer-status', @TimerStatus);
    
    HTTPRouter.RegisterRoute('/start-pause', @StartPauseAction);
    HTTPRouter.RegisterRoute('/reset', @ResetAction);    
    HTTPRouter.RegisterRoute('/skip', @Skip); {і це також бєєє}

    HTTPRouter.RegisterRoute('/mode-status', @ModeStatus); {mode pause or pomodoro rn}
    HTTPRouter.RegisterRoute('/session-request', @SessionRequested);
    HTTPRouter.RegisterRoute('/progress-conic-gradient', @conic);

    HTTPRouter.RegisterRoute('/tasks', @TaskJSON);
    HTTPRouter.RegisterRoute('/add-task', @AddTaskAction);
    HTTPRouter.RegisterRoute('/task-done', @TaskDoneAction);
    HTTPRouter.RegisterRoute('/delete-task', @DeleteTaskAction);

    HTTPRouter.RegisterRoute('/graphic', @GraphicData); {graphic for siiiiiiiiiite fnlly}
    
    {=====================================Sever stuff=========================================}

    CurrentMode := 0;
    SessionCount := 0;
    TimeInSec := 25 * 60;
    OriginalTimeInSec := TimeInSec;
    IsPaused := true;   

    repeat

    Delay(1000);

    if not isPaused then
        begin
            TimeInSec := TimeInSec - 1;
            Minutes := TimeInSec div 60;  
            Seconds := TimeInSec mod 60;
            if Seconds < 10 then
                WriteLn('Learning time left: ', Minutes:0:0, ' minutes and 0', Seconds:0:0, ' seconds')
            else
                WriteLn('Learning time left: ', Minutes:0:0, ' minutes and ', Seconds:0:0, ' seconds');
        end;      

        if SkipRequested then            
        begin
            TimeInSec := 0;
            SkipRequested := false;      
        end;

        if ResetRequested then          
        begin
            TimeInSec := OriginalTimeInSec;
            ResetRequested := false;
        end;

    If TimeInSec <= 0 then
        begin
            case currentMode of
            0: begin  
                    DateStr := FormatDateTime('yyyy-mm-dd', Now); 

                    if  GraphicJson.Find(DateStr) = nil then {creating when and how to write to json file}
                        GraphicJson.Add(DateStr, 1)
                    else
                        GraphicJson.Integers[DateStr] := GraphicJson.Integers[DateStr] + 1;

                    {================then write it to json file==============================}
                    
                        StringList := TStringList.Create;
                    try
                        StringList.Text := GraphicJson.FormatJSON();
                        StringList.SaveToFile('graphic.json');
                    finally
                        StringList.Free;
                    end;


                    SessionCount := SessionCount + 1; {session counts}

                    OriginalTimeInSec := 25;
                        if SessionCount mod 3 = 0 then
                                begin
                                    currentMode := 2; {for long pause}
                                    OriginalTimeInSec := 15 * 60;
                                    TimeInSec := OriginalTimeInSec;
                                end
                            else
                                begin
                                    currentMode := 1;
                                    OriginalTimeInSec := 5 * 60;  {after pomodoro we start short pause}
                                    TimeInSec := OriginalTimeInSec;
                                end;
                end;

            1:  begin
                currentMode := 0; {after short pause we start pomodoro}
                OriginalTimeInSec := 25 * 60;
                TimeInSec := OriginalTimeInSec;
                end;

            2:  begin
                    CurrentMode := 0;
                    OriginalTimeInSec := 25 * 60;
                    TimeInSec := OriginalTimeInSec;
                end;

        end;
        end;

until false;

{ 

repeat
    WriteLn('===================================');
    WriteLn('================list===============');
    WriteLn('===================================');

    WriteLn('Please choose a number: ');
    WriteLn('1. Create Task');
    WriteLn('2. Show the list');
    WriteLn('3. Make a task done');
    WriteLn('4. Delete Task');
    WriteLn('5. Exit');
    WriteLn;

    ReadLn(btn);

   case btn of
        1: begin 
            WriteLn('Please enter name for task');
            ReadLn(textVar);
            CreateTask(textVar);
        end;
        2: begin 
            ShowTask;
        end;
        3: begin 
            WriteLn('Which task did you complete?'); 
            ReadLn(completeBtn);
            taskDone(completeBtn);
        end;
        4: begin 
            WriteLn('Which task do you want to delete?'); 
            ReadLn(deleteVar);
            DeleteTask(deleteVar);
        end;
        5: begin 
        WriteLn('BYEEEEEEEEEEEEEEEEEEEE!');
        end;

        else
        WriteLn('You missed it by a bit, huh?');
    end;
    
    WriteLn;
until btn = 5;}

ReadLn;
end.