unit bucket_unit;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, ExtCtrls,
  Buttons;

type

  { TBucketForm }

  TBucketForm = class(TForm)
    BitBtn1: TBitBtn;
    BitBtn2: TBitBtn;
    CheckBox1: TCheckBox;
    Edit1: TEdit;
    Label1: TLabel;
    procedure BitBtn1Click(Sender: TObject);
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure FormShow(Sender: TObject);
  private

  public

  end;

var
  BucketForm: TBucketForm;

implementation

uses unit1;

{$R *.lfm}

{ TBucketForm }

procedure TBucketForm.FormShow(Sender: TObject);
begin
  BucketForm.Width := CheckBox1.Left + CheckBox1.Width + 8;
  BucketForm.Height := BitBtn1.Top + BitBtn1.Height + 8;
end;

//Создать бакет
procedure TBucketForm.BitBtn1Click(Sender: TObject);
begin
  if CheckBox1.Checked then
    cmd := 's3cmd mb s3://' + Edit1.Text + '; s3cmd setacl s3://' +
      Edit1.Text + '/  --acl-public'
  else
    cmd := 's3cmd mb s3://' + Edit1.Text + '; s3cmd setacl s3://' +
      Edit1.Text + '/  --acl-private';

  left_panel := False;

  MainForm.StartCmd;
end;

procedure TBucketForm.FormClose(Sender: TObject; var CloseAction: TCloseAction);
begin
  CloseAction := caFree;
end;

end.
