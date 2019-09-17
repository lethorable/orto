unit GridUnit;

{$MODE Delphi}

interface

uses sysutils, FileInputOutput, constants;

var Grid : Array of array of single;
    GridNCols,GridNRows:integer;
    GridLL_X, GridLL_Y : real;
    GridCellSize : real;
    GridNodataValue : real;
    GridByteOrder : string;

    usegrid : boolean;

Procedure ReadHDRFLT(fnam:string);
Procedure ReadHDRFLT_Rot(fnam:string);
Procedure ReadASCgrid(fnam:string);
Procedure ReadDTMgrid(fnam:string);

Procedure IndlaesGRIDlib(X0,Y0,Z0:real;Libnam:string);
Procedure IndlaesGRIDlib5km(X0,Y0,Z0:real;Libnam:string);

function InterpolerZiGrid(X,Y:real):real;

implementation

type strarray= array[1..100] of string;

Type KooTyp = record
                X,Y : double;
                c,r : integer;
                Z : double;
              end;

function InterpolerZiGrid(X,Y:real):real;
var
    DistX,DistY : real;
    LLX,LLY : Real;
    LLC,LLR:integer;
begin
  LLC:=trunc((X-GridLL_X)/GridCellSize);
  LLR:=trunc((Y-GridLL_Y)/GridCellSize); 

  LLX:=  LLc  *  GridCellSize+GridLL_X;
  LLY:=  LLr  *  GridCellSize+GridLL_Y;

  DistX:= (X-LLX)/GridCellSize;
  DistY:= (Y-LLY)/GridCellSize;

  If LLC<0 then Begin InterpolerZigrid:=-999; exit; end;
  If LLR<0 then Begin InterpolerZigrid:=-999; exit; end;
  If LLC>=GridNCols then Begin InterpolerZigrid:=-999; exit; end;
  If LLR>=GridNRows then Begin InterpolerZigrid:=-999; exit; end;
  InterPolerZiGrid:= (1-distX)*(1-distY)*Grid[LLC,LLR]
                      + distX*(1-DistY)*Grid[LLC+1,LLR]
                      + (1-distX)*distY*Grid[LLc,LLr+1]
                      +  distX*distY*Grid[LLc+1,LLr+1];
end;

Procedure disect(var st1:strarray;st2:string);
var a,b,l:integer; //tællere
    dst:string;    //Dummy String
begin
  for a:=1 to 50 do st1[a]:='';
  b:=1;
  for a:=1 to length(st2) do
  begin
    st1[b]:=st1[b]+st2[a];
    if st2[a] in ([' ']) then
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

Procedure disect2(var st1:strarray;st2:string);
var a,b,l:integer; //tællere
    dst:string;    //Dummy String
begin
  for a:=1 to 50 do st1[a]:='';
  b:=1;
  for a:=1 to length(st2) do
  begin
    st1[b]:=st1[b]+st2[a];
    if st2[a] in ([' ' , ',' , ';']) then
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

Procedure ReadHDRFLT(fnam:string);
var GridF: File of single;
    GridHeaderFile : textfile;
    st:string;
    sta: strarray;
    a,b,i,j:integer;
    BufA: Array of single;
    hh:single;
    amtstrf:integer;
    center:boolean;
    StartX,StartY:real;
begin
  AssignFile(GridHeaderFile,PChar(fnam));
  reset(GridHeaderFile);
  readln(GridHeaderFile,st);
  disect(sta,st);
  GridNCols:=StrToInt(sta[2]);
  readln(GridHeaderFile,st);
  disect(sta,st);
  GridNRows:=StrToInt(sta[2]);
  readln(GridHeaderFile,st);
  disect(sta,st);
  If uppercase(Sta[1])='XLLCENTER' then Center:=true else center:=false;
  StartX:=StrToFloat(sta[2]);
  readln(GridHeaderFile,st);
  disect(sta,st);
  StartY:=StrToFloat(sta[2]);
  readln(GridHeaderFile,st);
  disect(sta,st);
  GridCellSize:=StrToFloat(sta[2]);
  readln(GridHeaderFile,st);
  disect(sta,st);
  GridNoDataValue:=StrToFloat(sta[2]);
  readln(GridHeaderFile,st);
  disect(sta,st);
  GridByteOrder:=sta[2];
  closefile(GridHeaderFile);
  If not Center then
  begin
    startX:=startX+0.5*gridcellsize;
    startY:=StartY+0.5*Gridcellsize;
  end;
  GridLL_X:=startX;GridLL_Y:=startY;



  SetLength(Grid,GridNCols);
  for i:=0 to GridNCols-1 do
    SetLength(Grid[i],GridNRows);
  st:=ChangeFileExt(fnam,'.flt');
  Assignfile(GridF,PChar(st));
  reset(GridF);
  for  j:=GridNrows-1 Downto 0 do
  begin
    for i:=0 to GridNCols-1 do
    Read(GridF,Grid[i,j])
  end;
  closefile(GridF);
end;

Procedure ReadHDRFLT_Rot(fnam:string);
var GridF: File of single;
    GridHeaderFile : textfile;
    st:string;
    sta: strarray;
    a,b,i,j:integer;
    BufA: Array of single;
    hh:single;
    amtstrf:integer;
    TempLL : real;
    Center:boolean;
begin
  AssignFile(GridHeaderFile,PChar(fnam));
  reset(GridHeaderFile);
  readln(GridHeaderFile,st);
  disect(sta,st);
  GridNRows:=StrToInt(sta[2]);   //omvendt i fh.t. "almindelig" grid
  readln(GridHeaderFile,st);
  disect(sta,st);
  GridNCols:=StrToInt(sta[2]);  //omvendt i fh.t. "almindelig" grid
  readln(GridHeaderFile,st);
  disect(sta,st);
  GridLL_X:=StrToFloat(sta[2]);
  readln(GridHeaderFile,st);
  disect(sta,st);
  GridLL_Y:=StrToFloat(sta[2]);
  readln(GridHeaderFile,st);
  disect(sta,st);
  GridCellSize:=StrToFloat(sta[2]);
  readln(GridHeaderFile,st);
  disect(sta,st);
  GridNoDataValue:=StrToFloat(sta[2]);
  readln(GridHeaderFile,st);
  disect(sta,st);
  GridByteOrder:=sta[2];

  TempLL:=GridLL_X;
  GridLL_X:=GridLL_Y;
  GridLL_Y:=(-TempLL)-GridCellSize*(GridNRows-1);


  closefile(GridHeaderFile);
  SetLength(Grid,GridNCols);
  for i:=0 to GridNCols-1 do
    SetLength(Grid[i],GridNRows);
  st:=ChangeFileExt(fnam,'.flt');
  Assignfile(GridF,PChar(st));
  reset(GridF);
  for  j:= 0 to GridNcols-1 do
  begin
    for i:=0 to GridNrows-1 do
    Read(GridF,Grid[j,i])
  end;
  closefile(GridF);
end;


Procedure ReadASCgrid(fnam:string);
var GridF: Textfile;
    st:string;
    sta: strarray;
    a,b,i,j:integer;
    hh:single;
    amtstrf:integer;
    StartX,StartY:Real;
    center:boolean;
begin
  AssignFile(GridF,PChar(fnam));
  reset(GridF);
  readln(GridF,st);
  disect(sta,st);
  GridNCols:=StrToInt(sta[2]);
  readln(GridF,st);
  disect(sta,st);
  GridNRows:=StrToInt(sta[2]);
  readln(GridF,st);
  disect(sta,st);
  If uppercase(Sta[1])='XLLCENTER' then Center:=true else center:=false;

  StartX:=StrToFloat(sta[2]);
  readln(GridF,st);
  disect(sta,st);
  StartY:=StrToFloat(sta[2]);
  readln(GridF,st);
  disect(sta,st);
  GridCellSize:=StrToFloat(sta[2]);
  readln(GridF,st);
  disect(sta,st);
  GridNoDataValue:=StrToFloat(sta[2]);

  If not Center then
  begin
    startX:=startX+0.5*gridcellsize;
    startY:=StartY+0.5*Gridcellsize;
  end;
  GridLL_X:=startX;GridLL_Y:=startY;

  SetLength(Grid,GridNCols);
  for i:=0 to GridNCols-1 do
    SetLength(Grid[i],GridNRows);

  for  j:=GridNrows-1 Downto 0 do
  begin
    for i:=0 to GridNCols-1 do
    begin
      Read(GridF,Grid[i,j]);
      if Grid[i,j]<-90 then  Grid[i,j]:=0;
    end;
  end;
  closefile(GridF);
end;


Procedure IndlaesGRIDlib(X0,Y0,Z0:real;Libnam:string);
var
  i,j,k,l:integer;
  lower,upper:integer;
  first_read:boolean;
  st:string;
  ncols,nrows:integer;
  center:boolean;
  cellsize:real;
  oldncols,oldnrows:integer;
  oldcenter:boolean;
  oldcellsize:real;
  LLX,LLY:integer;
  sta:strarray;
  subdir:string;
  DTMnavn,Fnavn:string;
  f:textfile;
  startX,startY:real;
  inputcol,inputrow:integer;
  GridLowerLeftX,GridLowerLeftY:real;
  foundOne:boolean;
begin
  foundone:=false;
  if LibNam[length(libnam)]<>'\' then libnam:=libnam+'\';
  if Z0 <900 then begin lower:=-1;upper:=1; end else
  if Z0 <2000 then begin lower:=-2;upper:=2; end else
  if Z0 <3000 then begin lower:=-3;upper:=3; end else
  if Z0 <4000 then begin lower:=-4;upper:=4; end else
  begin lower:=-5;upper:=5; end;

  cellsize:=1.6;
  Center:=true;
  ncols:=625;
  nrows:=625;

  GridLowerLeftX:=(trunc(X0/1000)+lower)*1000;
  GridLowerLeftY:=(trunc(Y0/1000)+lower)*1000;


  first_read:=false;

  filemode:=0;
  for j:= lower to upper do
  for i:= lower to upper do
  begin
    LLx:=trunc(X0/1000)+i;
    LLy:=trunc(Y0/1000)+j;

    subdir:=inttostr(trunc(LLy/10))+'_'+inttostr(trunc(LLx/10))+'\';
    DTMnavn:=Libnam+subdir+DG_Lib_pref+'1km_'+inttostr(LLy)+'_'+inttostr(LLx)+'.asc';
    Fnavn:=Libnam+DG_Lib_pref+'1km_'+inttostr(LLy)+'_'+inttostr(LLx)+'.asc';
    If fileexists(Pchar(Fnavn)) then DTMnavn:=Fnavn;

    If fileexists(Pchar(DTMnavn)) then
    begin
      AssignFile(f,Pchar(DTMnavn));
      reset(f);
      Readln(f,st);Disect(sta,st);ncols:=StrtoInt(Sta[2]);
      Readln(f,st);Disect(sta,st);nrows:=StrtoInt(Sta[2]);
      Readln(f,st);Disect(sta,st);if UpperCase(sta[1])='XLLCENTER' then Center:=true else center:=false;
      Readln(f,st);Disect(sta,st);      Readln(f,st);Disect(sta,st);cellsize:=StrtoFloat(sta[2]);
      closefile(f);
      if first_read then //if we have read one file header, we can compare to check for identical headers.
      begin
        If ((oldncols<>ncols) or (oldnrows<>nrows) or(oldcenter<>center) or(oldcellsize<>cellsize)) then
        //raise an exception
        raise ERangeError.Create('ERROR!!! Grid quad headers in library are not uniform)');
      end;
      first_read:=true; //first
      oldncols:=ncols; oldnrows:=nrows; oldcenter:=center; oldcellsize:=cellsize;
    end else
    begin
      sl('ERROR!!! Library block '+DTMnavn+' is missing');
      continue;
    end;
    //Testing of data has finished. Now it is read into Ram!!!
  end;
  If first_read=false then sl('WARNING - no DTM grid available. Using Z=0!');
  GridCellSize:=cellsize;
  GridNcols:=ncols*(upper*2+1);
  GridNrows:=nrows*(upper*2+1);
  SetLength(Grid,GridNCols);
  for i:=0 to GridNCols-1 do
    SetLength(Grid[i],GridNRows);

  for j:= 0 to GridNcols-1 do
  for i:= 0 to GridNrows-1 do
    Grid[i,j]:=0;

  LLx:=trunc(X0/1000)+lower;
  LLy:=trunc(Y0/1000)+lower;
  subdir:=inttostr(trunc(LLy/10))+'_'+inttostr(trunc(LLx/10))+'\';
  DTMnavn:=Libnam+subdir+DG_Lib_pref+'1km_'+inttostr(LLy)+'_'+inttostr(LLx)+'.asc';
  Fnavn:=Libnam+DG_Lib_pref+'1km_'+inttostr(LLy)+'_'+inttostr(LLx)+'.asc';
  startX:= GridLowerLeftX;
  startY:= GridLowerLeftY;
  If not Center then
  begin
    startX:=startX+0.5*gridcellsize;
    startY:=StartY+0.5*Gridcellsize;
  end;
  GridLL_X:=startX;GridLL_Y:=startY;
  for j:= lower to upper do
  for i:= lower to upper do
  begin
    LLx:=trunc(X0/1000)+i;
    LLy:=trunc(Y0/1000)+j;
    subdir:=inttostr(trunc(LLy/10))+'_'+inttostr(trunc(LLx/10))+'\';
    DTMnavn:=Libnam+subdir+DG_Lib_pref+'1km_'+inttostr(LLy)+'_'+inttostr(LLx)+'.asc';
    Fnavn:=Libnam+DG_Lib_pref+'1km_'+inttostr(LLy)+'_'+inttostr(LLx)+'.asc';
    If fileexists(Pchar(Fnavn)) then DTMnavn:=Fnavn;

    If fileexists(Pchar(DTMnavn)) then
    begin
      AssignFile(f,Pchar(DTMnavn));
      reset(f);
      Readln(f,st);Disect(sta,st);ncols:=StrtoInt(Sta[2]);
      Readln(f,st);Disect(sta,st);nrows:=StrtoInt(Sta[2]);
      Readln(f,st);Disect(sta,st);if UpperCase(sta[1])='XLLCENTER' then Center:=true else center:=false;
      Readln(f,st);Disect(sta,st);Readln(f,st);Disect(sta,st);cellsize:=StrtoFloat(sta[2]);
      readln(f,st);
      for  l:=Nrows-1 Downto 0 do
      begin
        for k:=0 to NCols-1 do
        begin
        inputcol:=k+(upper+i)*ncols;
        inputrow:=l+(upper+j)*nrows;
          Read(F,Grid[inputcol,inputrow]);
        end;
      end;
      closefile(f);
    end else
    begin
      continue;
    end;
    //Testing of data has finished. Now it is read into Ram!!!
  end;
  filemode:=2;
end;


Procedure IndlaesGRIDlib5km(X0,Y0,Z0:real;Libnam:string);
var
  i,j,k,l:integer;
  lower,upper:integer;
  first_read:boolean;
  st:string;
  ncols,nrows:integer;
  center:boolean;
  cellsize:real;
  oldncols,oldnrows:integer;
  oldcenter:boolean;
  oldcellsize:real;
  LLX,LLY:integer;
  sta:strarray;
  subdir:string;
  DTMnavn,Fnavn:string;
  f:textfile;
  startX,startY:real;
  inputcol,inputrow:integer;
  GridLowerLeftX,GridLowerLeftY:real;

begin
  if LibNam[length(libnam)]<>'\' then libnam:=libnam+'\';
  lower:=-2;
  upper:=2;
  GridLowerLeftX:=(trunc(X0/5000)*5+lower*5)*1000;
  GridLowerLeftY:=(trunc(Y0/5000)*5+lower*5)*1000;
  first_read:=false;
  filemode:=0;
  for j:= lower to upper do
  for i:= lower to upper do
  begin
    LLx:=trunc(X0/5000)*5+i*5;
    LLy:=trunc(Y0/5000)*5+j*5;

    if fileexists(PChar(Libnam+DG_Lib_pref+'5km_'+inttostr(LLy)+'_'+inttostr(LLx)+'.asc')) then
    DTMnavn:=Libnam+DG_Lib_pref+'5km_'+inttostr(LLy)+'_'+inttostr(LLx)+'.asc' else
    begin
      subdir:=inttostr(trunc(LLy/10))+'_'+inttostr(trunc(LLx/10))+'\';
      DTMnavn:=Libnam+subdir+DG_Lib_pref+'5km_'+inttostr(LLy)+'_'+inttostr(LLx)+'.asc';
      Fnavn:=Libnam+DG_Lib_pref+'5km_'+inttostr(LLy)+'_'+inttostr(LLx)+'.asc';
      If fileexists(Pchar(Fnavn)) then DTMnavn:=Fnavn;
    end;

    If fileexists(Pchar(DTMnavn)) then
    begin
      AssignFile(f,Pchar(DTMnavn));
      reset(f);
      Readln(f,st);Disect(sta,st);ncols:=StrtoInt(Sta[2]);
      Readln(f,st);Disect(sta,st);nrows:=StrtoInt(Sta[2]);
      Readln(f,st);Disect(sta,st);if UpperCase(sta[1])='XLLCENTER' then Center:=true else center:=false;
      Readln(f,st);Disect(sta,st);      Readln(f,st);Disect(sta,st);cellsize:=StrtoFloat(sta[2]);
      closefile(f);
      if first_read then //if we have read one file header, we can compare to check for identical headers.
      begin
        If ((oldncols<>ncols) or (oldnrows<>nrows) or(oldcenter<>center) or(oldcellsize<>cellsize)) then
        //raise an exception
        raise ERangeError.Create('ERROR!!! Grid quad headers in library are not uniform)');
      end;
      first_read:=true; //first
      oldncols:=ncols; oldnrows:=nrows; oldcenter:=center; oldcellsize:=cellsize;
    end else
    begin
      sl('ERROR!!! Library block '+DTMnavn+' is missing');
      continue;
    end;
    //Testing of data has finished. Now it is read into Ram!!!
  end;
  GridCellSize:=cellsize;
  GridNcols:=ncols*(upper*2+1);
  GridNrows:=nrows*(upper*2+1);
  SetLength(Grid,GridNCols);
  for i:=0 to GridNCols-1 do
    SetLength(Grid[i],GridNRows);
  for j:= 0 to GridNcols-1 do
  for i:= 0 to GridNrows-1 do
    Grid[i,j]:=0;
  LLx:=trunc(X0/1000)+lower*5;
  LLy:=trunc(Y0/1000)+lower*5;
  subdir:=inttostr(trunc(LLy/10))+'_'+inttostr(trunc(LLx/10))+'\';
  DTMnavn:=Libnam+subdir+DG_Lib_pref+'5km_'+inttostr(LLy)+'_'+inttostr(LLx)+'.asc';
  Fnavn:=Libnam+DG_Lib_pref+'5km_'+inttostr(LLy)+'_'+inttostr(LLx)+'.asc';
  startX:= GridLowerLeftX;
  startY:= GridLowerLeftY;
  If not Center then
  begin
    startX:=startX+0.5*gridcellsize;
    startY:=StartY+0.5*Gridcellsize;
  end;
  GridLL_X:=startX;GridLL_Y:=startY;
  for j:= lower to upper do
  for i:= lower to upper do
  begin
    LLx:=trunc(X0/5000)*5+i*5;
    LLy:=trunc(Y0/5000)*5+j*5;

    if fileexists(PChar(Libnam+DG_Lib_pref+'5km_'+inttostr(LLy)+'_'+inttostr(LLx)+'.asc')) then
    DTMnavn:=Libnam+DG_Lib_pref+'5km_'+inttostr(LLy)+'_'+inttostr(LLx)+'.asc' else
    begin
      subdir:=inttostr(trunc(LLy/10))+'_'+inttostr(trunc(LLx/10))+'\';
      DTMnavn:=Libnam+subdir+DG_Lib_pref+'5km_'+inttostr(LLy)+'_'+inttostr(LLx)+'.asc';
      Fnavn:=Libnam+DG_Lib_pref+'5km_'+inttostr(LLy)+'_'+inttostr(LLx)+'.asc';
      If fileexists(Pchar(Fnavn)) then DTMnavn:=Fnavn;
    end;

    If fileexists(Pchar(DTMnavn)) then
    begin
      AssignFile(f,Pchar(DTMnavn));
      reset(f);
      Readln(f,st);Disect(sta,st);ncols:=StrtoInt(Sta[2]);
      Readln(f,st);Disect(sta,st);nrows:=StrtoInt(Sta[2]);
      Readln(f,st);Disect(sta,st);if UpperCase(sta[1])='XLLCENTER' then Center:=true else center:=false;
      Readln(f,st);Disect(sta,st);Readln(f,st);Disect(sta,st);cellsize:=StrtoFloat(sta[2]);
      readln(f,st);
      for  l:=Nrows-1 Downto 0 do
      begin
        for k:=0 to NCols-1 do
        begin
        inputcol:=k+(upper+i)*ncols;
        inputrow:=l+(upper+j)*nrows;
          Read(F,Grid[inputcol,inputrow]);
        end;
      end;
      closefile(f);
    end else
    begin
      continue;
    end;
    //Testing of data has finished. Now it is read into Ram!!!
  end;
  filemode:=2;
end;

Procedure ReadDTMgrid(fnam:string);
var f:textfile;
    XLeft,XRight,Ytop,Ybottom : real;
    st:string;
    sta: strarray;
    pkttt: string;
    k1,k2,k3 : single;
    kk1,kk2  : single;
    CC,RR : Integer;
    i,j : integer;
    gvidA : array[1..5] of integer;

begin
  assignfile(f,pchar(fnam));
  reset(f);
  //File is read through to find extents
  XLeft    :=   10000000000;
  Xright   :=  -10000000000;
  Ybottom  :=   10000000000;
  Ytop     :=  -10000000000;
  While not eof(f) do
  begin
    readln(f,st);
    disect2(sta,st);
    k1:=StrToFloat(sta[GRk1]);
    k2:=StrToFloat(sta[GRk2]);
    if k1>Xright then Xright:=k1;
    if k1<XLeft then Xleft:=k1;
    if k2>Ytop then Ytop:=k2;
    if k2<Ybottom then Ybottom:=k2;
  end;
  //Find Gridwidth
  reset(f);
  for i:=1 to 5 do
  begin
    readln(f,st);
    disect2(sta,st);
    k1:=StrToFloat(sta[GRk1]);
    k2:=StrToFloat(sta[GRk2]);
    readln(f,st);
    disect2(sta,st);
    kk1:=StrToFloat(sta[GRk1]);
    kk2:=StrToFloat(sta[GRk2]);
    GvidA[i]:=round(abs(k1-kk1)+abs(k2-kk2)); //ASSUMPTION - not in random order
  end;
  GridCellSize:=100000000000;
  for i:=1 to 5 do
  if GvidA[i]<GridCellSize then
  GridCellSize:=GvidA[i];

  GridNCols:=round(abs(Xright-Xleft)/GridCellSize)+1;
  GridNRows:=round(abs(Ytop-Ybottom)/GridCellSize)+1;
  GridLL_X :=Xleft;
  GridLL_y :=Ybottom;

  sl('  Gridsize '+IntToStr(GridNcols)+'x'+IntToStr(GridNrows));
  sl('  GridSpacing '+FloatToStr(GridCellSize)+' m');
  SetLength(Grid,GridNCols);
  for i:=0 to GridNCols-1 do
    SetLength(Grid[i],GridNRows);

  for j:=0 to GridNRows-1 do
  for i:=0 to GridNCols-1 do
  Grid[i,j]:=-9999;
  reset(f);
  While not eof(f) do
  begin
    readln(f,st);
    disect2(sta,st);
    pkttt:=sta[1];
    k1:=StrToFloat(sta[GRK1]);
    k2:=StrToFloat(sta[GRK2]);
    k3:=StrToFloat(sta[GRk3]);
    CC:=Trunc((k1-GridLL_X)/GridCellSize);
    RR:=Trunc((k2-GridLL_Y)/GridCellSize);
    Grid[CC,RR]:=k3;
  end;
  closefile(f);
end;

end.
