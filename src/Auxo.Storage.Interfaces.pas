unit Auxo.Storage.Interfaces;

interface

uses
  System.Generics.Collections, System.Rtti;

const
  IStorager_ID = '{0050760F-69AF-441A-880C-19ACE3DF4371}';
  IStorager_GUID: TGUID = IStorager_ID;

type
  IStorager = interface
  [IStorager_ID]
    procedure Load(AValues: TDictionary<string, string>);
    procedure Save(AMember: string; Value: TValue);
  end;

implementation

end.
