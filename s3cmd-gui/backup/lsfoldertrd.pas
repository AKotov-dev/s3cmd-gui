unit LSFolderTRD;

{$mode objfpc}{$H+}

interface

uses
  Classes, Process, SysUtils, Forms, Controls;

type
  StartLSFolder = class(TThread)
  private

    { Private declarations }
  protected
  var
    S: TStringList;

    procedure Execute; override;

    //Перечитываем текущую директорию SD-Card
    procedure UpdateSDBox;
    procedure ShowProgress;
    procedure HideProgress;

  end;

var
  android7: boolean;

implementation


uses unit1;

{ TRD }

//Апдейт текущего каталога SDBox
procedure StartLSFolder.Execute;
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
    //Ошибки не выводим, только список, ждём окончания потока
    ExProcess.Options := [poWaitOnExit, poUsePipes];

    //ls текущего каталога с заменой спецсимволов
    if MainForm.GroupBox2.Caption = 's3://' then
      ExProcess.Parameters.Add('s3cmd ls | cut -d " " -f4') else
      ExProcess.Parameters.Add('s3cmd ls ' + MainForm.GroupBox2.Caption + ' | cut -b' +
        IntToStr(Length(MainForm.GroupBox2.Caption) + 32) + '- | grep -v "^$"');

    ExProcess.Execute;
    S.LoadFromStream(ExProcess.Output);
    Synchronize(@UpdateSDBox);

  finally
    Synchronize(@HideProgress);
    S.Free;
    ExProcess.Free;
    Terminate;
  end;
end;

//Начало операции
procedure StartLSFolder.ShowProgress;
begin
  Screen.cursor := crHourGlass;
end;

//Окончание операции
procedure StartLSFolder.HideProgress;
begin
  //Очищаем команду для корректного "Esc"
  lscmd := '';
  Screen.cursor := crDefault;
end;

{ БЛОК ВЫВОДА LS в SDBox }
procedure StartLSFolder.UpdateSDBox;
begin
  //Вывод обновленного списка
  MainForm.SDBox.Items.Assign(S);
  //Апдейт содержимого
  MainForm.SDBox.Refresh;

  //Фокусируем
  MainForm.SDBox.SetFocus;

  //Если список не пуст - курсор в "0"
  if MainForm.SDBox.Count <> 0 then
    MainForm.SDBox.ItemIndex := 0;

        if MainForm.GroupBox2.Caption = 's3://' then
      MainForm.SDBox.MultiSelect:=False
    else
    MainForm.SDBox.MultiSelect:=True;
end;

end.
