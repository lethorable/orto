unit InOutUtil;

{$MODE Delphi}

interface

Type InOutPoint = Record
               x,y : double;
             end;


var

    PPA: Array[1..9] of InOutPoint;
    PPA_i : integer;

Function InsidePoly(x,y:real):boolean;

implementation

Function InsidePoly(x,y:real):boolean;
var i,j : integer;
    inside: boolean;
Begin
  inside:=false;
  j:=1;
  For i:=1 to PPA_i do
  begin
    inc(j);
    if j = PPA_i+1 then j:=1;
    if (((PPA[i].y<y) and (PPA[j].y>=y)) or ((PPA[j].y<y) and (PPA[i].y>=y))) then
    if PPA[i].x+(y-PPA[i].y)/(PPA[j].y-PPA[i].y)*(PPA[j].x-PPA[i].x) <x then
    if inside = false then inside:=true else
    if inside = true then inside:=false;
  end;
  InsidePoly:=inside;
end;

end.