unit Modbus;

interface

const M_DIRECT_RIGHT = 4;
      M_DIRECT_LEFT  = 2;
      M_DIRECTION_STOP = 1;
      M_FREQ_K = 0.01;
      LK_DRIVE = 1;
      TK_DRIVE = 2;
      BL_DRIVE = 3;
      READ_ANSW = 1;
      WRITE_ANSW = 2;

      PIN_LBL = 10;   // кнопка баллон влево
      PIN_RBL = 9;  // кнопка баллон вправо
      PIN_LTK = 16;  // кнопка верхн€€ каретка влево
      PIN_RTK = 14;  // кнопка верхн€€ каретка вправо
      PIN_LLK = 13;  // кнопка верхн€€ нижн€€ влево
      PIN_RLK = 12;  // кнопка верхн€€ нижн€€ вправо
      PIN_LTG = 4;   // левый верхний геркон
      PIN_RTG = 1;   // правый верхний геркон
      PIN_LLG = 5;   // левый нижний геркон
      PIN_RLG = 8;   // левый верхний геркон
      PIN_RUN = 11;  // кнопка работы станка

(* Table of CRC values for high-order byte *)
auchCRCHi:array[0..255] of byte=(
$00, $C1, $81, $40, $01, $C0, $80, $41, $01, $C0,
$80, $41, $00, $C1, $81, $40, $01, $C0, $80, $41,
$00, $C1, $81, $40, $00, $C1, $81, $40, $01, $C0,
$80, $41, $01, $C0, $80, $41, $00, $C1, $81, $40,
$00, $C1, $81, $40, $01, $C0, $80, $41, $00, $C1,
$81, $40, $01, $C0, $80, $41, $01, $C0, $80, $41,
$00, $C1, $81, $40, $01, $C0, $80, $41, $00, $C1,
$81, $40, $00, $C1, $81, $40, $01, $C0, $80, $41,
$00, $C1, $81, $40, $01, $C0, $80, $41, $01, $C0,
$80, $41, $00, $C1, $81, $40, $00, $C1, $81, $40,
$01, $C0, $80, $41, $01, $C0, $80, $41, $00, $C1,
$81, $40, $01, $C0, $80, $41, $00, $C1, $81, $40,
$00, $C1, $81, $40, $01, $C0, $80, $41, $01, $C0,
$80, $41, $00, $C1, $81, $40, $00, $C1, $81, $40,
$01, $C0, $80, $41, $00, $C1, $81, $40, $01, $C0,
$80, $41, $01, $C0, $80, $41, $00, $C1, $81, $40,
$00, $C1, $81, $40, $01, $C0, $80, $41, $01, $C0,
$80, $41, $00, $C1, $81, $40, $01, $C0, $80, $41,
$00, $C1, $81, $40, $00, $C1, $81, $40, $01, $C0,
$80, $41, $00, $C1, $81, $40, $01, $C0, $80, $41,
$01, $C0, $80, $41, $00, $C1, $81, $40, $01, $C0,
$80, $41, $00, $C1, $81, $40, $00, $C1, $81, $40,
$01, $C0, $80, $41, $01, $C0, $80, $41, $00, $C1,
$81, $40, $00, $C1, $81, $40, $01, $C0, $80, $41,
$00, $C1, $81, $40, $01, $C0, $80, $41, $01, $C0,
$80, $41, $00, $C1, $81, $40
);

(* Table of CRC values for low-order byte *)
auchCRCLo:array[0..255]of byte = (
$00, $C0, $C1, $01, $C3, $03, $02, $C2, $C6, $06,
$07, $C7, $05, $C5, $C4, $04, $CC, $0C, $0D, $CD,
$0F, $CF, $CE, $0E, $0A, $CA, $CB, $0B, $C9, $09,
$08, $C8, $D8, $18, $19, $D9, $1B, $DB, $DA, $1A,
$1E, $DE, $DF, $1F, $DD, $1D, $1C, $DC, $14, $D4,
$D5, $15, $D7, $17, $16, $D6, $D2, $12, $13, $D3,
$11, $D1, $D0, $10, $F0, $30, $31, $F1, $33, $F3,
$F2, $32, $36, $F6, $F7, $37, $F5, $35, $34, $F4,
$3C, $FC, $FD, $3D, $FF, $3F, $3E, $FE, $FA, $3A,
$3B, $FB, $39, $F9, $F8, $38, $28, $E8, $E9, $29,
$EB, $2B, $2A, $EA, $EE, $2E, $2F, $EF, $2D, $ED,
$EC, $2C, $E4, $24, $25, $E5, $27, $E7, $E6, $26,
$22, $E2, $E3, $23, $E1, $21, $20, $E0, $A0, $60,
$61, $A1, $63, $A3, $A2, $62, $66, $A6, $A7, $67,
$A5, $65, $64, $A4, $6C, $AC, $AD, $6D, $AF, $6F,
$6E, $AE, $AA, $6A, $6B, $AB, $69, $A9, $A8, $68,
$78, $B8, $B9, $79, $BB, $7B, $7A, $BA, $BE, $7E,
$7F, $BF, $7D, $BD, $BC, $7C, $B4, $74, $75, $B5,
$77, $B7, $B6, $76, $72, $B2, $B3, $73, $B1, $71,
$70, $B0, $50, $90, $91, $51, $93, $53, $52, $92,
$96, $56, $57, $97, $55, $95, $94, $54, $9C, $5C,
$5D, $9D, $5F, $9F, $9E, $5E, $5A, $9A, $9B, $5B,
$99, $59, $58, $98, $88, $48, $49, $89, $4B, $8B,
$8A, $4A, $4E, $8E, $8F, $4F, $8D, $4D, $4C, $8C,
$44, $84, $85, $45, $87, $47, $46, $86, $82, $42,
$43, $83, $41, $81, $80, $40
);

type
  modArr = array[0..7] of byte;
  VMessage   = array [0..255] of byte;
  PVMessage  = ^Vmessage;
  bArr = array[0..11] of byte;

  ModbusDrive = class
  public
    function getMoveString(speed : integer;addres:byte):string;
    function getDirectionString(direction:byte; addres:byte):string;
    procedure processData(b:byte);
    constructor Create;
    function getReqStr:string;
    function getVal:integer;
    function isPressed(pn : byte):boolean;
    function getPinsStr:string;
  private
    algPos :integer;
    inArr : bArr;
    flgCalcCBB : boolean;
    algMode : integer;
    val : integer;
    pins : array[0..26] of boolean;
    function getAnswerString(a:VMessage):string;
    procedure processInData();
  end;
  function crc16(Start:byte; UsDataLen:byte; PMes:PVMessage):word;

implementation

function ModbusDrive.getPinsStr:string;
var s : string;
    i : integer;
begin
  s := '';
  for i := 1 to 16 do
    if pins[i] then
      s := s+'1 '
    else
      s := s+'0 ';
  result := s;
end;

function ModbusDrive.isPressed(pn : byte):boolean;
begin
 result := pins[pn];
end;

function ModbusDrive.getReqStr:string;
var b:VMessage;
    i : integer;
    s : string;
    crc : Word;
begin
  s := '';
  b[0] := 16;
  b[1] := 3;
  b[2] := 0;
  b[3] := 51;
  b[4] := 0;
  b[5] := 1;

  crc := crc16(0,5,@b);
  b[6] := crc div 256;
  b[7]:= crc mod 256;

  for i := 0 to 7 do
  begin
    s := s+chr(b[i]);
  end;
  result := s;
end;

function ModbusDrive.getVal:integer;
begin
    result := val;
end;

constructor ModbusDrive.Create;
var i : integer;
begin
   algPos := 0;
   flgCalcCBB := false;
   algMode := 0;
   for i := 1 to 16 do
     pins[i] := false;
end;

procedure ModbusDrive.processInData();
var i : integer;
    tmpVaL : INTEGER;
begin
  if (algMode = 1) then
  begin
    //writeln(val);
    val := inArr[3]*256+inArr[4];
    tmpVal := val;
    for i := 1 to 16 do
    begin
      pins[i] := (tmpVal mod 2<>0);
      tmpVal := tmpVal div 2;
    end;

  end;
end;

procedure ModbusDrive.processData(b:byte);
begin
 inArr[algPos] := b;
 if (algPos=1) then
    case b of
      3: algMode := READ_ANSW;
      6: algMode := WRITE_ANSW;
    end;
 Inc(algPos);
 if ((algPos=7)and(algMode=READ_ANSW))or
    ((algPos=8)and(algMode=WRITE_ANSW)) then
 begin
  algPos := 0;
  processInData;
 end;
end;

function crc16(Start:byte; UsDataLen:byte; PMes:PVMessage):word;
var
   i:word;
   uIndex:byte ; (* will index into CRC lookup*)
   uchCRCHi : byte;
   uchCRCLo :byte;
begin
   uchCRCHi := $FF ; (* high CRC byte initialized *)
   uchCRCLo := $FF ; (* low CRC byte initialized  *)
   for i:=Start to UsDataLen do
  begin
    uIndex := uchCRCHi xor PMes^[i] ;      (* calculate the CRC*)
    uchCRCHi := uchCRCLo xor auchCRCHi[uIndex] ;
    uchCRCLo := auchCRCLo[uIndex] ;
  end;
       crc16:= (uchCRCHi shl 8 or uchCRCLo) ;
end;


function ModbusDrive.getAnswerString(a:VMessage):string;
var i, crc : integer;

begin
  crc := crc16(0,5,@a);
  a[6] := crc div 256;
  a[7]:= crc mod 256;
  for i := 0 to 7 do
    result := result+chr(a[i]);
end;

function ModbusDrive.getDirectionString(direction:byte; addres:byte):string;
var b : VMessage;
     num : integer;
begin
  if (addres=LK_DRIVE) then
    num := 5056+direction
  else
    num := direction;
  b[0] := addres;
  b[1] := 6;
  b[2] := 0;
  b[3] := 5;
  b[4] := num div 256;
  b[5] := num mod 256;
  result := getAnswerString(b);
end;

function ModbusDrive.getMoveString(speed : integer;addres:byte):string;
var b : VMessage;
begin
  b[0] := addres;
  b[1] := 6;
  b[2] := 0;
  b[3] := 4;
  b[4] := speed div 256;
  b[5] := speed mod 256;
  result := getAnswerString(b);
end;

end.
