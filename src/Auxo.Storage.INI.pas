unit Auxo.Storage.INI;

interface

uses
  System.Generics.Collections, System.Rtti, System.IniFiles, Auxo.Storage.Interfaces;

type
  TIniStorager = class(TInterfacedObject, IStorager)
  protected
    procedure Load(AValues: TDictionary<string, string>);
    procedure Save(AMember: string; Value: TValue);
  public
    IniFile: string;
    Section: string;
    constructor Create(AIniFile: string; ASection: string);
  end;

implementation

uses
  System.Classes, System.SysUtils, System.StrUtils, System.Types;

{ TIniStorager }

constructor TIniStorager.Create(AIniFile, ASection: string);
begin
  IniFile := AIniFile;
  Section := ASection;
end;

procedure TIniStorager.Load(AValues: TDictionary<string, string>);
var
  Ini: TIniFile;
  StrList: TStringList;
  KeyValue: TStringDynArray;
  I: Integer;
begin
  Ini := TIniFile.Create(IniFile);
  try
    StrList := TStringList.Create;
    try
      Ini.ReadSectionValues(Section, StrList);
      for I := 0 to StrList.Count-1 do
      begin
        KeyValue := SplitString(StrList[I], '=');
        AValues.Add(KeyValue[0], KeyValue[1]);
      end;
    finally
      StrList.Free;
    end;
  finally
    Ini.Free;
  end;
end;

procedure TIniStorager.Save(AMember: string; Value: TValue);
var
  Ini: TIniFile;
begin
  Ini := TIniFile.Create(IniFile);
  try
    Ini.WriteString(Section, AMember, Value.ToString);
  finally
    Ini.Free;
  end;
end;

end.
