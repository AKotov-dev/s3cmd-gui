program s3cmdgui;

{$mode objfpc}{$H+}

uses {$IFDEF UNIX}
  cthreads, {$ENDIF}
  Interfaces, // this includes the LCL widgetset
  Forms,
  Unit1,
  config_unit,
  bucket_unit,
  about_unit,
  FirstConnectTRD { you can add units after this };

{$R *.res}

begin
  RequireDerivedFormResource := True;
  Application.Title:='S3cmd-GUI v0.5';
  Application.Scaled := True;
  Application.Initialize;
  Application.CreateForm(TMainForm, MainForm);
  Application.Run;
end.
