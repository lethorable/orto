unit OrtoU;

{$MODE Delphi}

interface

uses
  DHM, constants, imageinterpolationu, FileInputOutput, InOutUtil, gridunit, inverses,
  SysUtils, Math;

procedure DoTheOrtho(fnam: string);

implementation


procedure calculateD;
begin
  if DRG = 'DEG' then
  begin
    ome := DegToRad(ome);
    phi := DegToRad(phi);
    kap := DegToRad(kap);
  end;
  if DRG = 'GRA' then
  begin
    ome := GradToRad(ome);
    phi := GradToRad(phi);
    kap := GradToRad(kap);
  end;
  D[1, 1] := cos(phi) * cos(kap);
  D[1, 2] := -cos(phi) * sin(kap);
  D[1, 3] := sin(phi);
  D[2, 1] := cos(ome) * sin(kap) + sin(ome) * sin(phi) * cos(kap);
  D[2, 2] := cos(ome) * cos(kap) - sin(ome) * sin(phi) * sin(kap);
  D[2, 3] := -sin(ome) * cos(phi);
  D[3, 1] := sin(ome) * sin(kap) - cos(ome) * sin(phi) * cos(kap);
  D[3, 2] := sin(ome) * cos(kap) + cos(ome) * sin(phi) * sin(kap);
  D[3, 3] := cos(ome) * cos(phi);
end;


procedure Dimension;
var
  i, j: integer;
begin

  //Allocation of RAM for the ortho in the array OA
  //The data in the array starts in (1,1)

  //isThern - if the input is a thermo image use ThermOA (which is an array of reals)
  if IsTherm then
  begin
    SetLength(ThermOA, MaxPixCol + 1);
    for i := 0 to MaxPixCol do
      SetLength(ThermOA[i], MaxPixRow + 1);

    for j := 0 to MaxPixRow do
      for i := 0 to maxPixCol do
        ThermOA[i, j] := -999;
  end
  else

    //Not thermal image - must be normal tiff
  begin
    if eightbit then
    begin
      SetLength(OA8, MaxPixCol + 1);
      for i := 0 to MaxPixCol do
        SetLength(OA8[i], MaxPixRow + 1);
    end
    else
    begin
      SetLength(OA16, MaxPixCol + 1);
      for i := 0 to MaxPixCol do
        SetLength(OA16[i], MaxPixRow + 1);
    end;
  end;
  //Input image must start in 0,0 therefore defined as below
  //  SetLength(BA,BilColMax);
  //  for i:=0 to BilColMax-1 do
  //    SetLength(BA[i],BilRowMax);
end;

function GetdrFromTable(r: real): real;
var
  d, t, tt: real;
  lower, upper: integer;
begin
  // [0, 10, 20, ...');
  d := r / distunit;
  lower := trunc(d);
  if lower >= DistTbl_i then
  begin
    GetdrFromTable := DistTbl[DistTbl_i] / 1000;
    exit;
  end;
  t := d - trunc(d);
  GetdrFromTable := (DistTbl[lower] + (DistTbl[lower + 1] - DistTbl[lower]) *
    (t / Distunit)) / 1000;
  //NB !!! Has been testet with an amateur camera
end;

procedure CalculateImageCoordinates(X, Y, Z: real; var x_dot, y_dot: real);
var
  Numerator_x, Numerator_y, Denominator: extended;
  r, rx, ry, dr, rr: real;
begin {colinerity equations are used. Numerator and denominator are calculated}
  Numerator_x := D_inv[1, 1] * (X - X0) + D_inv[1, 2] * (Y - Y0) + D_inv[1, 3] * (Z - Z0);
  Numerator_y := D_inv[2, 1] * (X - X0) + D_inv[2, 2] * (Y - Y0) + D_inv[2, 3] * (Z - Z0);
  Denominator := D_inv[3, 1] * (X - X0) + D_inv[3, 2] * (Y - Y0) + D_inv[3, 3] * (Z - Z0);

  x_dot := C * Numerator_x / Denominator;// - (XDH/1000);  //addition of PPA
  y_dot := C * Numerator_y / Denominator;// - (YDH/1000);

  x_dot := x_dot + XDH / 1000;
  y_dot := y_dot + YDH / 1000;

  r := sqrt((x_dot * x_dot) + (y_dot * y_dot)); //To get to mm

  //To save some multiplications
  rr := r * r;
  //in stead of LA1*r^1, LA3*r^3 ....  0, r^2 r^4
  dr := 0;
  if useLDP then
    dr := LA1 + LA3 * rr + LA5 * rr * rr + LA7 * rr * rr * rr;
  if UseLDT then
    dr := GetdrFromTable(r * 1000) / 1000;
  //.. saving a division.
  rx := x_dot * dr / r;
  ry := y_dot * dr / r;

  x_dot := x_dot + rx;
  y_dot := y_dot + ry;
end;

procedure CalculateColRow(x_dot, y_dot: real; var Col, Row: extended);
begin{USe the interior orientation to get pixel coordinates}
  col := D2_inv[1, 1] * (x_dot * 1000 - xx0 ) + D2_inv[1, 2] * (y_dot * 1000 - yy0 );
  row := D2_inv[2, 1] * (x_dot * 1000 - xx0 ) + D2_inv[2, 2] * (y_dot * 1000 - yy0 );
end;

procedure GetXY(col, row: integer; var x, y: real);
//Returns X,Y based on a Col, Row in the ortho.
begin
  x := ULX + Col * PixStr + 0.5 * PixStr;
  y := ULY - (Row * PixStr - 0.5 * PixStr);
end;

function GetQuickZ(col, row: integer): real;
  //To be used for (semi) true ortho. Z is calculated once and fetched directly
begin
  GetQuickZ := (ZA[col, row] / 100) - 200;
end;

procedure CreateOrtoFotoTherm;
var
  icol, irow: integer;
  ThisX, ThisY, ThisZ, x_dot, y_dot: real;
  ThisCol_dec, ThisRow_dec: extended;
  Pix: real;
  a, b: integer;
begin
  Invert2d(D2, D2_inv); {Invert i.o. matrix}
  Invert3d(D, D_inv);
  //  Form1.ProgressBar1.Min:=1;
  //  Form1.ProgressBar1.Max:=MaxPixRow;

  if STR then
  begin
    sl('inserting heights');
    for irow := 1 to MaxPixRow do
    begin
      for icol := 1 to MaxPixcol do
      begin
        GetXY(iCol, iRow, ThisX, ThisY);
        if usegrid then
          ThisZ := InterpolerZiGrid(ThisX, ThisY)
        else
          ThisZ := InterpolZ(ThisX, ThisY);
        ZA[iCol, iRow] := round(100 * (ThisZ + 200));
      end;
    end;
    UpdateZA;
  end;
  for irow := 1 to MaxPixRow do
  begin
    for icol := 1 to MaxPixcol do
    begin  //Here the ortho is calculated
      GetXY(iCol, iRow, ThisX, ThisY);

      if BPL then
        if insidePoly(thisx, thisy) = False then
        begin
          ThermOA[icol, irow] := -999;
          continue;
        end;
      if STR then
        thisZ := ZA[icol, irow] / 100 - 200
      else
      begin
        if usegrid then
          ThisZ := InterpolerZiGrid(ThisX, ThisY)
        else
          ThisZ := InterpolZ(ThisX, ThisY);
      end;

      CalculateImageCoordinates(ThisX, ThisY, ThisZ, x_dot, y_dot);

      CalculateColRow(x_dot, y_dot, ThisCol_dec, ThisRow_dec);
      if ((ThisCol_dec < 3) or (ThisRow_dec < 3) or (BilRowMax - ThisRow_dec < 3) or
        (BilColMax - ThisCol_dec < 3)) then
      begin

        Continue;

      end;
      InterpolatePixelInImageTherm(ThisCol_dec, ThisRow_dec, Pix);
      ThermOA[icol, irow] := Pix;
    end;
    //    form1.ProgressBar1.Position:=irow;
    //    application.ProcessMessages;
    //    form1.refresh;
  end; //End of ortho generation
end;

procedure CreateOrtofoto8;
var
  icol, irow: integer;
  ThisX, ThisY, ThisZ, x_dot, y_dot: real;
  ThisCol_dec, ThisRow_dec: extended;
  Pix: pixel8;
  a, b: integer;
begin
  Invert2d(D2, D2_inv); {Invert i.o. matrix}
  Invert3d(D, D_inv);
  //  Form1.ProgressBar1.Min:=1;
  //  Form1.ProgressBar1.Max:=MaxPixRow;

  if STR then
  begin
    sl('inserting heights');
    for irow := 1 to MaxPixRow do
    begin
      for icol := 1 to MaxPixcol do
      begin
        GetXY(iCol, iRow, ThisX, ThisY);
        if usegrid then
          ThisZ := InterpolerZiGrid(ThisX, ThisY)
        else
          ThisZ := InterpolZ(ThisX, ThisY);
        ZA[iCol, iRow] := round(100 * (ThisZ + 200));
      end;
    end;
    UpdateZA;
  end;
  for irow := 1 to MaxPixRow do
  begin
    for icol := 1 to MaxPixcol do
    begin  //Here the ortho is calculated
      GetXY(iCol, iRow, ThisX, ThisY);

      if BPL then
        if insidePoly(thisx, thisy) = False then
        begin
          OA8[icol, irow].r := BorderCollie;
          OA8[icol, irow].g := BorderCollie;
          OA8[icol, irow].b := BorderCollie;
          OA8[icol, irow].c := BorderCollie;
          continue;
        end;
      if STR then
        thisZ := ZA[icol, irow] / 100 - 200
      else
      begin
        if usegrid then
          ThisZ := InterpolerZiGrid(ThisX, ThisY)
        else
          ThisZ := InterpolZ(ThisX, ThisY);
      end;
      CalculateImageCoordinates(ThisX, ThisY, ThisZ, x_dot, y_dot);
      CalculateColRow(x_dot, y_dot, ThisCol_dec, ThisRow_dec);
      if ((ThisCol_dec < 3) or (ThisRow_dec < 3) or (BilRowMax - ThisRow_dec < 3) or
        (BilColMax - ThisCol_dec < 3)) then
        Continue;
      InterpolatePixelInImage8(ThisCol_dec, ThisRow_dec, Pix);
      OA8[icol, irow] := Pix;
    end;
    //    form1.ProgressBar1.Position:=irow;
    //    application.ProcessMessages;
    //    form1. refresh;
  end; //End of ortho calculation
end;

procedure CreateOrtofoto16;
var
  icol, irow: integer;
  ThisX, ThisY, ThisZ, x_dot, y_dot: real;
  ThisCol_dec, ThisRow_dec: extended;
  Pix: pixel16;
  a, b: integer;
begin
  Invert2d(D2, D2_inv); {Invert i.o. matrix}
  Invert3d(D, D_inv);
  //  Form1.ProgressBar1.Min:=1;
  //  Form1.ProgressBar1.Max:=MaxPixRow;

  if STR then
  begin
    sl('inserting heights');
    for irow := 1 to MaxPixRow do
    begin
      for icol := 1 to MaxPixcol do
      begin
        GetXY(iCol, iRow, ThisX, ThisY);
        if usegrid then
          ThisZ := InterpolerZiGrid(ThisX, ThisY)
        else
          ThisZ := InterpolZ(ThisX, ThisY);
        ZA[iCol, iRow] := round(100 * (ThisZ + 200));
      end;
    end;
    UpdateZA;
  end;
  for irow := 1 to MaxPixRow do
  begin
    for icol := 1 to MaxPixcol do
    begin  //Here the ortho is calculated
      GetXY(iCol, iRow, ThisX, ThisY);
      if BPL then
        if insidePoly(thisx, thisy) = False then
        begin
          OA16[icol, irow].r := BorderCollie;
          OA16[icol, irow].g := BorderCollie;
          OA16[icol, irow].b := BorderCollie;
          OA16[icol, irow].c := BorderCollie;
          continue;
        end;
      if STR then
        thisZ := ZA[icol, irow] / 100 - 200
      else
      begin
        if usegrid then
          ThisZ := InterpolerZiGrid(ThisX, ThisY)
        else
          ThisZ := InterpolZ(ThisX, ThisY);
      end;
      CalculateImageCoordinates(ThisX, ThisY, ThisZ, x_dot, y_dot);
      CalculateColRow(x_dot, y_dot, ThisCol_dec, ThisRow_dec);
      if ((ThisCol_dec < 3) or (ThisRow_dec < 3) or (BilRowMax - ThisRow_dec < 3) or
        (BilColMax - ThisCol_dec < 3)) then
        Continue;
      InterpolatePixelInImage16(ThisCol_dec, ThisRow_dec, Pix);
      OA16[icol, irow] := Pix;
    end;
    //    form1.ProgressBar1.Position:=irow;
    //    application.ProcessMessages;
    //    form1. refresh;
  end; //End of ortho calculation
end;

procedure CalculateGradientMap;
var
  irow, icol, a, b: integer;
  tmp: real;
  ThisX, ThisY, NX, NY, Z1, Z2: real;
begin
  sl('GradCalc');
  //  form1.refresh;
  for irow := 2 to MaxPixRow - 1 do
    for icol := 2 to MaxPixcol - 1 do
      GradientMap[icol, Irow] := False;

  //  Form1.ProgressBar1.Min:=1;
  //  Form1.ProgressBar1.Max:=MaxPixRow;

  for irow := 2 to MaxPixRow - 1 do
  begin
    for icol := 2 to MaxPixcol - 1 do
    begin
      for b := -1 to 1 do
        for a := -1 to 1 do
          if sqrt(Sqr(ZA[icol, irow] - ZA[icol + a, irow + b])) > (5.2) then
            GradientMap[icol, irow] := True;
    end;
{    form1.ProgressBar1.Position:=irow;
    application.ProcessMessages;
    form1. refresh;}
  end;
end;

procedure CalculateShadowMap;
var
  irow, icol, a, b, i, cpcol, cprow: integer;
  alpha, beta, epx, epy, len, llen: extended;
  Count: integer;
  konhoej: extended;
  O_col, O_row: real;
  ThisX, ThisY: real;
  Extraheight: real;
  SearchDist: integer;
  tCol, tRow: integer;
  cpX, cpY: real;
begin
  sl('ShadCalc');
  //form1.Refresh;
  Extraheight := Z0 / 2.5;
  SearchDist := 220;
  O_col := round((X0 - ULx + 0.5 * pixstr) / PixStr);
  O_row := round((-Y0 + ULy + 0.5 * pixstr) / PixStr);
  for irow := 1 to MaxPixRow do
    for icol := 1 to MaxPixcol do
      ShadowMap[icol, irow] := True;

  //  Form1.ProgressBar1.Min:=1;
  //  Form1.ProgressBar1.Max:=MaxPixRow;

  for irow := 1 to MaxPixRow do
  begin
    for icol := 1 to MaxPixcol do
      if GradientMap[icol, Irow] then
      begin
        len := sqrt(sqr(icol - o_col) + sqr(irow - o_row));
        if len <= 30 then
          continue;
        if (len * pixStr) > (Z0) then
          continue; //Ought to be out of reach
        epx := (icol - o_col) / len;
        epy := (irow - o_row) / len;
        konhoej := GetQuickZ(icol, irow);     //pixel suspected to shadow
        alpha := ((Z0 - (konhoej + extraheight)) / PixStr) / len;

        //2 to avoid division by zero... 0.5 to close the mesh. 10 =2*5.
        for i := 2 to searchdist + 10 do
        begin
          cpcol := Round(icol + epx * i * 0.5);
          cprow := Round(irow + epy * i * 0.5);
          llen := Sqrt(sqr(cpcol - icol) + sqr(cprow - irow));
          if (cpcol <= 0) or (cpcol >= Maxpixcol) or (cprow <= 0) or
            (cprow >= Maxpixrow) then
            break;
          Beta := ((konhoej - GetQuickZ(cpcol, cprow)) / pixStr) / llen;
          if Beta >= Alpha then
            ShadowMap[cpcol, cprow] := False;
        end;
      end;
    //   form1.ProgressBar1.Position:=irow;
    //   application.ProcessMessages;
    //   form1. refresh;
  end;


  for irow := 1 to MaxPixRow do
    for icol := 1 to MaxPixcol do
      GradientMap[icol, Irow] := ShadowMap[icol, irow];


  sl('DilCalc');
  //  form1.Refresh;


  //  Form1.ProgressBar1.Min:=1;
  //  Form1.ProgressBar1.Max:=MaxPixRow;


  //Dillate
  for irow := 2 to MaxPixRow - 1 do
  begin
    for icol := 2 to MaxPixcol - 1 do
    begin
      if ShadowMap[icol, Irow] = False then
        for b := -1 to 1 do
          for a := -1 to 1 do
            GradientMap[icol + a, irow + b] := False;
    end;
    //    form1.ProgressBar1.Position:=irow;
    //    application.ProcessMessages;
    //    form1. refresh;
  end;
  //Test below to check if all except one or two pixels around one pixel is black. If so the pixel itself is black
  sl('SmoothCalc1');
  //  form1.Refresh;

  //  Form1.ProgressBar1.Min:=1;
  //  Form1.ProgressBar1.Max:=MaxPixRow;


  for irow := 1 to MaxPixRow do
    for icol := 1 to MaxPixcol do
      ShadowMap[icol, Irow] := GradientMap[icol, irow];

  for irow := 2 to MaxPixRow - 1 do
  begin
    for icol := 2 to MaxPixcol - 1 do
      if ShadowMap[icol, irow] = True then
      begin
        Count := 0;
        for b := -1 to 1 do
          for a := -1 to 1 do
            if GradientMap[icol + a, irow + b] = False then
              Inc(Count);

        if Count >= 7 then
          ShadowMap[icol, irow] := False;
      end;
    //    form1.ProgressBar1.Position:=irow;
    //    application.ProcessMessages;
    //    form1. refresh;
  end;
  //Same procedure, once again (could be coded nicer)

  sl('SmoothCalc2');
  //  form1.Refresh;

  //  Form1.ProgressBar1.Min:=1;
  //  Form1.ProgressBar1.Max:=MaxPixRow;


  for irow := 1 to MaxPixRow do
    for icol := 1 to MaxPixcol do
      GradientMap[icol, Irow] := ShadowMap[icol, irow];

  for irow := 2 to MaxPixRow - 1 do
  begin
    for icol := 2 to MaxPixcol - 1 do
      if ShadowMap[icol, irow] = False then
      begin
        Count := 0;
        for b := -1 to 1 do
          for a := -1 to 1 do
            if ShadowMap[icol + a, irow + b] = True then
              Inc(Count);
        if Count >= 6 then
          GradientMap[icol, irow] := True;
      end;
    //    form1.ProgressBar1.Position:=irow;
    //    application.ProcessMessages;
    //    form1. refresh;
  end;
end;

procedure BlackOut;
var
  i: integer;
  icol, irow: integer;
begin

  SetLength(GradientMap, MaxPixCol + 1);
  for i := 0 to MaxPixCol do
    SetLength(GradientMap[i], MaxPixRow + 1);

  SetLength(ShadowMap, MaxPixCol + 1);
  for i := 0 to MaxPixCol do
    SetLength(ShadowMap[i], MaxPixRow + 1);

  CalculateGradientMap;
  CalculateShadowMap;

  for irow := 1 to MaxPixRow do
    for icol := 1 to MaxPixcol do
    begin
      if IsTherm then
      begin
        if GradientMap[icol, irow] = False then
        begin
          ThermOA[icol, irow] := -999;
        end;
      end;

      if eightbit then
      begin
        if GradientMap[icol, irow] = False then
        begin
          OA8[icol, irow].r := 0;
          OA8[icol, irow].g := 0;
          OA8[icol, irow].b := 0;
          OA8[icol, irow].c := 0;
        end;
      end
      else
      begin
        if GradientMap[icol, irow] = False then
        begin
          OA16[icol, irow].r := 0;
          OA16[icol, irow].g := 0;
          OA16[icol, irow].b := 0;
          OA16[icol, irow].c := 0;
        end;
      end;
    end;
end;

procedure DIMStr;
var
  i: integer;
begin
  SetLength(ZA, MaxPixCol + 1);
  for i := 0 to MaxPixCol do
    SetLength(ZA[i], MaxPixRow + 1);
end;

procedure RecalcTopLeft;
var
  a: integer;
  minx, maxx, miny, maxy: real;
begin
  minx := 10000000000000;
  MaxY := -10000000000000;
  minY := 10000000000000;
  MaxX := -10000000000000;
  for a := 1 to PPA_i do
  begin
    if PPA[a].x < minx then
      minx := PPA[a].x;
    if PPA[a].x > maxx then
      maxx := PPA[a].x;
    if PPA[a].y > maxy then
      maxy := PPA[a].y;
    if PPA[a].y < miny then
      miny := PPA[a].y;
  end;
  ULx := minX;
  ULy := Maxy;
  MaxPixCol := round((MaxX - MinX) / PixStr);
  MaxPixRow := round((MaxY - MinY) / PixStr);

  sl('Calculated dimension..:');
  sl('  Upper left X: ' + FloatToStr(ULx));
  sl('  Upper left Y: ' + FloatToStr(ULx));
  sl('  DimX: ' + IntToStr(MaxPixCol) + ' pixels');
  sl('  DimY: ' + IntToStr(MaxPixRow) + ' pixels');
end;


procedure CheckForTempDir;
begin
  if not DirectoryExists(TempDir) then
    if not CreateDir(TempDir) then
    begin
      sl('Cannot create ' + TempDir);
    end;
end;

procedure ValidateTopLeft;
begin
  ULx := trunc(ULX / PixStr) * PixStr;
  ULy := Round(ULY / PixStr) * PixStr;
end;



procedure DoTheOrtho;
var
  icol, irow: integer;
  i: integer;
  prgrs: integer;
  Convert: boolean;
  oldpixstr: real;
begin
  convert := False;

  prgrs := 0;


  if D[1, 1] = -999999999 then
    calculateD; //This true if OPK


  //  sl('Reading def-file: '+fnam);
  //  laes_konstanter(fnam);

  if STR then
  begin
    sl('Preparing SemiTrue');
    DIMStr;
  end;

  if rescaleparam <> 1 then
  begin
    oldPixStr := PixStr;
    PixStr := rescaleparam;
    sl('Rescaling ortho to ' + trim(Format('%5.3f', [PixStr])));
    MaxPixCol := round(OldPixStr * MaxPixCol / pixStr);
    MaxPixRow := round(OldPixStr * MaxPixRow / pixStr);
    sl('... cols: ' + IntToStr(MaxPixCol));
    sl('... rows: ' + IntToStr(MaxPixRow));
  end;

  if AutomodeX then
  begin
    ULX := round(X0 - MaxPixCol * PixStr / 2);
  end;

  if AutomodeY then
  begin
    ULY := round(Y0 + MaxPixRow * PixStr / 2);
  end;

  if BPL then
  begin
    sl('(Re)Dimensioning output to fit polygon constraint');
    RecalcTopLeft;
  end;

  ValidateTopLeft;

  if trim(DHM_name) <> '' then
  begin

    if uppercase(extractFileExt(DHM_name)) = '.TXT' then
    begin
      sl('Reading TIN (txt)');
      IndlaesTINtxt(X0 - pixstr * maxpixcol / 2, Y0 + pixstr * maxpixcol / 2,
        DHM_name, EntireBufMax, MiniBufMax, maxTrig);
      Inc(prgrs);
    end;

    if uppercase(extractFileExt(DHM_name)) = '.DTT' then
    begin
      sl('Reading Dot-Tin (dtt)');
      IndlaesTINdtt(X0 - pixstr * maxpixcol / 2, Y0 + pixstr * maxpixcol / 2,
        DHM_name, EntireBufMax, MiniBufMax, maxTrig);
      Inc(prgrs);
      //      form1.ProgressBar2.Position:=prgrs;
      //      application.processmessages;
    end;



    if uppercase(extractFileExt(DHM_name)) = '.HDR' then
    begin
      sl('Reading GRID (hdr/flt)');
      if Rot34 then
        ReadHDRFLT_rot(DHM_name)
      else
        ReadHDRFLT(DHM_name);
      UseGrid := True;
      Inc(prgrs);
      //      form1.ProgressBar2.Position:=prgrs;
      //      application.processmessages;
    end;

    if uppercase(extractFileExt(DHM_name)) = '.ASC' then
    begin
      sl('Reading GRID (asc)');
      ReadASCgrid(DHM_name);
      UseGrid := True;
      //    IndlaesTINtxt(X0-pixstr*maxpixcol/2,Y0+pixstr*maxpixcol/2,DHM_name,EntireBufMax,MiniBufMax, maxTrig);
      Inc(prgrs);
      //      form1.ProgressBar2.Position:=prgrs;
      //      application.processmessages;
    end;



    if uppercase(extractFileExt(DHM_name)) = '.CSV' then
    begin
      sl('Reading GRID (dtm)');
      ReadDTMgrid(DHM_name);
      UseGrid := True;
      //    IndlaesTINtxt(X0-pixstr*maxpixcol/2,Y0+pixstr*maxpixcol/2,DHM_name,EntireBufMax,MiniBufMax, maxTrig);
      Inc(prgrs);
      //      form1.ProgressBar2.Position:=prgrs;
      //      application.processmessages;
    end;
  end
  else
  begin
    if DHM_Lib <> '' then
    begin
      sl('Reading TIN from Lib');
      IndlaesTINlib(X0, Y0, Z0, DHM_lib, EntireBufMax, MiniBufMax);
      Inc(prgrs);
      //       form1.ProgressBar2.Position:=prgrs;
    end
    else
    begin
      sl('Reading GRID from Lib');
      UseGrid := True;
      if DG_Lib_tilesize = 1 then
        IndlaesGRIDlib(X0, Y0, Z0, DGL_lib);
      if DG_Lib_tilesize = 5 then
        IndlaesGRIDlib5km(X0, Y0, Z0, DGL_lib);
      Inc(prgrs);
      //       form1.ProgressBar2.Position:=prgrs;

    end;

  end;



  if Uppercase(ExtractFileExt(BilledFilNavn)) = '.ASC' then
  begin
    IsTherm := True;
    Indlaes_ASC(BilledFilNavn);
  end
  else
  begin
    sl('Reading image');
    Indlaes_tiff(BilledFilNavn);
  end;
  Inc(prgrs);
  sl('Allocating RAM for ortho');
  Dimension;
  Inc(prgrs);

  sl('Generating Ortho image');
  sl('Size: ' + IntToStr(MaxPixCol) + ' x ' + IntToStr(MaxPixRow));

  if IsTherm then
    CreateOrtoFotoTherm
  else
  begin
    if eightbit then
      CreateOrtoFoto8
    else
      CreateOrtoFoto16;
  end;
  Inc(prgrs);

  if STR then
  begin
    sl('Blacking out "hidden" areas');
    sl('Size: ' + IntToStr(MaxPixCol) + ' x ' + IntToStr(MaxPixRow));
    BlackOut;
  end;

  if IsTherm then
    OutPutMode := 'THERM';

  if OutPutMode = 'THERM' then
  begin
    sl('Writing Ortho: ASC');
    Skriv_ASC(OrtoFilNavn);
  end;

  if Outputmode = 'RGB' then
  begin
    sl('Writing Ortho: RGB tiled');
    if eightbit then
      Skriv_tiff8(OrtoFilNavn, 1)
    else
      Skriv_tiff16(OrtoFilNavn, 1);
    Skriv_tfw(OrtoFilNavn);
  end;

  if Outputmode = 'STRIPED' then
  begin
    sl('Writing Ortho: RGB striped');
    Skriv_tiff_old(OrtoFilNavn, 1);
    Skriv_tfw(OrtoFilNavn);
  end;

  if Outputmode = 'STRIPEDCIR' then
  begin
    sl('Writing Ortho: CIR striped');
    Skriv_tiff_old(OrtoFilNavn, 2);
    Skriv_tfw(OrtoFilNavn);
  end;

  if Outputmode = 'CIR' then
  begin
    sl('Writing Ortho: CIR tiled');
    if eightbit then
      Skriv_tiff8(OrtoFilNavn, 2)
    else
      Skriv_tiff16(OrtoFilNavn, 2);
    Skriv_tfw(OrtoFilNavn);
  end;

  if Outputmode = 'NDVI' then
  begin
    sl('Writing Ortho: NDVI tiled');
    if eightbit then
      Skriv_tiff8(OrtoFilNavn, 4)
    else
      Skriv_tiff16(OrtoFilNavn, 4);
    Skriv_tfw(OrtoFilNavn);
  end;

  if OutPutMode = 'BOTH' then
  begin
    sl('Writing Ortho: Dual output');
    sl('...writing RGB tiled');
    if eightbit then
      Skriv_tiff8(OrtoFilNavn, 1)
    else
      Skriv_tiff16(OrtoFilNavn, 1);
    Skriv_tfw(OrtoFilNavn);
    sl('...writing CIR tiled');
    if eightbit then
      Skriv_tiff8(changefileext(OrtoFilNavn, '_CIR.tif'), 2)
    else
      Skriv_tiff16(changefileext(OrtoFilNavn, '_CIR.tif'), 2);
    Skriv_tfw(changefileext(OrtoFilNavn, '_CIR.tif'));
  end;

  if OutPutMode = 'COMBI' then
  begin
    sl('Writing Ortho: combi tiled');
    if eightbit then
      Skriv_tiff8(OrtoFilNavn, 3)
    else
      Skriv_tiff16(OrtoFilNavn, 3);
    Skriv_tfw(OrtoFilNavn);
  end;

  if OrtoFilTN <> '' then
  begin
    sl('Writing thumbnail image');
    Skriv_tiff_tn8(OrtoFilTN);
  end;

  Inc(prgrs);

  if OrtoFilTN <> '' then
  begin
    sl('Writing world-file for thumbnail');
    Skriv_tfw_tn(OrtoFilTN);
  end;

  sl('End of execution');
end;




end.
