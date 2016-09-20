{ 1 об - 4096 BL
  1 см - 1381 TK
  1 см - 62 LK
}
unit main;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  StdCtrls, ExtCtrls, CPort,Sew, Modbus, ScktComp;

const
  SEW_TYPE = 0;
  MODBUS_TYPE = 1;

  DIRECT_LEFT = 0;
  DIRECT_RIGHT = 1;
  DIRECT_STOP = 2;

  FIFO_LENGTH = 20;

  COM_NUM_1 = 1;
  COM_NUM_2 = 2;
  COM_NUM_3 = 3;

  MOVE_DRIVE = 1;
  SET_LK_POINT = 2;
  MOVE_TO_NULL_POINT = 3;
  BUTTONS_SPEED = 4;
  MOVE_DRIVE_POS = 5;
  STOP_DRIVE_POS = 6;
type

  CDrive = class
    constructor Create(cdType,cadr:integer; nm: string;ckp,cki,ckpSp,ckiSp:real);
    procedure processDrive;
    procedure stopDrive;
    procedure moveDrive(direction:integer; cspeed : integer);
    procedure changeDirection(direction : integer);
    procedure smartControl(dir : integer; sp : integer);
  public
   speed : integer;
   pos : integer;
   direct : integer;
   flgStopped : boolean;
   prevU : integer;
   prevDir : integer;
  private
    dType : integer;
    adr : integer;
    sDrive : SewDrive;
    mDrive : ModbusDrive;
    pressTime : integer;
    name : string;
    u : integer;
  end;

  TForm1 = class(TForm)
    ComPort1: TComPort;
    Timer1: TTimer;
    ComPort2: TComPort;
    ComPort3: TComPort;
    OpenDialog1: TOpenDialog;
    Timer2: TTimer;
    Button2: TButton;
    Button4: TButton;
    Button5: TButton;
    Edit1: TEdit;
    Label1: TLabel;
    Button1: TButton;
    Button3: TButton;
    Edit2: TEdit;
    Label2: TLabel;
    Button7: TButton;
    Edit3: TEdit;
    Label3: TLabel;
    Button6: TButton;
    procedure ComPort1RxChar(Sender: TObject; Count: Integer);
    procedure Timer1Timer(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure ComPort3RxChar(Sender: TObject; Count: Integer);    
    procedure ComPort2RxChar(Sender: TObject; Count: Integer);
    procedure control;
    procedure Button2Click(Sender: TObject);
    procedure Button4Click(Sender: TObject);
    procedure Button5Click(Sender: TObject);
    procedure Button1Click(Sender: TObject);
    procedure Button3Click(Sender: TObject);
    procedure Button7Click(Sender: TObject);
    procedure Button6Click(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;
  // создаЄм параллельный процесс
var
  Form1: TForm1;
  // переменна€ дл€ проверки состо€ни€ кнопок по протоколу modbus
  maDrive : ModbusDrive;
  // переменные дл€ прин€ти€ сообщений от ардуино
  posCom3 : integer = 0;
  c3Arr : array[0..26] of byte;
  flgFF : boolean = false;
  // переменные двигателей
  driveTK, driveLK, driveBL : CDrive;

implementation

uses Math;

{$R *.DFM}

function ByteToHex(InByte:byte):shortstring;
const Digits:array[0..15] of char='0123456789ABCDEF';
begin
 result:=digits[InByte shr 4]+digits[InByte and $0F];
end;

procedure CDrive.changeDirection(direction : integer);
begin
  if (direct<>DIRECT_STOP) then
    direct:= direction;
end;

constructor CDrive.Create(cdType,cadr:integer; nm: string;ckp,cki,ckpSp,ckiSp:real);
var i : integer;
begin
  dType := cdType;
  if (dType = SEW_TYPE) then
    sDrive := SewDrive.Create;
  if (dType = MODBUS_TYPE) then
    mDrive := ModbusDrive.Create;
  adr := cadr;
  direct := DIRECT_STOP;
  name := nm;
  flgStopped := false;
  stopDrive;
  prevU := 0;
  prevDir := DIRECT_STOP;
  pressTime := 0;
end;

procedure CDrive.processDrive;
var dir : integer;
    i : integer;
    uSp : real;
    tmpu : real;
begin
 if (u=0) then
  stopDrive
 else
  begin
    if (direct<>DIRECT_STOP) then
    begin
      moveDrive(direct,round(u));
    end
    else
      stopDrive;
  end

end;

procedure CDrive.stopDrive;
begin
if not flgStopped then
begin
  if dType=SEW_TYPE then
  begin
      Form1.ComPort1.WriteStr(sDrive.getStopString);
      Sleep(50);
      Form1.ComPort1.WriteStr(sDrive.getStopString);
  end;
  if dType = MODBUS_TYPE then
  begin
      Sleep(20);
      Form1.ComPort2.WriteStr(mDrive.getDirectionString(M_DIRECTION_STOP,adr));
  end;
end;
  direct :=  DIRECT_STOP;

  flgStopped := true;
end;

procedure CDrive.smartControl(dir : integer; sp : integer);
begin
  case dir of
    DIRECT_LEFT:
    begin
      if (direct=DIRECT_RIGHT)  then
        stopDrive
      else
      begin
        direct := DIRECT_LEFT;
        u := sp;
      end;
    end;
    DIRECT_RIGHT:
    begin
      if (direct=DIRECT_LEFT)  then
        stopDrive
      else
      begin
        direct := DIRECT_RIGHT;
        u := sp;
      end;
    end;
    DIRECT_STOP:
      stopDrive;
  end;
end;

procedure CDrive.moveDrive(direction:integer; cspeed : integer);
var dir : integer;
begin
 if (cspeed<>prevU)or(direction<>prevDir) then
 begin
  prevU := u;
  prevDir := direction;
  flgStopped := false;
  if dType=SEW_TYPE then
  begin
    if (direction = DIRECT_LEFT)  then dir := SEW_DIRECT_LEFT;
    if (direction = DIRECT_RIGHT) then dir := SEW_DIRECT_RIGHT;
    Form1.ComPort1.WriteStr(sDrive.getMoveString(dir,cspeed));
  end;
  if dType = MODBUS_TYPE then
  begin
      if (direction = DIRECT_LEFT) then dir := M_DIRECT_LEFT;
      if (direction = DIRECT_RIGHT) then dir := M_DIRECT_RIGHT;
      Sleep(30);
      Form1.ComPort2.writeStr(mDrive.getMoveString(cspeed,adr));
      Sleep(30);
      Form1.ComPort2.WriteStr(mDrive.getDirectionString(dir,adr));
  end;
 end;
end;

procedure TForm1.control;
var str : string; i:integer;
begin
 // герконы
{ if (mDrive.isPressed(PIN_LLG))then
     driveLK.changeDirection(DIRECT_LEFT);
 if (mDrive.isPressed(PIN_RLG))then
     driveLK.changeDirection(DIRECT_RIGHT);    }
// if (maDrive.isPressed(PIN_LTG))then
//     driveTK.changeDirection(DIRECT_RIGHT);
// if (maDrive.isPressed(PIN_RTG))then
 //    driveTK.changeDirection(DIRECT_LEFT);

 if ( not maDrive.isPressed(PIN_RUN))  then
 begin
   // кнопки баллона
   if(driveBL.pressTime>3) then
   if (maDrive.isPressed(PIN_LBL) ) then
   begin
      driveBL.smartControl(DIRECT_LEFT,StrToInt(Form1.Edit1.Text));
      driveBL.pressTime := 0;
   end
   else if (maDrive.isPressed(PIN_RBL) ) then
   begin
     driveBL.smartControl(DIRECT_RIGHT,StrToInt(Form1.Edit1.Text));
     driveBL.pressTime := 0;
   end;

   if(driveTK.pressTime>3) then
   if (maDrive.isPressed(PIN_LTK) ) then
   begin
      driveTK.smartControl(DIRECT_LEFT,StrToInt(Form1.Edit2.Text));
      driveTK.pressTime := 0;
   end
   else if (maDrive.isPressed(PIN_RTK) ) then
   begin
     driveTK.smartControl(DIRECT_RIGHT,StrToInt(Form1.Edit2.Text));
     driveTK.pressTime := 0;
   end;

   if(driveLK.pressTime>3) then
   if (maDrive.isPressed(PIN_LLK) ) then
   begin
      driveLK.pressTime := 0;
      driveLK.smartControl(DIRECT_LEFT,StrToInt(Form1.Edit3.Text));
   end
   else if (maDrive.isPressed(PIN_RLK) ) then
   begin
     driveLK.smartControl(DIRECT_RIGHT,StrToInt(Form1.Edit3.Text));
     driveLK.pressTime := 0;
   end;
 end
 else
 begin
   driveBL.direct := DIRECT_STOP;
   driveTK.direct := DIRECT_STOP;
   driveLK.direct := DIRECT_STOP;
 end;
  inc(driveBl.pressTime);
 inc(driveTK.pressTime);
 inc(driveLK.pressTime);
end;



procedure TForm1.ComPort1RxChar(Sender: TObject; Count: Integer);
var str,s : string;
    i : integer;
begin
  ComPort1.ReadStr(Str, Count);
  s := 'COM1> ';
  for i := 1 to Count do
       s:= s+ ByteToHex(ord(str[i]))+' ';
 // logCom(true,s,COM_NUM_3);
end;

procedure TForm1.Timer1Timer(Sender: TObject);
var str : string;
    i : integer;
    adr : integer;
begin
  sleep(30);
  str := maDrive.getReqStr;
  ComPort2.WriteStr(str);
  control;
  
  driveBL.processDrive;
  driveTK.processDrive;
  driveLK.processDrive;
end;

procedure TForm1.FormCreate(Sender: TObject);
var today : TDateTime;
    str: string;
begin
  ComPort1.Open;
  ComPort2.Open;
  ComPort3.Open;
  driveLK := CDrive.Create(SEW_TYPE,0,'LK',13,0.4,1.8,0.1 );
  driveTK := CDrive.Create(MODBUS_TYPE,TK_DRIVE,'TK',4,0.6,1,1);
  driveBL := CDrive.Create(MODBUS_TYPE,BL_DRIVE,'BL',15,0.5,1,0.1);
  maDrive := ModbusDrive.Create;
  DecimalSeparator  := '.';

end;

procedure TForm1.FormDestroy(Sender: TObject);
begin
  FreeConsole;
  ComPort1.Close;

end;

function getVal(start,stop : integer):integer;
var i : integer;
begin
   result := 0;
   for i := stop downto start+1 do
    result := result*100 + (c3Arr[i]div 16)*10+c3Arr[i] mod 16;
   if (c3Arr[start]=2) then
    result := -result;
end;

procedure processCom3(b : byte);
var i : integer;
    tmp : integer;

begin
  if (posCom3=0) then
  begin
    if (b=255) then
      flgFF := true
    else
    begin
      if(flgFF) then
      begin
        flgFF := false;
        posCom3 := 1;
        c3Arr[0] := b;
      end;
    end;
  end
  else
    if (posCom3<=27) then
    begin
      c3Arr[posCom3] := b;
      Inc(posCom3);
    end
    else
    begin
      driveBL.pos := getVal(0,3);
      driveTk.pos := getVal(4,7);
      driveLK.pos  := getVal(8,11);
      driveBl.speed  := getVal(12,15)*2;
      driveTK.speed := getVal(16,19)*10;
      driveLK.speed := getVal(20,23)*2;
      posCom3 := 0;
      flgFF := false;
    end;
end;


procedure TForm1.ComPort3RxChar(Sender: TObject; Count: Integer);
var str,s: String;
    i : integer;
begin
  ComPort3.ReadStr(Str, Count);
  for i := 1 to Count do
       processCom3(ord(str[i]));
  //logCom(true,str,COM_NUM_3);
end;

procedure TForm1.ComPort2RxChar(Sender: TObject; Count: Integer);
var str,s : string;
    i : integer;
begin
  ComPort2.ReadStr(Str, Count);
  for i := 1 to Count do
      maDrive.processData(ord(str[i]));
  //logCom(true,str,COM_NUM_3);
end;

procedure TForm1.Button2Click(Sender: TObject);
begin
 driveBL.stopDrive;
 driveTK.stopDrive;
 driveLK.stopDrive;
end;

procedure TForm1.Button4Click(Sender: TObject);
begin
  driveBl.smartControl(DIRECT_LEFT,StrToInt(Edit1.Text));
end;
         
procedure TForm1.Button5Click(Sender: TObject);
begin
   driveBl.smartControl(DIRECT_RIGHT,StrToInt(Edit1.Text));
end;

procedure TForm1.Button1Click(Sender: TObject);
begin
   driveTK.smartControl(DIRECT_LEFT,StrToInt(Edit2.Text));
end;

procedure TForm1.Button3Click(Sender: TObject);
begin
  driveTK.smartControl(DIRECT_RIGHT,StrToInt(Edit2.Text));
end;

procedure TForm1.Button7Click(Sender: TObject);
begin
  driveLK.smartControl(DIRECT_RIGHT,StrToInt(Edit3.Text));
end;

procedure TForm1.Button6Click(Sender: TObject);
begin
  driveLK.smartControl(DIRECT_LEFT,StrToInt(Edit3.Text));
end;

end.

