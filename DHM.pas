unit DHM;

{$MODE Delphi}

interface

uses sysutils, FileInputOutput;


Procedure IndlaesTINtxt(X0,Y0:real;fnam:String;EntireBufMax,MiniBufMax, MaxTrig:integer);
Procedure IndlaesTINdtt(X0,Y0:real;fnam:String;EntireBufMax,MiniBufMax, MaxTrig:integer);

Procedure IndlaesTINlib(X0,Y0,Z0:real;Libnam:string;EntireBufMax,MiniBufMax:integer);

Function InterpolZ(k1,k2:real):real;

//Dummy interpol til test...
Function Interpoler_z(k1,k2:real):real;

Procedure UpdateZA;



var

    BufClearCount : integer;

implementation


uses OrtoU, constants, math;


Type
    TKoord = record
              x,y,z : real;
            end;

    TInOutPolyDef = Record
                 PA   : Array[1..3] of Tkoord;
                 PA_i : integer;
            end;


    Trig = record
               Poly        : TInOutPolyDef;
               A,B,C,D   : Real;
               Cx,Cy,dst : real;
            end;



Var Tin   : Array of Trig;
    Tin_i : integer;

    TinCM   : Array of trig;
    TINCM_i : integer;


    LastDist: Real;
    LastTrek: integer;

    P:Tkoord;
    TempPoly:Tinoutpolydef;

    LastY : Real;
    LastTreks:array[1..10000] of integer;
    LastTreks_i:integer;


    LastTCMs:array[1..10000] of integer;
    LastTCMs_i:integer;
    CMEBMAX, CMMBMAX:integer;
    LastTCM:integeR;

    XX0:real;
    EBMax,MBMax:integer;



type strarray= array[1..100] of string;

Procedure disect(var st1:strarray;st2:string);
var a,b,l:integer; //tællere
    dst:string;    //Dummy String
begin
  for a:=1 to 50 do st1[a]:='';
  b:=1;
  for a:=1 to length(st2) do
  begin
    st1[b]:=st1[b]+st2[a];
    if st2[a] in ([' ',',',';']) then
    begin
      dst:='';
      for l:=1 to length(st1[b])-1 do //fjern tegn i slutning af string
      dst:=dst+st1[b][l];
      st1[b]:='';
      st1[b]:=dst;
      if dst<>'' then
      inc(b);
    end;
  end;
end;

Function InsideTrek(P:Tkoord;Poly:TInOutPolydef):boolean;
var i,j : integer;
    inside: boolean;
Begin
  inside:=false;
  j:=1;
  For i:=1 to poly.PA_i do
  begin
    inc(j);
    if j = poly.PA_i+1 then j:=1;
    if (((poly.PA[i].y<P.y) and (Poly.PA[j].y>=P.y)) or ((Poly.PA[j].y<P.y) and (Poly.PA[i].y>=P.y))) then
    if poly.PA[i].x+(P.y-Poly.PA[i].y)/(Poly.PA[j].y-poly.PA[i].y)*(Poly.PA[j].x-poly.PA[i].x) <P.x then
    if inside = false then inside:=true else
    if inside = true then inside:=false;
  end;
  InsideTrek:=inside;
end;

Procedure CalcDists(k1,k2:real);
var a:integer;
begin
  for a:=1 to Tin_i do
  With Tin[a] do
  begin
    dst:=sqrt(sqr(k1-Cx)+sqr(k2-Cy));
  end;
end;

Procedure CalcDistsCM(k1,k2:real);
var a:integer;
begin
  for a:=1 to TinCM_i do
  With TinCM[a] do
  begin
    dst:=sqrt(sqr(k1-Cx)+sqr(k2-Cy));
  end;
end;


Procedure SortTreks;
var
   i, j, Gap : Integer;
   byt       : Boolean;
   Temp      : Trig;
Begin
  Gap := TIN_i;
  Repeat
    Gap := Trunc (Gap / 1.3);
    if Gap < 1 then Gap := 1;
    byt := False;
    For i := 1 to (TIN_i - Gap) do
    begin
      j := i + Gap;
      if TIN[i].dst > TIN[j].dst then { swap }
      begin
        Temp := TIN [i];
        TIN [i] := TIN [j];
        TIN [j] := Temp;
        byt := True;
      end;
    end;
  Until (Gap = 1) and not byt;
end;

Procedure SortTCM;
var
   i, j, Gap : Integer;
   byt       : Boolean;
   Temp      : Trig;
Begin
  Gap := TINCM_i;
  Repeat
    Gap := Trunc (Gap / 1.3);
    if Gap < 1 then Gap := 1;
    byt := False;
    For i := 1 to (TINCM_i - Gap) do
    begin
      j := i + Gap;
      if TINCM[i].dst > TINCM[j].dst then { swap }
      begin
        Temp := TINCM [i];
        TINCM [i] := TINCM [j];
        TINCM [j] := Temp;
        byt := True;
      end;
    end;
  Until (Gap = 1) and not byt;
end;



function FindTriangle:integer;
var aa:integer;
begin
  If LastTreks_i>0 then
  If InsideTrek(P,Tin[lastTrek].Poly) then
  begin
    FindTriangle:=Lasttrek;
    exit;
  end;

  for aa:=1 to LastTreks_i do
  with Tin[LastTreks[aa]] do
  If InsideTrek(P,Poly) then
  begin
    LastTrek:=LastTreks[aa];
    FindTriangle:=LastTreks[aa];
    exit;
  end;


 If LastTrek>EBmax then

  begin
    sl('Sorting TrekArray.');
    CalcDists(XX0,P.y);
    SortTreks;
    LastTreks_i:=0;
  end;


  for aa:=1 to Tin_i do
  With Tin[aa] do
  begin
    If InsideTrek(P,Poly) then
    begin
      If LastTreks_i>MBmax then
      begin
        Inc(BufClearCount);
        Lasttreks_i:=0;
      end;
      inc(LastTreks_i);
      LastTreks[LastTreks_i]:=aa;
      LastTrek:=aa;
      FindTriangle:=aa;
      exit;
    end;
  end;
  sl('Coordinates outside TIN covered area.'+#10+#10+'Coordinates (k1,k2)): '+floattostr(p.x)+' '+floattostr(p.y)+#10+#10+' Program terminated.');
  Halt;
end;


function FindTriangleCM:integer;
var aa:integer;
begin
  If LastTCMs_i>0 then
  If InsideTrek(P,TinCM[lastTCM].Poly) then
  begin
    FindTriangleCM:=LastTCM;
    exit;
  end;

  for aa:=1 to LastTCMs_i do
  with TinCM[LastTCMs[aa]] do
  If InsideTrek(P,Poly) then
  begin
    LastTCM:=LastTCMs[aa];
    FindTriangleCM:=LastTCMs[aa];
    exit;
  end;


 If LastTCM>CMEBmax then

  begin
    sl('Sorting TrekArrayCM.');
    CalcDists(XX0,P.y);
    SortTCM;
    LastTCMs_i:=0;
  end;


  for aa:=1 to TinCM_i do
  With TinCM[aa] do
  begin
    If InsideTrek(P,Poly) then
    begin
      If LastTCMs_i>MBmax then
      begin
        Inc(BufClearCount);
        LastTCMs_i:=0;
      end;
      inc(LastTreks_i);
      LastTCMs[LastTCMs_i]:=aa;
      LastTCM:=aa;
      FindTriangleCM:=aa;
      exit;
    end;
  end;
  FindTriangleCM:=0;
  //sl('Coordinates outside TINCM covered area.'+#10+#10+'Coordinates (k1,k2)): '+floattostr(p.x)+' '+floattostr(p.y)+#10+#10+' Program terminated.');
  //Halt;
end;


Function InterpoliTag(k1,k2:real):real;
var a:integer;
    z: real;

begin
  P.x:=k1;P.y:=k2;
  a:=FindTriangleCM;
  if a<>0 then
  begin
    With TINCM[a] do
    begin
      InterpoliTag:=-(A/C)*k1 - (B/C)*k2 - (D/C);
    end;
  end else
  interpoliTag:=-999;

end;



Function InterpolZ(k1,k2:real):real;
var a:integer;
    z: real;
    tz:real;
begin
  P.x:=k1;P.y:=k2;
{  if cm then
  begin
    tz:= InterpoliTag(k1,k2);
    if tz<-100 then
    begin
      a:=FindTriangle;
      With TIN[a] do
      begin
        InterpolZ:=-(A/C)*k1 - (B/C)*k2 - (D/C);
      end;
    end;
  end else   }
  a:=FindTriangle;
  With TIN[a] do
  begin
    InterpolZ:=-(A/C)*k1 - (B/C)*k2 - (D/C);
  end;
end;


Procedure IndlaesTINtxt(X0,Y0:real;fnam:String;EntireBufMax,MiniBufMax, MaxTrig:integer);
var f:textfile;
    st:string;
    pkt,opr : string;
    k1,k2,k3 : real;
    ok:boolean;
    kod:integer;
    kkod:string;
    dumfile:file of byte;
   Sz : longint;
   Sz2:real;
   sta:StrArray;
   temp:integer;
   a:integer;
   fsize:longint;
begin
  filemode:=0;
  temp:=0;
  BufClearCount:=0;
  TIN_i:=0;
  AssignFile(dumFile,pchar(fnam));
  reset(dumfile);
  fsize:=fileSize(dumfile);
  closefile(dumfile);
  assignfile(f,pchar(fnam));
  reset(f);
  readln(f,st);
  if fsize > 10000 then
  begin
    for a:=1 to 100 do
    begin
      readln(f,st);
      temp:=temp+length(st)+2;
    end;
    SZ2:=round((100/temp)*fsize);
    SZ:=round(Sz2*1.05);
    closefile(f);
  end else SZ:=20000;

  SetLength(TIN,Round(Sz));

  MBmax:=MiniBufMax;
  EBmax:=EntireBufMax;

  XX0:=X0;
  LastTreks_i:=0;
  LastTrek:=10000;
  LastY:=0;
  assignFile(f,pchar(fnam));
  reset(f);
  while not eof(f) do
  begin
    Readln(f,st);
    if st[1]='#' then continue;
    Disect(sta,st);
    begin

      kkod:=sta[1];//IntToStr(Kod);
      if kkod[length(kkod)]='1' then
      begin
        Inc(Tin_i);

        Tin[tin_i].Poly.PA[1].x:=StrToFloat(sta[2]);
        Tin[tin_i].Poly.PA[1].y:=StrToFloat(sta[3]);
        Tin[tin_i].Poly.PA[1].z:=StrToFloat(sta[4]);
        readln(f,st);
        disect(sta,st);

        Tin[tin_i].Poly.PA[2].x:=StrToFloat(sta[2]);
        Tin[tin_i].Poly.PA[2].y:=StrToFloat(sta[3]);
        Tin[tin_i].Poly.PA[2].z:=StrToFloat(sta[4]);
        readln(f,st);

        disect(sta,st);
        kkod:=(sta[1]);
        If (kkod[length(kkod)]='8') or (kkod[length(kkod)]='9') then
        begin
          Tin[tin_i].Poly.PA[3].x:=StrToFloat(sta[2]);
          Tin[tin_i].Poly.PA[3].y:=StrToFloat(sta[3]);
          Tin[tin_i].Poly.PA[3].z:=StrToFloat(sta[4]);
          Tin[tin_i].Poly.PA_i:=3;
        end else
        begin
          sl('TIN indeholder data, som ikke er en trekant, program sluttes');
          Halt;
        end;
      end else
      begin
        Sl('Tin indeholder et objekt, som ikke er en del af en trekant, program sluttes');
        halt;
      end;
    end;
    //A, B, C og D beregnes.
    With TIN[Tin_i] do
    begin
      A:=  Poly.PA[1].y*(Poly.PA[2].Z-Poly.PA[3].Z) + Poly.PA[2].y*(Poly.PA[3].z-Poly.PA[1].z) + Poly.PA[3].Y*(Poly.PA[1].Z-Poly.PA[2].Z);
      B:=  Poly.PA[1].Z*(Poly.PA[2].X-Poly.PA[3].X) + Poly.PA[2].Z*(Poly.PA[3].X-Poly.PA[1].x) + Poly.PA[3].Z*(Poly.PA[1].X-Poly.PA[2].X);
      C:=  Poly.PA[1].X*(Poly.PA[2].Y-Poly.PA[3].Y) + Poly.PA[2].X*(Poly.PA[3].Y-Poly.PA[1].Y) + Poly.PA[3].X*(Poly.PA[1].Y-Poly.PA[2].Y);
      D:= - A*Poly.PA[1].x - B*Poly.PA[1].y - C*Poly.PA[1].z;
      Cx:=(Poly.PA[1].x+Poly.PA[2].x+Poly.PA[3].x)/3;
      Cy:=(Poly.PA[1].y+Poly.PA[2].y+Poly.PA[3].y)/3;
    end;

  end;
  closefile(f);

  CalcDists(X0,Y0);
  SortTreks;
  LastTreks_i:=0;
  filemode:=2;
end;


Procedure IndlaesTINdtt(X0,Y0:real;fnam:String;EntireBufMax,MiniBufMax, MaxTrig:integer);
var f:textfile;
    st:string;
    pkt,opr : string;
    k1,k2,k3 : real;
    ok:boolean;
    kod:integer;
    kkod:string;
    dumfile:file of byte;
   Sz : longint;
   Sz2:real;
   sta:StrArray;
   temp:integer;
   a:integer;
   fsize:longint;
begin
  filemode:=0;
  temp:=0;
  BufClearCount:=0;
  TIN_i:=0;
  AssignFile(dumFile,pchar(fnam));
  reset(dumfile);
  fsize:=fileSize(dumfile);
  closefile(dumfile);


  assignfile(f,pchar(fnam));
  reset(f);
  readln(f,st);
  if fsize > 10000 then
  begin
    for a:=1 to 100 do
    begin
      readln(f,st);
      temp:=temp+length(st)+2;
    end;
    SZ2:=round((100/temp)*fsize);
    SZ:=round(Sz2*0.5);
    closefile(f);
  end else SZ:=20000;

  SetLength(TIN,Round(Sz));

   MBmax:=MiniBufMax;
   EBmax:=EntireBufMax;

   XX0:=X0;
   LastTreks_i:=0;
   LastTrek:=10000;
    LastY:=0;
  assignFile(f,pchar(fnam));
  reset(f);
  while not eof(f) do
  begin
    Readln(f,st);

    begin

      if st = 'TRIANGLE' then
      begin
        Inc(Tin_i);

        Readln(f,st);
        Readln(f,st);
        disect(sta,st);

        Tin[tin_i].Poly.PA[1].x:=StrToFloat(sta[3]);
        Tin[tin_i].Poly.PA[1].y:=StrToFloat(sta[4]);
        Tin[tin_i].Poly.PA[1].z:=StrToFloat(sta[5]);
        readln(f,st);
        disect(sta,st);

        Tin[tin_i].Poly.PA[2].x:=StrToFloat(sta[3]);
        Tin[tin_i].Poly.PA[2].y:=StrToFloat(sta[4]);
        Tin[tin_i].Poly.PA[2].z:=StrToFloat(sta[5]);
        readln(f,st);

        disect(sta,st);
        kkod:=(sta[1]);

        Tin[tin_i].Poly.PA[3].x:=StrToFloat(sta[3]);
        Tin[tin_i].Poly.PA[3].y:=StrToFloat(sta[4]);
        Tin[tin_i].Poly.PA[3].z:=StrToFloat(sta[5]);
        Tin[tin_i].Poly.PA_i:=3;
      end;
    end;
    //A, B, C og D beregnes.
    With TIN[Tin_i] do
    begin
      A:=  Poly.PA[1].y*(Poly.PA[2].Z-Poly.PA[3].Z) + Poly.PA[2].y*(Poly.PA[3].z-Poly.PA[1].z) + Poly.PA[3].Y*(Poly.PA[1].Z-Poly.PA[2].Z);
      B:=  Poly.PA[1].Z*(Poly.PA[2].X-Poly.PA[3].X) + Poly.PA[2].Z*(Poly.PA[3].X-Poly.PA[1].x) + Poly.PA[3].Z*(Poly.PA[1].X-Poly.PA[2].X);
      C:=  Poly.PA[1].X*(Poly.PA[2].Y-Poly.PA[3].Y) + Poly.PA[2].X*(Poly.PA[3].Y-Poly.PA[1].Y) + Poly.PA[3].X*(Poly.PA[1].Y-Poly.PA[2].Y);
      D:= - A*Poly.PA[1].x - B*Poly.PA[1].y - C*Poly.PA[1].z;
      Cx:=(Poly.PA[1].x+Poly.PA[2].x+Poly.PA[3].x)/3;
      Cy:=(Poly.PA[1].y+Poly.PA[2].y+Poly.PA[3].y)/3;
    end;

  end;
  closefile(f);

  
  CalcDists(X0,Y0);
  SortTreks;
  LastTreks_i:=0;


  CalcDists(X0,Y0);
  SortTreks;
  filemode:=2;
end;




Procedure AddAsingleTINtxt(fnam:string);
var f:textfile;
   st:string;
    pkt,opr : string;
    k1,k2,k3 : real;
    ok:boolean;
    kod:integer;
    kkod:string;
   sta:StrArray;
begin   //den ene lille-bitte tin indlæses
  assignFile(f,pchar(fnam));
  reset(f);
  while not eof(f) do
  begin
    Readln(f,st);
    if st[1]='#' then continue;
    Disect(sta,st);
    begin

      kkod:=sta[1];//IntToStr(Kod);
      if kkod[length(kkod)]='1' then
      begin
        Inc(Tin_i);

        Tin[tin_i].Poly.PA[1].x:=StrToFloat(sta[2]);
        Tin[tin_i].Poly.PA[1].y:=StrToFloat(sta[3]);
        Tin[tin_i].Poly.PA[1].z:=StrToFloat(sta[4]);
        readln(f,st);
        disect(sta,st);

        Tin[tin_i].Poly.PA[2].x:=StrToFloat(sta[2]);
        Tin[tin_i].Poly.PA[2].y:=StrToFloat(sta[3]);
        Tin[tin_i].Poly.PA[2].z:=StrToFloat(sta[4]);
        readln(f,st);

        disect(sta,st);
        kkod:=(sta[1]);
        If (kkod[length(kkod)]='8') or (kkod[length(kkod)]='9') then
        begin
          Tin[tin_i].Poly.PA[3].x:=StrToFloat(sta[2]);
          Tin[tin_i].Poly.PA[3].y:=StrToFloat(sta[3]);
          Tin[tin_i].Poly.PA[3].z:=StrToFloat(sta[4]);
          Tin[tin_i].Poly.PA_i:=3;
        end else
        begin
          sl('TIN indeholder data, som ikke er en trekant, program sluttes');
          Halt;
        end;
      end else
      begin
        Sl('Tin indeholder et objekt, som ikke er en del af en trekant, program sluttes');
        halt;
      end;
    end;
    //A, B, C og D beregnes.
    With TIN[Tin_i] do
    begin
      A:=  Poly.PA[1].y*(Poly.PA[2].Z-Poly.PA[3].Z) + Poly.PA[2].y*(Poly.PA[3].z-Poly.PA[1].z) + Poly.PA[3].Y*(Poly.PA[1].Z-Poly.PA[2].Z);
      B:=  Poly.PA[1].Z*(Poly.PA[2].X-Poly.PA[3].X) + Poly.PA[2].Z*(Poly.PA[3].X-Poly.PA[1].x) + Poly.PA[3].Z*(Poly.PA[1].X-Poly.PA[2].X);
      C:=  Poly.PA[1].X*(Poly.PA[2].Y-Poly.PA[3].Y) + Poly.PA[2].X*(Poly.PA[3].Y-Poly.PA[1].Y) + Poly.PA[3].X*(Poly.PA[1].Y-Poly.PA[2].Y);
      D:= - A*Poly.PA[1].x - B*Poly.PA[1].y - C*Poly.PA[1].z;
      Cx:=(Poly.PA[1].x+Poly.PA[2].x+Poly.PA[3].x)/3;
      Cy:=(Poly.PA[1].y+Poly.PA[2].y+Poly.PA[3].y)/3;
    end;

  end;
  closefile(f);


end;




Procedure IndlaesTINlib(X0,Y0,Z0:real;Libnam:string;EntireBufMax,MiniBufMax:integer);
var lower,upper:integer;
    DHMLibA : array[-10..10] of string;
    DHMLibA_i : integer;
    DTMnavn : string;
    i,j : integer;
    LLx,LLy : integer;
    BufSize:integer;
    f:file of byte;
    subdir:string;
begin

  BufSize:=0;
  TIN_i:=0;
  BufClearCount:=0;
  MBmax:=MiniBufMax;
  EBmax:=EntireBufMax;
  LastTreks_i:=0;
  LastTrek:=10000;

  if LibNam[length(libnam)]<>'\' then libnam:=libnam+'\';
  if Z0 <900 then begin lower:=-1;upper:=1; end else
  if Z0 <2000 then begin lower:=-2;upper:=2; end else
  if Z0 <3000 then begin lower:=-3;upper:=3; end else
  if Z0 <4000 then begin lower:=-4;upper:=4; end else
  begin lower:=-5;upper:=5; end;

  filemode:=0;
  for j:= lower to upper do
  for i:= lower to upper do
  begin

    LLx:=trunc(X0/1000)+i;
    LLy:=trunc(Y0/1000)+j;

    subdir:=inttostr(trunc(LLy/10))+'_'+inttostr(trunc(LLx/10))+'\';
    DTMnavn:=Libnam+subdir+'1km_'+inttostr(LLy)+'_'+inttostr(LLx)+'.txt';
    If fileexists(Pchar(DTMnavn)) then
    begin
      AssignFile(f,Pchar(DTMnavn));
      reset(f);
      BufSize:=BufSize+filesize(f);
      closefile(f);
    end else
    begin
      sl('...Library block '+DTMnavn+' is missing');
    end;
  end;
  filemode:=2;

  bufsize:=round(bufsize/35);
  SetLength(TIN,bufsize);

  for j:= lower to upper do
  for i:= lower to upper do
  begin
    LLx:=trunc(X0/1000)+i;
    LLy:=trunc(Y0/1000)+j;
    subdir:=inttostr(trunc(LLy/10))+'_'+inttostr(trunc(LLx/10))+'\';
    DTMnavn:=Libnam+subdir+'1km_'+inttostr(LLy)+'_'+inttostr(LLx)+'.txt';
    If fileexists(Pchar(DTMnavn)) then
    begin
	  sl(ExtractFileName(Pchar(DTMnavn)));

      AddASingleTinTxt(DTMnavn);
    end;
  end;
  sl('Sorting...');

  CalcDists(X0,Y0);
  SortTreks;
  LastTreks_i:=0;

end;




Function Interpoler_z(k1,k2:real):real;
begin
  Interpoler_z:=0;
end;


Procedure GetColRow(X,Y:real;Var col,row:integer);
//Beregner Col, Row på baggrund af X,Y. Kan som GetXY udbygges til at håndtere rot. orto.
begin


  col:=round((0.5*PixStr+X-ULX)/PixStr);
  row:=round((ULY-Y-0.5*PixStr)/PixStr);
end;

Procedure GetXY(col,row:integer;var x,y:real);
//Beregner en X,Y på baggrund af en col,row i ortofotoet. Kan evt. udbygges til at kunne
//håndtere roterede ortofotos vha. en helmert.
begin
  x:= ULX+Col*PixStr-0.5*PixStr;
  y:= ULY-(Row*PixStr-0.5*PixStr);
end;


Procedure UpdateZA;
var aaa:integer;
    minx,miny,maxx,maxy:real;
    lowC,UpC,LowR,UpR:integer;
    i,j, chan: integer;
    tx,ty,tz:real;
begin
//  chan:=0;
  for aaa:=1 to TinCM_i do
  begin
    with TinCM[aaa].poly do
    begin
      minx:=999999999; miny:=999999999999;Maxx:=-99999999999;maxy:=-99999999999;
      minx:=min(PA[1].x,min(PA[2].x,PA[3].x));
      maxx:=max(PA[1].x,max(PA[2].x,PA[3].x));
      miny:=min(PA[1].y,min(PA[2].y,PA[3].y));
      maxy:=max(PA[1].y,max(PA[2].y,PA[3].y));
    end;
    GetColRow(minx,miny,LowC,UpR);
    GetColRow(maxx,maxy,UpC,LowR);
    For j:=lowR to UpR do
    For i:=lowC to UpC do
    begin
      if j< 1 then continue;
      if i< 1 then continue;
      if j> maxpixrow then continue;
      if i> maxpixcol then continue;
      getxy(i,j,tx,ty);
      P.x:=tx;P.y:=ty;
      If insideTrek(P,TinCM[aaa].poly) then
      begin
        with TinCM[aaa] do
         tz:=-(A/C)*tx - (B/C)*ty - (D/C);
        tz:=100*(tz+200);
        If tz>ZA[i,j] then
        begin
          ZA[i,j]:=round(tz);
        end;
      end;
    end;
  end;
end;


end.