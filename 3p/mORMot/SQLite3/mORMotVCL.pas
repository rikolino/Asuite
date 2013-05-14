/// DB VCL dataset using TSQLTable/TSQLTableJSON data access
// - this unit is a part of the freeware Synopse framework,
// licensed under a MPL/GPL/LGPL tri-license; version 1.18
unit mORmotVCL;

{
    This file is part of Synopse mORmot framework.

    Synopse mORmot framework. Copyright (C) 2013 Arnaud Bouchez
      Synopse Informatique - http://synopse.info

  *** BEGIN LICENSE BLOCK *****
  Version: MPL 1.1/GPL 2.0/LGPL 2.1

  The contents of this file are subject to the Mozilla Public License Version
  1.1 (the "License"); you may not use this file except in compliance with
  the License. You may obtain a copy of the License at
  http://www.mozilla.org/MPL

  Software distributed under the License is distributed on an "AS IS" basis,
  WITHOUT WARRANTY OF ANY KIND, either express or implied. See the License
  for the specific language governing rights and limitations under the License.

  The Original Code is Synopse mORMot framework.

  The Initial Developer of the Original Code is Arnaud Bouchez.

  Portions created by the Initial Developer are Copyright (C) 2013
  the Initial Developer. All Rights Reserved.

  Contributor(s):
  Alternatively, the contents of this file may be used under the terms of
  either the GNU General Public License Version 2 or later (the "GPL"), or
  the GNU Lesser General Public License Version 2.1 or later (the "LGPL"),
  in which case the provisions of the GPL or the LGPL are applicable instead
  of those above. If you wish to allow use of your version of this file only
  under the terms of either the GPL or the LGPL, and not to allow others to
  use your version of this file under the terms of the MPL, indicate your
  decision by deleting the provisions above and replace them with the notice
  and other provisions required by the GPL or the LGPL. If you do not delete
  the provisions above, a recipient may use your version of this file under
  the terms of any one of the MPL, the GPL or the LGPL.

  ***** END LICENSE BLOCK *****

  Version 1.17
  - first public release, corresponding to Synopse mORMot Framework 1.17
  
  Version 1.18
  - renamed SQLite3VCL.pas to mORMotVCL.pas
  - fixed ticket [9de8be5d9e] with some types like TEnumeration or TTimeLog
  - fixed process with Unicode content
  - introduced new aForceWideString optional parameter for ticket [2970335e40]

}

{$I Synopse.inc} // define HASINLINE USETYPEINFO CPU32 CPU64 OWNNORMTOUPPER

interface

uses
  Windows,
  {$ifdef ISDELPHIXE2}System.SysUtils,{$else}SysUtils,{$endif}
  Classes,
  Contnrs,
{$ifndef DELPHI5OROLDER}
  Variants,
  MidasLib,
{$endif}
  SynCommons, mORmot,
  DB, DBClient;

/// convert a TSQLTable result into a VCL DataSet
// - current implementation will return a TClientDataSet instance, created from
// the supplied TSQLTable content (a more optimized version may appear later)
// - with non-Unicode version of Delphi, you can set aForceWideString to
// force the use of WideString fields instead of AnsiString, if needed
// - for better speed with Delphi older than Delphi 2009 Update 3, it is
// recommended to use http://andy.jgknet.de/blog/bugfix-units/midas-speed-fix-12
function TSQLTableToDataSet(aOwner: TComponent; aTable: TSQLTable; aClient: TSQLRest=nil
  {$ifndef UNICODE}; aForceWideString: boolean=false{$endif}): TDataSet;

/// convert a JSON result into a VCL DataSet
// - current implementation will return a TClientDataSet instance, created from
// the supplied TSQLTable content (a more optimized version may appear later)
// - with non-Unicode version of Delphi, you can set aForceWideString to
// force the use of WideString fields instead of AnsiString, if needed
// - with Unicode version of Delphi (2009+), UnicodeString will be used
// - for better speed with Delphi older than Delphi 2009 Update 3, it is
// recommended to use http://andy.jgknet.de/blog/bugfix-units/midas-speed-fix-12
function JSONToDataSet(aOwner: TComponent; const aJSON: RawUTF8; aClient: TSQLRest=nil
  {$ifndef UNICODE}; aForceWideString: boolean=false{$endif}): TDataSet;


implementation

function JSONToDataSet(aOwner: TComponent; const aJSON: RawUTF8; aClient: TSQLRest
  {$ifndef UNICODE}; aForceWideString: boolean{$endif}): TDataSet;
var T: TSQLTableJSON;
begin
  T := TSQLTableJSON.Create([],'',aJSON);
  try
    result := TSQLTableToDataSet(aOwner,T,aClient
      {$ifndef UNICODE},aForceWideString{$endif});
  finally
    T.Free;
  end;
end;

var
  GlobalDataSetCount: integer;

function TSQLTableToDataSet(aOwner: TComponent; aTable: TSQLTable; aClient: TSQLRest
  {$ifndef UNICODE}; aForceWideString: boolean{$endif}): TDataSet;
var F,i: integer;
    aFieldName: string;
    Types: array of record
      SQLType: TSQLFieldType;
      EnumType: Pointer;
    end;
begin
  result := TClientDataSet.Create(aOwner);
  try
    result.Name := 'DS'+IntToStr(GlobalDataSetCount); // unique name
    inc(GlobalDataSetCount);
    if aTable=nil then
      exit;
    SetLength(Types,aTable.FieldCount);
    for F := 0 to aTable.FieldCount-1 do begin
      aFieldName := aTable.GetString(0,F);
      with result.FieldDefs do begin
        Types[F].SQLType := aTable.FieldType(F,@Types[F].EnumType);
        case Types[F].SQLType of
        sftBoolean:
          Add(aFieldName,ftBoolean);
        sftInteger:
          Add(aFieldName,ftLargeint); // LargeInt=Int64
        sftFloat, sftCurrency:
          Add(aFieldName,ftFloat);
        sftID:
          Add(aFieldName,ftInteger);
        sftEnumerate, sftSet:
          if Types[F].EnumType=nil then
            Add(aFieldName,ftInteger) else
            Add(aFieldName,ftString,64);
        sftRecord:
          Add(aFieldName,ftString,64);
        sftDateTime, sftTimeLog, sftModTime, sftCreateTime:
          Add(aFieldName,ftDateTime);
        sftBlob:
          Add(aFieldName,ftBlob,(aTable.FieldLengthMax(F,true)*3) shr 2);
        sftUTF8Text:
          {$ifdef UNICODE} // for Delphi 2009+ TWideStringField = UnicodeString!
          Add(aFieldName,ftWideString,aTable.FieldLengthMax(F,true));
          {$else}
          if aForceWideString then
            Add(aFieldName,ftWideString,aTable.FieldLengthMax(F,true)) else
            Add(aFieldName,ftString,aTable.FieldLengthMax(F,true));
          {$endif}
        else
          Add(aFieldName,ftString,aTable.FieldLengthMax(F,true));
        end;
      end;
    end;
    TClientDataSet(result).CreateDataSet;
    TClientDataSet(result).LogChanges := false; // speed up
    for i := 1 to aTable.RowCount do begin
      result.Append;
      for F := 0 to result.FieldCount-1 do
      if aTable.Get(i,F)=nil then
        result.Fields[F].Clear else
      case Types[F].SQLType of
      sftBoolean:
        result.Fields[F].AsBoolean := aTable.GetAsInteger(i,F)<>0;
      sftInteger: // handle Int64 values directly
        (result.Fields[F] as TLargeintField).Value := GetInt64(aTable.Get(i,F));
      sftFloat, sftCurrency:
        result.Fields[F].AsFloat := GetExtended(aTable.Get(i,F));
      sftID:
        result.Fields[F].AsInteger := aTable.GetAsInteger(i,F);
      sftEnumerate, sftSet:
        if Types[F].EnumType=nil then
          result.Fields[F].AsInteger := aTable.GetAsInteger(i,F) else
          result.Fields[F].AsString := aTable.GetString(i,F);
      sftDateTime:
        result.Fields[F].AsDateTime := Iso8601ToDateTimePUTF8Char(aTable.Get(i,F),0);
      sftTimeLog, sftModTime, sftCreateTime:
        result.Fields[F].AsDateTime := aTable.GetVariant(i,F,aClient);
      sftBlob:
        {$ifdef UNICODE}
        result.Fields[F].AsBytes := aTable.GetBytes(i,F);
        {$else}
        result.Fields[F].AsString := aTable.GetBlob(i,F);
        {$endif}
      sftUTF8Text:
        {$ifdef UNICODE} // for Delphi 2009+ TWideStringField = UnicodeString!
        (result.Fields[F] as TWideStringField).Value := aTable.GetSynUnicode(i,F);
        {$else}
        if aForceWideString then
          (result.Fields[F] as TWideStringField).Value := aTable.GetSynUnicode(i,F) else
          result.Fields[F].AsString := aTable.GetString(i,F);
        {$endif}
      else   
        result.Fields[F].AsVariant := aTable.GetVariant(i,F,aClient);
      end;
      result.Post;
    end;
    result.First;
  except
    on Exception do
      FreeAndNil(result);
  end;
end;

end.

