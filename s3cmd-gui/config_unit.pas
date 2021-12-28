unit config_unit;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, Buttons, Process;

type

  { TConfigForm }

  TConfigForm = class(TForm)
    BitBtn1: TBitBtn;
    BitBtn2: TBitBtn;
    Edit1: TEdit;
    Edit2: TEdit;
    Edit3: TEdit;
    Edit4: TEdit;
    Edit5: TEdit;
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    Label4: TLabel;
    Label5: TLabel;
    procedure BitBtn1Click(Sender: TObject);
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure FormShow(Sender: TObject);
  private

  public

  end;

var
  ConfigForm: TConfigForm;

implementation

uses unit1;

{$R *.lfm}

{ TConfigForm }

procedure TConfigForm.BitBtn1Click(Sender: TObject);
var
  S: TStringList;
begin
  //Обновить правую панель, если подключение состоялось
  left_panel := False;
  //Делаем новый ~/.s3cfg и сохраняем
  try
    S := TStringList.Create;
    S.Add('[default]');
    S.Add('access_key = ' + Trim(Edit1.Text));
    S.Add('secret_key = ' + Trim(Edit2.Text));
    S.Add('bucket_location = ' + Trim(Edit3.Text));
    S.Add('host_base = ' + Trim(Edit4.Text));
    S.Add('host_bucket = ' + Trim(Edit5.Text));

    S.SaveToFile(GetUserDir + '.s3cfg');

    //Проверяем подключение выводим ошибки в SDMemo
    MainForm.CheckConnect;
  finally
    S.Free;
  end;
end;

procedure TConfigForm.FormClose(Sender: TObject; var CloseAction: TCloseAction);
begin
  CloseAction := caFree;
end;

//Чтение параметров напрямую из ~/.s3cfg
procedure TConfigForm.FormShow(Sender: TObject);
var
  S: ansistring;
begin
  if FileExists(GetUserDir + '.s3cfg') then
  begin
    if RunCommand('/bin/bash',
      ['-c', 'grep "access_key = " ~/.s3cfg | sed "s/access_key = //"'], S) then
      Edit1.Text := Trim(S);

    if RunCommand('/bin/bash',
      ['-c', 'grep "secret_key = " ~/.s3cfg | sed "s/secret_key = //"'], S) then
      Edit2.Text := Trim(S);

    if RunCommand('/bin/bash',
      ['-c', 'grep "bucket_location = " ~/.s3cfg | sed "s/bucket_location = //"'],
      S) then
      Edit3.Text := Trim(S);

    if RunCommand('/bin/bash',
      ['-c', 'grep "host_base = " ~/.s3cfg | sed "s/host_base = //"'], S) then
      Edit4.Text := Trim(S);

    if RunCommand('/bin/bash',
      ['-c', 'grep "host_bucket = " ~/.s3cfg | sed "s/host_bucket = //"'], S) then
      Edit5.Text := Trim(S);
  end;
end;

end.
