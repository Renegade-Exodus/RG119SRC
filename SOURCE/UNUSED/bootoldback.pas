{$A+,B-,D+,E-,F+,I-,L+,N-,O+,R-,S+,V-}

UNIT Boot;

INTERFACE

PROCEDURE initp1;
PROCEDURE init;

IMPLEMENTATION

USES
  Crt,
  Dos,
  Common,
  MyIo,
  MiscUser,
  TimeFunc;

PROCEDURE initp1;
VAR
  LineFile: FILE OF LineRec;
  F: FILE OF Byte;
  User: UserRecordType;
  X: Byte;
  Counter: Integer;

  PROCEDURE FindBadPaths;
  CONST
    AnyDone: Boolean = FALSE;
  VAR
    BootFile: Text;
    DirName,
    DirDesc,
    S2: AStr;
    Counter: Byte;
  BEGIN
    InField_Out_FGrd := 7;
    Infield_Out_BkGd := 0;
    Infield_Inp_FGrd := 7;
    Infield_Inp_BkGd := 0;
    IF Exist('1STBOOT') THEN
    BEGIN
      General.DataPath := StartDir+'\DATA\';
      General.MiscPath := StartDir+'\MISC\';
      General.LogsPath := StartDir+'\LOGS\';
      General.MsgPath  := StartDir+'\MSGS\';
      General.NodePath := '';
      General.TempPath := StartDir+'\TEMP\';
      General.ProtPath := StartDir+'\PROT\';
      General.ArcsPath := StartDir+'\ARCS\';
      General.FileAttachPath := StartDir+'\FATTACH\';
      General.lMultPath := StartDir+'\STRING\';
      SaveGeneral(FALSE);
      Assign(BootFile,StartDir+'1STBOOT');
      Erase(BootFile);
    END;
    FOR Counter := 1 TO 8 DO
    BEGIN
      CASE Counter OF
        1 : BEGIN
              DirDesc := 'DATA';
              DirName := General.DataPath;
            END;
        2 : BEGIN
              DirDesc := 'MSGS';
              DirName := General.MsgPath;
            END;
        3 : BEGIN
              DirDesc := 'FATTACH';
              DirName := General.FileAttachPath;
            END;
        4 : BEGIN
              DirDesc := 'MISC';
              DirName := General.MiscPath;
            END;
        5 : BEGIN
              DirDesc := 'LOGS';
              DirName := General.LogsPath;
            END;
        6 : BEGIN
              DirDesc := 'ARC';
              DirName := General.ArcsPath;
            END;
        7 : BEGIN
              DirDesc := 'PROT';
              DirName := General.ProtPath;
            END;
        8 : BEGIN
              DirDesc := 'STRING';
              DirName := General.lMultPath;
            END;
      END;
      IF (NOT ExistDir(DirName)) THEN
      BEGIN
        AnyDone := TRUE;
        WriteLn(DirDesc+' path is currently '+DirName);
        WriteLn('This path is bad or missing.');
        REPEAT
          WriteLn;
          S2 := DirName;
          Write('New '+DirDesc+' path: ');
          InField(S2,40);
          S2 := AllCaps(SQOutSp(S2));
          IF (DirName = S2) OR (S2 = '') THEN
          BEGIN
            NL;
            WriteLn('Illegal pathname error');
            Halt(ExitErrors);
          END
          ELSE
          BEGIN
            IF (S2 <> '') THEN
              S2 := BSlash(S2,TRUE);
            IF (ExistDir(S2)) THEN
              CASE Counter OF
                1 : General.DataPath := S2;
                2 : General.MsgPath := S2;
                3 : General.FileAttachPath := S2;
                4 : General.MiscPath := S2;
                5 : General.LogsPath := S2;
                6 : General.ArcsPath := S2;
                7 : General.ProtPath := S2;
                8 : General.lMultPath := S2;
            END
            ELSE
            BEGIN
              WriteLn;
              WriteLn('That path does not exist!');
            END;
          END;
        UNTIL (ExistDir(S2));
      END;
    END;
    IF (AnyDone) THEN
      SaveGeneral(FALSE);
  END;

BEGIN
  FindBadPaths;

  TextColor(Yellow);
  Write('Opening and checking NODE'+IntToStr(ThisNode)+'.DAT ... ');
  Assign(LineFile,General.DataPath+'NODE'+IntToStr(ThisNode)+'.DAT');
  Reset(LineFile);
  LastError := IOResult;
  IF (LastError = 2) OR (FileSize(LineFile) = 0) THEN
  BEGIN
    TextColor(Red);
    IF (LastError = 2) THEN
    BEGIN
      WriteLn('File missing!');
      TextColor(Yellow);
      Write('Creating missing file NODE'+IntToStr(ThisNode)+'.DAT ... ');
      ReWrite(LineFile);
    END
    ELSE
    BEGIN
      WriteLn('Records missing!');
      TextColor(Yellow);
      Write('Inserting missing NODE'+IntToStr(ThisNode)+'.DAT records ... ');
    END;
    FillChar(Liner,SizeOf(Liner),0);
    WITH Liner DO
    BEGIN
      InitBaud := 19200;
      Comport := 1;
      MFlags := [CTSRTS];
      Init := 'ATV1S0=0M0E0H0|';
      Answer := 'ATA|';
      HangUp := '^ATH0|';
      Offhook := 'ATH1|';
      DoorPath := '';
      TeleConfNormal := '^4[%UN] ^9';
      TeleConfAnon := '^4[^9??^4] ^9';
      TeleConfGlobal := '^4[%UN ^0GLOBAL^4] ^9';
      TeleConfPrivate := '^4[%UN ^0PRIVATE^4] ^9';
      Ok := 'OK';
      Ring := 'RING';
      Reliable := '/ARQ';
      CallerID := 'NMBR = ';
      NoCarrier := 'NO CARRIER';
      Connect[1]  := 'CONNECT';
      Connect[2] := 'CONNECT 600';
      Connect[3]  := 'CONNECT 1200';
      Connect[4] := 'CONNECT 2400';
      Connect[5]  := 'CONNECT 4800';
      Connect[6] := 'CONNECT 7200';
      Connect[7]  := 'CONNECT 9600';
      Connect[8] := 'CONNECT 12000';
      Connect[9]  := 'CONNECT 14400';
      Connect[10] := 'CONNECT 16800';
      Connect[11] := 'CONNECT 19200';
      Connect[12] := 'CONNECT 21600';
      Connect[13] := 'CONNECT 24000';
      Connect[14] := 'CONNECT 26400';
      Connect[15] := 'CONNECT 28800';
      Connect[16] := 'CONNECT 31200';
      Connect[17] := 'CONNECT 33600';
      Connect[18] := 'CONNECT 38400';
      Connect[19] := 'CONNECT 57600';
      Connect[20] := 'CONNECT 115200';
      Connect[21] := '';
      Connect[22] := '';
      UseCallerID := FALSE;
      LogonACS := '';
      IRQ := '4';
      Address := '3F8';
      AnswerOnRing := 1;
      MultiRing := FALSE;
      NodeTelnetUrl := '';
    END;
    Write(LineFile,Liner);
  END;
  Close(LineFile);
  LastError := IOResult;
  WriteLn('Done.');

  Assign(F,General.DataPath+'NODE'+IntToStr(ThisNode)+'.DAT');
  Reset(F);
  X := 0;
  Seek(F,FileSize(F));
  WHILE (FileSize(F) < SizeOf(LineRec)) DO
     Write(F,X);
  Close(F);
  Reset(LineFile);
  Read(LineFile,Liner);
  Close(LineFile);

  IF (Liner.Comport = 0) THEN
    LocalIOOnly := TRUE;

  TempDir := Copy(General.TempPath,1,Length(General.TempPath) - 1)+IntToStr(ThisNode)+'\';
  IF (NOT ExistDir(TempDir)) THEN
    MkDir(Copy(TempDir,1,Length(TempDir) - 1));
  IF (NOT ExistDir(TempDir+'QWK\')) THEN
    MkDir(TempDir+'QWK');
  IF (NOT ExistDir(TempDir+'ARC\')) THEN
    MkDir(TempDir+'ARC');
  IF (NOT ExistDir(TempDir+'UP\')) THEN
    MkDir(TempDir+'UP');
  IF (NOT ExistDir(TempDir+'CD\')) THEN
    MkDir(TempDir+'CD');
  LastError := IOResult;
  IF (LastError <> 0) THEN
  BEGIN
    WriteLn('Error creating directories: '+TempDir);
    Delay(1000);
  END;

  Assign(SysOpLogFile,General.LogsPath+'SYSOP.LOG');
  Append(SysOpLogFile);
  LastError := IOResult;
  IF (LastError = 2) THEN
    ReWrite(SysOpLogFile);
  Close(SysOpLogFile);

  Assign(NodeFile,General.DataPath+'MULTNODE.DAT');
  IF (General.MultiNode) THEN
  BEGIN
    Reset(NodeFile);
    LastError := IOResult;
    IF (LastError = 2) THEN
      ReWrite(NodeFile);
    IF (FileSize(NodeFile) < ThisNode) THEN
    BEGIN
      Seek(NodeFile,FileSize(NodeFile));
      WITH NodeR DO
      BEGIN
        User := 0;
        UserName := '';
        CityState := '';
        Sex := 'M';
        Age := 0;
        LogonTime := 0;
        GroupChat := FALSE;
        ActivityDesc := '';
        Status := [NActive];
        Room := 0;
        Channel := 0;
        FillChar(Invited,SizeOf(Invited),0);
        FillChar(Booted,SizeOf(Booted),0);
        FillChar(Forget,SizeOf(Forget),0);
      END;
      WHILE (FileSize(NodeFile) < ThisNode) DO
        Write(NodeFile,NodeR);
    END;
    Close(NodeFile);
    Assign(SysOpLogFile,TempDir+'TEMPLOG.'+IntToStr(ThisNode))
  END
  ELSE
    Assign(SysOpLogFile,General.LogsPath+'SYSOP.LOG');

  Append(SysOpLogFile);
  LastError := IOResult;
  IF (LastError = 2) THEN
    ReWrite(SysOpLogFile);
  Close(SysOpLogFile);

  Assign(SysOpLogFile1,General.LogsPath+'SLOGXXXX.LOG');
  SL1('');
  SL1('');
  SL1('^7--> ^5Renegade '+General.Version+' Node '+IntToStr(ThisNode)+' Loaded on '+dat+'^7 <--');

  Assign(UserFile,General.DataPath+'USERS.DAT');

  IF ((MaxUsers - 1) >= 1) THEN
    LoadURec(ThisUser,1)
  ELSE
    Exclude(ThisUser.SFLags,SLogSeparate);

  Assign(UserIDXFile,General.DataPath+'USERS.IDX');
  Reset(UserIDXFile);
  LastError := IOResult;
  IF (LastError = 2) OR (MaxIDXRec = -1) THEN
  BEGIN
    IF (LastError = 0) THEN
      Close(UserIDXFile);
    Write('Regenerating corrupted User index:   0%');
    kill(General.DataPath+'USERS.IDX');
    General.NumUsers := 0;
    ReWrite(UserIDXFile);
    Reset(UserFile);
    FOR Counter := 1 TO (MaxUsers - 1) DO
    BEGIN
      LoadURec(User,Counter);
      IF (Counter MOD 25 = 0) THEN
        Write(^H^H^H^H,(Counter / FileSize(UserFile) * 100):3:0,'%');
      IF (NOT (Deleted IN User.SFLags)) THEN
        Inc(lTodayNumUsers);
      InsertIndex(User.Name,Counter,FALSE,(Deleted IN User.SFLags));
      InsertIndex(User.realname,Counter,TRUE,(Deleted IN User.SFLags));
    END;
    Close(UserFile);
    Close(UserIDXFile);
    WriteLn;
    SaveGeneral(FALSE);
    LastError := IOResult;
  END
  ELSE
    Close(UserIDXFile);

  Assign(EventFile,General.DataPath+'EVENTS.DAT');
  Reset(EventFile);
  LastError := IOResult;
  IF (LastError = 2) THEN
  BEGIN
    WriteLn('Bad or missing EVENTS.DAT - creating...');
    ReWrite(EventFile);
    NumEvents := 1;
    New(MemEventArray[1]);
    WITH MemEventArray[1]^ DO
    BEGIN
      EventDescription := '<< New Event >>';
      EventDayOfMonth := 0;
      EventDays := [];
      EventStartTime := 0;
      EventFinishTime := 0;
      EventQualMsg := '';
      EventNotQualMsg := '';
      EventPreTime := 0;
      EventNode := 0;
      EventLastDate := 0;
      EventErrorLevel := 0;
      EventShellPath := '';
      LoBaud := 300;
      HiBaud := 115200;
      EventACS := 's10';
      MaxTimeAllowed := 60;
      SetARflag := '@';
      ClearARflag := '@';
      EFlags := [EventIsExternal,EventIsShell];
    END;
    Write(EventFile,MemEventArray[1]^);
  END
  ELSE
  BEGIN
    NumEvents := 0;
    IF NOT EOF(EventFile) THEN
      REPEAT
        Inc(NumEvents);
        New(MemEventArray[NumEvents]);
        Read(EventFile,MemEventArray[NumEvents]^);
        IF (IOResult <> 0) THEN
        BEGIN
          SysOpLog('Warning: Bad events file format.');
          Break;
        END;
      UNTIL (EOF(EventFile));
  END;
  Close(EventFile);
  LastError := IOResult;

  (* Done - 01/04/08 - Lee Palmer *)
  TextColor(Yellow);
  Write('Opening and checking MEMAIL.DAT ... ');
  Assign(EmailFile,General.DataPath+'MEMAIL.DAT');
  Reset(EmailFile);
  LastError := IOResult;
  IF (LastError = 2) OR (FileSize(EmailFile) = 0) THEN
  BEGIN
    TextColor(Red);
    IF (LastError = 2) THEN
    BEGIN
      WriteLn('File missing!');
      TextColor(Yellow);
      Write('Creating missing file MEMAIL.DAT ... ');
      ReWrite(EmailFile);
    END
    ELSE
    BEGIN
      WriteLn('Records missing!');
      TextColor(Yellow);
      Write('Inserting missing MEMAIL.DAT records ... ');
    END;
    FillChar(MemMsgArea,SizeOf(MemMsgArea),0);
    WITH MemMsgArea DO
    BEGIN
      Name := 'Private Messages';
      FileName := 'EMAIL';
      MsgPath := '';
      ACS := '^';
      PostACS := '';
      MCIACS := '';
      SysOpACS := General.MSoP;
      MaxMsgs := 65535;
      Anonymous := ATNo;
      Password := '';
      MAFlags := [];
      MAType := 0;
      Origin := '';
      Text_Color := General.Text_Color;
      Quote_Color := General.Quote_Color;
      Tear_Color := General.Tear_Color;
      Origin_Color := General.Origin_Color;
      MessageReadMenu := 0;
      QuoteStart := '|03Quoting message from |11@F |03to |11@T';
      QuoteEnd := '|03on |11@D|03.';
      PrePostFile := '';
      AKA := 0;
      QWKIndex := 0;
    END;
    Write(EmailFile,MemMsgArea);
  END;
  Close(EmailFile);
  LastError := IOResult;
  WriteLn('Done.');

  (* Done - 01/04/08 - Lee Palmer *)
  TextColor(Yellow);
  Write('Opening and checking MBASES.DAT ... ');
  Assign(MsgAreaFile,General.DataPath+'MBASES.DAT');
  Reset(MsgAreaFile);
  LastError := IOResult;
  IF (LastError = 2) OR (FileSize(MsgAreaFile) = 0) THEN
  BEGIN
    TextColor(Red);
    IF (LastError = 2) THEN
    BEGIN
      WriteLn('File missing!');
      TextColor(Yellow);
      Write('Creating missing file MBASES.DAT ... ');
      ReWrite(MsgAreaFile);
    END
    ELSE
    BEGIN
      WriteLn('Records missing!');
      TextColor(Yellow);
      Write('Inserting missing MBASES.DAT records ... ');
    END;
    FillChar(MemMsgArea,SizeOf(MemMsgArea),0);
    WITH MemMsgArea DO
    BEGIN
      Name := '<< New Message Area >>';
      FileName := 'NEWBOARD';
      MsgPath := '';
      ACS := '';
      PostACS := '';
      MCIACS := '';
      SysOpACS := '';
      MaxMsgs := 100;
      Anonymous := ATNo;
      Password := '';
      MAFlags := [];
      MAType := 0;
      Origin := '';
      Text_Color := General.Text_Color;
      Quote_Color := General.Quote_Color;
      Tear_Color := General.Tear_Color;
      Origin_Color := General.Origin_Color;
      MessageReadMenu := 0;
      QuoteStart := '|03Quoting message from |11@F |03to |11@T';
      QuoteEnd := '|03on |11@D|03.';
      PrePostFile := '';
      AKA := 0;
      QWKIndex := (FileSize(MsgAreaFile) + 1);
    END;
    Write(MsgAreaFile,MemMsgArea);
  END;
  NumMsgAreas := FileSize(MsgAreaFile);
  Close(MsgAreaFile);
  LastError := IOResult;
  WriteLn('Done.');

  (* Done - 08/11/08 - Lee Palmer *)
  TextColor(Yellow);
  Write('Opening and checking CONFRENC.DAT ... ');
  Assign(ConferenceFile,General.DataPath+'CONFRENC.DAT');
  Reset(ConferenceFile);
  LastError := IOResult;
  IF (LastError = 2) OR (FileSize(ConferenceFile) = 0) THEN
  BEGIN
    TextColor(Red);
    IF (LastError = 2) THEN
    BEGIN
      WriteLn('File missing!');
      TextColor(Yellow);
      Write('Creating missing file CONFRENC.DAT ... ');
      ReWrite(ConferenceFile);
    END
    ELSE
    BEGIN
      WriteLn('Records missing!');
      TextColor(Yellow);
      Write('Inserting missing CONFRENC.DAT records ... ');
    END;
    FillChar(Conference,SizeOf(Conference),0);
    WITH Conference DO
    BEGIN
      Key := '@';
      Name := 'General';
      ACS := '';
    END;
    Write(ConferenceFile,Conference);
  END;
  NumConfKeys := FileSize(ConferenceFile);
  ConfKeys := [];
  Counter := 1;
  WHILE (Counter <= NumConfKeys) DO
  BEGIN
    Seek(ConferenceFile,(Counter - 1));
    Read(ConferenceFile,Conference);
    Include(ConfKeys,Conference.Key);
    Inc(Counter);
  END;
  Close(ConferenceFile);
  LastError := IOResult;
  WriteLn('Done.');

  (* Done - 01/04/08 - Lee Palmer *)
  TextColor(Yellow);
  Write('Opening and checking FBASES.DAT ... ');
  Assign(FileAreaFile,General.DataPath+'FBASES.DAT');
  Reset(FileAreaFile);
  LastError := IOResult;
  IF (LastError = 2) OR (FileSize(FileAreaFile) = 0) THEN
  BEGIN
    TextColor(Red);
    IF (LastError = 2) THEN
    BEGIN
      WriteLn('File missing!');
      TextColor(Yellow);
      Write('Creating missing file FBASES.DAT ... ');
      ReWrite(FileAreaFile);
    END
    ELSE
    BEGIN
      WriteLn('Records missing!');
      TextColor(Yellow);
      Write('Inserting missing FBASES.DAT records ... ');
    END;
    FillChar(MemFileArea,SizeOf(MemFileArea),0);
    WITH MemFileArea DO
    BEGIN
      AreaName := '<< New File Area >>';
      FileName := 'NEWDIR';
      DLPath := StartDir[1]+':\';
      ULPath := DLPath;
      MaxFiles := 2000;
      Password := '';
      ArcType := 0;
      CmtType := 0;
      ACS := '';
      ULACS := '';
      DLACS := '';
      FAFlags := [];
    END;
    Write(FileAreaFile,MemFileArea);
  END;
  NumFileAreas := FileSize(FileAreaFile);
  Close(FileAreaFile);
  LastError := IOResult;
  WriteLn('Done.');

  (* Done - 01/04/08 - Lee Palmer *)
  TextColor(Yellow);
  Write('Opening and checking PROTOCOL.DAT ... ');
  Assign(ProtocolFile,General.DataPath+'PROTOCOL.DAT');
  Reset(ProtocolFile);
  LastError := IOResult;
  IF (LastError = 2) OR (FileSize(ProtocolFile) = 0) THEN
  BEGIN
    TextColor(Red);
    IF (LastError = 2) THEN
    BEGIN
      WriteLn('File missing!');
      TextColor(Yellow);
      Write('Creating missing file PROTOCOL.DAT ... ');
      ReWrite(ProtocolFile);
    END
    ELSE
    BEGIN
      WriteLn('Records missing!');
      TextColor(Yellow);
      Write('Inserting missing PROTOCOL.DAT records ... ');
    END;
    FillChar(Protocol,SizeOf(Protocol),0);
    WITH Protocol DO
    BEGIN
      PRFlags := [ProtXferOkCode];
      CKeys := '!';
      Description := '<< New Protocol >>';
      ACS := '';
      TempLog := '';
      DLoadLog := '';
      ULoadLog := '';
      DLCmd := '';
      ULCmd := '';
      FOR Counter := 1 TO 6 DO
      BEGIN
        DLCode[Counter] := '';
        ULCode[Counter] := '';
      END;
      EnvCmd := '';
      DLFList := '';
      MaxChrs := 127;
      TempLogPF := 0;
      TempLogPS := 0;
    END;
    Write(ProtocolFile,Protocol);
  END;
  NumProtocols := FileSize(ProtocolFile);
  Close(ProtocolFile);
  LastError := IOResult;
  WriteLn('Done.');

  (* Done - 01/04/08 - Lee Palmer *)
  TextColor(Yellow);
  Write('Opening and checking SCHEME.DAT ... ');
  Assign(SchemeFile,General.DataPath+'SCHEME.DAT');
  Reset(SchemeFile);
  LastError := IOResult;
  IF (LastError = 2) OR (FileSize(SchemeFile) = 0) THEN
  BEGIN
    TextColor(Red);
    IF (LastError = 2) THEN
    BEGIN
      WriteLn('File missing!');
      TextColor(Yellow);
      Write('Creating missing file SCHEME.DAT ... ');
      ReWrite(SchemeFile);
    END
    ELSE
    BEGIN
      WriteLn('Records missing!');
      TextColor(Yellow);
      Write('Inserting missing SCHEME.DAT records ... ');
    END;
    FillChar(Scheme,SizeOf(Scheme),0);
    WITH Scheme DO
    BEGIN
      Description := 'Default Color Scheme';
      FillChar(Color,SizeOf(Color),7);
      Color[1] :=  15;
      Color[2] :=   7;
      Color[3] :=  13;
      Color[4] :=  11;
      Color[5] :=   9;
      Color[6] :=  14;
      Color[7] :=  31;
      Color[8] :=  12;
      Color[9] := 142;
      Color[10] :=  10;
    END;
    Write(SchemeFile,Scheme);
  END;
  NumSchemes := FileSize(SchemeFile);
  Close(SchemeFile);
  LastError := IOResult;
  WriteLn('Done.');

  (* Done - 01/04/08 - Lee Palmer *)
  TextColor(Yellow);
  Write('Opening and checking VOTING.DAT ... ');
  Assign(VotingFile,General.DataPath+'VOTING.DAT');
  Reset(VotingFile);
  LastError := IOResult;
  IF (LastError = 2) THEN
  BEGIN
    TextColor(Red);
    WriteLn('File missing!');
    TextColor(Yellow);
    Write('Creating missing file VOTING.DAT ... ');
    ReWrite(VotingFile);
  END;
  NumVotes := FileSize(VotingFile);
  Close(VotingFile);
  LastError := IOResult;
  WriteLn('Done.');

  TextColor(Yellow);
  Write('Opening and checking VALIDATE.DAT ... ');
  Assign(ValidationFile,General.DataPath+'VALIDATE.DAT');
  Reset(ValidationFile);
  LastError := IOResult;
  IF (LastError = 2) OR (FileSize(ValidationFile) = 0) THEN
  BEGIN
    TextColor(Red);
    IF (LastError = 2) THEN
    BEGIN
      WriteLn('File missing!');
      TextColor(Yellow);
      Write('Creating missing file VALIDATE.DAT ... ');
      ReWrite(ValidationFile);
    END
    ELSE
    BEGIN
      WriteLn('Records missing!');
      TextColor(Yellow);
      Write('Inserting missing VALIDATE.DAT records ... ');
    END;
    LoadURec(User,0);
    FillChar(Validation,SizeOf(Validation),0);
    WITH Validation DO
    BEGIN
      Key := '!';
      ExpireTo := ' ';
      Description := 'New user validation';
      UserMsg := 'You have been validated, enjoy the system!';
      NewSL := User.SL;
      NewDSL := User.DSL;
      NewMenu := 0;
      Expiration := 0;
      NewFP := 0;
      NewCredit := 0;
      SoftAR := TRUE;
      SoftAC := TRUE;
      NewAR := [];
      NewAC := [];
    END;
    Write(ValidationFile,Validation);
  END;
  NumValKeys := FileSize(ValidationFile);
  ValKeys := [];
  Counter := 1;
  WHILE (Counter <= NumValKeys) DO
  BEGIN
    Seek(ValidationFile,(Counter - 1));
    Read(ValidationFile,Validation);
    Include(ValKeys,Validation.Key);
    Inc(Counter);
  END;
  Close(ValidationFile);
  LastError := IOResult;
  WriteLn('Done.');

  NumArcs := 1;
  WHILE (NumArcs <= MaxArcs) AND (General.FileArcInfo[NumArcs].Ext <> '') DO
    Inc(NumArcs);
  Dec(NumArcs);

  FOR Counter := 1 TO MaxMenus DO
    MenuRecNumArray[Counter] := 0;
  FOR Counter := 1 TO MaxMenus DO
    CmdNumArray[Counter] := 0;
  NumMenus := 0;
  NumCmds := 0;
  Assign(MenuFile,General.DataPath+'MENUS.DAT');
  Reset(MenuFile);
  LastError := IOResult;
  IF (LastError <> 0) THEN
  BEGIN
    Print('System Error: MENUS.DAT file is missing!');
    Halt;
  END
  ELSE
  BEGIN
    Counter := 0;
    WHILE NOT EOF(MenuFile) DO
    BEGIN
      Read(MenuFile,MenuR);
      IF (MenuR.Menu = TRUE) THEN
      BEGIN
        Inc(NumMenus);
        MenuRecNumArray[NumMenus] := Counter;
        IF (NumMenus > 1) THEN
          CmdNumArray[NumMenus - 1] := NumCmds;
        NumCmds := 0;
      END
      ELSE
        Inc(NumCmds);
      Inc(Counter);
    END;
    CmdNumArray[NumMenus] := NumCmds;
    Close(MenuFile);
  END;

  CFO := FALSE;

END;

FUNCTION SchareLoaded: Boolean;
VAR
  T_Al: Byte;
BEGIN
  ASM
    Mov Ah,10h
    Mov Al,0h
    Int 2fh
    Mov T_Al,Al
  END;
  SchareLoaded := (T_Al = $FF);
END;

PROCEDURE FindTaskerType;
VAR
  D5,
  DOS_Major,
  DOS_Minor,
  Os2Vers: Word;
  DVOk,
  OS2Ok,
  WinOk,
  WinNTOk: Boolean;

  FUNCTION TrueDosVer(VAR WinNTOk: Boolean): Word;
  VAR
    Regs: Registers;
  BEGIN
    WITH Regs DO
    BEGIN
      Ax := $3306;
      MsDos(Regs);
      IF (Bx = $3205) THEN
        WinNTOk := TRUE
      ELSE
        WinNTOk := FALSE;
      TrueDosVer := Bl;
    END;
  END;

  FUNCTION DosVer(VAR Minor,OS2Ver: Word): Word;
  VAR
    Regs: Registers;
  BEGIN
    OS2Ver := 0;
    WITH Regs DO
    BEGIN
      Ax := $3000;
      MsDos(Regs);
      DosVer := Al;
      Minor  := Ah;
      IF (Al = $0A) THEN
        OS2Ver := 1
      ELSE IF (Al = $14) THEN
        OS2Ver := 2;
    END;
  END;

  FUNCTION Win3_Check_On: Boolean;
  VAR
    Regs: Registers;
  BEGIN
    WITH Regs DO
    BEGIN
      AX := $1600;
      Intr($2F,Regs);                         { $00 no Win 2.x or 3.x      }
      IF (AL IN [$00,$01,$80,$FF]) THEN       { $01 Win/386 2.x running    }
        Win3_Check_On := FALSE                { $80 obsolete XMS installed }
      ELSE                                    { $FF Win/386 2.x running    }
        Win3_Check_On := TRUE;
     END;
  END;

  FUNCTION DV_Check_On: Boolean;
  VAR
    Regs: Registers;
  BEGIN
    DV_Check_On := FALSE;
    WITH Regs DO
    BEGIN
      Ax := $2B01;
      Cx := $4445;
      Dx := $5351;
      Intr($21,Regs);
    END;
    IF (Regs.AL = $FF) THEN
      DV_Check_On := FALSE
    ELSE
      DV_Check_On := TRUE;
  END;

BEGIN
  D5 := 0;
  Tasker := None;
  DVOk  := FALSE;
  OS2Ok := FALSE;
  WinOk := FALSE;
  WinNTOk := FALSE;    { This could also be just plain old Dos 5.0+ }
  DOS_Major := DosVer(DOS_Minor,Os2Vers);
  IF (Os2Vers IN [1,2]) THEN
    OS2Ok := TRUE
  ELSE
    DVOk := DV_Check_On;
  IF (NOT DVOk) AND (NOT OS2Ok) THEN
  BEGIN
    WinOk := Win3_Check_On;
    IF (NOT WinOk) THEN
      CASE Dos_Major of
         5..9 : D5 := TrueDosVer(WinNTOk);
      END;
  END;
  IF (DVOk) THEN
    Tasker := DV
  ELSE IF (WinOk) THEN
    Tasker := Win
  ELSE IF (OS2Ok) THEN
    Tasker := OS2
  ELSE IF (WinNTOk) THEN
    Tasker := Win32
  ELSE IF (D5 >= 5) THEN
    Tasker := Dos5N;
END;

PROCEDURE init;
VAR
  Node: Byte;
BEGIN
  IF (DateStr = '01-01-1980') THEN
  BEGIN
    ClrScr;
    TextColor(Yellow);
    WriteLn('Please set the operating system date & time.');
    Halt(ExitErrors);
  END;

  FindTaskerType;

  IF (General.MultiNode) AND (NOT SchareLoaded) THEN
  BEGIN
    ClrScr;
    TextColor(Yellow);
    WriteLn('WARNING: SHARE.EXE should be loaded for MultiNode operation.');
    Delay(1000);
  END;

  HangUp := FALSE;
  InCom := FALSE;
  OutCom := FALSE;
  Echo := TRUE;
  DoneDay := FALSE;
  CheckBreak := FALSE;
  SLogging := TRUE;
  Trapping := FALSE;
  ReadingMail := FALSE;
  SysOpOn := FALSE;
  BeepEnd := FALSE;
  WantOut := TRUE;
  InChat := FALSE;
  LIL := 0;

  ThisUser.PageLen := 24;  (* Is this needed ??? *)

  Buf := '';
  ChatCall := FALSE;
  LastAuthor := 0;
  LastLineStr := '';
  ChatReason := '';

  DirectVideo := NOT General.UseBIOS;

  IF (General.NetworkMode) AND (ThisNode = 0) THEN
  BEGIN
    LocalIOOnly := TRUE;
    Node := 1;
    WHILE (Node <= MaxNodes) AND (ThisNode = 0) DO
    BEGIN
      LoadNode(Node);
      IF (NOT (NActive IN NodeR.Status)) THEN
        ThisNode := Node;
      Inc(Node);
    END;
    IF (ThisNode = 0) THEN
      ThisNode := Node;
  END;

  IF (ThisNode > 255) THEN
    ThisNode := 1;

  IF (General.MultiNode) AND (ThisNode = 0) THEN
  BEGIN
    ClrScr;
    WriteLn('WARNING: No node number specified. Defaulting to node 1.');
    ThisNode := 1;
    Delay(1000);
  END
  ELSE IF (ThisNode = 0) THEN
    ThisNode := 1;

  initp1;

  LoadNode(ThisNode);
  WITH NodeR DO
  BEGIN
    User := 0;
    UserName := '';
    CityState := '';
    Sex := 'M';
    Age := 0;
    LogonTime := 0;
    GroupChat := FALSE;
    ActivityDesc := '';
    Status := [NActive];
    Room := 0;
    Channel := 0;
    FillChar(Invited,SizeOf(Invited),0);
    FillChar(Booted,SizeOf(Booted),0);
    FillChar(Forget,SizeOf(Forget),0);
  END;
  SaveNode(ThisNode);

END;

END.
