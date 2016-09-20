{ 1 об - 4096 BL
  1 см - 1381 TK
  1 см - 62 LK
}
unit main;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  StdCtrls, ExtCtrls, ScktComp, Unit2;

const
  DIRECT_LEFT = 0;
  DIRECT_RIGHT = 1;
  DIRECT_STOP = 2;

  MOVE_DRIVE = 1;
  SET_LK_POINT = 2;
  MOVE_TO_NULL_POINT = 3;
  BUTTONS_SPEED = 4;
  MOVE_DRIVE_POS = 5;
  STOP_DRIVE_POS =6 ;
type

  TForm1 = class(TForm)
    Button1: TButton;
    Edit1: TEdit;
    Edit2: TEdit;
    Edit4: TEdit;
    Edit5: TEdit;
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    Label5: TLabel;
    Edit6: TEdit;
    Label6: TLabel;
    Edit7: TEdit;
    Edit8: TEdit;
    Edit9: TEdit;
    Edit10: TEdit;
    Edit11: TEdit;
    Edit12: TEdit;
    Edit16: TEdit;
    Edit17: TEdit;
    Edit18: TEdit;
    Label7: TLabel;
    Label8: TLabel;
    Label9: TLabel;
    Label10: TLabel;
    Label11: TLabel;
    Label12: TLabel;
    Client: TClientSocket;
    Timer1: TTimer;
    Button3: TButton;
    Button4: TButton;
    Edit13: TEdit;
    Label13: TLabel;
    Edit14: TEdit;
    Button6: TButton;
    Button2: TButton;
    Button5: TButton;
    Button7: TButton;
    Edit15: TEdit;
    Label14: TLabel;
    CheckBox2: TCheckBox;
    Edit19: TEdit;
    Label15: TLabel;
    Edit3: TEdit;
    Label4: TLabel;
    Edit20: TEdit;
    Edit21: TEdit;
    Label16: TLabel;
    Label17: TLabel;
    Button8: TButton;
    Edit22: TEdit;
    Label18: TLabel;
    Edit23: TEdit;
    Label19: TLabel;
    Button10: TButton;
    Edit24: TEdit;
    Label20: TLabel;
    CheckBox3: TCheckBox;
    CheckBox4: TCheckBox;
    Label21: TLabel;
    Label22: TLabel;
    Label23: TLabel;
    Label24: TLabel;
    Button9: TButton;
    procedure FormCreate(Sender: TObject);
    procedure Button2Click(Sender: TObject);
    procedure setParamsGL();
    procedure ClientRead(Sender: TObject; Socket: TCustomWinSocket);
    procedure processTCP(s : string);
    procedure Timer1Timer(Sender: TObject);
    procedure Button3Click(Sender: TObject);
    procedure Button1Click(Sender: TObject);
    procedure sendDriveTCP;
    procedure diplayVals;
    procedure Button4Click(Sender: TObject);
    procedure Button6Click(Sender: TObject);
    procedure Button5Click(Sender: TObject);
    procedure Button7Click(Sender: TObject);
    procedure Button8Click(Sender: TObject);
    procedure Button9Click(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure Button10Click(Sender: TObject);
    procedure startTK;
  private
    { Private declarations }
  public
    { Public declarations }
  end;

    // создаём параллельный процесс

var
  Form1: TForm1;


  flgRun : boolean = false;
  spCnt : integer;
  curSpCnt : integer;
  flgLeft : boolean = true;
  prevPosLK : integer =0;

  flgStopped : boolean = false;
  flgWind : boolean = false;
  flgFirestWind : boolean = true;
  flgUnWinding : boolean = false;
  stm : integer = 0;
  timeToStop : integer = 0;  

  flgSetStartPos :boolean= true;

  f : textfile;

  wCnt : integer = 1;
  curWCnt : integer = 0;
  flgWindEnable : boolean = false;

  kTK : real = 1;
  curWCntTK : integer = 0;
  wCntTK : integer = 0;
  lTK : integer  = 500;
  posStartBLforTK : integer = 0;

  flgIdentification : boolean = false;
  identTime : real = 0;
  curSp : real = 0;
  curIdentTime : real = 200;
implementation


{$R *.DFM}

procedure stopWind;
begin
  directBL := DIRECT_STOP;
  directTK := DIRECT_STOP;
  directLK := DIRECT_STOP;
  flgRun := false;
  flgStopped := true;
  flgWind := false;
end;


procedure startWind;
begin
 //  Client.Socket.SendText(IntToStr(SET_LK_POINT));
  directBL := DIRECT_RIGHT;
  directLK := DIRECT_LEFT;
  flgRun := true;
  if (flgFirestWind) then
  begin
     posStartLK := posLK;
     flgFirestWind := false;
  end
  else
     posStartLK := posStartLK + posLK - prevPosLK;
//  writeln( posLK - prevPosLK );
  stm := 0;
  flgWind := true;
end;


procedure TForm1.setParamsGL;
begin
 setParams( StrToInt(Edit1.Text),
            StrToInt(Edit2.Text),
            StrToInt(Edit4.Text),
            StrToInt(Edit19.Text),
            StrToInt(Edit5.Text),
            StrToInt(Edit6.Text) );
 curSpCnt   := StrToInt(Edit13.Text);
 timeToStop := StrToInt(Edit19.Text);
 logLkCnt := 0;
 kTK := StrToInt(Edit22.Text)/100;
// tmWind := 0;
end;


procedure TForm1.FormCreate(Sender: TObject);
begin
  Client.Open;
  posLK:= 0;
  posTK:= 0;
  posBL := 0;
  speedLK := 0;
  speedBL := 0;
  speedTK := 0;
  curSpCnt :=0;
  directBL := DIRECT_STOP;
  directTK := DIRECT_STOP;
  directLK := DIRECT_STOP;
  flgStopped := false;
  allocConsole;

  spCnt := 0;

  setParamsGL;

  rewrite(f,'tmp.txt');

end;


procedure TForm1.Button2Click(Sender: TObject);
begin
  Client.Socket.SendText('Test');
  curSpCnt := spCnt;
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
var b : boolean;
    st : string;
begin
 s := s+' ';
// caption := s;       s
 posBL := getFirstVal(s);
 speedBL := getFirstVal(s);
 //speedStarBL := getFirstVal(s);
 posTK := getFirstVal(s);
 speedTK := getFirstVal(s);
 //speedStarTK := getFirstVal(s);
 posLK := getFirstVal(s)-posStartLK;
 speedLK := getFirstVal(s);
 //writeln(pos(' ',s));
 //writeln( copy(s,1,pos(' ',s)-1));
 b := StrToBool(copy(s,1,pos(' ',s)-1));
 //caption := s;
 if (flgSetStartPos) then
 begin
  posStartTK := posTK;
  posStartBL := posBL;
  flgSetStartPos := false;
 end;
 if flgWindEnable then
 begin
   if (flgWind) and( not b) then
   begin
    StopWind;
    writeln('Stop');
   end;
  if (not flgWind) and(b) then
   begin
   StartWind;
   writeln('start');
   end;
  flgWind := b;
 end;
// speedStarLK := getFirstVal(s);

end;

procedure TForm1.ClientRead(Sender: TObject; Socket: TCustomWinSocket);
var str : string;
begin
  str:=Socket.ReceiveText;
  processTCP(str);
end;

procedure processDrive;
var tmpSp, tmpPos : real;
begin
  if (flgWind)and(wCntTK>=curWCntTK) then
  begin
    curWCntTK := 0;
    Form1.CheckBox4.Checked :=false;
  end;
  if (flgWind)and(wCnt>=curWCnt) then
  begin
    curWCnt := 0;
    Form1.CheckBox3.Checked :=false;
  end;


  if (flgWind)and(Form1.CheckBox3.Checked) then
    speedStarLK := round(getValSp(FloatMod(tmWind,tW)))
  else
    speedStarLK := 0;

  posStarLK := round(getVal(FloatMod(tmWind,tW)));

  if (flgWind) then
    speedStarBL := round(getValSpBL(FloatMod(tmWind,tW)))
  else
    speedStarBL := 0;
  posStarBL := round(getValBL(FloatMod(tmWind,tW)));

  addToLogLK(tmWind,posLK,speedLK,posBL-posStartBL,speedBl);

 { if (flgWind)and(Form1.CheckBox3.Checked) then
    speedStarTK := round(getValSpTK(FloatMod(tmWind,tW)))
  else
    speedStarTK := 0;

  posStarTK := round(getValTK(tmWind,));       }

  if (Form1.CheckBox4.Checked) then
  begin
    if (wCntTK mod 2= 0) then
    begin
      speedStarTK := round(abs(speedStarBL)*kTK);
      posStarTK :=round((posBL-posStartBLforTK)*KTk+posStartTK);
    end
    else
    begin
      speedStarTK := - round((speedStarBL)*kTK);
      posStarTK :=round(lTK-(posBL-posStartBLforTK)*KTk+posStartTK);
    end;
    if (posBL-posStartBLforTK)*KTk>lTK then
      begin
        inc(wCntTK);
        posStartBLforTK := posBL;
      end;
//    writeln(kTk:4:6,' ',speedStarTK,' ',posStarTK);
//    Form1.caption := FloatToStr(posBL-posStartBLforTK)+' '+FloatToStr(tmpSp)+' ' + FloatToStr(tmpPos);
  end
  else
  begin
     speedStarTK := 0;
     posStarTK := posTK;
  end;
    // speedStarTK := 0;
    // posStarTK := posTK;

  //addToLogLK(tmWind,posLK,speedLK,round(FloatMod(posStarBL,windAngle)),speedBl);

  Form1.sendDriveTCP;
end;

procedure TForm1.sendDriveTCP ;
var s : string;
    tmp : integer;
begin
  if (flgWind) then
  begin

    s := IntToStr( MOVE_DRIVE_POS)+ ' '+
       IntToStr(posStarBL+posStartBL)+' ' +
       IntToStr(speedStarBL)+' ' +
       IntToStr(posStarTK)+' ' +
       IntToStr(speedStarTK)+' ' +
       IntToStr(posStarLK)+' '+
       IntToStr(speedStarLK)+' ' ;
//   writeln(posBL,' ',posStartBL,' ', posStarBL+posStartBL);
  end
  else
   if (flgIdentification) then
   begin
      tmp := round(round(identTime/8)/(round(curIdentTime/8))*1000)  ;
      writeln(tmp);
      if tmp mod 80 = 0 then
      begin
       s := IntToStr( MOVE_DRIVE)+ ' '+
       IntToStr(tmp*6)+' ' +
       IntToStr(DIRECT_LEFT)+' ' +
       IntToStr(tmp*6)+' ' +
       IntToStr(DIRECT_LEFT)+' ' +
       IntToStr(tmp*7)+' '+
       IntToStr(DIRECT_LEFT)+' ' ;
      end
      else
      begin
       s := IntToStr( MOVE_DRIVE)+ ' '+
       IntToStr(0)+' ' +
       IntToStr(DIRECT_STOP)+' ' +
       IntToStr(0)+' ' +
       IntToStr(DIRECT_STOP)+' ' +
       IntToStr(0)+' '+
       IntToStr(DIRECT_STOP)+' ' ;
      end;
   end
   else
     s:= IntToStr(STOP_DRIVE_POS)+' ';
  caption := s;
  Client.Socket.SendText(s);
  writeln(f,s);
  //writeln( );
end;

procedure TForm1.diplayVals;
begin
   Edit7.Text := IntToStr(posBL);
   Edit10.Text := IntToStr(speedBL);
   Edit16.Text := IntToStr(speedStarBL);

   Edit8.Text := IntToStr(posTK);
   Edit11.Text := IntToStr(speedTK);
   Edit17.Text := IntToStr(speedStarTK);

   Edit9.Text := IntToStr(posLK);
   Edit12.Text := IntToStr(speedLK);
   Edit18.Text := IntToStr(speedStarLK);
  // Label13.Caption := IntTOStr(spCnt);
   Label14.Caption := IntToStr(posStartLK);

   Edit3.Text := FloatToStr(encoderToGrad(windAngle));
   Edit20.Text := FloatToStr(encoderToGrad(cAngle));
   Edit21.Text := FloatToStr(encoderToGrad(sAngle));

   Refresh;
   Label13.Caption := IntTOStr(wCnt);
   Label21.Caption := IntTOStr(wCntTK);
end;

procedure TForm1.Timer1Timer(Sender: TObject);
begin
  if CheckBox2.Checked then
  begin
     directBL := DIRECT_LEFT;
     speedStarBL := 6000;
     directLK := DIRECT_STOP;
  end
  else
    processDrive;
  diplayVals;
  //caption := IntToStr(spCnt);
  if (flgStopped) and( abs(speedLK)<5) then
  begin
    prevPosLK := posLK;
    flgStopped := false;
  end;
  if (flgWind) then
    tmWind := tmWind + Timer1.Interval/1000;
  //caption :=  IntToStr(posBl)+' '+IntToStr(posStartBL);
  if ((Form1.CheckBox3.Checked)or(Form1.CheckBox4.Checked))then
  begin
    if(tmWind>tW*wCnt) then
    begin
      posStartBL :=   posStartBL+trunc(windAngle);
    // posStartBLforTK := posStartBLforTK + trunc(windAngle);
      Inc(wCnt);
      if (wCnt>=curWCnt) then
      begin
        curWCnt := 0;
        Form1.CheckBox3.Checked :=false;
      end;
    end;
  end
  else
  begin
      if flgWind then
      begin
        flgWindEnable := false;
        stopWind;
      end;
  end;
  if  flgIdentification then
  begin
     if (identTime<curIdentTime) then
      identTime := identTime + Timer1.Interval/1000
     else
     begin
       flgIdentification := false;
        Client.Socket.SendText(IntToStr(STOP_DRIVE_POS)+' ')
     end;
  end;

end;

procedure TForm1.Button3Click(Sender: TObject);
begin
   flgWindEnable := false;
   stopWind;
   CheckBox3.Checked := false;
  CheckBox4.Checked := false;
end;

procedure TForm1.startTK;
begin
  wCntTK := 0;
  curWCntTK := StrToInt(Edit23.text);
  kTK :=  StrToInt(Edit22.text)/100;
  lTK :=  StrToInt(Edit24.text);
  posStartBLforTK := posBL;
  posStartTK := posTK;
end;

procedure TForm1.Button1Click(Sender: TObject);
begin
  flgWindEnable := true;
  curWCnt :=  StrToInt(Edit13.Text);
  curWCntTK := StrToInt( Edit23.Text);
  startTK;
  CheckBox3.Checked := true;
  CheckBox4.Checked := true;
  posStartBL := posBL;
end;

procedure TForm1.Button4Click(Sender: TObject);
begin
  Client.Socket.SendText(IntToStr( MOVE_TO_NULL_POINT)+ ' ');
end;

procedure TForm1.Button6Click(Sender: TObject);
begin
  Client.Socket.SendText(IntToStr(BUTTONS_SPEED)+' '+Edit14.Text);
end;


procedure TForm1.Button5Click(Sender: TObject);
var f : textfile;
    i : integer;
begin
  setParamsGL;
end;

procedure TForm1.Button7Click(Sender: TObject);
begin
  posStartLK := posStartLK + StrToInt(Edit15.Text);
end;

procedure TForm1.Button8Click(Sender: TObject);
begin
  posStartLK := posLk;
  posStartBL := posBL;
  tmWind := 0;
end;

procedure TForm1.Button9Click(Sender: TObject);
begin
  flgIdentification := true;
  identTime := 0;
end;

procedure TForm1.FormDestroy(Sender: TObject);
begin
 closefile(f);
 Client.Close;
end;



procedure TForm1.Button10Click(Sender: TObject);
begin
  startTK;
end;

end.

