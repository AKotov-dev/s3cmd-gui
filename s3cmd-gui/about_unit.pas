unit about_unit;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ExtCtrls, StdCtrls,
  Buttons, LCLType;

type

  { TAboutForm }

  TAboutForm = class(TForm)
    Bevel1: TBevel;
    OkBtn: TBitBtn;
    Image1: TImage;
    Label1: TLabel;
    Label2: TLabel;
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure FormKeyUp(Sender: TObject; var Key: word; Shift: TShiftState);
    procedure FormShow(Sender: TObject);
  private

  public

  end;

var
  AboutForm: TAboutForm;

implementation

{$R *.lfm}

{ TAboutForm }

procedure TAboutForm.FormClose(Sender: TObject; var CloseAction: TCloseAction);
begin
  CloseAction := caFree;
end;

procedure TAboutForm.FormKeyUp(Sender: TObject; var Key: word; Shift: TShiftState);
begin
  if key = VK_ESCAPE then
    AboutForm.Close;
end;

procedure TAboutForm.FormShow(Sender: TObject);
begin
  Label1.Caption := Application.Title;
  AboutForm.Width := Label2.Left + Label2.Width + 20;
  AboutForm.Height := OkBtn.Top + OkBtn.Height + 8;
end;

end.

