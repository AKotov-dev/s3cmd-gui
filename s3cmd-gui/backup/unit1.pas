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
    CompDir: TShellTreeView;
    SettingsBtn: TSpeedButton;
    CopyFromPC: TSpeedButton;
    CopyFromSmartphone: TSpeedButton;
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
    RefreshBtn: TSpeedButton;
    SDBox: TListBox;
    SDMemo: TMemo;
    SelectAllBtn: TSpeedButton;
    InfoBtn: TSpeedButton;
    Splitter1: TSplitter;
    Splitter2: TSplitter;
    UpBtn: TSpeedButton;
    procedure AddBtnClick(Sender: TObject);
    procedure CompDirGetImageIndex(Sender: TObject; Node: TTreeNode);
    procedure CopyFromSmartphoneClick(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: boolean);
    procedure InfoBtnClick(Sender: TObject);
    procedure SettingsBtnClick(Sender: TObject);
    procedure CopyFromPCClick(Sender: TObject);
    procedure DelBtnClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormKeyUp(Sender: TObject; var Key: word; Shift: TShiftState);
    procedure FormShow(Sender: TObject);
    procedure MkPCDirBtnClick(Sender: TObject);
    procedure RefreshBtnClick(Sender: TObject);
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

var
  MainForm: TMainForm;

implementation

uses config_unit, bucket_unit, about_unit, lsfoldertrd, S3CommandTRD, FirstConnectTRD;

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

  StartLS;
end;

//StartCommand
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
  //Запоминаем позицию курсора
  i := CompDir.Selected.AbsoluteIndex;
  d := ExtractFilePath(CompDir.GetPathFromNode(CompDir.Selected));

  //Обновляем  выбранного родителя
  CompDir.Refresh(CompDir.Selected.Parent);
  //Возвращаем курсор на исходную
  CompDir.Path := d;
  CompDir.Select(CompDir.Items[i]);
  CompDir.SetFocus;
end;

procedure TMainForm.SDBoxDblClick(Sender: TObject);
begin
  if SDBox.Count <> 0 then
  begin
    if GroupBox2.Caption = 's3://' then
      GroupBox2.Caption := ' ';

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
      if (Pos('//', Items[Index]) <> 0) or
        (Copy(Items[Index], Length(Items[Index]), 1) = '/') then
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

//Копирование из облака на комп
procedure TMainForm.CopyFromSmartphoneClick(Sender: TObject);
var
  i: integer;
  c: string;
  e: boolean;
begin
  //Если команда выполняется - следующую не запускать
  if cmd <> '' then
    exit;

  //Флаг выбора панели
  left_panel := True;

  c := '';
  e := False; //Флаг совпадения файлов/папок (перезапись)
  cmd := '';  //Команда

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
          GroupBox2.Caption + SDBox.Items[i] + '''' + ' ' + '''' +
          ExtractFilePath(CompDir.GetPathFromNode(CompDir.Selected)) + '''';

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

procedure TMainForm.FormCloseQuery(Sender: TObject; var CanClose: boolean);
begin
  //Предупреждение о завершении обмена с облаком, если в прогрессе
  if cmd <> '' then
    if MessageDlg(SCloseQuery, mtWarning, [mbYes, mbCancel], 0) <> mrYes then
      Canclose := False;
end;

//Форма About
procedure TMainForm.InfoBtnClick(Sender: TObject);
begin
  AboutForm := TAboutForm.Create(Application);
  AboutForm.ShowModal;
end;

//Форма создания бакета
procedure TMainForm.AddBtnClick(Sender: TObject);
begin
  //Если команда выполняется - следующую не запускать
  if cmd <> '' then
    exit;
  BucketForm := TBucketForm.Create(Application);
  BucketForm.ShowModal;
end;

//Форма конфигурации ~/.s3cfg
procedure TMainForm.SettingsBtnClick(Sender: TObject);
begin
  //Если команда выполняется - следующую не запускать
  if cmd <> '' then
    exit;
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
  //Если команда выполняется - следующую не запускать
  if cmd <> '' then
    exit;

  //Флаг выбора панели
  left_panel := False;

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

procedure TMainForm.DelBtnClick(Sender: TObject);
var
  i: integer;
  c: string; //сборка команд...
begin
  if (SDBox.Count = 0) or (cmd <> '') then
    Exit;

  //Команда в поток
  cmd := '';
  c := '';

  //Флаг выбора панели
  left_panel := False;

  if GroupBox2.Caption <> 's3://' then
  begin
    //Удаление файлов и папок
    if (SDBox.SelCount <> 0) and
      (MessageDlg(SDelete, mtConfirmation, [mbYes, mbNo], 0) = mrYes) then
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
    end;
  end
  else
    //Удаление бакета!!!
  begin
    if MessageDlg(SDelete, mtConfirmation, [mbYes, mbNo], 0) = mrYes then
    begin
      cmd := 's3cmd multipart ' + SDBox.Items.Strings[SDBox.ItemIndex] +
        ' | grep ^[[:digit:]] | cut -f2 | awk ' + '''' + '{print "\""$0"\""}' +
        '''' + ' > ~/.s3cmd-gui/222;' + 's3cmd multipart ' +
        SDBox.Items.Strings[SDBox.ItemIndex] +
        ' | grep ^[[:digit:]] | cut -f3 > ~/.s3cmd-gui/333;' +
        'echo -e "#!/bin/bash\n" > ~/.s3cmd-gui/444;' +
        'paste ~/.s3cmd-gui/222 ~/.s3cmd-gui/333 >> ~/.s3cmd-gui/444;' +
        'sed -i "/s3/s/^/s3cmd abortmp /" ~/.s3cmd-gui/444; chmod +x ~/.s3cmd-gui/444; sh ~/.s3cmd-gui/444;'
        + 's3cmd rb --recursive --force ' + SDBox.Items.Strings[SDBox.ItemIndex];

      StartCmd;
    end;
  end;

end;

//Домашняя папка юзера - корень
procedure TMainForm.FormCreate(Sender: TObject);
begin
  CompDir.Root := ExcludeTrailingPathDelimiter(GetUserDir);
  CompDir.Items.Item[0].Selected := True;

  //Рабочая директория ~/.s3cmd-gui
  if not DirectoryExists(GetUserDir + '.s3cmd-gui') then
    MkDir(GetUserDir + '.s3cmd-gui');

  IniPropStorage1.IniFileName := GetUserDir + '.s3cmd-gui/s3cmd-gui.conf';
end;

//Esc - отмена длительных операций
procedure TMainForm.FormKeyUp(Sender: TObject; var Key: word; Shift: TShiftState);
begin
  if key = VK_ESCAPE then
  begin
    //Если копирование выполняется - отменяем
    if cmd <> '' then
    begin
      StartProcess('killall s3cmd');
      SDMemo.Append('s3cmd-gui: cancel operation...');
    end;
  end;
end;

procedure TMainForm.FormShow(Sender: TObject);
begin
  MainForm.Caption := Application.Title;
  IniPropStorage1.Restore;
  //Проверяем подключение выводим ошибки в SDMemo
  MainForm.CheckConnect;
  //Указатель в корень (s3://) и перечитываем
  MainForm.ReadS3Root;
end;

//Создать каталог на компе
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

//Перечитываем папку на компе
procedure TMainForm.RefreshBtnClick(Sender: TObject);
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
