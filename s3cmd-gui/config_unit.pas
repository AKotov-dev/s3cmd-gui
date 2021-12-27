unit config_unit;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, Buttons;

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
  left_panel := False;

  try
    S := TStringList.Create;
    S.Add('[default]');
    S.Add('access_key = ' + Edit1.Text);
    S.Add('secret_key = ' + Edit2.Text);
    S.Add('bucket_location = ' + Edit3.Text);
    S.Add('host_base = ' + Edit4.Text);
    S.Add('host_bucket =' + Edit5.Text);

    S.SaveToFile(GetUserDir + '.s3cfg');

    //Проверяем подключение выводим ошибки в SDMemo
    MainForm.CheckConnect;
    //Указатель в корень (s3://) и перечитываем
    MainForm.ReadS3Root;
  finally
    S.Free;
  end;
end;

procedure TConfigForm.FormClose(Sender: TObject; var CloseAction: TCloseAction);
begin
  CloseAction := caFree;

  //Если Ok = сохраняем настройки
  if ModalResult = mrOk then
    with MainForm.IniPropStorage1 do
    begin
      //    IniSection := 's3cmd'; //указываем секцию
      WriteString('access_key', Edit1.Text);
      WriteString('secret_key', Edit2.Text);
      WriteString('bucket_location', Edit3.Text);
      WriteString('host_base', Edit4.Text);
      WriteString('host_bucket', Edit5.Text);
    end;
end;

//Чтение параметров s3cmd
procedure TConfigForm.FormShow(Sender: TObject);
begin
  with MainForm.IniPropStorage1 do
  begin
    // IniSection := 's3cmd'; //указываем секцию
    Edit1.Text := ReadString('access_key', '');
    Edit2.Text := ReadString('secret_key', '');
    Edit3.Text := ReadString('bucket_location', '');
    Edit4.Text := ReadString('host_base', '');
    Edit5.Text := ReadString('host_bucket', '');
  end;
end;

end.
