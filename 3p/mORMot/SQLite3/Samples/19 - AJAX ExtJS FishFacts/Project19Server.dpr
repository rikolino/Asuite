{
   Synopse mORMot framework

   Sample 19 - HTTP Server for FishFacts ExtJS queries

}

program Project19Server;

//   first line of uses clause must be   {$I SynDprUses.inc}
uses
  {$I SynDprUses.inc}
  Forms,
  Unit2 in 'Unit2.pas' {Form1};

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TForm1, Form1);
  Application.Run;
end.
