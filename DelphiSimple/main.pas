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
    function toString:string;
    function getRelativePos : real;
    procedure driveEmulation;
    function getLogStr:string;
    procedure setKReg(ckp,cki,ckpSp,ckiSp:real);
  public
   posStart : real;
   speed : real;
   speedStar : real;
   direct : integer;
   posStar : real;
  private
    dType : integer;
    adr : integer;
    sDrive : SewDrive;
    mDrive : ModbusDrive;
    pos : real;
    prevU : integer;
    u : integer;
    name : string;
    prevDir : integer;
    kp,ki : real;
    kpSp, kiSp : real;
    fifo : array[1..FIFO_LENGTH] of real;
    fifoSp : array[1..FIFO_LENGTH] of real;

    flgUControl : boolean;
    flgStopped : boolean;

    up : real;
    ui : real;
    ie : real;
    e : real;


    eSp : real;
    ieSp : real;
    upSp : real;
    uiSp : real;
  end;

  TForm1 = class(TForm)
    ComPort1: TComPort;
    Timer1: TTimer;
    ComPort2: TComPort;
    ComPort3: TComPort;
    OpenDialog1: TOpenDialog;
    LogIn: TMemo;
    srv: TServerSocket;
    LogOut: TMemo;
    Timer2: TTimer;
    Edit1: TEdit;
    Edit2: TEdit;
    Edit3: TEdit;
    Edit4: TEdit;
    Button1: TButton;
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    Label4: TLabel;
    Edit5: TEdit;
    Label5: TLabel;
    Button2: TButton;
    Button3: TButton;
    procedure ComPort1RxChar(Sender: TObject; Count: Integer);

    procedure Timer1Timer(Sender: TObject);

    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure ComPort3RxChar(Sender: TObject; Count: Integer);    
    procedure ComPort2RxChar(Sender: TObject; Count: Integer);
    procedure control;
    procedure srvAccept(Sender: TObject; Socket: TCustomWinSocket);
    procedure srvClientDisconnect(Sender: TObject;
      Socket: TCustomWinSocket);
    procedure srvClientRead(Sender: TObject; Socket: TCustomWinSocket);
    procedure processTCP(s : string);
    procedure sendStatsTCP();
    procedure Timer2Timer(Sender: TObject);
    procedure Button1Click(Sender: TObject);
    procedure Button2Click(Sender: TObject);
    procedure Button3Click(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;
  // создаём параллельный процесс
var
  Form1: TForm1;
  // переменная для проверки состояния кнопок по протоколу modbus
  maDrive : ModbusDrive;
  // переменные для принятия сообщений от ардуино
  posCom3 : integer = 0;
  c3Arr : array[0..26] of byte;
  flgFF : boolean = false;
  // переменные двигателей
  driveTK, driveLK, driveBL : CDrive;
  // флаг подключения tcp клиента
  flgConnected : boolean = false;
  // усилие для управения кнопками
  curU : integer = 2500;

  flgRunInNullPoint : integer = 0;

  f : textfile;

  tmWind : real = 0;
  flgWinding : boolean = false;

  tcpStr : string = '';

  sr : real = 500;

  fglSrEnable : boolean = false;

  uDirection : integer = DIRECT_LEFT;
implementation

uses Math;

{$R *.DFM}

function CDrive.getLogStr:string;
begin
  result :=  FloatToStr(pos)+' '+FloatTOStr(posStar)+' '+FloatTOStr(speed)+' '+FloatTOStr(speedStar)+' '+IntToStr(u)+
  ' '+FloatTOStr(up)+' '+FloatTOStr(ui)+' '+FloatToStr(e);

end;

function ByteToHex(InByte:byte):shortstring;
const Digits:array[0..15] of char='0123456789ABCDEF';
begin
 result:=digits[InByte shr 4]+digits[InByte and $0F];
end;


procedure logCom(flgIn : boolean; msg : string; comNum : integer);
var i : integer;
    str : string;
begin
   str := 'Com ' + IntTOStr(comNum);
   if flgIn then
    str := str + '> '
   else
    str := str + '< ';
   for i := 1 to length(msg) do
    str:= str + ByteToHex(ord(msg[i]))+' ';
  { if flgIn then
     Form1.LogIn.Lines.Add(str)
   else
     Form1.LogOut.Lines.Add(str)     }
end;

function CDrive.getRelativePos:real;
begin
result := pos-posStart;
end;

procedure CDrive.changeDirection(direction : integer);
begin
  if (direct<>DIRECT_STOP) then
    direct:= direction;
end;

procedure CDrive.setKReg(ckp,cki,ckpSp,ckiSp:real);
begin
  kp := ckp;
  ki := cki;
  kpSp := ckpSp;
  kiSp := ckiSp;
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
  prevU := 0;
  prevDir := DIRECT_STOP;
  posStart := 0;
  kp := ckp;
  ki := cki;
  for i := 1 to FIFO_LENGTH do
  begin
    fifo[i] := 0;
    fifoSp[i] := 0;
  end;
  kpSp := ckpSp;
  kiSp := ckiSp;
  flgUControl := true;
  pos := 0;
  flgStopped := false;
  stopDrive;
end;

function CDRIve.toString:string;
begin
 // result := name+': u='+IntToStr(u)+' v='+FloatToStr(speed)+' vS='+FloatToStr(speedStar)+' p='+FloatToStr(pos-posStart)+' ps='+FloatToStr(posStar);
  result := FloatToStr(posStar)+' ps='+FloatToStr(speedStar);
end;

procedure CDrive.processDrive;
var dir : integer;
    i : integer;
    uSp : real;
    tmpu : real;
begin
 if (speedStar=0) then
 begin
  stopDrive;
  //writeln('stopDrive');
 end
 else
  if flgUControl then
  begin
    if (direct<>DIRECT_STOP) then
    begin
      moveDrive(direct,round(speedStar));
      if name = 'TK' then
      begin
        if (maDrive.isPressed(PIN_LTG))then
        begin
          driveTK.changeDirection(DIRECT_RIGHT);
          uDirection :=   DIRECT_RIGHT;
        end;
        if (maDrive.isPressed(PIN_RTG))then
        begin
          driveTK.changeDirection(DIRECT_LEFT);
          uDirection :=   DIRECT_LEFT;
        end;
      end;
    end
    else
      stopDrive;
   // writeln('uControl '+IntTOStr(direct)+' '+intToStr(round(speedStar)));
  end
  else
  begin
    e := (posStar - (pos-posStart));
    up := e*kp;
    ie := fifo[1];
    for i := 2 to FIFO_LENGTH do
    begin
      ie := ie + fifo[i];
      fifo[i-1] := fifo[i];
    end;
    fifo[FIFO_LENGTH] := e;
   // if abs(e)<10 then
   // fglSrEnable := true;
    //ui := ie*ki;
    tmpu := up+ui;
    //if (fglSrEnable) then
   // begin
    if (tmpu>sr) then tmpu :=  sr;
     if (tmpu<-sr) then tmpu := -sr;
  //  end;
     eSp := (speedStar+tmpu) - speed;
     upSp := eSp*kpSp;

     if name='BL' then
     begin
      uSp := speedStar*4.4;
      if (speedStar>0) then dir := DIRECT_RIGHT
      else  dir := DIRECT_LEFT;
     end;
     if name = 'TK' then
     begin
      uSp := speedStar*1.45;
      if (speedStar>0) then dir := DIRECT_RIGHT
      else  dir := DIRECT_LEFT;
     end;
     if name = 'LK' then
     begin
      uSp := speedStar*4.85;
      if (speedStar>0) then dir := DIRECT_LEFT
      else  dir := DIRECT_RIGHT;
     end;
     uSp := uSp + upSp {+ uiSp};

    u := abs(round(uSp));
    if (u<0) then u := 0;
   // writeln('ui '+FloatToStr(ui)+' up '+FloatToStr(up)+' p='+FloatToStr(pos-posStart)+' ps='+FloatToStr(posStar));
    moveDrive(dir,u);
  end;
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
  prevU := 0;
  flgStopped := true;
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
 if (maDrive.isPressed(PIN_LTG))then
     driveTK.changeDirection(DIRECT_RIGHT);
 if (maDrive.isPressed(PIN_RTG))then
     driveTK.changeDirection(DIRECT_LEFT);


 if ( not maDrive.isPressed(PIN_RUN))   then
 begin

    driveBL.speedStar := curU;
    driveTK.speedStar := curU;
    driveLK.speedStar := curU;
   // кнопки баллона
   if (maDrive.isPressed(PIN_LBL) ) then
   begin
     driveBL.direct := DIRECT_LEFT;

     //writeln('Left');
   end
   else if (maDrive.isPressed(PIN_RBL) ) then
   begin
     driveBL.direct := DIRECT_RIGHT;
     //driveBL.speedStar := 1000;
    // writeln('Right');
   end
   else
   begin
     driveBL.direct := DIRECT_STOP;
    // driveBL.speedStar := 0;
  //   writeln('Stop');
   end;

   // кнопки верхней каретки
   if (maDrive.isPressed(PIN_LTK) ) then
     driveTK.direct := DIRECT_LEFT
   else if (maDrive.isPressed(PIN_RTK) ) then
     driveTK.direct := DIRECT_RIGHT
   else
     driveTK.direct := DIRECT_STOP;
   // кнопки нижней каретки
   if (maDrive.isPressed(PIN_LLK) ) then
     driveLK.direct := DIRECT_LEFT
   else if (maDrive.isPressed(PIN_RLK) ) then
     driveLK.direct := DIRECT_RIGHT
   else
     driveLK.direct := DIRECT_STOP;
 end
 else
 begin
      case flgRunInNullPoint of
        1 :
         if (maDrive.isPressed(PIN_RLG))then
         begin
             driveLK.direct := DIRECT_RIGHT;
             driveLK.speedStar := 2000;
             flgRunInNullPoint := 2;
         end
         else
         begin
            driveLK.direct := DIRECT_LEFT;
             driveLK.speedStar := 2000;
         end;
        2:
        if (maDrive.isPressed(PIN_LLG))then
        begin
          driveLK.direct := DIRECT_STOP;
          driveLK.posStart := driveLK.pos;
          driveBL.posStart := driveBL.pos;
          driveTK.posStart := driveTK.pos;
          flgRunInNullPoint := 0;
        end
        else
        begin
         driveLK.direct := DIRECT_RIGHT;
         driveLK.speedStar := 2000;
        end;
      end;
    end;

//    caption :=  driveBl.toString;
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


procedure CDrive.driveEmulation;
begin
 if (flgUControl) then
 begin
  if direct<> DIRECT_STOP then
  begin
    speed := speedStar/100 + Random(5)-2;
    if direct = DIRECT_RIGHT then
      speed  := -speed;
    pos := pos + speed;
  end;
 end
 else
 begin
    pos := posStar + random(20)-10;
    speed := speedStar + random(10)-5;
    //writeln(f,pos:2:2,' ',speed:2:2);
 end;
end;

procedure TForm1.sendStatsTCP();
var s : string;
begin
 if flgConnected then
 begin
  s := IntToStr( round(driveBl.pos))+ ' '+
       IntToStr( round(driveBl.speed))+ ' '+
      // IntToStr( round(driveBl.speedStar))+ ' '+
       IntToStr( round(driveTK.pos))+ ' '+
       IntToStr( round(driveTK.speed))+ ' '+
       //IntToStr( round(driveTK.speedStar))+ ' '+
       IntToStr( round(driveLK.pos))+ ' '+
       IntToStr( round(driveLK.speed))+ ' ' +
       BoolToStr(maDrive.isPressed(PIN_RUN))+' ';
      // IntToStr( round(driveLK.speedStar))+' ';
  srv.Socket.Connections[0].SendText(s);
 // LogOut.Lines.Add('TCP < '+s);
  //caption := s;
 end;
end;

procedure TForm1.Timer1Timer(Sender: TObject);
var str : string;
    i : integer;
    adr : integer;
begin
  str := maDrive.getReqStr;

 // logCom(false,str,COM_NUM_2);

  //Caption := IntToStr(driveLK.direct)+' '+FLoatToStr(driveLK.speedStar);
  control;
  //driveLK.driveEmulation;
  //driveBL.driveEmulation;
//  caption := FloatToStr(driveLK.speedStar)+' '+FloatToStr(driveLK.speed);
  driveBL.processDrive;
  driveTK.processDrive;
  driveLK.processDrive;
  writeln(f,driveBL.getLogStr+ ' ' +  driveTK.getLogStr+ ' ' + driveLK.getLogStr);
  sleep(30);
  ComPort2.WriteStr(str);
 // sleep(10);
//  caption := IntToStr(curU);
//  writeln(mDrive.getPinsStr);
 // Caption:=FloatToStr(driveLK.speedStar)+' '+IntTOStr(driveLK.direct);

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
  srv.Active := true;
 // AllocConsole;
  today := Time;
  str := 'log\'+StringReplace(DateToStr(today),'.','_',
                          [rfReplaceAll, rfIgnoreCase]) + '_'+  StringReplace(TimeToStr(today),':','_',
                          [rfReplaceAll, rfIgnoreCase])+'.txt';
  rewrite(f,str);
  tmWind := 0;

  DecimalSeparator  := '.';

end;

procedure TForm1.FormDestroy(Sender: TObject);
begin
  FreeConsole;
  ComPort1.Close;
  closefile(f);
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

function getFirstVal( var s : string):integer;
var valS : string;
begin
 while s[1]=' ' do
  delete(s,1,1);
 valS := copy(s,1,pos(' ',s)-1);
 delete(s,1,pos(' ',s));
 result := StrToInt(vals);
end;

procedure TForm1.processTCP(s : string);
var cmd : integer;
begin
 s := s+' ';
 //writeln(s);
  cmd := getFirstVal(s);
  case cmd of
    MOVE_DRIVE :
    begin
      driveBL.speedStar := getFirstVal(s);
      driveBL.direct := getFirstVal(s);
      driveTK.speedStar := getFirstVal(s);
      driveTK.direct := getFirstVal(s);
      if driveTK.direct<>DIRECT_STOP then
        driveTK.direct := uDirection;
      driveLK.speedStar := getFirstVal(s);
      driveLK.direct := getFirstVal(s);
      driveBL.flgUControl := true;
      driveTK.flgUControl := true;
      driveLK.flgUControl := true;
    end;
    SET_LK_POINT :
    begin
      driveLK.posStart := driveLK.pos;
      driveBL.posStart := driveBL.pos;
      driveTK.posStart := driveTK.pos;
    end;
    MOVE_TO_NULL_POINT:
    begin
      flgRunInNullPoint := 1;
    end;
    BUTTONS_SPEED:
      curU :=  getFirstVal(s);
    MOVE_DRIVE_POS:

    begin

      driveBL.posStar := getFirstVal(s);
      driveBL.speedStar := getFirstVal(s);
      driveTK.posStar := getFirstVal(s);
      driveTK.speedStar := getFirstVal(s);
   //   writeln(driveTK.posStar:2:0,' ',driveTK.speedStar:2:0);
      //caption := FloatToStr(driveTK.posStar)+' '+ FloatToStr(driveTK.speedStar);
      driveLK.posStar := getFirstVal(s);
      driveLK.speedStar := getFirstVal(s);
      //Form1.caption := FloatToStr(driveTK.speedStar)+' '+FloatToStr(driveTK.posStar);
      driveBL.flgUControl := false;
      driveTK.flgUControl := false;
      driveLK.flgUControl := false;
     // writeln(f,s,' : ',driveLK.speedStar:2:2,' ',driveLK.posStar:2:2);
      flgWinding := true;
     // flgWinding := true;
    end;
    STOP_DRIVE_POS:
    begin
      flgWinding := false;
      driveBL.flgUControl := true;
      driveTK.flgUControl := true;
      driveLK.flgUControl := true;
     // driveBL.speedStar :=0;
    //  driveTK.speedStar :=0;
     // driveLK.speedStar :=0 ;
     // driveLK.direct := DIRECT_STOP;
     // driveLK.direct := DIRECT_STOP;
     // driveLK.direct := DIRECT_STOP;
    end;

  end;
end;

procedure TForm1.srvAccept(Sender: TObject;
  Socket: TCustomWinSocket);
begin
  //logIn.Lines.Add('Подключился клиент с IP адресом '+Socket.RemoteAddress);
   flgConnected := true;
end;

procedure TForm1.srvClientDisconnect(Sender: TObject;
  Socket: TCustomWinSocket);
begin
  //logIn.Lines.Add('Клиент '+socket.RemoteAddress+' отключился от сервера.');
  flgConnected := false;
end;

procedure TForm1.srvClientRead(Sender: TObject; Socket: TCustomWinSocket);
var str : string;
begin
  str:=Socket.ReceiveText;
//  logIn.Lines.Add('TCP > '+str);
  processTCP(str);
end;


procedure TForm1.Timer2Timer(Sender: TObject);
begin
 sendStatsTCP;
end;

procedure TForm1.Button1Click(Sender: TObject);
begin
   driveLK.setKReg(StrToFloat(Edit1.text),StrToFloat(Edit2.text),StrToFloat(Edit3.text),StrToFloat(Edit4.text));
   sr := StrToFloat(edit5.text);
end;

procedure TForm1.Button2Click(Sender: TObject);
begin
 driveBL.stopDrive;
 driveTK.stopDrive;
 driveLK.stopDrive;
end;

procedure TForm1.Button3Click(Sender: TObject);
begin
  driveBL.moveDrive(DIRECT_LEFT,6000);
end;

end.

