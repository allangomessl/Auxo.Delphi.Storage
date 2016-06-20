unit Auxo.Storage.Core;

interface

uses
  Auxo.Storage.Interfaces, System.Generics.Collections, System.Rtti, System.SysUtils;

type
  TStorage = class;

  Prop<T> = record
  private
    FValue: T;
    MemberName: string;
    Storage: TStorage;
    function GetValue: T;
    procedure SetValue(const AValue: T);
  public
    property Value: T read GetValue write SetValue;
    constructor Create(AValue: T); overload;

    class operator Implicit(AValue: Prop<T>): T;
    class operator Equal(ALeft: Prop<T>; ARight: T): Boolean;
    class operator NotEqual(ALeft: Prop<T>; ARight: T): Boolean;
    class operator GreaterThan(ALeft: Prop<T>; ARight: T): Boolean;
    class operator GreaterThanOrEqual(ALeft: Prop<T>; ARight: T): Boolean;
    class operator LessThan(ALeft, ARight: Prop<T>): Boolean;
    class operator LessThanOrEqual(ALeft, ARight: Prop<T>): Boolean;
  end;

  Crypt = record
  private
    FValue: string;
    MemberName: string;
    Storage: TStorage;
    function GetValue: string;
    procedure SetValue(const Value: string);
  public
    constructor Create(Value: string); overload;
    property Value: string read GetValue write SetValue;

    class operator Implicit(Value: Crypt): string;

    class operator Equal(Left: Crypt; Right: string): Boolean;
    class operator NotEqual(Left: Crypt; Right: string): Boolean;

    class operator GreaterThan(Left: Crypt; Right: string): Boolean;
    class operator GreaterThanOrEqual(Left: Crypt; Right: string): Boolean;

    class operator LessThan(Left, Right: Crypt): Boolean;
    class operator LessThanOrEqual(Left, Right: Crypt): Boolean;
  end;

  TStorage = class
  private
    FStorager: IStorager;
    FValues: TDictionary<string, string>;
    function GetValue<T>(Field: TRttiField): T;
    function SetValueType<T>(Field: TRttiField; DefaultValues: Boolean): Boolean;
    procedure SetValues(DefaultValues: Boolean);
  protected
    FDefaultValuesSetting: Boolean;
    procedure SetDefaultValues; virtual;
    procedure Save(const AMember: string; Value: TValue); virtual;
  public
    constructor Create(AStorager: IStorager); virtual;
  end;

var
  EncryptDelegate: TFunc<string, string>;
  DecryptDelegate: TFunc<string, string>;

implementation

uses
  System.Generics.Defaults, System.TypInfo, System.UITypes;

{ Prop<T> }

constructor Prop<T>.Create(AValue: T);
begin
  FValue := Value;
end;

function Prop<T>.GetValue: T;
begin
  Result := FValue;
end;

procedure Prop<T>.SetValue(const AValue: T);
begin
  FValue := Value;
  if Storage <> nil then
    Storage.Save(MemberName, TValue.From<T>(Value));
end;

class operator Prop<T>.Equal(ALeft: Prop<T>; ARight: T): Boolean;
begin
  Result := TEqualityComparer<T>.Default.Equals(ALeft.FValue, ARight);
end;

class operator Prop<T>.GreaterThan(ALeft: Prop<T>; ARight: T): Boolean;
begin
  Result := TComparer<T>.Default.Compare(ALeft, ARight) > 0;
end;

class operator Prop<T>.GreaterThanOrEqual(ALeft: Prop<T>; ARight: T): Boolean;
begin
  Result := TComparer<T>.Default.Compare(ALeft, ARight) >= 0;
end;

class operator Prop<T>.Implicit(AValue: Prop<T>): T;
begin
  Result := AValue.GetValue;
end;

class operator Prop<T>.LessThan(ALeft, ARight: Prop<T>): Boolean;
begin
  Result := TComparer<T>.Default.Compare(ALeft, ARight) < 0;
end;

class operator Prop<T>.LessThanOrEqual(ALeft, ARight: Prop<T>): Boolean;
begin
  Result := TComparer<T>.Default.Compare(ALeft, ARight) <= 0;
end;

class operator Prop<T>.NotEqual(ALeft: Prop<T>; ARight: T): Boolean;
begin
  Result := not TEqualityComparer<T>.Default.Equals(ALeft.FValue, ARight);
end;

{ Crypt }

constructor Crypt.Create(Value: string);
begin
  FValue := Value;
end;

function Crypt.GetValue: string;
begin
  if Assigned(DecryptDelegate) then
    Result := DecryptDelegate(FValue)
  else
    raise Exception.Create('public var DecryptDelegate in Auxo Storage.Proxyes not assigned');
end;

procedure Crypt.SetValue(const Value: string);
begin
  if Assigned(EncryptDelegate) then
  begin
    FValue := EncryptDelegate(Value);
    Storage.Save(MemberName, FValue);
  end
  else
    raise Exception.Create('public var DecryptDelegate in Auxo Storage.Proxyes not assigned');
end;

class operator Crypt.Equal(Left: Crypt; Right: string): Boolean;
begin
  Result := TEqualityComparer<string>.Default.Equals(Left.FValue, Right);
end;

class operator Crypt.GreaterThan(Left: Crypt; Right: string): Boolean;
begin
  Result := TComparer<string>.Default.Compare(Left, Right) > 0;
end;

class operator Crypt.GreaterThanOrEqual(Left: Crypt; Right: string): Boolean;
begin
  Result := TComparer<string>.Default.Compare(Left, Right) >= 0;
end;

class operator Crypt.Implicit(Value: Crypt): string;
begin
  Result := Value.GetValue;
end;

class operator Crypt.LessThan(Left, Right: Crypt): Boolean;
begin
  Result := TComparer<string>.Default.Compare(Left, Right) < 0;
end;

class operator Crypt.LessThanOrEqual(Left, Right: Crypt): Boolean;
begin
  Result := TComparer<string>.Default.Compare(Left, Right) <= 0;
end;

class operator Crypt.NotEqual(Left: Crypt; Right: string): Boolean;
begin
  Result := not TEqualityComparer<string>.Default.Equals(Left.FValue, Right);
end;

{ TStorage }

constructor TStorage.Create(AStorager: IStorager);
begin
  FStorager := AStorager;
//  FStorager.SetStorage(Self);
  SetValues(True);
  SetValues(False);
end;

function TStorage.GetValue<T>(Field: TRttiField): T;
var
  Hndle: PTypeInfo;
  Value: TValue;
begin
  Hndle := TypeInfo(T);
  if Hndle = TypeInfo(Integer) then
    Value := TValue.From<Integer>(StrToIntDef(FValues.Items[Field.Name], 0))
  else if Hndle = TypeInfo(string) then
    Value := TValue.From<string>(FValues.Items[Field.Name])
  else if Hndle = TypeInfo(TDateTime) then
    Value := TValue.From<TDateTime>(StrToDateTimeDef(FValues.Items[Field.Name], 0))
  else if Hndle = TypeInfo(Word) then
    Value := TValue.From<Word>(StrToIntDef(FValues.Items[Field.Name], 0))
  else if Hndle = TypeInfo(Boolean) then
    Value := TValue.From<Boolean>(StrToBoolDef(FValues.Items[Field.Name], False))
  else if Hndle = TypeInfo(TColor) then
    Value := TValue.From<TColor>(StrToIntDef(FValues.Items[Field.Name], $7FFFFFFF))
  else if Hndle = TypeInfo(Double) then
    Value := TValue.From<Double>(StrToFloatDef(FValues.Items[Field.Name], 0))
  else
    Value := TValue.From<string>(FValues.Items[Field.Name]);
  Result := Value.AsType<T>;
end;

procedure TStorage.Save(const AMember: string; Value: TValue);
begin
  if not FDefaultValuesSetting then
    FStorager.Save(AMember, Value);
end;

procedure TStorage.SetDefaultValues;
begin

end;

procedure TStorage.SetValues(DefaultValues: Boolean);
var
  Field: TRttiField;
  Ctx: TRttiContext;
  Typ: TRttiType;
begin
  Ctx := TRttiContext.Create;
  Typ := Ctx.GetType(Self.ClassType);
  FValues := TDictionary<string, string>.Create;
  try
    if not DefaultValues then
      FStorager.Load(FValues);
    for Field in Typ.GetFields do
    begin
      if SetValueType<Integer>(Field, DefaultValues) then Continue
      else if SetValueType<string>(Field, DefaultValues) then Continue
      else if SetValueType<TDateTime>(Field, DefaultValues) then Continue
      else if SetValueType<Word>(Field, DefaultValues) then Continue
      else if SetValueType<Boolean>(Field, DefaultValues) then Continue
      else if SetValueType<TColor>(Field, DefaultValues) then Continue
      else if SetValueType<Double>(Field, DefaultValues) then Continue
    end;
    if DefaultValues then
    begin
      FDefaultValuesSetting := True;
      SetDefaultValues;
      FDefaultValuesSetting := False;
    end;
  finally
    FValues.Free;
  end;
end;

function TStorage.SetValueType<T>(Field: TRttiField; DefaultValues: Boolean): Boolean;
var
  cfgCrypt: Crypt;
  cfgProp: Prop<T>;
begin
  Result := False;
  if Field.FieldType.Handle = TypeInfo(Prop<T>) then
  begin
    cfgProp.Storage := Self;
    cfgProp.MemberName := Field.Name;
    if FValues.ContainsKey(Field.Name) then
    begin
      cfgProp.Value := GetValue<T>(Field);
      Field.SetValue(Self, TValue.From<Prop<T>>(cfgProp));
    end;
    if DefaultValues then
      Field.SetValue(Self, TValue.From<Prop<T>>(cfgProp));
    Result := True;
  end
  else if Field.FieldType.Handle = TypeInfo(Crypt) then
  begin
    cfgCrypt.Storage := Self;
    cfgCrypt.MemberName := Field.Name;
    if FValues.ContainsKey(Field.Name) then
    begin
      cfgCrypt.FValue := GetValue<string>(Field);
      Field.SetValue(Self, TValue.From<Crypt>(cfgCrypt));
    end;
    if DefaultValues then
      Field.SetValue(Self, TValue.From<Crypt>(cfgCrypt));
    Result := True;
  end;
end;

end.
