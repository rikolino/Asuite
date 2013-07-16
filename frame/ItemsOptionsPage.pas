unit ItemsOptionsPage;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, BaseEntityPage, Vcl.StdCtrls,
  Vcl.ComCtrls, Vcl.Buttons, ulEnumerations, ulCommonClasses;

type
  TfrmItemsOptionsPage = class(TfrmBaseEntityPage)
    gbExecution: TGroupBox;
    lbActionOnExe: TLabel;
    cbRunSingleClick: TCheckBox;
    cxActionOnExe: TComboBox;
    grpOrderSoftware: TGroupBox;
    lblOrderInfo: TLabel;
    pgcSoftwareOrder: TPageControl;
    tsStartUp: TTabSheet;
    lstStartUp: TListBox;
    tsShutdown: TTabSheet;
    lstShutdown: TListBox;
    cbAutorun: TCheckBox;
    btnDown: TBitBtn;
    btnUp: TBitBtn;
    procedure btnDownClick(Sender: TObject);
    procedure btnUpClick(Sender: TObject);
  private
    { Private declarations }
    FAutorunType: TAutorunType;
    procedure PopulateLstAutoExe(ListBox: TListBox;AutorunItemList: TAutorunItemList);
    procedure MoveItemUp(ListBox: TListBox);
    procedure MoveItemDown(ListBox: TListBox);
    procedure SaveInAutorunItemList(ListBox: TListBox;AutorunItemList: TAutorunItemList);
  strict protected
    function GetTitle: string; override;
    function InternalLoadData: Boolean; override;
    function InternalSaveData: Boolean; override;
  public
    { Public declarations }
    property AutorunType: TAutorunType read FAutorunType write FAutorunType;
  end;

var
  frmItemsOptionsPage: TfrmItemsOptionsPage;

implementation

uses
  ulNodeDataTypes, ulTreeView, ulAppConfig;

{$R *.dfm}

{ TfrmItemsOptionsPage }

procedure TfrmItemsOptionsPage.btnDownClick(Sender: TObject);
begin
  case pgcSoftwareOrder.ActivePageIndex of
    0: MoveItemDown(lstStartUp);
    1: MoveItemDown(lstShutdown);
  end;
end;

procedure TfrmItemsOptionsPage.btnUpClick(Sender: TObject);
begin
  case pgcSoftwareOrder.ActivePageIndex of
    0: MoveItemUp(lstStartUp);
    1: MoveItemUp(lstShutdown);
  end;
end;

function TfrmItemsOptionsPage.GetTitle: string;
begin
  Result := 'Items';
end;

procedure TfrmItemsOptionsPage.PopulateLstAutoExe(ListBox: TListBox;AutorunItemList: TAutorunItemList);
var
  I: Integer;
  NodeData: TvFileNodeData;
begin
  ListBox.Items.BeginUpdate;
  for I := 0 to AutorunItemList.Count - 1 do
  begin
    NodeData := AutorunItemList[I];
    if Assigned(NodeData) then
      ListBox.Items.AddObject(NodeData.Name, AutorunItemList[I]);
  end;
  ListBox.Items.EndUpdate;
end;

procedure TfrmItemsOptionsPage.SaveInAutorunItemList(ListBox: TListBox;
  AutorunItemList: TAutorunItemList);
var
  I: Integer;
  NodeData: TvFileNodeData;
begin
  AutorunItemList.Clear;
  for I := 0 to ListBox.Count - 1 do
  begin
    NodeData := TvFileNodeData(ListBox.Items.Objects[I]);
    NodeData.AutorunPos := AutorunItemList.Add(NodeData);
    NodeData.Changed := True;
  end;
end;

procedure TfrmItemsOptionsPage.MoveItemUp(ListBox: TListBox);
var
  CurrIndex: Integer;
begin
  with ListBox do
  begin
    CurrIndex := ItemIndex;
    if (CurrIndex <> (-1 and 0)) and (Count <> 0) then
    begin
      Items.Move(CurrIndex, CurrIndex - 1);
      Selected[CurrIndex - 1] := True;
    end;
  end;
end;

procedure TfrmItemsOptionsPage.MoveItemDown(ListBox: TListBox);
var
  CurrIndex: Integer;
begin
  with ListBox do
  begin
    CurrIndex := ItemIndex;
    if (CurrIndex <> (-1 and (Count - 1))) and (Count <> 0) then
    begin
      Items.Move(CurrIndex, CurrIndex + 1);
      Selected[CurrIndex + 1] := True;
    end;
  end;
end;

function TfrmItemsOptionsPage.InternalLoadData: Boolean;
begin
  inherited;
  //Execution options
  cxActionOnExe.ItemIndex   := Ord(Config.ActionOnExe);
  cbRunSingleClick.Checked  := Config.RunSingleClick;
  //Autorun
  cbAutorun.Checked := Config.Autorun;
  //According as AutorunType, display StartUp or Shutdown page
  case FAutorunType of
    atAlwaysOnStart, atSingleInstance:
      pgcSoftwareOrder.ActivePageIndex := 0;
    atAlwaysOnClose:
      pgcSoftwareOrder.ActivePageIndex := 1;
  end;
  //Populate lstStartUp and lstShutdown
  PopulateLstAutoExe(lstStartUp,StartupItemList);
  PopulateLstAutoExe(lstShutdown,ShutdownItemList);
end;

function TfrmItemsOptionsPage.InternalSaveData: Boolean;
begin
  inherited;
  //Execution options
  Config.ActionOnExe    := TActionOnExecute(cxActionOnExe.ItemIndex);
  Config.RunSingleClick := cbRunSingleClick.Checked;
  //Autorun
  Config.Autorun        := cbAutorun.Checked;
  //Save Startup and Shutdown lists
  SaveInAutorunItemList(lstStartUp,StartupItemList);
  SaveInAutorunItemList(lstShutdown,ShutdownItemList);
end;

end.
