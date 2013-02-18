{$IFDEF WIN32}
{$I DEFINES.INC}
{$ENDIF}

{$A+,B-,D+,E-,F+,I-,L+,N-,O+,R-,S+,V-}

UNIT Mail3;

INTERFACE

PROCEDURE EditMessageText(MsgNum: Word);
PROCEDURE ForwardMessage(MsgNum: Word);
PROCEDURE MoveMsg(MsgNum: Word);

IMPLEMENTATION

USES
  Dos,
  Common,
  Common5,
  Mail0,
  Mail1,
  Mail4,
  MsgPack,
  MiscUser,
  TimeFunc;

PROCEDURE EditMessageText(MsgNum: Word);
VAR
  TempQuoteFile: Text;
  MHeader: MHeaderRec;
  MsgTempStr: STRING;
  SaveFileAttached: Byte;
  TempTextSize: Word;
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
  TempTextSize := 0;
  REPEAT
    BlockRead(MsgTxtF,MsgTempStr[0],1);
    BlockRead(MsgTxtF,MsgTempStr[1],Ord(MsgTempStr[0]));
    LastError := IOResult;
    IF (LastError <> 0) THEN
    BEGIN
      NL;
      Print('Error reading from '+MemMsgArea.FileName+'.DAT file.');
      SysOpLog('Error reading from '+MemMsgArea.FileName+'.DAT file.');
      TempTextSize := MHeader.TextSize;
    END;
    Inc(TempTextSize,(Length(MsgTempStr) + 1));
    WriteLn(TempQuoteFile,MsgTempStr);
    LastError := IOResult;
    IF (LastError <> 0) THEN
    BEGIN
      NL;
      Print('Error writting to TEMPQ'+IntToStr(ThisNode)+'.MSG file.');
      SysOpLog('Error writting to TEMPQ'+IntToStr(ThisNode)+'.MSG file.');
      TempTextSize := MHeader.TextSize;
    END;
  UNTIL (TempTextSize >= MHeader.TextSize);
  Close(MsgTxtF);
  Close(TempQuoteFile);
  GetFileDateTime('TEMPQ'+IntToStr(ThisNode)+'.MSG',FileDateTime1);
  SaveFileAttached := MHeader.FileAttached;
  IF NOT (InputMessage((ReadMsgArea <> -1),FALSE,'',MHeader,'TEMPQ'+IntToStr(ThisNode)+'.MSG',78,500)) THEN
  BEGIN
    Kill('TEMPQ'+IntToStr(ThisNode)+'.MSG');
    Exit;
  END;
  MHeader.FileAttached := SaveFileAttached;
  GetFileDateTime('TEMPQ'+IntToStr(ThisNode)+'.MSG',FileDateTime2);
  IF (FileDateTime1 <> FileDateTime2) THEN
  BEGIN
    Assign(TempQuoteFile,'TEMPQ'+IntToStr(ThisNode)+'.MSG');
    Reset(TempQuoteFile);
    MHeader.TextSize := 0;
    Reset(MsgTxtF,1);
    MHeader.Pointer := (FileSize(MsgTxtF) + 1);
    Seek(MsgTxtF,(MHeader.Pointer - 1));
    REPEAT
      ReadLn(TempQuoteFile,MsgTempStr);
      LastError := IOResult;
      IF (LastError <> 0) THEN
      BEGIN
        NL;
        Print('Error reading from TEMPQ'+IntToStr(ThisNode)+'.MSG file.');
        SysOpLog('Error reading from TEMPQ'+IntToStr(ThisNode)+'.MSG file.');
      END;
      Inc(MHeader.TextSize,(Length(MsgTempStr) + 1));
      BlockWrite(MsgTxtF,MsgTempStr,(Length(MsgTempStr) + 1));
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
  MsgTempStr: STRING;
  SaveReadMsgArea,
  Unum: Integer;
  TempTextSize: Word;
  TempPtr,
  TempPtr1: LongInt;
  ForwardOk,
  SaveConfSystem: Boolean;
BEGIN
  SaveReadMsgArea := ReadMsgArea;

  SaveConfSystem := ConfSystem;
  ConfSystem := FALSE;
  IF (SaveConfSystem) THEN
    NewCompTables;

  NL;
  Print('^5Forward message to which user (1-'+(IntToStr(MaxUsers - 1))+')?^1');
  NL;
  Print('Enter User Number, Name, or Partial Search String.');
  Prt(': ');
  lFindUserWS(UNum);
  IF (UNum < 1) THEN
    PauseScr(FALSE)
  ELSE
  BEGIN
    LoadURec(User,UNum);

    ForwardOk := TRUE;

    IF (User.Name = ThisUser.Name) THEN
    BEGIN
      NL;
      Print('^7You can not forward messages to yourself!^1');
      ForwardOk := FALSE;
    END
    ELSE IF (NoMail IN User.Flags) AND (NOT CoSysOp) THEN
    BEGIN
      NL;
      Print('^7The mailbox for this user is closed!^1');
      ForwardOk := FALSE;
    END
    ELSE IF (User.Waiting >= General.MaxWaiting) AND (NOT CoSysOp) THEN
    BEGIN
      NL;
      Print('^7The mailbox for this user is full!^1');
      ForwardOk := FALSE;
    END;

    IF (NOT ForwardOk) THEN
      PauseScr(FALSE)
    ELSE
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

      MsgTempStr := 'Message forwarded from '+Caps(ThisUser.Name);
      Inc(UNum,(Length(MsgTempStr) + 1));
      IF (SaveReadMsgArea <> -1) THEN
        BlockWrite(MsgTxtF1,MsgTempStr,(Length(MsgTempStr) + 1))
      ELSE
        BlockWrite(MsgTxtF,MsgTempStr,(Length(MsgTempStr) + 1));

      MsgTempStr := 'Message forwarded on '+DateStr+' at '+TimeStr;
      Inc(UNum,(Length(MsgTempStr) + 1));
      IF (SaveReadMsgArea <> -1) THEN
        BlockWrite(MsgTxtF1,MsgTempStr,(Length(MsgTempStr) + 1))
      ELSE
        BlockWrite(MsgTxtF,MsgTempStr,(Length(MsgTempStr) + 1));

      MsgTempStr := '';
      Inc(UNum,(Length(MsgTempStr) + 1));
      IF (SaveReadMsgArea <> -1) THEN
        BlockWrite(MsgTxtF1,MsgTempStr,(Length(MsgTempStr) + 1))
      ELSE
        BlockWrite(MsgTxtF,MsgTempStr,(Length(MsgTempStr) + 1));

      TempTextSize := 0;

      REPEAT
        Seek(MsgTxtF,(TempPtr + TempTextSize));

        BlockRead(MsgTxtF,MsgTempStr[0],1);

        BlockRead(MsgTxtF,MsgTempStr[1],Ord(MsgTempStr[0]));

        LastError := IOResult;

        Inc(TempTextSize,(Length(MsgTempStr) + 1));

        IF (SaveReadMsgArea <> - 1) THEN
        BEGIN
          Seek(MsgTxtF1,FileSize(MsgTxtF1));
          BlockWrite(MsgTxtF1,MsgTempStr,(Length(MsgTempStr) + 1));
        END
        ELSE
        BEGIN
          Seek(MsgTxtF,FileSize(MsgTxtF));
          BlockWrite(MsgTxtF,MsgTempStr,(Length(MsgTempStr) + 1));
        END;

      UNTIL (TempTextSize >= MHeader.TextSize);

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
      Print('Message forwarded to: ^5'+Caps(User.Name)+'^1');
      PauseScr(FALSE);

      SysOpLog('Message forwarded to: ^5'+Caps(User.Name));

    END;

  END;

  ConfSystem := SaveConfSystem;
  IF (SaveConfSystem) THEN
    NewCompTables;

  InitMsgArea(SaveReadMsgArea);
END;

PROCEDURE MoveMsg(MsgNum: Word);
VAR
  MsgHdrF1: FILE OF MHeaderRec;
  MsgTxtF1: FILE;
  MHeader: MHeaderRec;
  MsgTxtStr: STRING;
  InputStr: Str5;
  MArea,
  NumMAreas,
  SaveMArea,
  NewMsgArea,
  SaveReadMsgArea: Integer;
  TempTextSize: Word;
  SaveConfSystem: Boolean;
BEGIN
  SaveReadMsgArea := ReadMsgArea;
  SaveConfSystem := ConfSystem;
  ConfSystem := FALSE;
  IF (SaveConfSystem) THEN
    NewCompTables;
  MArea := 1;
  NumMAreas := 0;
  NewMsgArea := 0;
  LightBarCmd := 1;
  LightBarFirstCmd := TRUE;
  InputStr := '?';
  REPEAT
    SaveMArea := MArea;
    IF (InputStr = '?') THEN
      MessageAreaList(MArea,NumMAreas,5,FALSE);
    {
    %LFMove to which area? (^50^4=^5Private^4,^5'+IntToStr(LowMsgArea)+'^4-^5'+IntToStr(HighMsgArea)+'^4)
       [^5#^4,^5?^4=^5Help^4,^5Q^4=^5Quit^4]: @
    }
    MsgAreaScanInput(LRGLngStr(77,TRUE),Length(IntToStr(HighMsgArea)),InputStr,'Q[]?',LowMsgArea,HighMsgArea);
    IF (InputStr <> 'Q') THEN
    BEGIN
      IF (InputStr = '[') THEN
      BEGIN
        MArea := (SaveMArea - ((PageLength - 5) * 2));
        IF (MArea < 1) THEN
          MArea := 1;
        InputStr := '?';
      END
      ELSE IF (InputStr = ']') THEN
      BEGIN
        IF (MArea > NumMsgAreas) THEN
          MArea := SaveMArea;
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
        MArea := SaveMArea;
      END
      ELSE IF (StrToInt(InputStr) < 0) OR (StrToInt(InputStr) > HighMsgArea) THEN
      BEGIN
        NL;
        Print('^7The range must be from 0 to '+IntToStr(HighMsgArea)+'!^1');
        NL;
        PauseScr(FALSE);
        MArea := SaveMArea;
        InputStr := '?';
      END
      ELSE
      BEGIN
        IF (InputStr = '0') THEN
          NewMsgArea := -1
        ELSE
          NewMsgArea := CompMsgArea(StrToInt(InputStr),1);
        IF (NewMsgArea = ReadMsgArea) THEN
        BEGIN
          NL;
          Print('^7You can not move a message to the same area!^1');
          NL;
          PauseScr(FALSE);
          MArea := SaveMArea;
          InputStr := '?';
        END
        ELSE
        BEGIN
          InitMsgArea(NewMsgArea);
          IF (NOT MsgAreaAC(NewMsgArea)) THEN
          BEGIN
            NL;
            Print('^7You do not have access to this message area!^1');
            NL;
            PauseScr(FALSE);
            MArea := SaveMArea;
            InputStr := '?';
          END
          ELSE IF (NOT AACS(MemMsgArea.PostAcs)) THEN
          BEGIN
            NL;
            Print('^7You do not have posting access to this message area!^1');
            NL;
            PauseScr(FALSE);
            MArea := SaveMArea;
            InputStr := '?';
          END
          ELSE
          BEGIN
            NL;
            IF (NOT PYNQ('Move message to '+MemMsgArea.Name+'? ',0,FALSE)) THEN
            BEGIN
              MArea := SaveMArea;
              InputStr := '?';
            END
            ELSE
            BEGIN
              InitMsgArea(SaveReadMsgArea);
              LoadHeader(MsgNum,MHeader);
              IF (NOT (MDeleted IN MHeader.Status)) THEN
                Include(MHeader.Status,MDeleted);
              SaveHeader(MsgNum,MHeader);
              LoadMsgArea(NewMsgArea);
              Assign(MsgHdrF1,General.MsgPath+MemMsgArea.FileName+'.HDR');
              Reset(MsgHdrF1);
              IF (IOResult = 2) THEN
                ReWrite(MsgHdrF1);
              Seek(MsgHdrF1,FileSize(MsgHdrF1));
              Assign(MsgTxtF1,General.MsgPath+MemMsgArea.FileName+'.DAT');
              Reset(MsgTxtF1,1);
              IF (IOResult = 2) THEN
                ReWrite(MsgTxtF1,1);
              Reset(MsgTxtF,1);
              Seek(MsgTxtF,(MHeader.Pointer - 1));
              MHeader.Pointer := (FileSize(MsgTxtF1) + 1);
              Seek(MsgTxtF1,FileSize(MsgTxtF1));
              IF (MDeleted IN MHeader.Status) THEN
                Exclude(MHeader.Status,MDeleted);
              Write(MsgHdrF1,MHeader);
              Close(MsgHdrF1);
              TempTextSize := 0;
              REPEAT
                BlockRead(MsgTxtF,MsgTxtStr[0],1);
                BlockRead(MsgTxtF,MsgTxtStr[1],Ord(MsgTxtStr[0]));
                LastError := IOResult;
                Inc(TempTextSize,(Length(MsgTxtStr) + 1));
                BlockWrite(MsgTxtF1,MsgTxtStr,(Length(MsgTxtStr) + 1));
                LastError := IOResult;
              UNTIL (TempTextSize >= MHeader.TextSize);
              Close(MsgTxtF1);
              Close(MsgTxtF);
              NL;
              Print('The message was moved successfully.');
              InputStr := 'Q';
            END;
          END;
          ReadMsgArea := SaveReadMsgArea;
        END;
      END;
    END;
  UNTIL (InputStr = 'Q') OR (HangUp);
  ConfSystem := SaveConfSystem;
  IF (SaveConfSystem) THEN
    NewCompTables;
  InitMsgArea(SaveReadMsgArea);
END;

END.
