{$IFDEF WIN32}
{$I DEFINES.INC}
{$ENDIF}

{$A+,B-,D+,E-,F+,I-,L+,N-,O+,R-,S+,V-}

UNIT File6;

INTERFACE

USES
  Common;

FUNCTION CheckBatchDL(FileName: Str52): Boolean;
PROCEDURE EditBatchDLQueue;
PROCEDURE BatchDownload;
PROCEDURE ListBatchDLFiles;
PROCEDURE RemoveBatchDLFiles;
PROCEDURE ClearBatchDlQueue;

IMPLEMENTATION

USES
  Dos,
  Common5,
  ExecBat,
  File0,
  File1,
  File2,
  File4,
  File12,
  MultNode,
  ShortMsg,
  TimeFunc;

FUNCTION CheckBatchDL(FileName: Str52): Boolean;
VAR
  RecNum: LongInt;
  FileFound: Boolean;
BEGIN
  FileFound := FALSE;
  IF (NumBatchDLFiles > 0) THEN
  BEGIN
    Assign(BatchDLFile,General.DataPath+'BATCHDL.DAT');
    Reset(BatchDLFile);
    RecNum := 1;
    WHILE (RecNum <= FileSize(BatchDLFile)) AND (NOT FileFound) DO
    BEGIN
      Seek(BatchDLFile,(RecNum - 1));
      Read(BatchDLFile,BatchDL);
      IF (BatchDL.BDLUserNum = UserNum) AND (BatchDL.BDLFileName = FileName) THEN
        FileFound := TRUE;
      Inc(RecNum);
    END;
    Close(BatchDLFile);
    LastError := IOResult;
  END;
  CheckBatchDL := FileFound;
END;

PROCEDURE EditBatchDLQueue;
VAR
  Cmd: CHAR;
BEGIN
  IF (NumBatchDLFiles = 0) THEN
  BEGIN
    NL;
    Print('The batch download queue is empty');
    Exit;
  END;
  REPEAT
    NL;
    Prt('Batch download queue [^5C^4=^5Clear Batch^4,^5L^4=^5List Batch^4,^5R^4=^5Remove a file^4,^5Q^4=^5Quit^4]: ');
    OneK(Cmd,'QCLR',TRUE,TRUE);
    CASE Cmd OF
      'C' : ClearBatchDlQueue;
      'L' : ListBatchDLFiles;
      'R' : RemoveBatchDLFiles;
    END;
  UNTIL (Cmd = 'Q') OR (HangUp);
END;

PROCEDURE BatchDownload;
TYPE
  TotalsRecordType = RECORD
    FilesDL,
    FilesDLRatio: Byte;
    BytesDL,
    BytesDLRatio,
    PointsDL,
    PointsDLRatio: LongInt;
  END;
VAR
  Totals: TotalsRecordType;
  FileListTxt,
  DLFListTxt: Text;
  NewFileName: AStr;
  SaveLastDirFileName: Str12;
  NumExtDesc,
  Counter,
  Counter1: BYTE;
  ReturnCode,
  SaveFileArea,
  DirFileRecNum,
  ProtocolNumber,
  SaveLastDirFileRecNum,
  ToXfer: Integer;
  RecNum,
  RecNum1,
  TransferTime: LongInt;
  AutoLogOff,
  FO: Boolean;

  PROCEDURE AddNacc(BatchDL: BatchDLRecordType);
  BEGIN
    IF (BatchDL.BDLSection = -1) THEN
    BEGIN
      IF (IsFileAttach IN BatchDL.BDLFlags) THEN
        MemFileArea.AreaName := 'File Attach'
      ELSE IF (IsUnlisted IN BatchDL.BDLFlags) THEN
        MemFileArea.AreaName := 'Unlisted Download'
      ELSE IF (IsTempArc IN BatchDL.BDLFlags) THEN
        MemFileArea.AreaName := 'Temporary Archive'
      ELSE IF (IsQWK IN BatchDL.BDLFlags) THEN
        MemFileArea.AreaName := 'QWK Download';
    END
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
      FileArea := BatchDL.BDLSection;
      RecNo(FileInfo,StripName(BatchDL.BDLFileName),DirFileRecNum);
      IF (BadDownloadPath) THEN
        Exit;
      IF (DirFileRecNum <> -1) THEN
      BEGIN
        Seek(FileInfoFile,DirFileRecNum);
        Read(FileInfoFile,FileInfo);
        Inc(FileInfo.Downloaded);
        Seek(FileInfoFile,DirFileRecNum);
        Write(FileInfoFile,FileInfo);
      END;
      Close(FileInfoFile);
      Close(ExtInfoFile);
      FileArea := SaveFileArea;
      IF (FO) THEN
        InitFileArea(FileArea);
      LastDIRRecNum := SaveLastDirFileRecNum;
      LastDIRFileName := SaveLastDirFileName;
    END;
    NL;
    Star(StripName(BatchDL.BDLFileName)+' successfully downloaded.');
    SysOpLog('^3Batch downloaded: "^5'+StripName(BatchDL.BDLFileName)+'^3" from ^5'+
             MemFileArea.AreaName+'.');
    LastError := IOResult;
  END;

  FUNCTION ReverseSlash(S: AStr): AStr;
  VAR
    Counter: Byte;
  BEGIN
    FOR Counter := 1 TO Length(S) DO
      IF (S[Counter] = '/') THEN
        S[Counter] := '\';
    ReverseSlash := S;
  END;

  PROCEDURE UpdateSatistics(BatchDL: BatchDLRecordType);
  BEGIN

    IF (Totals.FilesDL < 255) THEN
      Inc(Totals.FilesDL);

    IF ((Totals.BytesDL + BatchDL.BDLFSize) < 2147483647) THEN
      Inc(Totals.BytesDL,BatchDL.BDLFSize)
    ELSE
      Totals.BytesDL := 2147483647;

    IF ((Totals.PointsDL + BatchDL.BDLPoints) < 2147483647) THEN
      Inc(Totals.PointsDL,BatchDL.BDLPoints)
    ELSE
      Totals.PointsDL := 2147483647;

    IF (NOT (IsNoRatio IN BatchDL.BDLFlags)) THEN
    BEGIN
      IF (Totals.FilesDLRatio < 255) THEN
        Inc(Totals.FilesDLRatio);

      IF ((Totals.BytesDLRatio + BatchDL.BDLFSize) < 2147483647) THEN
        Inc(Totals.BytesDLRatio,BatchDL.BDLFSize)
      ELSE
        Totals.BytesDLRatio := 2147483647;
    END;

    IF (NOT (IsNoFilePoints IN BatchDL.BDLFlags)) THEN
      IF ((Totals.PointsDLRatio + BatchDL.BDLPoints) < 2147483647) THEN
        Inc(Totals.PointsDLRatio,BatchDL.BDLPoints)
      ELSE
        Totals.PointsDLRatio := 2147483647;

    AddNacc(BatchDL);

    WITH FileInfo DO
    BEGIN
      FileName := StripName(BatchDL.BDLFileName);
      Description := '';
      FilePoints := BatchDL.BDLPoints;
      Downloaded := 0;
      FileSize := 0;
      OwnerNum := BatchDL.BDLUploader;
      OwnerName := BatchDL.BDLOwnerName;
      FileDate := 0;
      VPointer := 0;
      VTextSize := 0;
      FIFlags := [];
    END;

    CreditUploader(FileInfo);

    Dec(NumBatchDLFiles);
    Dec(BatchDLTime,BatchDL.BDLTime);
    Dec(BatchDLSize,BatchDL.BDLFSize);
    Dec(BatchDLPoints,BatchDL.BDLPoints);
    IF (BatchDL.BDLStorage = Copied) THEN
      Kill(BatchDL.BDLFileName);

  END;

  PROCEDURE ChopOfSpace(VAR S: AStr);
  BEGIN
    WHILE (S[1] = ' ') DO
      S := Copy(S,2,(Length(S) - 1));
    IF (Pos(' ',S) <> 0) THEN
      S := Copy(S,1,(Pos(' ',S) - 1));
  END;

  PROCEDURE FigureSucc;
  VAR
    TempLogTxt,
    DLoadLogTxt: Text;
    LogStr,
    FileStr,
    StatStr: AStr;
    RecNum,
    RecNum1: LongInt;
    ToFile,
    ReadLog,
    FoundFile,
    FoundReturnCode: Boolean;
  BEGIN

    ReadLog := FALSE;
    ToFile := FALSE;
    IF (Protocol.TempLog <> '') THEN
    BEGIN
      Assign(TempLogTxt,FunctionalMCI(Protocol.TempLog,'',''));
      Reset(TempLogTxt);
      IF (IOResult = 0) THEN
      BEGIN
        ReadLog := TRUE;
        IF (FunctionalMCI(Protocol.DLoadLog,'','') <> '') THEN
        BEGIN
          Assign(DLoadLogTxt,FunctionalMCI(Protocol.DLoadLog,'',''));
          Append(DLoadLogTxt);
          IF (IOResult = 2) THEN
            ReWrite(DLoadLogTxt);
          ToFile := TRUE;
        END;

        SysOpLog('Start scan of:  "^0'+AllCaps(FunctionalMCI(Protocol.TempLog,'',''))+'^1".');

        WHILE (NOT EOF(TempLogTxt)) DO
        BEGIN
          ReadLn(TempLogTxt,LogStr);
          IF (ToFile) THEN
            WriteLn(DLoadLogTxt,LogStr);
          FileStr := Copy(LogStr,Protocol.TempLogPF,((Length(LogStr) - Protocol.TempLogPF) - 1));
          StatStr := Copy(LogStr,Protocol.TempLogPS,((Length(LogStr) - Protocol.TempLogPS) - 1));

          FileStr := ReverseSlash(FileStr);

          ChopOfSpace(FileStr);

          FoundReturnCode := FALSE;
          FoundFile := FALSE;
          Reset(BatchDLFile);
          RecNum := 1;
          WHILE (RecNum <= FileSize(BatchDLFile)) AND (NOT FoundFile) DO
          BEGIN
            Seek(BatchDLFile,(RecNum - 1));
            Read(BatchDLFile,BatchDL);
            IF (BatchDL.BDLUserNum = UserNum) AND (Pos(AllCaps(BatchDL.BDLFileName),AllCaps(FileStr)) <> 0) THEN
            BEGIN
              FoundFile := TRUE;
              IF (FindReturnCode(Protocol.DLCode,Protocol.PRFlags,StatStr)) THEN
              BEGIN
                FoundReturnCode := TRUE;
                UpdateSatistics(BatchDL);
                Dec(RecNum);
                IF (RecNum >= 0) AND (RecNum <= (FileSize(BatchDLFile) - 2)) THEN
                  FOR RecNum1 := RecNum TO (FileSize(BatchDLFile) - 2) DO
                  BEGIN
                    Seek(BatchDLFile,(RecNum1 + 1));
                    Read(BatchDLFile,BatchDL);
                    Seek(BatchDLFile,RecNum1);
                    Write(BatchDLFile,BatchDL);
                  END;
                Seek(BatchDLFile,(FileSize(BatchDLFile) - 1));
                Truncate(BatchDLFile);
              END;
            END;
            Inc(RecNum);
          END;

          IF (NOT FoundFile) THEN
            SysOpLog('^7File not found: "^5'+BatchDL.BDLFileName+'^7"')
          ELSE IF (NOT FoundReturnCode) THEN
            SysOpLog('^7Return code not found: "^5'+BatchDL.BDLFileName+'^7"');
        END;
        SysOpLog('End scan of: "^0'+AllCaps(FunctionalMCI(Protocol.TempLog,'',''))+'^1".');

        Close(TempLogTxt);
        IF (ToFile) THEN
          Close(DLoadLogTxt);
      END;
    END;

    IF (NOT ReadLog) THEN
    BEGIN
      SysOpLog('Start scan of: "^0BATCHDL.DAT^1"');
      Reset(BatchDLFile);
      RecNum := 1;
      WHILE (RecNum <= FileSize(BatchDLFile)) DO
      BEGIN
        Seek(BatchDLFile,(RecNum - 1));
        Read(BatchDLFile,BatchDL);
        IF (BatchDL.BDLUserNum = UserNum) THEN
        BEGIN
          UpdateSatistics(BatchDL);
          Dec(RecNum);
          IF (RecNum >= 0) AND (RecNum <= (FileSize(BatchDLFile) - 2)) THEN
            FOR RecNum1 := RecNum TO (FileSize(BatchDLFile) - 2) DO
            BEGIN
              Seek(BatchDLFile,(RecNum1 + 1));
              Read(BatchDLFile,BatchDL);
              Seek(BatchDLFile,RecNum1);
              Write(BatchDLFile,BatchDL);
            END;
          Seek(BatchDLFile,(FileSize(BatchDLFile) - 1));
          Truncate(BatchDLFile);
        END;
        Inc(RecNum);
      END;
      SysOpLog('End scan of: "^0BATCHDL.DAT^1"');
    END;
  END;

BEGIN
  IF (NumBatchDLFiles = 0) THEN
  BEGIN
    NL;
    Print('The batch download queue is empty.');
    Exit;
  END;

  NL;
  Print('^5Batch download (Statistics):^1');
  NL;
  Star('^1Total file(s)     : ^5'+FormatNumber(NumBatchDLFiles)+'^1');
  Star('^1Total size        : ^5'+ConvertBytes(BatchDLSize,FALSE)+'^1');
  Star('^1Total file points : ^5'+FormatNumber(BatchDLPoints)+'^1');
  Star('^1Download time     : ^5'+CTim(BatchDLTime)+'^1');
  Star('^1Time left online  : ^5'+CTim(NSL)+'^1');

  IF (BatchDLPoints > ThisUser.FilePoints) THEN
  BEGIN
    NL;
    Print('^7Insufficient file points, remove file(s) from your batch queue!^1');
    NL;
    Print('^1Chargeable        : ^5'+FormatNumber(BatchDLPoints)+'^1');
    Print('^1Your account      : ^5'+FormatNumber(ThisUser.FilePoints)+'^1');
    NL;
    EditBatchDLQueue;
    Exit;
  END;

  IF (BatchDLTime > NSL) THEN
  BEGIN
    NL;
    Print('^7Insufficient time left online, remove file(s) from your batch queue!^1');
    NL;
    EditBatchDLQueue;
    Exit;
  END;

  ProtocolNumber := DoProtocol(Protocol,FALSE,TRUE,TRUE,FALSE);

  CASE ProtocolNumber OF
    -1 : ;
    -2 : Exit;
    -3 : ;
    -4 : ;
    -5 : EditBatchDLQueue;
  ELSE
    IF (InCom) THEN
    BEGIN

      Assign(BatchDLFile,General.DataPath+'BATCHDL.DAT');
      Reset(BatchDLFile);

      FillChar(Totals,SizeOf(Totals),0);

      PurgeDir(TempDir+'UP\',FALSE);

      IF Exist(FunctionalMCI(Protocol.TempLog,'','')) THEN
        Kill(FunctionalMCI(Protocol.TempLog,'',''));

      IF Exist(TempDir+'ARC\FILES.BBS') THEN
        Kill(TempDir+'ARC\FILES.BBS');

      IF Exist(FunctionalMCI(Protocol.DLFList,'','')) THEN
        Kill(FunctionalMCI(Protocol.DLFList,'',''));

      NL;
      AutoLogOff := PYNQ('Auto-logoff after file transfer? ',0,FALSE);

      NL;
      IF PYNQ('Download file descriptions? ',0,FALSE) THEN
      BEGIN
        Assign(FileListTxt,TempDir+'ARC\FILES.BBS');
        ReWrite(FileListTxt);
        Writeln(FileListTxt,StripColor(General.BBSName)+' Batch Download File Listing');
        WriteLn(FileListTxt);

        Reset(BatchDLFile);
        RecNum := 1;
        WHILE (RecNum <= FileSize(BatchDLFile)) DO
        BEGIN
          Seek(BatchDLFile,(RecNum - 1));
          Read(BatchDLFile,BatchDL);
          IF (BatchDL.BDLUserNum = UserNum) THEN
          BEGIN
            IF (BatchDL.BDLSection = -1) THEN
              WriteLn(FileListTxt,PadLeftStr(Align(StripName(BatchDL.BDLFileName)),14)+' [No Description Available]')
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
              FileArea := BatchDL.BDLSection;
              RecNo(FileInfo,StripName(BatchDL.BDLFileName),DirFileRecNum);
              IF (BadDownloadPath) THEN
                WriteLn(FileListTxt,PadLeftStr(Align(StripName(BatchDL.BDLFileName)),14)+' [Bad Download Path]')
              ELSE IF (DirFileRecNum = -1) THEN
                WriteLn(FileListTxt,PadLeftStr(Align(StripName(BatchDL.BDLFileName)),14)+' [File Not Found]')
              ELSE
              BEGIN
                Seek(FileInfoFile,DirFileRecNum);
                Read(FileInfoFile,FileInfo);
                WriteLn(FileListTxt,PadLeftStr(Align(StripName(BatchDL.BDLFileName)),14)+FileInfo.Description);
                IF (FileInfo.VPointer <> -1) THEN
                BEGIN
                  LoadVerbArray(FileInfo,ExtendedArray,NumExtDesc);
                  FOR Counter1 := 1 TO NumExtDesc DO
                    IF (ExtendedArray[Counter1] <> '') THEN
                      WriteLn(FileListTxt,PadLeftStr('',14)+ExtendedArray[Counter1]);
                END;
                Close(FileInfoFile);
                Close(ExtInfoFile);
                FileArea := SaveFileArea;
                IF (FO) THEN
                  InitFileArea(FileArea);
                LastDIRRecNum := SaveLastDirFileRecNum;
                LastDIRFileName := SaveLastDirFileName;
                LastError := IOResult;
              END;
              WriteLn(FileListTxt);
            END;
          END;
          Inc(RecNum);
        END;
        Close(FileListTxt);

        WITH BatchDL DO
        BEGIN
          BDLFileName := TempDir+'ARC\FILES.BBS';
          BDLOwnerName := Caps(ThisUser.Name);
          BDLStorage := Disk;
          BDLUserNum := UserNum;
          BDLSection := -1;
          BDLPoints := 0;
          BDLUploader := UserNum;
          BDLFSize := GetFileSize(TempDir+'ARC\FILES.BBS');
          BDLTime := (BDLFSize DIV Rate);
          BDLFlags := [];
        END;

        Seek(BatchDLFile,FileSize(BatchDLFILE));
        Write(BatchDLFile,BatchDL);

        Inc(NumBatchDLFiles);
        Inc(BatchDLTime,BatchDL.BDLTime);
        Inc(BatchDLSize,BatchDL.BDLFSize);
        Inc(BatchDLPoints,BatchDL.BDLPoints);

        NL;
        Print('^1File              : ^5FILES.BBS^1');
        Print('^1Size              : ^5'+ConvertBytes(BatchDL.BDLFSize,FALSE)+'^1');
        Print('^1File points       : ^5'+FormatNumber(BatchDL.BDLPoints)+'^1');
        Print('^1Download time     : ^5'+CTim(BatchDL.BDLTime)+'^1');
        NL;
        Print('^1New download time : ^5'+CTim(BatchDLTime)+'^1');
        LastError := IOResult;
      END;

      Reset(BatchDLFile);
      Counter1 := 0;
      RecNum := 1;
      WHILE (RecNum <= FileSize(BatchDLFile)) AND (Counter1 = 0) DO
      BEGIN
        Seek(BatchDLFile,(RecNum - 1));
        Read(BatchDLFile,BatchDL);
        IF (BatchDL.BDLUserNum = UserNum) AND (BatchDL.BDLStorage = CD) THEN
          Inc(Counter1);
        Inc(RecNum);
      END;

      IF (Counter1 <> 0) THEN
      BEGIN
        NL;
        Print('Please wait, copying files from CD-ROM ... ');

        Reset(BatchDLFile);
        RecNum := 1;
        WHILE (RecNum <= FileSize(BatchDLFile)) DO
        BEGIN
          Seek(BatchDLFile,(RecNum - 1));
          Read(BatchDLFile,BatchDL);
          IF (BatchDL.BDLUserNum = UserNum) AND (BatchDL.BDLStorage = CD) THEN
            IF CopyMoveFile(TRUE,'',BatchDL.BDLFileName,
                     TempDir+'CD\'+StripName(BatchDL.BDLFileName),FALSE) THEN
            BEGIN
              BatchDL.BDLStorage := Copied;
              BatchDL.BDLFileName := TempDir+'CD\'+StripName(BatchDL.BDLFileName);
              Seek(BatchDLFile,(RecNum - 1));
              Write(BatchDLFile,BatchDL);
            END;
          Inc(RecNum);
        END;
      END;


      NewFileName := General.ProtPath+FunctionalMCI(Protocol.DLCmd,'','');

      ToXfer := 0;

      IF (Pos('%F',Protocol.DLCmd) <> 0) THEN
      BEGIN
        Reset(BatchDLFile);
        RecNum := 1;
        WHILE (RecNum <= FileSize(BatchDLFile)) DO
        BEGIN
          Seek(BatchDLFile,(RecNum - 1));
          Read(BatchDLFile,BatchDL);
          IF (BatchDL.BDLUserNum = UserNum) THEN
          BEGIN
            Inc(ToXFer);
            NewFileName := FunctionalMCI(NewFileName,BatchDL.BDLFileName,'');
            IF (Length(NewFileName) > Protocol.MaxChrs) THEN
            BEGIN
              SysOpLog('^7Exceeds maximum DOS char length: "^5'+NewFileName+'^1"');
              RecNum := FileSize(BatchDLFile);
            END;
          END;
          Inc(RecNum);
        END;
      END;

      IF (Protocol.DLFList <> '') THEN
      BEGIN
        Assign(DLFListTxt,FunctionalMCI(Protocol.DLFList,'',''));
        ReWrite(DLFListTxt);
        Reset(BatchDLFile);
        RecNum := 1;
        WHILE (RecNum <= FileSize(BatchDLFile)) DO
        BEGIN
          Seek(BatchDLFile,(RecNum - 1));
          Read(BatchDLFile,BatchDL);
          IF (BatchDL.BDLUserNum = UserNum) THEN
          BEGIN
            WriteLn(DLFListTxt,BatchDL.BDLFileName);
            Inc(ToXfer);
          END;
          Inc(RecNum);
        END;
        Close(DLFListTxt);
        LastError := IOResult;
      END;

      NL;
      Star('Ready to send batch download transfer.');

      ExecProtocol('',
                   TempDir+'UP\',
                   FunctionalMCI(Protocol.EnvCmd,'','')
                   +#13#10+
                   NewFileName,
                   -1,
                   ReturnCode,
                   TransferTime);

      NL;
      Star('Batch download transfer complete.');

      IF Exist(FunctionalMCI(Protocol.DLFList,'','')) THEN
        Kill(FunctionalMCI(Protocol.DLFList,'',''));

      IF Exist(TempDir+'ARC\FILES.BBS') THEN
      BEGIN
        Reset(BatchDLFile);
        RecNum1 := -1;
        RecNum := 1;
        WHILE (RecNum <= FileSize(BatchDLFile)) AND (RecNum1 = -1) DO
        BEGIN
          Seek(BatchDLFile,(RecNum - 1));
          Read(BatchDLFile,BatchDL);
          IF ((BatchDL.BDLUserNum = UserNum) AND (BatchDL.BDLFileName = TempDir+'ARC\FILES.BBS')) THEN
          BEGIN
            Dec(NumBatchDLFiles);
            Dec(BatchDLTime,BatchDL.BDLTime);
            Dec(BatchDLSize,BatchDL.BDLFSize);
            Dec(BatchDLPoints,BatchDL.BDLPoints);
            IF (BatchDL.BDLStorage = Copied) THEN
              Kill(BatchDL.BDLFileName);
            RecNum1 := RecNum;
          END;
          Inc(RecNum);
        END;
        IF (RecNum1 <> -1) THEN
        BEGIN
          Dec(RecNum1);
          FOR RecNum := RecNum1 TO (FileSize(BatchDLFile) - 2) DO
          BEGIN
            Seek(BatchDLFile,(RecNum + 1));
            Read(BatchDLFile,BatchDL);
            Seek(BatchDLFile,RecNum);
            Write(BatchDLFile,BatchDL);
          END;
          Seek(BatchDLFile,(FileSize(BatchDLFile) - 1));
          Truncate(BatchDLFile);
        END;
        Kill(TempDir+'ARC\FILES.BBS');
      END;

      FigureSucc;

      IF Exist(FunctionalMCI(Protocol.TempLog,'','')) THEN
        Kill(FunctionalMCI(Protocol.TempLog,'',''));

      IF ((DownloadsToday + Totals.FilesDL) < 2147483647) THEN
        Inc(DownloadsToday,Totals.FilesDL)
      ELSE
        DownloadsToday := 2147483647;

      IF ((DownloadKBytesToday + (Totals.BytesDL DIV 1024)) < 2147483647) THEN
        Inc(DownloadKBytesToday,(Totals.BytesDL DIV 1024))
      ELSE
        DownloadKBytesToday := 2147483647;

      IF ((ThisUser.Downloads + Totals.FilesDLRatio) < 2147483647) THEN
        Inc(ThisUser.Downloads,Totals.FilesDLRatio)
      ELSE
        ThisUser.Downloads := 2147483647;

      IF ((ThisUser.DLToday + Totals.FilesDLRatio) < 2147483647) THEN
        Inc(ThisUser.DLToday,Totals.FilesDLRatio)
      ELSE
        ThisUser.DLToday := 2147483647;

      IF ((ThisUser.DK + (Totals.BytesDLRatio DIV 1024)) < 2147483647) THEN
        Inc(ThisUser.DK,(Totals.BytesDLRatio DIV 1024))
      ELSE
        ThisUser.DK := 2147483647;

      IF ((ThisUser.DLKToday + (Totals.BytesDLRatio DIV 1024)) < 2147483647) THEN
        Inc(ThisUser.DLKToday,(Totals.BytesDLRatio DIV 1024))
      ELSE
        ThisUser.DLKToday := 2147483647;

      IF ((ThisUser.FilePoints - Totals.PointsDLRatio) > 0) THEN
        Dec(ThisUser.FilePoints,Totals.PointsDLRatio)
      ELSE
        ThisUser.FilePoints := 0;

      LIL := 0;

      NL;
      Print('^5Batch download (Totals):^1');
      NL;
      Star('^1Total file(s)     : ^5'+FormatNumber(Totals.FilesDL));
      Star('^1Total size        : ^5'+ConvertBytes(Totals.BytesDL,FALSE));
      Star('^1Total file points : ^5'+FormatNumber(Totals.PointsDL));
      Star('^1Download time     : ^5'+FormattedTime(TransferTime));
      Star('^1Transfer rate     : ^5'+FormatNumber(GetCPS(Totals.BytesDL,TransferTime))+' cps');

      SysOpLog('^3 - Totals:'+
               ' '+FormatNumber(Totals.FilesDL)+' '+Plural('file',Totals.FilesDL)+
               ', '+ConvertBytes(Totals.BytesDL,FALSE)+
               ', '+FormatNumber(Totals.PointsDL)+' fp'+
               ', '+FormattedTime(TransferTime)+' tt'+
               ', '+FormatNumber(GetCPS(Totals.BytesDL,Transfertime))+' cps.');

      IF (Totals.FilesDL < Totals.FilesDLRatio) THEN
        Totals.FilesDLRatio := Totals.FilesDL;

      LIL := 0;

      NL;
      Print('^5Batch download (Charges):^1');
      NL;
      Star('^1Total file(s)     : ^5'+FormatNumber(Totals.FilesDLRatio));
      Star('^1Total size        : ^5'+ConvertBytes(Totals.BytesDLRatio,FALSE));
      Star('^1Total file points : ^5'+FormatNumber(Totals.PointsDLRatio));

      SysOpLog('^3 - Charges:'+
               ' '+FormatNumber(Totals.FilesDLRatio)+' '+Plural('file',Totals.FilesDLRatio)+
               ', '+ConvertBytes(Totals.BytesDLRatio,FALSE)+
               ', '+FormatNumber(Totals.PointsDLRatio)+' fp.');

      IF (NumBatchDLFiles > 0) THEN
      BEGIN

        Totals.BytesDL := 0;
        Totals.PointsDL := 0;

        Reset(BatchDLFile);
        RecNum := 1;
        WHILE (RecNum <= FileSize(BatchDLFile)) DO
        BEGIN
          Seek(BatchDLFile,(RecNum - 1));
          Read(BatchDLFile,BatchDL);
          IF (BatchDL.BDLUserNum = UserNum) THEN
          BEGIN
            Inc(Totals.BytesDL,BatchDL.BDLFSize);
            Inc(Totals.PointsDL,BatchDL.BDLPoints);
          END;
          Inc(RecNum);
        END;

        LIL := 0;

        NL;
        Print('^5Batch download (Not Transferred):^1');
        NL;
        Star('^1Total file(s)     : ^5'+FormatNumber(NumBatchDLFiles));
        Star('^1Total size        : ^5'+ConvertBytes(Totals.BytesDL,FALSE));
        Star('^1Total file points : ^5'+FormatNumber(Totals.PointsDL));

        SysOpLog('^3 - Not downloaded:'+
             ' '+FormatNumber(NumBatchDLFiles)+' '+Plural('file',NumBatchDLFiles)+
             ', '+ConvertBytes(Totals.BytesDL,FALSE)+
             ', '+FormatNumber(Totals.PointsDL)+' fp.');
      END;

      Close(BatchDLFile);

      LIL := 0;

      NL;
      Print('^5Enjoy the file(s), '+Caps(ThisUser.Name)+'!^1');
      PauseScr(FALSE);

      SaveURec(ThisUser,UserNum);

      IF (ProtBiDirectional IN Protocol.PRFlags) THEN
        BatchUpload(TRUE,TransferTime);

      IF (AutoLogOff) THEN
        CountDown
    END;
  END;
END;

PROCEDURE ListBatchDLFiles;
VAR
  FileNumToList: Byte;
  RecNum: LongInt;
BEGIN
  IF (NumBatchDLFiles = 0) THEN
  BEGIN
    NL;
    Print('The batch download queue is empty.');
    Exit;
  END;
  Abort := FALSE;
  Next := FALSE;
  NL;
  PrintACR('^4###:FileName.Ext Area  Pts    Bytes         hh:mm:ss^1');
  PrintACR('^4===:============:=====:======:=============:========^1');
  Assign(BatchDLFile,General.DataPath+'BATCHDL.DAT');
  Reset(BatchDLFile);
  FileNumToList := 1;
  RecNum := 1;
  WHILE (RecNum <= FileSize(BatchDLFile)) AND (NOT Abort) AND (NOT HangUp) DO
  BEGIN
    Seek(BatchDLFile,(RecNum - 1));
    Read(BatchDLFile,BatchDL);
    IF (BatchDL.BDLUserNum = UserNum) THEN
    BEGIN
      PrintACR('^3'+PadRightInt(FileNumToList,3)+
               '^4:^5'+Align(StripName(BatchDL.BDLFileName))+
               ' '+AOnOff((BatchDL.BDLSection = -1),'^7 --- ','^5'+PadRightInt(CompFileArea(BatchDL.BDLSection,0),5))+
               ' ^4'+PadRightStr(FormatNumber(BatchDL.BDLPoints),6)+
               ' ^4'+PadRightStr(FormatNumber(BatchDL.BDLFSize),13)+
               ' ^7'+CTim(BatchDL.BDLTime)+
               AOnOff(IsNoRatio IN BatchDL.BDLFlags,'^5 [No-Ratio]','')+
               AOnOff(IsNoFilePoints IN BatchDL.BDLFlags,'^5 [No-Points]','')+'^1');
      Inc(FileNumToList);
    END;
    WKey;
    Inc(RecNum);
  END;
  Close(BatchDLFile);
  LastError := IOResult;
  PrintACR('^4===:============:=====:======:=============:========^1');
  PrintACR('^3'+PadLeftStr('Totals:',22)+
           ' ^4'+PadRightStr(FormatNumber(BatchDLPoints),6)+
           ' '+PadRightStr(FormatNumber(BatchDLSize),13)+
           ' ^7'+CTim(BatchDLTime)+'^1');
  SysOpLog('Viewed the batch download queue.');
END;

PROCEDURE RemoveBatchDLFiles;
VAR
  InputStr: Str3;
  Counter,
  FileNumToRemove: Byte;
  RecNum,
  RecNum1: LongInt;
BEGIN
  IF (NumBatchDLFiles = 0) THEN
  BEGIN
    NL;
    Print('The batch download queue is empty.');
    Exit;
  END;
  InputStr := '?';
  REPEAT
    IF (InputStr = '?') THEN
      ListBatchDLFiles;
    NL;
    Prt('File to remove? (^51^4-^5'+IntToStr(NumBatchDLFiles)+'^4) [^5?^4=^5List^4,^5<CR>^4=^5Quit^4]: ');
    MPL(Length(IntToStr(NumBatchDLFiles)));
    ScanInput(InputStr,^M'?');
    FileNumToRemove := StrToInt(InputStr);
    IF (NOT (InputStr[1] IN ['?','-',^M])) THEN
      IF (FileNumToRemove < 1) OR (FileNumToRemove > NumBatchDLFiles) THEN
      BEGIN
        NL;
        Print('^7The range must be from 1 to '+IntToStr(NumBatchDLFiles)+'!^1');
        InputStr := '?';
      END
      ELSE
      BEGIN
        Counter := 0;
        Assign(BatchDLFile,General.DataPath+'BATCHDL.DAT');
        Reset(BatchDLFile);
        RecNum := 1;
        WHILE (RecNum <= FileSize(BatchDLFile)) DO
        BEGIN
          Seek(BatchDLFile,(RecNum - 1));
          Read(BatchDLFile,BatchDL);
          IF (BatchDL.BDLUserNum = UserNum) THEN
          BEGIN
            Inc(Counter);
            IF (Counter = FileNumToRemove) THEN
            BEGIN
              Dec(NumBatchDLFiles);
              Dec(BatchDLTime,BatchDL.BDLTime);
              Dec(BatchDLSize,BatchDL.BDLFSize);
              Dec(BatchDLPoints,BatchDL.BDLPoints);
              IF (BatchDL.BDLStorage = Copied) THEN
                Kill(BatchDL.BDLFileName);
              NL;
              Print('Removed from batch download queue: "^5'+StripName(BatchDL.BDLFileName)+'^1".');
              SysOpLog('Batch DL Remove: "^5'+StripName(BatchDL.BDLFileName)+'^1".');
              Dec(RecNum);
              FOR RecNum1 := RecNum TO (FileSize(BatchDLFile) - 2) DO
              BEGIN
                Seek(BatchDLFile,(RecNum1 + 1));
                Read(BatchDLFile,BatchDL);
                Seek(BatchDLFile,RecNum1);
                Write(BatchDLFile,BatchDL);
              END;
              Seek(BatchDLFile,(FileSize(BatchDLFile) - 1));
              Truncate(BatchDLFile);
              RecNum := FileSize(BatchDLFile);
            END;
          END;
          Inc(RecNum);
        END;
        Close(BatchDLFile);
        LastError := IOResult;
        IF (NumBatchDLFiles <> 0) THEN
        BEGIN
          NL;
          Print('^1Batch download queue: ^5'+IntToStr(NumBatchDLFiles)+' '+Plural('file',NumBatchDLFiles)+
                ', '+ConvertBytes(BatchDLSize,FALSE)+
                ', '+FormatNumber(BatchDLPoints)+
                ' '+Plural('file point',BatchDLPoints)+', '+FormattedTime(BatchDLTime));
        END
        ELSE
        BEGIN
          BatchDLTime := 0;
          BatchDLSize := 0;
          BatchDLPoints := 0;
          NL;
          Print('The batch download queue is now empty.');
          SysOpLog('Cleared the batch download queue.');
        END;
      END;
  UNTIL (InputStr <> '?') OR (HangUp);
END;

PROCEDURE ClearBatchDLQueue;
VAR
  RecNum,
  RecNum1: LongInt;
BEGIN
  IF (NumBatchDLFiles = 0) THEN
  BEGIN
    NL;
    Print('The batch download queue is empty.');
    Exit;
  END;
  NL;
  IF PYNQ('Clear batch download queue? ',0,FALSE) THEN
  BEGIN
    NL;
    Assign(BatchDLFile,General.DataPath+'BATCHDL.DAT');
    Reset(BatchDLFile);
    RecNum := 1;
    WHILE (RecNum <= FileSize(BatchDLFile)) DO
    BEGIN
      Seek(BatchDLFile,(RecNum - 1));
      Read(BatchDLFile,BatchDL);
      IF (BatchDL.BDLUserNum = UserNum) THEN
      BEGIN
        Dec(NumBatchDLFiles);
        Dec(BatchDLTime,BatchDL.BDLTime);
        Dec(BatchDLSize,BatchDL.BDLFSize);
        Dec(BatchDLPoints,BatchDL.BDLPoints);
        IF (BatchDL.BDLStorage = Copied) THEN
          Kill(BatchDL.BDLFileName);
        Print('Removed from batch download queue: "^5'+StripName(BatchDL.BDLFileName)+'^1".');
        SysOpLog('Batch DL Remove: "^5'+StripName(BatchDL.BDLFileName)+'^1".');
        Dec(RecNum);
        FOR RecNum1 := RecNum TO (FileSize(BatchDLFile) - 2) DO
        BEGIN
          Seek(BatchDLFile,(RecNum1 + 1));
          Read(BatchDLFile,BatchDL);
          Seek(BatchDLFile,RecNum1);
          Write(BatchDLFile,BatchDL);
        END;
        Seek(BatchDLFile,(FileSize(BatchDLFile) - 1));
        Truncate(BatchDLFile);
      END;
      Inc(RecNum);
    END;
    Close(BatchDLFile);
    LastError := IOResult;
    BatchDLTime := 0;
    BatchDLSize := 0;
    BatchDLPoints := 0;
    NL;
    Print('The batch download queue is now empty.');
    SysOpLog('Cleared the batch download queue.');
  END;
END;

END.
