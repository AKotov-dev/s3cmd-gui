unit FirstConnectTRD;

{$mode objfpc}{$H+}

interface

uses
  Classes, Process, SysUtils, Forms;

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
    S := TStringList.Create;
    FreeOnTerminate := True; //Уничтожить по завершении

    //Рабочий процесс
    ExProcess := TProcess.Create(nil);
    ExProcess.Executable := 'bash';
    ExProcess.Parameters.Add('-c');

    //Выводим ошибки подключения в SDMemo
    ExProcess.Options := [poUsePipes, poStderrToOutPut];
    ExProcess.Parameters.Add('s3cmd ls >/dev/null');
    ExProcess.Execute;

    S.LoadFromStream(ExProcess.Output);
    Synchronize(@UpdateSDMemo);

  finally
    S.Free;
    ExProcess.Free;
    Terminate;
  end;
end;

//Вывод ошибок, если есть
procedure StartFirstConnect.UpdateSDMemo;
begin
  MainForm.SDMemo.Lines.Assign(S);
  MainForm.SDMemo.Refresh;
end;


end.

