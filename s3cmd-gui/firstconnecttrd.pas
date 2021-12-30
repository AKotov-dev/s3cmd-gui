unit FirstConnectTRD;

{$mode objfpc}{$H+}

interface

uses
  Classes, Process, SysUtils;

type
  StartFirstConnect = class(TThread)
  private

    { Private declarations }
  protected
  var
    S: TStringList;

    procedure Execute; override;

    //Выводим лог
    procedure UpdateLogMemo;

  end;

implementation


uses unit1;

{ TRD }

//Пробный s3cmd ls
procedure StartFirstConnect.Execute;
var
  ExProcess: TProcess;
begin
  try
    S := TStringList.Create;
    FreeOnTerminate := True; //Уничтожить по завершении

    //Рабочий процесс
    ExProcess := TProcess.Create(nil);
    ExProcess.Executable := 'bash';
    ExProcess.Parameters.Add('-c');

    //Выводим ошибки подключения в LogMemo
    ExProcess.Options := [poWaitOnExit, poUsePipes, poStderrToOutPut];
    ExProcess.Parameters.Add('s3cmd ls >/dev/null');
    ExProcess.Execute;

    S.LoadFromStream(ExProcess.Output);
    Synchronize(@UpdateLogMemo);

  finally
    S.Free;
    ExProcess.Free;
    Terminate;
  end;
end;

//Вывод ошибок, если есть
procedure StartFirstConnect.UpdateLogMemo;
begin
  MainForm.LogMemo.Lines.Assign(S);
  MainForm.LogMemo.Refresh;

  //Если в выводе нет 'error' - прочитать и вывести корень 's3://'
  if Pos('error', LowerCase(S.Text)) <> 0 then
    MainForm.SDBox.Clear
  else
    MainForm.ReadS3Root;
end;


end.

