{$IFDEF WIN32}
{$I DEFINES.INC}
{$ENDIF}

{$A+,B-,D+,E-,F+,I-,L+,N-,O+,R-,S+,V-}

UNIT ArcView;

INTERFACE

USES
  Common;

FUNCTION ValidIntArcType(FileName: Str12): Boolean;
PROCEDURE ViewInternalArchive(FileName: AStr);
PROCEDURE ViewDirInternalArchive;

IMPLEMENTATION

USES
  Dos,
  File0,
  File14,
  TimeFunc;

CONST
  MethodType: ARRAY [0..21] OF STRING[10] =
   ('Directory ',  {* Directory marker *}
    'Unknown!  ',  {* Unknown compression type *}
    'Stored    ',  {* No compression *}
    'Packed    ',  {* Repeat-Byte compression *}
    'Squeezed  ',  {* Huffman with repeat-Byte compression *}
    'crunched  ',  {* Obsolete LZW compression *}
    'Crunched  ',  {* LZW 9-12 bit with repeat-Byte compression *}
    'Squashed  ',  {* LZW 9-13 bit compression *}
    'Crushed   ',  {* LZW 2-13 bit compression *}
    'Shrunk    ',  {* LZW 9-13 bit compression *}
    'Reduced 1 ',  {* Probabilistic factor 1 compression *}
    'Reduced 2 ',  {* Probabilistic factor 2 compression *}
    'Reduced 3 ',  {* Probabilistic factor 3 compression *}
    'Reduced 4 ',  {* Probabilistic factor 4 compression *}
    'Frozen    ',  {* Modified LZW/Huffman compression *}
    'Imploded  ',  {* Shannon-Fano tree compression *}
    'Compressed',
    'Method 1  ',
    'Method 2  ',
    'Method 3  ',
    'Method 4  ',
    'Deflated  ');

TYPE
  ArcRecordType = RECORD   {* structure of ARC archive file header *}
    FileName: ARRAY [0..12] OF Char; {* FileName *}
    C_Size: LongInt;     {* compressed size *}
    Mod_Date: SmallInt;   {* last mod file Date *}
    Mod_Time: SmallInt;   {* last mod file Time *}
    CRC: SmallInt;        {* CRC *}
    U_Size: LongInt;     {* uncompressed size *}
  END;

  ZipRecordType = RECORD   {* structure of ZIP archive file header *}
    Version: SmallInt;    {* Version needed to extract *}
    Bit_Flag: SmallInt;   {* General purpose bit flag *}
    Method: SmallInt;     {* compression Method *}
    Mod_Time: SmallInt;   {* last mod file Time *}
    Mod_Date: SmallInt;   {* last mod file Date *}
    CRC: LongInt;        {* CRC-32 *}
    C_Size: LongInt;     {* compressed size *}
    U_Size: LongInt;     {* uncompressed size *}
    F_Length: SmallInt;   {* FileName Length *}
    E_Length: SmallInt;   {* extra field Length *}
  END;

  ZooRecordType = RECORD   {* structure of ZOO archive file header *}
    Tag: LongInt;     {* Tag -- redundancy check *}
    Typ: Byte;        {* TYPE of directory entry (always 1 for now) *}
    Method: Byte;     {* 0 = Stored, 1 = Crunched *}
    Next: LongInt;    {* position of Next directory entry *}
    Offset: LongInt;  {* position of this file *}
    Mod_Date: SmallWord;   {* modification Date (DOS format) *}
    Mod_Time: SmallWord;   {* modification Time (DOS format) *}
    CRC: SmallWord;        {* CRC *}
    U_Size: LongInt;  {* uncompressed size *}
    C_Size: LongInt;  {* compressed size *}
    Major_V: Char;    {* major Version number *}
    Minor_V: Char;    {* minor Version number *}
    Deleted: Byte;    {* 0 = active, 1 = Deleted *}
    Struc: Char;      {* file structure if any *}
    Comment: LongInt; {* location of file Comment (0 = none) *}
    Cmt_Size: SmallWord;   {* Length of Comment (0 = none) *}
    FName: ARRAY [0..12] OF Char; {* FileName *}
    Var_DirLen: SmallInt; {* Length of variable part of dir entry *}
    TZ: Char;         {* timezone where file was archived *}
    Dir_Crc: SmallWord;    {* CRC of directory entry *}
  END;

  LZHRecordType = RECORD   {* structure of LZH archive file header *}
    H_Length: Byte;   {* Length of header *}
    H_Cksum: Byte;    {* checksum of header bytes *}
    Method: ARRAY [1..5] OF Char; {* compression TYPE "-lh#-" *}
    C_Size: LongInt;  {* compressed size *}
    U_Size: LongInt;  {* uncompressed size *}
    Mod_Time: SmallInt;{* last mod file Time *}
    Mod_Date: SmallInt;{* last mod file Date *}
    Attrib: SmallInt;  {* file attributes *}
    F_Length: Byte;   {* Length of FileName *}
    CRC: SmallInt;     {* CRC *}
  END;

  ARJRecordType = RECORD
    FirstHdrSize: Byte;
    ARJVersion: Byte;
    ARJRequired: Byte;
    HostOS: Byte;
    Flags: Byte;
    Method: Byte;
    FileType: Byte;
    GarbleMod: Byte;
    Time,
    Date: SmallInt;
    CompSize: LongInt;
    OrigSize: LongInt;
    OrigCRC: ARRAY[1..4] OF Byte;
    EntryName: SmallWord;
    AccessMode: SmallWord;
    HostData: SmallWord;
  END;

  OutRec = RECORD      {* output information structure *}
    FileName: AStr;    {* output file name *}
    Date,              {* output Date *}
    Time,              {* output Time *}
    Method: SmallInt;   {* output storage type *}
    CSize,             {* output compressed size *}
    USize: LongInt;    {* output uncompressed size *}
  END;

PROCEDURE AbEnd(VAR Aborted: Boolean);
BEGIN
  NL;
  Print('^7** ^5Error processing archive^7 **');
  Aborted := TRUE;
  Abort := TRUE;
  Next := TRUE;
END;

PROCEDURE Details(Out: OutRec;
                  VAR Level,
                  NumFiles: Integer;
                  VAR TotalCompSize,
                  TotalUnCompSize: LongInt);
VAR
  OutP: AStr;
  AMPM: Str2;
  DT: DateTime;
  Ratio: LongInt;
BEGIN
  Out.FileName := AllCaps(Out.FileName);
  DT.Day := Out.Date AND $1f;                 {* Day = bits 4-0 *}
  DT.Month := (Out.Date SHR 5) AND $0f;       {* Month = bits 8-5 *}
  DT.Year := ((Out.Date SHR 9) AND $7f) + 80; {* Year = bits 15-9 *}
  DT.Min := (Out.Time SHR 5) AND $3f;      {* Minute = bits 10-5 *}
  DT.Hour := (Out.Time SHR 11) AND $1f;       {* Hour = bits 15-11 *}

  IF (DT.Month > 12) THEN
    Dec(DT.Month,12);     {* adjust for Month > 12 *}
  IF (DT.Year > 99) THEN
    Dec(DT.Year,100);      {* adjust for Year > 1999 *}
  IF (DT.Hour > 23) THEN
    Dec(DT.Hour,24);       {* adjust for Hour > 23 *}
  IF (DT.Min > 59) THEN
    Dec(DT.Min,60);   {* adjust for Minute > 59 *}

  ConvertAmPm(DT.Hour,AmPm);

  IF (Out.USize = 0) THEN
    Ratio := 0
  ELSE   {* Ratio is 0% for null-Length file *}
    Ratio := (100 - ((Out.CSize * 100) DIV Out.USize));
  IF (Ratio > 99) THEN
     Ratio := 99;

  OutP := '^4'+PadRightStr(FormatNumber(Out.USize),13)+
          ' '+PadRightStr(FormatNumber(Out.CSize),13)+
          ' '+PadRightInt(Ratio,2)+'%'+
          ' ^9'+MethodType[Out.Method]+
          ' ^7'+ZeroPad(IntToStr(DT.Month))+
          '/'+ZeroPad(IntToStr(DT.Day))+
          '/'+ZeroPad(IntToStr(DT.Year))+
          ' '+ZeroPad(IntToStr(DT.Hour))+
          ':'+ZeroPad(IntToStr(DT.Min))+
          AMPM[1]+' ^5';

  IF (Level > 0) THEN
    OutP := OutP + PadRightStr('',Level); {* spaces for dirs (ARC only)*}

  OutP := OutP + Out.FileName;

  PrintACR(OutP);

  IF (Out.Method = 0) THEN
    Inc(Level)    {* bump dir Level (ARC only) *}
  ELSE
  BEGIN
    Inc(TotalCompSize,Out.CSize);  {* adjust accumulators and counter *}
    Inc(TotalUnCompSize,Out.USize);
    Inc(NumFiles);
  END;
END;

PROCEDURE Final(NumFiles: Integer;
                TotalCompSize,
                TotalUnCompSize: LongInt);
VAR
  OutP: AStr;
  Ratio: LongInt;
BEGIN
  IF (TotalUnCompSize = 0) THEN
    Ratio := 0
  ELSE
    Ratio := (100 - ((TotalCompSize * 100) DIV TotalUnCompSize));
  IF (Ratio > 99) THEN
    Ratio := 99;

  OutP := '^4'+PadRightStr(FormatNumber(TotalUnCompSize),13)+
          ' '+PadRightStr(FormatNumber(TotalCompSize),13)+
          ' '+PadRightInt(Ratio,2)+
          '%                            ^5'+IntToStr(NumFiles)+' '+Plural('file',NumFiles);
  PrintACR('^4------------- ------------- ---                            ------------');
  PrintACR(OutP);
END;

FUNCTION GetByte(VAR F: FILE; VAR Aborted: Boolean): Char;
VAR
  C: Char;
  NumRead: Word;
BEGIN
  IF (NOT Aborted) THEN
  BEGIN
    BlockRead(F,C,1,NumRead);
    IF (NumRead = 0) THEN
    BEGIN
      Close(F);
      AbEnd(Aborted);
    END;
    GetByte := C;
  END;
END;

PROCEDURE ZIP_Proc(VAR F: FILE;
                   VAR Out: OutRec;
                   VAR Level,
                   NumFiles: Integer;
                   VAR TotalCompSize,
                   TotalUnCompSize: LongInt;
                   VAR Aborted: Boolean);
VAR
  ZIP: ZipRecordType;
  C: Char;
  Counter: Integer;
  NumRead: Word;
  Signature: LongInt;
BEGIN
  WHILE (NOT Aborted) DO
  BEGIN
    BlockRead(F,Signature,4,NumRead);
    IF (Signature = $02014b50) OR (Signature = $06054b50) THEN
      Exit;
    IF (NumRead <> 4) OR (Signature <> $04034b50) THEN
    BEGIN
      AbEnd(Aborted);
      Exit;
    END;
    BlockRead(F,ZIP,26,NumRead);
    IF (NumRead <> 26) THEN
    BEGIN
      AbEnd(Aborted);
      Exit;
    END;
    FOR Counter := 1 TO ZIP.F_Length DO
      Out.FileName[Counter] := GetByte(F,Aborted);
    Out.FileName[0] := Chr(ZIP.F_Length);
    FOR Counter := 1 TO ZIP.E_Length DO
      C := GetByte(F,Aborted);
    Out.Date := ZIP.Mod_Date;
    Out.Time := ZIP.Mod_Time;
    Out.CSize := ZIP.C_Size;
    Out.USize := ZIP.U_Size;
    CASE ZIP.Method OF
      0 : Out.Method := 2;
      1 : Out.Method := 9;
      2,3,4,5 :
          Out.Method := (ZIP.Method + 8);
      6 : Out.Method := 15;
      8 : Out.Method := 21;
    ELSE
      Out.Method := 1;
    END;
    Details(Out,Level,NumFiles,TotalCompSize,TotalUnCompSize);
    IF (Abort) THEN
      Exit;
    Seek(F,(FilePos(F) + ZIP.C_Size));
    IF (IOResult <> 0) THEN
      AbEnd(Aborted);
    IF (Abort) THEN
      Exit;
  END;
END;

PROCEDURE ARJ_Proc(VAR ArjFile: FILE;
                   VAR Out: OutRec;
                   VAR Level,
                   NumFiles: Integer;
                   VAR TotalCompSize,
                   TotalUnCompSize: LongInt;
                   VAR Aborted: Boolean);
TYPE
  ARJSignature = RECORD
    MagicNumber: SmallWord;
    BasicHdrSiz: SmallWord;
  END;
VAR
  Hdr: ARJRecordType;
  Sig: ARJSignature;
  FileName,
  FileTitle: AStr;
  JunkByte: Byte;
  Counter: Integer;
  NumRead,
  ExtSize: Word;
  HeaderCrc: LongInt;
BEGIN
  BlockRead(ArjFile,Sig,SizeOf(Sig));
  IF (IOResult <> 0) OR (Sig.MagicNumber <> $EA60) THEN
    Exit
  ELSE
  BEGIN
    BlockRead(ArjFile,Hdr,SizeOf(Hdr),NumRead);
    Counter := 0;
    REPEAT
      Inc(Counter);
      BlockRead(ArjFile,FileName[Counter],1);
    UNTIL (FileName[Counter] = #0);
    FileName[0] := Chr(Counter - 1);
    REPEAT
      BlockRead(ArjFile,JunkByte,1);
    UNTIL (JunkByte = 0);
    BlockRead(ArjFile,HeaderCRC,4);
    BlockRead(ArjFile,ExtSize,2);
    IF (ExtSize > 0) THEN
      Seek(ArjFile,FilePos(ArjFile) + ExtSize + 4);
    BlockRead(ArjFile,Sig,SizeOf(Sig));
    WHILE (Sig.BasicHdrSiz > 0) AND (NOT Abort) AND (IOResult = 0) DO
    BEGIN
      BlockRead(ArjFile,Hdr,SizeOf(Hdr),NumRead);
      Counter := 0;
      REPEAT
        Inc(Counter);
        BlockRead(ArjFile,FileName[Counter],1);
      UNTIL (FileName[Counter] = #0);
      FileName[0] := Chr(Counter - 1);
      Out.FileName := FileName;
      Out.Date := Hdr.Date;
      Out.Time := Hdr.Time;
      IF (Hdr.Method = 0) THEN
        Out.Method := 2
      ELSE
        Out.Method := (Hdr.Method + 16);
      Out.CSize := Hdr.CompSize;
      Out.USize := Hdr.OrigSize;
      Details(Out,Level,NumFiles,TotalCompSize,TotalUnCompSize);
      IF (Abort) THEN
        Exit;
      REPEAT
        BlockRead(ArjFile,JunkByte,1);
      UNTIL (JunkByte = 0);
      BlockRead(ArjFile,HeaderCRC,4);
      BlockRead(ArjFile,ExtSize,2);
      Seek(ArjFile,(FilePos(ArjFile) + Hdr.CompSize));
      BlockRead(ArjFile,Sig,SizeOf(Sig));
    END;
  END;
END;

PROCEDURE ARC_Proc(VAR F: FILE;
                   VAR Out: OutRec;
                   VAR Level,
                   NumFiles: Integer;
                   VAR TotalCompSize,
                   TotalUnCompSize: LongInt;
                   VAR Aborted: Boolean);
VAR
  Arc: ArcRecordType;
  C: Char;
  Counter,
  Method: Integer;
  NumRead: Word;
BEGIN
  REPEAT
    C := GetByte(F,Aborted);
    Method := Ord(GetByte(F,Aborted));
    CASE Method OF
      0 : Exit;
      1,2 :
          Out.Method := 2;
      3,4,5,6,7 :
          Out.Method := Method;
      8,9,10 :
           Out.Method := (Method - 2);
      30 : Out.Method := 0;
      31 : Dec(Level);
    ELSE
      Out.Method := 1;
    END;
    IF (Method <> 31) THEN
    BEGIN
      BlockRead(F,Arc,23,NumRead);
      IF (NumRead <> 23) THEN
      BEGIN
        AbEnd(Aborted);
        Exit;
      END;
      IF (Method = 1) THEN
        Arc.U_Size := Arc.C_Size
      ELSE
      BEGIN
        BlockRead(F,Arc.U_Size,4,NumRead);
        IF (NumRead <> 4) THEN
        BEGIN
          AbEnd(Aborted);
          Exit;
        END;
      END;
      Counter := 0;
      REPEAT
        Inc(Counter);
        Out.FileName[Counter] := Arc.FileName[Counter - 1];
      UNTIL (Arc.FileName[Counter] = #0) OR (Counter = 13);
      Out.FileName[0] := Chr(Counter);
      Out.Date := Arc.Mod_Date;
      Out.Time := Arc.Mod_Time;
      IF (Method = 30) THEN
      BEGIN
        Arc.C_Size := 0;
        Arc.U_Size := 0;
      END;
      Out.CSize := Arc.C_Size;
      Out.USize := Arc.U_Size;
      Details(Out,Level,NumFiles,TotalCompSize,TotalUnCompSize);
      IF (Abort) THEN
        Exit;
      IF (Method <> 30) THEN
      BEGIN
        Seek(F,(FilePos(F) + Arc.C_Size));
        IF (IOResult <> 0) THEN
        BEGIN
          AbEnd(Aborted);
          Exit;
        END;
      END;
    END;
  UNTIL (C <> #$1a) OR (Aborted);
  IF (NOT Aborted) THEN
    AbEnd(Aborted);
END;

PROCEDURE ZOO_Proc(VAR F: FILE;
                   VAR Out: OutRec;
                   VAR Level,
                   NumFiles: Integer;
                   VAR TotalCompSize,
                   TotalUnCompSize: LongInt;
                   VAR Aborted: Boolean);
VAR
  ZOO: ZooRecordType;
  ZOO_LongName,
  ZOO_DirName: AStr;
  C: Char;
  NamLen,
  DirLen: Byte;
  Counter,
  Method: Integer;
  NumRead: Word;
  ZOO_Temp,
  ZOO_Tag: LongInt;
BEGIN

  FOR Counter := 0 TO 19 DO
    C := GetByte(F,Aborted);
  BlockRead(F,ZOO_Tag,4,NumRead);
  IF (NumRead <> 4) THEN
    AbEnd(Aborted);
  IF (ZOO_Tag <> $fdc4a7dc) THEN
    AbEnd(Aborted);
  BlockRead(F,ZOO_Temp,4,NumRead);
  IF (NumRead <> 4) THEN
    AbEnd(Aborted);
  Seek(F,ZOO_Temp);
  IF (IOResult <> 0) THEN
    AbEnd(Aborted);

  WHILE (NOT Aborted) DO
  BEGIN
    BlockRead(F,ZOO,56,NumRead);
    IF (NumRead <> 56) THEN
    BEGIN
      AbEnd(Aborted);
      Exit;
    END;
    IF (ZOO.Tag <> $fdc4a7dc) THEN
      AbEnd(Aborted);
    IF (Abort) OR (ZOO.Next = 0) THEN
      Exit;
    NamLen := Ord(GetByte(F,Aborted));
    DirLen := Ord(GetByte(F,Aborted));
    ZOO_LongName := '';
    ZOO_DirName := '';

    IF (NamLen > 0) THEN
      FOR Counter := 1 TO NamLen DO
        ZOO_LongName := ZOO_LongName + GetByte(F,Aborted);

    IF (DirLen > 0) THEN
    BEGIN
      FOR Counter := 1 TO DirLen DO
        ZOO_DirName := ZOO_DirName + GetByte(F,Aborted);
      IF (ZOO_DirName[Length(ZOO_DirName)] <> '/') THEN
        ZOO_DirName := ZOO_DirName + '/';
    END;
    IF (ZOO_LongName <> '') THEN
      Out.FileName := ZOO_LongName
    ELSE
    BEGIN
      Counter := 0;
      REPEAT
        Inc(Counter);
        Out.FileName[Counter] := ZOO.FName[Counter - 1];
      UNTIL (ZOO.FName[Counter] = #0) OR (Counter = 13);
      Out.FileName[0] := Chr(Counter);
      Out.FileName := ZOO_DirName+Out.FileName;
    END;
    Out.Date := ZOO.Mod_Date;
    Out.Time := ZOO.Mod_Time;
    Out.CSize := ZOO.C_Size;
    Out.USize := ZOO.U_Size;
    Method := ZOO.Method;
    CASE Method OF
      0 : Out.Method := 2;
      1 : Out.Method := 6;
    ELSE
      Out.Method := 1;
    END;
    IF NOT (ZOO.Deleted = 1) THEN
      Details(Out,Level,NumFiles,TotalCompSize,TotalUnCompSize);
    IF (Abort) THEN
      Exit;
    Seek(F,ZOO.Next);
    IF (IOResult <> 0) THEN
    BEGIN
      AbEnd(Aborted);
      Exit;
    END;
  END;
END;

PROCEDURE LZH_Proc(VAR F: FILE;
                   VAR Out: OutRec;
                   VAR Level,
                   NumFiles: Integer;
                   VAR TotalCompSize,
                   TotalUnCompSize: LongInt;
                   VAR Aborted: Boolean);
VAR
  LZH: LZHRecordType;
  C,
  Method: Char;
  Counter: Integer;
  NumRead: Word;
BEGIN
  WHILE (NOT Aborted) DO
  BEGIN
    C := GetByte(F,Aborted);
    IF (C = #0) THEN
      Exit
    ELSE
      LZH.H_Length := Ord(C);
    C := GetByte(F,Aborted);
    LZH.H_Cksum := Ord(C);
    BlockRead(F,LZH.Method,5,NumRead);
    IF (NumRead <> 5) THEN
    BEGIN
      AbEnd(Aborted);
      Exit;
    END;
    IF ((LZH.Method[1] <> '-') OR (LZH.Method[2] <> 'l') OR (LZH.Method[3] <> 'h')) THEN
    BEGIN
      AbEnd(Aborted);
      Exit;
    END;
    BlockRead(F,LZH.C_Size,15,NumRead);
    IF (NumRead <> 15) THEN
    BEGIN
      AbEnd(Aborted);
      Exit;
    END;
    FOR Counter := 1 TO LZH.F_Length DO
      Out.FileName[Counter] := GetByte(F,Aborted);
    Out.FileName[0] := Chr(LZH.F_Length);
    IF ((LZH.H_Length - LZH.F_Length) = 22) THEN
    BEGIN
      BlockRead(F,LZH.CRC,2,NumRead);
      IF (NumRead <> 2) THEN
      BEGIN
        AbEnd(Aborted);
        Exit;
      END;
    END;
    Out.Date := LZH.Mod_Date;
    Out.Time := LZH.Mod_Time;
    Out.CSize := LZH.C_Size;
    Out.USize := LZH.U_Size;
    Method := LZH.Method[4];
    CASE Method OF
      '0' : Out.Method := 2;
      '1' : Out.Method := 14;
    ELSE
      Out.Method := 1;
    END;
    Details(Out,Level,NumFiles,TotalCompSize,TotalUnCompSize);
    Seek(F,(FilePos(F) + LZH.C_Size));
    IF (IOResult <> 0) THEN
      AbEnd(Aborted);
    IF (Abort) THEN
      Exit;
  END;
END;

FUNCTION ValidIntArcType(FileName: Str12): Boolean;
CONST
  ArcTypes: ARRAY [1..7] OF Str3 = ('ZIP','ARC','PAK','ZOO','LZH','ARK','ARJ');
VAR
  Counter: Byte;
BEGIN
  ValidIntArcType := FALSE;
  FOR Counter := 1 TO 7 DO
    IF (ArcTypes[Counter] = AllCaps(Copy(FileName,(Pos('.',FileName) + 1),3))) THEN
      ValidIntArcType := TRUE;
END;

PROCEDURE ViewInternalArchive(FileName: AStr);
VAR
  LZH_Method: ARRAY [1..5] OF Char;
  F: FILE;
  (*
  DirInfo: SearchRec;
  *)
  Out: OutRec;
  C: Char;
  LZH_H_Length,
  Counter,
  ArcType: Byte;
  RCode,
  FileType,
  Level,
  NumFiles: Integer;
  NumRead: Word;
  TotalUnCompSize,
  TotalCompSize: LongInt;
  Aborted: Boolean;
BEGIN
  FileName := SQOutSp(FileName);

  IF (Pos('*',FileName) <> 0) OR (Pos('?',FileName) <> 0) THEN
  BEGIN
    FindFirst(FileName,AnyFile - Directory - VolumeID - Hidden - SysFile,DirInfo);
    IF (DOSError = 0) THEN
      FileName := DirInfo.Name;
  END;

  IF ((Exist(FileName)) AND (NOT Abort) AND (NOT HangUp)) THEN
  BEGIN

    ArcType := 1;
    WHILE (General.FileArcInfo[ArcType].Ext <> '') AND
          (General.FileArcInfo[ArcType].Ext <> Copy(FileName,(Length(FileName) - 2),3)) AND
          (ArcType < MaxArcs + 1) DO
      Inc(ArcType);

    IF NOT ((General.FileArcInfo[ArcType].Ext = '') OR (ArcType = 7)) THEN
    BEGIN
      IF (General.FileArcInfo[ArcType].ListLine[1] = '/') AND
         (General.FileArcInfo[ArcType].ListLine[2] IN ['1'..'5']) AND
         (Length(General.FileArcInfo[ArcType].ListLine) = 2) THEN
      BEGIN
        Aborted := FALSE;
        Abort := FALSE;
        Next := FALSE;
        NL;
        PrintACR('^3'+StripName(FileName)+':');
        NL;
        IF (NOT Abort) THEN
        BEGIN
          Assign(F,FileName);
          Reset(F,1);
          C := GetByte(F,Aborted);
          CASE C OF
            #$1a : FileType := 1;
             'P' : BEGIN
                     IF (GetByte(F,Aborted) <> 'K') THEN
                       AbEnd(Aborted);
                     FileType := 2;
                   END;
             'Z' : BEGIN
                     FOR Counter := 0 TO 1 DO
                       IF (GetByte(F,Aborted) <> 'O') THEN
                         AbEnd(Aborted);
                     FileType := 3;
                   END;
             #96 : BEGIN
                     IF (GetByte(F,Aborted) <> #234) THEN
                       AbEnd(Aborted);
                     FileType := 5;
                   END;
          ELSE
          BEGIN
            LZH_H_Length := Ord(C);
            C := GetByte(F,Aborted);
            FOR Counter := 1 TO 5 DO
              LZH_Method[Counter] := GetByte(F,Aborted);
            IF ((LZH_Method[1] = '-') AND (LZH_Method[2] = 'l') AND (LZH_Method[3] = 'h')) THEN
              FileType := 4
            ELSE
              AbEnd(Aborted);
          END;
        END;
        Reset(F,1);
        Level := 0;
        NumFiles := 0;
        TotalCompSize := 0;
        TotalUnCompSize := 0;
        AllowContinue := TRUE;
        PrintACR('^3 Length         Size Now     %    Method     Date    Time  FileName');
        PrintACR('^4------------- ------------- --- ---------- -------- ------ ------------');
        CASE FileType OF
          1 : ARC_Proc(F,Out,Level,NumFiles,TotalCompSize,TotalUnCompSize,Aborted);
          2 : ZIP_Proc(F,Out,Level,NumFiles,TotalCompSize,TotalUnCompSize,Aborted);
          3 : ZOO_Proc(F,Out,Level,NumFiles,TotalCompSize,TotalUnCompSize,Aborted);
          4 : LZH_Proc(F,Out,Level,NumFiles,TotalCompSize,TotalUnCompSize,Aborted);
          5 : ARJ_Proc(F,Out,Level,NumFiles,TotalCompSize,TotalUnCompSize,Aborted);
        END;
        Final(NumFiles,TotalCompSize,TotalUnCompSize);
        Close(F);
        AllowContinue := FALSE;
      END;
    END
    ELSE
    BEGIN
      NL;
      Prompt('^3Archive '+FileName+':  ^4Please wait....');
      ShellDOS(FALSE,FunctionalMCI(General.FileArcInfo[ArcType].ListLine,FileName,'')+' >shell.$$$',RCode);
      BackErase(15);
      PFL('SHELL.$$$');
      Kill('SHELL.$$$');
    END;
  END;
  END;
END;

PROCEDURE ViewDirInternalArchive;
VAR
  FileName: Str12;
  DirFileRecNum: Integer;
  Found,
  LastArc,
  LastGif: Boolean;
BEGIN
  {
  NL;
  Print('^9Enter the name of the archive(s) you would like to view:');
  }
  lRGLngStr(25,FALSE);
  FileName := '';
  { Print(FString.lGFNLine1); }
  lRGLngStr(28,FALSE);
  { Prt(FString.GFNLine2); }
  lRGLngStr(29,FALSE);
  GetFileName(FileName);
  LastArc := FALSE;
  LastGif := FALSE;
  AllowContinue := TRUE;
  Found := FALSE;
  Abort := FALSE;
  Next := FALSE;
  RecNo(FileInfo,FileName,DirFileRecNum);
  IF (BadDownloadPath) THEN
    Exit;
  WHILE (DirFileRecNum <> -1) AND (NOT Abort) AND (NOT HangUp) DO
  BEGIN
    Seek(FileInfoFile,DirFileRecNum);
    Read(FileInfoFile,FileInfo);
    IF IsGIFExt(FileInfo.FileName) THEN
    BEGIN
      LastArc := FALSE;
      IF (NOT LastGif) THEN
      BEGIN
        LastGif := TRUE;
        NL;
        PrintACR('^3Filename.Ext^4:^3Resolution ^4:^3Num Colors^4:^3Signature');
        PrintACR('^4============:===========:==========:===============');
      END;
      IF Exist(MemFileArea.DLPath+FileInfo.FileName) THEN
      BEGIN
        PrintACR(GetGIFSpecs(MemFileArea.DLPath+SQOutSp(FileInfo.FileName),FileInfo.Description,1));
        Found := TRUE;
      END
      ELSE
      BEGIN
        PrintACR(GetGIFSpecs(MemFileArea.ULPath+SQOutSp(FileInfo.FileName),FileInfo.Description,1));
        Found := TRUE;
      END;
    END
    ELSE IF ValidIntArcType(FileInfo.FileName) THEN
    BEGIN
      LastGif := FALSE;
      IF (NOT LastArc) THEN
        LastArc := TRUE;
      IF Exist(MemFileArea.DLPath+FileInfo.FileName) THEN
      BEGIN
        ViewInternalArchive(MemFileArea.DLPath+FileInfo.FileName);
        Found := TRUE;
      END
      ELSE
      BEGIN
        ViewInternalArchive(MemFileArea.ULPath+FileInfo.FileName);
        Found := TRUE;
      END;
    END;
    WKey;
    NRecNo(FileInfo,DirFileRecNum);
  END;
  Close(FileInfoFile);
  Close(ExtInfoFile);
  AllowContinue := FALSE;
  IF (NOT Found) THEN
  BEGIN
    NL;
    Print('File not found.');
  END;
  LastError := IOResult;
END;

END.