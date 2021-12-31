unit acl_unit;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ExtCtrls, Buttons;

type

  { TACLForm }

  TACLForm = class(TForm)
    OkBtn: TBitBtn;
    CloseBtn: TBitBtn;
    RadioGroup1: TRadioGroup;
    procedure OkBtnClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormShow(Sender: TObject);
  private

  public

  end;

var
  ACLForm: TACLForm;

implementation

uses unit1;

{$R *.lfm}

{ TACLForm }

//Публичный/Приватный (ACL)
procedure TACLForm.OkBtnClick(Sender: TObject);
var
  i: integer;
  c: string;
begin
  for i := 0 to MainForm.SDBox.Count - 1 do
  begin
    if MainForm.SDBox.Selected[i] then
    begin
      if RadioGroup1.ItemIndex = 0 then
      begin
        if MainForm.GroupBox2.Caption <> 's3://' then
          c := 's3cmd setacl --recursive "' + MainForm.GroupBox2.Caption +
            MainForm.SDBox.Items[i] + '" --acl-public'
        else
          c := 's3cmd setacl ' + MainForm.SDBox.Items[i] + '/ --acl-public';

        cmd := c + '; ' + cmd;
      end
      else
      begin
        if MainForm.GroupBox2.Caption <> 's3://' then
          c := 's3cmd setacl --recursive "' + MainForm.GroupBox2.Caption +
            MainForm.SDBox.Items[i] + '" --acl-private'
        else
          c := 's3cmd setacl ' + MainForm.SDBox.Items[i] + '/ --acl-private';

        cmd := c + '; ' + cmd;
      end;
    end;
  end;
  MainForm.StartCmd;
end;

procedure TACLForm.FormCreate(Sender: TObject);
begin
  RadioGroup1.Items[0] := SPublicAccess;
  RadioGroup1.Items[1] := SPrivateAccess;
end;

procedure TACLForm.FormShow(Sender: TObject);
begin
  ACLForm.Height := OkBtn.Top + OkBtn.Height + 8;
end;

end.
