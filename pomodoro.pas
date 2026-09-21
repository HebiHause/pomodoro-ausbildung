program Pomodoro;
{$mode objfpc}{$H+}

uses crt, fphttpapp, httpdefs, httproute, {server}
Classes, SysUtils, procedures, {more detaild for language}
fpjson, {json}
fphttpclient, opensslsockets, {api}
ShellAPI; {for automatic open}

var
    DateStr: string; {current date in graphic.json (2026-09-16)}

begin 

    InitProcedures; {initialize to do list }
    GraphicJson := TJSONObject.Create;

    begin {Load existing graphic from json for previos users activity}
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
            GraphicJson := TJSONObject.Create; {if there nothing then create a new one}
        end;

    {=====================================HTTP for Site=========================================}
    ServerThread := TServerThread.Create(false); {start server in background}
    ShellExecute(0, 'open', 'http://localhost:8080', nil, nil, 1); {auto-open the site }

    HTTPRouter.RegisterRoute('/', @MainPage, true); 
    HTTPRouter.RegisterRoute('/style.css', @StylePage); 
    HTTPRouter.RegisterRoute('/timer-status', @TimerStatus);
    

    HTTPRouter.RegisterRoute('/set-pomodoro', @SetPomodoroAction);
    HTTPRouter.RegisterRoute('/set-short-pause', @SetShortPauseAction);
    HTTPRouter.RegisterRoute('/set-long-pause', @SetLongPauseAction);
    HTTPRouter.RegisterRoute('/start-pause', @StartPauseAction);
    HTTPRouter.RegisterRoute('/reset', @ResetAction);    
    HTTPRouter.RegisterRoute('/skip', @Skip); 

    HTTPRouter.RegisterRoute('/mode-status', @ModeStatus); {current mode for Pomodoro such a shor/long pause or work time}
    HTTPRouter.RegisterRoute('/session-request', @SessionRequested);
    HTTPRouter.RegisterRoute('/progress-conic-gradient', @conic); {visualisation of the timer in %}

    HTTPRouter.RegisterRoute('/tasks', @TaskJSON);
    HTTPRouter.RegisterRoute('/add-task', @AddTaskAction);
    HTTPRouter.RegisterRoute('/task-done', @TaskDoneAction);
    HTTPRouter.RegisterRoute('/delete-task', @DeleteTaskAction);

    HTTPRouter.RegisterRoute('/graphic', @GraphicData); 
    {=====================================HTTP for Site=========================================}

    {initial for timer. Is paused until user will press button Start}
    CurrentMode := 0;
    SessionCount := 0;
    TimeInSec := 25 * 60;
    OriginalTimeInSec := TimeInSec;
    IsPaused := true;   

    {main loop for timer: ticking per second}
    repeat

    Delay(1000);

    if not isPaused then
        begin
            TimeInSec := TimeInSec - 1; 
            Minutes := TimeInSec div 60;  
            Seconds := TimeInSec mod 60; 
            if Seconds < 10 then {how to display timer}
                WriteLn('Learning time left: ', Minutes:0:0, ' minutes and 0', Seconds:0:0, ' seconds')
            else
                WriteLn('Learning time left: ', Minutes:0:0, ' minutes and ', Seconds:0:0, ' seconds');
        end;      

        if SkipRequested then {web button, times go straight to the 0 sec}
        begin
            TimeInSec := 0;
            SkipRequested := false;      
        end;

        if ResetRequested then {web button, times restore original duration}
        begin
            TimeInSec := OriginalTimeInSec;
            ResetRequested := false;
        end;

    If TimeInSec <= 0 then 
        begin
            case currentMode of {which mode should be next: After 3 Pomodoro and Short Pause circle, there should be Long Pause}
            0: begin  
                    DateStr := FormatDateTime('yyyy-mm-dd', Now); 

                    if  GraphicJson.Find(DateStr) = nil then {Log completed session under today's date in graphic.json}
                        GraphicJson.Add(DateStr, 1)
                    else
                        GraphicJson.Integers[DateStr] := GraphicJson.Integers[DateStr] + 1;
                    
                    {write information on the disk}
                        StringList := TStringList.Create;
                    try
                        StringList.Text := GraphicJson.FormatJSON();
                        StringList.SaveToFile('graphic.json');
                    finally
                        StringList.Free;
                    end;


                    SessionCount := SessionCount + 1; {session counts}

                    OriginalTimeInSec := 25; {starting 25 min Pomodoro session }
                        if SessionCount mod 3 = 0 then
                                begin
                                    currentMode := 2; {switch to Long Pause}
                                    OriginalTimeInSec := 15 * 60;
                                    TimeInSec := OriginalTimeInSec;
                                end
                            else
                                begin
                                    currentMode := 1;
                                    OriginalTimeInSec := 5 * 60;  {switch to Short Pause}
                                    TimeInSec := OriginalTimeInSec;
                                end;
                end;

            1:  begin
                currentMode := 0; {after short pause we start pomodoro}
                OriginalTimeInSec := 25 * 60;
                TimeInSec := OriginalTimeInSec;
                end;

            2:  begin
                    CurrentMode := 0; {after long pause starting Pomodoro}
                    OriginalTimeInSec := 25 * 60;
                    TimeInSec := OriginalTimeInSec;
                end;

        end;
        end;

until false;

ReadLn;
end.