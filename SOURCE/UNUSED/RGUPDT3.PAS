{$M 49152,0,65536}
PROGRAM RGUPDT3;

USES
  Crt,
  Dos,
  TimeFunc;

{$I RECORDS.PAS}

CONST
  DYNY: BOOLEAN = FALSE;

TYPE
  OldFileInfoFlagType =
   (OldFINotVal,                   { If file is not validated }
    OldFIIsRequest,                { If file is REQUEST }
    OldFIResumeLater,              { If file is RESUME-LATER }
    OldFIHatched);                 { Has file been hatched? }

  OldFIFlagSet = SET OF OldFileInfoFlagType;

  OldFileInfoRecordType =          { *.DIR : File records }
  {$IFDEF WIN32} PACKED {$ENDIF} RECORD
    FileName: STRING[12];          { Filename }
    Description: STRING[50];       { File description }
    FilePoints: Integer;           { File points }
    Downloaded: LongInt;           { Number DLs }
    SizeMod: Byte;                 { # chars over last 128 Byte block }
    Blocks: LongInt;               { # 128 Byte blks }
    OwnerNum: Integer;             { ULer OF file }
    OwnerName: STRING[36];         { ULer's name }
    Date: UnixTime;                { Date ULed }
    DateN: Word;                   { Numeric date ULed - 01/01/85 - 07/26/3061 = 0-65535 }
    VPointer: LongInt;             { Pointer to verbose descr, -1 if none }
    VTextSize: Integer;            { Verbose descr textsize - 50 Bytes x 99 Lines = 4950 max }
    OldFIFlags: OldFIFlagSet;      { File status }
  END;

function sqoutsp(s:string):string;
begin
  while (pos(' ',s)>0) do delete(s,pos(' ',s),1);
  sqoutsp:=s;
end;

function exist(fn: astr): boolean;
var
  srec: searchrec;
begin
  findfirst(sqoutsp(fn),anyfile,srec);
  exist := (doserror = 0);
end;

FUNCTION SYN(B: BOOLEAN): STRING;
BEGIN
  IF (B) THEN
    SYN := 'Yes'
  ELSE
    SYN := 'No ';
END;

FUNCTION YN: BOOLEAN;
VAR
  C: CHAR;
BEGIN
  Write(SQOutSp(SYN(DYNY)));
  REPEAT
    C := UpCase(Char(ReadKey));
  UNTIL (C IN ['Y','N',^M]);
  IF (DYNY) AND (C <> 'N') THEN
    C := 'Y';
  IF (DYNY) AND (C = 'N') THEN
    Write(#8#8#8'No ')
  ELSE IF (NOT DYNY) AND (C = 'Y') THEN
    Write(#8#8'Yes');
  WriteLn;
  YN := (C = 'Y');
  DYNY := FALSE;
end;

FUNCTION PYNQ(CONST S: AStr): BOOLEAN;
BEGIN
  Write(S);
  PYNQ := YN;
END;

FUNCTION Caps(s: STRING): STRING;
VAR
  Counter: Integer;  { must be Integer }
BEGIN
  IF (s[1] IN ['a'..'z']) THEN
    Dec(s[1],32);
  FOR Counter := 2 TO Length(s) DO
    IF (s[Counter - 1] IN ['a'..'z','A'..'Z']) THEN
      IF (s[Counter] IN ['A'..'Z']) THEN
        Inc(s[Counter],32)
      ELSE
    ELSE
      IF (s[Counter] IN ['a'..'z']) THEN
        Dec(s[Counter],32);
  Caps := s;
END;

FUNCTION IntToStr(L: LongInt): STRING;
VAR
  S: STRING[11];
BEGIN
  Str(L,S);
  IntToStr := S;
END;

PROCEDURE ReadDirFile(DirPath,FName: AStr);
VAR
  OldDirFile: FILE OF OldFileInfoRecordType;
  DirFile: FILE OF FileInfoRecordType;
  OldDir: OldFileInfoRecordType;
  Dir: FileInfoRecordType;
  RecNum: Integer;
BEGIN
  IF (Exist(DirPath+FName+'.DIR')) THEN
  BEGIN
    Assign(OldDirFile,DirPath+FName+'.DIR');
    Reset(OldDirFile);
    Assign(DirFile,DirPath+FName+'.NEW');
    ReWrite(DirFile);
    RecNum := 0;
    WHILE (RecNum <= (FileSize(OldDirFile) - 1)) DO
    BEGIN
      Seek(OldDirFile,RecNum);
      Read(OldDirFile,OldDir);
      WITH DIR DO
      BEGIN
        FileName := OldDir.FileName;
        Description := OldDir.Description;
        FilePoints := OldDir.FilePoints;
        Downloaded := OldDir.Downloaded;
        FileSize := ((OldDir.Blocks * 128) + OldDir.SizeMod);
        OwnerNum := OldDir.OwnerNum;
        OwnerName := OldDir.OwnerName;
        FileDate := OldDir.Date;
        VPointer := OldDir.VPointer;
        VTextSize := OldDir.VTextSize;
        FIFlags := [];
        IF (OldFINotVal IN OldDir.OldFIFlags) THEN
          Include(FIFlags,FINotVal);
        IF (OldFIIsRequest IN OldDir.OldFIFlags) THEN
          Include(FIFlags,FIIsRequest);
        IF (OldFIResumeLater IN OldDir.OldFIFlags) THEN
          Include(FIFlags,FIResumeLater);
        IF (OldFIHatched IN OldDir.OldFIFlags) THEN
          Include(FIFlags,FIHatched);
      END;
      Write(DirFile,Dir);
      Inc(RecNum);
    END;
    Close(OldDirFile);
    Close(DirFile);
    Assign(OlDDirFile,DirPath+FName+'.DIR');
    Erase(OlDDirFile);
    Assign(DirFile,DirPath+FName+'.NEW');
    ReName(DirFile,DirPath+FName+'.DIR');
  END;
END;

PROCEDURE ConvertFileInfoRec(General: GeneralRecordType);
VAR
  FileAreaFile: FILE OF FileAreaRecordType;
  FileArea: FileAreaRecordType;
  DirPath: STRING;
  Counter: Integer;
BEGIN
  Write('Converting "*.DIR" files ... ');
  Assign(FileAreaFile,General.DataPath+'FBASES.DAT');
  Reset(FileAreaFile);
  Counter := 0;
  WHILE (Counter <= (FileSize(FileAreaFile) - 1)) DO
  BEGIN
    Seek(FileAreaFile,Counter);
    Read(FileAreaFile,FileArea);
    WITH FileArea DO
    BEGIN
      IF (FADirDLPath IN FileArea.FAFlags) THEN
        DIRPath := FileArea.DLPath
      ELSE
        DIRPath := General.DataPath;
      ReadDirFile(DirPath,FileArea.FileName);
    END;
    Inc(Counter);
  END;
  Close(FileAreaFile);
  WriteLn('Done');
END;

VAR
  GeneralFile: FILE OF GeneralRecordType;
  General: GeneralRecordType;

BEGIN
  ClrScr;
  WriteLn('Renegade Update Utility (??.??/? to 10.01/8)');
  WriteLn;
  Writeln('This utility will upgrade your Renegade BBS from');
  WriteLn('Version ??.??/? to Version 10.01/8.');
  WriteLn;
  IF PYNQ('Do you wish to continue? ') THEN
  BEGIN
    WriteLn;
    Write('Reading "RENEGADE.DAT" file ... ');
    Assign(GeneralFile,'RENEGADE.DAT');
    Reset(GeneralFile);
    Read(GeneralFile,General);
    Close(GeneralFile);
    WriteLn('Done');
    WriteLn;
    ConvertFileInfoRec(General);
    WriteLn;
    WriteLn('Conversion complete!');
    WriteLn;
    WriteLn('Please replace your old RENEGADE.EXE/RENEGADE.OVR files');
    WriteLn('with the new files provided with this update.');
  END;
END.
