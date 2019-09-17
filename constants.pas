unit constants;

{$MODE Delphi}



interface


uses SysUtils, inverses, InOutUtil,

     math;



CONST VERSION = '2016-05-20';

Type Pixel8  = Record
                r,g,b,c : byte;
               end;

     Pixel16 = Record
                r,g,b,c : word;
               end;

Var
    ThermBA : Array of array of Real;

    ThermOA : Array of Array of Real;

    OA8   : Array of Array of pixel8;

    BA8   : Array of Array of pixel8;

    OA16   : Array of Array of pixel16;

    BA16   : Array of Array of pixel16;

    eightbit : boolean;

    ZA   : Array of Array of Word;

    GradientMap : array of Array of Boolean;

    ShadowMap   : array of Array of Boolean;


    DHM_name           :  String;            //File name of DHM
    DHM_lib            :  String;            //Path to library of DHM files
    DGL_lib            :  String;

    DG_Lib_pref        :  String;            //Prefix for files in the DHM library (ie "DTM_")

    DG_lib_tilesize    : integer;



    GRK1,GRK2,GRK3  : integer;


    PexFnam       : string;
    Billednummer  : String;
    BilledFilNavn       : String;       //File name of the input aerial image
    BilColMax,BilRowMax : integer;      //Number of cols and rows in the image



    D2,D2_inv   : mat2d;    //Interior orientation rotation matrix - and its inverted matrix
    xx0,yy0     : real;                 // x´0 og y´0

    C           : Real;                 //Camera konstant, Must be negative (i.e. -0.152002)

    X0,Y0,Z0    : Real;                 //Image exposure world coordinates
    D, D_inv    : mat3d;      //Rotation matrix and its inverted matrix. Order of rotation must be 1)omega (x) 2)phi (y) 3) kappa (z)

    Ome,Phi,Kap : Real;                 //Omega, phi and kappa - only used if no rotation matrix is in the input.

    OrtoFilNavn : String;               //Name of the new ortho

    OrtoFilTN   : String;               //Name of thumbnail

    PixStr               : Real;        // Pixel size in the generated ortho
    MaxPixCol,MaxPixRow  : integer;     // Dimension of the ortho
    ULx,ULy,LRx,LRy      : Real;        //Coordinates to corners Upper Left and Lower Right

    STR                  : Boolean;     // SemiTrue output (hidden pixels are blacked out)

    BPL                  : Boolean;

    channels             : byte;        // 1 = grays, 3 = rgb

    Rot34                : boolean;
    MiniBufMax           : integer;
    EntireBufMax         : integer;

    Interpol             : byte;  //0 = direct, 1 = bilinear, 2 = bicubic
    PolParam             : Real; //Parameter for bicubic interpolation

    MaxTrig              : integer;

    AutoModeX,AutoModeY  : boolean; //Center the ortho automatically

    EFnam                : string;

    BorderCollie         : Byte;

    OrtoLogName          : string;

    XdH, YdH             : real;

    LA1, LA3, LA5, LA7   : real;

    DRG                  : String[3];

    TempDir,TempFile     : String;

    InputFormat,GDALpar, GdalPath, IrfanPath,IrfanPar, ISRUPath, ISRUpar  : String;

    AlmostBlackValue    : boolean;

    UseLog              :Boolean;

    CIRInputImage       : Boolean; //If input image is a 4-channel picture, this will be set as "TRUE"

    OutputMode          : String;

    RescaleParam        : real;

    IsTherm             : Boolean;

    DistTbl             : Array[0..100] of real;
    DistUnit            : real;
    DistTbl_i           : integer;

    KMLfile             : boolean;
    KMLtransparam       : String;

    UseLDP, UseLDT      : boolean;


type strarray= array[1..100] of string;


Procedure SetDefaultParams;
Procedure laes_konstanter(fnam:string);

Procedure disect(var st1:strarray;st2:string);
implementation

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





Procedure SetDefaultParams;
begin
  UseLDP:=false;UseLDT:=false;
  DistTbl_i:=0;
  IsTherm:=False;
  STR:=False;  //Ortho is NOT calculated semi-true as default
  EFnam:='!ERROR.ERR';
  OrtoLogName := 'Orto.log';
  BPL:=False; //nothing is blacked out by default
  Interpol:=2; PolParam:=-1; //Bicubic convolution is default
  DRG:='DEG'; //Default for angle-units is degrees (360 = 2pi)
  XdH:=0;  YdH:=0; //PPA is set to zero default
  LA1:=0;  LA3:=0;  LA5:=0;  LA7:=0;  //Lens distortion is set to zero default
  Ome:=0;Phi:=0;Kap:=0; //omega, phi kappa
  PixStr:=0.25; // 25 cm is default resolution
  AutomodeX:= True; AutomodeY:=True; //TopLeft pix is per default calculated automatic.
  MaxPixCol:=1000; MaxPixRow:=1000; //Per default the ortho size is 1000x1000 pixels
  Rot34:=False; //Per default, imagery is not rotated to accommodate Danish system 34.
  MiniBufMax:= 870; //Minibuffer is set to 870 triangles (dunno why but works!!)
  EntireBufMax:= 999999; //Max number of triangles to store in buffer (dunno why, but works also!!!)
  InputFormat:='';
  TempDir:='C:\Temp\';
  DHM_name:='';
  DHM_lib:='';
  OrtoFilTN:='';
  DG_Lib_pref:='';
  DG_lib_tilesize:=1;
  OutputMode:='RGB';
  RescaleParam:=1;
  eightbit:=true;
  KMLfile:=false;
  AlmostBlackValue:=True;
  D[1,1]:=-999999999; //To check later if anything has been entered - -999999999 is the dummy value.
end;


Procedure laes_konstanter(fnam:string);
var f:textfile;
    st4 : String[4];
    st3 : String[3];
    a:integer;
    St,st2 : String;
    sta:strarray;
    aa:integer;
begin
  SetDefaultParams;
  AssignFile(f,fnam);
  Reset(f);
  STR:=False;
  While not eof(f) do
  begin
    st4:='        ';
    st2:='        ';
    Readln(f,st2);
    st4:=st2;
    If st4[4]='=' then
    begin
      st:='';
      for a:= 5 to length(st2) do st:=st+st2[a];
      st3:='';
      for a:=1 to 3 do
      St3:=st3+St4[a];



      If UpperCase(st3) = 'CON' then
                               C:=StrToFloat(trim(st));

      If UpperCase(St3) = 'DTM' then
                               begin
                                 Disect(sta,st);
                                 If uppercase(extractFileExt(trim(sta[1]))) = '.CSV' then
                                 begin
                                   DHM_name:=Trim(sta[1]);
                                   GRK1:=StrToInt(Trim(sta[2]));
                                   GRK2:=StrToInt(Trim(sta[3]));
                                   GRK3:=StrToInt(Trim(sta[4]));
                                 end else
                                 DHM_name:=Trim(st);

                               end;

      If UpperCase(st3) = 'DTL' then
                               DHM_lib:=Trim(st);

      If UpperCase(st3) = 'DGL' then
                               DGL_lib:=Trim(st);

      If UpperCase(st3) = 'ORT' then
                               OrtoFilNavn:=Trim(st);

      If UpperCase(st3) = 'OTN' then
                               OrtoFilTN:=Trim(st);

      If UpperCase(st3) = 'LOG' then
                               OrtoLogName:=Trim(st);

      If UpperCase(St3) = 'RES' then
                               PixStr:= StrToFloat(Trim(st));

      If UpperCase(St3) = 'XDH' then
                               XdH:= StrToFloat(Trim(st));

      If UpperCase(St3) = 'YDH' then
                               YdH:= StrToFloat(Trim(st));

      If UpperCase(St3) = 'LDP' then
                               begin
                                 UseLDP:=True;
                                 Disect(sta,st);
                                 LA1:=  StrToFloat(Trim(UpperCase(sta[1])));
                                 LA3:=  StrToFloat(Trim(UpperCase(sta[2])));
                                 LA5:=  StrToFloat(Trim(UpperCase(sta[3])));
                                 LA7:=  StrToFloat(Trim(UpperCase(sta[4])));
                               end;

      If UpperCase(St3) = 'TLX' then
                               Begin
                                 If Trim(st)='AUTO' then
                                 begin
                                   AutomodeX:=true;
                                 end else
                                 begin
                                   AutomodeX:=false;
                                   ULx:= StrToFloat(Trim(st));
                                 end;
                               end;
      If UpperCase(St3) = 'TLY' then
                               Begin
                                 If Trim(st)='AUTO' then
                                 begin
                                   AutomodeY:=true;
                                 end else
                                 begin
                                   AutomodeY:=false;
                                   ULy:= StrToFloat(Trim(st));
                                 end;
                               end;

      If UpperCase(St3) = 'SZX' then
                               MaxPixCol:= StrToInt(Trim(st));
      If UpperCase(St3) = 'SZY' then
                               MaxPixRow:= StrToInt(Trim(st));

      IF UpperCase(St3) = 'STR' then
                               begin
                                 If UpperCase(Trim(st)) = 'YES' then
                                   STR:=True else
                                   STR:=False;
                               end;

      If UpperCase(St3) = 'BPL' then
                              begin
                                PPA_i:=0;
                                if uppercase(Trim(st)) <>'NO' then
                                begin
                                  disect(sta,st);
                                  BPL:= True;
                                  PPA_i:=StrToInt(Trim(sta[1]));
                                  BorderCollie:=StrToInt(Trim(Sta[2]));
                                end;
                                for aa:=1 to PPA_i do
                                begin
                                  read(f,st4);
                                  if uppercase(st4)='BP'+inttostr(aa)+'=' then
                                  begin
                                    read(f,PPA[aa].x);
                                    readln(f,PPA[aa].y);
                                  end else
                                  begin
                                    ppa_i:=round(ppa_i/0); //for at slutte programmet med en fejl...
                                  end;
                                end;
                              end;


      If UpperCase(St3) = 'INT' then
                               begin
                                 Disect(sta,st);
                                 if Trim(UpperCase(sta[1]))='BIL' then interpol:=1 else
                                 if Trim(UpperCase(sta[1]))='CUB' then
                                 begin
                                   Interpol:=2;
                                   if sta[2]='' then PolParam:=-1 else PolParam:=StrToFloat(sta[2]);
                                 end else
                                 if Trim(UpperCase(sta[1]))='BET' then Interpol:=3 else
                                 interpol:=0;
                               end;

      If UpperCase(St3) = 'IMG' then
                               billedfilnavn:= Trim(st);
      If UpperCase(St3) = 'R34' then
                               Begin
                                 If Uppercase(Trim(st))= 'YES' then Rot34:=TRUE else Rot34:=false;
                               end;
      If UpperCase(St3) = 'MBF' then
                               MiniBufMax:=StrToInt(Trim(st));
      If UpperCase(St3) = 'BBF' Then
                               EntireBufMax:=StrToInt(Trim(st));

      If UpperCase(St3) = 'IL1' Then
                               begin
                                  Disect(sta,st);
                                  D2[1,1]:=strToFloat(sta[1]);
                                  D2[1,2]:=StrToFloat(sta[2]);
                               end;

      If UpperCase(St3) = 'IL2' Then
                               begin
                                  Disect(sta,st);
                                  D2[2,1]:=strToFloat(sta[1]);
                                  D2[2,2]:=StrToFloat(sta[2]);
                               end;

      If UpperCase(St3) = 'IL3' Then
                               begin
                                  Disect(sta,st);
                                  xx0:=strToFloat(sta[1]);
                                  yy0:=StrToFloat(sta[2]);
                               end;

      If UpperCase(st3) = 'DRG' then
                               DRG:=Trim(st);

      If UpperCase(St3) = 'OME' then
                               Ome:=StrToFloat(Trim(st));

      If UpperCase(St3) = 'PHI' then
                               Phi:=StrToFloat(Trim(st));

      If UpperCase(St3) = 'KAP' then
                               Kap:=StrToFloat(Trim(st));

      If UpperCase(st3) = 'XL1' Then
                                begin
                                  Disect(sta,st);
                                  D[1,1]:=strToFloat(sta[1]);
                                  D[1,2]:=StrToFloat(sta[2]);
                                  D[1,3]:=StrToFloat(sta[3]);
                                end;

      If UpperCase(st3) = 'XL2' Then
                                begin
                                  Disect(sta,st);
                                  D[2,1]:=strToFloat(sta[1]);
                                  D[2,2]:=StrToFloat(sta[2]);
                                  D[2,3]:=StrToFloat(sta[3]);
                                end;

      If UpperCase(st3) = 'XL3' Then
                                begin
                                  Disect(sta,st);
                                  D[3,1]:=strToFloat(sta[1]);
                                  D[3,2]:=StrToFloat(sta[2]);
                                  D[3,3]:=StrToFloat(sta[3]);
                                end;

      If UpperCase(st3) = 'X_0' Then X0:=StrToFloat(Trim(st));
      If UpperCase(st3) = 'Y_0' Then Y0:=StrToFloat(Trim(st));
      If UpperCase(st3) = 'Z_0' Then Z0:=StrToFloat(Trim(st));

      If UpperCase(st3) = 'ERR' then
                               EFnam:=Trim(St);

      If UpperCase(st3) = 'TMP' then
                               Begin
                                 TempDir:=Trim(st);
                                 If TempDir[length(TempDir)]<>'\' then tempDir:=tempDir+'\';
                               end;
      If UpperCase(st3) = 'IFT' then
                               InputFormat:=Trim(st);


      If UpperCase(st3) = 'ABV' then
                                 if trim(Uppercase(st))= 'NO' then AlmostBlackValue:=False else AlmostBlackValue:=True;

      If UpperCase(st3) = 'DGP' then
                               DG_Lib_pref:=Trim(st);

      If UpperCase(st3) = 'DGS' then
                               DG_Lib_tilesize:=strtoInt(Trim(st));

      If UpperCase(st3) = 'OPM' then
                               Outputmode:=uppercase(Trim(st));

      If Uppercase(st3) = 'RSC' then RescaleParam:=StrToFloat(trim(st));

      //Lens distortion as a table - ALL three paramters must be present (DSI, DSD, DST)!

      If Uppercase(st3) = 'DSI' Then
                                Begin
                                  UseLDT:=True;
                                  DistTbl_i:=StrToInt(trim(st))-1;
                                  for aa:=0 to DistTbl_i do DistTbl[aa]:=0;
                                end;

      If Uppercase(st3) = 'DSD' then DistUnit:=StrToFloat(trim(st));

      If uppercase(st3) = 'DST' then
                                begin
                                  Disect(sta,st);
                                  for aa:=0 to DistTbl_i do DistTbl[aa]:=StrToFloat(sta[aa+1]);
                                end;
      If Uppercase(st3) = 'KML' then If Uppercase(Trim(st))= 'YES' then KMLfile:=TRUE else kmlfile:=FALSE;

    end;
  end;

  Closefile(f);
//  If D[1,1] = -999999999 then calculateD; //If no D-matrix has been input, it needs to be calculated.
end;




end.
