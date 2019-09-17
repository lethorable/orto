program orto;

{$MODE Delphi}

uses OrtoU, inverses, DHM, constants, imageinterpolationu, FileInputOutput, InOutUtil, gridunit,
	 
	 Math, sysUtils;

var fn: string;
     f: textfile;
	 a: integer;
     usedef:boolean;

begin
  decimalseparator:='.';
  SetDefaultParams;

  If Paramstr(1)<>'' then
  begin
    uselog:=true;
	
//    If Uppercase(Paramstr(2))='NOLOG' then uselog:=false else useLog:=true;

    for a:=1 to ParamCount do
    begin
      if Uppercase(Paramstr(a))='-DEF' then
      begin
        fn:=paramstr(a+1);
        usedef:=true;
      end;

      If UpperCase(Paramstr(a)) = '-I' then   billedfilnavn:= Paramstr(a+1);
      If UpperCase(Paramstr(a)) = '-O' then  OrtoFilNavn:=paramstr(a+1);

      if Uppercase(Paramstr(a)) = '-CON' then C:=StrToFloat(paramstr(a+1));

      If UpperCase(Paramstr(a)) = '-DTM' then
                                  begin
                                    If uppercase(extractFileExt(trim(Paramstr(a+1)))) = '.CSV' then
                                    begin
                                      DHM_name:=Paramstr(a+1);
                                      GRK1:=StrToInt(Paramstr(a+2));
                                      GRK2:=StrToInt(Paramstr(a+3));
                                      GRK3:=StrToInt(Paramstr(a+4));
                                    end else
                                    DHM_name:=Paramstr(a+1);
                                  end;

      If UpperCase(Paramstr(a)) = '-DTL' then  DHM_lib:=paramstr(a+1);
      If UpperCase(Paramstr(a)) = '-DGL' then  DGL_lib:=paramstr(a+1);

      If UpperCase(Paramstr(a)) = '-RES' then  PixStr:= StrToFloat(paramstr(a+1));
      If UpperCase(Paramstr(a)) = '-XDH' then  XdH:= StrToFloat(paramstr(a+1));
      If UpperCase(Paramstr(a)) = '-YDH' then  YdH:= StrToFloat(paramstr(a+1));
      If UpperCase(Paramstr(a)) = '-LDP' then
                                   begin
                                     UseLDP:=True;
                                     LA1:=  StrToFloat(UpperCase(paramstr(a+1)));
                                     LA3:=  StrToFloat(UpperCase(paramstr(a+2)));
                                     LA5:=  StrToFloat(UpperCase(paramstr(a+3)));
                                     LA7:=  StrToFloat(UpperCase(paramstr(a+4)));
                                   end;
      If UpperCase(Paramstr(a)) = '-TLX' then
                               Begin
                                 If Paramstr(a+1)='AUTO' then
                                 begin
                                   AutomodeX:=true;
                                 end else
                                 begin
                                   AutomodeX:=false;
                                   ULx:= StrToFloat(Paramstr(a+1));
                                 end;
                               end;
      If UpperCase(Paramstr(a)) = '-TLY' then
                               Begin
                                 If Paramstr(a+1)='AUTO' then
                                 begin
                                   AutomodeY:=true;
                                 end else
                                 begin
                                   AutomodeY:=false;
                                   ULy:= StrToFloat(Paramstr(a+1));
                                 end;
                               end;
      If UpperCase(Paramstr(a)) = '-SZX' then MaxPixCol:= StrToInt(Paramstr(a+1));
      If UpperCase(Paramstr(a)) = '-SZY' then MaxPixRow:= StrToInt(Paramstr(a+1));
      If UpperCase(Paramstr(a)) = '-IL1' Then
                              begin

                                 D2[1,1]:=strToFloat(Paramstr(a+1));
                                 D2[1,2]:=StrToFloat(Paramstr(a+2));
                              end;
      If UpperCase(Paramstr(a)) = '-IL2' Then
                              begin

                                 D2[2,1]:=strToFloat(Paramstr(a+1));
                                 D2[2,2]:=StrToFloat(Paramstr(a+2));
                              end;
      If UpperCase(Paramstr(a)) = '-IL3' Then
                              begin
                                 xx0:=strToFloat(Paramstr(a+1));
                                 yy0:=strToFloat(Paramstr(a+2));
                              end;
      If UpperCase(Paramstr(a)) = '-DRG' then DRG:=uppercase(Paramstr(a+1));
      If UpperCase(Paramstr(a)) = '-OME' then Ome:=StrToFloat(Paramstr(a+1));
      If UpperCase(Paramstr(a)) = '-PHI' then Phi:=StrToFloat(Paramstr(a+1));
      If UpperCase(Paramstr(a)) = '-KAP' then Kap:=StrToFloat(Paramstr(a+1));
      If UpperCase(Paramstr(a)) = '-X_0' Then X0:=StrToFloat(Paramstr(a+1));
      If UpperCase(Paramstr(a)) = '-Y_0' Then Y0:=StrToFloat(Paramstr(a+1));
      If UpperCase(Paramstr(a)) = '-Z_0' Then Z0:=StrToFloat(Paramstr(a+1));
      If UpperCase(Paramstr(a)) = '-DGP' then DG_Lib_pref:=Paramstr(a+1);
      If UpperCase(Paramstr(a)) = '-DGS' then DG_Lib_tilesize:=strtoInt(Paramstr(a+1));
      If UpperCase(Paramstr(a)) = '-OPM' then Outputmode:=uppercase(Paramstr(a+1));
	  If UpperCase(Paramstr(a)) = '-NOLOG' then uselog:=false;
    end;

	InitiateLogFile;
	
    if usedef then
    begin
      sl('Reading def-file: '+fn);
      laes_konstanter(fn);
    end;

    if not fileexists(fn) then
      fn:=GetCurrentDir+'\'+fn;

    try
        DoTheOrtho(fn);
    except
      on E:Exception do
      begin
        If EFnam = '!ORTO.ERR' then
        EFnam:=GetCurrentDir+'\'+EFnam;
        assignfile(f,EFnam);
        if FileExists(EFnam) then append(f) else rewrite(f);
        Writeln(f,'********************************');
        Writeln(f,dateTimeToStr(Now)+' Critical error');
        Writeln(f,'File parameters... ');
        if usedef then Writeln(f,'   DefFileName:   '+paramstr(1));
        Writeln(f,'           DTM=   '+DHM_Name);
        Writeln(f,'           ORT=   '+OrtoFilNavn);
        Writeln(f,'           IMG=   '+billedFilNavn);
        Writeln(f);
        Writeln(f,'Errormessage:  '+E.message);
        Writeln(f);
        closefile(f);
        sl('Abnormal program termination...: '+E.message);
        halt;
      end;
    end;
    halt;
  end Else
  begin
    writeln;
    writeln('  Orto version '+VERSION);
    WRITELN;
    writeln;
    writeln('  .o0o. OPTIONS .o0o.');
    writeln;
    writeln('  Call with either...:');
    writeln;
    writeln('          orto -def <def file> ');
    writeln('  or:');
    writeln('          orto -i <input> -o <output> -dtm <terrain file> ...... <>');
    writeln('          (refer to parameters below)');
	writeln;
	writeln('  use -NOLOG to suppress log file');
    writeln;
    writeln('  .o0o. BASIC FILE PARAMTERS .o0o.');
    writeln;
    writeln('  -I   aerial image (tiff file)');
    writeln('  -O   output ortho image (tiff file)');
    writeln('  -DTM Terrain model (.asc .csv ...) <xcol ycol zcol>');
    writeln('          If using a .csv file then xcol ycol zcol are column numbers ');
    writeln('          of x, y and z)');
    writeln;
    writeln('  .o0o. CAMERA PARAMETERS .o0o.');
    writeln;
    writeln('  -CON Principal distance (camera constant) untis [m], must be negative ');
    writeln('          (eg. -0.15012');
    writeln('  -XDH PPA (x'' offset from PPS to PPA units [mm])');
    writeln('  -YDH PPA (y'' offset from PPS to PPA units [mm])');
    writeln('  -LDP <A1 A3 A5 A7> (Lens distortion paramters)');
    writeln('  -IL1 <D11 D12>');
    writeln('  -IL2 <D21 D22>');
    writeln('  -IL3 <dx'' dy''>');
    writeln('          For most modern digital photogrammetric cameras this has been');
    writeln('          calibrated to be symmetric. IL1 and IL2 will have');
    writeln('          [IL1= pixelsize 0] and [IL2= 0 -pixelsize]. Pixel sizes are in');
    writeln('          units mm. IL3 are offset to PPS and can be calculated as');
    writeln('          [IL3 = -(imagewidth/2) (imageheight/2)] units [mm].');
    writeln;
    writeln('  .o0o. OUTPUT ORTHO PARAMTERS .o0o.');
    writeln;
    writeln('  -RES Resolution of output. Units [m] (ie. 0.1)');
    writeln('  -SZX Size of output in x-direction. Units [cols]');
    writeln('  -SZY Size of output in y-direction. Units [rows]');
    writeln('  -TLX Top left x coordinate ie. 603630.30');
    writeln('  -TLY Top left y coordinate ie. 6605640.20');
    writeln('         TLX and TLY can be set to AUTO. This centers the output image ');
    writeln('         around projection centre');
    writeln;
    writeln('  .o0o. AERIAL IMAGE PARAMETERS .o0o.');
    writeln;
    writeln('  -X_0 Projection centre X');
    writeln('  -Y_0 Projection centre Y');
    writeln('  -Z_0 Projection centre Z');
    writeln;
    writeln('  -DRG Units of rotation. Options are DEG RAD GRAD');
    writeln('  -OME Omega (rotation x-axis)');
    writeln('  -PHI Phi (rotation y-axis)');
    writeln('  -KAP Kappa (rotation z-axis)');
    writeln;
    writeln('  .o0o. FURTHER TERRAIN OPTIONS .o0o.');
    writeln;
    writeln('  -DTL Terrain Library (path to library of tin files)');
    writeln('  -DGL Grid Library (path to library of .asc grid files)');
    Writeln('  -DGP      Prefix for files in grid library');
    Writeln('  -DGS      Grid library tile size');
    writeln;
  end;
end.

