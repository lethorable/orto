unit imageinterpolationu;

{$mode delphi}

interface

uses
  Classes, SysUtils,

  constants;

Procedure InterpolatePixelInImage8(ocol,orow:Extended;var Pix:pixel8);
Procedure InterpolatePixelInImageTherm(ocol,orow:Extended;var Pix:real);
Procedure InterpolatePixelInImage16(ocol,orow:Extended;var Pix:pixel16);


implementation


Procedure InterpolatePixelInImage8(ocol,orow:Extended;var Pix:pixel8);
var  PAT : array[1..4] of pixel8;
     distCol,distRow:extended;
     a,b : integer;
     cnst : real;
     tocol,torow:integer;
     ppp:pixel8;
     rrr,ggg,bbb,ccc:real;
     av : real;

//START of local procedures
    function validate(fff:real):byte;
    begin
      if fff>255 then validate:=255 else
      if fff<0 then validate:=0 else
      validate:=round(fff);
    end;

    function P(X:real):real;
    begin
      if x>0 then p:=x else p:=0;
    end;

    Function Bet(X:real):real;
    begin
      If  (x<=1) then
      begin
        bet:=0.5*x*x*x-x*x+(2/3); //B-spline
        exit;
      end;
      if ((1<x) and(x<=2)) then
      begin
        bet:=(-1/6)*x*x*x+x*x-2*x+(4/3); //B-spline
        exit;
      end;
      if x>2 then bet:=0;
    end;

    function R(X:real):real;
    begin
      If  (x<=1) then
      begin
        R:=(av+2)*x*x*x-(av+3)*x*x+1; //Bicub 1-var
        exit;
      end;
      if ((1<x) and(x<=2)) then
      begin
        R:=av*x*x*x-5*av*x*x+8*av*x-4*av; // bicub 1-var
        exit;
      end;
      if x>2 then R:=0;
    end;
//End of local procedures


begin
  //Bilinear interpolation...:
  tocol:=trunc(ocol);
  torow:=trunc(orow);
  distCol:=ocol-tocol;
  distRow:=orow-torow;

  if interpol=2 then   //Bikubic interpolation
  begin
    av:=PolParam; //This is read from parameter file
    rrr:=0;
    ggg:=0;
    bbb:=0;
    ccc:=0;
    for a:=-1 to 2 do
    for b:=-1 to 2 do
    begin
      cnst:=R(abs(a-distcol))*R(abs(distrow-b));
      rrr:=rrr+(BA8[tocol+a,torow+b].r *cnst);
      ggg:=ggg+(BA8[tocol+a,torow+b].g *cnst);
      bbb:=bbb+(BA8[tocol+a,torow+b].b *cnst);
      ccc:=ccc+(BA8[tocol+a,torow+b].c *cnst);
    end;
    pix.r:=validate(rrr);
    pix.g:=validate(ggg);
    pix.b:=validate(bbb);
    pix.c:=validate(ccc);
    if almostblackvalue then
    begin
      if pix.r = 0 then pix.r:=1;
      if pix.g = 0 then pix.g:=1;
      if pix.b = 0 then pix.b:=1;
      if pix.c = 0 then pix.c:=1;
    exit;
    end
  end else

  if interpol=3 then // Beta spline interpolation
  begin
    rrr:=0;
    ggg:=0;
    bbb:=0;
    ccc:=0;
    for a:=-1 to 2 do
    for b:=-1 to 2 do
    begin
      cnst:=Bet(abs(a-distcol))*Bet(abs(distrow-b));
      rrr:=rrr+(BA8[tocol+a,torow+b].r *cnst);
      ggg:=ggg+(BA8[tocol+a,torow+b].g *cnst);
      bbb:=bbb+(BA8[tocol+a,torow+b].b *cnst);
      ccc:=ccc+(BA8[tocol+a,torow+b].c *cnst);
    end;
    pix.r:=validate(rrr);
    pix.g:=validate(ggg);
    pix.b:=validate(bbb);
    pix.c:=validate(ccc);
    if almostblackvalue then
    begin
      if pix.r = 0 then pix.r:=1;
      if pix.g = 0 then pix.g:=1;
      if pix.b = 0 then pix.b:=1;
      if pix.c = 0 then pix.c:=1;
    exit;
    end
  end else

  If interpol=1 then  //Bilinear interpolation
  begin
    PAT[1]:=  BA8[tocol,torow];
    PAT[2]:=BA8[tocol+1,torow];
    PAT[3]:=BA8[tocol,torow+1];
    PAT[4]:=BA8[tocol+1,torow+1];

    pix.r:= round(  (1-distcol)*(1-DistRow)*Pat[1].r
                   + distCol*(1-distrow)*PAT[2].r
                   + distRow*(1-distCol)*PAT[3].r
                   + distCol*distRow*PAT[4].r   );

    pix.g:= round(  (1-distcol)*(1-DistRow)*Pat[1].g
                   + distCol*(1-distrow)*PAT[2].g
                   + distRow*(1-distCol)*PAT[3].g
                   + distCol*distRow*PAT[4].g   );

    pix.b:= round(  (1-distcol)*(1-DistRow)*Pat[1].b
                   + distCol*(1-distrow)*PAT[2].b
                   + distRow*(1-distCol)*PAT[3].b
                   + distCol*distRow*PAT[4].b   );

    pix.c:= round(  (1-distcol)*(1-DistRow)*Pat[1].c
                   + distCol*(1-distrow)*PAT[2].c
                   + distRow*(1-distCol)*PAT[3].c
                   + distCol*distRow*PAT[4].c   );


    if almostblackvalue then
    begin
      if pix.r = 0 then pix.r:=1;
      if pix.g = 0 then pix.g:=1;
      if pix.b = 0 then pix.b:=1;
      if pix.c = 0 then pix.c:=1;

    exit;
    end
  end else
  if interpol=0 then  //Direct interpolation
  begin
    Pix.r:=BA8[round(ocol),round(orow)].r;
    Pix.g:=BA8[round(ocol),round(orow)].g;
    Pix.b:=BA8[round(ocol),round(orow)].b;
    Pix.c:=BA8[round(ocol),round(orow)].c;
    if almostblackvalue then
    begin
      if pix.r = 0 then pix.r:=1;
      if pix.g = 0 then pix.g:=1;
      if pix.b = 0 then pix.b:=1;
      if pix.c = 0 then pix.c:=1;
    end
  end;
end;


Procedure InterpolatePixelInImageTherm(ocol,orow:Extended;var Pix:real);
var  PAT : array[1..4] of real;
     distCol,distRow:extended;
     a,b : integer;
     cnst : real;
     tocol,torow:integer;
     ppp:real;
     rrr,ggg,bbb,ccc:real;
     av : real;

    function P(X:real):real;
    begin
      if x>0 then p:=x else p:=0;
    end;

    Function Bet(X:real):real;
    begin
      If  (x<=1) then
      begin
        bet:=0.5*x*x*x-x*x+(2/3); //B-spline
        exit;
      end;
      if ((1<x) and(x<=2)) then
      begin
        bet:=(-1/6)*x*x*x+x*x-2*x+(4/3); //B-spline
        exit;
      end;
      if x>2 then bet:=0;
    end;

    function R(X:real):real;
    begin
      If  (x<=1) then
      begin
        R:=(av+2)*x*x*x-(av+3)*x*x+1; //Bicub 1-var
        exit;
      end;
      if ((1<x) and(x<=2)) then
      begin
        R:=av*x*x*x-5*av*x*x+8*av*x-4*av; // bicub 1-var
        exit;
      end;
      if x>2 then R:=0;
    end;


begin
  tocol:=trunc(ocol);
  torow:=trunc(orow);
  distCol:=ocol-tocol;
  distRow:=orow-torow;

  if interpol=2 then   //Bikubisk interpolation
  begin
    av:=PolParam; 
    rrr:=0;
    ggg:=0;
    bbb:=0;
    ccc:=0;
    for a:=-1 to 2 do
    for b:=-1 to 2 do
    begin
      cnst:=R(abs(a-distcol))*R(abs(distrow-b));
      rrr:=rrr+(thermBA[tocol+a,torow+b] *cnst);
    end;
    pix:=(rrr);
    if almostblackvalue then
    begin
      if pix < -200 then pix:=-999;
    exit;
    end
  end else

  if interpol=3 then // Beta spline interpolation
  begin
    rrr:=0;
    ggg:=0;
    bbb:=0;
    ccc:=0;
    for a:=-1 to 2 do
    for b:=-1 to 2 do
    begin
      cnst:=Bet(abs(a-distcol))*Bet(abs(distrow-b));
      rrr:=rrr+(ThermBA[tocol+a,torow+b] *cnst);
    end;
    pix:=(rrr);
    if almostblackvalue then
    begin
      if pix <-200 then pix:=-999;
    exit;
    end
  end else

  If interpol=1 then  //Bilinear interpolation
  begin
    PAT[1]:=  ThermBA[tocol,torow];
    PAT[2]:=ThermBA[tocol+1,torow];
    PAT[3]:=ThermBA[tocol,torow+1];
    PAT[4]:=ThermBA[tocol+1,torow+1];

    pix:=     (  (1-distcol)*(1-DistRow)*Pat[1]
                   + distCol*(1-distrow)*PAT[2]
                   + distRow*(1-distCol)*PAT[3]
                   + distCol*distRow*PAT[4]   );
    if almostblackvalue then
    begin
      if pix <-200 then pix:=-999;
    exit;
    end
  end else
  if interpol=0 then  //Direct interpolation
  begin
    Pix:=ThermBA[round(ocol),round(orow)];
    if almostblackvalue then
    begin
      if pix <-200 then pix:=-999;
    end
  end;
end;


Procedure InterpolatePixelInImage16(ocol,orow:Extended;var Pix:pixel16);
var  PAT : array[1..4] of pixel16;
     distCol,distRow:extended;
     a,b : integer;
     cnst : real;
     tocol,torow:integer;
     ppp:pixel16;
     rrr,ggg,bbb,ccc:real;
     av : real;

//START local procedures
    function validate(fff:real):word;
    begin
      if fff>65535 then validate:=65535 else
      if fff<0 then validate:=0 else
      validate:=round(fff);
    end;

    function P(X:real):real;
    begin
      if x>0 then p:=x else p:=0;
    end;

    Function Bet(X:real):real;
    begin
      If  (x<=1) then
      begin
        bet:=0.5*x*x*x-x*x+(2/3); //B-spline
        exit;
      end;
      if ((1<x) and(x<=2)) then
      begin
        bet:=(-1/6)*x*x*x+x*x-2*x+(4/3); //B-spline
        exit;
      end;
      if x>2 then bet:=0;
    end;

    function R(X:real):real;
    begin
      If  (x<=1) then
      begin
        R:=(av+2)*x*x*x-(av+3)*x*x+1; //Bicub 1-var
        exit;
      end;
      if ((1<x) and(x<=2)) then
      begin
        R:=av*x*x*x-5*av*x*x+8*av*x-4*av; // bicub 1-var
        exit;
      end;
      if x>2 then R:=0;
    end;
//End locals


begin
  //Ved bilineær interpolation...:
  tocol:=trunc(ocol);
  torow:=trunc(orow);
  distCol:=ocol-tocol;
  distRow:=orow-torow;

  if interpol=2 then   //Bikubic interpolation
  begin
    av:=PolParam; //This is read from the parameter file (ideally av = -1)
    rrr:=0;
    ggg:=0;
    bbb:=0;
    ccc:=0;
    for a:=-1 to 2 do
    for b:=-1 to 2 do
    begin
      cnst:=R(abs(a-distcol))*R(abs(distrow-b));
      rrr:=rrr+(BA16[tocol+a,torow+b].r *cnst);
      ggg:=ggg+(BA16[tocol+a,torow+b].g *cnst);
      bbb:=bbb+(BA16[tocol+a,torow+b].b *cnst);
      ccc:=ccc+(BA16[tocol+a,torow+b].c *cnst);
    end;
    pix.r:=validate(rrr);
    pix.g:=validate(ggg);
    pix.b:=validate(bbb);
    pix.c:=validate(ccc);
    if almostblackvalue then
    begin
      if pix.r = 0 then pix.r:=1;
      if pix.g = 0 then pix.g:=1;
      if pix.b = 0 then pix.b:=1;
      if pix.c = 0 then pix.c:=1;
    exit;
    end
  end else

  if interpol=3 then // Beta spline interpolation
  begin
    rrr:=0;
    ggg:=0;
    bbb:=0;
    ccc:=0;
    for a:=-1 to 2 do
    for b:=-1 to 2 do
    begin
      cnst:=Bet(abs(a-distcol))*Bet(abs(distrow-b));
      rrr:=rrr+(BA16[tocol+a,torow+b].r *cnst);
      ggg:=ggg+(BA16[tocol+a,torow+b].g *cnst);
      bbb:=bbb+(BA16[tocol+a,torow+b].b *cnst);
      ccc:=ccc+(BA16[tocol+a,torow+b].c *cnst);
    end;
    pix.r:=validate(rrr);
    pix.g:=validate(ggg);
    pix.b:=validate(bbb);
    pix.c:=validate(ccc);
    if almostblackvalue then
    begin
      if pix.r = 0 then pix.r:=1;
      if pix.g = 0 then pix.g:=1;
      if pix.b = 0 then pix.b:=1;
      if pix.c = 0 then pix.c:=1;
    exit;
    end
  end else

  If interpol=1 then  //Bilinear interpolation
  begin
    PAT[1]:=  BA16[tocol,torow];
    PAT[2]:=BA16[tocol+1,torow];
    PAT[3]:=BA16[tocol,torow+1];
    PAT[4]:=BA16[tocol+1,torow+1];

    pix.r:= round(  (1-distcol)*(1-DistRow)*Pat[1].r
                   + distCol*(1-distrow)*PAT[2].r
                   + distRow*(1-distCol)*PAT[3].r
                   + distCol*distRow*PAT[4].r   );

    pix.g:= round(  (1-distcol)*(1-DistRow)*Pat[1].g
                   + distCol*(1-distrow)*PAT[2].g
                   + distRow*(1-distCol)*PAT[3].g
                   + distCol*distRow*PAT[4].g   );

    pix.b:= round(  (1-distcol)*(1-DistRow)*Pat[1].b
                   + distCol*(1-distrow)*PAT[2].b
                   + distRow*(1-distCol)*PAT[3].b
                   + distCol*distRow*PAT[4].b   );

    pix.c:= round(  (1-distcol)*(1-DistRow)*Pat[1].c
                   + distCol*(1-distrow)*PAT[2].c
                   + distRow*(1-distCol)*PAT[3].c
                   + distCol*distRow*PAT[4].c   );


    if almostblackvalue then
    begin
      if pix.r = 0 then pix.r:=1;
      if pix.g = 0 then pix.g:=1;
      if pix.b = 0 then pix.b:=1;
      if pix.c = 0 then pix.c:=1;

    exit;
    end
  end else
  if interpol=0 then  //Direct interpolation
  begin
    Pix.r:=BA16[round(ocol),round(orow)].r;
    Pix.g:=BA16[round(ocol),round(orow)].g;
    Pix.b:=BA16[round(ocol),round(orow)].b;
    Pix.c:=BA16[round(ocol),round(orow)].c;
    if almostblackvalue then
    begin
      if pix.r = 0 then pix.r:=1;
      if pix.g = 0 then pix.g:=1;
      if pix.b = 0 then pix.b:=1;
      if pix.c = 0 then pix.c:=1;
    end
  end;
end;

end.

