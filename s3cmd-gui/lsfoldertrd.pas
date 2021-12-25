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
    ExProcess.Options := [poWaitOnExit, poUsePipes];  //poWaitOnExit,
    //ls текущего каталога с заменой спецсимволов
    if MainForm.GroupBox2.Caption = 's3://' then
      ExProcess.Parameters.Add('s3cmd ls | cut -d " " -f4')
    else
      ExProcess.Parameters.Add('s3cmd ls ' + MainForm.GroupBox2.Caption +
        ' | cut -b' + IntToStr(Length(MainForm.GroupBox2.Caption) + 32) +
        '- | grep -v "^$"');

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
  Screen.cursor := crDefault;
end;

{ БЛОК ВЫВОДА LS в SDBox }
procedure StartLSFolder.UpdateSDBox;
begin
  with MainForm do
  begin
    //Вывод обновленного списка
    SDBox.Items.Assign(S);
    //Апдейт содержимого
    SDBox.Refresh;

    //Фокусируем
    SDBox.SetFocus;

    //Если список не пуст - курсор в "0"
    if SDBox.Count <> 0 then
      SDBox.ItemIndex := 0;

    //Если в корне - мультиселект отключен (можно выделить только 1 бакет)
    if GroupBox2.Caption = 's3://' then
      SDBox.MultiSelect := False
    else
      SDBox.MultiSelect := True;
  end;
end;

end.
