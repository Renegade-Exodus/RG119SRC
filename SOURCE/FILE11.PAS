{$IFDEF WIN32}
{$I DEFINES.INC}
{$ENDIF}

{$A+,B-,D+,E-,F+,I-,L+,N-,O+,R-,S+,V-}

UNIT File11;

INTERFACE

USES
  Common;

TYPE
  FileRecType = RECORD
    FArrayFileArea,
    FArrayDirFileRecNum: SmallInt;
  END;

  FileArrayType = ARRAY [0..99] OF FileRecType;

VAR
  FArray: FileArrayType;

FUNCTION CanSee(CONST FileInfo: FileInfoRecordType): Boolean;
FUNCTION GetFileStats(FileInfo: FileInfoRecordType): AStr;
PROCEDURE InitFArray(VAR F: FileArrayType);
PROCEDURE DisplayFileAreaHeader;
PROCEDURE lDisplay_File(FileInfo: FileInfoRecordType; FArrayRecNum: Byte; SearchString: Str20;
                        NormalPause: Boolean);
PROCEDURE SearchFileSpec;
PROCEDURE ListFileSpec(FName: Str12);
PROCEDURE SearchFileDescriptions;
PROCEDURE GlobalNewFileScan(VAR FArrayRecNum: Byte);
PROCEDURE NewFilesScanSearchType(CONST MenuOption: Str50);
PROCEDURE FileAreaChange(VAR Done: Boolean; CONST MenuOption: Str50);
PROCEDURE CreateTempDir;

IMPLEMENTATION

USES
  Dos,
  Crt,
  ArcView,
  Common5,
  File0,
  File1,
  File10,
  Menus,
  TimeFunc;

TYPE
  DownLoadArrayType = ARRAY [0..99] OF SmallInt;

VAR
  DLArray: DownloadArrayType;
  Lines,
  FileRedisplayLines: Byte;

PROCEDURE InitFArray(VAR F: FileArrayType);
VAR
  Counter: Byte;
BEGIN
  FOR Counter := 0 TO 99 DO
    WITH F[Counter] DO
    BEGIN
      FArrayFileArea := -1;
      FArrayDirFileRecNum := -1;
    END;
END;

FUNCTION GetDlArray(VAR DLArray: DownLoadArrayType; CmdLen: Byte): Boolean;
VAR
  s,
  s1,
  s2: Str160;
  Counter,
  Counter1,
  Counter2,
  Counter3: Byte;
  Ok: Boolean;
BEGIN
  Ok := TRUE;
  FOR Counter := 1 TO (((LennMCI(MemMenu.MenuPrompt) + CmdLen) + 1)) DO
    BackSpace;
  FOR Counter := 0 TO 99 DO
    DLArray[Counter] := -1;
  Prt('Enter file number or range (##,##-##): ');
  s := '';
  MPL(20);
  InputMain(s,20,[NoLineFeed]);
  IF (SqOutSp(S) = '') THEN
    OK := FALSE
  ELSE
  BEGIN
    FOR Counter := 1 TO Length(S) DO
      IF (NOT (S[Counter] IN ['0'..'9','-'])) THEN
        Ok := FALSE;
    IF (S = '-') OR (S[1] = '-') OR (S[Length(s)] = '-') THEN
      OK := FALSE;
    IF (Ok) THEN
    BEGIN
      NL;
      s1 := '';
      s2 := '';
      Counter1 := 0;
      FOR Counter := 1 TO Length(s) DO
      BEGIN
        IF s[Counter] IN ['0'..'9'] THEN
          s1 := s1 + s[Counter]
        ELSE
        BEGIN
          IF (s[Counter] = '-') THEN
          BEGIN
            s2 := '';
            FOR Counter2 := (Counter + 1) TO Length(s) DO
            BEGIN
              IF (s[counter2] IN ['0'..'9']) THEN
                s2 := s2 + s[counter2]
              ELSE
              BEGIN
                IF (s1 <> '') AND (StrToInt(s1) >= 0) AND (StrToInt(s1) <= 99) AND
                   (S2 <> '') AND (StrToInt(s2) >= 0) AND (StrToInt(s2) <= 99) THEN
                  FOR Counter3 := StrToInt(s1) TO StrToInt(s2) DO
                  BEGIN
                    DLArray[Counter1] := Counter3;
                    Inc(Counter1);
                  END;
                s1 := '';
                Counter := Counter + Length(s2);
                s2 := '';
                Counter2 := Length(s);
              END;
            END;
            Counter := Counter + Length(s2);
          END
          ELSE IF (StrToInt(s1) >= 0) AND (StrToInt(s1) <= 99) THEN
          BEGIN
            DLArray[Counter1] := StrToInt(s1);
            Inc(Counter1);
            s1 := '';
            s2 := '';
          END;
        END;
      END;
      IF (Length(s1) <> 0) AND (StrToInt(s1) >= 0) AND (StrToInt(s1) <= 99) THEN
        DLArray[Counter1] := StrToInt(s1);
      IF (s1 <> '') AND (StrToInt(s1) >= 0) AND (StrToInt(s1) <= 99) AND
         (S2 <> '') AND (StrToInt(s2) >= 0) AND (StrToInt(s2) <= 99) THEN
        FOR Counter3 := StrToInt(s1) TO StrToInt(s2) DO
        BEGIN
          DLArray[Counter1] := Counter3;
          Inc(Counter1)
        END;
    END;
  END;
  IF (NOT OK) THEN
  BEGIN
    FOR Counter := 1 TO 20 DO
      OutKey(' ');
    UserColor(1);
    FOR Counter := 1 TO (LennMCI(MemMenu.MenuPrompt) + 21) DO
      BackSpace;
  END;

  GetDLArray := OK;
END;

PROCEDURE Pause_Files;
VAR
  TransferFlags: TransferFlagSet;
  CmdStr,
  NewMenuCmd: AStr;
  SaveLastDirFileName: Str12;
  Cmd: Char;
  SaveMenu,
  Counter,
  CmdToExec: Byte;
  Counter1,
  SaveFileArea,
  SaveLastDirFileRecNum: Integer;
  Done,
  CmdNotHid,
  CmdExists,
  FO: Boolean;
BEGIN
  LIL := 0;
  IF (Lines < PageLength) OR (HangUp) THEN
    Exit;
  Lines := 0;
  FileRedisplayLines := 0;
  FileAreaNameDisplayed := FALSE;

  SaveMenu := CurMenu;
  CurMenu := General.FileListingMenu;
  IF (NOT NewMenuToLoad) THEN
    LoadMenuPW;
  AutoExecCmd('FIRSTCMD');
  REPEAT
    MainMenuHandle(CmdStr);
    NewMenuCmd := '';
    CmdToExec := 0;
    TFilePrompt := 0;
    Done := FALSE;
    REPEAT
      FCmd(CmdStr,CmdToExec,CmdExists,CmdNotHid);
      IF (CmdToExec <> 0) AND (MemCmd^[CmdToExec].CmdKeys <> '-^') AND
         (MemCmd^[CmdToExec].CmdKeys <> '-/') AND (MemCmd^[CmdToExec].CmdKeys <> '-\') THEN
      BEGIN
        IF (CmdStr <> '') AND (CmdStr <> 'ENTER') AND (MemCmd^[CmdToExec].CmdKeys <> 'L5') AND
           (MemCmd^[CmdToExec].CmdKeys <> 'L6') AND (MemCmd^[CmdToExec].CmdKeys <> 'L7') AND
           (MemCmd^[CmdToExec].CmdKeys <> 'L8') THEN
          NL;
        DoMenuCommand(Done,
                      MemCmd^[CmdToExec].CmdKeys,
                      MemCmd^[CmdToExec].Options,
                      NewMenuCmd,
                      MemCmd^[CmdToExec].NodeActivityDesc);
      END;
    UNTIL (CmdToExec = 0) OR (Done) OR (HangUp);
    Abort := FALSE;
    Next := FALSE;
    CASE TFilePrompt OF
      1 : ;
      2 : BEGIN
            Print('%LFListing aborted.');
            Abort := TRUE;
          END;
      3 : BEGIN
            Print('%LFFile area skipped.');
            Next  := TRUE;
          END;
      4 : BEGIN
            Print('%LF^5'+MemFileArea.AreaName+'^3 '+AOnOff(NewScanFileArea,'will NOT','WILL')+
                  ' be scanned.');
            LoadNewScanFile(NewScanFileArea);
            NewScanFileArea := (NOT NewScanFileArea);
            SaveNewScanFile(NewScanFileArea);
          END;
      5 : BEGIN
            IF GetDLArray(DLArray,Length(CmdStr)) THEN
              IF (DLInTime) THEN
                IF (NOT BatchDLQueuedFiles([])) THEN
                BEGIN
                  Counter := 0;
                  WHILE (Counter <= 99) AND (NOT Abort) AND (NOT HangUp) DO
                  BEGIN
                    IF (DLArray[Counter] <> -1) THEN
                      IF (FArray[DLArray[Counter]].FArrayDirFileRecNum = -1) THEN
                        Print('%LF^7Invalid file number selected: "^9'+IntToStr(DLArray[Counter])+'^7".')
                      ELSE
                      BEGIN
                        SaveLastDirFileRecNum := LastDIRRecNum;
                        SaveLastDirFileName := LastDIRFileName;
                        FO := (FileRec(FileInfoFile).Mode <> FMClosed);
                        IF (FO) THEN
                        BEGIN
                          Close(FileInfoFile);
                          Close(ExtInfoFile);
                        END;
                        SaveFileArea := FileArea;
                        FileArea := FArray[DLArray[Counter]].FArrayFileArea;
                        InitFileArea(FileArea);
                        Seek(FileInfoFile,FArray[DLArray[Counter]].FArrayDirFileRecNum);
                        Read(FileInfoFile,FileInfo);
                        TransferFlags := [IsCheckRatio];
                        DLX(FileInfo,FArray[DLArray[Counter]].FArrayDirFileRecNum,TransferFlags);
                        IF (IsKeyboardAbort IN TransferFlags) THEN
                          Abort := TRUE;
                        Close(FileInfoFile);
                        Close(ExtInfoFile);
                        FileArea := SaveFileArea;
                        IF (FO) THEN
                          InitFileArea(FileArea);
                        LastDIRRecNum := SaveLastDirFileRecNum;
                        LastDIRFileName := SaveLastDirFileName;
                      END;
                    Inc(Counter);
                  END;
                  IF (Abort) THEN
                    Abort := FALSE;
                  NL;
                END;
          END;
      6 : BEGIN
            IF GetDLArray(DLArray,Length(CmdStr)) THEN
              IF (DLInTime) THEN
              BEGIN
                Counter := 0;
                WHILE (Counter <= 99) AND (NOT Abort) AND (NOT HangUp) DO
                BEGIN
                  IF (DLArray[Counter] <> -1) THEN
                    IF (FArray[DLArray[Counter]].FArrayDirFileRecNum = -1) THEN
                      Print('%LF^7Invalid file number selected: "^9'+IntToStr(DLArray[Counter])+'^7".')
                    ELSE
                    BEGIN
                      SaveLastDirFileRecNum := LastDIRRecNum;
                      SaveLastDirFileName := LastDIRFileName;
                      FO := (FileRec(FileInfoFile).Mode <> FMClosed);
                      IF (FO) THEN
                      BEGIN
                        Close(FileInfoFile);
                        Close(ExtInfoFile);
                      END;
                      SaveFileArea := FileArea;
                      FileArea := FArray[DLArray[Counter]].FArrayFileArea;
                      InitFileArea(FileArea);
                      Seek(FileInfoFile,FArray[DLArray[Counter]].FArrayDirFileRecNum);
                      Read(FileInfoFile,FileInfo);
                      TransferFlags := [IsCheckRatio,lIsAddDLBatch];
                      DLX(FileInfo,FArray[DLArray[Counter]].FArrayDirFileRecNum,TransferFlags);
                      IF (IsKeyboardAbort IN TransferFlags) THEN
                        Abort := TRUE;
                      Close(FileInfoFile);
                      Close(ExtInfoFile);
                      FileArea := SaveFileArea;
                      IF (FO) THEN
                        InitFileArea(FileArea);
                      LastDIRRecNum := SaveLastDirFileRecNum;
                      LastDIRFileName := SaveLastDirFileName;
                    END;
                  Inc(Counter);
                END;
                IF (Abort) THEN
                  Abort := FALSE;
                NL;
              END;
          END;
      7 : BEGIN
            IF GetDLArray(DLArray,Length(CmdStr)) THEN
            BEGIN
              Counter := 0;
              WHILE (Counter <= 99) AND (NOT Abort) AND (NOT HangUp) DO
              BEGIN
                IF (DLArray[Counter] <> -1) THEN
                  IF (FArray[DLArray[Counter]].FArrayDirFileRecNum = -1) THEN
                    Print('%LF^7Invalid file number selected: "^9'+IntToStr(DLArray[Counter])+'^7".')
                  ELSE
                  BEGIN
                    SaveLastDirFileRecNum := LastDIRRecNum;
                    SaveLastDirFileName := LastDIRFileName;
                    FO := (FileRec(FileInfoFile).Mode <> FMClosed);
                    IF (FO) THEN
                    BEGIN
                      Close(FileInfoFile);
                      Close(ExtInfoFile);
                    END;
                    SaveFileArea := FileArea;
                    FileArea := FArray[DLArray[Counter]].FArrayFileArea;
                    InitFileArea(FileArea);
                    Seek(FileInfoFile,FArray[DLArray[Counter]].FArrayDirFileRecNum);
                    Read(FileInfoFile,FileInfo);
                    IF (NOT ValidIntArcType(FileInfo.FileName)) THEN
                      Print('%LF'+SQOutSp(FileInfo.FileName)+' is not a valid archive type or not supported.')
                    ELSE
                    BEGIN
                      IF Exist(MemFileArea.DLPath+FileInfo.FileName) THEN
                        ViewInternalArchive(MemFileArea.DLPath+SQOutSp(FileInfo.FileName))
                      ELSE IF Exist(MemFileArea.ULPath+FileInfo.FileName) THEN
                        ViewInternalArchive(MemFileArea.ULPath+SQOutSp(FileInfo.FileName));
                    END;
                    Close(FileInfoFile);
                    Close(ExtInfoFile);
                    FileArea := SaveFileArea;
                    IF (FO) THEN
                      InitFileArea(FileArea);
                    LastDIRRecNum := SaveLastDirFileRecNum;
                    LastDIRFileName := SaveLastDirFileName;
                  END;
                Inc(Counter);
              END;
              IF (Abort) THEN
                Abort := FALSE;
              NL;
            END;
          END;
      8 : IF (NOT FileSysop) THEN
          BEGIN
            NL;
            Print('%LFYou do not have the required access level for this option.');
            NL;
          END
          ELSE
          BEGIN
            IF GetDLArray(DLArray,Length(CmdStr)) THEN
            BEGIN
              Counter := 0;
              WHILE (Counter <= 99) AND (NOT Abort) AND (NOT HangUp) DO
              BEGIN
                IF (DLArray[Counter] <> -1) THEN
                  IF (FArray[DLArray[Counter]].FArrayDirFileRecNum = -1) THEN
                    Print('%LF^7Invalid file number selected: "^9'+IntToStr(DLArray[Counter])+'^7".')
                  ELSE
                  BEGIN
                    SaveLastDirFileRecNum := LastDIRRecNum;
                    SaveLastDirFileName := LastDIRFileName;
                    FO := (FileRec(FileInfoFile).Mode <> FMClosed);
                    IF (FO) THEN
                    BEGIN
                      Close(FileInfoFile);
                      Close(ExtInfoFile);
                    END;
                    SaveFileArea := FileArea;
                    FileArea := FArray[DLArray[Counter]].FArrayFileArea;
                    InitFileArea(FileArea);
                    Seek(FileInfoFile,FArray[DLArray[Counter]].FArrayDirFileRecNum);
                    Read(FileInfoFile,FileInfo);
                    EditFile(FArray[DLArray[Counter]].FArrayDirFileRecNum,Cmd,FALSE,FALSE);
                    IF (Cmd = 'Q') THEN
                      Abort := TRUE
                    ELSE IF (Cmd = 'P') THEN
                    BEGIN
                      Counter1 := Counter;
                      IF (Counter1 > 0) THEN
                      BEGIN
                        IF (DLArray[Counter1] <> -1) THEN
                          IF (FArray[DLArray[Counter1]].FArrayDirFileRecNum <> -1) THEN
                            Counter := (Counter1 - 1);
                        Dec(Counter1);
                      END;
                      Dec(Counter);
                    END;
                    Close(FileInfoFile);
                    Close(ExtInfoFile);
                    FileArea := SaveFileArea;
                    IF (FO) THEN
                      InitFileArea(FileArea);
                    LastDIRRecNum := SaveLastDirFileRecNum;
                    LastDIRFileName := SaveLastDirFileName;
                  END;
                Inc(Counter);
              END;
              IF (Abort) THEN
                Abort := FALSE;
              IF (Next) THEN
                Next := FALSE;
              IF (Cmd <> 'Q') THEN
                NL;
            END;
          END;
    END;
  UNTIL (TFilePrompt = 1) OR (Abort) OR (Next) OR (HangUp);
  IF (TFilePrompt = 1) AND (NOT Abort) AND (NOT Next) AND (NOT HangUp) THEN
    NL;
  CurMenu := SaveMenu;
  NewMenuToLoad := TRUE;
END;

FUNCTION CanSee(CONST FileInfo: FileInfoRecordType): Boolean;
BEGIN
  CanSee := (NOT (FINotVal IN FileInfo.FIFlags)) OR (UserNum = FileInfo.OwnerNum) OR (AACS(General.SeeUnVal));
END;

PROCEDURE Output_File_Stuff(CONST s: AStr);
BEGIN
  IF (TextRec(NewFilesF).Mode = FMOutPut)THEN
  BEGIN
    WriteLn(NewFilesF,StripColor(s));
    Lines := 0;
  END
  ELSE
    PrintACR(s+'^1');
END;

PROCEDURE DisplayFileAreaHeader;
BEGIN
  IF (FileAreaNameDisplayed) THEN
    Exit;
  Lil := 0;
  Lines := 0;
  FileRedisplayLines := 0;
  (*
  CLS;
  IF (NOT General.FileCreditRatio) THEN
  BEGIN
    Output_File_Stuff('ÚÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿');
    Output_File_Stuff('³##³ File Name  ³   Size   ³ Description  '+PadLeftStr(s,34)+'  ³');
    Output_File_Stuff('ÀÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ');
  END
  ELSE
  BEGIN
    Output_File_Stuff('ÚÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿');
    Output_File_Stuff('³##³ÿFile Name  ³Pts³ Size ³ Description  '+PadLeftStr(s,34)+'  ³');
    Output_File_Stuff('ÀÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ');
  END;
  *)

  IF (NOT General.FileCreditRatio) THEN
    lRGLngStr(63,FALSE)
  ELSE
    lRGLngStr(64,FALSE);
  Inc(Lines,LIL);
  Inc(FileRedisplayLines,LIL);

  FileAreaNameDisplayed := TRUE;
END;

FUNCTION GetFileStats(FileInfo: FileInfoRecordType): AStr;
BEGIN
  IF (FIIsRequest IN FileInfo.FIFlags) THEN
    GetFileStats := '   Offline'
  ELSE IF (FIResumeLater IN FileInfo.FIFlags) THEN
    GetFileStats := '   ResLatr'
  ELSE IF (FINotVal IN FileInfo.FIFlags) THEN
    GetFileStats := '   Unvalid'
  ELSE IF (NOT General.FileCreditRatio) THEN
    GetFileStats := ''+PadRightStr(ConvertBytes(FileInfo.FileSize,TRUE),10)
  ELSE
    GetFileStats := ''+PadRightInt(FileInfo.FilePoints,3)+' '+PadRightStr(ConvertKB(FileInfo.FileSize DIV 1024,TRUE),6);
END;

PROCEDURE lDisplay_File(FileInfo: FileInfoRecordType; FArrayRecNum: Byte; SearchString: Str20;
                        NormalPause: Boolean);
VAR
  TempStr,
  TempStr1,
  TempStr2: AStr;
  LineNum,
  NumExtDesc: Byte;

  FUNCTION SubStone(SrcStr,OldStr,NewStr: AStr; IsCaps: Boolean): AStr;
  VAR
    StrPos: Byte;
  BEGIN
    IF (OldStr <> '') THEN
    BEGIN
      IF (IsCaps) THEN
        NewStr := AllCaps(NewStr);
      StrPos := Pos(AllCaps(OldStr),AllCaps(SrcStr));
      IF (StrPos > 0)  THEN
      BEGIN
        Insert(NewStr,SrcStr,(StrPos + Length(OldStr)));
        Delete(SrcStr,StrPos,Length(OldStr));
      END;
    END;
    SubStone := SrcStr;
  END;

BEGIN
  TempStr := AOnOff(DayNum(PD2Date(FileInfo.FileDate)) >= DayNum(PD2Date(NewFileDate)),'*',' ')+
                    ''+PadRightInt(FArrayRecNum,2);

  TempStr1 := FileInfo.FileName;
  IF (SearchString <> '') THEN
    TempStr1 := SubStone(TempStr1,SearchString,''+AllCaps(SearchString)+'',TRUE);
  TempStr := TempStr + ' '+TempStr1+' '+GetFileStats(FileInfo)+'';

  TempStr2 := TempStr;

  TempStr1 := FileInfo.Description;
  IF (SearchString <> '') THEN
    TempStr1 := SubStone(TempStr1,SearchString,''+AllCaps(SearchString)+'',TRUE);
  IF (LennMCI(TempStr1) > 50) THEN
    TempStr1 := Copy(TempStr1,1,Length(TempStr1) - (LennMCI(TempStr1) - 50));
  TempStr := TempStr + ' '+TempStr1;


  IF (NOT NormalPause) AND (NOT Next) AND (NOT Abort) AND (NOT HangUp) THEN
    DisplayFileAreaHeader;

  Inc(Lines);

  IF (NOT Next) AND (NOT Abort) AND (NOT HangUp) THEN
    Output_File_Stuff(TempStr);
  IF (NOT NormalPause) AND (NOT Next) AND (NOT Abort) AND (NOT HangUp) THEN
    Pause_Files;

  IF (FileInfo.VPointer <> -1) THEN
  BEGIN
    LoadVerbArray(FileInfo,ExtendedArray,NumExtDesc);
    LineNum := 1;
    WHILE (LineNum <= NumExtDesc) AND (NOT Next) AND (NOT Abort) AND (NOT HangUp) DO
    BEGIN
      TempStr1 := ExtendedArray[LineNum];
      IF (SearchString <> '') THEN
        TempStr1 := SubStone(TempStr1,SearchString,''+AllCaps(SearchString)+'',TRUE);

      IF (Lines = FileRedisplayLines) THEN
        TempStr := TempStr2 + ' '+TempStr1+''
      ELSE
        TempStr := PadLeftStr('',28)+''+TempStr1+'';

      IF (NOT NormalPause) AND (NOT Next) AND (NOT Abort) AND (NOT HangUp) THEN
        DisplayFileAreaHeader;

      Inc(Lines);

      IF (NOT Next) AND (NOT Abort) AND (NOT HangUp) THEN
        Output_File_Stuff(TempStr);

      IF (NOT NormalPause) AND (NOT Next) AND (NOT Abort) AND (NOT HangUp) THEN
        Pause_Files;
      Inc(LineNum);
    END;
  END;

  TempStr := '';
  IF (FAShowName IN MemFileArea.FAFlags) THEN
    IF (Lines = FileRedisplayLines) THEN
      TempStr := TempStr2 + ' Uploaded by '+Caps(FileInfo.OwnerName)
    ELSE
      TempStr := TempStr + PadLeftStr('',28)+'Uploaded by '+Caps(FileInfo.OwnerName);

  IF (FAShowDate IN MemFileArea.FAFlags) THEN
  BEGIN
    IF (TempStr = '') THEN
      IF (Lines = FileRedisplayLines) THEN
        TempStr := TempStr2 + ' Uploaded'
      ELSE
        TempStr := PadLeftStr('',28)+'Uploaded';
    TempStr := TempStr +' on '+PD2Date(FileInfo.FileDate);
    IF (Length(TempStr) > 78) THEN
      TempStr := Copy(TempStr,1,78);
  END;

  IF (FAShowName IN MemFileArea.FAFlags) OR (FAShowDate IN MemFileArea.FAFlags) THEN
  BEGIN

    IF (NOT NormalPause) AND (NOT Next) AND (NOT Abort) AND (NOT HangUp) THEN
      DisplayFileAreaHeader;

    Inc(Lines);

    IF (NOT Next) AND (NOT Abort) AND (NOT HangUp) THEN
      Output_File_Stuff(TempStr);
    IF (NOT NormalPause) AND (NOT Next) AND (NOT Abort) AND (NOT HangUp) THEN
      Pause_Files;
  END;

  IF (FIResumeLater IN FileInfo.FIFlags) AND (FileInfo.OwnerNum = UserNum) AND NOT (TextRec(NewFilesF).Mode = FMOutPut) THEN
  BEGIN
    IF (Lines = FileRedisplayLines) THEN
      TempStr := TempStr2 + ' ^8>^7'+'>> ^3'+'You ^5'+'MUST RESUME^3'+' this file to receive credit'
    ELSE
      TempStr := PadLeftStr('',28)+'^8>^7'+'>> ^3'+'You ^5'+'MUST RESUME^3'+' this file to receive credit';

    IF (NOT NormalPause) AND (NOT Next) AND (NOT Abort) AND (NOT HangUp) THEN
      DisplayFileAreaHeader;

    Inc(Lines);

    IF (NOT Next) AND (NOT Abort) AND (NOT HangUp) THEN
      Output_File_Stuff(TempStr);
    IF (NOT NormalPause) AND (NOT Next) AND (NOT Abort) AND (NOT HangUp) THEN
      Pause_Files;
  END;
END;

PROCEDURE SearchFileAreaSpec(FArea: Integer; FName: Str12; VAR FArrayRecNum: Byte);
VAR
  DirFileRecNum: Integer;
  Found: Boolean;
BEGIN
  IF (FileArea <> FArea) THEN
    ChangeFileArea(FArea);
  IF (FileArea = FArea) THEN
  BEGIN
    RecNo(FileInfo,FName,DirFileRecNum);
    IF (BadDownloadPath) THEN
      Exit;
    Found := FALSE;
    LIL := 0;
    CLS;
    Prompt('^1Scanning ^5'+MemFileArea.AreaName+' #'+IntToStr(CompFileArea(FArea,0))+'^1 ...');
    WHILE (DirFileRecNum <> -1) AND (NOT Abort) AND (NOT HangUp) DO
    BEGIN
      Seek(FileInfoFile,DirFileRecNum);
      Read(FileInfoFile,FileInfo);
      IF (CanSee(FileInfo)) THEN
      BEGIN

        WITH FArray[FArrayRecNum] DO
        BEGIN
          FArrayFileArea := FileArea;
          FArrayDirFileRecNum := DirFileRecNum;
        END;

        DisplayFileAreaHeader;
        lDisplay_File(FileInfo,FArrayRecNum,'',FALSE);

        Inc(FArrayRecNum);
        IF (FArrayRecNum = 100) THEN
          FArrayRecNum := 0;

        Found := TRUE;
      END;
      NRecNo(FileInfo,DirFileRecNum);
      IF (DirFileRecNum = -1) AND (Found) AND (Lines > FileRedisplayLines) AND (NOT Abort) AND (NOT HangUp) THEN
      BEGIN
        Lines := PageLength;
        Pause_Files;
      END;
    END;
    IF (NOT Found) THEN
    BEGIN
      LIL := 0;
      BackErase(15 + LennMCI(MemFileArea.AreaName) + Length(IntToStr(CompFileArea(FArea,0))));
    END;
    Close(FileInfoFile);
    Close(ExtInfoFile);
  END;
END;

PROCEDURE SearchFileSpec;
VAR
  FName: Str12;
  FArrayRecNum: Byte;
  FArea,
  SaveFileArea: Integer;
  SaveConfSystem: Boolean;
BEGIN
  NL;
  { Print(FString.SearchLine); }
  lRGLngStr(20,FALSE);
  { Print(FString.lGFNLine1); }
  lRGLngStr(28,FALSE);
  { Prt(FString.GFNLine2); }
  lRGLngStr(29,FALSE);
  FName := '';
  GetFileName(FName);
  IF (FName = '') THEN
  BEGIN
    Print('%LFAborted.');
    Exit;
  END;
  SaveFileArea := FileArea;
  Abort := FALSE;
  Next := FALSE;
  InitFArray(FArray);
  FArrayRecNum := 0;
  SaveConfSystem := ConfSystem;
  ConfSystem := NOT PYNQ('%LFSearch all conferences? ',0,TRUE);
  IF (ConfSystem <> SaveConfSystem) THEN
    NewCompTables;
  FArea := 1;
  WHILE (FArea >= 1) AND (FArea <= NumFileAreas) AND (NOT Abort) AND (NOT HangUp) DO
  BEGIN
    SearchFileAreaSpec(FArea,FName,FArrayRecNum);
    WKey;
    Inc(FArea);
  END;
  IF (ConfSystem <> SaveConfSystem) THEN
  BEGIN
    ConfSystem := SaveConfSystem;
    NewCompTables;
  END;
  FileArea := SaveFileArea;
  LoadFileArea(FileArea);
END;

PROCEDURE ListFileSpec(FName: Str12);
VAR
  FArrayRecNum: Byte;
BEGIN
  Abort := FALSE;
  Next := FALSE;
  InitFArray(FArray);
  FArrayRecNum := 0;
  IF (FName = '') THEN
  BEGIN
    NL;
    { Print(FString.ListLine); }
    lRGLngStr(18,FALSE);
    { Print(FString.lGFNLine1); }
    lRGLngStr(28,FALSE);
    { Prt(FString.GFNLine2); }
    lRGLngStr(29,FALSE);
    GetFileName(FName);
  END
  ELSE
    FName := Align(FName);
  SearchFileAreaSpec(FileArea,FName,FArrayRecNum);
END;

PROCEDURE SearchFileAreaDescription(FArea: Integer; SearchString: Str20; VAR FArrayRecNum: Byte);
VAR
  LineNum,
  NumExtDesc: Byte;
  DirFileRecNum: Integer;
  SearchStringFound,
  Found: Boolean;
BEGIN
  IF (FileArea <> FArea) THEN
    ChangeFileArea(FArea);
  IF (FileArea = FArea) THEN
  BEGIN
    RecNo(FileInfo,'*.*',DirFileRecNum);
    IF (BadDownloadPath) THEN
      Exit;
    Found := FALSE;
    LIL := 0;
    CLS;
    Prompt('^1Scanning ^5'+MemFileArea.AreaName+' #'+IntToStr(CompFileArea(FArea,0))+'^1 ...');
    WHILE (DirFileRecNum <> -1) AND (NOT Abort) AND (NOT HangUp) DO
    BEGIN
      Seek(FileInfoFile,DirFileRecNum);
      Read(FileInfoFile,FileInfo);
      IF (CanSee(FileInfo)) THEN
      BEGIN
        SearchStringFound := ((Pos(SearchString,AllCaps(FileInfo.Description)) <> 0) OR
                             (Pos(SearchString,AllCaps(FileInfo.FileName)) <> 0));
        IF (NOT SearchStringFound) AND (FileInfo.VPointer <> -1) THEN
        BEGIN
          LoadVerbArray(FileInfo,ExtendedArray,NumExtDesc);
          LineNum := 1;
          WHILE (LineNum <= NumExtDesc) AND (NOT SearchStringFound) AND (NOT Abort) AND (NOT HangUp) DO
          BEGIN
            IF (Pos(SearchString,AllCaps(ExtendedArray[LineNum])) <> 0) THEN
              SearchStringFound := TRUE;
            Inc(LineNum);
          END;
        END;
        IF (SearchStringFound) THEN
        BEGIN

          WITH FArray[FArrayRecNum] DO
          BEGIN
            FArrayFileArea := FileArea;
            FArrayDirFileRecNum := DirFileRecNum;
          END;

          DisplayFileAreaHeader;

          lDisplay_File(FileInfo,FArrayRecNum,SearchString,FALSE);

          Inc(FArrayRecNum);
          IF (FArrayRecNum = 100) THEN
            FArrayRecNum := 0;

          Found := TRUE;
        END;
      END;
      NRecNo(FileInfo,DirFileRecNum);
      IF (DirFileRecNum = -1) AND (Found) AND (Lines > FileRedisplayLines) AND (NOT Abort) AND (NOT HangUp) THEN
      BEGIN
        Lines := PageLength;
        Pause_Files;
      END;
    END;
    IF (NOT Found) THEN
    BEGIN
      LIL := 0;
      BackErase(15 + LennMCI(MemFileArea.AreaName) + Length(IntToStr(CompFileArea(FArea,0))));
    END;
    Close(FileInfoFile);
    Close(ExtInfoFile);
  END;
END;

PROCEDURE SearchFileDescriptions;
VAR
  SearchString: Str20;
  FArrayRecNum: Byte;
  FArea,
  SaveFileArea: Integer;
  SaveConfSystem: Boolean;
BEGIN
  NL;
  { Print(FString.FindLine1); }
  lRGLngStr(21,FALSE);
  NL;
  { Print(FString.FindLine2); }
  lRGLngStr(22,FALSE);
  Prt(': ');
  MPL(20);
  Input(SearchString,20);
  IF (SearchString = '') THEN
  BEGIN
    Print('%LFAborted.');
    Exit;
  END;
  Abort := FALSE;
  Next := FALSE;
  InitFArray(FArray);
  FArrayRecNum := 0;
  Print('%LFSearching for "'+SearchString+'"');
  IF (NOT PYNQ('%LFSearch all file areas? ',0,FALSE)) THEN
    SearchFileAreaDescription(FileArea,SearchString,FArrayRecNum)
  ELSE
  BEGIN
    SaveFileArea := FileArea;
    SaveConfSystem := ConfSystem;
    ConfSystem := NOT PYNQ('%LFSearch all conferences? ',0,TRUE);
    IF (ConfSystem <> SaveConfSystem) THEN
      NewCompTables;
    FArea := 1;
    WHILE (FArea >= 1) AND (FArea <= NumFileAreas) AND (NOT Abort) AND (NOT HangUp) DO
    BEGIN
      SearchFileAreaDescription(FArea,SearchString,FArrayRecNum);
      WKey;
      Inc(FArea);
    END;
    IF (ConfSystem <> SaveConfSystem) THEN
    BEGIN
      ConfSystem := SaveConfSystem;
      NewCompTables;
    END;
    FileArea := SaveFileArea;
    LoadFileArea(FileArea);
  END;
END;

PROCEDURE NewFileScan(FArea: Integer; Global: Boolean; VAR FArrayRecNum: Byte);
VAR
  DirFileRecNum: Integer;
  Found: Boolean;
BEGIN
  IF (FileArea <> FArea) THEN
    ChangeFileArea(FArea);
  IF (FileArea = FArea) THEN
  BEGIN
    RecNo(FileInfo,'*.*',DirFileRecNum);
    IF (BadDownloadPath) THEN
      Exit;
    IF (NOT Global) OR (NewScanFileArea) THEN
    BEGIN
      Found := FALSE;
      LIL := 0;
      CLS;
      Prompt('^1Scanning ^5'+MemFileArea.AreaName+' #'+IntToStr(CompFileArea(FileArea,0))+'^1 ...');
      WHILE (DirFileRecNum <> -1) AND (NOT Abort) AND (NOT HangUp) DO
      BEGIN

        Seek(FileInfoFile,DirFileRecNum);
        Read(FileInfoFile,FileInfo);

        IF ((CanSee(FileInfo)) AND (DayNum(PD2Date(FileInfo.FileDate)) >= DayNum(PD2Date(NewFileDate))))
           OR (CanSee(FileInfo) AND (FINotVal IN FileInfo.FIFlags)) THEN
        BEGIN

          WITH FArray[FArrayRecNum] DO
          BEGIN
            FArrayFileArea := FileArea;
            FArrayDirFileRecNum := DirFileRecNum;
          END;

          DisplayFileAreaHeader;
          lDisplay_File(FileInfo,FArrayRecNum,'',FALSE);

          Inc(FArrayRecNum);
          IF (FArrayRecNum = 100) THEN
            FArrayRecNum := 0;

          Found := TRUE;
        END;
        NRecNo(FileInfo,DirFileRecNum);
        IF (DirFileRecNum = -1) AND (Found) AND (Lines > FileRedisplayLines) AND (NOT Abort) AND (NOT HangUp) THEN
        BEGIN
          Lines := PageLength;
          Pause_Files;
        END;
      END;
      IF (NOT Found) THEN
      BEGIN
        LIL := 0;
        BackErase(15 + LennMCI(MemFileArea.AreaName) + Length(IntToStr(CompFileArea(FArea,0))));
      END;
    END;
    Close(FileInfoFile);
    Close(ExtInfoFile);
  END;
END;

PROCEDURE GlobalNewFileScan(VAR FArrayRecNum: Byte);
VAR
  FArea: Integer;
BEGIN
  FArea := 1;
  WHILE (FArea >= 1) AND (FArea <= NumFileAreas) AND (NOT Abort) AND (NOT HangUp) DO
  BEGIN
    NewFileScan(FArea,TRUE,FArrayRecNum);
    IF (TextRec(NewFilesF).Mode = FMOutPut) THEN
      Output_File_Stuff('');
    WKey;
    Inc(FArea);
  END;
END;

PROCEDURE NewFilesScanSearchType(CONST MenuOption: Str50);
VAR
  FArrayRecNum: Byte;
  SaveFileArea: Integer;
BEGIN
  SaveFileArea := FileArea;
  Abort := FALSE;
  Next := FALSE;
  InitFArray(FArray);
  FArrayRecNum := 0;
  IF (UpCase(MenuOption[1]) = 'C') THEN
    NewFileScan(FileArea,FALSE,FArrayRecNum)
  ELSE IF (UpCase(MenuOption[1]) = 'G') THEN
    GlobalNewFileScan(FArrayRecNum)
  ELSE IF (StrToInt(MenuOption) <> 0) THEN
    NewFileScan(StrToInt(MenuOption),FALSE,FArrayRecNum)
  ELSE
  BEGIN
    {
    NL;
    Print('|03List Files - |11P |03to Pause');
    NL;
    }
    lRGLngStr(19,FALSE);

    IF PYNQ('%LFSearch all file areas? ',0,FALSE) THEN
      GlobalNewFileScan(FArrayRecNum)
    ELSE
      NewFileScan(FileArea,FALSE,FArrayRecNum);
  END;
  FileArea := SaveFileArea;
  LoadFileArea(FileArea);
END;

PROCEDURE FileAreaChange(VAR Done: Boolean; CONST MenuOption: Str50);
VAR
  InputStr: Str5;
  Cmd: Char;
  FArea,
  SaveFArea,
  NumFAreas: Integer;
  SaveTempPause: Boolean;
BEGIN
  IF (MenuOption <> '') THEN
    CASE Upcase(MenuOption[1]) OF
      '+' : BEGIN
              FArea := FileArea;
              IF (FileArea >= NumFileAreas) THEN
                FArea := 0
              ELSE
                REPEAT
                  Inc(FArea);
                  ChangeFileArea(FArea);
                UNTIL ((FileArea = FArea) OR (FArea >= NumFileAreas));
              IF (FileArea <> FArea) THEN
              BEGIN
                {
                %LFHighest accessible file area.
                %PA
                }
                LRGLngStr(83,FALSE);
              END
              ELSE
                LastCommandOvr := TRUE;
            END;
      '-' : BEGIN
              FArea := FileArea;
              IF (FileArea <= 0) THEN
                FArea := 0
              ELSE
                REPEAT
                  Dec(FArea);
                  ChangeFileArea(FArea);
                UNTIL ((FileArea = FArea) OR (FArea <= 0));
              IF (FileArea <> FArea) THEN
              BEGIN
                {
                %LFLowest accessible file area.
                %PA
                }
                LRGLngStr(82,FALSE);
              END
              ELSE
                LastCommandOvr := TRUE;
            END;
      'L' : BEGIN
              SaveTempPause := TempPause;
              TempPause := FALSE;
              FArea := 1;
              NumFAreas := 0;
              Cmd := '?';
              REPEAT
                SaveFArea := FArea;
                IF (Cmd = '?') THEN
                  LFileAreaList(FArea,NumFAreas,5,FALSE);
                {
                %LFFile area list? [^5#^4,^5?^4=^5Help^4,^5Q^4=^5Quit^4]: @
                }
                LOneK(LRGLngStr(70,TRUE),Cmd,'Q[]?',TRUE,TRUE);
                TempPause := FALSE;
                IF (Cmd <> 'Q') THEN
                BEGIN
                  IF (Cmd = '[') THEN
                  BEGIN
                    Farea := (SaveFArea - ((PageLength - 5) * 2));
                    IF (FArea < 1) THEN
                      FArea := 1;
                    Cmd := '?';
                  END
                  ELSE IF (Cmd = ']') THEN
                  BEGIN
                    IF (FArea > NumFileAreas) THEN
                      FArea := SaveFArea;
                    Cmd := '?';
                  END
                  ELSE IF (Cmd = '?') THEN
                  BEGIN
                    {
                    $File_Message_Area_List_Help
                    %LF^1(^3###^1)Manual entry selection  ^1(^3<CR>^1)Select current entry
                    ^1(^3<Home>^1)First entry on page  ^1(^3<End>^1)Last entry on page
                    ^1(^3Left Arrow^1)Previous entry   ^1(^3Right Arrow^1)Next entry
                    ^1(^3Up Arrow^1)Move up            ^1(^3Down Arrow^1)Move down
                    ^1(^3[^1)Previous page             ^1(^3]^1)Next page
                    %PA
                    }
                    LRGLngStr(71,FALSE);
                    FArea := SaveFArea;
                  END
                END;
              UNTIL (Cmd = 'Q') OR (HangUp);
              TempPause := SaveTempPause;
              LastCommandOvr := TRUE;
           END;
    ELSE
    BEGIN
      IF (StrToInt(MenuOption) > 0) THEN
      BEGIN
        FArea := StrToInt(MenuOption);
        IF (FArea <> FileArea) THEN
          ChangeFileArea(FArea);
        IF (Pos(';',MenuOption) > 0) THEN
        BEGIN
          CurMenu := StrToInt(Copy(MenuOption,(Pos(';',MenuOption) + 1),Length(MenuOption)));
          NewMenuToLoad := TRUE;
          Done := TRUE;
        END;
        LastCommandOvr := TRUE;
      END;
    END;
  END
  ELSE
  BEGIN
    SaveTempPause := TempPause;
    TempPause := FALSE;
    FArea := 1;
    NumFAreas := 0;

    LightBarCmd := 1;
    LightBarFirstCmd := TRUE;

    InputStr := '?';
    REPEAT
      SaveFArea := FArea;
      IF (InputStr = '?') THEN
        lFileAreaList(FArea,NumFAreas,5,FALSE);
      {
      %LFChange file area? [^5#^4,^5?^4=^5Help^4,^5Q^4=^5Quit^4]: @
      }
      FileAreaScanInput(LRGLngStr(72,TRUE),Length(IntToStr(HighFileArea)),InputStr,'Q[]?',LowFileArea,HighFileArea);
      IF (InputStr <> 'Q') THEN
      BEGIN
        IF (InputStr = '[') THEN
        BEGIN
          Farea := (SaveFArea - ((PageLength - 5) * 2));
          IF (FArea < 1) THEN
            FArea := 1;
          InputStr := '?';
        END
        ELSE IF (InputStr = ']') THEN
        BEGIN
          IF (FArea > NumFileAreas) THEN
            FArea := SaveFArea;
          InputStr := '?';
        END
        ELSE IF (InputStr = '?') THEN
        BEGIN
          {
          $File_Message_Area_List_Help
          %LF^1(^3###^1)Manual entry selection  ^1(^3<CR>^1)Select current entry
          ^1(^3<Home>^1)First entry on page  ^1(^3<End>^1)Last entry on page
          ^1(^3Left Arrow^1)Previous entry   ^1(^3Right Arrow^1)Next entry
          ^1(^3Up Arrow^1)Move up            ^1(^3Down Arrow^1)Move down
          ^1(^3[^1)Previous page             ^1(^3]^1)Next page
          %PA
          }
          LRGLngStr(71,FALSE);
          FArea := SaveFArea;
        END
        ELSE IF (StrToInt(InputStr) < LowFileArea) OR (StrToInt(InputStr) > HighFileArea) THEN
        BEGIN
          {
          %LF^7The range must be from %A1 to %A2!^1
          }
          LRGLngStr(78,FALSE);
          FArea := SaveFArea;
          InputStr := '?';
        END
        ELSE
        BEGIN
          FArea := CompFileArea(StrToInt(InputStr),1);
          IF (FArea <> FileArea) THEN
            ChangeFileArea(FArea);
          IF (FArea = FileArea) THEN
            InputStr := 'Q'
          ELSE
          BEGIN
            {
            %LF^7You do not have access to this file area!^1
            }
            LRGLngStr(80,FALSE);
            FArea := SaveFArea;
            InputStr := '?';
          END;
        END;
      END;
    UNTIL (InputStr = 'Q') OR (HangUp);
    TempPause := SaveTempPause;
    LastCommandOvr := TRUE;
  END;
END;

PROCEDURE CreateTempDir;
VAR
  TempPath: Str40;
  Changed: Boolean;
BEGIN
  TempPath := '';
  InputPath('%LF^4Enter file path for temporary directory (^5End with a ^4"^5\^4"):%LF^4:',TempPath,TRUE,TRUE,Changed);
  IF (TempPath = '') THEN
  BEGIN
    Print('%LFAborted.');
    Exit;
  END;
  IF (NOT ExistDir(TempPath)) THEN
  BEGIN
    Print('%LFThat directory does not exist.');
    Exit;
  END;
  FillChar(TempMemFileArea,SizeOf(TempMemFileArea),0);
  WITH TempMemFileArea DO
  BEGIN
    AreaName := '<< Temporary >>';
    FileName := 'TEMPFILE';
    DLPath := TempPath;
    ULPath := TempPath;
    MaxFiles := 2000;
    Password := '';
    ArcType := 1;
    CmtType := 1;
    ACS := 's'+IntToStr(ThisUser.SL)+'d'+IntToStr(ThisUser.DSL);
    ULACS := ACS;
    DLACS := ACS;
    FAFlags := [];
  END;
  FileArea := (NumFileAreas + 1);
  LoadFileArea(FileArea);
  SysOpLog('Created temporary directory #'+IntToStr(FileArea)+' in "'+TempPath+'"');
END;

END.
