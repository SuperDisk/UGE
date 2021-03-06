unit Utils;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Song, Waves, HugeDatatypes, Constants, gHashSet, fgl, instruments, math;

function Lerp(v0, v1, t: Double): Double;
function Snap(Value, Every: Integer): Integer;
function ReMap(Value, Istart, Istop, Ostart, Ostop: Double): Double;
function IntReMap(Value, Istart, Istop, Ostart, Ostop: Integer): Integer;
function ConvertWaveform(Waveform: TWave): T4bitWave;
procedure BlankPattern(Pat: PPattern);
procedure BlankCell(var Cell: TCell);
function EffectCodeToStr(Code: Integer; Params: TEffectParams): String;
function EffectToExplanation(Code: Integer; Params: TEffectParams): String;
//function UniqueOrdersDuringPlayback(Song: TSong; FromPos, ToPos: Integer): Integer;

function ModInst(Inst: Integer): Integer;
function UnmodInst(Bank: TInstrumentType; Inst: Integer): Integer;
function InstBankName(Bank: TInstrumentType): String;

implementation

function Lerp(v0, v1, t: Double): Double;
begin
  Result := ((1 - t) * v0) + (t * v1);
end;

function Snap(Value, Every: Integer): Integer;
begin
  Result := Trunc(Value/Every)*Every;
end;

function ReMap(Value, Istart, Istop, Ostart, Ostop: Double): Double;
begin
  Result := ostart + ((ostop - ostart) * ((value - istart) / (istop - istart)));
end;

function IntReMap(Value, Istart, Istop, Ostart, Ostop: Integer): Integer;
begin
  Result := Trunc(ReMap(Value, Istart, Istop, Ostart, Ostop));
end;

function ConvertWaveform(Waveform: TWave): T4bitWave;
var
  I: Integer;
  J: Integer;
begin
  for I := 0 to 15 do begin
    J := I*2;
    Result[I] := (Waveform[J] shl 4) or (Waveform[J+1]);
  end;
end;

procedure BlankPattern(Pat: PPattern);
var
  I: Integer;
begin
  for I := 0 to High(Pat^) do begin
    Pat^[I] := Default(TCell);
    Pat^[I].Note := NO_NOTE;
  end;
end;

procedure BlankCell(var Cell: TCell);
begin
  Cell := Default(TCell);
  Cell.Note := NO_NOTE;
end;

function EffectCodeToStr(Code: Integer; Params: TEffectParams): String;
begin
  Result := HexStr((Code shl 8) or Params.Value, 3);
end;

function EffectToExplanation(Code: Integer; Params: TEffectParams): String;
var
  P: String;
begin
  Result := 'No explanation';
  P := IntToStr(Params.Value);
  case Code of
    $0: Result := 'Arpeggiate by +'+IntToStr(Params.Param1)+', +'+IntToStr(Params.Param2)+' semitones';
    $1: Result := 'Slide up by '+P+' units';
    $2: Result := 'Slide down by '+P+' units';
    $3: Result := 'Tone portamento by '+P+' units';
    $5: Result := 'Set Left speaker vol to '+IntToStr(Params.Param1)+', Right speaker vol to '+IntToStr(Params.Param2);
    $6: Result := 'Call routine #'+P;
    $7: Result := 'Delay note by '+P+' ticks';
    $A: Result := 'Increase volume by '+IntToStr(Params.Param1)+' units, decrease volume by '+IntToStr(Params.Param2)+' units';
    $B: Result := 'Jump to order '+P;
    $C: begin
      if (Params.Value < 16) then Result := 'Keep envelope, Set volume to '+IntToStr(Params.Param2)+'/15'
      else if (Params.Value < 128) then Result := 'Envelope Down '+IntToStr(Params.Param1)+'/64Hz, Set volume to '+IntToStr(Params.Param2)+'/15'
      else if (Params.Value < 144) then Result := 'Envelope Off, Set volume to '+IntToStr(Params.Param2)+'/15'
      else Result := 'Envelope Up '+IntToStr(Params.Param1-8)+'/64Hz, Set volume to '+IntToStr(Params.Param2)+'/15'
    end;
    $D: Result := 'Jump to row '+P+' on the next pattern';
    $E: Result := 'Cut note after '+P+' ticks';
    $F: Result := 'Set speed to '+P+' ticks';
  end;
end;

{function UniqueOrdersDuringPlayback(Song: TSong; FromPos, ToPos: Integer
  ): Integer;
var
  Seen: array of Integer;
  CurOrder, CurRow: Integer;
  OrderChanged: Boolean;
  NextOrder, NextRow: Integer;
  OrderCount, TotalSeenOrders: Integer;
  Cell: TCell;
  I: Integer;
  Pat: TPattern;
begin
  CurOrder := FromPos;
  CurRow := 0;
  OrderChanged := True;
  TotalSeenOrders := 0;

  with Song do
    OrderCount := MaxIntValue([High(OrderMatrix[0]), High(OrderMatrix[1]),
      High(OrderMatrix[2]), High(OrderMatrix[3])]);

  SetLength(Seen, OrderCount);

  NextOrder := -1;
  NextRow := -1;
  repeat
    if OrderChanged then begin
      OrderChanged := False;
      Inc(Seen[CurOrder]);
      Inc(TotalSeenOrders);
    end;

    for I := 0 to 3 do begin
      Pat := Song.Patterns[Song.OrderMatrix[I, CurOrder]]^;
      Cell := Pat[CurRow];
      case Cell.EffectCode of
        $B: NextOrder := Max(Cell.EffectParams.Value-1, OrderCount-1);
        $D: NextRow := Cell.EffectParams.Value;
      end;
    end;

    if NextOrder = -1 then
      NextOrder := CurOrder;

    if NextRow = -1 then
      NextRow := CurRow + 1;

    if NextRow > High(TPattern) then begin
      NextRow := 0;
      NextOrder := CurOrder + 1;
    end;

    if NextOrder > OrderCount-1 then begin
      OrderChanged := True;
      NextOrder := 0;
    end;

    if CurOrder <> NextOrder then
      OrderChanged := True;

    CurOrder := NextOrder;
    CurRow := NextRow;
    NextOrder := -1;
    NextRow := -1;
    writeln(CurOrder, ' ', curRow);
  until (Seen[CurOrder] > 1) or (CurOrder = ToPos);

  Result := TotalSeenOrders;
end;}

function ModInst(Inst: Integer): Integer;
begin
  Result := ((Inst-1) mod 15)+1;
end;

function UnmodInst(Bank: TInstrumentType; Inst: Integer): Integer;
begin
  case Bank of
    itSquare: Result := Inst+(15*0);
    itWave: Result := Inst+(15*1);
    itNoise: Result := Inst+(15*2);
  end;
end;

function InstBankName(Bank: TInstrumentType): String;
begin
  case Bank of
    itSquare: Result := 'Square';
    itWave: Result := 'Wave';
    itNoise: Result := 'Noise';
  end;
end;

end.

