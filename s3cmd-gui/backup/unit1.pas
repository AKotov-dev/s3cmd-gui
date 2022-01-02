unit Unit1;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ExtCtrls, StdCtrls,
  ShellCtrls, Buttons, ComCtrls, IniPropStorage, Types, Process,
  LCLType, DefaultTranslator;

type

  { TMainForm }

  TMainForm = class(TForm)
    ACLBtn: TSpeedButton;
    CompDir: TShellTreeView;
    SettingsBtn: TSpeedButton;
    CopyFromPC: TSpeedButton;
    CopyFromBucket: TSpeedButton;
    DelBtn: TSpeedButton;
    AddBtn: TSpeedButton;
    GroupBox1: TGroupBox;
    GroupBox2: TGroupBox;
    ImageList1: TImageList;
    IniPropStorage1: TIniPropStorage;
    MkPCDirBtn: TSpeedButton;
    Panel1: TPanel;
    Panel2: TPanel;
    Panel3: TPanel;
    Panel4: TPanel;
    ProgressBar1: TProgressBar;
    UpdateBtn: TSpeedButton;
    SDBox: TListBox;
    LogMemo: TMemo;
    SelectAllBtn: TSpeedButton;
    InfoBtn: TSpeedButton;
    Splitter1: TSplitter;
    Splitter2: TSplitter;
    UpBtn: TSpeedButton;
    procedure ACLBtnClick(Sender: TObject);
    procedure AddBtnClick(Sender: TObject);
    procedure CompDirGetImageIndex(Sender: TObject; Node: TTreeNode);
    procedure CopyFromBucketClick(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: boolean);
    procedure FormKeyDown(Sender: TObject; var Key: word; Shift: TShiftState);
    procedure InfoBtnClick(Sender: TObject);
    procedure SettingsBtnClick(Sender: TObject);
    procedure CopyFromPCClick(Sender: TObject);
    procedure DelBtnClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure MkPCDirBtnClick(Sender: TObject);
    procedure UpdateBtnClick(Sender: TObject);
    procedure CompDirUpdate;
    procedure SDBoxDblClick(Sender: TObject);
    procedure SDBoxDrawItem(Control: TWinControl; Index: integer;
      ARect: TRect; State: TOwnerDrawState);
    procedure SelectAllBtnClick(Sender: TObject);
    procedure StartProcess(command: string);
    procedure StartLS;
    procedure StartCmd;
    procedure UpBtnClick(Sender: TObject);
    procedure ReadS3Root;
    procedure CheckConnect;

  private

  public

  end;

var
  left_panel: boolean;
  cmd: string;

resourcestring
  SDelete = 'Delete selected object(s)?';
  SOverwriteObject = 'Overwrite existing objects?';
  SObjectExists = 'The folder already exists!';
  SCreateDir = 'Create directory';
  SInputName = 'Enter the name:';
  SCancelCopyng = 'Esc - cancel... ';
  SCloseQuery = 'Copying is in progress! Finish the process?';
  SPublicAccess = 'Public access [READ, recursive, --acl-public]';
  SPrivateAccess = 'Private access [READ, recursive, --acl-private]';
  SNewBucket = 'Create new private Bucket';
  SBucketName = 'Bucket name:';

var
  MainForm: TMainForm;

implementation

uses config_unit, about_unit, lsfoldertrd, S3CommandTRD, FirstConnectTRD, acl_unit;

{$R *.lfm}

{ TMainForm }

//Ошибки первого подключения
procedure TMainForm.CheckConnect;
var
  FStartFirstConnect: TThread;
begin
  FStartFirstConnect := StartFirstConnect.Create(False);
  FStartFirstConnect.Priority := tpHighest; //tpHigher
end;

//Чтение корня хранилища
procedure TMainForm.ReadS3Root;
begin
  GroupBox2.Caption := 's3://';
  StartLS;
end;

//ls в директории s3:// (SDBox)
procedure TMainForm.StartCmd;
var
  FStartCmdThread: TThread;
begin
  FStartCmdThread := StartS3Command.Create(False);
  FStartCmdThread.Priority := tpHighest; //tpHigher
end;

//ls в директории s3:// (SDBox)
procedure TMainForm.StartLS;
var
  FLSFolderThread: TThread;
begin
  FLSFolderThread := StartLSFolder.Create(False);
  FLSFolderThread.Priority := tpHighest; //tpHigher
end;

//Уровень вверх
procedure TMainForm.UpBtnClick(Sender: TObject);
var
  i: integer;
begin
  if GroupBox2.Caption <> 's3://' then

  begin
    for i := Length(GroupBox2.Caption) - 1 downto 1 do
      if GroupBox2.Caption[i] = '/' then
      begin
        GroupBox2.Caption := Copy(GroupBox2.Caption, 1, i);
        break;
      end;
  end;
  //Чтение текущей директории
  StartLS;
end;

//StartCommand (служебные команды)
procedure TMainForm.StartProcess(command: string);
var
  ExProcess: TProcess;
begin
  try
    ExProcess := TProcess.Create(nil);
    ExProcess.Executable := 'bash';
    ExProcess.Parameters.Add('-c');
    ExProcess.Parameters.Add(command);
    ExProcess.Options := [poWaitOnExit, poUsePipes];
    ExProcess.Execute;
  finally
    ExProcess.Free;
  end;
end;

//Апдейт текущей директории CompDir (ShellTreeView)
procedure TMainForm.CompDirUpdate;
var
  i: integer; //Абсолютный индекс выделенного
  d: string; //Выделенная директория
begin
  try
    //Запоминаем позицию курсора
    i := CompDir.Selected.AbsoluteIndex;
    d := ExtractFilePath(CompDir.GetPathFromNode(CompDir.Selected));

    //Обновляем  выбранного родителя
    with CompDir do
      Refresh(Selected.Parent);

    //Курсор на созданную папку
    CompDir.Path := d;
    CompDir.Select(CompDir.Items[i]);
    CompDir.SetFocus;
  except;
    //Если сбой - перечитать корень
    UpdateBtn.Click;
  end;
end;

//Сменить директорию облака (s3://.../..)
procedure TMainForm.SDBoxDblClick(Sender: TObject);
begin
  if SDBox.Count <> 0 then
  begin
    if (Pos('//', SDBox.Items.Strings[SDBox.ItemIndex]) <> 0) or
      (Copy(SDBox.Items.Strings[SDBox.ItemIndex],
      Length(SDBox.Items.Strings[SDBox.ItemIndex]), 1) = '/') then
    begin
      GroupBox2.Caption := Trim(IncludeTrailingPathDelimiter(GroupBox2.Caption +
        SDBox.Items[SDBox.ItemIndex]));
      StartLS;
    end;
  end;
end;

//Прорисовка иконок панели 's3://'
procedure TMainForm.SDBoxDrawItem(Control: TWinControl; Index: integer;
  ARect: TRect; State: TOwnerDrawState);
var
  BitMap: TBitMap;
begin
  BitMap := TBitMap.Create;
  try
    ImageList1.GetBitMap(0, BitMap);

    with SDBox do
    begin
      Canvas.FillRect(aRect);
      //Вывод текста со сдвигом (общий)
      //Сверху иконки взависимости от последнего символа ('/')
      if Copy(Items[Index], Length(Items[Index]), 1) = '/' then
      begin
        //Имя папки
        Canvas.TextOut(aRect.Left + 27, aRect.Top + 5, Items[Index]);
        //Иконка папки
        ImageList1.GetBitMap(0, BitMap);
        Canvas.Draw(aRect.Left + 2, aRect.Top + 2, BitMap);
      end
      else
      begin
        //Имя файла
        Canvas.TextOut(aRect.Left + 27, aRect.Top + 5, Items[Index]);
        //Иконка файла
        ImageList1.GetBitMap(1, BitMap);
        Canvas.Draw(aRect.Left + 2, aRect.Top + 2, BitMap);
      end;
    end;
  finally
    BitMap.Free;
  end;
end;

//Выделить всё
procedure TMainForm.SelectAllBtnClick(Sender: TObject);
begin
  if GroupBox2.Caption <> 's3://' then
    SDBox.SelectAll;
end;

//Подстановка иконок папка/файл в ShellTreeView
procedure TMainForm.CompDirGetImageIndex(Sender: TObject; Node: TTreeNode);
begin
  if FileGetAttr(CompDir.GetPathFromNode(node)) and faDirectory <> 0 then
    Node.ImageIndex := 0
  else
    Node.ImageIndex := 1;
  Node.SelectedIndex := Node.ImageIndex;
end;

//Копирование из облака на компьютер
procedure TMainForm.CopyFromBucketClick(Sender: TObject);
var
  i: integer;
  c: string;
  e: boolean;
begin
  //Флаг выбора панели
  left_panel := True;

  c := '';
  cmd := '';  //Команда
  e := False; //Флаг совпадения файлов/папок (перезапись)

  if (SDBox.SelCount <> 0) and (GroupBox2.Caption <> 's3://') then
  begin
    for i := 0 to SDBox.Count - 1 do
    begin
      if SDBox.Selected[i] then
      begin
        if not e then
          if (FileExists(ExtractFilePath(CompDir.GetPathFromNode(CompDir.Selected)) +
            SDBox.Items[i]) or (DirectoryExists(
            ExtractFilePath(CompDir.GetPathFromNode(CompDir.Selected)) +
            SDBox.Items[i]))) then
            e := True;

        c := 's3cmd get --progress --recursive --force ' + '''' +
          ExcludeTrailingPathDelimiter(GroupBox2.Caption + SDBox.Items[i]) +
          '''' + ' ' + '''' + ExtractFilePath(CompDir.GetPathFromNode(
          CompDir.Selected)) + '''';

        cmd := c + '; ' + cmd;
      end;
    end;

    //Если есть совпадения (перезапись файлов)
    if e and (MessageDlg(SOverwriteObject, mtConfirmation, [mbYes, mbNo], 0) <>
      mrYes) then
      exit;

    StartCmd;
  end;
end;

//Предупреждение о завершении обмена с облаком, если в прогрессе
procedure TMainForm.FormCloseQuery(Sender: TObject; var CanClose: boolean);
begin
  if cmd <> '' then
    if MessageDlg(SCloseQuery, mtWarning, [mbYes, mbCancel], 0) <> mrYes then
      Canclose := False
    else
    begin
      StartProcess('killall s3cmd');
      CanClose := True;
    end;
end;

//Esc - отмена операций
procedure TMainForm.FormKeyDown(Sender: TObject; var Key: word; Shift: TShiftState);
begin
  if key = VK_ESCAPE then
  begin
    //Если копирование выполняется - отменяем
    if cmd <> '' then
    begin
      StartProcess('killall s3cmd');
      LogMemo.Append('S3cmd-GUI: Esc - Cancellation of the operation...');
    end;
  end;
end;

//Форма About
procedure TMainForm.InfoBtnClick(Sender: TObject);
begin
  AboutForm := TAboutForm.Create(Application);
  AboutForm.ShowModal;
end;

//Создание нового бакета
procedure TMainForm.AddBtnClick(Sender: TObject);
var
  S: string;
begin
  S := '';
  repeat
    if not InputQuery(SNewBucket, SBucketName, S) then
      Exit
  until S <> '';

  cmd := 's3cmd mb s3://' + Trim(S) + '; s3cmd setacl s3://' + Trim(S) +
    '/  --acl-private';

  left_panel := False;

  //Создаём новый бакет и показываем список бакетов 's3://'
  MainForm.GroupBox2.Caption := 's3://';
  MainForm.StartCmd;
end;

//Публичный/Приватный объект(ы)
procedure TMainForm.ACLBtnClick(Sender: TObject);
begin
  if SDBox.SelCount <> 0 then
    ACLForm.ShowModal;
end;

//Форма конфигурации ~/.s3cfg
procedure TMainForm.SettingsBtnClick(Sender: TObject);
begin
  ConfigForm := TConfigForm.Create(Application);
  ConfigForm.ShowModal;
end;

//Копирование с компа в облако
procedure TMainForm.CopyFromPCClick(Sender: TObject);
var
  i, sd: integer;
  c: string;
  e: boolean;
begin
  //Флаг выбора панели
  left_panel := False;
  //Сборка единой команды
  c := '';
  //Флаг совпадения имени
  e := False;
  //Команда
  cmd := '';

  //Если выбрано и выбран не корень и копируем не в корень облака (s3://)
  if (CompDir.Items.SelectionCount <> 0) and (not CompDir.Items.Item[0].Selected) and
    (GroupBox2.Caption <> 's3://') then
  begin
    for i := 0 to CompDir.Items.Count - 1 do
    begin
      if CompDir.Items[i].Selected then
      begin
        //Ищем совпадения (перезапись объектов)
        if not e then
          for sd := 0 to SDBox.Count - 1 do
          begin
            if CompDir.Items[i].Text = ExcludeTrailingPathDelimiter(
              SDBox.Items[sd]) then
              e := True;
          end;

        c := 's3cmd --progress --recursive put ' + '''' +
          ExcludeTrailingPathDelimiter(CompDir.Items[i].GetTextPath) +
          '''' + ' ' + '''' + GroupBox2.Caption + '''';

        cmd := c + '; ' + cmd;
      end;
    end;

    //Если есть совпадения (перезапись файлов)
    if e and (MessageDlg(SOverwriteObject, mtConfirmation, [mbYes, mbNo], 0) <>
      mrYes) then
      exit;

    StartCmd;
  end;
end;

//Удаление объекта(ов)
procedure TMainForm.DelBtnClick(Sender: TObject);
var
  i: integer;
  c: string; //сборка команд...
begin
  //Удаление файлов и папок
  if (SDBox.SelCount = 0) or (MessageDlg(SDelete, mtConfirmation, [mbYes, mbNo], 0) <>
    mrYes) then
    exit;

  //Команда в поток
  cmd := '';
  //Сборка команды
  c := '';

  //Флаг выбора панели
  left_panel := False;

  if GroupBox2.Caption <> 's3://' then
  begin
    for i := 0 to SDBox.Count - 1 do
    begin
      if SDBox.Selected[i] then
      begin
        if Pos('/', SDBox.Items[i]) <> 0 then
          c := 's3cmd --recursive --force del ' + '''' + GroupBox2.Caption +
            SDBox.Items[i] + ''''
        else
          c := 's3cmd rm --force ' + '''' + GroupBox2.Caption +
            SDBox.Items[i] + '''';
        //Собираем команду
        cmd := c + '; ' + cmd;
      end;
    end;
    StartCmd;
  end
  else
    //Удаление бакета и его незавершенных загрузок (очистка/удаление)
  begin
    cmd := 's3cmd multipart s3://' + SDBox.Items[SDBox.ItemIndex] +
      ' | grep ^[[:digit:]] | cut -f2 | awk ' + '''' + '{print "\""$0"\""}' +
      '''' + ' > ~/.s3cmd-gui/222;' + 's3cmd multipart s3://' +
      SDBox.Items[SDBox.ItemIndex] +
      ' | grep ^[[:digit:]] | cut -f3 > ~/.s3cmd-gui/333;' +
      'echo -e "#!/bin/bash\n" > ~/.s3cmd-gui/444;' +
      'paste ~/.s3cmd-gui/222 ~/.s3cmd-gui/333 >> ~/.s3cmd-gui/444;' +
      'sed -i "/s3/s/^/s3cmd abortmp /" ~/.s3cmd-gui/444; chmod +x ~/.s3cmd-gui/444; sh ~/.s3cmd-gui/444;'
      + 's3cmd rb --recursive --force s3://' + SDBox.Items[SDBox.ItemIndex];

    StartCmd;
  end;

end;

//Домашняя папка юзера - корень
procedure TMainForm.FormCreate(Sender: TObject);
begin
  //Очищаем переменную команды для потока
  cmd := '';

  CompDir.Root := ExcludeTrailingPathDelimiter(GetUserDir);
  CompDir.Items.Item[0].Selected := True;

  //Рабочая директория ~/.s3cmd-gui
  if not DirectoryExists(GetUserDir + '.s3cmd-gui') then
    MkDir(GetUserDir + '.s3cmd-gui');

  IniPropStorage1.IniFileName := GetUserDir + '.s3cmd-gui/s3cmd-gui.conf';
end;

procedure TMainForm.FormShow(Sender: TObject);
begin
  MainForm.Caption := Application.Title;
  IniPropStorage1.Restore;

  //Коррекция размеров при масштабировании в Plasma
  Panel3.Height := CopyFromPC.Height + 14;
  Panel4.Height := Panel3.Height;

  //Проверяем подключение выводим ошибки в LogMemo = StartLS (s3://)
  MainForm.CheckConnect;
end;

//Создать каталог на компьютере
procedure TMainForm.MkPCDirBtnClick(Sender: TObject);
var
  S: string;
begin
  //Флаг выбора панели
  left_panel := False;

  S := '';
  repeat
    if not InputQuery(SCreateDir, SInputName, S) then
      Exit
  until S <> '';

  //Если есть совпадения (перезапись файлов)
  if DirectoryExists(IncludeTrailingPathDelimiter(
    ExtractFilePath(CompDir.GetPathFromNode(CompDir.Selected))) + S) then
  begin
    MessageDlg(SObjectExists, mtWarning, [mbOK], 0);
    Exit;
  end;
  //Создаём директорию
  MkDir(IncludeTrailingPathDelimiter(
    ExtractFilePath(CompDir.GetPathFromNode(CompDir.Selected))) + S);

  //Обновляем содержимое выделенного нода
  CompDirUpdate;
end;

//Перечитываем домашнюю папку на компьютере
procedure TMainForm.UpdateBtnClick(Sender: TObject);
begin
  with CompDir do
  begin
    Select(CompDir.TopItem, [ssCtrl]);
    Refresh(CompDir.Selected.Parent);
    Select(CompDir.TopItem, [ssCtrl]);
    SetFocus;
  end;
end;

end.
