{$IFDEF WIN32}
{$I DEFINES.INC}
{$ENDIF}

{$A+,B-,D+,E-,F+,I-,L+,N-,O+,R-,S+,V-}

UNIT File8;

INTERFACE

USES
  Dos,
  Common;

PROCEDURE Send(FileInfo: FileInfoRecordType;
               DirFileRecNum: Integer;
               DownloadPath: PathStr;
               VAR TransferFlags: TransferFlagSet);
PROCEDURE Receive(FileName: Str12;
                  UploadPath: PathStr;
                  ResumeFile: Boolean;
                  VAR UploadOk,
                  KeyboardAbort,
                  AddULBatch: Boolean;
                  VAR TransferTime: LongInt);

IMPLEMENTATION

USES
  Crt,
  ExecBat,
  File0,
  File1,
  File2,
  File4,
  File6,
  File12,
  TimeFunc;

{ CheckFileRatio
 1 - File bad
 2 - File + Batch bad
 3 - File Bad - Daily
 4 - File + Batch bad - Daily
}

PROCEDURE CheckFileRatio(FileInfo: FileInfoRecordType; VAR ProtocolNumber: Integer);
VAR
  Counter: Byte;
  RecNum: LongInt;
  FileKBSize: LongInt;
  Ratio: Real;
  BadRatio,
  DailyLimits: Boolean;
BEGIN
  FileKbSize := (FileInfo.FileSize DIV 1024);

  IF (NumBatchDLFiles > 0) THEN
  BEGIN
    Assign(BatchDLFile,General.DataPath+'BATCHDL.DAT');
    Reset(BatchDLFile);
    RecNum := 1;
    WHILE (RecNum <= FileSize(BatchDLFile)) DO
    BEGIN
      Seek(BatchDLFile,(RecNum - 1));
      Read(BatchDLFile,BatchDL);
      IF (BatchDL.BDLUserNum = UserNum) AND (BatchDL.BDLFileName = FileInfo.FileName) THEN
        IF (NOT (IsNoRatio IN BatchDL.BDLFlags)) THEN
          Inc(FileKBSize,(BatchDL.BDLFSize DIV 1024));
      Inc(RecNum);
    END;
    Close(BatchDLFile);
    LastError := IOResult;
  END;

  BadRatio := FALSE;

  IF (ThisUser.UK > 0) THEN
    Ratio := ((FileKbSize + ThisUser.DK) / ThisUser.UK)
  ELSE
    Ratio := (FileKBSize + ThisUser.DK);

  IF (General.DLKRatio[ThisUser.SL] > 0) AND (Ratio > General.DLKRatio[ThisUser.SL]) THEN
    BadRatio := TRUE;

  IF (ThisUser.Uploads > 0) THEN
    Ratio := (((ThisUser.Downloads + NumBatchDLFiles) + 1) / ThisUser.Uploads)
  ELSE
    Ratio := ((ThisUser.Downloads + NumBatchDLFiles) + 1);

  IF (General.DLRatio[ThisUser.SL] > 0) AND (Ratio > General.DLRatio[ThisUser.SL]) THEN
    BadRatio := TRUE;

  IF (NOT General.ULDLRatio) THEN
    BadRatio := FALSE;

  DailyLimits := FALSE;
  IF (General.DailyLimits) THEN
    IF ((ThisUser.DLKToday + FileKbSize) > General.DLKOneDay[ThisUser.SL]) OR
       (((ThisUser.DLToday + NumBatchDLFiles) + 1) > General.DLOneDay[ThisUser.SL]) THEN
    BEGIN
      BadRatio := TRUE;
      DailyLimits := TRUE;
    END;

  IF (AACS(General.NoDLRatio)) OR (FNoDLRatio IN ThisUser.Flags) THEN
    BadRatio := FALSE;

  LoadFileArea(FileArea);
  IF (FANoRatio IN MemFileArea.FAFlags) THEN
    BadRatio := FALSE;

  Counter := 0;

  IF (BadRatio) THEN
    IF (NumBatchDLFiles = 0) THEN
      Counter := 1
    ELSE
      Counter := 2;

  IF (DailyLimits) AND (Counter > 0) THEN
    Inc(Counter,2);

  CASE Counter OF
    1,3 : BEGIN
            IF (Counter = 3) THEN
            BEGIN
              PrintF('DLTMAX');
              IF (NoFile) THEN
              BEGIN
                {
                NL;
                Print('^5Your upload/download ratio is too poor to download this.');
                }
                NL;
                lRGLngStr(27,FALSE);
                NL;
                Print('^1Today you have downloaded '+FormatNumber(ThisUser.DLToday)+' '+Plural('file',ThisUser.DLToday)+
                      '^1 totaling '+FormatNumber(ThisUser.DLKToday)+'k');
                NL;
                Print('^1The maximum you can download in one day is '+FormatNumber(General.DLOneDay[ThisUser.SL])+
                      ' '+Plural('file',General.DLOneDay[ThisUser.SL])+
                      '^1 totaling '+FormatNumber(General.DLKOneDay[ThisUser.SL])+'k');
              END;
            END
            ELSE
            BEGIN
              PrintF('DLMAX');
              IF (NoFile) THEN
              BEGIN
                {
                NL;
                Print('^5Your upload/download ratio is too poor to download this.');
                }
                NL;
                lRGLngStr(27,FALSE);
                NL;
                Print('^5You have downloaded: '+FormatNumber(ThisUser.DK)+'k in '+FormatNumber(ThisUser.Downloads)+
                      ' '+Plural('file',ThisUser.Downloads));
                Print('^5You have uploaded  : '+FormatNumber(ThisUser.UK)+'k in '+FormatNumber(ThisUser.Uploads)+
                      ' '+Plural('file',ThisUser.Uploads));
                NL;
                Print('^5  1 upload for every '+FormatNumber(General.DLRatio[ThisUser.SL])+
                      ' downloads must be maintained.');
                Print('^5  1k must be uploaded for every '+FormatNumber(General.DLKRatio[ThisUser.SL])+'k downloaded.');
              END;
            END;
          END;
    2,4 : BEGIN
            IF (Counter = 4) THEN
              PrintF('DLBTMAX')
            ELSE
              PrintF('DLBMAX');
            IF (NoFile) THEN
            BEGIN
              {
              NL;
              Print('^5Your upload/download ratio is too poor to download this.');
              }
              NL;
              lRGLngStr(27,FALSE);
              NL;
              Print('^5Assuming you download the files already in the batch queue,');
              IF (Counter = 2) THEN
                Print('^5your upload/download ratio would be out of balance.')
              ELSE
                Print('^5you would exceed the maximum download limits for one day.');
            END;
          END;
  END;
  IF (Counter IN [1..4]) THEN
  BEGIN
    SysOpLog('Download refused: Ratio out of balance: '+SQOutSp(FileInfo.FileName));
    SysOpLog(' ULs: '+FormatNumber(ThisUser.UK)+'k in '+FormatNumber(ThisUser.Uploads)+
             ' '+Plural('file',ThisUser.Uploads)+
             ' - DLs: '+FormatNumber(ThisUser.DK)+'k in '+FormatNumber(ThisUser.Downloads)+
             ' '+Plural('file',ThisUser.Downloads));
    ProtocolNumber := -2;
  END;

END;

PROCEDURE BatchDLAdd(FileInfo: FileInfoRecordType; DownloadPath: Str40; TransferFlags: TransferFlagSet);
VAR
  User: UserRecordType;
BEGIN
  IF CheckBatchDL(DownloadPath+FileInfo.FileName) THEN
  BEGIN
    NL;
    Print('^7This file is already in the batch download queue!^1');
  END
  ELSE IF (NumBatchDLFiles = General.MaxBatchDLFiles) THEN
  BEGIN
    NL;
    Print('^7The batch download queue is full!^1');
  END
  ELSE IF ((BatchDLTime + (FileInfo.FileSize DIV Rate)) > NSL) THEN
  BEGIN
    NL;
    Print('^7Insufficient time left online to add to the batch download queue!^1');
  END
  ELSE
  BEGIN

    Assign(BatchDLFile,General.DataPath+'BATCHDL.DAT');
    IF (NOT Exist(General.DataPath+'BATCHDL.DAT')) THEN
      ReWrite(BatchDLFile)
    ELSE
      Reset(BatchDLFile);

    WITH BatchDL DO
    BEGIN

      BDLFileName := SQOutSp(DownloadPath+FileInfo.FileName);

      IF (FileArea <> -1) THEN
        BDLOwnerName := AllCaps(FileInfo.OwnerName)
      ELSE
      BEGIN
        LoadURec(User,1);
        BDLOwnerName := AllCaps(User.Name);
      END;

      IF (IsCDRom IN TransferFlags) THEN
        BDLStorage := CD
      ELSE
        BDLStorage := Disk;

      BDLUserNum := UserNum;

      BDLSection := FileArea;

      IF (FileArea <> -1) THEN
        BDLPoints := FileInfo.FilePoints
      ELSE
        BDLPoints := 0;

      IF (FileArea <> -1) THEN
        BDLUploader := FileInfo.OwnerNum
      ELSE
        BDLUploader := 1;

      BDLFSize := FileInfo.FileSize;

      BDLTime := (FileInfo.FileSize DIV Rate);

      IF (IsFileAttach IN TransferFlags) THEN
        Include(BDLFlags,IsFileAttach)
      ELSE IF (IsUnlisted IN TransferFlags) THEN
        Include(BDLFlags,IsUnlisted)
      ELSE IF (IsTempArc IN TransferFlags) THEN
        Include(BDLFlags,IsTempArc)
      ELSE IF (IsQWK IN TransferFlags) THEN
        Include(BDLFlags,IsQWK);

      IF (NOT ChargeFilePoints(FileArea)) THEN
        Include(BDLFlags,IsNoFilePoints);

      IF (NOT ChargeFileRatio(FileArea)) THEN
        Include(BDLFlags,IsNoRatio);

    END;
    Seek(BatchDLFile,FileSize(BatchDLFile));
    Write(BatchDLFile,BatchDL);
    Close(BatchDLFile);

    Inc(NumBatchDLFiles);

    Inc(BatchDLSize,BatchDL.BDLFSize);

    Inc(BatchDLTime,BatchDL.BDLTime);

    Inc(BatchDLPoints,BatchDL.BDLPoints);

    {
    NL;
    Print('^5File added to batch download queue.');
    }
    lRGLngStr(30,FALSE);
    NL;
    Print('^1Batch download queue:'+
          ' ^5'+IntToStr(NumBatchDLFiles)+' '+Plural('file',NumBatchDLFiles)+
          ', '+ConvertBytes(BatchDLSize,FALSE)+
          ', '+FormatNumber(BatchDLPoints)+' '+Plural('file point',BatchDLPoints)+
          ', '+FormattedTime(BatchDLTime)+'^1');

    IF (IsFileAttach IN BatchDL.BDLFlags) THEN
      MemFileArea.AreaName := 'File Attach'
    ELSE IF (IsUnlisted IN BatchDL.BDLFlags) THEN
      MemFileArea.AreaName := 'Unlisted Download'
    ELSE IF (IsTempArc IN BatchDL.BDLFlags) THEN
      MemFileArea.AreaName := 'Temporary Archive'
    ELSE IF (IsQWK IN BatchDL.BDLFlags) THEN
      MemFileArea.AreaName := 'QWK Download';

    SysOpLog('Batch DL Add: "^5'+StripName(BatchDL.BDLFileName)+
            '^1" from ^5'+MemFileArea.AreaName);
  END;
END;

PROCEDURE Send(FileInfo: FileInfoRecordType;
               DirFileRecNum: Integer;
               DownloadPath: PathStr;
               VAR TransferFlags: TransferFlagSet);
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
  ReturnCode,
  ProtocolNumber: Integer;
  TransferTime: LongInt;
BEGIN
  Exclude(TransferFlags,IsKeyboardAbort);

  Exclude(TransferFlags,IsTransferOk);

  IF (lIsAddDLBatch IN TransferFlags) THEN
    ProtocolNumber := -4
  ELSE
    ProtocolNumber := DoProtocol(Protocol,FALSE,TRUE,FALSE,FALSE);

  IF (IsCheckRatio IN TransferFlags) THEN
    IF (-ProtocolNumber IN [1,4]) OR (NOT (-ProtocolNumber IN [2..3,5])) THEN
      CheckFileRatio(FileInfo,ProtocolNumber);

  CASE ProtocolNumber OF
   -2 : BEGIN
          NL;
          Print('^1Aborted!');
          Include(TransferFlags,IsKeyboardAbort);
        END;
   -3 : BEGIN
          NL;
          Print('^1Skipped!');
        END;
   -4 : BatchDLAdd(FileInfo,DownloadPath,TransferFlags);
   -5 : ;
  ELSE
    IF (InCom) OR (ProtocolNumber = -1) THEN
    BEGIN
      IF (ProtocolNumber = -1) THEN
      BEGIN
        NL;
        Print('^5Caution: ^1No check is made to ensure the file you selected for viewing^1');
        Print('^1         is an ascii text file!');
        NL;
        IF (NOT PYNQ('Continue to view selected file? ',0,FALSE)) THEN
        BEGIN
          Include(TransferFlags,IsKeyboardAbort);
          Exit;
        END;
      END;

      IF (IsCDRom IN TransferFlags) THEN
      BEGIN
        NL;
        Print('Please wait, copying file from CD-ROM ... ');
        IF CopyMoveFile(TRUE,'',DownloadPath+SQOutSp(FileInfo.FileName),TempDir+'CD\'+SQOutSp(FileInfo.FileName),FALSE) THEN
          DownloadPath := TempDir+'CD\';
      END;

      NL;
      IF PYNQ('Auto-logoff after '+AOnOff(ProtocolNumber = -1,'viewing file','file transfer')+'? ',0,FALSE) THEN
        Include(TransferFlags,IsAutoLogOff);

      NL;
      Star('Ready to '+AOnOff(ProtocolNumber = -1,'view','send')+': ^5'+SQOutSp(FileInfo.FileName)+'.');

      ExecProtocol(AOnOff(ProtocolNumber = -1,DownloadPath+SQOutSp(FileInfo.FileName),''),
                   TempDir+'UP\',
                   FunctionalMCI(Protocol.EnvCmd,'','')+
                   #13#10
                   +General.ProtPath+FunctionalMCI(Protocol.DLCmd,DownloadPath+SQOutSp(FileInfo.FileName),''),
                   0,
                   ReturnCode,
                   TransferTime);

      NL;
      Star('File '+AOnOff(ProtocolNumber = -1,'viewing','download')+' complete.');

      IF (ProtocolNumber = -1) THEN
      BEGIN
        IF (ReturnCode = 0) THEN
          Include(TransferFlags,IsTransferOk);
      END
      ELSE
      BEGIN
        IF FindReturnCode(Protocol.DLCode,Protocol.PRFlags,IntToStr(ReturnCode)) THEN
          Include(TransferFlags,IsTransferOk);
      END;

      IF (NOT (IsTransferOk IN TransferFlags)) THEN
      BEGIN
        NL;
        Star(AOnOff(ProtocolNumber = -1,'Text view','Download')+' unsuccessful.');
        SysOpLog('^7'+AOnOff(ProtocolNumber = -1,'Text view','Download')+' failed: "^5'+SQOutSp(FileInfo.FileName)+
                '^7" from ^5'+MemFileArea.AreaName);
        Include(TransferFlags,isPaused);
      END
      ELSE
      BEGIN
        LIL := 0;

        SysOpLog('^3'+AOnOff(ProtocolNumber = -1,'Viewed','Downloaded')+' "^5'+SQOutSp(FileInfo.FileName)+
                 '^3" from ^5'+MemFileArea.AreaName+'.');

        FillChar(Totals,SizeOf(Totals),0);

        Inc(Totals.FilesDL);
        Inc(Totals.BytesDL,FileInfo.FileSize);
        Inc(Totals.PointsDL,FileInfo.FilePoints);

        IF (ChargeFileRatio(FileArea)) THEN
        BEGIN
          Inc(Totals.FilesDLRatio);
          Inc(Totals.BytesDLRatio,FileInfo.FileSize);
        END;

        IF (ChargeFilePoints(FileArea)) THEN
          Inc(Totals.PointsDLRatio,FileInfo.FilePoints);

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

        IF ((DownloadsToday + Totals.FilesDL) < 2147483647) THEN
          Inc(DownloadsToday,Totals.FilesDL)
        ELSE
          DownloadsToday := 2147483647;

        IF ((DownloadKBytesToday + (Totals.BytesDL DIV 1024)) < 2147483647) THEN
          Inc(DownloadKBytesToday,(Totals.BytesDL DIV 1024))
        ELSE
          DownloadKBytesToday := 2147483647;

        SaveURec(ThisUser,UserNum);

        LIL := 0;

        NL;
        Print('^5Download statistics (Totals):^1');
        NL;
        Star('File name         : ^5'+SQOutSp(FileInfo.FileName));
        Star('File size         : ^5'+ConvertBytes(Totals.BytesDL,FALSE));
        Star('File point(s)     : ^5'+FormatNumber(Totals.PointsDL));
        Star(AOnOff(ProtocolNumber = -1,'View time         ','Download time     ')+': ^5'+FormattedTime(TransferTime));
        Star('Transfer rate     : ^5'+FormatNumber(GetCPS(FileInfo.FileSize,Transfertime))+' cps');

        SysOpLog('^3 - Totals:'+
                 ' '+FormatNumber(Totals.FilesDL)+' '+Plural('file',Totals.FilesDL)+
                 ', '+ConvertBytes(Totals.BytesDL,FALSE)+
                 ', '+FormatNumber(Totals.PointsDL)+' fp'+
                 ', '+FormattedTime(TransferTime)+
                 ', '+FormatNumber(GetCPS(Totals.BytesDL,Transfertime))+' cps.');
        LIL := 0;

        NL;
        Print('^5Download statistics (Charges):^1');
        NL;
        Star('File(s)           : ^5'+FormatNumber(Totals.FilesDLRatio));
        Star('File size         : ^5'+ConvertBytes(Totals.BytesDLRatio,FALSE));
        Star('File point(s)     : ^5'+FormatNumber(Totals.PointsDLRatio));

        SysOpLog('^3 - Charges:'+
                 ' '+FormatNumber(Totals.FilesDLRatio)+' '+Plural('file',Totals.FilesDLRatio)+
                 ', '+ConvertBytes(Totals.BytesDLRatio,FALSE)+
                 ', '+FormatNumber(Totals.PointsDLRatio)+' fp.');

        CreditUploader(FileInfo);

        IF (DirFileRecNum <> -1) THEN
        BEGIN
          Inc(FileInfo.Downloaded);
          Seek(FileInfoFile,DirFileRecNum);
          Write(FileInfoFile,FileInfo);
          LastError := IOResult;
        END;

        LIL := 0;

        NL;
        Print('^5Enjoy the file, '+Caps(ThisUser.Name)+'!^1');
        PauseScr(FALSE);

      END;

      IF (ProtBiDirectional IN Protocol.PRFlags) AND (NOT OfflineMail) THEN
        BatchUpload(TRUE,0);

      IF (IsAutoLogoff IN TransferFlags) THEN
        CountDown
    END;
  END;
END;

PROCEDURE Receive(FileName: Str12;
                  UploadPath: PathStr;
                  ResumeFile: Boolean;
                  VAR UploadOk,
                  KeyboardAbort,
                  AddULBatch: Boolean;
                  VAR TransferTime: LongInt);
VAR
  ReturnCode,
  ProtocolNumber: Integer;
BEGIN
  UploadOk := TRUE;

  KeyboardAbort := FALSE;

  TransferTime := 0;

  ProtocolNumber := DoProtocol(Protocol,TRUE,FALSE,FALSE,ResumeFile);

  CASE ProtocolNumber OF
    -1 : UploadOk := FALSE;
    -2 : BEGIN
           UploadOk := FALSE;
           KeyboardAbort := TRUE;
         END;
    -3 : BEGIN
           UploadOk := FALSE;
           KeyboardAbort := TRUE;
         END;
    -4 : AddULBatch := TRUE;
    -5 : UploadOk := FALSE;
  ELSE
    IF (NOT InCom) THEN
      UploadOk := FALSE
    ELSE
    BEGIN

      PurgeDir(TempDir+'UP\',FALSE);

      NL;
      Star('Ready to receive: ^5'+SQOutSp(FileName)+'.');

      TimeLock := TRUE;

      ExecProtocol('',
                   UploadPath,
                   FunctionalMCI(Protocol.EnvCmd,'','')+
                   #13#10+
                   General.ProtPath+FunctionalMCI(Protocol.ULCmd,SQOutSp(FileName),''),
                   0,
                   ReturnCode,
                   TransferTime);

      TimeLock := FALSE;

      NL;
      Star('File upload complete.');

      UploadOk := FindReturnCode(Protocol.ULCode,Protocol.PRFlags,IntToStr(ReturnCode));
    END;
  END;
END;

END.
