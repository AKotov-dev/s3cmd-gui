unit FirstConnectTRD;

{$mode objfpc}{$H+}

interface

uses
  Classes, Process, SysUtils, Forms, Controls;

type
  StartFirstConnect = class(TThread)
  private

    { Private declarations }
  protected
  var
    S: TStringList;

    procedure Execute; override;

    //Перечитываем текущую директорию SD-Card
    procedure UpdateSDMemo;
    procedure ShowProgress;
    procedure HideProgress;

  end;

implementation


uses unit1;

{ TRD }

//Апдейт текущего каталога SDBox
procedure StartFirstConnect.Execute;
var
  ExProcess: TProcess;
begin
  try
    Synchronize(@ShowProgress);

    S := TStringList.Create;
    FreeOnTerminate := True; //Уничтожить по завершении

    //Рабочий процесс
    ExProcess := TProcess.Create(nil);
    ExProcess.Executable := 'bash';
    ExProcess.Parameters.Add('-c');

    //Выводим ошибки подключения в SDMemo
    ExProcess.Options := [poWaitOnExit, poUsePipes, poStderrToOutPut];
    ExProcess.Parameters.Add('s3cmd ls >/dev/null');
    ExProcess.Execute;

    S.LoadFromStream(ExProcess.Output);
    Synchronize(@UpdateSDMemo);

  finally
    Synchronize(@HideProgress);
    S.Free;
    ExProcess.Free;
    Terminate;
  end;
end;

//Начало операции
procedure StartFirstConnect.ShowProgress;
begin
  Screen.cursor := crHourGlass;
end;

//Окончание операции
procedure StartFirstConnect.HideProgress;
begin
  Screen.cursor := crDefault;
end;

//Вывод ошибок, если есть
procedure StartFirstConnect.UpdateSDMemo;
begin
  MainForm.SDMemo.Lines.Assign(S);
  MainForm.SDMemo.Refresh;
end;


end.

