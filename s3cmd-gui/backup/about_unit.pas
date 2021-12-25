unit about_unit;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ExtCtrls, StdCtrls,
  Buttons;

type

  { TAboutForm }

  TAboutForm = class(TForm)
    Bevel1: TBevel;
    BitBtn1: TBitBtn;
    Image1: TImage;
    Label1: TLabel;
    Label2: TLabel;
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
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

procedure TAboutForm.FormShow(Sender: TObject);
begin
  AboutForm.Width:=Label2.Left + Label2.Width + 20;
  AboutForm.Height:= BitBtn1.Top + BitBtn1.Height + 8;
end;

end.

