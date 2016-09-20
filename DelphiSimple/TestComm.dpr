program TestComm;

uses
  Forms,
  main in 'main.pas' {Form1},
  PortUnit in 'PortUnit.pas',
  ComUnit in 'ComUnit.pas',
  Drive in 'Drive.pas';

{$R *.RES}

begin
  Application.Initialize;
  Application.CreateForm(TForm1, Form1);
  Application.Run;
end.
