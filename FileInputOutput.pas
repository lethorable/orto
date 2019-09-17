unit FileInputOutput;

{$MODE Delphi}

interface

uses SysUtils,	constants, Math;


var     log       : textfile;

Procedure InitiateLogFile;

Procedure sl(tt:string);



Procedure WriteOrtofoto8;
Procedure indlaesBWfil(fnam:string);
Procedure IndlaesRGBfil(fnam:String);
Procedure Indlaes_billede(fnam:string);

Procedure Indlaes_ASC(fnam:string);

Procedure Indlaes_tiff(fnam:string);
Procedure Skriv_tiff8(fnam:string;Omode:byte);
Procedure Skriv_tiff16(fnam:string;Omode:byte);
Procedure Skriv_tiff_old(fnam:string;Omode:byte);
Procedure Skriv_tiff_tn8(fnam:string);

Procedure Skriv_ASC(OrtoFilNavn:string);



Procedure Skriv_tfw(fnam:string);
Procedure Skriv_tfw_tn(fnam:string);

implementation


Type


     valuetype = record
                   A   : Array[1..32] of byte;
                   A_I : integer;
                 end;



Function tstr:string;
begin
 Tstr:=dateTimeToStr(Now);
end;


Procedure InitiateLogFile;
var st:string;
begin
 If useLog then
 begin
   OrtoLogName := 'Orto.log'; //NB!! Uhensigtsmæssigt at det ligesom kommer her.
                              //Hvis man angiver log= i logfilen, redirectes loggen!!!
  AssignFile(log,OrtoLogName);

  If FileExists(OrtoLogName)  then
  begin
    Append(Log);
  end else
  begin
    Rewrite(log);
    Writeln(log,'');
    Writeln(log,'Logfile created: '+tstr);
  end;
  Writeln(log);
  Writeln(log);
  Writeln(log);
  Writeln(log,'**************************************************');
  Writeln(log,'       New ortho image started '+tstr);
  Writeln(log,'**************************************************');
  Writeln(log);
  closefile(log);
 end;
end;

Procedure sl(tt:string);
begin
  Writeln(tstr+'    '+tt);
  If Uselog then
  begin
    assignfile(log,OrtoLogName);
    Append(log);
    Writeln(log,tstr+'    '+tt);
    closefile(log);
  end;
end;

Procedure Esl(tt:string);
begin
  Append(log);
  Writeln(log,tstr+'    '+tt);
  closefile(log);
end;



Procedure Indlaes_ASC(fnam:string);
var f:textfile;
   st:string;
   sta:strArray;
   aaa,bbb:integer;
   tv:real;
begin
  assignFile(f,Pchar(fnam));
  reset(f);
  readln(f,st);
  disect(sta,st);
  BilColMax:=StrToInt(Sta[2]);
  readln(f,st);
  disect(sta,st);
  BilRowMax:=StrToInt(Sta[2]);


  SetLength(ThermBA,bilColMax); //Cols
  for aaa:=0 to BilColMax-1 do
  SetLength(ThermBA[aaa],BilRowMax);  //Rows
  readln(f,st);
  readln(f,st);
  readln(f,st);
  readln(f,st); //nodata value;
  for bbb:=0 to BilRowMax-1 do
  begin
    for aaa:=0 to BilColMax-1 do
    begin
      Read(f,tv);
      ThermBA[aaa,bbb]:=tv;
    end;
    readln(f);
  end;
  closefile(f);

end;


const THstr = '%12.3f';

Procedure Skriv_ASC(OrtoFilNavn:string);
var f:textfile;
    i,j:integer;

begin
  assignFile(f,Pchar(OrtoFilNavn));
  rewrite(f);
  writeln(f,'ncols '+inttostr(MaxPixCol));
  writeln(f,'nrows '+inttostr(MaxPixRow));
  writeln(f,'xllcenter '+FloatToStr(ULx));
  Writeln(f,'yllcenter '+FloatToStr((ULy-(MaxPixRow*PixStr))));
  Writeln(f,'cellsize '+FloattoStr(PixStr));
  Writeln(f,'nodata_value -999');
  for j:=1 to MaxPixRow do
  begin
    for i:=1 to MaxPixCol do

    begin
      Write(f,trim(Format(THstr,[ThermOA[i,j]])));
      write(f,' ');
    end;
    writeln(f);
  end;
  closefile(f);
end;

procedure dumpBA16(fnam:string;omode:byte);
Type DirentryType = record               //POS
                      Tag     : integer; //X
                      Dtype   : integer; //X+2
                      Cnt     : integer; //X+4
                      ValOfst : integer; //X+8
                    end;

var f : file of byte;
    g : textfile;
    Buf:array[0..70000] of byte;
    c:byte;
    V:Valuetype;
    VI:integer; //Value in Integer
    i,j : integer;
    Dstart : integer;

    ByteOrder : Boolean; //True = II, false = MM

    FirstIFD : Integer;

    DirEntries : Array[0..100] of DirEntryType;
    NumberOfDirEntries : Integer;

    ImageWidth, ImageLength : integer;
    BitsPerSample : integer;
    SamplesPerPixel : byte;
    Compression : integer;
    PhotometricInterpretation: Integer;
    StripOffsets:integer;
    NStripOffsets : integer;

    RowsPerStrip:integer;
    StripByteCounts:integer;

    rr,gg,bb : byte;
    aaa,bbb : integer;

    TileOffsets,TileByteCounts: array[1..1000] of integer;
    TileOffsets_i, TileByteCounts_i: integer;
    TileWidth, TileLength : integer;
    TileOffsetsStart,TileByteCountsStart:integer;

    ai,aj,ak,al : integer;
    numTilewidth, NumtileHeight : integer;
    aktTileNum:integer;

    IFDstart:integer;

Function ValU(V:valuetype):integer;
var tval, i:integer;
begin
  tval:=0;
  if ByteOrder then  //least significant first
  with V do
  begin
    for i:=1 to A_i do
    tval:=tval+A[i]*round(power(256,i-1));
  end else           //Most significant first
  with V do
  begin
    for i:=1 to V.A_i do
    tval:=tval+  V.A[i]*round(power(256,V.A_I-i));
  end;
  ValU:=tval;
end;


Procedure FLAS(antal:integer);
var i : integer;
begin
  With V do
  begin
    for i:=1 to antal do
    Read(f,A[i]);
    A_i:=antal;
  end;
  VI:=ValU(V);
end;

Function IntToByte(tal,len:integer):Valuetype;
var V:ValueType;
    i : integer;
    temp1,temp2:integer;
begin
  temp1:=tal;
  for i:=len-1 downto 0 do
  begin
    Temp2:=trunc(temp1/(power(256,i)));
    Temp1:=Temp1-round(Temp2*Power(256,i));
    V.A[len-i]:=Temp2;
  end;
  V.A_i:=len;
  IntToByte:=V;
end;

Procedure FSKV(tal,ant,wrlen:integer);    //WRITES to file (tal = number ant = "type"    wrlen = length in bytes
Var V:Valuetype;                                                              //1=byte
    i:integer;                                                                //2=ascii
    dumbyt: Byte;                                                             //3=short
begin                                                                         //4=long
  dumbyt:=0;
  V:=IntToByte(tal,ant);
  for i:=1 to ant do     //II - de to første karakterer
  Write(f,V.A[i]);
  For i:=1 to wrlen-ant do
  Write(f,dumbyt);

end;


Function D(DT:integer):integer;
begin
  case DT of
     1 : D:=1;
     2 : D:=1;
     3 : D:=2;
     4 : D:=4;
     5 : D:=4;
  else d:=1; end;
end;

const Footerstring='This file has been generated with the os orto project';

var
  AktDir:integer;
  AktTyp:byte;
  AktCnt:integer;
  AktVal:integer;

begin
  ImageWidth:=BilColMax;
  Imagelength:=BilrowMax;

  TileWidth:=256;
  TileLength:=256;

  NumTileWidth:=  trunc((BilColMax+Tilewidth-1)/TileWidth);
  NumTileHeight:= trunc((bilRowMax+tileLength-1)/TileLength);

  if Omode = 3 then SamplesPerPixel:=4 else SamplesPerPixel:=3;

  IFDstart:=numtilewidth*NumTileHeight*256*256*samplesPerPixel*2+32; //

  assign(f,fnam);


  rewrite(f);

  FSKV(77,1,1);FSKV(77,1,1);
  FSKV(42,2,2);
  FSKV(IFDstart,4,4);    //This must be on a word boundary - but how to check???

  FSKV(16,2,2);
  FSKV(16,2,2);
  FSKV(16,2,2);
  FSKV(16,2,2);
  FSKV(0,2,2);
  FSKV(0,2,2);
  FSKV(0,2,2);
  FSKV(0,2,2);
  FSKV(255,2,2);
  FSKV(255,2,2);
  FSKV(255,2,2);
  FSKV(255,2,2);

  begin
    aaa:=0;bbb:=0;
    For j:=0 to NumTileHeight-1 do
    begin
      bbb:=256*j;
      for i:=0 to NumTileWidth-1 do
      begin
        aaa:=256*i;
        for aj:=0 to 255 do
        begin
          for ai:=0 to 255 do
          begin
            if aj+bbb>BilRowMax then continue;
            if ai+aaa>BilColMax then continue;
            V:=IntToByte(BA16[aaa+ai,bbb+aj].r,2);
            buf[ai*8   ]:=V.A[1];
            buf[ai*8+1 ]:=V.A[2];

            V:=IntToByte(BA16[aaa+ai,bbb+aj].g,2);
            buf[ai*8+2 ]:=V.A[1];
            buf[ai*8+3 ]:=V.A[2];

            V:=IntToByte(BA16[aaa+ai,bbb+aj].b,2);
            buf[ai*8+4 ]:=V.A[1];
            buf[ai*8+5 ]:=V.A[2];

            V:=IntToByte(BA16[aaa+ai,bbb+aj].c,2);
            buf[ai*8+6 ]:=V.A[1];
            buf[ai*8+7 ]:=V.A[2];

          end;
          blockwrite(f,buf,tilewidth*SamplesPerPixel*2);
        end;
      end;
    end;
  end;


  FSKV(15,2,2); // <- Første post i IFD er antallet af poster i IFD'en
    For i:=1 to 15 do
  begin
    Case i of
         1: begin
              AktDir:=256;
              AktTyp:=4;
              AktCnt:=1;
              If Rot34 then
                AktVal:=bilRowMax
              else
                AktVal:=BilColMax;   //<--- Dette er det normale
            end;        //Bredde
         2: begin
              AktDir:=257;
              AktTyp:=4;
              AktCnt:=1;
              if Rot34 then
                AktVal:=BilColMax
              else
                AktVal:=bilRowMax;
            end;       //Længde
         3: begin AktDir:=258; AktTyp:=3; if omode = 3 then AktCnt:=4 else AktCnt:=3; AktVal:=8; end;//Antal bits per sample, henvisning
         4: begin AktDir:=259; AktTyp:=3; AktCnt:=1; AktVal:=1; end;                 //Compression
         5: begin AktDir:=262; AktTyp:=3; AktCnt:=1; AktVal:=2; end;                 //Photometric interpretation
         6: begin AktDir:=274; AktTyp:=3; AktCnt:=1; AktVal:=1; end;                 //Orientation
         7: Begin
              Aktdir:=277;
              AktTyp:=3;
              AktCnt:=1;
              if Omode = 3 then AktVal:=4 else AktVal:=3;    //Antal byte per pixel
            end;
         8: Begin AktDir:=280; AktTyp:=3; AktCnt:=3; AktVal:=16; end; //Min sample value
         9: Begin AktDir:=281; AktTyp:=3; AktCnt:=3; AktVal:=24; end; //Max sample value

        10: Begin AktDir:=284; AktTyp:=3; AktCnt:=1; AktVal:=1; end; //Planar configuration
        11: Begin AktDir:=296; AktTyp:=3; AktCnt:=1; AktVal:=1; end; //Resolution Unit
        12: Begin AktDir:=322; AktTyp:=3; AktCnt:=1; AktVal:=256; end; //TileWidth
        13: Begin AktDir:=323; AktTyp:=3; AktCnt:=1; AktVal:=256; end; //TileLength
        14: Begin AktDir:=324; AktTyp:=4; AktCnt:=NumTileWidth*NumTileHeight; AktVal:=IFDStart+182; end;
        15: Begin AktDir:=325; AktTyp:=4; AktCnt:=NumTileWidth*NumTileHeight; AktVal:=IFDstart+NumTileWidth*NumTileHeight*SamplesPerPixel*2+182;
            end;
    end;
    FSKV(AktDir,2,2);
    FSKV(AktTyp,2,2);
    FSKV(AktCnt,4,4);
    If ((AktDir = 258) or (AktDir = 280) or (AktDir = 281)) then
    FSKV(AktVal,4,4) else
    FSKV(AktVal,D(AktTyp),4);
  end;                  
  for i:=0 to NumTileWidth*NumTileHeight-1 do FSKV(i*256*256*SamplesPerPixel*2+32,4,4);   //muligvis fejl her
  for i:=0 to NumTileWidth*NumTileHeight-1 do FSKV(256*256*SamplesPerPixel*2,4,4);        //og her

  FSKV(0,1,1);  FSKV(0,1,1);  FSKV(0,1,1);  FSKV(0,1,1);  //Fire bytes med nul efter IFD
  FSKV(0,1,1); //For at ende på et lige tal...

  closefile(f);
end;









Procedure Skriv_tiff_tn8(fnam:string);
Type DirentryType = record               //POS
                      Tag     : integer; //X
                      Dtype   : integer; //X+2
                      Cnt     : integer; //X+4
                      ValOfst : integer; //X+8
                    end;

var f : file of byte;
    g : textfile;
    Buf:array[0..70000] of byte;
    c:byte;
    V:Valuetype;
    VI:integer; //Value in Integer
    i,j : integer;
    Dstart : integer;

    ByteOrder : Boolean; //True = II, false = MM

    FirstIFD : Integer;

    DirEntries : Array[0..100] of DirEntryType;
    NumberOfDirEntries : Integer;

    ImageWidth, ImageLength : integer;
    BitsPerSample : integer;
    Compression : integer;
    PhotometricInterpretation: Integer;
    StripOffsets:integer;
    NStripOffsets : integer;
    SamplesPerPixel:integer;
    RowsPerStrip:integer;
    StripByteCounts:integer;

    rr,gg,bb : byte;
    aaa,bbb : integer;

Function ValU(V:valuetype):integer;
var tval, i:integer;
begin
  tval:=0;
  if ByteOrder then  //least significant first
  with V do
  begin
    for i:=1 to A_i do
    tval:=tval+A[i]*round(power(256,i-1));
  end else           //Most significant first
  with V do
  begin
    for i:=1 to V.A_i do
    tval:=tval+  V.A[i]*round(power(256,V.A_I-i));
  end;
  ValU:=tval;
end;


Procedure FLAS(antal:integer);
var i : integer;
begin
  With V do
  begin
    for i:=1 to antal do
    Read(f,A[i]);
    A_i:=antal;
  end;
  VI:=ValU(V);
end;

Function IntToByte(tal,len:integer):Valuetype;
var V:ValueType;
    i : integer;
    temp1,temp2:integer;
begin
  temp1:=tal;
  for i:=len-1 downto 0 do
  begin
    Temp2:=trunc(temp1/(power(256,i)));
    Temp1:=Temp1-round(Temp2*Power(256,i));
    V.A[len-i]:=Temp2;
  end;
  V.A_i:=len;
  IntToByte:=V;
end;

Procedure FSKV(tal,ant,wrlen:integer);
Var V:Valuetype;
    i:integer;
    dumbyt: Byte;
begin
  dumbyt:=0;
  V:=IntToByte(tal,ant);
  for i:=1 to ant do     //II - de to første karakterer
  Write(f,V.A[i]);
  For i:=1 to wrlen-ant do
  Write(f,dumbyt);

end;

Function D(DT:integer):integer;
begin
  case DT of
     1 : D:=1;
     2 : D:=1;
     3 : D:=2;
     4 : D:=4;
     5 : D:=4;
  else d:=1; end;
end;

const Footerstring='This file has been generated with the os orto project';

var
  AktDir:integer;
  AktTyp:byte;
  AktCnt:integer;
  AktVal:integer;

begin
  ImageWidth:=round(MaxPixCol/2);
  Imagelength:=round(MaxPixRow/2);


  assign(f,fnam);


  rewrite(f);

  FSKV(77,1,1);FSKV(77,1,1);
  FSKV(42,2,2);
  FSKV(8,4,4);

  FSKV(12,2,2);

  For i:=1 to 12 do
  begin
    Case i of
         1: begin
              AktDir:=256;
              AktTyp:=4;
              AktCnt:=1;
              If Rot34 then
                AktVal:=ImageLength
              else
                AktVal:=ImageWidth;
            end;        //Bredde
         2: begin
              AktDir:=257;
              AktTyp:=4;
              AktCnt:=1;
              if Rot34 then
                AktVal:=ImageWidth
              else
                AktVal:=ImageLength;
            end;       //Længde
         3: begin AktDir:=258; AktTyp:=3; AktCnt:=3; AktVal:=160; end;               //Antal bits per pixel, henvisning
         4: begin AktDir:=259; AktTyp:=3; AktCnt:=1; AktVal:=1; end;                 //Compression
         5: begin AktDir:=262; AktTyp:=3; AktCnt:=1; AktVal:=2; end;                 //Photometric interpretation
         6: begin AktDir:=273; AktTyp:=4; AktCnt:=1; AktVal:=186; end;               //StripOffset - henvisning
         7: Begin Aktdir:=277; AktTyp:=3; AktCnt:=1; AktVal:=3; end;                 //Antal byte per pixel
         8: Begin Aktdir:=278; AktTyp:=4; AktCnt:=1; if Rot34 then AktVal:=ImageWidth else AktVal:=ImageLength; end;
         9: Begin AktDir:=279; AktTyp:=4; AktCnt:=1; AktVal:=ImageWidth*ImageLength*3; end;
        10: Begin AktDir:=282; AktTyp:=5; AktCnt:=1; AktVal:=168; end;               //Henvisning til opløsning
        11: Begin AktDir:=283; AktTyp:=5; AktCnt:=1; AktVal:=176; end;               // ---"---
        12: Begin AktDir:=296; AktTyp:=3; AktCnt:=1; AktVal:=3; end;                 //Resolution unit
    end;
    FSKV(AktDir,2,2);
    FSKV(AktTyp,2,2);
    FSKV(AktCnt,4,4);
    If AktDir = 258 then
    FSKV(AktVal,4,4) else
    FSKV(AktVal,D(AktTyp),4);
  end;
  FSKV(0,1,1);  FSKV(0,1,1);  FSKV(0,1,1);  FSKV(0,1,1);  //Fire bytes med nul efter IFD
  FSKV(0,1,1); //For at ende på et lige tal...
  FSKV(77,1,1);
  FSKV(8,2,2);
  FSKV(8,2,2);
  FSKV(8,2,2);
  FSKV(0,2,2);
  FSKV(720000,4,4);
  FSKV(10000,4,4);
  FSKV(720000,4,4);
  FSKV(10000,4,4);
  FSKV(0,1,1);
  FSKV(77,1,1);

  If Rot34 then
  begin
    For aaa:=ImageWidth downto 1 do
    begin
      for bbb:=1 to imageLength do
      begin
        buf[bbb*3-3]:=OA8[aaa,bbb].r;
        buf[bbb*3-2]:=OA8[aaa,bbb].g;
        buf[bbb*3-1]:=OA8[aaa,bbb].b;
      end;
      BlockWrite(f,buf,ImageLength*3);
    end;
  end else
  begin
    For aaa:=1 to ImageLength do
    begin
      for bbb:=1 to imageWidth do
      begin
        buf[bbb*3-3]:=round((OA8[bbb*2-1,aaa*2-1].r+OA8[bbb*2-1,aaa*2].r+OA8[bbb*2,aaa*2-1].r+OA8[bbb*2,aaa*2].r)/4);
        buf[bbb*3-2]:=round((OA8[bbb*2-1,aaa*2-1].g+OA8[bbb*2-1,aaa*2].g+OA8[bbb*2,aaa*2-1].g+OA8[bbb*2,aaa*2].g)/4);
        buf[bbb*3-1]:=round((OA8[bbb*2-1,aaa*2-1].b+OA8[bbb*2-1,aaa*2].b+OA8[bbb*2,aaa*2-1].g+OA8[bbb*2,aaa*2].b)/4);
      end;
      BlockWrite(f,buf,ImageWidth*3);
    end;
  end;
  for i:=1 to 10 do
  FSKV(0,1,1);
  For i:=1 to length(Footerstring) do
  begin
    c:=ord(Footerstring[i]);
    Write(f,c);
  end;
  for i:=1 to 10 do
  FSKV(0,1,1);
  closefile(f);
end;

Procedure Skriv_tiff8(fnam:string;Omode:byte);
Type DirentryType = record               //POS
                      Tag     : integer; //X
                      Dtype   : integer; //X+2
                      Cnt     : integer; //X+4
                      ValOfst : integer; //X+8
                    end;

var f : file of byte;
    g : textfile;
    Buf:array[0..70000] of byte;
    c:byte;
    V:Valuetype;
    VI:integer; //Value in Integer
    i,j : integer;
    Dstart : integer;

    ByteOrder : Boolean; //True = II, false = MM

    FirstIFD : Integer;

    DirEntries : Array[0..100] of DirEntryType;
    NumberOfDirEntries : Integer;

    ImageWidth, ImageLength : integer;
    BitsPerSample : integer;
    SamplesPerPixel : byte;
    Compression : integer;
    PhotometricInterpretation: Integer;
    StripOffsets:integer;
    NStripOffsets : integer;

    RowsPerStrip:integer;
    StripByteCounts:integer;

    rr,gg,bb : byte;
    aaa,bbb : integer;

    TileOffsets,TileByteCounts: array[1..100000] of integer;
    TileOffsets_i, TileByteCounts_i: integer;
    TileWidth, TileLength : integer;
    TileOffsetsStart,TileByteCountsStart:integer;

    ai,aj,ak,al : integer;
    numTilewidth, NumtileHeight : integer;
    aktTileNum:integer;

    IFDstart:integer;

    tpix:Byte;
    ttpix:real;

Function ValU(V:valuetype):integer;
var tval, i:integer;
begin
  tval:=0;
  if ByteOrder then  //least significant first
  with V do
  begin
    for i:=1 to A_i do
    tval:=tval+A[i]*round(power(256,i-1));
  end else           //Most significant first
  with V do
  begin
    for i:=1 to V.A_i do
    tval:=tval+  V.A[i]*round(power(256,V.A_I-i));
  end;
  ValU:=tval;
end;


Procedure FLAS(antal:integer);
var i : integer;
begin
  With V do
  begin
    for i:=1 to antal do
    Read(f,A[i]);
    A_i:=antal;
  end;
  VI:=ValU(V);
end;

Function IntToByte(tal,len:integer):Valuetype;
var V:ValueType;
    i : integer;
    temp1,temp2:integer;
begin
  temp1:=tal;
  for i:=len-1 downto 0 do
  begin
    Temp2:=trunc(temp1/(power(256,i)));
    Temp1:=Temp1-round(Temp2*Power(256,i));
    V.A[len-i]:=Temp2;
  end;
  V.A_i:=len;
  IntToByte:=V;
end;




Procedure FSKV(tal,ant,wrlen:integer);    //WRITES to file (tal = number ant = "type"    wrlen = length in bytes
Var V:Valuetype;                                                              //1=byte
    i:integer;                                                                //2=ascii
    dumbyt: Byte;                                                             //3=short
begin                                                                         //4=long
  dumbyt:=0;
  V:=IntToByte(tal,ant);
  for i:=1 to ant do     //II - de to første karakterer
  Write(f,V.A[i]);
  For i:=1 to wrlen-ant do
  Write(f,dumbyt);

end;

Function D(DT:integer):integer;
begin
  case DT of
     1 : D:=1;
     2 : D:=1;
     3 : D:=2;
     4 : D:=4;
     5 : D:=4;
  else d:=1; end;
end;

const Footerstring='This file has been generated with the os orto project';

var
  AktDir:integer;
  AktTyp:byte;
  AktCnt:integer;
  AktVal:integer;
  NDVI_naevner: real;
begin
  ImageWidth:=MaxPixCol;
  Imagelength:=MaxPixRow;

  TileWidth:=256;
  TileLength:=256;

  NumTileWidth:=  trunc((ImageWidth+Tilewidth-1)/TileWidth);
  NumTileHeight:= trunc((ImageLength+tileLength-1)/TileLength);

  if Omode = 3 then SamplesPerPixel:=4 else SamplesPerPixel:=3;

  IFDstart:=numtilewidth*NumTileHeight*256*256*samplesPerPixel+32; //

  assign(f,fnam);


  rewrite(f);

  FSKV(77,1,1);FSKV(77,1,1);
  FSKV(42,2,2);
  FSKV(IFDstart,4,4);    //This must be on a word boundary - but how to check???

  FSKV(8,2,2);
  FSKV(8,2,2);
  FSKV(8,2,2);
  FSKV(8,2,2);
  FSKV(0,2,2);
  FSKV(0,2,2);
  FSKV(0,2,2);
  FSKV(0,2,2);
  FSKV(255,2,2);
  FSKV(255,2,2);
  FSKV(255,2,2);
  FSKV(255,2,2);

  If (Omode = 1) then
  begin
    aaa:=0;bbb:=0;
    For j:=0 to NumTileHeight-1 do
    begin
      bbb:=256*j;
      for i:=0 to NumTileWidth-1 do
      begin
        aaa:=256*i;
        for aj:=0 to 255 do
        begin
          for ai:=0 to 255 do
          begin
            if aj+bbb+1>imagelength then continue;
            if ai+aaa+1>imageWidth then continue;
            buf[ai*3  ]:=OA8[aaa+ai+1,bbb+aj+1].r;
            buf[ai*3+1]:=OA8[aaa+ai+1,bbb+aj+1].g;
            buf[ai*3+2]:=OA8[aaa+ai+1,bbb+aj+1].b;
          end;
          blockwrite(f,buf,tilewidth*SamplesPerPixel);
        end;
      end;
    end;
  end;

  If (Omode = 2) then
  begin
    aaa:=0;bbb:=0;
    For j:=0 to NumTileHeight-1 do
    begin
      bbb:=256*j;
      for i:=0 to NumTileWidth-1 do
      begin
        aaa:=256*i;
        for aj:=0 to 255 do
        begin
          for ai:=0 to 255 do
          begin
            if aj+bbb+1>imagelength then continue;
            if ai+aaa+1>imageWidth then continue;
            buf[ai*3  ]:=OA8[aaa+ai+1,bbb+aj+1].c;
            buf[ai*3+1]:=OA8[aaa+ai+1,bbb+aj+1].r;
            buf[ai*3+2]:=OA8[aaa+ai+1,bbb+aj+1].g;
          end;
          blockwrite(f,buf,tilewidth*SamplesPerPixel);
        end;
      end;
    end;
  end;

  If (Omode = 3) then   //Combined
  begin
    aaa:=0;bbb:=0;
    For j:=0 to NumTileHeight-1 do
    begin
      bbb:=256*j;
      for i:=0 to NumTileWidth-1 do
      begin
        aaa:=256*i;
        for aj:=0 to 255 do
        begin
          for ai:=0 to 255 do
          begin
            if aj+bbb+1>imagelength then continue;
            if ai+aaa+1>imageWidth then continue;
            buf[ai*4  ]:=OA8[aaa+ai+1,bbb+aj+1].r;
            buf[ai*4+1]:=OA8[aaa+ai+1,bbb+aj+1].g;
            buf[ai*4+2]:=OA8[aaa+ai+1,bbb+aj+1].b;
            buf[ai*4+3]:=OA8[aaa+ai+1,bbb+aj+1].c;
          end;
          blockwrite(f,buf,tilewidth*SamplesPerPixel);
        end;
      end;
    end;
  end;

  If (Omode = 4) then //NDVI
  begin
    aaa:=0;bbb:=0;
    For j:=0 to NumTileHeight-1 do
    begin
      bbb:=256*j;
      for i:=0 to NumTileWidth-1 do
      begin
        aaa:=256*i;
        for aj:=0 to 255 do
        begin
          for ai:=0 to 255 do
          begin
            if aj+bbb+1>imagelength then continue;
            if ai+aaa+1>imageWidth then continue;
            ndvi_naevner:=(OA8[aaa+ai+1,bbb+aj+1].c+OA8[aaa+ai+1,bbb+aj+1].r);
			if (abs(ndvi_naevner)<0.00000000001) then 
			  ttpix:= 0
			else
              ttpix:=  256*((OA8[aaa+ai+1,bbb+aj+1].c-OA8[aaa+ai+1,bbb+aj+1].r)/ndvi_naevner);
            if ttpix<0 then ttpix:=0;
            tpix:=trunc(ttpix);

            buf[ai*3  ]:=tpix;
            buf[ai*3+1]:=tpix;
            buf[ai*3+2]:=tpix;
          end;
          blockwrite(f,buf,tilewidth*SamplesPerPixel);
        end;
      end;
    end;
  end;

  FSKV(15,2,2); // <- Første post i IFD er antallet af poster i IFD'en
    For i:=1 to 15 do
  begin
    Case i of
         1: begin
              AktDir:=256;
              AktTyp:=4;
              AktCnt:=1;
              If Rot34 then
                AktVal:=ImageLength
              else
                AktVal:=ImageWidth;   //<--- Dette er det normale
              //              If Rot34 then AktVal:=ImageLength else AktVal:=ImageWidth;
            end;        //Bredde
         2: begin
              AktDir:=257;
              AktTyp:=4;
              AktCnt:=1;
              if Rot34 then
                AktVal:=ImageWidth
              else
                AktVal:=ImageLength;
            end;       //Længde
         3: begin AktDir:=258; AktTyp:=3; if omode = 3 then AktCnt:=4 else AktCnt:=3; AktVal:=8; end;//Antal bits per sample, henvisning
         4: begin AktDir:=259; AktTyp:=3; AktCnt:=1; AktVal:=1; end;                 //Compression
         5: begin AktDir:=262; AktTyp:=3; AktCnt:=1; AktVal:=2; end;                 //Photometric interpretation
         6: begin AktDir:=274; AktTyp:=3; AktCnt:=1; AktVal:=1; end;                 //Orientation
         7: Begin
              Aktdir:=277;
              AktTyp:=3;
              AktCnt:=1;
              if Omode = 3 then AktVal:=4 else AktVal:=3;    //Antal byte per pixel
            end;
         8: Begin AktDir:=280; AktTyp:=3; AktCnt:=3; AktVal:=16; end; //Min sample value
         9: Begin AktDir:=281; AktTyp:=3; AktCnt:=3; AktVal:=24; end; //Max sample value

        10: Begin AktDir:=284; AktTyp:=3; AktCnt:=1; AktVal:=1; end; //Planar configuration
        11: Begin AktDir:=296; AktTyp:=3; AktCnt:=1; AktVal:=1; end; //Resolution Unit
        12: Begin AktDir:=322; AktTyp:=3; AktCnt:=1; AktVal:=256; end; //TileWidth
        13: Begin AktDir:=323; AktTyp:=3; AktCnt:=1; AktVal:=256; end; //TileLength
        14: Begin AktDir:=324; AktTyp:=4; AktCnt:=NumTileWidth*NumTileHeight; AktVal:=IFDStart+182; end;
        15: Begin AktDir:=325; AktTyp:=4; AktCnt:=NumTileWidth*NumTileHeight; AktVal:=IFDstart+NumTileWidth*NumTileHeight*4+182; end; //Der bruges 4 bytes til at gemme een henvisning!
    end;
    FSKV(AktDir,2,2);
    FSKV(AktTyp,2,2);
    FSKV(AktCnt,4,4);
    If ((AktDir = 258) or (AktDir = 280) or (AktDir = 281)) then
    FSKV(AktVal,4,4) else
    FSKV(AktVal,D(AktTyp),4);
  end;                  //hertil 34+13*8
  for i:=0 to NumTileWidth*NumTileHeight-1 do FSKV(i*256*256*SamplesPerPixel+32,4,4);
  for i:=0 to NumTileWidth*NumTileHeight-1 do FSKV(256*256*SamplesPerPixel,4,4);

  FSKV(0,1,1);  FSKV(0,1,1);  FSKV(0,1,1);  FSKV(0,1,1);  //Fire bytes med nul efter IFD
  FSKV(0,1,1); //For at ende på et lige tal...
  closefile(f);
end;

Procedure Skriv_tiff16(fnam:string;Omode:byte);
Type DirentryType = record               //POS
                      Tag     : integer; //X
                      Dtype   : integer; //X+2
                      Cnt     : integer; //X+4
                      ValOfst : integer; //X+8
                    end;

var f : file of byte;
    g : textfile;
    Buf:array[0..70000] of byte;
    c:byte;
    V:Valuetype;
    VI:integer; //Value in Integer
    i,j : integer;
    Dstart : integer;

    ByteOrder : Boolean; //True = II, false = MM

    FirstIFD : Integer;

    DirEntries : Array[0..100] of DirEntryType;
    NumberOfDirEntries : Integer;

    ImageWidth, ImageLength : integer;
    BitsPerSample : integer;
    SamplesPerPixel : byte;
    Compression : integer;
    PhotometricInterpretation: Integer;
    StripOffsets:integer;
    NStripOffsets : integer;

    RowsPerStrip:integer;
    StripByteCounts:integer;

    rr,gg,bb : byte;
    aaa,bbb : integer;

    TileOffsets,TileByteCounts: array[1..100000] of integer;
    TileOffsets_i, TileByteCounts_i: integer;
    TileWidth, TileLength : integer;
    TileOffsetsStart,TileByteCountsStart:integer;

    ai,aj,ak,al : integer;
    numTilewidth, NumtileHeight : integer;
    aktTileNum:integer;

    IFDstart:integer;


    ttpix:real;
    tp1,tp2:byte;

Function ValU(V:valuetype):integer;
var tval, i:integer;
begin
  tval:=0;
  if ByteOrder then  //least significant first
  with V do
  begin
    for i:=1 to A_i do
    tval:=tval+A[i]*round(power(256,i-1));
  end else           //Most significant first
  with V do
  begin
    for i:=1 to V.A_i do
    tval:=tval+  V.A[i]*round(power(256,V.A_I-i));
  end;
  ValU:=tval;
end;


Procedure FLAS(antal:integer);
var i : integer;
begin
  With V do
  begin
    for i:=1 to antal do
    Read(f,A[i]);
    A_i:=antal;
  end;
  VI:=ValU(V);
end;

Function IntToByte(tal,len:integer):Valuetype;
var V:ValueType;
    i : integer;
    temp1,temp2:integer;
begin
  temp1:=tal;
  for i:=len-1 downto 0 do
  begin
    Temp2:=trunc(temp1/(power(256,i)));
    Temp1:=Temp1-round(Temp2*Power(256,i));
    V.A[len-i]:=Temp2;
  end;
  V.A_i:=len;
  IntToByte:=V;
end;

Procedure FSKV(tal,ant,wrlen:integer);    //WRITES to file (tal = number ant = "type"    wrlen = length in bytes
Var V:Valuetype;                                                              //1=byte
    i:integer;                                                                //2=ascii
    dumbyt: Byte;                                                             //3=short
begin                                                                         //4=long
  dumbyt:=0;
  V:=IntToByte(tal,ant);
  for i:=1 to ant do     //II - de to første karakterer
  Write(f,V.A[i]);
  For i:=1 to wrlen-ant do
  Write(f,dumbyt);

end;

Function D(DT:integer):integer;
begin
  case DT of
     1 : D:=1;
     2 : D:=1;
     3 : D:=2;
     4 : D:=4;
     5 : D:=4;
  else d:=1; end;
end;

const Footerstring='This file has been generated with the os orto project';

var
  AktDir:integer;
  AktTyp:byte;
  AktCnt:integer;
  AktVal:integer;
  NDVI_naevner: real;
begin
  ImageWidth:=MaxPixCol;
  Imagelength:=MaxPixRow;

  TileWidth:=256;
  TileLength:=256;

  NumTileWidth:=  trunc((ImageWidth+Tilewidth-1)/TileWidth);
  NumTileHeight:= trunc((ImageLength+tileLength-1)/TileLength);

  if Omode = 3 then SamplesPerPixel:=4 else SamplesPerPixel:=3;

  IFDstart:=numtilewidth*NumTileHeight*256*256*samplesPerPixel*2+32; //

  assign(f,fnam);


  rewrite(f);

  FSKV(77,1,1);FSKV(77,1,1);
  FSKV(42,2,2);
  FSKV(IFDstart,4,4);    //This must be on a word boundary - but how to check???

  FSKV(16,2,2);
  FSKV(16,2,2);
  FSKV(16,2,2);
  FSKV(16,2,2);
  FSKV(0,2,2);
  FSKV(0,2,2);
  FSKV(0,2,2);
  FSKV(0,2,2);
  FSKV(255,2,2);
  FSKV(255,2,2);
  FSKV(255,2,2);
  FSKV(255,2,2);

  If (Omode = 1) then
  begin
    aaa:=0;bbb:=0;
    For j:=0 to NumTileHeight-1 do
    begin
      bbb:=256*j;
      for i:=0 to NumTileWidth-1 do
      begin
        aaa:=256*i;
        for aj:=0 to 255 do
        begin
          for ai:=0 to 255 do
          begin
            if aj+bbb+1>imagelength then continue;
            if ai+aaa+1>imageWidth then continue;
            V:=IntToByte(OA16[aaa+ai+1,bbb+aj+1].r,2);
            buf[ai*6   ]:=V.A[1];
            buf[ai*6+1 ]:=V.A[2];

            V:=IntToByte(OA16[aaa+ai+1,bbb+aj+1].g,2);
            buf[ai*6+2 ]:=V.A[1];
            buf[ai*6+3 ]:=V.A[2];

            V:=IntToByte(OA16[aaa+ai+1,bbb+aj+1].b,2);
            buf[ai*6+4 ]:=V.A[1];
            buf[ai*6+5 ]:=V.A[2];
          end;
          blockwrite(f,buf,tilewidth*SamplesPerPixel*2);
        end;
      end;
    end;
  end;

  If (Omode = 2) then
  begin
    aaa:=0;bbb:=0;
    For j:=0 to NumTileHeight-1 do
    begin
      bbb:=256*j;
      for i:=0 to NumTileWidth-1 do
      begin
        aaa:=256*i;
        for aj:=0 to 255 do
        begin
          for ai:=0 to 255 do
          begin
            if aj+bbb+1>imagelength then continue;
            if ai+aaa+1>imageWidth then continue;
            V:=IntToByte(OA16[aaa+ai+1,bbb+aj+1].c,2);
            buf[ai*6   ]:=V.A[1];
            buf[ai*6+1 ]:=V.A[2];

            V:=IntToByte(OA16[aaa+ai+1,bbb+aj+1].r,2);
            buf[ai*6+2 ]:=V.A[1];
            buf[ai*6+3 ]:=V.A[2];

            V:=IntToByte(OA16[aaa+ai+1,bbb+aj+1].g,2);
            buf[ai*6+4 ]:=V.A[1];
            buf[ai*6+5 ]:=V.A[2];
          end;
          blockwrite(f,buf,tilewidth*SamplesPerPixel*2);
        end;
      end;
    end;
  end;

  If (Omode = 3) then   //Combined
  begin
    aaa:=0;bbb:=0;
    For j:=0 to NumTileHeight-1 do
    begin
      bbb:=256*j;
      for i:=0 to NumTileWidth-1 do
      begin
        aaa:=256*i;
        for aj:=0 to 255 do
        begin
          for ai:=0 to 255 do
          begin
            if aj+bbb+1>imagelength then continue;
            if ai+aaa+1>imageWidth then continue;
            V:=IntToByte(OA16[aaa+ai+1,bbb+aj+1].r,2);
            buf[ai*8   ]:=V.A[1];
            buf[ai*8+1 ]:=V.A[2];

            V:=IntToByte(OA16[aaa+ai+1,bbb+aj+1].g,2);
            buf[ai*8+2 ]:=V.A[1];
            buf[ai*8+3 ]:=V.A[2];

            V:=IntToByte(OA16[aaa+ai+1,bbb+aj+1].b,2);
            buf[ai*8+4 ]:=V.A[1];
            buf[ai*8+5 ]:=V.A[2];

            V:=IntToByte(OA16[aaa+ai+1,bbb+aj+1].c,2);
            buf[ai*8+6 ]:=V.A[1];
            buf[ai*8+7 ]:=V.A[2];

          end;
          blockwrite(f,buf,tilewidth*SamplesPerPixel*2);
        end;
      end;
    end;
  end;


  If (Omode = 4) then //NDVI, 12bit
  begin
    aaa:=0;bbb:=0;
    For j:=0 to NumTileHeight-1 do
    begin
      bbb:=256*j;
      for i:=0 to NumTileWidth-1 do
      begin
        aaa:=256*i;
        for aj:=0 to 255 do
        begin
          for ai:=0 to 255 do
          begin
            if aj+bbb+1>imagelength then continue;
            if ai+aaa+1>imageWidth then continue;

			ndvi_naevner:=(OA16[aaa+ai+1,bbb+aj+1].c+OA16[aaa+ai+1,bbb+aj+1].r);
			if (abs(ndvi_naevner)<0.000000000001) then 
			  ttpix := 0
			else
              ttpix:= 256*256*((OA16[aaa+ai+1,bbb+aj+1].c-OA16[aaa+ai+1,bbb+aj+1].r)/ndvi_naevner);

            if ttpix<0 then ttpix:=0;

            V:=IntToByte(trunc(ttpix),2);

            buf[ai*6   ]:=V.A[1];
            buf[ai*6+1 ]:=V.A[2];

            buf[ai*6+2 ]:=V.A[1];
            buf[ai*6+3 ]:=V.A[2];

            buf[ai*6+4 ]:=V.A[1];
            buf[ai*6+5 ]:=V.A[2];
          end;
          blockwrite(f,buf,tilewidth*SamplesPerPixel*2);
        end;
      end;
    end;
  end;




  FSKV(15,2,2); // <- Første post i IFD er antallet af poster i IFD'en
    For i:=1 to 15 do
  begin
    Case i of
         1: begin
              AktDir:=256;
              AktTyp:=4;
              AktCnt:=1;
              If Rot34 then
                AktVal:=ImageLength
              else
                AktVal:=ImageWidth;   //<--- Dette er det normale
            end;        //Bredde
         2: begin
              AktDir:=257;
              AktTyp:=4;
              AktCnt:=1;
              if Rot34 then
                AktVal:=ImageWidth
              else
                AktVal:=ImageLength;
            end;       //Længde
         3: begin AktDir:=258; AktTyp:=3; if omode = 3 then AktCnt:=4 else AktCnt:=3; AktVal:=8; end;//Antal bits per sample, henvisning
         4: begin AktDir:=259; AktTyp:=3; AktCnt:=1; AktVal:=1; end;                 //Compression
         5: begin AktDir:=262; AktTyp:=3; AktCnt:=1; AktVal:=2; end;                 //Photometric interpretation
         6: begin AktDir:=274; AktTyp:=3; AktCnt:=1; AktVal:=1; end;                 //Orientation
         7: Begin
              Aktdir:=277;
              AktTyp:=3;
              AktCnt:=1;
              AktVal:=SamplesPerPixel;    //Antal byte per pixel
            end;
         8: Begin AktDir:=280; AktTyp:=3; AktCnt:=3; AktVal:=16; end; //Min sample value
         9: Begin AktDir:=281; AktTyp:=3; AktCnt:=3; AktVal:=24; end; //Max sample value

        10: Begin AktDir:=284; AktTyp:=3; AktCnt:=1; AktVal:=1; end; //Planar configuration
        11: Begin AktDir:=296; AktTyp:=3; AktCnt:=1; AktVal:=1; end; //Resolution Unit
        12: Begin AktDir:=322; AktTyp:=3; AktCnt:=1; AktVal:=256; end; //TileWidth
        13: Begin AktDir:=323; AktTyp:=3; AktCnt:=1; AktVal:=256; end; //TileLength
        14: Begin AktDir:=324; AktTyp:=4; AktCnt:=NumTileWidth*NumTileHeight; AktVal:=IFDStart+182; end;
        15: Begin AktDir:=325; AktTyp:=4; AktCnt:=NumTileWidth*NumTileHeight; AktVal:=IFDstart+NumTileWidth*NumTileHeight*4+182; //Der bruges 4 byte til at gemme een henvisning
            end;
    end;
    FSKV(AktDir,2,2);
    FSKV(AktTyp,2,2);
    FSKV(AktCnt,4,4);
    If ((AktDir = 258) or (AktDir = 280) or (AktDir = 281)) then
    FSKV(AktVal,4,4) else
    FSKV(AktVal,D(AktTyp),4);
  end;
  for i:=0 to NumTileWidth*NumTileHeight-1 do FSKV(i*256*256*SamplesPerPixel*2+32,4,4);   //muligvis fejl her
  for i:=0 to NumTileWidth*NumTileHeight-1 do FSKV(256*256*SamplesPerPixel*2,4,4);        //og her


  FSKV(0,1,1);  FSKV(0,1,1);  FSKV(0,1,1);  FSKV(0,1,1);  //Fire bytes med nul efter IFD
  FSKV(0,1,1); //For at ende på et lige tal...
  closefile(f);
end;



Procedure Skriv_tiff_old(fnam:string;Omode:byte);
Type DirentryType = record               //POS
                      Tag     : integer; //X
                      Dtype   : integer; //X+2
                      Cnt     : integer; //X+4
                      ValOfst : integer; //X+8
                    end;

var f : file of byte;
    g : textfile;
    Buf:array[0..70000] of byte;
    c:byte;
    V:Valuetype;
    VI:integer; //Value in Integer
    i,j : integer;
    Dstart : integer;

    ByteOrder : Boolean; //True = II, false = MM

    FirstIFD : Integer;
    DirEntries : Array[0..100] of DirEntryType;
    NumberOfDirEntries : Integer;

    ImageWidth, ImageLength : integer;
    BitsPerSample : integer;
    Compression : integer;
    PhotometricInterpretation: Integer;
    StripOffsets:integer;
    NStripOffsets : integer;
    SamplesPerPixel:integer;
    RowsPerStrip:integer;
    StripByteCounts:integer;

    rr,gg,bb : byte;
    aaa,bbb : integer;

Function ValU(V:valuetype):integer;
var tval, i:integer;
begin
  tval:=0;
  if ByteOrder then  //least significant first
  with V do
  begin
    for i:=1 to A_i do
    tval:=tval+A[i]*round(power(256,i-1));
  end else           //Most significant first
  with V do
  begin
    for i:=1 to V.A_i do
    tval:=tval+  V.A[i]*round(power(256,V.A_I-i));
  end;
  ValU:=tval;
end;


Procedure FLAS(antal:integer);
var i : integer;
begin
  With V do
  begin
    for i:=1 to antal do
    Read(f,A[i]);
    A_i:=antal;
  end;
  VI:=ValU(V);
end;

Function IntToByte(tal,len:integer):Valuetype;
var V:ValueType;
    i : integer;
    temp1,temp2:integer;
begin
  temp1:=tal;
  for i:=len-1 downto 0 do
  begin
    Temp2:=trunc(temp1/(power(256,i)));
    Temp1:=Temp1-round(Temp2*Power(256,i));
    V.A[len-i]:=Temp2;
  end;
  V.A_i:=len;
  IntToByte:=V;
end;

Procedure FSKV(tal,ant,wrlen:integer);
Var V:Valuetype;
    i:integer;
    dumbyt: Byte;
begin
  dumbyt:=0;
  V:=IntToByte(tal,ant);
  for i:=1 to ant do     //II - de to første karakterer
  Write(f,V.A[i]);
  For i:=1 to wrlen-ant do
  Write(f,dumbyt);
end;

Function D(DT:integer):integer;
begin
  case DT of
     1 : D:=1;
     2 : D:=1;
     3 : D:=2;
     4 : D:=4;
     5 : D:=4;
  else d:=1; end;
end;

const Footerstring='This file has been generated with the os orto project';

var
  AktDir:integer;
  AktTyp:byte;
  AktCnt:integer;
  AktVal:integer;

begin
  ImageWidth:=MaxPixCol;
  Imagelength:=MaxPixRow;
  assign(f,fnam);
  rewrite(f);

  FSKV(77,1,1);FSKV(77,1,1);
  FSKV(42,2,2);
  FSKV(8,4,4);

  FSKV(12,2,2);

  For i:=1 to 12 do
  begin
    Case i of
         1: begin
              AktDir:=256;
              AktTyp:=4;
              AktCnt:=1;
              If Rot34 then
                AktVal:=ImageLength
              else
                AktVal:=ImageWidth;
            end;        //Bredde
         2: begin
              AktDir:=257;
              AktTyp:=4;
              AktCnt:=1;
              if Rot34 then
                AktVal:=ImageWidth
              else
                AktVal:=ImageLength;
            end;       //Længde
         3: begin AktDir:=258; AktTyp:=3; AktCnt:=3; AktVal:=160; end;               //Antal bits per pixel, henvisning
         4: begin AktDir:=259; AktTyp:=3; AktCnt:=1; AktVal:=1; end;                 //Compression
         5: begin AktDir:=262; AktTyp:=3; AktCnt:=1; AktVal:=2; end;                 //Photometric interpretation
         6: begin AktDir:=273; AktTyp:=4; AktCnt:=1; AktVal:=186; end;               //StripOffset - henvisning
         7: Begin
              Aktdir:=277;
              AktTyp:=3;
              AktCnt:=1;
              if Omode = 3 then AktVal:=4 else AktVal:=3;    //Antal byte per pixel
            end;
         8: Begin Aktdir:=278; AktTyp:=4; AktCnt:=1; if Rot34 then AktVal:=ImageWidth else AktVal:=ImageLength; end;
         9: Begin AktDir:=279; AktTyp:=4; AktCnt:=1; if omode=3 then AktVal:=ImageWidth*ImageLength*4 else AktVal:=ImageWidth*ImageLength*3; end;
        10: Begin AktDir:=282; AktTyp:=5; AktCnt:=1; AktVal:=168; end;               //Henvisning til opløsning
        11: Begin AktDir:=283; AktTyp:=5; AktCnt:=1; AktVal:=176; end;               // ---"---
        12: Begin AktDir:=296; AktTyp:=3; AktCnt:=1; AktVal:=3; end;                 //Resolution unit
    end;
    FSKV(AktDir,2,2);
    FSKV(AktTyp,2,2);
    FSKV(AktCnt,4,4);
    If AktDir = 258 then
    FSKV(AktVal,4,4) else
    FSKV(AktVal,D(AktTyp),4);
  end;
  FSKV(0,1,1);  FSKV(0,1,1);  FSKV(0,1,1);  FSKV(0,1,1);  //Fire bytes med nul efter IFD
  FSKV(0,1,1); //For at ende på et lige tal...
  FSKV(77,1,1);
  FSKV(8,2,2);
  FSKV(8,2,2);
  FSKV(8,2,2);
  FSKV(0,2,2);
  FSKV(720000,4,4);
  FSKV(10000,4,4);
  FSKV(720000,4,4);
  FSKV(10000,4,4);
  FSKV(0,1,1);
  FSKV(77,1,1);

  If Rot34 then
  begin
    For aaa:=ImageWidth downto 1 do
    begin
      if Omode = 3 then
      begin
        for bbb:=1 to imageLength do
        begin
          buf[bbb*4-4]:=OA8[aaa,bbb].r;
          buf[bbb*4-3]:=OA8[aaa,bbb].g;
          buf[bbb*4-2]:=OA8[aaa,bbb].b;
          buf[bbb*4-1]:=OA8[aaa,bbb].c;
        end;
        BlockWrite(f,buf,ImageLength*4);
      end else
      begin
        for bbb:=1 to imageLength do
        begin

          if Omode = 2 then
          begin
            buf[bbb*3-3]:=OA8[aaa,bbb].c;
            buf[bbb*3-2]:=OA8[aaa,bbb].r;
            buf[bbb*3-1]:=OA8[aaa,bbb].g;
          end else
          begin
            buf[bbb*3-3]:=OA8[aaa,bbb].r;
            buf[bbb*3-2]:=OA8[aaa,bbb].g;
            buf[bbb*3-1]:=OA8[aaa,bbb].b;
          end;
        end;
        BlockWrite(f,buf,ImageLength*3);
      end;
    end;
  end else
  begin
    if Omode=3 then
    begin
      For aaa:=1 to ImageLength do
      begin
        for bbb:=1 to imageWidth do
        begin
          buf[bbb*4-4]:=OA8[bbb,aaa].r;
          buf[bbb*4-3]:=OA8[bbb,aaa].g;
          buf[bbb*4-2]:=OA8[bbb,aaa].b;
          buf[bbb*4-1]:=OA8[bbb,aaa].c;
        end;
        BlockWrite(f,buf,ImageWidth*4);
      end;
    end else
    begin
      For aaa:=1 to ImageLength do
      begin
        for bbb:=1 to imageWidth do
        begin
          if Omode = 2 then
          begin
            buf[bbb*3-3]:=OA8[bbb,aaa].c;
            buf[bbb*3-2]:=OA8[bbb,aaa].r;
            buf[bbb*3-1]:=OA8[bbb,aaa].g;
          end else
          begin
            buf[bbb*3-3]:=OA8[bbb,aaa].r;
            buf[bbb*3-2]:=OA8[bbb,aaa].g;
            buf[bbb*3-1]:=OA8[bbb,aaa].b;
          end;
        end;
        BlockWrite(f,buf,ImageWidth*3);
      end;
    end;
  end;
  for i:=1 to 10 do
  FSKV(0,1,1);
  For i:=1 to length(Footerstring) do
  begin
    c:=ord(Footerstring[i]);
    Write(f,c);
  end;
  for i:=1 to 10 do
  FSKV(0,1,1);
  closefile(f);
end;

Procedure Indlaes_tiff(fnam:string);
Type DirentryType = record               //POS
                      Tag     : integer; //X
                      Dtype   : integer; //X+2
                      Cnt     : integer; //X+4
                      ValOfst : integer; //X+8
                      DEstart : integer;
                    end;

var f:file of byte;
    Buf:array[1..70000] of byte;
    c:byte;
    V:Valuetype;
    VI:integer; //Value in Integer
    i,j : integer;
    Dstart : integer;

    ByteOrder : Boolean; //True = II, false = MM

    FirstIFD : Integer;


    DirEntries : Array[0..100] of DirEntryType;
    NumberOfDirEntries : Integer;

    ImageWidth, ImageLength : integer;
    BitsPerSample, BitsPerSample_i : integer;
    SamplePerPixel : integer;
    Compression : integer;
    PhotometricInterpretation: Integer;
    StripOffsets:integer;
    NStripOffsets : integer;
    SamplesPerPixel:integer;
    RowsPerStrip:integer;
    StripByteCounts:integer;

    TileOffsets,TileByteCounts: array[0..100000] of integer;
    TileOffsets_i, TileByteCounts_i: integer;
    TileWidth, TileLength : integer;
    TileOffsetsStart,TileByteCountsStart:integer;

    rr,gg,bb : byte;
    aaa,bbb : integer;
    ai,aj,ak,al : integer;
    numTilewidth, NumtileHeight : integer;
    aktTileNum:integer;
    TileFile:Boolean;

Function ValU(V:valuetype):integer;
var tval, i:integer;
begin
  tval:=0;
  if ByteOrder then  //least significant first
  with V do
  begin
    for i:=1 to A_i do
    tval:=tval+A[i]*round(power(256,i-1));
  end else           //Most significant first
  with V do
  begin
    for i:=1 to V.A_i do
    tval:=tval+  V.A[i]*round(power(256,V.A_I-i));
  end;
  ValU:=tval;
end;


Procedure FLAS(antal:integer);
var i : integer;
begin
  With V do
  begin
    for i:=1 to antal do
    Read(f,A[i]);
    A_i:=antal;
  end;
  VI:=ValU(V);
end;

Function IntToByte(tal,len:integer):Valuetype;
var V:ValueType;
    i : integer;
    temp1,temp2:integer;
begin
  temp1:=tal;
  for i:=len-1 downto 0 do
  begin
    Temp2:=trunc(temp1/(power(256,i)));
    Temp1:=Temp1-round(Temp2*Power(256,i));
    V.A[len-i]:=Temp2;
  end;
  V.A_i:=len;
  IntToByte:=V;
end;

Procedure FSKV(tal,ant,wrlen:integer);
Var V:Valuetype;
    i:integer;
    dumbyt: Byte;
begin
  dumbyt:=0;
  V:=IntToByte(tal,ant);
  for i:=1 to ant do     //II - de to første karakterer
  Write(f,V.A[i]);
  For i:=1 to wrlen-ant do
  Write(f,dumbyt);
end;

Function D(DT:integer):integer;
begin
  case DT of
     1 : D:=1;
     2 : D:=1;
     3 : D:=2;
     4 : D:=4;
     5 : D:=4;
  else d:=1; end;
end;

procedure DumpDirEntries(fnam:string);
var i:integer;
    f:textfile;
begin
  assignfile(f,fnam);
  rewrite(f);
  for i:=0 to NumberOfDirEntries-1 do
  with DirEntries[i] do
  begin
    writeln(f,format('%20d%20d%20d%20d',[Tag,Dtype,Cnt,ValOfst]));
  end;
  closefile(f);
end;

procedure DumpTileSZtoFile(fnam:string);
var f:textfile;
    ti:integer;
begin
  assignfile(f,fnam);
  rewrite(f);
  for ti:=0 to TileOffsets_i-1 do
  Begin
    writeln(f,format('%10d%10d%10d',[ti,tileOffSets[ti],TileByteCounts[ti]]));
  end;
  closefile(f);
end;


const Footerstring='This file has been generated with the os orto project';

var
  AktDir:integer;
  AktTyp:byte;
  AktCnt:integer;
  AktVal:integer;

  PV: ValueType;
begin
  TileFile:=False;
  Filemode:=0;
  AssignFile(f,fnam);
  reset(f);
  Seek(f,1);
  Read(f,c);
  If Chr(c)='I' then byteorder:=true else byteorder:=false;


  Seek(f,2);
  FLAS(2); //FLAS Indlæser værdi i V (42)

  Seek(f,4);
  FLAS(4);    //Læs position for første IFD

  FirstIFD:=VI;

  Seek(f,FirstIFD);

  FLAS(2);

  NumberOfDirEntries:=VI; //  Showmessage('NumberOfDirEntries: '+IntToStr(VI));

  For i:=0 to NumberOfDirEntries do
  With DirEntries[i] do
    Tag:=0;


  for i:=0 to NumberOfDirEntries-1 do
  begin
    Dstart:= FirstIFD+2+12*i;
    With DirEntries[i] do
    begin
      Seek(f,Dstart);
      FLAS(2);
      Tag:=VI;
      FLAS(2);
      Dtype:=VI;
      FLAS(4);
      CNT:=VI;
      If Tag = 258 then FLAS(4) else FLAS(D(Dtype));  //258 er reference til en position 4 bytes!!! 
      ValOfst:=VI;
      DEStart:=Dstart;
    end;
  end;

  For i:=0 to NumberOfDirEntries-1 do
  With DirEntries[i] do
  begin
    If Tag=273 then
    begin
      StripOffsets:=ValOfst;
      NStripOffsets:=CNT;
    end;
    If Tag=257 then ImageLength:=ValOfst;
    If Tag=256 then ImageWidth:=ValOfst;
    if Tag=258 then
    begin
      BitsPerSample:=ValOfst;      /// NB!!! BITS PER PIXEL ER VEL HER!!!!!
      BitsPerSample_i:=cnt;
    end;
    if tag=277 then SamplesPerPixel:=ValOfSt;
    if Tag=324 then
    begin
      TileFile:=True;
      TileOffsets_i:=Cnt;
      TileOffsetsStart:=ValOfst;
    end;
    if Tag=325 then
    begin
      TileByteCounts_i:=Cnt;
      TileByteCountsStart:=ValOfSt;
    end;
    if Tag=322 then TileWidth:= ValOfst;
    if Tag=323 then TileLength:= ValOfst;
  end;

  if samplesPerPixel = 4 then CIRInputImage:= True;

  Seek(f,Bitspersample);
  FLAS(2);
  If VI=8 then eightbit:=true else eightbit:=false;

  if not tilefile then
  begin
    If NStripOffsets<>1 then
    begin
      seek(f,StripOffsets);
      FLAS(4);
      Seek(f,VI);
    end else
    begin
      seek(f,StripOffsets);
    end;
  end;


  if tilefile then
  begin

    for i:=0 to TileOffsets_i-1 do
    begin
      seek(f,TileOffsetsStart+i*4);
      FLAS(4);
      TileOffsets[i]:=VI;
    end;
    for i:=0 to TileByteCounts_i-1 do
    begin
      seek(f,TileByteCountsStart+i*4);
      FLAS(4);
      TileByteCounts[i]:=VI;
    end;
  end;

  if eightbit then
  begin
    SetLength(BA8,ImageWidth); //Cols
    for aaa:=0 to ImageWidth-1 do
    SetLength(BA8[aaa],ImageLength);  //Rows
  end else
  begin
    SetLength(BA16,ImageWidth); //Cols
    for aaa:=0 to ImageWidth-1 do
    SetLength(BA16[aaa],ImageLength);  //Rows

  end;

  if not tilefile then
  begin
    if eightbit then
    begin
      For aaa:=0 to ImageLength-1 do       //Rows
      begin
        begin
          BlockRead(f,buf,ImageWidth*SamplesPerPixel);
          For bbb:=0 to ImageWidth-1 do
          begin
            BA8[bbb,aaa].r:=buf[((bbb*SamplesPerPixel)+1)];
            BA8[bbb,aaa].g:=buf[((bbb*SamplesPerPixel)+1)+1];
            BA8[bbb,aaa].b:=buf[((bbb*SamplesPerPixel)+1)+2];
            if samplesPerPixel = 4 then
            BA8[bbb,aaa].c:=buf[((bbb*SamplesPerPixel)+1)+3];
          end;
        end;
      end;
    end else
    begin
      PV.A_I:=2;
      For aaa:=0 to ImageLength-1 do       //Rows
      begin

        begin
          BlockRead(f,buf,ImageWidth*SamplesPerPixel*2);
          For bbb:=0 to ImageWidth-1 do
          begin
            PV.A[1]:=buf[((bbb*SamplesPerPixel)+1)];
            PV.A[2]:=buf[((bbb*SamplesPerPixel)+2)];
            BA16[bbb,aaa].r:=ValU(PV); //red
            PV.A[1]:=buf[((bbb*SamplesPerPixel)+3)];
            PV.A[2]:=buf[((bbb*SamplesPerPixel)+4)];
            BA16[bbb,aaa].g:=ValU(PV); //red
            PV.A[1]:=buf[((bbb*SamplesPerPixel)+5)];
            PV.A[2]:=buf[((bbb*SamplesPerPixel)+6)];
            BA16[bbb,aaa].b:=ValU(PV); //red

            if samplesPerPixel = 4 then
            begin
              PV.A[1]:=buf[((bbb*SamplesPerPixel)+7)];
              PV.A[2]:=buf[((bbb*SamplesPerPixel)+8)];
              BA16[bbb,aaa].c:=ValU(PV); //red
            end;
          end;
        end;
      end;
    end;
  end;
  if tilefile then
  begin
    akttilenum:=-1;
    NumTileWidth:=  trunc((ImageWidth+Tilewidth-1)/TileWidth);
    NumTileHeight:= trunc((ImageLength+tileLength-1)/TileLength);
    if eightbit then
    begin
      for ai:=0 to NumtileHeight-1 do
      begin
        for aj:=0 to NumTileWidth-1 do
        begin
          inc(akttilenum);
          seek(f,tileoffsets[akttilenum]);
          for al:=0 to tilelength-1 do
          begin
            BlockRead(f,buf,(tilelength)*SamplesPerPixel);
            aaa:=al+ai*tilelength;
            if aaa>imagelength-1 then continue;
            for ak:=0 to tilewidth-1 do
            begin
              bbb:=ak+aj*tilewidth;
              if bbb>imagewidth-1 then continue;
              BA8[bbb,aaa].r:=buf[ak*SamplesPerPixel+1];
              BA8[bbb,aaa].g:=buf[ak*SamplesPerPixel+2];
              BA8[bbb,aaa].b:=buf[ak*SamplesPerPixel+3];
              if samplesperpixel = 4 then
              BA8[bbb,aaa].c:=buf[ak*SamplesPerPixel+4];
            end;
          end;
        end;
      end;
    end else
    begin
      PV.A_I:=2;
      for ai:=0 to NumtileHeight-1 do
      begin
        for aj:=0 to NumTileWidth-1 do
        begin
          inc(akttilenum);
          seek(f,tileoffsets[akttilenum]);
          for al:=0 to tilelength-1 do
          begin
            BlockRead(f,buf,(tilelength)*SamplesPerPixel*2);
            aaa:=al+ai*tilelength;
            if aaa>imagelength-1 then continue;
            for ak:=0 to tilewidth-1 do
            begin
              bbb:=ak+aj*tilewidth;
              if bbb>imagewidth-1 then continue;
              PV.A[1]:=buf[((ak*SamplesPerPixel*2)+1)];
              PV.A[2]:=buf[((ak*SamplesPerPixel*2)+2)];
              BA16[bbb,aaa].r:=ValU(PV); //red
              PV.A[1]:=buf[((ak*SamplesPerPixel*2)+3)];
              PV.A[2]:=buf[((ak*SamplesPerPixel*2)+4)];
              BA16[bbb,aaa].g:=ValU(PV); //g
              PV.A[1]:=buf[((ak*SamplesPerPixel*2)+5)];
              PV.A[2]:=buf[((ak*SamplesPerPixel*2)+6)];
              BA16[bbb,aaa].b:=ValU(PV); //b
              if samplesperpixel = 4 then
              begin
                PV.A[1]:=buf[((ak*SamplesPerPixel*2)+7)];
                PV.A[2]:=buf[((ak*SamplesPerPixel*2)+8)];
                BA16[bbb,aaa].c:=ValU(PV); //c
              end;
            end;
          end;
        end;
      end;
    end;
  end;
  closefile(f);
  BilColMax:=ImageWidth;
  BilRowMax:=ImageLength;
  Filemode:=2;
end;



Procedure Indlaes_tiff_old(fnam:string);
Type DirentryType = record               //POS
                      Tag     : integer; //X
                      Dtype   : integer; //X+2
                      Cnt     : integer; //X+4
                      ValOfst : integer; //X+8
                    end;

var f:file of byte;
    Buf:array[1..70000] of byte;
    c:byte;
    V:Valuetype;
    VI:integer; //Value in Integer
    i,j : integer;
    Dstart : integer;

    ByteOrder : Boolean; //True = II, false = MM

    FirstIFD : Integer;


    DirEntries : Array[0..100] of DirEntryType;
    NumberOfDirEntries : Integer;

    ImageWidth, ImageLength : integer;
    BitsPerSample : integer;
    Compression : integer;
    PhotometricInterpretation: Integer;
    StripOffsets:integer;
    NStripOffsets : integer;
    SamplesPerPixel:integer;
    RowsPerStrip:integer;
    StripByteCounts:integer;

    rr,gg,bb : byte;
    aaa,bbb : integer;

Function ValU(V:valuetype):integer;
var tval, i:integer;
begin
  tval:=0;
  if ByteOrder then  //least significant first
  with V do
  begin
    for i:=1 to A_i do
    tval:=tval+A[i]*round(power(256,i-1));
  end else           //Most significant first
  with V do
  begin
    for i:=1 to V.A_i do
    tval:=tval+  V.A[i]*round(power(256,V.A_I-i));
  end;
  ValU:=tval;
end;


Procedure FLAS(antal:integer);
var i : integer;
begin
  With V do
  begin
    for i:=1 to antal do
    Read(f,A[i]);
    A_i:=antal;
  end;
  VI:=ValU(V);
end;

Function IntToByte(tal,len:integer):Valuetype;
var V:ValueType;
    i : integer;
    temp1,temp2:integer;
begin
  temp1:=tal;
  for i:=len-1 downto 0 do
  begin
    Temp2:=trunc(temp1/(power(256,i)));
    Temp1:=Temp1-round(Temp2*Power(256,i));
    V.A[len-i]:=Temp2;
  end;
  V.A_i:=len;
  IntToByte:=V;
end;

Procedure FSKV(tal,ant,wrlen:integer);
Var V:Valuetype;
    i:integer;
    dumbyt: Byte;
begin
  dumbyt:=0;
  V:=IntToByte(tal,ant);
  for i:=1 to ant do     //II - de to første karakterer
  Write(f,V.A[i]);
  For i:=1 to wrlen-ant do
  Write(f,dumbyt);
end;


Function D(DT:integer):integer;
begin
  case DT of
     1 : D:=1;
     2 : D:=1;
     3 : D:=2;
     4 : D:=4;
     5 : D:=4;
  else d:=1; end;
end;

const Footerstring='This file has been generated with the os orto project';

var
  AktDir:integer;
  AktTyp:byte;
  AktCnt:integer;
  AktVal:integer;

begin
  Filemode:=0;
  AssignFile(f,fnam);
  reset(f);
  Seek(f,1);
  Read(f,c);
  If Chr(c)='I' then byteorder:=true else byteorder:=false;
  Seek(f,2);
  FLAS(2); //FLAS Indlæser værdi i V (42)

  Seek(f,4);
  FLAS(4);    //Læs position for første IFD

  FirstIFD:=VI;

  Seek(f,FirstIFD);

  FLAS(2);

  NumberOfDirEntries:=VI; //  Showmessage('NumberOfDirEntries: '+IntToStr(VI));

  For i:=1 to NumberOfDirEntries do
  With DirEntries[i] do
    Tag:=0;
  for i:=0 to NumberOfDirEntries-1 do
  begin
    Dstart:= FirstIFD+2+12*i;
    With DirEntries[i] do
    begin
      Seek(f,Dstart);
      FLAS(2);
      Tag:=VI;
      FLAS(2);
      Dtype:=VI;
      FLAS(4);
      CNT:=VI;
      FLAS(D(Dtype));
      ValOfst:=VI;
    end;
  end;

  For i:=0 to NumberOfDirEntries do
  With DirEntries[i] do
  begin
    If Tag=273 then begin StripOffsets:=ValOfst; NStripOffsets:=CNT; end;
    If Tag=257 then ImageLength:=ValOfst;
    If Tag=256 then ImageWidth:=ValOfst;
  end;

  If NStripOffsets<>1 then
  begin
    seek(f,StripOffsets);
    FLAS(4);
    Seek(f,VI);
  end else
  begin
    seek(f,StripOffsets);
  end;
  SetLength(BA8,ImageWidth); //Cols
  for aaa:=0 to ImageWidth-1 do
  SetLength(BA8[aaa],ImageLength);  //Rows
  For aaa:=0 to ImageLength-1 do       //Rows
  begin
    BlockRead(f,buf,ImageWidth*3);
    For bbb:=0 to ImageWidth-1 do
    begin
      BA8[bbb,aaa].r:=buf[((bbb*3)+1)];
      BA8[bbb,aaa].g:=buf[((bbb*3)+1)+1];
      BA8[bbb,aaa].b:=buf[((bbb*3)+1)+2];
    end;
  end;
  closefile(f);
  BilColMax:=ImageWidth;
  BilRowMax:=ImageLength;
  Filemode:=2;
end;

Procedure WriteOrtofoto8;
var f:file Of pixel8;
    icol,irow : integer;
    buf : array[0..12000] of pixel8;
begin
  Assign(f,OrtoFilNavn);
  Rewrite(f);
  for irow:=1 to MaxPixRow do
  begin
    for icol:=1 to MaxPixCol do
    buf[icol-1]:= OA8[icol,irow];  
    BlockWrite(f,buf,MAxPixCol);
  end;
  closefile(f);
end;

Procedure indlaesBWfil(fnam:string);
var icol,irow : integer;
    f         : file of byte;
    buf       : array[0..12000] of byte;
begin
  Assignfile(f,fnam);
  reset(f);
  for irow:=0 to BilRowMax-1 do
  begin
    BlockRead(f,buf,BilColMax);
    For icol:=0 to BilColMax-1 do
    begin
      BA8[icol,irow].r:=buf[icol];
      BA8[icol,irow].g:=buf[icol];
      BA8[icol,irow].b:=buf[icol];
    end;
  end;
  closefile(f);
end;

Procedure IndlaesRGBfil(fnam:String);
var icol,irow : integer;
    cc,cr     : integer;
    f         : file of byte;
    buf       : array[1..15000] of byte;
begin
  Assignfile(f,fnam);
  reset(f);
  for irow:=0 to BilRowMax-1 do
  begin
    BlockRead(f,buf,BilColMax);
    For icol:=0 to BilColMax-1 do
    begin
      BA8[icol,irow].r:=buf[icol];
    end;
  end;
  for irow:=0 to BilRowMax-1 do
  begin
    BlockRead(f,buf,BilColMax);
    For icol:=0 to BilColMax-1 do
    begin
      BA8[icol,irow].g:=buf[icol];
    end;
  end;
  for irow:=0 to BilRowMax-1 do
  begin
    BlockRead(f,buf,BilColMax);
    For icol:=0 to BilColMax-1 do
    begin
      BA8[icol,irow].b:=buf[icol];
    end;
  end;
  closefile(f);
end;

Procedure Indlaes_billede(fnam:string);
begin
  If channels = 1 then indlaesBWfil(fnam);
  if Channels = 3 then indlaesRGBfil(fnam);
end;

Procedure Skriv_tfw(fnam:string);
var f:textfile;
    tfwx,tfwy:real;
begin
  assignfile(f,ChangeFileExt(fnam,'.tfw'));
  rewrite(f);
  If Rot34 then
  begin
    tfwx:=-ULY +0.5*pixstr; 
    tfwy:=ULX+PixStr*MaxPixCol-0.5*pixstr;
  end else
  begin
    tfwx:=ULX+0.5*pixstr;
    tfwy:=ULY-0.5*pixstr;
  end;
  Writeln(f,FloatToStr(PixStr));
  Writeln(f,'0.00000');
  Writeln(f,'0.00000');
  Writeln(f,FloatToStr(-PixStr));
  Writeln(f,FloatToStr(tfwx));
  Writeln(f,FloatToStr(tfwy));
  closeFile(f);
end;

Procedure Skriv_tfw_tn(fnam:string);
var f:textfile;
    tfwx,tfwy:real;
begin
  assignfile(f,ChangeFileExt(fnam,'.tfw'));
  rewrite(f);

  If Rot34 then
  begin
    tfwx:=-ULY +0.5*pixstr; 
    tfwy:=ULX+PixStr*(MaxPixCol/2)-0.5*pixstr;
  end else
  begin
    tfwx:=ULX+pixstr;
    tfwy:=ULY-pixstr;
  end;
  Writeln(f,FloatToStr(PixStr*2));
  Writeln(f,'0.00000');
  Writeln(f,'0.00000');
  Writeln(f,FloatToStr(-PixStr*2));
  Writeln(f,FloatToStr(tfwx));
  Writeln(f,FloatToStr(tfwy));
  closeFile(f);
end;



end.
