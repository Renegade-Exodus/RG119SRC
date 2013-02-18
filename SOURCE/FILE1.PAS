{$IFDEF WIN32}
{$I DEFINES.INC}
{$ENDIF}

{$A+,B-,D+,E-,F+,I-,L+,N-,O+,R-,S+,V-}

UNIT File1;

INTERFACE

USES
  Common;

FUNCTION ChargeFilePoints(FArea: Integer): Boolean;
FUNCTION ChargeFileRatio(FArea: Integer): Boolean;
PROCEDURE CreditUploader(FileInfo: FileInfoRecordType);
FUNCTION SearchForDups(CONST CompleteFN: Str12): Boolean;
FUNCTION DizExists(CONST FN: AStr): Boolean;
PROCEDURE GetDiz(VAR FileInfo: FileInfoRecordType; VAR ExtendedArray: ExtendedDescriptionArray; VAR NumExtDesc: Byte);
PROCEDURE DLX(FileInfo: FileInfoRecordType;
              DirFileRecNum: Integer;
              VAR TransferFlags: TransferFlagSet);
FUNCTION DLInTime: BOOLEAN;
FUNCTION BatchDLQueuedFiles(TransferFlags: TransferFlagSet): BOOLEAN;
PROCEDURE DL(CONST FileName: Str12; TransferFlags: TransferFlagSet);
PROCEDURE GetFileDescription(VAR FileInfo: FileInfoRecordType; VAR ExtendedArray: ExtendedDescriptionArray;
                             VAR NumExtDesc: Byte; VAR ToSysOp: Boolean);
PROCEDURE WriteFV(FileInfo: FileInfoRecordType;DirFileRecNum: Integer; ExtendedArray: ExtendedDescriptionArray);
PROCEDURE UpdateFileInfo(VAR FileInfo: FileInfoRecordType; CONST FN: Str12; VAR GotPts: Integer);
PROCEDURE ArcStuff(VAR Ok,Convt: Boolean; VAR FSize,ConvTime: LongInt;
                   ITest: Boolean; CONST FilePath: AStr; VAR FileName: Str12; VAR Descr: AStr);
PROCEDURE DownloadFile(FileName: Str12; TransferFlags: TransferFlagSet);
PROCEDURE UploadFile;
PROCEDURE LFileAreaList(VAR FArea,NumFAreas: Integer; AdjPageLen: Byte; ShowScan: Boolean);
PROCEDURE UnlistedDownload(FileName: AStr);
PROCEDURE Do_Unlisted_Download;

IMPLEMENTATION

USES
  Dos,
  Crt,
  Archive1,
  Email,
  Events,
  File0,
  File2,
  File6,
  File8,
  File11,
  File12,
  File14,
  MultNode,
  ShortMsg,
  TimeFunc;

FUNCTION ChargeFilePoints(FArea: Integer): Boolean;
VAR
  ChargePoints: Boolean;
BEGIN
  ChargePoints := FALSE;
  IF (FArea <> -1) AND
     (NOT (FANoRatio IN MemFileArea.FAFlags)) AND
     (NOT AACS(General.NoFileCredits)) AND
     (NOT (FNoCredits IN ThisUser.Flags)) AND
     (General.FileCreditRatio) THEN
    ChargePoints := TRUE;
  ChargeFilePoints := ChargePoints;
END;

FUNCTION ChargeFileRatio(FArea: Integer): Boolean;
VAR
  ChargeRatio: Boolean;
BEGIN
  ChargeRatio := FALSE;
  IF (FArea <> -1) AND
     (NOT (FANoRatio IN MemFileArea.FAFlags)) AND
     (NOT AACS(General.NoDLRatio)) AND
     (NOT (FNoDLRatio IN ThisUser.Flags)) AND
     (General.ULDLRatio) THEN
    ChargeRatio := TRUE;
  ChargeFileRatio := ChargeRatio;
END;

PROCEDURE CreditUploader(FileInfo: FileInfoRecordType);
VAR
  User: UserRecordType;
  FilePointCredit: LongInt;
BEGIN
  IF (General.RewardSystem) AND (FileInfo.OwnerNum >= 1) AND (FileInfo.OwnerNum <= (MaxUsers - 1)) AND
     (FileInfo.OwnerNum <> UserNum) THEN
  BEGIN
    LoadURec(User,FileInfo.OwnerNum);
    FilePointCredit := Trunc(FileInfo.FilePoints * (General.RewardRatio DIV 100));
    IF (CRC32(FileInfo.OwnerName) = CRC32(User.Name)) AND (FilePointCredit > 0) THEN
    BEGIN
      IF ((User.FilePoints + FilePointCredit) < 2147483647) THEN
        Inc(User.FilePoints,FilePointCredit)
      ELSE
        User.FilePoints := 2147483647;
      SaveURec(User,FileInfo.OwnerNum);
      SysOpLog('^3 - Credits: '+FormatNumber(FilePointCredit)+' fp to "^5'+Caps(User.Name)+'^3".');
      SendShortMessage(FileInfo.OwnerNum,'You received '+FormatNumber(FilePointCredit)+
                       ' '+Plural('file point',FilePointCredit)+' for the download of '
                       +SQOutSp(FileInfo.FileName));
    END;
  END;
END;

FUNCTION OKDL(CONST FileInfo: FileInfoRecordType): Boolean;
VAR
  MHeader: MHeaderRec;
  Counter: Byte;
BEGIN
  OKDL := TRUE;
  IF (FIIsRequest IN FileInfo.FIFlags) THEN
  BEGIN
    PrintF('REQFILE');
    IF (NoFile) THEN
    BEGIN
      NL;
      Print('^5You must request this from '+General.SysOpName+'!^1');
    END;
    NL;
    IF (PYNQ('Request this file now? ',0,FALSE)) THEN
    BEGIN
      InResponseTo := #1'Request "'+SQOutSp(FileInfo.FileName)+'" from area #'+IntToStr(CompFileArea(FileArea,0));
      MHeader.Status := [];
      SEMail(1,MHeader);
    END;
    OKDL := FALSE;
  END
  ELSE IF (FIResumeLater IN FileInfo.FIFlags) AND (NOT FileSysOp) THEN
  BEGIN
    NL;
    Print('^7You are not the uploader of this file!^1');
    OKDL := FALSE;
  END
  ELSE IF (FINotVal IN FileInfo.FIFlags) AND (NOT AACS(General.DLUNVal)) THEN
  BEGIN
    NL;
    Print('^7Your access level does not permit downloading unvalidated files!^1');
    OKDL := FALSE;
  END
  ELSE IF (FileInfo.FilePoints > 0) AND (ThisUser.FilePoints < FileInfo.FilePoints) AND
     ChargeFilePoints(FileArea) THEN
  BEGIN
    NL;
    Print('^7'+lRGLngStr(26,TRUE)+'^1'{FString.NoFileCredits});
    OKDL := FALSE;
  END
  ELSE IF ((FileInfo.FileSize DIV Rate) > NSL) THEN
  BEGIN
    NL;
    Print('^7Insufficient time left online to download this file!^1');
    Print(Ctim(NSL));
    OKDL := FALSE;
  END;
END;

PROCEDURE DLX(FileInfo: FileInfoRecordType;
              DirFileRecNum: Integer;
              VAR TransferFlags: TransferFlagSet);
VAR
  DownloadPath: Str52;
  CopyPath: Str40;
  Cmd: Char;
  Changed: Boolean;
BEGIN
  Abort := FALSE;
  Next := FALSE;
  IF (IsFileAttach IN TransferFlags) THEN
  BEGIN
    NL;
    Print('^4The following has been attached:^1');
  END;
  NL;
  DisplayFileInfo(FileInfo,FALSE);
  IF (IsFileAttach IN TransferFlags) THEN
    IF (InCom) THEN
    BEGIN
      NL;
      IF (NOT PYNQ('Download file now? ',0,FALSE)) THEN
        Exit;
    END
    ELSE IF (NOT CoSysOp) THEN
      Exit
    ELSE
    BEGIN
      NL;
      IF (NOT PYNQ('Move file now? ',0,FALSE)) THEN
        Exit;
    END;

  IF (NOT OKDL(FileInfo)) THEN
    Include(TransferFlags,IsPaused)
  ELSE
  BEGIN

    DownloadPath := '';

    IF (Exist(MemFileArea.DLPath+FileInfo.FileName)) THEN
    BEGIN
      DownloadPath := MemFileArea.DLPath;
      IF (FACDRom IN MemFileArea.FAFlags) THEN
        InClude(TransferFLags,IsCDRom);
    END
    ELSE IF (Exist(MemFileArea.ULPath+FileInfo.FileName)) THEN
      DownloadPath := MemFileArea.ULPath;

    IF (DownloadPath = '') THEN
    BEGIN
      NL;
      Print('^7File does not actually exist.^1');
      SysOpLog('File missing: '+SQOutSp(DownloadPath+FileInfo.FileName));
      Exit;
    END;
    IF (InCom) THEN
      Send(FileInfo,DirFileRecNum,DownloadPath,TransferFlags)
    ELSE IF (NOT CoSysOp) THEN
      Include(TransferFlags,IsPaused)
    ELSE
    BEGIN
      CopyPath := '';
      InputPath('%LF^4Enter the destination path (^5End with a ^4"^5\^4"):%LF^4:',CopyPath,FALSE,TRUE,Changed);
      IF (CopyPath = '') THEN
        Include(TransferFlags,IsPaused)
      ELSE
      BEGIN
        NL;
        IF (NOT CopyMoveFile(NOT (IsFileAttach IN TransferFlags),
                             +AOnOff(IsFileAttach IN TransferFlags,'^1Moving ... ','^1Copying ... '),
                             DownloadPath+SQOutSp(FileInfo.FileName),
                             CopyPath+SQOutSp(FileInfo.FileName),TRUE)) THEN
        Include(TransferFlags,IsPaused);
      END;
    END;
  END;
  IF (IsPaused IN TransferFlags) AND (NOT (IsFileAttach IN TransferFlags)) THEN
  BEGIN
    NL;
    Prompt('^1Press [^5Enter^1] to Continue or [^5Q^1]uit: ');
    Onek(Cmd,'Q'^M,TRUE,TRUE);
    IF (Cmd = 'Q') THEN
    BEGIN
      Include(TransferFlags,IsKeyboardAbort);
      Abort := TRUE;
    END;
  END;
  IF (IsPaused IN TransferFLags) THEN
    Exclude(TransferFlags,IsPaused);
END;

PROCEDURE DL(CONST FileName: Str12; TransferFlags: TransferFlagSet);
VAR
  SaveFileArea,
  FArea: Integer;
  GotAny,
  Junk: Boolean;

  FUNCTION ScanBase(FileName1: Str12; VAR GotAny1: Boolean): Boolean;
  VAR
    DirFileRecNum: Integer;
  BEGIN
    ScanBase := FALSE;
    RecNo(FileInfo,FileName1,DirFileRecNum);
    IF (BadDownloadPath) THEN
      Exit;
    WHILE (DirFileRecNum <> -1) AND (NOT Abort) AND (NOT HangUp) DO
    BEGIN
      Seek(FileInfoFile,DirFileRecNum);
      Read(FileInfoFile,FileInfo);
      BackErase(13);
      IF (NOT (FINotVal IN FileInfo.FIFlags)) OR (AACS(General.DLUnVal)) THEN
        IF AACS(MemFileArea.DLACS) THEN
        BEGIN
          DLX(FileInfo,DirFileRecNum,TransferFlags);
          ScanBase := TRUE;
          IF (IsKeyboardAbort IN TransferFlags) THEN
            Abort := TRUE;
          IF (NOT (IsWildCard(FileName1))) THEN
            Abort := TRUE;
        END
        ELSE
        BEGIN
          NL;
          Print('Your access level does not permit downloading this file.');
        END;
      GotAny1 := TRUE;
      WKey;
      NRecNo(FileInfo,DirFileRecNum);
    END;
    Close(FileInfoFile);
    Close(ExtInfoFile);
    LastError := IOResult;
  END;

BEGIN
  GotAny := FALSE;
  Abort := FALSE;
  Next := FALSE;

  Include(TransferFlags,IsCheckRatio);

  NL;
  Prompt('Searching ...');

  IF (NOT ScanBase(FileName,GotAny)) THEN
  BEGIN
    SaveFileArea := FileArea;
    FArea := 1;
    WHILE (FArea >= 1) AND (FArea <= NumFileAreas) AND (NOT Abort) AND (NOT HangUp) DO
    BEGIN
      IF (FArea <> SaveFileArea) THEN
      BEGIN
        LoadFileArea(FArea);
        IF (MemFileArea.Password = '') THEN  (* Doesn't scan areas with a Password ??? *)
          ChangeFileArea(FArea);
        IF (FileArea = FArea) THEN
          Junk := ScanBase(FileName,GotAny);
      END;
      WKey;
      Inc(FArea);
    END;
    FileArea := SaveFileArea;
    LoadFileArea(FileArea);
  END;
  IF (NOT GotAny) THEN
  BEGIN
    BackErase(13);
    NL;
    Print('File not found.');
  END;
END;

FUNCTION DLInTime: BOOLEAN;
VAR
  DLAllowed: BOOLEAN;
BEGIN
  DLAllowed := TRUE;

  IF (NOT InTime(Timer,General.DLLowTime,General.DLHiTime)) THEN
    DLAllowed := FALSE;

  IF (ComPortSpeed < General.MinimumDLBaud) THEN
    IF (NOT InTime(Timer,General.MinBaudDLLowTime,General.MinBaudDLHiTime)) THEN
      DLAllowed := FALSE;

  IF (NOT DLAllowed) THEN
  BEGIN
    NL;
    PrintF('DLHOURS');
    IF (NoFile) THEN
      Print('File downloading is not allowed at this time.');
  END;
  DLInTime := DLAllowed;
END;

FUNCTION BatchDLQueuedFiles(TransferFlags: TransferFlagSet): BOOLEAN;
VAR
  DLBatch: BOOLEAN;
BEGIN
  DLBatch := FALSE;
  IF (NOT (lIsAddDLBatch IN TransferFLags)) AND (NumBatchDLFiles > 0) THEN
  BEGIN
    NL;
    IF (PYNQ('Batch download queued files? ',0,FALSE)) THEN
    BEGIN
      BatchDownload;
      DLBatch := TRUE;
    END;
  END;
  BatchDLQueuedFiles := DLBatch;
END;

PROCEDURE DownloadFile(FileName: Str12; TransferFlags: TransferFlagSet);
BEGIN
  IF (DLInTime) THEN
    IF (NOT BatchDLQueuedFiles(TransferFlags)) THEN
    BEGIN
      IF (FileName = '') THEN
      BEGIN
        PrintF('DLOAD');
        IF (NOT (lIsAddDLBatch IN TransferFlags)) THEN
          {
          NL;
          Print(FString.downloadline)
          NL;
          Prt('File name: ');
          }
          lRGLngStr(23,FALSE)
        ELSE
          {
          NL;
          Print(FString.AddDLBatch);
          NL;
          Prt('File name: ');
          }
          lRGLngStr(31,FALSE);
        MPL(12);
        Input(FileName,12);
        IF (FileName = '') THEN
        BEGIN
          NL;
          Print('Aborted.');
        END;
      END;
      IF (FileName <> '') THEN
      BEGIN
        IF (Pos('.',FileName) = 0) THEN
          FileName := FileName+'.*';
        DL(FileName,TransferFlags);
      END
    END;
END;

PROCEDURE GetFileDescription(VAR FileInfo: FileInfoRecordType; VAR ExtendedArray: ExtendedDescriptionArray;
                             VAR NumExtDesc: Byte; VAR ToSysOp: Boolean);
VAR
  MaxLen: Byte;
BEGIN
  NL;
  IF ((ToSysOp) AND (General.ToSysOpDir >= 1) AND (General.ToSysOpDir <= NumFileAreas)) THEN
    Print('Begin description with (/) to make upload "Private".')
  ELSE
    ToSysOp := FALSE;
  LoadFileArea(FileArea);
  IF ((FAUseGIFSpecs IN MemFileArea.FAFlags) AND ISGifExt(FileInfo.FileName)) THEN
  BEGIN
    Print('Enter your text. Press <^5Enter^1> alone to end. (31 chars/line 1, 50 chars/line 2-'+IntToStr(MaxExtDesc + 1)+')');
    MaxLen := 31;
  END
  ELSE
  BEGIN
    Print('Enter your text. Press <^5Enter^1> alone to end. (50 chars/line 1-'+IntToStr(MaxExtDesc + 1)+')');
    MaxLen := 50;
  END;
  REPEAT
    Prt(': ');
    MPL(MaxLen);
    InputWC(FileInfo.Description,MaxLen);
    IF ((FileInfo.Description[1] = '/') OR (RValidate IN ThisUser.Flags)) AND (ToSysOp) THEN
    BEGIN
      IF (General.ToSysOpDir >= 1) AND (General.ToSysOpDir <= NumFileAreas) THEN
        FileArea := General.ToSysOpDir;
      InitFileArea(FileArea);
      ToSysOp := TRUE;
    END
    ELSE
      ToSysOp := FALSE;
    IF (FileInfo.Description[1] = '/') THEN
      Delete(FileInfo.Description,1,1);
  UNTIL ((FileInfo.Description <> '') OR (FileSysOp) OR (HangUp));
  FillChar(ExtendedArray,SizeOf(ExtendedArray),0);
  NumExtDesc := 0;
  REPEAT
    Inc(NumExtDesc);
    Prt(': ');
    MPL(50);
    InputL(ExtendedArray[NumExtDesc],50);
  UNTIL (ExtendedArray[NumExtDesc] = '') OR (NumExtDesc = MaxExtDesc) OR (HangUp);
END;

FUNCTION DizExists(CONST FN: AStr): Boolean;
VAR
  Ok: Boolean;
BEGIN
  DizExists := FALSE;
  IF (ArcType(FN) > 0) THEN
  BEGIN
    Star('Checking for description...'#29);
    ArcDecomp(Ok,ArcType(FN),FN,'FILE_ID.DIZ DESC.SDI');
    IF (Ok) AND (Exist(TempDir+'ARC\FILE_ID.DIZ') OR (Exist(TempDir+'ARC\DESC.SDI'))) THEN
      DizExists := TRUE;
    NL;
  END;
END;

PROCEDURE GetDiz(VAR FileInfo: FileInfoRecordType; VAR ExtendedArray: ExtendedDescriptionArray; VAR NumExtDesc: Byte);
VAR
  DizFile: Text;
  TempStr: Str50;
  Counter: Byte;
BEGIN
  IF (Exist(TempDir+'ARC\FILE_ID.DIZ')) THEN
    Assign(DizFile,TempDir+'ARC\FILE_ID.DIZ')
  ELSE
    Assign(DizFile,TempDir+'ARC\DESC.SDI');
  Reset(DizFile);
  IF (IOResult <> 0) THEN
    Exit;
  Star('Importing description.');
  FillChar(ExtendedArray,SizeOf(ExtendedArray),0);
  Counter := 1;
  WHILE NOT EOF(DizFile) AND (Counter <= (MaxExtDesc + 1)) DO
  BEGIN
    ReadLn(DizFile,TempStr);
    IF (TempStr = '') THEN
      TempStr := ' ';
    IF (Counter = 1) THEN
      FileInfo.Description := TempStr
    ELSE
      ExtendedArray[Counter - 1] := TempStr;
    Inc(Counter);
  END;
  NumExtDesc := MaxExtDesc;
  WHILE (NumExtDesc >= 1) AND ((ExtendedArray[NumExtDesc] = ' ') OR (ExtendedArray[NumExtDesc] = '')) DO
  BEGIN
    ExtendedArray[NumExtDesc] := '';
    Dec(NumExtDesc);
  END;
  Close(DizFile);
  Erase(DizFile);
  LastError := IOResult;
END;

PROCEDURE WriteFV(FileInfo: FileInfoRecordType; DirFileRecNum: Integer; ExtendedArray: ExtendedDescriptionArray);
VAR
  LineNum: Byte;
  VFO: Boolean;
BEGIN
  FileInfo.VTextSize := 0;
  IF (ExtendedArray[1] = '') THEN
    FileInfo.VPointer := -1
  ELSE
  BEGIN
    VFO := (FileRec(ExtInfoFile).Mode <> FMClosed);
    IF (NOT VFO) THEN
      Reset(ExtInfoFile,1);
    IF (IOResult = 0) THEN
    BEGIN
      FileInfo.VPointer := (FileSize(ExtInfoFile) + 1);
      Seek(ExtInfoFile,FileSize(ExtInfoFile));
      FOR LineNum := 1 TO MaxExtDesc DO
        IF (ExtendedArray[LineNum] <> '') THEN
        BEGIN
          Inc(FileInfo.VTextSize,(Length(ExtendedArray[LineNum]) + 1));
          BlockWrite(ExtInfoFile,ExtendedArray[LineNum],(Length(ExtendedArray[LineNum]) + 1));
        END;
      IF (NOT VFO) THEN
        Close(ExtInfoFile);
    END;
  END;
  Seek(FileInfoFile,DirFileRecNum);
  Write(FileInfoFile,FileInfo);
  LastError := IOResult;
END;

PROCEDURE UpdateFileInfo(VAR FileInfo: FileInfoRecordType; CONST FN: Str12; VAR GotPts: Integer);
BEGIN
  WITH FileInfo DO
  BEGIN
    FileName := Align(FN);
    Downloaded := 0;
    OwnerNum := UserNum;
    OwnerName := AllCaps(ThisUser.Name);
    FileDate := Date2PD(DateStr);
    IF (NOT General.FileCreditRatio) THEN
    BEGIN
      FilePoints := 0;
      GotPts := 0;
    END
    ELSE
    BEGIN
      FilePoints := 0;
      IF (General.FileCreditCompBaseSize > 0) THEN
        FilePoints := ((FileSize DIV 1024) DIV General.FileCreditCompBaseSize);
      GotPts := (FilePoints * General.FileCreditComp);
      IF (GotPts < 1) THEN
        GotPts := 1;
    END;
    FIFlags := [];

    IF (NOT AACS(General.ULValReq)) AND (NOT General.ValidateAllFiles) THEN
      Include(FIFlags,FINotVal);

  END;
END;

(*
OldArcType : current archive format, 0 IF none
NewArcType : desired archive format, 0 IF none
OldFileName : current FileName
NewFileName : desired archive format FileName
*)

PROCEDURE ArcStuff(VAR Ok,
                   Convt: Boolean;    { IF Ok - IF converted }
                   VAR FSize,	      { file size }
                   ConvTime: LongInt; { convert time  }
                   ITest: Boolean;    { whether to test integrity  }
                   CONST FilePath: AStr; { filepath  }
                   VAR FileName: Str12;      { FileName  }
                   VAR Descr: AStr);  { Description  }
VAR
  OldFileName,
  NewFileName: AStr;
  OldArcType,
  NewArcType: Byte;
BEGIN
  Ok := TRUE;

  ConvTime := 0;

  FSize := GetFileSize(FilePath+FileName);

  IF (NOT General.TestUploads) THEN
    Exit;

  OldFileName := SQOutSp(FilePath+FileName);

  OldArcType := ArcType(OldFileName);

  NewArcType := MemFileArea.ArcType;

  IF (NOT General.FileArcInfo[NewArcType].Active) OR
     (General.FileArcInfo[NewArcType].Ext = '') THEN
  BEGIN
    NewArcType := 0;
    NewArcType := OldArcType;
  END;


  IF ((OldArcType <> 0) AND (NewArcType <> 0)) THEN
  BEGIN


    NewFileName := FileName;

    IF (Pos('.',NewFileName) <> 0) THEN
      NewFileName := Copy(NewFileName,1,(Pos('.',NewFileName) - 1));

    NewFileName := SQOutSp(FilePath+NewFileName+'.'+General.FileArcInfo[NewArcType].Ext);

    IF ((ITest) AND (General.FileArcInfo[OldArcType].TestLine <> '')) THEN
    BEGIN
      NL;
      Star('Testing file integrity ... '#29);
      ArcIntegrityTest(Ok,OldArcType,OldFileName);
      IF (NOT Ok) THEN
      BEGIN
        SysOpLog('^5 '+OldFileName+' on #'+IntToStr(FileArea)+': errors in integrity test');
        Print('^3failed.');
      END
      ELSE
        Print('^3passed.');
    END;

    IF (Ok) AND ((OldArcType <> NewArcType) OR General.Recompress) AND (NewArcType <> 0) THEN
    BEGIN
      Convt := InCom; 	{* don't convert IF local AND non-file-SysOp *}

      IF (FileSysOp) THEN
      BEGIN
        IF (OldArcType = NewArcType) THEN
          Convt := PYNQ('Recompress this file? ',0,TRUE)
        ELSE
          Convt := PYNQ('Convert archive to .'+General.FileArcInfo[NewArcType].Ext+' format? ',0,TRUE);
      END;

      IF (Convt) THEN
      BEGIN
        NL;

        ConvTime := GetPackDateTime;

        ConvA(Ok,OldArcType,NewArcType,OldFileName,NewFileName);

        ConvTime := (GetPackDateTime - ConvTime);

        IF (Ok) THEN
        BEGIN

          IF (OldArcType <> NewArcType) THEN
            Kill(FilePath+FileName);

          FSize := GetFileSize(NewFileName);

          IF (FSize = -1) OR (FSize = 0) THEN
            Ok := FALSE;

          FileName := Align(StripName(NewFileName));
          Star('No errors in conversion, file passed.');
        END
        ELSE
        BEGIN
          IF (OldArcType <> NewArcType) THEN
            Kill(NewFileName);
          SysOpLog('^5 '+OldFileName+' on #'+IntToStr(FileArea)+': Conversion unsuccessful');
          Star('errors in conversion!  Original format retained.');
          NewArcType := OldArcType;
        END;
        Ok := TRUE;
      END
      ELSE
        NewArcType := OldArcType;
    END;

    IF (Ok) AND (General.FileArcInfo[NewArcType].CmtLine <> '') THEN
    BEGIN
      ArcComment(Ok,NewArcType,MemFileArea.CmtType,SQOutSp(FilePath+FileName));
      Ok := TRUE;
    END;

  END;

  FileName := SQOutSp(FileName);

  IF (FAUseGIFSpecs IN MemFileArea.FAFlags) AND (IsGifExt(FileName)) THEN
    Descr := GetGIFSpecs(FilePath+FileName,Descr,2);

END;

FUNCTION SearchForDups(CONST CompleteFN: Str12): Boolean;
VAR
  WildFN,
  NearFN: Str12;
  SaveFileArea,
  FArea,
  FArrayRecNum: Integer;
  AnyFound,
  HadACC,
  Thisboard,
  CompleteMatch,
  NearMatch: Boolean;

  PROCEDURE SearchB(FArea1: Integer; VAR FArrayRecNum: Integer; CONST FN: Str12; VAR HadACC: Boolean);
  VAR
    DirFileRecNum: Integer;
  BEGIN
    HadACC := FileAreaAC(FArea1);
    IF (NOT HadACC) OR (FANoDupeCheck IN MemFileArea.FAFlags) AND (NOT (FileArea = FArea1)) THEN
      Exit;
    FileArea := FArea1;
    RecNo(FileInfo,FN,DirFileRecNum);
    IF (BadDownloadPath) THEN
      Exit;
    WHILE (DirFileRecNum <> -1) DO
    BEGIN
      IF (NOT AnyFound) THEN
      BEGIN
        NL;
        NL;
        AnyFound := TRUE;
      END;
      Seek(FileInfoFile,DirFileRecNum);
      Read(FileInfoFile,FileInfo);
      IF (CanSee(FileInfo)) THEN
      BEGIN
        WITH FArray[FArrayRecNum] DO
        BEGIN
          FArrayFileArea := FileArea;
          FArrayDirFileRecNum := DirFileRecNum;
        END;
        LDisplay_File(FileInfo,FArrayRecNum,'',TRUE);
        Inc(FArrayRecNum);
        IF (FArrayRecNum = 100) THEN
          FArrayRecNum := 0;
      END;
      IF (Align(FileInfo.FileName) = Align(CompleteFN)) THEN
      BEGIN
        CompleteMatch := TRUE;
        ThisBoard := TRUE;
      END
      ELSE
      BEGIN
        NearFN := Align(FileInfo.FileName);
        NearMatch := TRUE;
        ThisBoard := TRUE;
      END;
      NRecNo(FileInfo,DirFileRecNum);
    END;
    Close(FileInfoFile);
    Close(ExtInfoFile);
    FileArea := SaveFileArea;
    InitFileArea(FileArea);
    LastError := IOResult;
  END;

BEGIN
  SaveFileArea := FileArea;
  InitFArray(FArray);
  FArrayRecNum := 0;
  AnyFound := FALSE;
  Prompt('^5Searching for possible duplicates ... ');
  SearchForDups := TRUE;
  IF (Pos('.',CompleteFN) > 0) THEN
    WildFN := Copy(CompleteFN,1,Pos('.',CompleteFN) - 1)
  ELSE
    WildFN := CompleteFN;
  WildFn := SQOutSp(WildFN);
  WHILE (WildFN[Length(WildFN)] IN ['0'..'9']) AND (Length(WildFN) > 2) DO
    Dec(WildFN[0]);
  WHILE (Length(WildFN) < 8) DO
    WildFN := WildFN + '?';
  WildFN := WildFN + '.???';
  CompleteMatch := FALSE;
  NearMatch := FALSE;
  FArea := 1;
  WHILE (FArea >= 1) AND (FArea <= NumFileAreas) AND (NOT HangUp) DO
  BEGIN
    Thisboard := FALSE;
    SearchB(FArea,FArrayRecNum,WildFN,HadACC);
    LoadFileArea(FArea);
    IF (CompleteMatch) THEN
    BEGIN
      SysOpLog('User tried to upload '+SQOutSp(CompleteFN)+' to #'+IntToStr(SaveFileArea)+
           '; existed in #'+IntToStr(FArea)+AOnOff(NOT HadACC,' - no access',''));
      NL;
      NL;
      IF (HadACC) THEN
        Print('^5File "'+SQOutSp(CompleteFN)+'" already exists in "'+MemFileArea.AreaName+'^5 #'+IntToStr(FArea)+'".')
      ELSE
        Print('^5File "'+SQOutSp(CompleteFN)+ 'cannot be accepted by the system at this time.');
      Print('^7Illegal File Name.');
      Exit;
    END
    ELSE IF (NearMatch) AND (Thisboard) THEN
    BEGIN
      SysOpLog('User entered upload file name "'+SQOutSp(CompleteFN)+'" in #'+
           IntToStr(FileArea)+'; was warned that "'+SQOutSp(NearFN)+
           '" existed in #'+IntToStr(FArea)+AOnOff(NOT HadACC,' - no access to',''));
    END;
    Inc(FArea);
  END;
  FileArea := SaveFileArea;
  InitFileArea(FileArea);
  IF (NOT AnyFound) THEN
    Print('No duplicates found.');
  NL;
  SearchForDups := FALSE;
END;

(*
AExists       : if file already exists in dir
DirFileRecNum : rec-num of file if already exists in file listing
ResumeFile    : IF user is going to RESUME THE UPLOAD
ULS           : whether file is to be actually UPLOADED
OffLine       : IF uploaded a file to be OffLine automatically..
*)

PROCEDURE UL(FileName: Str12; LocBatUp: Boolean; VAR AddULBatch: Boolean);
VAR
  fi: FILE OF Byte;
  Cmd: Char;
  Counter,
  LineNum,
  NumExtDesc: Byte;
  DirFileRecNum,
  SaveFileArea,
  GotPts: Integer;
  TransferTime,
  RefundTime,
  ConversionTime: LongInt;
  ULS,
  UploadOk,
  KeyboardAbort,
  Convt,
  AExists,
  ResumeFile,
  WentToSysOp,
  OffLine: Boolean;
BEGIN
  SaveFileArea := FileArea;
  InitFileArea(FileArea);
  IF (BadUploadPath) THEN
    Exit;

  UploadOk := TRUE;

  IF (FileName[1] = ' ') OR (FileName[10] = ' ') THEN
    UploadOk := FALSE;

  FOR Counter := 1 TO Length(FileName) DO
    IF (Pos(FileName[Counter],'0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ.-!#$%^&''~()_') = 0) THEN
    BEGIN
      UploadOk := FALSE;
      Break;
    END;

  IF (NOT UploadOk) THEN
  BEGIN
    NL;
    Print('^7Illegal file name specified!^1');
    PauseScr(FALSE);
    Exit;
  END;

  Abort := FALSE;
  Next := FALSE;

  ResumeFile := FALSE;

  ULS := TRUE;

  OffLine := FALSE;

  AExists := Exist(MemFileArea.ULPath+FileName);

  FileName := Align(FileName);

  RecNo(FileInfo,FileName,DirFileRecNum);
  IF (DirFileRecNum <> -1) THEN
  BEGIN
    Seek(FileInfoFile,DirFileRecNum);
    Read(FileInfoFile,FileInfo);
    ResumeFile := (FIResumeLater IN FileInfo.FIFlags);
    IF (ResumeFile) THEN
    BEGIN
      NL;
      Print('^5Note: ^1This is a resume-later file.^1');
      ResumeFile := (CRC32(FileInfo.OwnerName) = CRC32(ThisUser.Name)) OR (FileSysOp);
      IF (ResumeFile) THEN
      BEGIN
        IF (NOT InCom) THEN
        BEGIN
          NL;
          Print('^7File upload can not be resumed locally!^1');
          PauseScr(FALSE);
          Exit;
        END;
        NL;
        ResumeFile := PYNQ('Resume upload of "'+SQOutSp(FileName)+'"? ',0,TRUE);
        IF (NOT ResumeFile) THEN
          Exit;
      END
      ELSE
      BEGIN
        NL;
        Print('^7You are not the uploader of this file!^1');
        PauseScr(FALSE);
        Exit;
      END;
    END;
  END;

  IF (NOT AExists) AND (FileSysOp) AND (NOT InCom) THEN
  BEGIN
    ULS := FALSE;
    OffLine := TRUE;
    NL;
    Print('File does not exist in upload path: ^5'+MemFileArea.ULPath+SQOutSp(FileName)+'^1');
    IF (DirFileRecNum <> -1) THEN
    BEGIN
      NL;
      Print('^5Note: ^1File exists in listing.^1');
    END;
    NL;
    IF NOT PYNQ('Do you want to create an offline entry? ',0,FALSE) THEN
      Exit;
  END;

  IF (NOT ResumeFile) THEN
  BEGIN

    IF (((AExists) OR (DirFileRecNum <> -1)) AND (NOT FileSysOp)) THEN
    BEGIN
      NL;
      Print('^7File already exists!^1');
      Exit;
    END;
    IF (FileSize(FileInfoFile) >= MemFileArea.MaxFiles) THEN
    BEGIN
      NL;
      Star('^7This file area is full!^1');
      Exit;
    END;

    IF (NOT AExists) AND (NOT OffLine) THEN
      IF (NOT CheckDriveSpace('Upload',MemFileArea.ULPath,General.MinSpaceForUpload)) THEN
        Exit;

    IF (AExists) THEN
    BEGIN
      ULS := FALSE;
      NL;
      Print('^1File exists in upload path: ^5'+MemFileArea.ULPath+SQOutSp(FileName));
      IF (DirFileRecNum <> -1) THEN
      BEGIN
        NL;
        Print('^5Note: ^1File exists in listing.^1');
      END;

      IF (LocBatUp) THEN
      BEGIN
        NL;
        Prompt('^7[Q]uit or Upload this? (Y/N) ['+SQOutSp(ShowYesNo(DirFileRecNum = -1))+']: ');
        OneK(Cmd,'QYN'^M,FALSE,FALSE);
        IF (DirFileRecNum <> -1) THEN
          UploadOk := (Cmd = 'Y')
        ELSE
          UploadOk := (Cmd IN ['Y',^M]);
        Abort := (Cmd = 'Q');
        IF (Abort) THEN
          Print('^3Quit')
        ELSE IF (NOT UploadOk) THEN
          Print('^3No')
        ELSE
          Print('^3Yes');
        UserColor(1);
      END
      ELSE
      BEGIN
        NL;
        UploadOk := PYNQ('Upload this? (Y/N) ['+SQOutSp(ShowYesNo(DirFileRecNum = -1))+']: ',0,(DirFileRecNum = -1));
      END;
      DirFileRecNum := 0;
    END;

    IF (General.SearchDup) AND (UploadOk) AND (NOT Abort) AND (InCom) THEN
      IF (NOT FileSysOp) OR (PYNQ('Search for duplicates? ',0,FALSE)) THEN
          IF (SearchForDups(FileName)) THEN
            Exit;

    IF (ULS) THEN
    BEGIN
      NL;
      UploadOk := PYNQ('Upload "^5'+SQOutSp(FileName)+'^7" to ^5'+MemFileArea.AreaName+'^7? ',0,TRUE);
    END;

    IF ((UploadOk) AND (ULS) AND (NOT ResumeFile)) THEN
    BEGIN

      Assign(fi,MemFileArea.ULPath+FileName);
      ReWrite(fi);
      IF (IOResult <> 0) THEN
        UploadOk := FALSE
      ELSE
      BEGIN
        Close(fi);
        Erase(fi);
        IF (IOResult <> 0) THEN
          UploadOk := FALSE;
      END;

      IF (NOT UploadOk) THEN
      BEGIN
        NL;
        Print('^7Unable to upload that file name!^1');
        Exit;
      END;
    END;

  END;

  IF (NOT UploadOk) THEN
    Exit;

  WentToSysOp := TRUE;

  IF (NOT ResumeFile) THEN
  BEGIN
    FileInfo.FileName := Align(FileName);
    GetFileDescription(FileInfo,ExtendedArray,NumExtDesc,WentToSysOp);
  END;

  UploadOk := TRUE;

  IF (ULS) THEN
  BEGIN
    Receive(FileName,MemFileArea.ULPath,ResumeFile,UploadOk,KeyboardAbort,AddULBatch,TransferTime);

    IF (AddULBatch) THEN
    BEGIN
      IF CheckBatchUL(FileName) THEN
      BEGIN
        NL;
        Print('^7This file is already in the batch upload queue!^1');
      END
      ELSE IF (NumBatchULFiles = General.MaxBatchULFiles) THEN
      BEGIN
        NL;
        Print('^7The batch upload queue is full!^1');
      END
      ELSE
      BEGIN
        Assign(BatchULFile,General.DataPath+'BATCHUL.DAT');
        IF (NOT Exist(General.DataPath+'BATCHUL.DAT')) THEN
          ReWrite(BatchULFile)
        ELSE
          Reset(BatchULFile);
        WITH BatchUL DO
        BEGIN
          BULFileName := SQOutSp(FileName);
          BULUserNum := UserNum;

          BULSection := FileArea;  (*  Should this be CompFileArea ??? *)

          BULDescription := FileInfo.Description;

          IF (ExtendedArray[1] = '') THEN
          BEGIN
            BULVPointer := -1;
            BULVTextSize := 0;
          END
          ELSE
          BEGIN
            Assign(BatchULF,General.DataPath+'BATCHUL.EXT');
            IF (NOT Exist(General.DataPath+'BATCHUL.EXT')) THEN
              ReWrite(BatchULF,1)
            ELSE
              Reset(BatchULF,1);
            BULVPointer := (FileSize(BatchULF) + 1);
            BULVTextSize := 0;
            Seek(BatchULF,FileSize(BatchULF));
            FOR LineNum := 1 TO NumExtDesc DO
              IF (ExtendedArray[LineNum] <> '') THEN
              BEGIN
                Inc(BULVTextSize,(Length(ExtendedArray[LineNum]) + 1));
                BlockWrite(BatchULF,ExtendedArray[LineNum],(Length(ExtendedArray[LineNum]) + 1));
              END;
            Close(BatchULF);
            LastError := IOResult;
          END;

          Seek(BatchULFile,FileSize(BatchULFile));
          Write(BatchULFile,BatchUL);
          Close(BatchULFile);
          LastError := IOResult;

          Inc(NumBatchULFiles);
          NL;
          Print('^5File added to the batch upload queue.^1');
          NL;
          Star('^1Batch upload queue: ^5'+IntToStr(NumBatchULFiles)+' '+Plural('file',NumBatchULFiles));
          SysOpLog('Batch UL Add: "^5'+BatchUL.BULFileName+'^1" to ^5'+MemFileArea.AreaName);
        END;
      END;
      NL;
      Star('^1Press <^5Enter^1> to stop adding to the batch upload queue.^1');
      NL;
      FileArea := SaveFileArea;
      Exit;
    END;

    IF (KeyboardAbort) THEN
    BEGIN
      FileArea := SaveFileArea;
      Exit;
    END;

    RefundTime := (TransferTime * (General.ULRefund DIV 100));

    Inc(FreeTime,RefundTime);

    NL;

  END;

  NL;

  Convt := FALSE;

  IF (NOT OffLine) THEN
  BEGIN

    Assign(fi,MemFileArea.ULPath+FileName);
    Reset(fi);
    IF (IOResult <> 0) THEN
      UploadOk := FALSE
    ELSE
    BEGIN
      FileInfo.FileSize := FileSize(fi);
      IF (FileSize(fi) = 0) THEN
        UploadOk := FALSE;
      Close(fi);

    END;

  END;

  IF ((UploadOk) AND (NOT OffLine)) THEN
  BEGIN

    ArcStuff(UploadOk,Convt,FileInfo.FileSize,ConversionTime,ULS,MemFileArea.ULPath,FileName,FileInfo.Description);

    UpdateFileInfo(FileInfo,FileName,GotPts);

    IF (General.FileDiz) AND (DizExists(MemFileArea.ULPath+FileName)) THEN
      GetDiz(FileInfo,ExtendedArray,NumExtDesc);

    IF (UploadOk) THEN
    BEGIN

      IF (AACS(General.ULValReq)) OR (General.ValidateAllFiles) THEN
        Include(FileInfo.FIFlags,FIOwnerCredited);

      IF (NOT ResumeFile) OR (DirFileRecNum = -1) THEN
        WriteFV(FileInfo,FileSize(FileInfoFile),ExtendedArray)
      ELSE
        WriteFV(FileInfo,DirFileRecNum,ExtendedArray);

      IF (ULS) THEN
      BEGIN

        IF (UploadsToday < 2147483647) THEN
          Inc(UploadsToday);

        IF ((UploadKBytesToday + (FileInfo.FileSize DIV 1024)) < 2147483647) THEN
          Inc(UploadKBytesToday,(FileInfo.FileSize DIV 1024))
        ELSE
          UploadKBytesToday := 2147483647;

      END;

      SysOpLog('^3Uploaded: "^5'+SQOutSp(FileName)+'^3" on ^5'+MemFileArea.AreaName);

      IF (ULS) THEN


        SysOpLog('^3 ('+ConvertBytes(FileInfo.FileSize,FALSE)+', '+FormattedTime(TransferTime)+
                 ', '+FormatNumber(GetCPS(FileInfo.FileSize,Transfertime))+' cps)');

      IF ((InCom) AND (ULS)) THEN
      BEGIN

        Star('File size    : ^5'+ConvertBytes(FileInfo.FileSize,FALSE));

        Star('Upload time  : ^5'+FormattedTime(TransferTime));

        IF (Convt) THEN
          Star('Convert time : ^5'+FormattedTime(ConversionTime));

        Star('Transfer rate: ^5'+FormatNumber(GetCPS(FileInfo.FileSize,TransferTime))+' cps');

        Star('Time refund  : ^5'+FormattedTime(RefundTime));

        IF (GotPts <> 0) THEN
          Star('File Points  : ^5'+FormatNumber(GotPts)+' pts');

        IF (ChopTime > 0) THEN
        BEGIN
          Inc(ChopTime,RefundTime);
          Dec(FreeTime,RefundTime);
          NL;
          Star('Sorry, no upload time refund may be given at this time.');
          Star('You will get your refund after the event.');
          NL;
        END;

        IF (NOT AACS(General.ULValReq)) AND (NOT General.ValidateAllFiles) THEN
        BEGIN
          IF (General.ULDLRatio) THEN
          BEGIN
            NL;
            Print('^5You will receive file credit as soon as the SysOp validates the file!')
          END
          ELSE
          BEGIN
            NL;
            Print('^5You will receive credit as soon as the SysOp validates the file!');
          END;
        END
        ELSE
        BEGIN

          IF ((NOT General.ULDLRatio) AND (NOT General.FileCreditRatio) AND (GotPts = 0)) THEN
          BEGIN
            NL;
            Print('^5You will receive credit as soon as the Sysop validates the file!')
          END
          ELSE
          BEGIN

            IF (ThisUser.Uploads < 2147483647) THEN
              Inc(ThisUser.Uploads);

            IF ((ThisUser.UK + (FileInfo.FileSize DIV 1024)) < 2147483647) THEN
              Inc(ThisUser.UK,(FileInfo.FileSize DIV 1024))
            ELSE
              ThisUser.UK := 2147483647;

            IF ((ThisUser.FilePoints + GotPts) < 2147483647) THEN
              Inc(ThisUser.FilePoints,GotPts)
            ELSE
              ThisUser.FilePoints := 2147483647;

          END;
        END;


        NL;
        Print('^5Thanks for the file, '+Caps(ThisUser.Name)+'!');
        PauseScr(FALSE);

      END
      ELSE
        Star('Entry added.');
    END;
  END;

  IF (NOT UploadOk) AND (NOT OffLine) THEN
  BEGIN

    IF (Exist(MemFileArea.ULPath+FileName)) THEN
    BEGIN

      Star('Upload not received.');

      IF ((FileInfo.FileSize DIV 1024) >= General.MinResume) THEN
      BEGIN
        NL;
        IF PYNQ('Save file for a later resume? ',0,TRUE) THEN
        BEGIN

          UpdateFileInfo(FileInfo,FileName,GotPts);

          Include(FileInfo.FIFlags,FIResumeLater);

          IF (NOT AExists) OR (DirFileRecNum = -1) THEN
            WriteFV(FileInfo,FileSize(FileInfoFile),ExtendedArray)
          ELSE
            WriteFV(FileInfo,DirFileRecNum,ExtendedArray);

        END;
      END;

      IF (NOT (FIResumeLater IN FileInfo.FIFlags)) AND (Exist(MemFileArea.ULPath+FileName)) THEN
        Kill(MemFileArea.ULPath+FileName);

      SysOpLog('^3Error uploading '+SQOutSp(FileName)+
               ' - '+AOnOff(FIResumeLater IN FileInfo.FIFlags,'file saved for later resume','file deleted'));
    END;

    Star('Removing time refund of '+FormattedTime(RefundTime));

    Dec(FreeTime,RefundTime);
  END;

  IF (OffLine) THEN
  BEGIN
    FileInfo.FileSize := 0;
    UpdateFileInfo(FileInfo,FileName,GotPts);
    Include(FileInfo.FIFlags,FIIsRequest);
    WriteFV(FileInfo,FileSize(FileInfoFile),ExtendedArray);
  END;

  Close(FileInfoFile);
  Close(ExtInfoFile);

  FileArea := SaveFileArea;
  InitFileArea(FileArea);

  SaveURec(ThisUser,UserNum);
END;

PROCEDURE UploadFile;
VAR
  FileName: Str12;
  AddULBatch: Boolean;
BEGIN
  InitFileArea(FileArea);
  IF (BadUploadPath) THEN
    Exit;
  IF (NOT AACS(MemFileArea.ULACS)) THEN
  BEGIN
    NL;
    Star('Your access level does not permit uploading to this file area.');
    Exit;
  END;
  PrintF('UPLOAD');
  IF (NumBatchULFiles > 0) THEN
  BEGIN
    NL;
    IF PYNQ('Upload queued files? ',0,FALSE) THEN
    BEGIN
      BatchUpload(FALSE,0);
      Exit;
    END;
  END;
  REPEAT
    AddULBatch := FALSE;
    {
    NL;
    Print(FString.UploadLine);
    NL;
    Prt('File name: ');
    }
    lRGLngStr(24,FALSE);
    MPL(12);
    Input(FileName,12);
    FileName := SQOutSp(FileName);
    IF (FileName = '') THEN
    BEGIN
      NL;
      Print('Aborted.');
    END
    ELSE
    BEGIN
      IF (NOT FileSysOp) THEN
        UL(FileName,FALSE,AddULBatch)
      ELSE
      BEGIN
        IF (NOT IsWildCard(FileName)) THEN
          UL(FileName,FALSE,AddULBatch)
        ELSE
        BEGIN
          FindFirst(MemFileArea.ULPath+FileName,AnyFile - Directory - VolumeID - Hidden - SysFile,DirInfo);
          IF (DOSError <> 0) THEN
          BEGIN
            NL;
            Print('No files found.');
          END
          ELSE
            REPEAT
              UL(DirInfo.Name,TRUE,AddULBatch);
              FindNext(DirInfo);
            UNTIL (DOSError <> 0) OR (Abort) OR (HangUp);
        END;
      END;
    END;
  UNTIL (NOT AddUlBatch) OR (HangUp);
END;

PROCEDURE LFileAreaList(VAR FArea,NumFAreas: Integer; AdjPageLen: Byte; ShowScan: Boolean);
VAR
  ScanChar: Str1;
  TempStr: AStr;
  NumOnline,
  NumDone: Byte;
  SaveFileArea: Integer;
BEGIN
  SaveFileArea := FileArea;
  Abort := FALSE;
  Next := FALSE;
  NumOnline := 0;
  TempStr := '';

  FillChar(LightBarArray,SizeOf(LightBarArray),0);
  LightBarCounter := 0;

  {
  $New_Scan_Char_File
  þ
  $
  }
  IF (ShowScan) THEN
    ScanChar := lRGLngStr(55,TRUE);
  {
  %CL-ÚÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
  -³. Num -³/ Name                           -³. Num -³/ Name                           -³
  -ÀÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
  }
  lRGLngStr(59,FALSE);
  Reset(FileAreaFile);
  NumDone := 0;
  WHILE (NumDone < (PageLength - AdjPageLen)) AND (FArea >= 1) AND (FArea <= NumFileAreas) AND (NOT Abort) AND (NOT HangUp) DO
  BEGIN
    LoadFileArea(FArea);
    IF (ShowScan) THEN
      LoadNewScanFile(NewScanFileArea);
    IF AACS(MemFileArea.ACS) OR (FAUnHidden IN MemFileArea.FAFlags) THEN
    BEGIN

      IF (General.UseFileAreaLightBar) AND (FileAreaLightBar IN ThisUser.SFlags) THEN
      BEGIN
        Inc(LightBarCounter);
        LightBarArray[LightBarCounter].CmdToExec := CompFileArea(FArea,0);
        LightBarArray[LightBarCounter].CmdToShow := MemFileArea.AreaName;
        IF (NumOnline = 0) THEN
        BEGIN
          LightBarArray[LightBarCounter].Xpos := 8;
          LightBarArray[LightBarCounter].YPos := WhereY;
        END
        ELSE
        BEGIN
          LightBarArray[LightBarCounter].Xpos := 47;
          LightBarArray[LightBarCounter].YPos := WhereY;
        END;
      END;

      TempStr := TempStr + AOnOff(ShowScan AND NewScanFileArea,'0'+ScanChar[1],' ')+
                           PadLeftStr(PadRightStr('1'+IntToStr(CompFileArea(FArea,0)),5)+
                           +'2 '+MemFileArea.AreaName,37)+' ';
      Inc(NumOnline);
      IF (NumOnLine = 2) THEN
      BEGIN
        PrintACR(TempStr);
        NumOnline := 0;
        Inc(NumDone);
        TempStr := '';
      END;
      Inc(NumFAreas);
    END;
    WKey;
    Inc(FArea);
  END;
  Close(FileAreaFile);
  LastError := IOResult;
  IF (NumOnline = 1) AND (NOT Abort) AND (NOT HangUp) THEN
    PrintACR(TempStr)
  ELSE IF (NumFAreas = 0) AND (NOT Abort) AND (NOT HangUp) THEN
    LRGLngStr(67,FALSE);
  {
  %LF^7No file areas!^1
  }
  FileArea := SaveFileArea;
  LoadFileArea(FileArea);
END;

PROCEDURE UnlistedDownload(FileName: AStr);
VAR
  User: UserRecordType;
  TransferFlags: TransferFlagSet;
  DS: DirStr;
  NS: NameStr;
  ES: ExtStr;
  SaveFileArea: Integer;
BEGIN
  IF (FileName <> '') THEN
    IF (NOT Exist(FileName)) THEN
    BEGIN
      NL;
      Print('File not found.');
    END
    ELSE
    BEGIN
      SaveFileArea := FileArea;
      FileArea := -1;
      Abort := FALSE;
      Next := FALSE;
      LoadURec(User,1);
      FSplit(FileName,DS,NS,ES);
      FindFirst(SQOutSp(FileName),AnyFile - Directory - VolumeID - Hidden - SysFile,DirInfo);
      WHILE (DOSError = 0) AND (NOT Abort) AND (NOT HangUp) DO
      BEGIN
        WITH MemFileArea DO
        BEGIN
          AreaName := 'Unlisted Download';
          DLPath := DS;
          ULPath := DS;
          FAFlags := [FANoRatio];
        END;
        WITH FileInfo DO
        BEGIN
          FileName := Align(DirInfo.Name);
          Description := 'Unlisted Download';
          FilePoints := 0;
          Downloaded := 0;
          FileSize := DirInfo.Size;
          OwnerNum := 1;
          OwnerName := Caps(User.Name);
          FileDate := Date2PD(DateStr);
          VPointer := -1;
          VTextSize := 0;
          FIFlags := [];
        END;
        TransferFlags := [IsUnlisted];
        IF (InCom) THEN
        BEGIN
          NL;
          IF (PYNQ('Is this file located on a CDRom? ',0,FALSE)) THEN
            Include(MemFileArea.FAFlags,FACDROm);
        END;
        DLX(FileInfo,-1,TransferFlags);
        IF (IsKeyboardAbort IN Transferflags) THEN
          Abort := TRUE;
        FindNext(DirInfo);
      END;
      FileArea := SaveFileArea;
      LoadFileArea(FileArea);
    END;
END;

PROCEDURE Do_Unlisted_Download;
VAR
  PathFileName: Str52;
BEGIN
  NL;
  Print('Enter file name to download (d:path\filename.ext)');
  Prt(': ');
  MPL(52);
  Input(PathFileName,52);
  IF (PathFileName = '') THEN
  BEGIN
    NL;
    Print('Aborted.');
  END
  ELSE IF (NOT IsUL(PathFileName)) THEN
  BEGIN
    NL;
    Print('You must specify the complete path to the file.');
  END
  ELSE
    UnlistedDownload(PathFileName)
END;

END.
