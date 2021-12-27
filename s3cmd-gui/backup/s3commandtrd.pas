unit S3CommandTRD;

{$mode objfpc}{$H+}

interface

uses
  Classes, Process, SysUtils, ComCtrls;

type
  StartS3Command = class(TThread)
  private

    { Private declarations }
  protected
  var
    Log: TStringList;

    procedure Execute; override;

    procedure ShowLog;
    procedure StartProgress;
    procedure StopProgress;

  end;

implementation

uses Unit1;

{ TRD }

procedure StartS3Command.Execute;
var
  ExProcess: TProcess;
begin
  try //Вывод лога и прогресса
    Synchronize(@StartProgress);

    FreeOnTerminate := True; //Уничтожить по завершении
    Log := TStringList.Create;

    //Рабочий процесс
    ExProcess := TProcess.Create(nil);

    ExProcess.Executable := 'bash';
    ExProcess.Parameters.Add('-c');
    ExProcess.Parameters.Add(cmd);

    ExProcess.Options := [poUsePipes, poStderrToOutPut];
    //, poWaitOnExit (синхронный вывод)

    ExProcess.Execute;

    //Выводим лог динамически
    while ExProcess.Running do
    begin
      Log.LoadFromStream(ExProcess.Output);

      //Выводим лог
      Log.Text := Trim(Log.Text);

      //  sleep(100);
      if Log.Count <> 0 then
        Synchronize(@ShowLog);
    end;

  finally
    Synchronize(@StopProgress);
    Log.Free;
    ExProcess.Free;
    Terminate;
  end;
end;

{ БЛОК ОТОБРАЖЕНИЯ ЛОГА }

//Старт индикатора
procedure StartS3Command.StartProgress;
begin
  with MainForm do
  begin
    SDMemo.Clear;
    //Метка отмены копирования
    Panel4.Caption := SCancelCopyng;
    ProgressBar1.Style := pbstMarquee;
    ProgressBar1.Refresh;
    //Запрещаем параллельное копирование
    CopyFromPC.Enabled := False;
    CopyFromBucket.Enabled := False;
    DelBtn.Enabled := False;
  end;
end;

//Стоп индикатора
procedure StartS3Command.StopProgress;
begin
  with MainForm do
  begin
    //Метка отмены копирования
    Panel4.Caption := '';
    //   ProgressBar1.Visible := False;
    ProgressBar1.Style := pbstNormal;
    ProgressBar1.Refresh;

    //Разрешаем копирование
    CopyFromPC.Enabled := True;
    CopyFromBucket.Enabled := True;
    DelBtn.Enabled := True;

    //Обновление каталогов назначения (выборочно)
    if left_panel then
      CompDirUpdate
    else
      StartLS;
  end;
  //Очищаем команду для корректного "Esc"
  cmd := '';
end;

//Вывод лога
procedure StartS3Command.ShowLog;
var
  i: integer;
begin
  //Вывод построчно
  for i := 0 to Log.Count - 1 do
    MainForm.SDMemo.Lines.Append(Log[i]);

  //Вывод пачками
  //  MainForm.SDMemo.Lines.Assign(Result);
end;

end.
