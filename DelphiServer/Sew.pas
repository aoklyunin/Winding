unit Sew;

interface

const SEW_DIRECT_RIGHT = 0;
      SEW_DIRECT_LEFT  = 1;
      SEW_ARR_LENGTH = 9;
      SEW_FREQ_K =0.2;
type
  sewArr = array[0..SEW_ARR_LENGTH] of byte;

  SewDrive = class
  public
    function getStopString:string;
    function getMoveString(direction:byte; speed : integer):string;
  private
    function calcCBB(inArr:sewArr;length:integer):byte;
    function getAnswerString(a:sewArr):string;
  end;

implementation

function SewDrive.calcCBB(inArr:sewArr;length:integer):byte;
var curCBB:byte;
    i : integer;
begin
  curCBB := inArr[0];
  for i := 1 to length-1 do
  begin
    curCBB := curCBB XOR inArr[i];
  end;
  result := curCBB;
end;

function SewDrive.getAnswerString(a:sewArr):string;
var i : integer;
begin
  a[SEW_ARR_LENGTH] := calcCBB(a, SEW_ARR_LENGTH);
  for i := 0 to SEW_ARR_LENGTH do
    result := result + chr(a[i]);
end;

function SewDrive.getStopString:string;
var a : sewArr;
    i : integer;
begin
  result := '';
  a[0] := $02;
  a[1] := $00;
  a[2] := $85;
  a[3] := $00;
  a[4] := $00;
  a[5] := $00;
  a[6] := $00;
  a[7] := $00;
  a[8] := $00;
  result := getAnswerString(a);
end;

function SewDrive.getMoveString(direction:byte; speed : integer):string;
var h,l : byte;
    a : sewArr;
begin
  if (direction = SEW_DIRECT_RIGHT) then
    speed := -speed;
  h := Hi(speed);
  l := Lo(speed);
  a[0] := $02;
  a[1] := $00;
  a[2] := $85;
  a[3] := $0;
  a[4] := 06;
  a[5] := h;
  a[6] := l;
  a[7] := $00;
  a[8] := $00;
  result := getAnswerString(a);
end;

end.
