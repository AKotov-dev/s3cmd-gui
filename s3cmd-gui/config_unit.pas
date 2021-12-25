unit config_unit;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, Buttons,
  IniPropStorage;

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
    IniPropStorage1: TIniPropStorage;
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    Label4: TLabel;
    Label5: TLabel;
    procedure BitBtn1Click(Sender: TObject);
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure FormCreate(Sender: TObject);
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
  try
    S := TStringList.Create;
    S.Add('[default]');
    S.Add('access_key = ' + Edit1.Text);
    S.Add('secret_key = ' + Edit2.Text);
    S.Add('bucket_location = ' + Edit3.Text);
    S.Add('host_base = ' + Edit4.Text);
    S.Add('host_bucket =' + Edit5.Text);

    S.SaveToFile(GetUserDir + '.s3cfg');
    left_panel := False;

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
end;

procedure TConfigForm.FormCreate(Sender: TObject);
begin
  IniPropStorage1.IniFileName := MainForm.IniPropStorage1.IniFileName;
end;

end.
