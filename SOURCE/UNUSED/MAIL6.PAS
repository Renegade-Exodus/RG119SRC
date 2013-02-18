{$A+,B-,D+,E-,F+,I-,L+,N-,O+,R-,S+,V-}

UNIT Mail6;

INTERFACE

PROCEDURE EditMessageText(MsgNum: Word);
PROCEDURE ForwardMessage(MsgNum: Word);
PROCEDURE MoveMsg(MsgNum: Word);
PROCEDURE ToggleMsgAreaScanFlags;

IMPLEMENTATION

USES
  Dos,
  Common,
  Mail0,
  Mail1,
  Mail7,
  MsgPack,
  MiscUser;

PROCEDURE EditMessageText(MsgNum: Word);
VAR
  TempQuoteFile: Text;
  MHeader: MHeaderRec;
  TempStr: STRING;
  SaveFileAttached: Byte;
  TotLoad: Word;
  FileDateTime1,
  FileDateTime2: LongInt;
BEGIN
  SysOpLog('Edited message #'+IntToStr(MsgNum)+' on '+MemMsgArea.Name);
  Assign(TempQuoteFile,'TEMPQ'+IntToStr(ThisNode)+'.MSG');
  ReWrite(TempQuoteFile);
  LastError := IOResult;
  IF (LastError <> 0) THEN
  BEGIN
    NL;
    Print('Error creating TEMPQ'+IntToStr(ThisNode)+'.MSG file.');
    SysOpLog('Error creating TEMPQ'+IntToStr(ThisNode)+'.MSG file.');
    Exit;
  END;
  LoadHeader(MsgNum,MHeader);
  Reset(MsgTxtF,1);
  Seek(MsgTxtF,(MHeader.Pointer - 1));
  TotLoad := 0;
  REPEAT
    BlockRead(MsgTxtF,TempStr[0],1);
    BlockRead(MsgTxtF,TempStr[1],Ord(TempStr[0]));
    LastError := IOResult;
    IF (LastError <> 0) THEN
    BEGIN
      NL;
      Print('Error reading from '+MemMsgArea.FileName+'.DAT file.');
      SysOpLog('Error reading from '+MemMsgArea.FileName+'.DAT file.');
      TotLoad := MHeader.TextSize;
    END;
    Inc(TotLoad,(Length(TempStr) + 1));
    WriteLn(TempQuoteFile,TempStr);
    LastError := IOResult;
    IF (LastError <> 0) THEN
    BEGIN
      NL;
      Print('Error writting to TEMPQ'+IntToStr(ThisNode)+'.MSG file.');
      SysOpLog('Error writting to TEMPQ'+IntToStr(ThisNode)+'.MSG file.');
      TotLoad := MHeader.TextSize;
    END;
  UNTIL (TotLoad >= MHeader.TextSize);
  Close(MsgTxtF);
  Close(TempQuoteFile);
  FileDateTime1 := GetFileDateTime('TEMPQ'+IntToStr(ThisNode)+'.MSG');
  SaveFileAttached := MHeader.FileAttached;
  IF NOT (InputMessage((ReadMsgArea <> -1),FALSE,TRUE,'',MHeader,'TEMPQ'+IntToStr(ThisNode)+'.MSG')) THEN
  BEGIN
    Kill('TEMPQ'+IntToStr(ThisNode)+'.MSG');
    Exit;
  END;
  MHeader.FileAttached := SaveFileAttached;
  FileDateTime2 := GetFileDateTime('TEMPQ'+IntToStr(ThisNode)+'.MSG');
  IF (FileDateTime1 <> FileDateTime2) THEN
  BEGIN
    Assign(TempQuoteFile,'TEMPQ'+IntToStr(ThisNode)+'.MSG');
    Reset(TempQuoteFile);
    MHeader.TextSize := 0;
    Reset(MsgTxtF,1);
    MHeader.Pointer := (FileSize(MsgTxtF) + 1);
    Seek(MsgTxtF,(MHeader.Pointer - 1));
    REPEAT
      ReadLn(TempQuoteFile,TempStr);
      LastError := IOResult;
      IF (LastError <> 0) THEN
      BEGIN
        NL;
        Print('Error reading from TEMPQ'+IntToStr(ThisNode)+'.MSG file.');
        SysOpLog('Error reading from TEMPQ'+IntToStr(ThisNode)+'.MSG file.');
      END;
      Inc(MHeader.TextSize,(Length(TempStr) + 1));
      BlockWrite(MsgTxtF,TempStr,(Length(TempStr) + 1));
      LastError := IOResult;
      IF (LastError <> 0) THEN
      BEGIN
        NL;
        Print('Error writting to '+MemMsgArea.FileName+'.DAT file.');
        SysOpLog('Error writting to '+MemMsgArea.FileName+'.DAT file.');
      END;
    UNTIL (EOF(TempQuoteFile));
    Close(MsgTxtF);
    Close(TempQuoteFile);
    SaveHeader(MsgNum,MHeader);
    LastError := IOResult;
  END;
  Kill('TEMPQ'+IntToStr(ThisNode)+'.MSG');
END;

PROCEDURE ForwardMessage(MsgNum: Word);
VAR
  MsgHdrF1: FILE OF MHeaderRec;
  MsgTxtF1: FILE;
  User: UserRecordType;
  MHeader: MHeaderRec;
  TempStr: STRING;
  SaveReadMsgArea,
  Unum: Integer;
  TempTextSize,
  TotLoad: Word;
  TempPtr,
  TempPtr1: LongInt;
  SaveConfSystem: Boolean;
BEGIN
  SaveReadMsgArea := ReadMsgArea;

  SaveConfSystem := ConfSystem;
  ConfSystem := FALSE;
  IF (SaveConfSystem) THEN
    NewCompTables;

  NL;
  Print('Forward message to which user (1-'+(IntToStr(MaxUsers - 1))+')?');
  NL;
  Print('Enter User Number, Name, or Partial Search String.');
  Prt(': ');
  lFindUserWS(UNum);
  IF (UNum > 0) THEN
  BEGIN
    IF (UNum = UserNum) THEN
    BEGIN
      NL;
      Print('You can not forward messages to yourself.');
    END
    ELSE
    BEGIN
      LoadURec(User,UNum);
      IF ((User.Waiting < General.MaxWaiting) AND NOT (NoMail IN User.Flags)) OR (CoSysOp) THEN
      BEGIN
        InitMsgArea(SaveReadMsgArea);

        LoadHeader(MsgNum,MHeader);

        Mheader.MTO.UserNum := UNum;
        MHeader.MTO.A1S := User.Name;
        MHeader.MTO.Name := User.Name;
        MHeader.MTO.Real := User.RealName;

        TempPtr := (MHeader.Pointer - 1);

        Reset(MsgTxtF,1);

        MHeader.Pointer := (FileSize(MsgTxtF) + 1);

        Seek(MsgTxtF,FileSize(MsgTxtF));

        IF (SaveReadMsgArea <> -1) THEN
        BEGIN

          LoadMsgArea(-1);

          Assign(MsgHdrF1,General.MsgPath+MemMsgArea.FIleName+'.HDR');
          Reset(MsgHdrF1);
          IF (IOResult = 2) THEN
            ReWrite(MsgHdrF1);

          Assign(MsgTxtF1,General.MsgPath+MemMsgArea.FIleName+'.DAT');
          Reset(MsgTxtF1,1);
          IF (IOResult = 2) THEN
            ReWrite(MsgTxtF1,1);

          TempPtr1 := (FileSize(MsgTxtF1) + 1);

          Seek(MsgTxtF1,FileSize(MsgTxtF1));
        END;

        UNum := 0;

        TempStr := 'Message forwarded from '+Caps(ThisUser.Name);
        Inc(UNum,(Length(TempStr) + 1));
        IF (SaveReadMsgArea <> -1) THEN
          BlockWrite(MsgTxtF1,TempStr,(Length(TempStr) + 1))
        ELSE
          BlockWrite(MsgTxtF,TempStr,(Length(TempStr) + 1));

        TempStr := 'Message forwarded on '+DateStr+' at '+TimeStr;
        Inc(UNum,(Length(TempStr) + 1));
        IF (SaveReadMsgArea <> -1) THEN
          BlockWrite(MsgTxtF1,TempStr,(Length(TempStr) + 1))
        ELSE
          BlockWrite(MsgTxtF,TempStr,(Length(TempStr) + 1));

        TempStr := '';
        Inc(UNum,(Length(TempStr) + 1));
        IF (SaveReadMsgArea <> -1) THEN
          BlockWrite(MsgTxtF1,TempStr,(Length(TempStr) + 1))
        ELSE
          BlockWrite(MsgTxtF,TempStr,(Length(TempStr) + 1));

        TotLoad := 0;

        REPEAT
          Seek(MsgTxtF,(TempPtr + TotLoad));

          BlockRead(MsgTxtF,TempStr[0],1);

          BlockRead(MsgTxtF,TempStr[1],Ord(TempStr[0]));

          LastError := IOResult;

          Inc(TotLoad,(Length(TempStr) + 1));

          IF (SaveReadMsgArea <> - 1) THEN
          BEGIN
            Seek(MsgTxtF1,FileSize(MsgTxtF1));
            BlockWrite(MsgTxtF1,TempStr,(Length(TempStr) + 1));
          END
          ELSE
          BEGIN
            Seek(MsgTxtF,FileSize(MsgTxtF));
            BlockWrite(MsgTxtF,TempStr,(Length(TempStr) + 1));
          END;

        UNTIL (TotLoad >= MHeader.TextSize);

        Close(MsgTxtF);
        IF (SaveReadMsgArea <> -1) THEN
        BEGIN
          Close(MsgTxtF1);
          Close(MsgHdrF1);
        END;

        Inc(MHeader.TextSize,UNum);

        IF (SaveReadMsgArea <> -1) THEN
        BEGIN
          InitMsgArea(-1);
          MHeader.Pointer := TempPtr1;
        END;

        SaveHeader((HiMsg + 1),MHeader);

        LoadURec(User,MHeader.MTO.UserNum);
        Inc(User.Waiting);
        SaveURec(User,MHeader.MTO.UserNum);

        NL;
        Print('A copy of this message has been forwarded.');

        SysOpLog('Forwarded message to '+Caps(User.Name));
      END;
    END;
  END;

  ConfSystem := SaveConfSystem;
  IF (SaveConfSystem) THEN
    NewCompTables;

  InitMsgArea(SaveReadMsgArea);
END;

PROCEDURE MoveMsg(MsgNum: Word);
VAR
  MsgHdrF1: File of MHeaderRec;
  MsgTxtF1: File;
  MHeader: MHeaderRec;
  TempStr: STRING;
  NewMsgArea,
  SaveReadMsgArea: Integer;
  TotLoad: Word;
  Done,
  SaveConfSystem: Boolean;
BEGIN
  SaveReadMsgArea := ReadMsgArea;

  SaveConfSystem := ConfSystem;
  ConfSystem := FALSE;
  IF (SaveConfSystem) THEN
    NewCompTables;

  NewMsgArea := 0;
  Done := FALSE;
  REPEAT
    NL;
    Prt('Move to which area? (^50^4-^5'+IntToStr(AmBase(NumMsgAreas))+'^4) [^5?^4=^5List^4] [^5Q^4=^5Quit^4]: ');
    ScanInput(TempStr,'?Q'^M);
    IF (TempStr = 'Q') OR (TempStr = ^M) OR (TempStr = '') THEN
      Done := TRUE
    ELSE IF (TempStr = '?') THEN
      MessageAreaList(FALSE)
    ELSE
    BEGIN
      IF (TempStr = '0') THEN
        NewMsgArea := -1
      ELSE
        NewMsgArea := AMBase(StrToInt(TempStr));
      IF (NewMsgArea = ReadMsgArea) THEN
      BEGIN
        NL;
        Print('You can not move a message to the same area.');
      END
      ELSE IF (NewMsgArea = -1) OR (NewMsgArea >= 1) AND (NewMsgArea <= NumMsgAreas) THEN
        Done := TRUE
      ELSE
      BEGIN
        NL;
        Print('You can not move a message to this area.');
      END;
    END;
  UNTIL ((Done) OR (HangUp));
  IF ((NewMsgArea >= 1) AND (NewMsgArea <= NumMsgAreas)) OR (NewMsgArea = -1) THEN
  BEGIN
    IF (MsgAreaAC(NewMsgArea)) THEN
    BEGIN
      InitMsgArea(SaveReadMsgArea);

      LoadHeader(MsgNum,MHeader);

      LoadMsgArea(NewMsgArea);

      Assign(MsgHdrF1,General.MsgPath+MemMsgArea.FIleName+'.HDR');
      Reset(MsgHdrF1);
      IF (IOResult = 2) THEN
        ReWrite(MsgHdrF1);

      Assign(MsgTxtF1,General.MsgPath+MemMsgArea.FIleName+'.DAT');
      Reset(MsgTxtF1,1);
      IF (IOResult = 2) THEN
        ReWrite(MsgTxtF1,1);

      Seek(MsgHdrF1,FileSize(MsgHdrF1));
      Reset(MsgTxtF,1);
      Seek(MsgTxtF,(MHeader.Pointer - 1));
      MHeader.Pointer := (FileSize(MsgTxtF1) + 1);
      Seek(MsgTxtF1,FileSize(MsgTxtF1));
      IF (MDeleted IN MHeader.Status) THEN
        Exclude(MHeader.Status,MDeleted);
      Write(MsgHdrF1,MHeader);
      Close(MsgHdrF1);
      TotLoad := 0;

      REPEAT
        BlockRead(MsgTxtF,TempStr[0],1);
        BlockRead(MsgTxtF,TempStr[1],Ord(TempStr[0]));
        LastError := IOResult;
        Inc(TotLoad,(Length(TempStr) + 1));
        BlockWrite(MsgTxtF1,TempStr,(Length(TempStr) + 1));
        LastError := IOResult;
      UNTIL (TotLoad >= MHeader.TextSize);
      Close(MsgTxtF1);
      Close(MsgTxtF);
      InitMsgArea(SaveReadMsgArea);
      LoadHeader(MsgNum,MHeader);
      Include(MHeader.Status,MDeleted);
      SaveHeader(MsgNum,MHeader);
      NL;
      Print('The message was moved successfully.');
    END;
  END;

  ConfSystem := SaveConfSystem;
  IF (SaveConfSystem) THEN
    NewCompTables;

  InitMsgArea(SaveReadMsgArea);
END;

(*
PROCEDURE ToggleFileAreaScanFlags;
VAR
  InputStr: STRING[9];
  Temp,
  First,
  Last,
  SaveFileBoard: Integer;
  SaveConfSystem: Boolean;

  PROCEDURE ToggleScanFlags(Start,Finish: Integer; ScanType: Byte);
  VAR
    ScanArea: Boolean;
  BEGIN
    FOR FileBoard := Start TO Finish DO
    BEGIN
      InitFileArea(FileBoard);
      Reset(ScnFile);
      Seek(ScnFile,(UserNum - 1));
      IF (ScanType = 1) THEN
        ScanArea := TRUE
      ELSE IF (ScanType = 2) THEN
        ScanArea := FALSE
      ELSE IF (ScanType = 3) THEN
        ScanArea := NOT NewScanFBase;
      Write(ScnFile,ScanArea);
      Close(ScnFile);
    END;
    IF (ScanType IN [1..2]) OR (ScanType = 3) AND (First = Last) THEN
      NL;
    IF (ScanType = 1) THEN
      Print('You are now scanning all file areas.')
    ELSE IF (ScanType = 2) THEN
      Print('You are now not scanning any file areas.')
    ELSE IF (ScanType = 3) THEN
      IF (First = Last) THEN
        Print('^5'+MemFileArea.Name+'^3 will '+AOnOff(ScanArea,'','not ')+'be scanned.');
    IF (ScanType IN [1..2]) OR (ScanType = 3) AND (First = Last) THEN
      NL;
  END;

BEGIN
  SaveFileBoard := FileBoard;
  SaveConfSystem := ConfSystem;
  ConfSystem := FALSE;
  IF (SaveConfSystem) THEN
    NewCompTables;
  IF (Novice IN ThisUser.Flags) THEN
    FileAreaList(TRUE)
  ELSE
    NL;
  REPEAT
    Prt('Range to toggle (^5x^4-^5y^4), [^5F^4]lag or [^5U^4]nflag all, [^5?^4=^5List^4]: ');
    MPL(9);
    ScanInput(InputStr,'FU-?'^M);
    IF (InputStr = '-') THEN
      InputStr := ^M
    ELSE IF (InputStr = '?') THEN
      FileAreaList(TRUE)
    ELSE IF (InputStr = 'F') THEN
      ToggleScanFlags(1,NumFileAreas,1)
    ELSE IF (InputStr = 'U') THEN
      ToggleScanFlags(1,NumFileAreas,2)
    ELSE IF (StrToInt(InputStr) > 0) THEN
    BEGIN
      First := AFBase(StrToInt(InputStr));
      IF (Pos('-',InputStr) = 0) THEN
        Last := First
      ELSE
      BEGIN
        Last := AFBase(StrToInt(Copy(InputStr,(Pos('-',InputStr) + 1),(Length(InputStr) - Pos('-',InputStr)))));
        IF (First > Last) THEN
        BEGIN
          Temp := First;
          First := Last;
          Last := Temp;
        END;
      END;
      IF (First >= 1) AND (Last <= NumFileAreas) THEN
        ToggleScanFlags(First,Last,3)
      ELSE
      BEGIN
        NL;
        Print('Invalid range entered.');
        NL;
      END;
    END;
  UNTIL (InputStr = ^M) OR (HangUp);
  ConfSystem := SaveConfSystem;
  IF (SaveConfSystem) THEN
    NewCompTables;
  FileBoard := SaveFileBoard;
  InitFileArea(FileBoard);
  LastError := IOResult;
  LastCommandOvr := TRUE;
END;
*)

PROCEDURE ToggleMsgAreaScanFlags;
VAR
  InputStr: Str9;
  First,
  Last,
  Temp,
  SaveMsgArea: Integer;
  SaveConfSystem: Boolean;
BEGIN
  SaveMsgArea := MsgArea;
  SaveConfSystem := ConfSystem;
  ConfSystem := FALSE;
  IF (SaveConfSystem) THEN
    NewCompTables;
  MessageAreaList(TRUE);
  REPEAT
    Prt('Range to toggle (^5X^4-^5Y^4,^5F^4lag or ^5U^4nflag all,^5?^4=^5List^4,^5<CR>^4=^5Quit^4): ');
    MPL(9);
    ScanInput(InputStr,'FU-?'^M);
    IF (InputStr = '-') THEN
      InputStr := ^M
    ELSE IF (InputStr = '?') THEN
      MessageAreaList(TRUE)
    ELSE IF (InputStr = 'F') THEN
    BEGIN
      FOR MsgArea := 1 TO NumMsgAreas DO
      BEGIN
        InitMsgArea(MsgArea);
        IF (NOT NewScanMsgArea) THEN
          NewScanMsgArea := ToggleNewScan;
      END;
      NL;
      Print('You are now reading all message areas.');
      NL;
    END
    ELSE IF (InputStr = 'U') THEN
    BEGIN
      FOR MsgArea := 1 TO NumMsgAreas DO
      BEGIN
        InitMsgArea(MsgArea);
        IF (NewScanMsgArea) AND NOT (MAForceRead IN MemMsgArea.MAFlags) THEN
          NewScanMsgArea := ToggleNewScan;
      END;
      NL;
      Print('You are now not reading any message areas.');
      NL;
    END
    ELSE IF (StrToInt(InputStr) > 0) THEN
    BEGIN
      First := AMBase(StrToInt(InputStr));
      IF (Pos('-',InputStr) > 0) THEN
      BEGIN
        Last := AMBase(StrToInt(Copy(InputStr,(Pos('-',InputStr) + 1),255)));
        IF (First > Last) THEN
        BEGIN
          Temp := First;
          First := Last;
          Last := Temp;
        END;
      END
      ELSE
        Last := First;
      IF (First < 1) AND (Last > NumMsgAreas) THEN
      BEGIN
        NL;
        Print('Invalid range.');
        NL;
      END
      ELSE
      BEGIN
        FOR MsgArea := First TO Last DO
        BEGIN
          InitMsgArea(MsgArea);
          IF NOT (MAForceRead IN MemMsgArea.MAFlags) THEN
          BEGIN
            NewScanMsgArea := ToggleNewScan;
            IF (First = Last) THEN
            BEGIN
              NL;
              Print('^5' + MemMsgArea.Name + '^3 will ' + AOnOff(NewScanMsgArea, 'not ','')+ 'be scanned.');
              NL;
            END;
          END
          ELSE
          BEGIN
            NL;
            Print('^5' + MemMsgArea.Name + '^3 cannot be removed from your newscan.');
            NL;
          END;
        END;
      END;
    END;
  UNTIL (InputStr = ^M) OR (HangUp);
  ConfSystem := SaveConfSystem;
  IF (SaveConfSystem) THEN
    NewCompTables;
  MsgArea := SaveMsgArea;
  LoadMsgArea(MsgArea);
  LastCommandOvr := TRUE;
END;

END.
