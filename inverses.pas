unit inverses;

{$mode delphi}


//http://www.cg.info.hiroshima-cu.ac.jp/~miyazaki/knowledge/teche23.html

interface
type mat2d = array[1..2,1..2] of extended;
type mat3d = array[1..3,1..3] of extended;

procedure invert2d(a:mat2d;var a_inv:mat2d);
procedure invert3d(a:mat3d;var a_inv:mat3d);

implementation

uses
  Classes, SysUtils;



procedure invert2d(a:mat2d;var a_inv:mat2d);
var q : extended;
    aa,bb,cc,dd:extended;
begin
  aa:=a[1,1]; bb:=a[1,2];
  cc:=a[2,1]; dd:=a[2,2];
  q:=1/(aa*dd-bb*cc);
  a_inv[1,1]:=dd*q;
  a_inv[1,2]:=-bb*q;
  a_inv[2,1]:=-cc*q;
  a_inv[2,2]:=aa*q;
end;


procedure invert3d(a:mat3d;var a_inv:mat3d);
var det : extended;
    tA  : mat3d;
begin
  det:= (a[1,1]*a[2,2]*a[3,3])+
       (a[2,1]*a[3,2]*a[1,3])+
       (a[3,1]*a[1,2]*a[2,3])-
       (a[1,1]*a[3,2]*a[2,3])-
       (a[3,1]*a[2,2]*a[1,3])-
       (a[2,1]*a[1,2]*a[3,3]);


  ta[1,1]:= (a[2,2]*a[3,3]-a[2,3]*a[3,2])/det; ta[1,2]:=(a[1,3]*a[3,2]-a[1,2]*a[3,3])/det; ta[1,3]:=(a[1,2]*a[2,3]-a[1,3]*a[2,2])/det;
  ta[2,1]:= (a[2,3]*a[3,1]-a[2,1]*a[3,3])/det; ta[2,2]:=(a[1,1]*a[3,3]-a[1,3]*a[3,1])/det; ta[2,3]:=(a[1,3]*a[2,1]-a[1,1]*a[2,3])/det;
  ta[3,1]:= (a[2,1]*a[3,2]-a[2,2]*a[3,1])/det; ta[3,2]:=(a[1,2]*a[3,1]-a[1,1]*a[3,2])/det; ta[3,3]:=(a[1,1]*a[2,2]-a[1,2]*a[2,1])/det;

  a_inv:=ta;
end;



end.

