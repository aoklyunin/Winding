unit Unit2;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, main,openGL,Matr, ExtCtrls;

const MAX_POINT_CNT = 100;
      tMat=0.00001;{������������ �����, ������� � ����, �� ��� ������}
      MAX_LENGTH = 100000000;
type
  TForm2 = class(TForm)
    Timer1: TTimer;
    procedure FormCreate(Sender: TObject);
    procedure FormPaint(Sender: TObject);
    procedure Timer1Timer(Sender: TObject);
  private
    { Private declarations }
  public
    hrc:HGLRC; // �������� ������� "hrc:HGLRC" � ������ "private"
    DC : HDC;  // � ��� ���� ������� (Device Context)
  end;

  GPoint = class
    constructor Create(tx, ta, tt : real);
    procedure paint;
  public
    x, a, t : real;
  end;

  GPart = class
     procedure paint;
     constructor Create(a,b,c : GPoint);
     function getAq(t : real) : real;
     function getAqp(t : real) : real;
     function getXq(t : real) : real;
     function getXqp(t : real): real;
  private
     ak : array[1..4] of real;
     xk : array[1..4] of real;

     flgX, flgA : boolean;
  public
     tb,te : real;
  end;

var
  Form2: TForm2;
  points : array[0..MAX_POINT_CNT] of GPoint;
  parts : array[1..MAX_POINT_CNT] of GPart;
  tm : array[0..MAX_POINT_CNT] of real;
  pointCnt : integer;
  timeLength : real;
  maxG, minG : real;
  flgStarted : boolean;
  xU, aU : array[1..MAX_LENGTH] of real;
  uXpos : integer = 0;
  uApos : integer = 0;
implementation

{$R *.dfm}

function GPart.getAq(t : real) : real;
begin
 result := ak[1]+ak[2]*t+ak[3]*t*t+ak[4]*t*t*t;
end;
function GPart.getAqp(t : real) : real;
begin
 result := ak[2]+2*ak[3]*t+3*ak[4]*t*t;
end;
function GPart.getXq(t : real) : real;
begin
 result := xk[1]+xk[2]*t+xk[3]*t*t+xk[4]*t*t*t;
end;
function GPart.getXqp(t : real) : real;
begin
 result := xk[2]+2*xk[3]*t+3*xk[4]*t*t;
end;


procedure SetDCPixelFormat (hdc : HDC);     // ��� ��������� ������� ������� ��������
var pfd : TPixelFormatDescriptor;           // �� ����� ��������� �������� ������
    nPixelFormat : Integer;
begin
 FillChar (pfd, SizeOf (pfd), 0);
 // ��������� ������ ��������� ��������� � ����, �������� ��������� ����������� ������
 // OpenGL � �������� ������� ����������� (����� ����������� �� �������)
 pfd.dwFlags  := PFD_DRAW_TO_WINDOW or PFD_SUPPORT_OPENGL or PFD_DOUBLEBUFFER;
 nPixelFormat := ChoosePixelFormat (hdc, @pfd);
 SetPixelFormat (hdc, nPixelFormat, @pfd);
end;


constructor GPoint.Create(tx, ta, tt : real);
begin
  x := tx;
  a := ta;
  t := tt;
end;

function VtoGL(v: real):real;
begin
  result := v/(maxG-minG)*1.8-0.9;
end;

function TtoGL(v: real):real;
begin
   result := v/timeLength*1.8-0.9;
end;

procedure GPoint.paint;
var px, pa, pt : real;
begin
  px := VtoGL(x);
  pa := VtoGL(a);
  pt := TtoGL(t);
  glColor3f(1,0.5,0.5);
  glBegin(GL_LINES);
    glVertex2f(pt-0.01,px-0.01);
    glVertex2f(pt+0.01,px+0.01);
    glVertex2f(pt+0.01,px-0.01);
    glVertex2f(pt-0.01,px+0.01);
  glEnd;
  glColor3f(0.5,0.5,1);
  glBegin(GL_LINES);
    glVertex2f(pt-0.01,pa-0.01);
    glVertex2f(pt+0.01,pa+0.01);
    glVertex2f(pt+0.01,pa-0.01);
    glVertex2f(pt-0.01,pa+0.01);
  glEnd;
end;

constructor GPart.Create(a,b,c : GPoint);
var q : array [1..4] of real;
    k,j,i,p:integer;{n-������ �������,k-������� �� �������,j-������� �� ��������,p-������� ������������}
    matA, matB ,e : TMatr;
    det,det1:real;{det-������������ �������� �������,det1-������������-����������}
    f:byte;{������� ��������������� �������� �������}
begin
  flgA := false;
  flgX := false;
  matA[1,1] := 1;  matA[1,2] := a.t;  matA[1,3] := a.t*a.t;  matA[1,4] := a.t*a.t*a.t;
  matA[2,1] := 0;  matA[2,2] := 1;    matA[2,3] := 2*a.t;    matA[2,4] := 3*a.t*a.t;
  matA[3,1] := 1;  matA[3,2] := b.t;  matA[3,3] := b.t*b.t;  matA[3,4] := b.t*b.t*b.t;
  matA[4,1] := 0;  matA[4,2] := 1;    matA[4,3] := 2*b.t;    matA[4,4] := 3*b.t*b.t;
  for i := 1 to 4 do
  begin
    for j := 1 to 4 do
    begin
      if matA[i,j] = 0 then matA[i,j] :=  tMat;
    end;
  end;
  Opr(4,p,matA,det,f); {vychislenie opredelitelja}{������� ������������}
  if f=1 then ShowMessage('�� ���������� �������� �������');
  Transp(matA,4,matB);  {������������� �������}
  Peresch(4,p,matB,det1,e);  {������� ����������}
  for k:=1 to 4 do
  for j:=1 to 4 do
    e[k,j]:=e[k,j]/det; {������� �������� �������}
  q[1] := a.a; // q0
  q[2] := (b.a-a.a)/(b.t-a.t);// qp0
  q[3] := b.a;// q1
  q[4] := (c.a-b.a)/(c.t-b.t); // qp1
  for i := 1 to 4 do
  begin
    ak[i] := 0;
    for j := 1 to 4 do
      ak[i] := ak[i]+e[i,j]*q[j];
    if (ak[i]<-100000) or (ak[i]>100000) then
      flgA := true;
  end;
  if (flgA) then
  begin
    ak[1] := -a.t*(b.a-a.a)/(b.t-a.t)+a.a;
    ak[2] := (b.a-a.a)/(b.t-a.t);
    ak[3] := 0;
    ak[4] := 0;
  end;
  q[1] := a.x; // q0
  q[2] := (b.x-a.x)/(b.t-a.t);// qp0
  q[3] := b.x;// q1
  q[4] := (c.x-b.x)/(c.t-b.t); // qp1

  for i := 1 to 4 do
  begin
    xk[i] := 0;
    for j := 1 to 4 do
      xk[i] := xk[i]+e[i,j]*q[j];
    if (xk[i]<-100000) or (xk[i]>100000) then
      flgX := true;
  end;
  if (flgX) then
  begin
    xk[1] := -a.t*(b.x-a.x)/(b.t-a.t)+a.x;
    xk[2] := (b.x-a.x)/(b.t-a.t);
    xk[3] := 0;
    xk[4] := 0;
  end;
  tb := a.t;
  te := b.t;
end;

procedure GPart.paint;
var i : integer;
    val : real;
begin
   glColor3f(1,0.8,0.8);
  glBegin(GL_LINE_STRIP);
  for i := round(tb) to round(te) do
  begin
     val := ak[1]+ ak[2]*i+ak[3]*i*i+ak[4]*i*i*i;
     glVertex2f(TtoGL(i),VtoGL(val));
  end;
  glEnd;
   glColor3f(0.8,0.8,1);
  glBegin(GL_LINE_STRIP);
  for i := round(tb) to round(te) do
  begin
     val := xk[1]+ xk[2]*i+xk[3]*i*i+xk[4]*i*i*i;
     glVertex2f(TtoGL(i),VtoGL(val));
  end;
  glEnd;

end;


procedure TForm2.FormCreate(Sender: TObject);
begin
  DC := GetDC (Handle);                   // �������� �������� ����������
  SetDCPixelFormat(DC);                   // ���������� ������ ��������
 // hrc := wglCreateContext(DC);            // ������� ��������� �� �������� ���� �����
 // wglMakeCurrent(DC, hrc);                // ������� ����� ������� ����������� ���������
  hrc := wglCreateContext(Form2.DC);
  wglMakeCurrent(Form2.DC, Form2.hrc);

  flgStarted := false;
end;


procedure TForm2.FormPaint(Sender: TObject);
var i : integer;
begin
  glViewPort(0,0,ClientWidth,ClientHeight); // ���������, ����� ����� ������ �����
           // �������������� ��� ����������� "��������" OpenGL (������ - ���� �����)
  glClearColor(0.2,0.2,1.0,1);  // ������ ���� ������� ������ (��� ������� RGB, �� 0 �� 1)
  glClear(GL_COLOR_BUFFER_BIT+GL_DEPTH_BUFFER_BIT);    // ������� ����� ����� � Z-�����
  glEnable(GL_DEPTH_TEST);              // �������� ����� ������������ ������� ��������
  glLoadIdentity;
  if (flgStarted) then
  begin
    for i := 0 to pointCnt do
      points[i].paint;
    for i := 1 to pointCnt do
      parts[i].paint;
     glColor3f(0.3,1,0.3);
    glBegin(GL_LINE_STRIP);
    for i := 1 to uXpos do
      glVertex2f(TtoGL(i*0.1),VtoGL(xU[i]));
  //  writeln(xU[uXpos],' ',VtoGL(xU[uXpos]));
    glEnd;
    glColor3f(1,0.3,0.3);
    glBegin(GL_LINE_STRIP);
      for i := 1 to uApos do
        glVertex2f(TtoGL(i*0.1),VtoGL(aU[i]));
    glEnd;
  end;
  SwapBuffers(Form2.DC);           // ������ ������� ������ (��� ����� ������ ��������)

end;

procedure TForm2.Timer1Timer(Sender: TObject);
begin
  InvalidateRect(form2.Handle,nil,False); // ���� ���������� �������������� ���� �� �������
end;

end.

