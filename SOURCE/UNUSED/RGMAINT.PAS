{$M 35500,0,131072}
PROGRAM RGMAINT;

USES
  Crt,
  Dos,
  TimeFunc;

{$I RECORDS.PAS}

TYPE
  StorageType =
  (
    Disk,
    CD,
    Copied
  );

  TransferFlagType =
   (IsAddDLBatch,
    IsFileAttach,
    IsUnlisted,
    IsTempArc,
    IsQWK,
    IsNoFilePoints,
    IsNoRatio,
    IsCheckRatio,
    IsCDRom,
    IsPaused,
    IsAutoLogOff,
    IsKeyboardAbort,
    IsTransferOk);

  TransferFlagSet = SET OF TransferFlagType;

  BatchDLRecordType = RECORD
    BDLFileName: STRING[52];
    BDLStorage: StorageType;
    BDLUserNum,
    BDLSection,
    BDLPoints,
    BDLUploader: Integer;
    BDLFSize,
    BDLTime,
    BDLOwnerCRC: LongInt;
    BDLFlags: TransferFlagSet;
  END;

  DirF = FILE OF FileInfoRecordType;
  SF = FILE OF UserIDXRec;

CONST
  DYNY: BOOLEAN = FALSE;

FUNCTION AllCaps(S: STRING): STRING;
VAR
  Counter: Byte;
BEGIN
  FOR Counter := 1 TO Length(S) DO
    IF (S[Counter] IN ['a'..'z']) THEN
      S[Counter] := Chr(Ord(S[Counter]) - Ord('a')+Ord('A'));
  AllCaps := S;
END;

FUNCTION IntToStr(L: LongInt): STRING;
VAR
  S: STRING[11];
BEGIN
  Str(L,S);
  IntToStr := s;
END;

FUNCTION SQOutSp(S: STRING): STRING;
BEGIN
  WHILE (Pos(' ',S) > 0) DO
    Delete(S,Pos(' ',S),1);
  SQOutSp := S;
END;

FUNCTION Exist(fn: AStr): Boolean;
VAR
  DirInfo: SearchRec;
BEGIN
  FindFirst(SQOutSp(fn),AnyFile,DirInfo);
  Exist := (DOSError = 0);
END;

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
END;

FUNCTION PYNQ(CONST S: AStr): BOOLEAN;
BEGIN
  Write(S);
  PYNQ := YN;
END;

FUNCTION StrToInt(S: STRING): LongInt;
VAR
  I: Integer;
  L: LongInt;
BEGIN
  Val(S,L,I);
  IF (I > 0) THEN
  BEGIN
    S[0] := Chr(I - 1);
    Val(S,L,I)
  END;
  IF (S = '') THEN
    StrToInt := 0
  ELSE
    StrToInt := L;
END;

FUNCTION GetFileSize(FileName: AStr): LongInt;
VAR
  F: FILE OF Byte;
  FSize: LongInt;
BEGIN
  FSize := 0;
  IF (Exist(SQOutSp(FileName))) THEN
  BEGIN
    Assign(F,SQOutSp(FileName));
    Reset(F);
    FSize := FileSize(F);
    Close(F);
  END;
  GetFileSize := FSize;
END;

PROCEDURE KillUserVotes(DataPath: STRING; VAR User: UserRecordType);
VAR
  VotingFile: FILE OF VotingRecordType;
  Topic: VotingRecordType;
  Counter: Integer;
BEGIN
  IF (Exist(DataPath+'VOTING.DAT')) THEN
  BEGIN
    Assign(VotingFile,DataPath+'VOTING.DAT');
    Reset(VotingFile);
    FOR Counter := 1 TO FileSize(VotingFile) DO
      IF (User.Vote[Counter] > 0) THEN
      BEGIN
        Seek(VotingFile,(Counter - 1));
        Read(VotingFile,Topic);
        IF (Topic.NumVotedQuestion > 0) THEN
          Dec(Topic.NumVotedQuestion);
        IF (Topic.Answers[User.Vote[Counter]].NumVotedAnswer > 0) THEN
          Dec(Topic.Answers[User.Vote[Counter]].NumVotedAnswer);
        Seek(VotingFile,(Counter - 1));
        Write(VotingFile,Topic);
        User.Vote[Counter] := 0;
      END;
    Close(VotingFile);
  END;
END;

PROCEDURE ResetVotes(DataPath: STRING);
VAR
  VotingFile: FILE OF VotingRecordType;
  Topic: VotingRecordType;
  Counter,
  Counter1: Integer;
BEGIN
  IF (Exist(DataPath+'VOTING.DAT')) THEN
  BEGIN
    Assign(VotingFile,DataPath+'VOTING.DAT');
    Reset(VotingFile);
    FOR Counter := 1 TO FileSize(VotingFile) DO
    BEGIN
      Seek(VotingFile,(Counter - 1));
      Read(VotingFile,Topic);
      Topic.NumVotedQuestion := 0;;
      FOR Counter1 := 1 TO 25 DO
        Topic.Answers[Counter1].NumVotedAnswer := 0;
      Seek(VotingFile,(Counter - 1));
      Write(VotingFile,Topic);
    END;
    Close(VotingFile);
  END;
END;

PROCEDURE ReScanUserVotes(DataPath: STRING; VAR User: UserRecordType);
VAR
  VotingFile: FILE OF VotingRecordType;
  Topic: VotingRecordType;
  Counter: Integer;
BEGIN
  IF (Exist(DataPath+'VOTING.DAT')) THEN
  BEGIN
    Assign(VotingFile,DataPath+'VOTING.DAT');
    Reset(VotingFile);
    FOR Counter := 1 TO FileSize(VotingFile) DO
      IF (User.Vote[Counter] > 0) THEN
      BEGIN
        Seek(VotingFile,(Counter - 1));
        Read(VotingFile,Topic);
        Inc(Topic.NumVotedQuestion);
        Inc(Topic.Answers[User.Vote[Counter]].NumVotedAnswer);
        Seek(VotingFile,(Counter - 1));
        Write(VotingFile,Topic);
      END;
    Close(VotingFile);
  END;
END;

PROCEDURE KillShortMsgs(DataPath: STRING; VAR User: UserRecordType);
VAR
  ShortMsgFile: FILE OF ShortMessageRecordType;
  ShortMsg: ShortMessageRecordType;
  Counter: Integer;
BEGIN
  IF (Exist(DataPath+'SHORTMSG.DAT')) THEN
  BEGIN
    Assign(ShortMsgFile,DataPath+'SHORTMSG.DAT');
    Reset(ShortMsgFile);
    FOR Counter := 1 TO FileSize(ShortMsgFile) DO
    BEGIN
      Seek(ShortMsgFile,(Counter - 1));
      Read(ShortMsgFile,ShortMsg);
      IF (ShortMsg.Destin = User.UserID) THEN
        ShortMsg.Destin := -1;
      Seek(ShortMsgFile,(Counter - 1));
      Write(ShortMsgFile,ShortMsg);
    END;
    Close(ShortMsgFile);
  END;
END;

PROCEDURE UpdateShortMsgs(DataPath: STRING; VAR User: UserRecordType; NewUserNumber: Integer);
VAR
  ShortMsgFile: FILE OF ShortMessageRecordType;
  ShortMsg: ShortMessageRecordType;
  Counter: Integer;
BEGIN
  IF Exist(DataPath+'SHORTMSG.DAT') THEN
  BEGIN
    Assign(ShortMsgFile,DataPath+'SHORTMSG.DAT');
    Reset(ShortMsgFile);
    FOR Counter := 1 TO FileSize(ShortMsgFile) DO
    BEGIN
      Seek(ShortMsgFile,(Counter - 1));
      Read(ShortMsgFile,ShortMsg);
      IF (ShortMsg.Destin = User.UserID) THEN
        ShortMsg.Destin := NewUserNumber;
      Seek(ShortMsgFile,(Counter - 1));
      Write(ShortMsgFile,ShortMsg);
    END;
    Close(ShortMsgFile);
  END;
END;

PROCEDURE PurgingShortMsgs(DataPath: STRING);
VAR
  ShortMsgFile: FILE OF ShortMessageRecordType;
  ShortMsgFile1: FILE OF ShortMessageRecordType;
  ShortMsg: ShortMessageRecordType;
  Counter: Integer;
BEGIN
  IF Exist(DataPath+'SHORTMSG.DAT') THEN
  BEGIN
    Assign(ShortMsgFile,DataPath+'SHORTMSG.DAT');
    Reset(ShortMsgFile);
    Assign(ShortMsgFile1,DataPath+'SHORTMSG.BAK');
    ReWrite(ShortMsgFile1);
    FOR Counter := 1 TO FileSize(ShortMsgFile) DO
    BEGIN
      Seek(ShortMsgFile,(Counter - 1));
      Read(ShortMsgFile,ShortMsg);
      IF (ShortMsg.Destin <> -1) THEN
      BEGIN
        Seek(ShortMsgFile1,FileSize(ShortMsgFile1));
        Write(ShortMsgFile1,ShortMsg);
      END;
    END;
    Close(ShortMsgFile);
    Erase(ShortMsgFile);
    Close(ShortMsgFile1);
    ReName(ShortMsgFile1,DataPath+'SHORTMSG.DAT');
  END;
END;

PROCEDURE KillBatchQueue(DataPath: STRING; VAR User: UserRecordType);
VAR
  BatchDLFile: FILE OF BatchDlRecordType;
  BatchDL: BatchDlRecordType;
  Counter: Integer;
BEGIN
  IF Exist(DataPath+'BATCHDL.DAT') THEN
  BEGIN
    Assign(BatchDLFile,DataPath+'BATCHDL.DAT');
    Reset(BatchDLFile);
    FOR Counter := 1 TO FileSize(BatchDLFile) DO
    BEGIN
      Seek(BatchDLFile,(Counter - 1));
      Read(BatchDLFile,BatchDL);
      IF (BatchDL.BDLUserNum = User.UserID) THEN
        BatchDL.BDLUserNum := -1;
      Seek(BatchDLFile,(Counter - 1));
      Write(BatchDLFile,BatchDL);
    END;
    Close(BatchDLFile);
  END;
END;

PROCEDURE UpdateBatchQueue(DataPath: STRING; VAR User: UserRecordType; NewUserNumber: Integer);
VAR
  BatchDLFile: FILE OF BatchDLRecordType;
  BatchDL: BatchDlRecordType;
  Counter: Integer;
BEGIN
  IF Exist(DataPath+'BATCHDL.DAT') THEN
  BEGIN
    Assign(BatchDLFile,DataPath+'BATCHDL.DAT');
    Reset(BatchDLFile);
    FOR Counter := 1 TO FileSize(BatchDLFile) DO
    BEGIN
      Seek(BatchDLFile,(Counter - 1));
      Read(BatchDLFile,BatchDL);
      IF (BatchDL.BDLUserNum = User.UserID) THEN
        BatchDL.BDLUserNum := NewUserNumber;
      Seek(BatchDLFile,(Counter - 1));
      Write(BatchDLFile,BatchDL);
    END;
    Close(BatchDLFile);
  END;
END;

PROCEDURE PurgingBatchQueue(DataPath: STRING);
VAR
  BatchDLFile: FILE OF BatchDLRecordType;
  BatchDLFile1: FILE OF BatchDLRecordType;
  BatchDL: BatchDLRecordType;
  Counter: Integer;
BEGIN
  IF Exist(DataPath+'BATCHDL.DAT') THEN
  BEGIN
    Assign(BatchDLFile,DataPath+'BATCHDL.DAT');
    Reset(BatchDLFile);
    Assign(BatchDLFile1,DataPath+'BATCHDL.BAK');
    ReWrite(BatchDLFile1);
    FOR Counter := 1 TO FileSize(BatchDLFile) DO
    BEGIN
      Seek(BatchDLFile,(Counter - 1));
      Read(BatchDLFile,BatchDL);
      IF (BatchDL.BDLUserNum <> -1) THEN
      BEGIN
        Seek(BatchDLFile1,FileSize(BatchDLFile1));
        Write(BatchDLFile1,BatchDL);
      END;
    END;
    Close(BatchDLFile);
    Erase(BatchDLFile);
    Close(BatchDLFile1);
    ReName(BatchDLFile1,DataPath+'BATCHDL.DAT');
  END;
END;

PROCEDURE KillUserEMail(DataPath,MsgPath: STRING; VAR User: UserRecordType);
VAR
  MsgHdrF: FILE OF MHeaderRec;
  MHeader: MHeaderRec;
  MsgNum: Word;
BEGIN
  IF (Exist(MsgPath+'EMAIL.HDR')) THEN
  BEGIN
    Assign(MsgHdrF,MsgPath+'EMAIL.HDR');
    Reset(MsgHdrF);
    FOR MsgNum := 1 TO FileSize(MsgHdrF) DO
    BEGIN
      Seek(MsgHdrF,(MsgNum - 1));
      Read(MsgHdrF,MHeader);
      IF ((MHeader.MTO.UserNum = User.UserID) OR (MHeader.From.UserNum = User.UserID)) THEN
        Include(MHeader.Status,MDeleted);
      IF (MHeader.MTO.UserNum = User.UserID) THEN
        MHeader.MTO.UserNum := 0;
      IF (MHeader.FROM.UserNum = User.UserID) THEN
        MHeader.FROM.UserNum := 0;
      Seek(MsgHdrF,(MsgNum - 1));
      Write(MsgHdrF,MHeader);
    END;
    Close(MsgHdrF);
    User.Waiting := 0;
  END;
END;

PROCEDURE UpdateUserEMail(MsgPath: STRING; VAR User: UserRecordType; NewUserNum: Integer);
VAR
  MsgHdrF: FILE OF MHeaderRec;
  MHeader: MHeaderRec;
  MsgNum: Word;
BEGIN
  IF (Exist(MsgPath+'EMAIL.HDR')) THEN
  BEGIN
    Assign(MsgHdrF,MsgPath+'EMAIL.HDR');
    Reset(MsgHdrF);
    FOR MsgNum := 1 TO FileSize(MsgHdrF) DO
    BEGIN
      Seek(MsgHdrF,(MsgNum - 1));
      Read(MsgHdrF,MHeader);
      IF (MHeader.MTO.UserNum = User.UserID) THEN
        MHeader.MTO.UserNum := NewUserNum;
      IF (MHeader.From.UserNum = User.UserID) THEN
        MHeader.From.UserNum := NewUserNum;
      Seek(MsgHdrF,(MsgNum - 1));
      Write(MsgHdrF,MHeader);
    END;
    Close(MsgHdrF);
  END;
END;

PROCEDURE ReScanUserEMail(MsgPath: STRING; VAR User: UserRecordType; UserNum: Integer);
VAR
  MsgHdrF: FILE OF MHeaderRec;
  MHeader: MHeaderRec;
  MsgNum: Word;
BEGIN
  IF (Exist(MsgPath+'EMAIL.HDR')) THEN
  BEGIN
    User.Waiting := 0;
    Assign(MsgHdrF,MsgPath+'EMAIL.HDR');
    Reset(MsgHdrF);
    FOR MsgNum := 1 TO FileSize(MsgHdrF) DO
    BEGIN
      Seek(MsgHdrF,(MsgNum - 1));
      Read(MsgHdrF,MHeader);
      IF (MHeader.MTO.UserNum = UserNum) THEN
        IF (NOT (MDeleted IN MHeader.Status)) THEN
          Inc(User.Waiting);
    END;
    Close(MsgHdrF);
  END;
END;

PROCEDURE UpdateDIRFilesDeletedUsers(DataPath: STRING; User,SysOpUser: UserRecordType);
VAR
  FileAreaFile: FILE OF FileAreaRecordType;
  DirFile: FILE OF FileInfoRecordType;
  FileArea: FileAreaRecordType;
  VerbF: FILE;
  F: FileInfoRecordType;
  Counter,
  Counter1: Integer;
BEGIN
  Assign(FileAreaFile,DataPath+'FBASES.DAT');
  Reset(FileAreaFile);
  FOR Counter := 0 TO (FileSize(FileAreaFile) - 1) DO
  BEGIN
    Seek(FileAreaFile,Counter);
    Read(FileAreaFile,FileArea);
    IF (FADirDLPath IN FileArea.FAFlags) THEN
      Assign(Dirfile,FileArea.Dlpath+FileArea.FileName+'.DIR')
    ELSE
      Assign(Dirfile,Datapath+FileArea.FileName+'.DIR');
    Reset(Dirfile);
    IF (IOResult = 2) THEN
      ReWrite(Dirfile);
    IF (FADirDLPath IN FileArea.FAFlags) THEN
      Assign(VerbF,FileArea.DLPath+FileArea.FileName+'.EXT')
    ELSE
      Assign(VerbF,Datapath+FileArea.FileName+'.EXT');
    Reset(VerbF,1);
    IF (IOResult = 2) THEN
      ReWrite(VerbF,1);
    FOR Counter1 := 0 TO (FileSize(DirFile) - 1) DO
    BEGIN
      Seek(DirFile,Counter1);
      Read(DirFile,F);
      IF (F.OwnerNum = User.UserID) THEN
      BEGIN
        F.OwnerNum := SysOpUser.UserID;
        F.OwnerName := AllCaps(SysOpUser.Name);
      END;
      Seek(DirFile,Counter1);
      Write(DirFile,F);
    END;
    Close(DirFile);
    Close(VerbF);
  END;
  Close(FileAreaFile);
END;

PROCEDURE UpdateDIRFilesExistingUsers(DataPath: STRING; User: UserRecordType; NewUserNum: Integer);
VAR
  FileAreaFile: FILE OF FileAreaRecordType;
  DirFile: FILE OF FileInfoRecordType;
  VerbF: FILE;
  FileArea: FileAreaRecordType;
  F: FileInfoRecordType;
  Counter,
  Counter1: Integer;
BEGIN
  Assign(FileAreaFile,DataPath+'FBASES.DAT');
  Reset(FileAreaFile);
  FOR Counter := 0 TO (FileSize(FileAreaFile) - 1) DO
  BEGIN
    Seek(FileAreaFile,Counter);
    Read(FileAreaFile,FileArea);
    IF (FADirDLPath IN FileArea.FAFlags) THEN
      Assign(Dirfile,FileArea.Dlpath+FileArea.FileName+'.DIR')
    ELSE
      Assign(Dirfile,Datapath+FileArea.FileName+'.DIR');
    Reset(Dirfile);
    IF (IOResult = 2) THEN
      ReWrite(Dirfile);
    IF (FADirDLPath IN FileArea.FAFlags) THEN
      Assign(VerbF,FileArea.Dlpath+FileArea.FileName+'.EXT')
    ELSE
      Assign(VerbF,Datapath+FileArea.FileName+'.EXT');
    Reset(VerbF,1);
    IF (IOResult = 2) THEN
      ReWrite(VerbF,1);
    FOR Counter1 := 0 TO (FileSize(DirFile) - 1) DO
    BEGIN
      Seek(DirFile,Counter1);
      Read(DirFile,F);
      IF (F.OwnerNum = User.UserID) THEN
        F.OwnerNum := NewUserNum;
      Seek(DirFile,Counter1);
      Write(DirFile,F);
    END;
    Close(DirFile);
    Close(VerbF);
  END;
  Close(FileAreaFile);
END;

PROCEDURE UpdateDIRFileSize(DataPath: STRING);
VAR
  FileAreaFile: FILE OF FileAreaRecordType;
  DirFile: FILE OF FileInfoRecordType;
  FileArea: FileAreaRecordType;
  VerbF: FILE;
  F: FileInfoRecordType;
  Counter,
  Counter1: Integer;
  FSize: Longint;
BEGIN
  Assign(FileAreaFile,DataPath+'FBASES.DAT');
  Reset(FileAreaFile);
  FOR Counter := 0 TO (FileSize(FileAreaFile) - 1) DO
  BEGIN
    Seek(FileAreaFile,Counter);
    Read(FileAreaFile,FileArea);
    IF (FADirDLPath IN FileArea.FAFlags) THEN
      Assign(Dirfile,FileArea.Dlpath+FileArea.FileName+'.DIR')
    ELSE
      Assign(Dirfile,Datapath+FileArea.FileName+'.DIR');
    Reset(Dirfile);
    IF (IOResult = 2) THEN
      ReWrite(Dirfile);
    IF (FADirDLPath IN FileArea.FAFlags) THEN
      Assign(VerbF,FileArea.Dlpath+FileArea.FileName+'.EXT')
    ELSE
      Assign(VerbF,Datapath+FileArea.FileName+'.EXT');
    Reset(VerbF,1);
    IF (IOResult = 2) THEN
      ReWrite(VerbF,1);
    FOR Counter1 := 0 TO (FileSize(DirFile) - 1) DO
    BEGIN
      Seek(DirFile,Counter1);
      Read(DirFile,F);
      FSize := GetFileSize(FileArea.DLPath+F.FileName);
      IF (FSize = 0) THEN
      BEGIN
        F.FileSize := 0;
        Include(F.FIFlags,FIIsRequest);
      END
      ELSE
        F.FileSize := FSize;
      Seek(DirFile,Counter1);
      Write(DirFile,F);
    END;
    Close(DirFile);
    Close(VerbF);
  END;
  Close(FileAreaFile);
END;

PROCEDURE UpdateFileSCNFilesExistingUsers(DataPath: STRING);
VAR
  FileAreaFile: FILE OF FileAreaRecordType;
  UserFile: FILE OF UserRecordType;
  UserFile2: FILE OF UserRecordType;
  ScnFile: FILE OF Boolean;
  ScnFile1: FILE OF Boolean;
  FileArea: FileAreaRecordType;
  User: UserRecordType;
  Path: STRING;
  Counter,
  Counter1,
  NumUsers: Integer;
  NewScanFBase: Boolean;
BEGIN
  Assign(UserFile,DataPath+'USERS.DAT');
  Reset(UserFile);
  Assign(UserFile2,DataPath+'USERS.BAK');
  Reset(UserFile2);
  Assign(FileAreaFile,DataPath+'FBASES.DAT');
  Reset(FileAreaFile);
  FOR Counter := 0 TO (FileSize(FileAreaFile) - 1) DO
  BEGIN
    Seek(FileAreaFile,Counter);
    Read(FileAreaFile,FileArea);
    IF (FADirDLPath IN FileArea.FAFlags) THEN
      Path := FileArea.Dlpath+FileArea.FileName
    ELSE
      Path := Datapath+FileArea.FileName;
    Assign(ScnFile,Path+'.SCN');
    Reset(ScnFile);
    IF (IOResult = 2) THEN
      ReWrite(ScnFile);
    Assign(ScnFile1,Path+'.SCB');
    ReWrite(ScnFile1);
    NumUsers := (FileSize(UserFile) - 1);
    IF (NumUsers > FileSize(ScnFile)) THEN
    BEGIN
      Seek(ScnFile,FileSize(ScnFile));
      NewScanFBase := TRUE;
      FOR Counter1 := FileSize(ScnFile) TO (NumUsers - 1) DO
        Write(ScnFile,NewScanFBase);
    END;
    FOR Counter1 := 1 TO (FileSize(UserFile2) - 1) DO
    BEGIN
      Seek(ScnFile1,FileSize(ScnFile1));
      NewScanFBase := TRUE;
      Write(ScnFile1,NewScanFBase);
    END;
    FOR Counter1 := 1 TO (FileSize(UserFile2) - 1) DO
    BEGIN
      Seek(UserFile2,Counter1);
      Read(UserFile2,User);
      Seek(ScnFile,(User.UserID - 1));
      Read(ScnFile,NewScanFBase);
      Seek(ScnFile1,(Counter1 - 1));
      Write(ScnFile1,NewScanFBase);
    END;
    Close(ScnFile);
    Erase(ScnFile);
    Close(ScnFile1);
    ReName(ScnFile1,Path+'.SCN');
  END;
  Close(FileAreaFile);
  Close(UserFile);
  Close(UserFile2);
END;

PROCEDURE UpdateMsgFilesDeletedUsers(DataPath,MsgPath: STRING; User: UserRecordType);
VAR
  MsgAreaFile: FILE OF MessageAreaRecordType;
  MsgHdrF: FILE OF MHeaderRec;
  MsgTxtF: FILE;
  MsgArea: MessageAreaRecordType;
  MHeader: MHeaderRec;
  Counter: Integer;
  MsgNum: Word;
BEGIN
  Assign(MsgAreaFile,DataPath+'MBASES.DAT');
  Reset(MsgAreaFile);
  FOR Counter := 0 TO (FileSize(MsgAreaFile) - 1) DO
  BEGIN
    Seek(MsgAreaFile,Counter);
    Read(MsgAreaFile,MsgArea);
    Assign(MsgHdrF,MsgPath+MsgArea.FileName+'.HDR');
    Reset(MsgHdrF);
    IF (IOResult = 2) THEN
      ReWrite(MsgHdrF);
    Assign(MsgTxtF,MsgPath+MsgArea.FileName+'.DAT');
    Reset(MsgTxtF,1);
    IF (IOResult = 2) THEN
      ReWrite(MsgTxtF,1);
    FOR MsgNum := 1 TO FileSize(MsgHdrF) DO
    BEGIN
      Seek(MsgHdrF,(MsgNum - 1));
      Read(MsgHdrF,MHeader);
      IF (MHeader.MTO.UserNum = User.UserID) THEN
        MHeader.MTO.UserNum := 0;
      IF (MHeader.From.UserNum = User.UserID) THEN
        MHeader.From.UserNum := 0;
      Seek(MsgHdrF,(MsgNum - 1));
      Write(MsgHdrF,MHeader);
    END;
    Close(MsgHdrF);
    Close(MsgTxtF);
  END;
  Close(MsgAreaFile);
END;

PROCEDURE UpdateMsgFilesExistingUsers(DataPath,MsgPath: STRING; User: UserRecordType; NewUserNum: Integer);
VAR
  MsgAreaFile: FILE OF MessageAreaRecordType;
  MsgHdrF: FILE OF MHeaderRec;
  MsgTxtF: FILE;
  MsgArea: MessageAreaRecordType;
  MHeader: MHeaderRec;
  Counter: Integer;
  MsgNum: Word;
BEGIN
  Assign(MsgAreaFile,DataPath+'MBASES.DAT');
  Reset(MsgAreaFile);
  FOR Counter := 0 TO (FileSize(MsgAreaFile) - 1) DO
  BEGIN
    Seek(MsgAreaFile,Counter);
    Read(MsgAreaFile,MsgArea);
    Assign(MsgHdrF,MsgPath+MsgArea.FileName+'.HDR');
    Reset(MsgHdrF);
    IF (IOResult = 2) THEN
      ReWrite(MsgHdrF);
    Assign(MsgTxtF,MsgPath+MsgArea.FileName+'.DAT');
    Reset(MsgTxtF,1);
    IF (IOResult = 2) THEN
      ReWrite(MsgTxtF,1);
    FOR MsgNum := 1 TO FileSize(MsgHdrF) DO
    BEGIN
      Seek(MsgHdrF,(MsgNum - 1));
      Read(MsgHdrF,MHeader);
      IF (MHeader.MTO.UserNum = User.UserID) THEN
        MHeader.MTO.UserNum := NewUserNum;
      IF (MHeader.From.UserNum = User.UserID) THEN
        MHeader.From.UserNum := NewUserNum;
      Seek(MsgHdrF,(MsgNum - 1));
      Write(MsgHdrF,MHeader);
    END;
    Close(MsgHdrF);
    Close(MsgTxtF);
  END;
  Close(MsgAreaFile);
END;

PROCEDURE UpdateMsgSCNFilesExistingUsers(DataPath,MsgPath: STRING);
VAR
  MessageFile: FILE OF MessageAreaRecordType;
  UserFile: FILE OF UserRecordType;
  UserFile2: FILE OF UserRecordType;
  MsgScanFile: FILE OF ScanRec;
  MsgScanFile1: FILE OF ScanRec;
  MsgArea: MessageAreaRecordType;
  User: UserRecordType;
  LastReadRecord: ScanRec;
  Path: STRING;
  Counter,
  Counter1,
  NumUsers: Integer;
BEGIN
  Assign(UserFile,DataPath+'USERS.DAT');
  Reset(UserFile);
  Assign(UserFile2,DataPath+'USERS.BAK');
  Reset(UserFile2);
  Assign(MessageFile,DataPath+'MBASES.DAT');
  Reset(MessageFile);
  FOR Counter := 0 TO (FileSize(MessageFile) - 1) DO
  BEGIN
    Seek(MessageFile,Counter);
    Read(MessageFile,MsgArea);
    Path := MsgPath+MsgArea.FileName;
    Assign(MsgScanFile,Path+'.SCN');
    Reset(MsgScanFile);
    IF (IOResult = 2) THEN
      ReWrite(MsgScanFile);
    Assign(MsgScanFile1,Path+'.SCB');
    ReWrite(MsgScanFile1);
    NumUsers := (FileSize(UserFile) - 1);
    IF (NumUsers > FileSize(MsgScanFile)) THEN
    BEGIN
      WITH LastReadRecord DO
      BEGIN
        LastRead := 0;
        NewScan :=  TRUE;
      END;
      Seek(MsgScanFile,FileSize(MsgScanFile));
      FOR Counter1 := FileSize(MSGScanFile) TO (NumUsers - 1) DO
        Write(MsgScanFile,LastReadRecord);
    END;
    FOR Counter1 := 1 TO (FileSize(UserFile2) - 1) DO
    BEGIN
      WITH LastReadRecord DO
      BEGIN
        LastRead := 0;
        NewScan :=  TRUE;
      END;
      Seek(MsgScanFile1,FileSize(MsgScanFile1));
      Write(MsgScanFile1,LastReadRecord);
    END;
    FOR Counter1 := 1 TO (FileSize(UserFile2) - 1) DO
    BEGIN
      Seek(UserFile2,Counter1);
      Read(UserFile2,User);
      Seek(MsgScanFile,(User.UserID - 1));
      Read(MsgScanFile,LastReadRecord);
      Seek(MsgScanFile1,(Counter1 - 1));
      Write(MsgScanFile1,LastReadRecord);
    END;
    Close(MsgScanFile);
    Erase(MsgScanFile);
    Close(MsgScanFile1);
    ReName(MsgScanFile1,Path+'.SCN');
  END;
  Close(MessageFile);
  Close(UserFile);
  Close(UserFile2);
END;

PROCEDURE PackMessageArea(MsgPath,FN: STRING; MaxM: LongInt);
VAR
  Buffer: ARRAY [1..4096] OF Char;
  MsgHdrF1,
  MsgHdrF2: FILE OF MheaderRec;
  BrdF1,
  BrdF2: FILE;
  MHeader: MheaderRec;
  Numm,
  i,
  IDX,
  TotLoad,
  Buffered: Word;
  NeedPack: Boolean;

  PROCEDURE ErrMsg;
  BEGIN
    Writeln('Error renaming temp files while packing.');
  END;

  PROCEDURE Kill(CONST FN: AStr);
  VAR
    F: FILE;
  BEGIN
    IF Exist(FN) THEN
    BEGIN
      Assign(F,FN);
      Erase(F);
    END;
  END;

BEGIN
  NeedPack := FALSE;
  FN := AllCaps(FN);
  FN := MsgPath + FN;

  Assign(BrdF1,FN+'.DAT');
  Reset(BrdF1,1);
  IF (IOResult <> 0) THEN
    Exit;

  Assign(MsgHdrF1,FN+'.HDR');
  Reset(MsgHdrF1);

  IF (IOResult <> 0) THEN
  BEGIN
    Close(BrdF1);
    Exit
  END;

  IF (MaxM <> 0) AND (FileSize(MsgHdrF1) > MaxM) THEN
  BEGIN
    Numm := 0;
    IDX := FileSize(MsgHdrF1);
    WHILE (IDX > 0) DO
    BEGIN
      Seek(MsgHdrF1,(IDX - 1));
      Read(MsgHdrF1,MHeader);
      IF NOT (MDeleted IN MHeader.Status) THEN
        Inc(Numm);
      IF (Numm > MaxM) AND NOT (Permanent IN MHeader.Status) THEN
      BEGIN
        MHeader.Status := [MDeleted];
        Seek(MsgHdrF1,(IDX - 1));
        Write(MsgHdrF1,MHeader);
      END;
      Dec(IDX);
    END;
  END
  ELSE
  BEGIN

    WHILE (FilePos(MsgHdrF1) < FileSize(MsgHdrF1)) AND (NOT NeedPack) DO
    BEGIN
      Read(MsgHdrF1,MHeader);
      IF (MDeleted IN MHeader.Status) THEN
        NeedPack := TRUE;
    END;

    IF (NOT NeedPack) THEN
    BEGIN
      Close(MsgHdrF1);
      Close(BrdF1);
      Exit;
    END;
  END;

  Assign(BrdF2,FN+'.DA1');
  ReWrite(BrdF2,1);

  Assign(MsgHdrF2,FN+'.HD2');
  ReWrite(MsgHdrF2);

  Kill(FN+'.HD3');
  Kill(FN+'.DA3');

  IDX := 1;
  i := 0;

  WHILE (i <= FileSize(MsgHdrF1) - 1) DO
  BEGIN
    Seek(MsgHdrF1,i);
    Read(MsgHdrF1,MHeader);

    IF (MHeader.Pointer - 1 + MHeader.TextSize > FileSize(BrdF1)) OR
       (MHeader.Pointer < 1) THEN
      MHeader.Status := [MDeleted];

    IF NOT (MDeleted IN MHeader.Status) THEN
    BEGIN
      Inc(IDX);
      Seek(BrdF1,MHeader.Pointer - 1);
      MHeader.Pointer := (FileSize(BrdF2) + 1);
      Write(MsgHdrF2,MHeader);

      TotLoad := 0;
      IF (MHeader.TextSize > 0) THEN
        WHILE (MHeader.TextSize > 0) DO
        BEGIN
          Buffered := MHeader.TextSize;
          IF (Buffered > 4096) THEN
            Buffered := 4096;
          Dec(MHeader.TextSize,Buffered);
          BlockRead(BrdF1,Buffer[1],Buffered);
          BlockWrite(BrdF2,Buffer[1],Buffered);
        END;
    END;
    Inc(i);
  END;

  Close(BrdF1);
  Close(BrdF2);
  Close(MsgHdrF1);
  Close(MsgHdrF2);

  ReName(BrdF1,FN+'.DA3');                     { ReName .DAT to .DA3 }

  IF (IOResult <> 0) THEN                      { Didn't work, abort  }
  BEGIN
    ErrMsg;
    Exit;
  END;

  ReName(BrdF2,FN+'.DAT');                     { ReName .DA2 to .DAT }

  IF (IOResult <> 0) THEN                      { Didn't work, abort  }
  BEGIN
    ErrMsg;
    ReName(BrdF1,FN+'.DAT');                 { ReName .DA3 to .DAT }
    Exit;
  END;

  ReName(MsgHdrF1,FN+'.HD3');                  { ReName .HDR to .HD3 }

  IF (IOResult <> 0) THEN                      { Didn't work, abort  }
  BEGIN
    ErrMsg;
    Erase(BrdF2);                            { Erase .DA2          }
    ReName(BrdF1,FN+'.DAT');                 { ReName .DA3 to .DAT }
    Exit;
  END;

  ReName(MsgHdrF2,FN+'.HDR');                  { ReName .HD2 to .HDR }

  IF (IOResult <> 0) THEN                      { Didn't work, abort  }
  BEGIN
    ErrMsg;
    Erase(BrdF2);                            { Erase .DAT (new)    }
    Erase(MsgHdrF2);                         { Erase .HD2 (new)    }
    ReName(BrdF1,FN+'.DAT');                 { ReName .DA3 to .DAT }
    ReName(MsgHdrF1,FN+'.HDR');              { ReName .HD3 to .HDR }
    Exit;
  END;

  Erase(MsgHdrF1);
  Erase(BrdF1);
END;

PROCEDURE PackMessageAreas(DataPath,MsgPath: STRING);
VAR
  MsgAreaFile: FILE OF MessageAreaRecordType;
  MsgArea: MessageAreaRecordType;
  MArea: Integer;
BEGIN
  PackMessageArea(MsgPath,'EMAIL',0);
  Assign(MsgAreaFile,DataPath+'MBASES.DAT');
  Reset(MsgAreaFile);
  FOR MArea := 0 TO (FileSize(MsgAreaFile) - 1) DO
  BEGIN
    Seek(MsgAreaFile,MArea);
    Read(MsgAreaFile,MsgArea);
    PackMessageArea(MsgPath,MsgArea.FileName,MsgArea.MaxMsgs);
  END;
  Close(MsgAreaFile);
END;

PROCEDURE SortFileArea(VAR DirFile1: DirF; NumFiles: Integer);
VAR
  F1,
  F2: FileInfoRecordType;
  NumSorted,
  RecNum,
  RecNum1,
  Gap: Integer;
BEGIN
  Gap := NumFiles;
  REPEAT;
    Gap := (Gap DIV 2);
    IF (Gap = 0) THEN
      Gap := 1;
    NumSorted := 0;
    FOR RecNum := 1 TO (NumFiles - Gap) DO
    BEGIN
      RecNum1 := (RecNum + Gap);
      Seek(DirFile1,(RecNum - 1));
      Read(DirFile1,F1);
      Seek(DirFile1,(RecNum1 - 1));
      Read(DirFile1,F2);
      IF (F1.FileName > F2.FileName) THEN
      BEGIN
        Seek(DirFile1,(RecNum - 1));
        Write(DirFile1,F2);
        Seek(DirFile1,(RecNum1 - 1));
        Write(DirFile1,F1);
        Inc(NumSorted);
      END;
    END;
  UNTIL (NumSorted = 0) AND (Gap = 1);
END;

PROCEDURE SortAllFileAreas(DataPath: STRING);
VAR
  FileAreaFile: FILE OF FileAreaRecordType;
  DirFile: DirF;
  FileArea: FileAreaRecordType;
  F: FileInfoRecordType;
  NumFiles,
  Counter: Integer;
BEGIN
  Assign(FileAreaFile,DataPath+'FBASES.DAT');
  Reset(FileAreaFile);
  FOR Counter := 0 TO (FileSize(FileAreaFile) - 1) DO
  BEGIN
    Seek(FileAreaFile,Counter);
    Read(FileAreaFile,FileArea);
    IF (FADirDLPath IN FileArea.FAFlags) THEN
      Assign(Dirfile,FileArea.Dlpath+FileArea.FileName+'.DIR')
    ELSE
      Assign(Dirfile,Datapath+FileArea.FileName+'.DIR');
    Reset(Dirfile);
    IF (IOResult = 2) THEN
      ReWrite(Dirfile);
    NumFiles := FileSize(DirFile);
    IF (NumFiles <> 0) THEN
      SortFileArea(DirFile,NumFiles);
    Close(DirFile);
  END;
  Close(FileAreaFile);
END;

PROCEDURE InsertIndex(VAR UserIndexFile1: SF; Uname: AStr; UserNum: Integer; IsReal,IsDeleted: Boolean);
VAR
  IndexR: UserIDXRec;
  Current,
  InsertAt: Integer;
  Done: Boolean;

  PROCEDURE WriteIndex;
  BEGIN
    FillChar(IndexR,SizeOf(IndexR),0);
    WITH IndexR DO
    BEGIN
      Name := Uname;
      Number := UserNum;
      RealName := IsReal;
      Deleted := IsDeleted;
      Left := -1;
      Right := -1;
      Write(UserIndexFile1,IndexR);
    END
  END;

BEGIN
  Done := FALSE;
  Uname := Allcaps(Uname);
  Current := 0;
  Reset(UserIndexFile1);
  IF (FileSize(UserIndexFile1) = 0) THEN
    WriteIndex
  ELSE
    REPEAT
      Seek(UserIndexFile1,Current);
      InsertAt := Current;
      Read(UserIndexFile1,IndexR);
      IF (Uname < IndexR.Name) THEN
        Current := IndexR.Left
      ELSE IF (Uname > IndexR.Name) THEN
        Current := IndexR.Right
      ELSE IF (IndexR.Deleted <> IsDeleted) THEN
      BEGIN
        Done := TRUE;
        IndexR.Deleted := IsDeleted;
        IndexR.RealName := IsReal;
        IndexR.Number := UserNum;
        Seek(UserIndexFile1,Current);
        Write(UserIndexFile1,IndexR);
      END
      ELSE
      BEGIN
        IF (UserNum <> IndexR.Number) THEN
          WriteLn('Note: Duplicate user '+UName+' #'+IntToStr(IndexR.Number)+' and '+UName+' #'+IntToStr(UserNum))
        ELSE
        BEGIN
          IndexR.RealName := FALSE;
          Seek(UserIndexFile1,Current);         { Make it be his handle IF it's BOTH }
          Write(UserIndexFile1,IndexR);
        END;
        Done := TRUE;
      END;
    UNTIL (Current = -1) OR (Done);
  IF (Current = -1) THEN
  BEGIN
    IF (Uname < IndexR.Name) THEN
      IndexR.Left := FileSize(UserIndexFile1)
    ELSE
      IndexR.Right := FileSize(UserIndexFile1);
    Seek(UserIndexFile1,InsertAt);
    Write(UserIndexFile1,IndexR);
    Seek(UserIndexFile1,FileSize(UserIndexFile1));
    WriteIndex;
  END;
  Close(UserIndexFile1);
END;

PROCEDURE PackUsers;
VAR
  GeneralFile: FILE OF GeneralRecordType;
  UserFile: FILE OF UserRecordType;
  UserFile1: FILE OF UserRecordType;
  UserFile2: FILE OF UserRecordType;
  UserIndexFile: SF;
  F: FILE;
  General: GeneralRecordType;
  User,
  SysOpUser: UserRecordType;
  DeleteDateStr: STRING;
  TotalUsers,
  Counter: Integer;
  Year: Word;
  PackedDeleteDate: LongInt;
  UsersToDelete,
  DeleteByDate,
  InvalidDate: Boolean;
BEGIN
  DeleteByDate := FALSE;

  IF (ParamCount > 0) THEN
    FOR Counter := 1 TO ParamCount DO
      IF (AllCaps(Copy(ParamStr(Counter),1,2)) = AllCaps('-D')) THEN
      BEGIN
        DeleteDateStr := Copy(ParamStr(Counter),3,Length(ParamStr(Counter)));
        InvalidDate := FALSE;
        IF (Length(DeleteDateStr) <> 10) THEN
          InvalidDate := TRUE;
        IF (StrToInt(Copy(DeleteDateStr,1,2)) = 0) THEN
          InvalidDate := TRUE;
        IF (StrToInt(Copy(DeleteDateStr,1,2)) > 12) THEN
          InvalidDate := TRUE;
        IF (StrToInt(Copy(DeleteDateStr,4,2)) = 0) THEN
          InvalidDate := TRUE;
        IF (StrToInt(Copy(DeleteDateStr,1,2)) IN [1,3,5,7,8,10,12]) THEN
          IF (StrToInt(Copy(DeleteDateStr,4,2)) > 31) THEN
            InvalidDate := TRUE;
        IF (StrToInt(Copy(DeleteDateStr,1,2)) IN [4,6,9,11]) THEN
          IF (StrToInt(Copy(DeleteDateStr,4,2)) > 30) THEN
            InvalidDate := TRUE;
        IF (StrToInt(Copy(DeleteDateStr,1,2)) = 2) AND ((StrToInt(Copy(DeleteDateStr,7,4)) MOD 4) <> 0) THEN
          IF (StrToInt(Copy(DeleteDateStr,4,2)) > 28) THEN
            InvalidDate := TRUE;
        IF (StrToInt(Copy(DeleteDateStr,1,2)) = 2) AND ((StrToInt(Copy(DeleteDateStr,7,4)) MOD 4) = 0) THEN
          IF (StrToInt(Copy(DeleteDateStr,4,2)) > 29) THEN
            InvalidDate := TRUE;
        GetYear(Year);
        IF (StrToInt(Copy(DeleteDateStr,7,4)) > Year) THEN
          InvalidDate := TRUE;

      IF (InvalidDate) THEN
      BEGIN
        WriteLn;
        WriteLn(^G^G^G'Invalid date or format, valid format is "00/00/0000');
        Exit;
      END
      ELSE
      BEGIN
        PackedDeleteDate := Date2PD(DeleteDateStr);
        DeleteByDate := TRUE;
      END;
    END;

  ClrScr;
  WriteLn('Renegade User Packer Version 2.0');
  Writeln('Copyright 2009 - The Renegade Developement Team');
  WriteLn;
  Writeln('This utility will pack your Renegade BBS Version 1.0');
  WriteLn('USERS.DAT file and update all required data files.');
  WriteLn;
  WriteLn('User''s to be packed:');
  WriteLn(' - All user''s currently marked for deletion');
  IF (DeleteByDate) THEN
    WriteLn(' - All user''s that have not logged on since '+DeleteDateStr);
  WriteLn;
  WriteLn('This process could take awhile depending on the total number');
  WriteLn('of files on your BBS that require update.');
  WriteLn;
  IF PYNQ('Do you wish to continue? ') THEN
  BEGIN
    WriteLn;
    IF (NOT Exist('RENEGADE.DAT')) THEN
      WriteLn('This utility must be executed in the same directory as RENEGADE.DAT!')
    ELSE
    BEGIN
      Write('Reading RENEGADE.DAT ... ');
      Assign(GeneralFile,'RENEGADE.DAT');
      Reset(GeneralFile);
      Read(GeneralFile,General);
      Close(GeneralFile);
      WriteLn('Done!');

      WriteLn;
      Write('Checking USERS.DAT for user''s to pack ... ');
      Assign(UserFile,General.DataPath+'USERS.DAT');
      Reset(UserFile);
      UsersToDelete := FALSE;
      Counter := 2;
      WHILE (Counter <= (FileSize(UserFile) - 1)) AND (NOT UsersToDelete) DO
      BEGIN
        Seek(UserFile,Counter);
        Read(UserFile,User);
        IF (Deleted IN User.SFlags) OR (DeleteByDate) AND (NOT (FNoDeletion IN User.Flags))
           AND (User.LastOn < PackedDeleteDate) THEN
          UsersToDelete := TRUE;
        Inc(Counter);
      END;
      WriteLn('Done!');

      IF (NOT UsersToDelete) THEN
      BEGIN
        WriteLn;
        WriteLn(^G^G^G'No deleted user''s found to pack!');
      END
      ELSE
      BEGIN

        Write('Updating USERS.DAT "UserID" with record number for all user''s ... ');
        FOR Counter := 0 TO (FileSize(UserFile) - 1) DO
        BEGIN
          Seek(UserFile,Counter);
          Read(UserFile,User);
          User.UserID := Counter;
          Seek(UserFile,Counter);
          Write(UserFile,User);
        END;
        WriteLn('Done!');

        Write('Locating deleted user''s and creating USERS.DEL and USERS.BAK ... ');
        Assign(UserFile1,General.DataPath+'USERS.DEL');
        ReWrite(UserFile1);
        Assign(UserFile2,General.DataPath+'USERS.BAK');
        ReWrite(UserFile2);
        Seek(UserFile,0);
        Read(UserFile,User);
        User.UserID := 0;
        Seek(UserFile2,FileSize(UserFile2));
        Write(UserFile2,User);
        Seek(UserFile,1);
        Read(UserFile,User);
        User.UserID := 1;
        Seek(UserFile2,FileSize(UserFile2));
        Write(UserFile2,User);
        FOR Counter := 2 TO (FileSize(UserFile) - 1) DO
        BEGIN
          Seek(UserFile,Counter);
          Read(UserFile,User);
          IF (Deleted IN User.SFlags) OR (DeleteByDate) AND (NOT (FNoDeletion IN User.Flags))
             AND (User.LastOn < PackedDeleteDate) THEN
          BEGIN
            Seek(UserFile1,FileSize(UserFile1));
            Write(UserFile1,User);
          END
          ELSE
          BEGIN
            Seek(UserFile2,FileSize(UserFile2));
            Write(UserFile2,User);
          END;
        END;
        Close(UserFile);
        Close(UserFile2);
        WriteLn('Done!');

        Write('Removing voting records for deleted user''s ... ');
        FOR Counter := 0 TO (FileSize(UserFile1) - 1) DO
        BEGIN
          Seek(UserFile1,Counter);
          Read(UserFile1,User);
          KillUserVotes(General.DataPath,User);
          Seek(UserFile1,Counter);
          Write(UserFile1,User);
        END;
        WriteLn('Done!');

        Write('Setting SHORTMSG.DAT "Destin" to -1 for deleted user''s ... ');
        FOR Counter := 0 TO (FileSize(UserFile1) - 1) DO
        BEGIN
          Seek(UserFile1,Counter);
          Read(UserFile1,User);
          KillShortMsgs(General.DataPath,User);
        END;
        WriteLn('Done!');

        Write('Updating SHORTMSG.DAT "Destin" with new user number ... ');
        Reset(UserFile2);
        FOR Counter := 1 TO (FileSize(UserFile2) - 1) DO
        BEGIN
          Seek(UserFile2,Counter);
          Read(UserFile2,User);
          UpdateShortMsgs(General.DataPath,User,Counter);
        END;
        Close(UserFile2);
        WriteLn('Done!');

        (*
        Write('Setting BATCHDL.DAT "BDLUserNum" to -1 for all deleted user''s ... ');
        FOR Counter := 0 TO (FileSize(UserFile1) - 1) DO
        BEGIN
          Seek(UserFile1,Counter);
          Read(UserFile1,User);
          KillBatchQueue(General.DataPath,User);
        END;
        WriteLn('Done!');

        Write('Updating BATCHDL.DAT "BDLUserNum" with new user number ... ');
        Reset(UserFile2);
        FOR Counter := 1 TO (FileSize(UserFile2) - 1) DO
        BEGIN
          Seek(UserFile2,Counter);
          Read(UserFile2,User);
          UpdateBatchQueue(General.DataPath,User,Counter);
        END;
        Close(UserFile2);
        WriteLn('Done!');

        Write('Setting EMAIL.HDR "MDeleted" for email to/from deleted user''s ... ');
        FOR Counter := 0 TO (FileSize(UserFile1) - 1) DO
        BEGIN
          Seek(UserFile1,Counter);
          Read(UserFile1,User);
          KillUserEMail(General.DataPath,General.MsgPath,User);
          Seek(UserFile1,Counter);
          Write(UserFile1,User);
        END;
        WriteLn('Done!');

        Write('Updating EMAIL.HDR "MTO/FROM" with new user number ... ');
        Reset(UserFile2);
        FOR Counter := 1 TO (FileSize(UserFile2) - 1) DO
        BEGIN
          Seek(UserFile2,Counter);
          Read(UserFile2,User);
          UpdateUserEMail(General.MsgPath,User,Counter);
          Seek(UserFile2,Counter);
          Write(UserFile2,User);
        END;
        Close(UserFile2);
        WriteLn('Done!');

        Write('Updating *.DIR files with sysop name/number for all deleted user''s ... ');
        Assign(UserFile2,General.DataPath+'USERS.BAK');
        Reset(UserFile2);
        Seek(UserFile2,1);
        Read(UserFile2,SysOpUser);
        Close(UserFile2);
        Reset(UserFile1);
        FOR Counter := 0 TO (FileSize(UserFile1) - 1) DO
        BEGIN
          Seek(UserFile1,Counter);
          Read(UserFile1,User);
          UpdateDIRFilesDeletedUsers(General.DataPath,User,SysOpUser);
        END;
        WriteLn('Done!');

        Write('Updating *.DIR files with new user number ... ');
        Reset(UserFile2);
        FOR Counter := 1 TO (FileSize(UserFile2) - 1) DO
        BEGIN
          Seek(UserFile2,Counter);
          Read(UserFile2,User);
          UpdateDIRFilesExistingUsers(General.DataPath,User,Counter);
        END;
        Close(UserFile2);
        WriteLn('Done!');

        Write('Setting *.HDR files "MTO/FROM" to 0 for all deleted user''s ... ');
        Reset(UserFile1);
        FOR Counter := 0 TO (FileSize(UserFile1) - 1) DO
        BEGIN
          Seek(UserFile1,Counter);
          Read(UserFile1,User);
          UpdateMsgFilesDeletedUsers(General.DataPath,General.MsgPath,User);
        END;
        WriteLn('Done!');

        Write('Updating *.HDR files with new user number for existing user''s ... ');
        Reset(UserFile2);
        FOR Counter := 1 TO (FileSize(UserFile2) - 1) DO
        BEGIN
          Seek(UserFile2,Counter);
          Read(UserFile2,User);
          UpdateMsgFilesExistingUsers(General.DataPath,General.MsgPath,User,Counter);
        END;
        Close(UserFile2);
        WriteLn('Done!');

        Write('Updating file area scan flags for existing user''s ... ');
        UpdateFileSCNFilesExistingUsers(General.DataPath);
        WriteLn('Done!');

        Write('Updating message area scan flags for existing user''s ... ');
        UpdateMsgSCNFilesExistingUsers(General.DataPath,General.MsgPath);
        WriteLn('Done!');

        Write('Re-Scaning email waiting for existing user''s ... ');
        Reset(UserFile2);
        FOR Counter := 1 TO (FileSize(UserFile2) - 1) DO
        BEGIN
          Seek(UserFile2,Counter);
          Read(UserFile2,User);
          ReScanUserEMail(General.MsgPath,User,Counter);
          Seek(UserFile2,Counter);
          Write(UserFile2,User);
        END;
        WriteLn('Done!');

        Write('Re-Scaning voting for existing user''s ... ');
        ResetVotes(General.DataPath);
        FOR Counter := 1 TO (FileSize(UserFile2) - 1) DO
        BEGIN
          Seek(UserFile2,Counter);
          Read(UserFile2,User);
          ReScanUserVotes(General.DataPath,User);
          Seek(UserFile2,Counter);
          Write(UserFile2,User);
        END;
        WriteLn('Done!');

        Write('Updating UserID with record number for existing user''s ... ');
        FOR Counter := 0 TO (FileSize(UserFile2) - 1) DO
        BEGIN
          Seek(UserFile2,Counter);
          Read(UserFile2,User);
          User.UserID := Counter;
          Seek(UserFile2,Counter);
          Write(UserFile2,User);
        END;
        WriteLn('Done!');

        Write('Purging SHORTMSG.DAT of deleted records ... ');
        PurgingShortMsgs(General.DataPath);
        WriteLn('Done!');

        Write('Purging BATCHDL.DAT of deleted records ... ');
        PurgingBatchQueue(General.DataPath);
        WriteLn('Done!');

        Write('Updating all File Area file size ... ');
        UpdateDIRFileSize(General.DataPath);
        WriteLn('Done!');

        Write('Sorting all file areas ... ');
        SortAllFileAreas(General.DataPath);
        WriteLn('Done!');

        Write('Packing all message areas ... ');
        PackMessageAreas(General.DataPath,General.MsgPath);
        WriteLn('Done!');

        Write('Deleting USERS.DEL ... ');
        Close(UserFile1);
        Erase(UserFile1);
        WriteLn('Done!');

        Write('Deleting USERS.DAT ... ');
        Erase(UserFile);
        WriteLn('Done!');

        Write('Re-Naming USERS.BAK to USERS.DAT ... ');
        ReName(UserFile2,General.DataPath+'USERS.DAT');
        WriteLn('Done!');

        Write('Deleting USERS.IDX ... ');
        Assign(F,General.DataPath+'USERS.IDX');
        Erase(F);
        WriteLn('Done!');

        Write('Creating and re-indexing USERS.IDX ... ');
        TotalUsers := 0;
        Assign(UserIndexFile,General.DataPath+'USERS.IDX');
        ReWrite(UserIndexFile);
        Reset(UserFile2);
        FOR Counter := 1 TO (FileSize(UserFile2) - 1) DO
        BEGIN
          Seek(UserFile2,Counter);
          Read(UserFile2,User);
          IF NOT (Deleted IN User.SFLags) THEN
            Inc(TotalUsers);
          InsertIndex(UserIndexFile,User.Name,Counter,FALSE,(Deleted IN User.SFLags));
          InsertIndex(UserIndexFile,User.RealName,Counter,TRUE,(Deleted IN User.SFLags));
        END;
        Close(UserFile2);
        WriteLn('Done!');

        Write('Updating RENEGADE.DAT "NumUsers" ... ');
        Assign(GeneralFile,'RENEGADE.DAT');
        Reset(GeneralFile);
        Read(GeneralFile,General);
        General.NumUsers := TotalUsers;
        Seek(GeneralFile,0);
        Write(GeneralFile,General);
        Close(GeneralFile);
        WriteLn('Done!');
        *)

        WriteLn;
        WriteLn(^G^G^G'Your USERS.DAT file has been packed and associated files have been updated.');
     END;
    END;
  END;
END;

BEGIN
  PackUsers;
END.