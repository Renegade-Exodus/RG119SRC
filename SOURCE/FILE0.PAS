{$IFDEF WIN32}
{$I DEFINES.INC}
{$ENDIF}

{$A+,B-,D+,E-,F+,I-,L+,N-,O+,R-,S+,V-}

UNIT File0;

INTERFACE

USES
  Common;

FUNCTION CompFileArea(FArea,ArrayNum: Integer): Integer;
FUNCTION GetCPS(TotalBytes,TransferTime: LongInt): LongInt;
PROCEDURE CountDown;
FUNCTION Align(CONST FName: Str12): Str12;
FUNCTION BadDownloadPath: Boolean;
FUNCTION BadUploadPath: Boolean;
PROCEDURE DisplayFileInfo(VAR F: FileInfoRecordType; Editing: Boolean);
FUNCTION FileAreaAC(FArea: Integer): Boolean;
PROCEDURE ChangeFileArea(FArea: Integer);
PROCEDURE LoadFileArea(FArea: Integer);
FUNCTION GetDirPath(MemFileArea: FileAreaRecordType): ASTR;
PROCEDURE LoadNewScanFile(VAR NewScanFile: Boolean);
PROCEDURE SaveNewScanFile(NewScanFile: Boolean);
PROCEDURE InitFileArea(FArea: Integer);
FUNCTION Fit(CONST FileName1,FileName2: Str12): Boolean;
PROCEDURE GetFileName(VAR FileName: Str12);
FUNCTION ISUL(CONST s: AStr): Boolean;
FUNCTION IsWildCard(CONST s: AStr): Boolean;
PROCEDURE NRecNo(FileInfo: FileInfoRecordType; VAR RN: Integer);
PROCEDURE LRecNo(Fileinfo: FileInfoRecordType; VAR RN: Integer);
PROCEDURE RecNo(FileInfo: FileInfoRecordType; FileName: Str12; VAR RN: Integer);
PROCEDURE LoadVerbArray(F: FileInfoRecordType; VAR ExtArray: ExtendedDescriptionArray; VAR NumExtDesc: Byte);
PROCEDURE SaveVerbArray(VAR F: FileInfoRecordType; ExtArray: ExtendedDescriptionArray; NumExtDesc: Byte);

IMPLEMENTATION

USES
  Dos,
  File1,
  ShortMsg,
  TimeFunc
{$IFDEF WIN32}
  ,Windows
{$ENDIF}
  ;

FUNCTION CompFileArea(FArea,ArrayNum: Integer): Integer;
VAR
  FileCompArrayFile: FILE OF CompArrayType;
  CompFileArray: CompArrayType;
BEGIN
  Assign(FileCompArrayFile,TempDir+'FACT'+IntToStr(ThisNode)+'.DAT');
  Reset(FileCompArrayFile);
  Seek(FileCompArrayFile,(FArea - 1));
  Read(FileCompArrayFile,CompFileArray);
  Close(FileCompArrayFile);
  CompFileArea := CompFileArray[ArrayNum];
END;

FUNCTION GetCPS(TotalBytes,TransferTime: LongInt): LongInt;
BEGIN
  IF (TransferTime > 0) THEN
    GetCPS := (TotalBytes DIV TransferTime)
  ELSE
    GetCPS := 0;
END;

(* Done - 01/01/07 Lee Palmer *)
FUNCTION Align(CONST FName: Str12): Str12;
VAR
  F: Str8;
  E: Str3;
  Counter,
  Counter1: Byte;
BEGIN
  Counter := Pos('.',FName);
  IF (Counter = 0) THEN
  BEGIN
    F := FName;
    E := '   ';
  END
  ELSE
  BEGIN
    F := Copy(FName,1,(Counter - 1));
    E := Copy(FName,(Counter + 1),3);
  END;
  F := PadLeftStr(F,8);
  E := PadLeftStr(E,3);
  Counter := Pos('*',F);
  IF (Counter <> 0) THEN
    FOR Counter1 := Counter TO 8 DO
      F[Counter1] := '?';
  Counter := Pos('*',E);
  IF (Counter <> 0) THEN
    FOR Counter1 := Counter TO 3 DO
      E[Counter1] := '?';
  Counter := Pos(' ',F);
  IF (Counter <> 0) THEN
    FOR Counter1 := Counter TO 8 DO
      F[Counter1] := ' ';
  Counter := Pos(' ',E);
    IF (Counter <> 0) THEN
      FOR Counter1 := Counter TO 3 DO
        E[Counter1] := ' ';
  Align := F+'.'+E;
END;

FUNCTION BadDownloadPath: Boolean;
BEGIN
  IF (BadDLPath) THEN
  BEGIN
    NL;
    Print('^7File area #'+IntToStr(FileArea)+': Unable to perform command.');
    SysOpLog('^5Bad DL file path: "'+MemFileArea.DLPath+'".');
    Print('^5Please inform the SysOp.');
    SysOpLog('Invalid DL path (File Area #'+IntToStr(FileArea)+'): "'+MemFileArea.DLPath+'"');
  END;
  BadDownloadPath := BadDLPath;
END;

FUNCTION BadUploadPath: Boolean;
BEGIN
  IF (BadULPath) THEN
  BEGIN
    NL;
    Print('^7File area #'+IntToStr(FileArea)+': Unable to perform command.');
    SysOpLog('^5Bad UL file path: "'+MemFileArea.Ulpath+'".');
    Print('^5Please inform the SysOp.');
    SysOpLog('Invalid UL path (File Area #'+IntToStr(FileArea)+'): "'+MemFileArea.Ulpath+'"');
  END;
  BadUploadPath := BadULPath;
END;

FUNCTION FileAreaAC(FArea: Integer): Boolean;
BEGIN
  FileAreaAC := FALSE;
  IF (FArea < 1) OR (FArea > NumFileAreas) THEN
    Exit;
  LoadFileArea(FArea);
  FileAreaAC := AACS(MemFileArea.ACS);
END;

PROCEDURE ChangeFileArea(FArea: Integer);
VAR
  PW: Str20;
BEGIN
  IF (FArea < 1) OR (FArea > NumFileAreas) OR (NOT FileAreaAC(FArea)) THEN
    Exit;
  IF (MemFileArea.Password <> '') AND (NOT SortFilesOnly) THEN
  BEGIN
    NL;
    Print('File area: ^5'+MemFileArea.AreaName+' #'+IntToStr(CompFileArea(FArea,0))+'^1');
    NL;
    Prt('Password: ');
    GetPassword(PW,20);
    IF (PW <> MemFileArea.Password) THEN
    BEGIN
      NL;
      Print('^7Incorrect password!^1');
      Exit;
    END;
  END;
  FileArea := FArea;
  ThisUser.LastFileArea := FileArea;
END;

PROCEDURE LoadFileArea(FArea: Integer);
VAR
  FO: Boolean;
BEGIN
  IF (ReadFileArea = FArea) THEN
    Exit;
  IF (FArea < 1) THEN
    Exit;
  IF (FArea > NumFileAreas) THEN
  BEGIN
    MemFileArea := TempMemFileArea;
    ReadFileArea := FArea;
    Exit;
  END;
  FO := (FileRec(FileAreaFile).Mode <> FMClosed);
  IF (NOT FO) THEN
  BEGIN
    Reset(FileAreaFile);
    LastError := IOResult;
    IF (LastError > 0) THEN
    BEGIN
      SysOpLog('FBASES.DAT/Open Error - '+IntToStr(LastError)+' (Procedure: LoadFileArea - '+IntToStr(FArea)+')');
      Exit;
    END;
  END;
  Seek(FileAreaFile,(FArea - 1));
  LastError := IOResult;
  IF (LastError > 0) THEN
  BEGIN
    SysOpLog('FBASES.DAT/Seek Error - '+IntToStr(LastError)+' (Procedure: LoadFileArea - '+IntToStr(FArea)+')');
    Exit;
  END;
  Read(FileAreaFile,MemFileArea);
  LastError := IOResult;
  IF (LastError > 0) THEN
  BEGIN
    SysOpLog('FBASES.DAT/Read Error - '+IntToStr(LastError)+' (Procedure: LoadFileArea - '+IntToStr(FArea)+')');
    Exit;
  END
  ELSE
    ReadFileArea := FArea;
  IF (NOT FO) THEN
  BEGIN
    Close(FileAreaFile);
    LastError := IOResult;
    IF (LastError > 0) THEN
    BEGIN
      SysOpLog('FBASES.DAT/Close Error - '+IntToStr(LastError)+' (Procedure: LoadFileArea - '+IntToStr(FArea)+')');
      Exit;
    END;
  END;
  LastError := IOResult;
END;

FUNCTION GetDirPath(MemFileArea: FileAreaRecordType): AStr;
BEGIN
  IF (FADirDLPath IN MemFileArea.FAFlags) THEN
    GetDirPath := MemFileArea.DLPath+MemFileArea.FileName
  ELSE
    GetDirPath := General.DataPath+MemFileArea.FileName;
END;

PROCEDURE LoadNewScanFile(VAR NewScanFile: Boolean);
VAR
  FileAreaScanFile: FILE OF Boolean;
  Counter: Integer;
BEGIN
  Assign(FileAreaScanFile,GetDirPath(MemFileArea)+'.SCN');
  Reset(FileAreaScanFile);
  IF (IOResult = 2) THEN
    ReWrite(FileAreaScanFile);
  IF (UserNum > FileSize(FileAreaScanFile)) THEN
  BEGIN
    NewScanFile := TRUE;
    Seek(FileAreaScanFile,FileSize(FileAreaScanFile));
    FOR Counter := FileSize(FileAreaScanFile) TO (UserNum - 1) DO
      Write(FileAreaScanFile,NewScanFile);
  END
  ELSE
  BEGIN
    Seek(FileAreaScanFile,(UserNum - 1));
    Read(FileAreaScanFile,NewScanFile);
  END;
  Close(FileAreaScanFile);
  LastError := IOResult;
END;

PROCEDURE SaveNewScanFile(NewScanFile: Boolean);
VAR
  FileAreaScanFile: FILE OF Boolean;
BEGIN
  Assign(FileAreaScanFile,GetDirPath(MemFileArea)+'.SCN');
  Reset(FileAreaScanFile);
  Seek(FileAreaScanFile,(UserNum - 1));
  Write(FileAreaScanFile,NewScanFile);
  Close(FileAreaScanFile);
  LastError := IOResult;
END;

PROCEDURE InitFileArea(FArea: Integer);
BEGIN
  LoadFileArea(FArea);

  IF ((Length(MemFileArea.DLPath) = 3) AND (MemFileArea.DLPath[2] = ':') AND (MemFileArea.DLPath[3] = '\')) THEN
    BadDLPath := NOT ExistDrive(MemFileArea.DLPath[1])
  ELSE IF NOT (FACDRom IN MemFileArea.FAFlags) THEN
    BadDLPath := NOT ExistDir(MemFileArea.DLPath)
  ELSE
    BadDLPath := FALSE;

  IF ((Length(MemFileArea.ULPath) = 3) AND (MemFileArea.ULPath[2] = ':') AND (MemFileArea.DLPath[3] = '\')) THEN
    BadULPath := NOT ExistDrive(MemFileArea.ULPath[1])
  ELSE IF NOT (FACDRom IN MemFileArea.FAFlags) THEN
    BadULPath := NOT ExistDir(MemFileArea.ULPath)
  ELSE
    BadULPath := FALSE;

  IF (NOT DirFileOpen1) THEN
    IF (FileRec(FileInfoFile).Mode <> FMClosed) THEN
      Close(FileInfoFile);
  DirFileOpen1 := FALSE;

  Assign(FileInfoFile,GetDirPath(MemFileArea)+'.DIR');
  Reset(FileInfoFile);
  IF (IOResult = 2) THEN
    ReWrite(FileInfoFile);
  IF (IOResult <> 0) THEN
  BEGIN
    SysOpLog('Error opening file: '+GetDirPath(MemFileArea)+'.DIR');
    Exit;
  END;

  IF (NOT ExtFileOpen1) THEN
    IF (FileRec(ExtInfoFile).Mode <> FMClosed) THEN
      Close(ExtInfoFile);
  ExtFileOpen1 := FALSE;

  Assign(ExtInfoFile,GetDirPath(MemFileArea)+'.EXT');
  Reset(ExtInfoFile,1);
  IF (IOResult = 2) THEN
    ReWrite(ExtInfoFile,1);
  IF (IOResult <> 0) THEN
  BEGIN
    SysOpLog('Error opening file: '+GetDirPath(MemFileArea)+'.EXT');
    Exit;
  END;

  LoadNewScanFile(NewScanFileArea);

  FileAreaNameDisplayed := FALSE;
END;

PROCEDURE DisplayFileInfo(VAR F: FileInfoRecordType; Editing: Boolean);
VAR
  TempStr: AStr;
  Counter,
  NumLine,
  NumExtDesc: Byte;

  FUNCTION DisplayFIStr(FIFlags: FIFlagSet): AStr;
  VAR
    TempStr1: AStr;
  BEGIN
    TempStr1 := '';
    IF (FINotVal IN FIFlags) THEN
      TempStr1 := TempStr1 + ' ^8'+'<NV>';
    IF (FIIsRequest IN FIFlags) THEN
      TempStr1 := TempStr1 + ' ^9'+'Ask (Request File)';
    IF (FIResumeLater IN FIFlags) THEN
      TempStr1 := TempStr1 + ' ^7'+'Resume later';
    IF (FIHatched IN FIFlags) THEN
      TempStr1 := TempStr1 + ' ^7'+'Hatched';
    DisplayFIStr := TempStr1;
  END;

BEGIN
  Counter := 1;
  WHILE (Counter <= 7) AND (NOT Abort) AND (NOT HangUp) DO
  BEGIN
    WITH F DO
    BEGIN
      IF (Editing) THEN
        TempStr := IntToStr(Counter)+'. '
      ELSE
        TempStr := '';
      CASE Counter OF
        1 : TempStr := TempStr + 'Filename         : ^0'+SQOutSp(FileName);
        2 : IF (NOT General.FileCreditRatio) THEN
              TempStr := TempStr + 'File size        : ^2'+ConvertBytes(FileSize,FALSE)
            ELSE
              TempStr := TempStr + 'File size        : ^2'+ConvertKB(FileSize DIV 1024,FALSE);
        3 : BEGIN
              TempStr := TempStr + 'Description      : ^9'+Description;
              PrintACR('^1'+TempStr);
              IF (F.VPointer <> -1) THEN
              BEGIN
                LoadVerbArray(F,ExtendedArray,NumExtDesc);
                NumLine := 1;
                WHILE (NumLine <= NumExtDesc) AND (NOT Abort) AND (NOT HangUp) DO
                BEGIN
                  PrintACR('^1'+AOnOff(Editing,PadLeftStr('',3),'')
                           +AOnOff(Editing AND (NumLine = 1),PadLeftStr('Extended',13),PadLeftStr('',13))
                           +AOnOff(Editing,PadRightInt(NumLine,3),PadRightStr('',3))
                           +' : ^9'+ExtendedArray[NumLine]);
                  Inc(NumLine);
                END;
              END;
              IF (Editing) THEN
                IF (F.VPointer = -1) THEN
                  PrintACR('^5   No extended description.');
            END;
        4 : TempStr := TempStr + 'Uploaded by      : ^4'+Caps(OwnerName);
        5 : TempStr := TempStr + 'Uploaded on      : ^5'+PD2Date(FileDate);
        6 : BEGIN
              TempStr := TempStr + 'Times downloaded : ^5'+FormatNumber(Downloaded);
              PrintACR('^1'+TempStr);
              IF (NOT Editing) THEN
              BEGIN
                TempStr := 'Block size       : 128-"^5'+IntToStr(FileSize DIV 128)+
                                               '^1" / 1024-"^5'+IntToStr(FileSize DIV 1024)+'^1"';
                PrintACR('^1'+TempStr);
                TempStr := 'Time to download : ^5'+CTim(FileSize DIV Rate);
                PrintACR('^1'+TempStr);
              END;
            END;
        7 : TempStr := TempStr + 'File point cost  : ^4'+AOnOff((FilePoints > 0),FormatNumber(FilePoints),'FREE')+
                                 DisplayFIStr(FIFlags);
      END;
      IF (NOT (Counter IN [3,6])) THEN
        PrintACR('^1'+TempStr+'^1');
    END;
    Inc(Counter);
  END;
END;

FUNCTION Fit(CONST FileName1,FileName2: Str12): Boolean;
VAR
  Counter: Byte;
  Match: Boolean;
BEGIN
  Match := TRUE;
  FOR Counter := 1 TO 12 DO
    IF (FileName1[Counter] <> FileName2[Counter]) AND (FileName1[Counter] <> '?') THEN
      Match := FALSE;
  IF (FileName2 = '') THEN
    Match := FALSE;
  Fit := Match;
END;

PROCEDURE GetFileName(VAR FileName: Str12);
BEGIN
  MPL(12);
  InputMain(FileName,12,[NoLineFeed,UpperOnly]);
  IF (FileName <> '') THEN
    NL
  ELSE
  BEGIN
    MPL(12);
    FileName := '*.*';
    Print(FileName);
  END;
  FileName := Align(FileName);
END;

FUNCTION ISUL(CONST s: AStr): Boolean;
BEGIN
  ISUL := ((Pos('/',s) <> 0) OR (Pos('\',s) <> 0) OR (Pos(':',s) <> 0) OR (Pos('|',s) <> 0));
END;

FUNCTION IsWildCard(CONST S: AStr): Boolean;
BEGIN
  IsWildCard := ((Pos('*',S) <> 0) OR (Pos('?',S) <> 0));
END;

PROCEDURE LRecNo(FileInfo: FileInfoRecordType; VAR RN: Integer);
VAR
  DirFileRecNum: Integer;
BEGIN
  RN := 0;
  IF (LastDIRRecNum <= FileSize(FileInfoFile)) AND (LastDIRRecNum >= 0) THEN
  BEGIN
    DirFileRecNum := (LastDIRRecNum - 1);
    WHILE (DirFileRecNum >= 0) AND (RN = 0) DO
    BEGIN
      Seek(FileInfoFile,DirFileRecNum);
      Read(FileInfoFile,FileInfo);
      IF Fit(LastDIRFileName,FileInfo.FileName) THEN
        RN := DirFileRecNum;
      Dec(DirFileRecNum);
    END;
    LastDIRRecNum := RN;
  END
  ELSE
    RN := -1;
  LastError := IOResult;
END;

PROCEDURE NRecNo(FileInfo: FileInfoRecordType; VAR RN: Integer);
VAR
  DirFileRecNum: Integer;
BEGIN
  RN := 0;
  IF (LastDIRRecNum < FileSize(FileInfoFile)) AND (LastDIRRecNum >= -1) THEN
  BEGIN
    DirFileRecNum := (LastDIRRecNum + 1);
    WHILE (DirFileRecNum < FileSize(FileInfoFile)) AND (RN = 0) DO
    BEGIN
      Seek(FileInfoFile,DirFileRecNum);
      Read(FileInfoFile,FileInfo);
      IF Fit(LastDIRFileName,FileInfo.FileName) THEN
        RN := (DirFileRecNum + 1);
      Inc(DirFileRecNum);
    END;
    Dec(RN);
    LastDIRRecNum := RN;
  END
  ELSE
    RN := -1;
  LastError := IOResult;
END;

PROCEDURE RecNo(FileInfo: FileInfoRecordType; FileName: Str12; VAR RN: Integer);
VAR
  DirFileRecNum: Integer;
BEGIN
  InitFileArea(FileArea);
  FileName := Align(FileName);
  RN := 0;
  DirFileRecNum := 0;
  WHILE (DirFileRecNum < FileSize(FileInfoFile)) AND (RN = 0) DO
  BEGIN
    Seek(FileInfoFile,DirFileRecNum);
    Read(FileInfoFile,FileInfo);
    IF Fit(FileName,FileInfo.FileName) THEN
      RN := (DirFileRecNum + 1);
    Inc(DirFileRecNum);
  END;
  Dec(RN);
  LastDIRRecNum := RN;
  LastDIRFileName := FileName;
  LastError := IOResult;
END;

PROCEDURE LoadVerbArray(F: FileInfoRecordType; VAR ExtArray: ExtendedDescriptionArray; VAR NumExtDesc: Byte);
VAR
  VerbStr: AStr;
  TotLoad: Integer;
  VFO: Boolean;
BEGIN
  FillChar(ExtArray,SizeOf(ExtArray),0);
  NumExtDesc := 1;
  VFO := (FileRec(ExtInfoFile).Mode <> FMClosed);
  IF (NOT VFO) THEN
    Reset(ExtInfoFile,1);
  IF (IOResult = 0) THEN
  BEGIN
    TotLoad := 0;
    Seek(ExtInfoFile,(F.VPointer - 1));
    REPEAT
      BlockRead(ExtInfoFile,VerbStr[0],1);
      BlockRead(ExtInfoFile,VerbStr[1],Ord(VerbStr[0]));
      Inc(TotLoad,(Length(VerbStr) + 1));
      ExtArray[NumExtDesc] := VerbStr;
      Inc(NumExtDesc);
    UNTIL (TotLoad >= F.VTextSize);
    IF (NOT VFO) THEN
      Close(ExtInfoFile);
  END;
  Dec(NumExtDesc);
  LastError := IOResult;
END;

PROCEDURE SaveVerbArray(VAR F: FileInfoRecordType; ExtArray: ExtendedDescriptionArray; NumExtDesc: Byte);
VAR
  LineNum: Byte;
  VFO: Boolean;
BEGIN
  VFO := (FileRec(ExtInfoFile).Mode <> FMClosed);
  IF (NOT VFO) THEN
    Reset(ExtInfoFile,1);
  IF (IOResult = 0) THEN
  BEGIN
    F.VPointer := (FileSize(ExtInfoFile) + 1);
    F.VTextSize := 0;
    Seek(ExtInfoFile,FileSize(ExtInfoFile));
    FOR LineNum := 1 TO NumExtDesc DO
      IF (ExtArray[LineNum] <> '') THEN
      BEGIN
        Inc(F.VTextSize,(Length(ExtArray[LineNum]) + 1));
        BlockWrite(ExtInfoFile,ExtArray[LineNum],(Length(ExtArray[LineNum]) + 1));
      END;
    IF (NOT VFO) THEN
      Close(ExtInfoFile);
  END;
  LastError := IOResult;
END;

PROCEDURE CountDown;
VAR
  Cmd: Char;
  Counter: Byte;
  SaveTimer: LongInt;
BEGIN
  NL;
  Print('Press <^5CR^1> to logoff now.');
  Print('Press <^5Esc^1> to abort logoff.');
  NL;
  Prompt('|12Hanging up in: ^99');
  SaveTimer := Timer;
  Cmd := #0;
  Counter := 9;
  WHILE (Counter > 0) AND NOT (Cmd IN [#13,#27]) AND (NOT HangUp) DO
  BEGIN
    IF (NOT Empty) THEN
      Cmd := Char(InKey);
    IF (Timer <> SaveTimer) THEN
    BEGIN
      Dec(Counter);
      Prompt(^H+IntToStr(Counter));
      SaveTimer := Timer;
    END
    ELSE
{$IFDEF MSDOS}
      ASM
        Int 28h
      END;
{$ENDIF}
{$IFDEF WIN32}
      Sleep(1);
{$ENDIF}
  END;
  IF (Cmd <> #27) THEN
  BEGIN
    HangUp := TRUE;
    OutCom := FALSE;
  END;
  UserColor(1);
END;

END.
