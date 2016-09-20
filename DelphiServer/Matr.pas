unit Matr;

interface

const tMat=0.00001;{������������ �����, ������� � ����, �� ��� ������}

type
  Tmatr=array[1..4,1..4]of real;


procedure Per(n,k:integer;a:Tmatr;var p:integer);{������������ ����� � ����. ������� ���������}
function znak(p:integer):integer;{��������� ����� ��� ������������ ����� �������}
function znak1(i,m:integer):integer;{��������� ����� ��� ������������ ����� ��� ���������� ����������}
procedure opr(n,p:integer;a:Tmatr;var det:real;var f:byte);{���������� ������������ �������}
procedure opr1(n,p:integer;d:Tmatr;var det1:real);{���������� ����������� ��� ����������}
Procedure Peresch(n,p:integer;var b:Tmatr;det1:real;var e:Tmatr);{���������� ����������}
procedure Transp(a:Tmatr; n:integer;var at:Tmatr);{���������������� �������}


implementation

procedure Per(n,k:integer;a:Tmatr;var p:integer);{������������ ����� � ����. ������� ���������}
var z:real;
    j,i:integer;
begin
  z:=abs(a[k,k]);
  i:=k;
  p:=0;
  for j:=k+1 to n do
  begin
    if abs(a[j,k])>z then
      begin
        z:=abs(a[j,k]);
        i:=j;
        p:=p+1;
      end;
  end;
  if i>k then
  for j:=k to n do
   begin
     z:=a[i,j];
     a[i,j]:=a[k,j];
     a[k,j]:=z;
   end;
end;

function znak(p:integer):integer;{��������� ����� ��� ������������ ����� �������}
begin
  if p mod 2=0 then
    znak:=1
  else
    znak:=-1;
end;

function znak1(i,m:integer):integer;{��������� ����� ��� ������������ ����� ��� ���������� ����������}
begin
  if (i+m) mod 2=0 then
    znak1:=1
  else
    znak1:=-1;
end;

procedure opr(n,p:integer;a:Tmatr;var det:real;var f:byte);{���������� ������������ �������}
var k,i,j:integer;
    r:real;
begin
det:=1.0;f:=0;
for k:=1 to n do
   begin
     if a[k,k]=0 then per(k,n,a,p);
     det:=znak(p)*det*a[k,k];
     if abs(det)<tMat then
      begin
       f:=1;
       writeln('�������� ������� ���!');
       readln;
       exit;
      end;
     for j:=k+1 to n do
        begin
         r:=a[j,k]/a[k,k];
         for i:=k to n do
         a[j,i]:=a[j,i]-r*a[k,i];
        end;
   end;
end;
procedure opr1(n,p:integer;d:Tmatr;var det1:real);{���������� ����������� ��� ����������}
var k,i,j:integer;
    r:real;
begin
det1:=1.0;
for k:=2 to n do
   begin
     if d[k,k]=0 then per(n,k,d,p);
     det1:=znak(p)*det1*d[k,k];
     for j:=k+1 to n do
       begin
         r:=d[j,k]/d[k,k];
         for i:=k to n do
         d[j,i]:=d[j,i]-r*d[k,i];
       end;
   end;
end;

Procedure Peresch(n,p:integer;var b:Tmatr;det1:real;var e:Tmatr);{���������� ����������}
var i,m,k,j:integer;
    z:real;
    d,c:Tmatr;
begin
for i:=1 to n do
for m:=1 to n do
   begin
     for j:= 1 to n do {������������ �����}
       begin
         z:=b[i,j];
         for k:=i downto 2 do
         d[k,j]:=b[k-1,j];
         for k:=i+1 to n do
         d[k,j]:=b[k,j];
         d[1,j]:=z;
       end;
     for k:=1 to n do {������������ ��������}
       begin
         z:=d[k,m];
         for j:=m downto 2 do
         c[k,j]:=d[k,j-1];
         for j:=m+1 to n do
         c[k,j]:=d[k,j];
         c[k,1]:=z;
       end;
     Opr1(n,p,c,det1);{���������� �������������}
     e[i,m]:=det1*znak1(i,m);{���������� ����������}
   end;
end;

procedure Transp(a:Tmatr; n:integer;var at:Tmatr);{���������������� �������}
var k,j:integer;
begin
for k:= 1 to n do
for j:=1 to n do
at[k,j]:=a[j,k];
end;


end.

