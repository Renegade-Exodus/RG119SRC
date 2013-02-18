{$A+,B-,D+,E-,F+,I-,L+,N-,O+,R-,S+,V-}

UNIT Mail5;

INTERFACE

USES
  Common;

PROCEDURE Post(ReplyTo: LongInt; VAR TToI: FromToInfo; PvtMsg: Boolean);
PROCEDURE ReadMessages(MenuOption: Str50);
PROCEDURE ScanMessages(MArea: Integer; AskUpDate: Boolean; MenuOption: Str50);
PROCEDURE StartNewScan(MenuOption: Str50);
PROCEDURE ScanYours;
FUNCTION FirstNew: Word;

IMPLEMENTATION

USES
  Dos,
  Mail0,
  Mail1,
  EMail,
  Mail6,
  Menus,
  ShortMsg,
  SysOp3,
  TimeFunc;

VAR
  TempLastRead: LongInt;

PROCEDURE Post(ReplyTo: LongInt; VAR TToI: FromToInfo; PvtMsg: Boolean);
VAR
  MHeader,
  MHeader2: MHeaderRec;
  ok: Boolean;

  PROCEDURE Nope(DisplayStr: AStr);
  BEGIN
    IF (ok) THEN
    BEGIN
      NL;
      Print(DisplayStr);
      NL;
    END;
    ok := FALSE;
  END;

BEGIN
  ok := TRUE;
  LoadMsgArea(MsgArea);
  IF (NOT AACS(MemMsgArea.PostACS)) THEN
    Nope('Your access level does not allow you to post in this area.');
  IF (AccountBalance < General.CreditPost) AND NOT (FNoCredits IN ThisUser.Flags) THEN
    Nope('Insufficient account balance to post a message.');
  IF ((RPost IN ThisUser.Flags) OR (NOT AACS(General.NormPubPost))) THEN
    Nope('Your access priviledges do not include posting.');
  IF ((PToday >= General.MaxPubPost) AND (NOT MsgSysOp)) THEN
    Nope('Too many messages posted today.');
  IF (ok) THEN
  BEGIN
    InitMsgArea(MsgArea);
    MHeader.FileAttached := 0;
    MHeader.Status := [];
    IF (ReplyTo <> -1) THEN
    BEGIN
      MHeader.MTo := TToI;
      IF (MHeader.MTo.Anon > 0) THEN
        MHeader.MTo.A1S := UseName(MHeader.MTo.Anon,MHeader.MTo.A1S);
    END
    ELSE
    BEGIN
      FillChar(MHeader.MTo,SizeOf(MHeader.MTo),0);
      InResponseTo := '';
    END;

    IF (MemMsgArea.PrePostFile <> '') THEN
    BEGIN
      PrintF(MemMsgArea.PrePostFile);
      PauseScr(FALSE);
    END;

    IF (InputMessage(TRUE,(ReplyTo <> -1),TRUE,'',MHeader,'')) THEN
    BEGIN
      IF (ReplyTo <> -1) THEN
        MHeader.ReplyTo := ((HiMsg + 1) - ReplyTo);
      IF (PvtMsg) THEN
        Include(MHeader.Status,Prvt);
      SaveHeader((HiMsg + 1),MHeader);
      IF (ReplyTo <> -1) THEN
      BEGIN
        LoadHeader(ReplyTo,MHeader2);
        Inc(MHeader2.Replies);
        SaveHeader(ReplyTo,MHeader2);
      END;
      SysOpLog(MHeader.Subject+' posted on ^5'+MemMsgArea.Name);
      IF (MHeader.MTo.A1S <> '') THEN
        SysOpLog('  To: "'+MHeader.MTo.A1S+'"');
      Print('^9Message posted on ^5'+MemMsgArea.Name+'^9.');
      NL;
      Inc(ThisUser.MsgPost);
      Inc(PToday);
      IF NOT (FNoCredits IN ThisUser.Flags) THEN
        AdjustBalance(General.CreditPost);
      SaveURec(ThisUser,UserNum);
      Update_Screen;
    END;
  END;
END;

PROCEDURE ListMessages;
VAR
  MHeader: MheaderRec;
  S,
  S1: STRING;
  TempHiMsg: Word;
  ADate: DateTime;
  NumDone: Byte;
BEGIN
  NumDone := 0;
  TempHiMsg := HiMsg;
  IF ((Msg_On < 1) OR (Msg_On > TempHiMsg)) THEN
    Exit;
  Abort := FALSE;
  Next := FALSE;  (* Added *)
  Cls;
  PrintACR('旼컴컴컫컴컴컴컴컴컴컴컴컴컫컴컴컴컴컴컴컴컴컴컴쩡컴컴컴컴컴컴컴컴컴쩡컴컴컴커');
  PrintACR('� Msg# � Sender            � Receiver           �  '+'Subject           �! Posted �');
  PrintACR('읕컴컴컨컴컴컴컴컴컴컴컴컴컨컴컴컴컴컴컴컴컴컴컴좔컴컴컴컴컴컴컴컴컴좔컴컴컴켸');
  Dec(Msg_On);
  WHILE ((NumDone < (PageLength - 7)) AND (Msg_On >= 0) AND (Msg_On < TempHiMsg) AND (NOT Next) AND (NOT Abort) AND
        (NOT HangUp)) DO
  BEGIN
    Inc(Msg_On);
    LoadHeader(Msg_On,MHeader);
    IF ((NOT (UnValidated IN MHeader.Status)) AND NOT (Mdeleted IN MHeader.Status)) OR (MsgSysOp) THEN
    BEGIN
      IF (Mdeleted IN MHeader.Status) THEN
        S := '''D '
      ELSE IF (UnValidated IN MHeader.Status) THEN
        S := '''U '
      ELSE IF ToYou(MHeader) OR FromYou(MHeader) THEN
        S := '''> '
      ELSE IF (TempLastRead < MHeader.Date) THEN
        S := '''* '
      ELSE
        S := '  ';
      S := S + '"'+PadLeftInt(Msg_On,5)+'  #';
      IF (MARealName IN MemMsgArea.MAFlags) THEN
        S1 := UseName(MHeader.From.Anon,MHeader.From.Real)
      ELSE
        S1 := UseName(MHeader.From.Anon,MHeader.From.A1S);
      S := S + PadLeftStr(S1,18)+'  $';
      IF ((MARealName IN MemMsgArea.MAFlags) AND (MHeader.MTo.Real <> '')) THEN
        S1 := UseName(MHeader.MTo.Anon,MHeader.MTo.Real)
      ELSE
        S1 := UseName(MHeader.MTo.Anon,MHeader.MTo.A1S);
      S := S + PadLeftStr(S1,19)+' % ';
      IF (MHeader.FileAttached = 0) THEN
        S := S + PadLeftStr(MHeader.Subject,18)
      ELSE
        S := S + PadLeftStr(Stripname(MHeader.Subject),18);
      PackToDate(ADate,MHeader.Date);
      S := S + ' &'+ZeroPad(IntToStr(ADate.Month))+'/'+ ZeroPad(IntToStr(ADate.Day))+'/'+ZeroPad(IntToStr(ADate.Year));
      IF (AllowMCI IN MHeader.Status) THEN
        PrintACR(S)
      ELSE
        Print(S);
      Inc(NumDone);
    END;
    Wkey;
    IF (Next) THEN
    BEGIN
      Abort := FALSE;
      Next := FALSE;
    END;
  END;
  IF (Msg_On = TempHiMsg) THEN
  BEGIN
    Dec(Msg_On);
    LoadHeader(Msg_On,MHeader);
  END;
END;

PROCEDURE MainRead(OncOnly,AskUpdate,Pub: Boolean);
VAR
  User: UserRecordType;
  MHeader: MHeaderRec;
  LastReadRecord: ScanRec;
  Cmd,
  NewMenuCmd: AStr;
  Cmd1: Char;
  SaveMenu,
  CmdToExec,
  Counter: Byte;
  MsgNum,
  ThreadStart: Word;
  Done,
  CmdNotHid,
  CmdExists,
  AskPost,
  Contlist,
  DoneScan,
  HadUnVal: Boolean;

  FUNCTION CantBeSeen: Boolean;
  BEGIN
    CantBeSeen := (NOT MsgSysOp) AND ((UnValidated IN MHeader.Status) OR (Mdeleted IN MHeader.Status) OR
                  ((Prvt IN MHeader.Status) AND NOT (ToYou(MHeader) OR FromYou(MHeader))));
  END;

BEGIN
  AskPost := FALSE;
  Contlist := FALSE;
  DoneScan := FALSE;
  HadUnVal := FALSE;
  AllowContinue := TRUE;
  ThreadStart := 0;
  TReadPrompt := 0;
  Abort := FALSE;
  Next := FALSE;
  SaveMenu := CurMenu;

  IF (MemMsgArea.MessageReadMenu <> 0) THEN
    CurMenu := MemMsgArea.MessageReadMenu
  ELSE
    CurMenu := General.MessageReadMenu;

  IF (NOT NewMenuToLoad) THEN
    LoadMenuPW;

  AutoExecCmd('FIRSTCMD');

  REPEAT
    IF (Contlist) AND (Abort) THEN
    BEGIN
      Contlist := FALSE;
      NL;
      Print('Continuous message listing off.');
      TReadPrompt := 255;
    END;
    IF (Msg_On < 1) OR (Msg_On > HiMsg) THEN
    BEGIN
      IF (NOT Contlist) THEN
      BEGIN
        DoneScan := TRUE;
        AskPost := TRUE;
      END
      ELSE
      BEGIN
        Contlist := FALSE;
        Msg_On := HiMsg;
        NL;
        Print('Continuous message listing off.');
        TReadPrompt := 255;
      END;
    END;
    IF (NOT DoneScan) AND (TReadPrompt IN [0..2,8..10,18]) THEN
    BEGIN
      IF (Contlist) THEN
        Next := TRUE;
      LoadHeader(Msg_On,MHeader);
      IF (UnValidated IN MHeader.Status) THEN
        HadUnVal := TRUE;
      WHILE (((Msg_On < HiMsg) AND (TReadPrompt <> 2)) OR ((Msg_On > 1) AND (TReadPrompt = 2))) AND
            (CantBeSeen) DO
      BEGIN
        IF (TReadPrompt = 2) THEN
          Dec(Msg_On)
        ELSE
          Inc(Msg_On);
        LoadHeader(Msg_On,MHeader);
      END;
      IF ((Msg_On = 1) OR (Msg_On = HiMsg)) AND (CantBeSeen) THEN
      BEGIN
        DoneScan := TRUE;
        AskPost := TRUE;
      END
      ELSE
      BEGIN
        IF ((CLSMsg IN ThisUser.SFlags) AND (NOT Contlist)) THEN
          Cls
        ELSE
          NL;
        ReadMsg(Msg_On,Msg_On,HiMsg);
        IF (TempLastRead < MHeader.Date) AND (MHeader.Date <= GetPackDateTime) THEN
          TempLastRead := MHeader.Date;
        IF (Pub) THEN
          Inc(MRead);
      END;
    END;
    IF (NOT Contlist) AND (NOT DoneScan) THEN
      REPEAT
        TReadPrompt := 0;
        MainMenuHandle(Cmd);
        NewMenuCmd := '';
        CmdToExec := 0;
        Done := FALSE;
        REPEAT
          FCmd(Cmd,CmdToExec,CmdExists,CmdNotHid);
          IF (CmdToExec <> 0) AND (MemCmd^[CmdToExec].CmdKeys <> '-^') AND
             (MemCmd^[CmdToExec].CmdKeys <> '-/') AND (MemCmd^[CmdToExec].CmdKeys <> '-\') THEN
            DoMenuCommand(Done,
                          MemCmd^[CmdToExec].CmdKeys,
                          MemCmd^[CmdToExec].Options,
                          NewMenuCmd,
                          MemCmd^[CmdToExec].NodeActivityDesc);
        UNTIL (CmdToExec = 0) OR (Done) OR (HangUp);
        Abort := FALSE;
        Next := FALSE;
        CASE TReadPrompt OF
          1 : ;  { Read Again }
          2 : Dec(Msg_On);  { Previous Message }
          3 : IF (NOT MsgSysOp) THEN
                Print('You do not have the required access level for this option.')
              ELSE
                MoveMsg(Msg_On);
          4 : IF (NOT CoSysOp) THEN
                Print('You do not have the required access level for this option.')
              ELSE
                ExtractMsgToFile(Msg_On);
          5 : IF (MsgSysOp) OR FromYou(MHeader) THEN
              BEGIN
                REPEAT
                  NL;
                  Prt('Message editing (^5?^4=^5Help^4): ');
                  MPL(1);
                  IF (MsgSysOp) THEN
                    Onek(Cmd1,'QVPRAFTSEOD?'^M)
                  ELSE
                    Onek(Cmd1,'QFTSEOD?'^M);
                  IF (NOT (Cmd1 IN ['Q',^M])) THEN
                    NL;
                  CASE Cmd1 OF
                    '?' : BEGIN
                            LCmds(15,5,'From','To');
                            LCmds(15,5,'Subject','Edit text');
                            LCmds(15,5,'Oops','Display header');
                            IF (MsgSysOp) THEN
                            BEGIN
                              LCmds(15,5,'Permanent','Validation');
                              LCmds(15,5,'Rescan','Anonymous');
                            END;
                            LCmds(15,5,'Quit','');
                          END;
                    'D' : FOR Counter := 1 TO 6 DO
                            IF (HeaderLine(MHeader,Msg_On,HiMsg,Counter) <> '') THEN
                              PrintACR(Headerline(MHeader,Msg_On,HiMsg,Counter));
                    'O' : IF PYNQ('Reload old information? ',0) THEN
                            LoadHeader(Msg_On,MHeader);
                    'E' : BEGIN
                            EditMessageText(Msg_On);
                            LoadHeader(Msg_On,MHeader);
                          END;
                    'S' : IF (MHeader.FileAttached = 0) OR (MsgSysOp) THEN
                          BEGIN
                            Prt('Subj: ');
                            InputDefault(MHeader.Subject,MHeader.Subject,40,[ColorsAllowed],FALSE)
                          END
                          ELSE
                            Print('Sorry, you can''t edit that.');
                    'T' : BEGIN
                            Print('^11. Posted to  : ^5'+MHeader.MTo.A1S);
                            Print('^12. Real name  : ^5'+MHeader.MTo.Real);
                            Print('^13. System name: ^5'+MHeader.MTo.Name);
                            NL;
                            Prt('Edit name (^51^4-^53^4) [^5Q^4]uit: ');
                            Onek(Cmd1,'Q123'^M);
                            IF (NOT (Cmd1 IN ['Q',^M])) THEN
                              NL;
                            CASE Cmd1 OF
                              '1' : BEGIN
                                      Prt('Posted to: ');
                                      InputDefault(MHeader.MTo.A1S,MHeader.MTo.A1S,36,[],FALSE);
                                    END;
                              '2' : BEGIN
                                      Prt('Real name: ');
                                      InputDefault(MHeader.MTo.Real,MHeader.MTo.Real,36,[],FALSE);
                                    END;
                              '3' : BEGIN
                                      Prt('System name: ');
                                      InputDefault(MHeader.MTo.Name,MHeader.MTo.Name,36,[],FALSE);
                                    END;
                            END;
                            Cmd1 := #0;
                          END;
                    'F' : IF (MHeader.From.Anon > 0) OR (MsgSysOp) THEN
                          BEGIN
                            Print('^11. Posted to  : ^5'+MHeader.From.A1S);
                            Print('^12. Real name  : ^5'+MHeader.From.Real);
                            Print('^13. System name: ^5'+MHeader.From.Name);
                            NL;
                            Prt('Edit name (^51^4-^53^4) [^5Q^4]uit: ');
                            Onek(Cmd1,'Q123'^M);
                            IF (NOT (Cmd1 IN ['Q',^M])) THEN
                              NL;
                            CASE Cmd1 OF
                              '1' : BEGIN
                                      Prt('Posted to: ');
                                      InputDefault(MHeader.From.A1S,MHeader.From.A1S,36,[],FALSE);
                                    END;
                              '2' : BEGIN
                                      Prt('Real name: ');
                                      InputDefault(MHeader.From.Real,MHeader.From.Real,36,[],FALSE);
                                    END;
                              '3' : BEGIN
                                      Prt('System name: ');
                                      InputDefault(MHeader.From.Name,MHeader.From.Name,36,[],FALSE);
                                    END;
                            END;
                            Cmd1 := #0;
                          END
                          ELSE
                            Print('Sorry, you can''t edit that.');
                    'A' : IF (MsgSysOp) THEN
                          BEGIN
                            IF (MHeader.From.Anon IN [1,2]) THEN
                              MHeader.From.Anon := 0
                            ELSE
                            BEGIN
                              Loadurec(User,MHeader.From.UserNum);
                              IF AACS1(User,MHeader.From.UserNum,General.CSOP) THEN
                                MHeader.From.Anon := 2
                              ELSE
                                MHeader.From.Anon := 1;
                            END;
                            Print('Message is '+AOnOff((MHeader.From.Anon = 0),'not ','')+'anonymous');
                            SysOpLog('Message is '+AOnOff((MHeader.From.Anon = 0),'not ','')+'anonymous');
                          END;
                    'R' : IF (MsgSysOp) THEN
                          BEGIN
                            IF (Sent IN MHeader.Status) THEN
                            BEGIN
                              Exclude(MHeader.Status,Sent);
                              IF NOT (MAScanOut IN MemMsgArea.MAFlags) THEN
                                UpdateBoard;
                            END
                            ELSE
                              Include(MHeader.Status,Sent);
                            Print('Message '+AOnOff((Sent IN MHeader.Status),'','not ')+'marked as scanned.');
                            SysOpLog('Message '+AOnOff((Sent IN MHeader.Status),'','not ')+'marked as scanned.');
                          END;
                    'P' : IF (MsgSysOp) THEN
                          BEGIN
                            IF (Permanent IN MHeader.Status) THEN
                              Exclude(MHeader.Status,Permanent)
                            ELSE
                              Include(MHeader.Status,Permanent);
                            Print('Message is '+AOnOff((Permanent IN MHeader.Status),'','not ')+'permanent.');
                            SysOpLog('Message is '+AOnOff((Permanent IN MHeader.Status),'','not ')+'permanent.');
                          END;
                    'V' : IF (MsgSysOp) THEN
                          BEGIN
                            IF (UnValidated IN MHeader.Status) THEN
                              Exclude(MHeader.Status,UnValidated)
                            ELSE
                              Include(MHeader.Status,UnValidated);
                            Print('Message '+AOnOff((UnValidated IN MHeader.Status),'un','')+'validated.');
                            SysOpLog('Message '+AOnOff((UnValidated IN MHeader.Status),'un','')+'validated.');
                          END;
                  END;
                UNTIL (Cmd1 IN ['Q',^M]) OR (HangUp);
                Cmd1 := #0;
                SaveHeader(Msg_On,MHeader);
              END;
          6 : BEGIN
                DumpQuote(MHeader);
                IF (NOT Pub) THEN
                  AutoReply(MHeader)
                ELSE
                BEGIN
                  NL;
                  IF (Prvt IN MHeader.Status) THEN
                    Dyny := TRUE;
                  IF (MHeader.From.Anon = 0) OR (AACS(General.Anonpubread)) THEN
                    IF PYNQ('Is this to be a private reply? ',0) THEN
                      IF (MAPrivate IN MemMsgArea.MAFlags) THEN
                        IF PYNQ('Reply in Email? ',0) THEN
                          AutoReply(MHeader)
                        ELSE
                          Post(Msg_On,MHeader.From,TRUE)
                      ELSE
                        AutoReply(MHeader)
                    ELSE
                      Post(Msg_On,MHeader.From,FALSE)
                  ELSE
                    Post(Msg_On,MHeader.From,FALSE);
                END;
              END;
          7 : BEGIN
                Msg_On := (HiMsg + 1);
                LoadHeader(HiMsg,MHeader);
                IF (MHeader.Date <= GetPackDateTime) THEN
                  TempLastRead := MHeader.Date;
                Next := FALSE;
              END;
          8 : IF ((Msg_On - MHeader.ReplyTo) > 0) AND (MHeader.ReplyTo > 0) THEN
              BEGIN
                IF (ThreadStart = 0) THEN
                  ThreadStart := Msg_On;
                Dec(Msg_On,MHeader.ReplyTo);
              END;
          9 : IF ((ThreadStart >= 1) AND (ThreadStart <= HiMsg)) THEN
              BEGIN
                Msg_On := ThreadStart;
                ThreadStart := 0;
              END;
         10 : BEGIN
                Contlist := TRUE;
                Abort := FALSE;
                NL;
                Print('Continuous message listing on.');
              END;
         11 : IF (Pub) THEN
              BEGIN
                IF (Permanent IN MHeader.Status) THEN
                BEGIN
                  NL;
                  Print('This is a permanent public message.');
                END
                ELSE
                BEGIN
                  IF (Msg_On >= 1) AND (Msg_On <= HiMsg) AND (MsgSysOp OR FromYou(MHeader)) THEN
                  BEGIN
                    LoadHeader(Msg_On,MHeader);
                    IF (Mdeleted IN MHeader.Status) THEN
                      Exclude(MHeader.Status,Mdeleted)
                    ELSE
                      Include(MHeader.Status,Mdeleted);
                    SaveHeader(Msg_On,MHeader);
                    IF NOT (Mdeleted IN MHeader.Status) THEN
                    BEGIN
                      IF FromYou(MHeader) THEN
                      BEGIN
                        IF (ThisUser.MsgPost < 2147483647) THEN
                          Inc(ThisUser.MsgPost);
                        AdjustBalance(General.Creditpost);
                      END;
                      NL;
                      Print('Public message undeleted.');
                      SysOpLog('* Undeleted public message '+MHeader.Subject);
                    END
                    ELSE
                    BEGIN
                      IF FromYou(MHeader) THEN
                      BEGIN
                        IF (ThisUser.MsgPost > 0) THEN
                          Dec(ThisUser.MsgPost);
                        AdjustBalance(-General.Creditpost);
                      END;
                      NL;
                      Print('Public message deleted.');
                      SysOpLog('* Deleted public message '+MHeader.Subject);
                    END;
                  END
                  ELSE
                  BEGIN
                    NL;
                    Print('You can only delete public messages from you.');
                  END;
                END;
              END
              ELSE
              BEGIN
                IF (Msg_On >= 1) AND (Msg_On <= HiMsg) AND (MsgSysOp OR FromYou(MHeader) OR ToYou(MHeader)) THEN
                BEGIN
                  LoadHeader(Msg_On,MHeader);
                  IF (Mdeleted IN MHeader.Status) THEN
                    Exclude(MHeader.Status,Mdeleted)
                  ELSE
                    Include(MHeader.Status,Mdeleted);
                  SaveHeader(Msg_On,MHeader);
                  IF NOT (MDeleted IN MHeader.Status) THEN
                  BEGIN
                    LoadURec(User,MHeader.MTO.UserNum);
                    IF (User.Waiting < 255) THEN
                      Inc(User.Waiting);
                    SaveURec(User,MHeader.MTO.UserNum);
                    NL;
                    Print('Private message undeleted.');
                    IF FromYou(MHeader) OR (MsgSysOp) THEN
                      SysOpLog('* Uneleted private message from '+MHeader.From.A1S)
                    ELSE IF ToYou(MHeader) OR (MsgSysOp) THEN
                      SysOpLog('* Undeleted private message to '+MHeader.MTo.A1S);
                  END
                  ELSE
                  BEGIN
                    LoadURec(User,MHeader.MTO.UserNum);
                    IF (User.Waiting > 0) THEN
                      Dec(User.Waiting);
                    SaveURec(User,MHeader.MTO.UserNum);
                    NL;
                    Print('Private message deleted.');
                    IF FromYou(MHeader) OR (MsgSysOp) THEN
                      SysOpLog('* Deleted private message from '+MHeader.From.A1S)
                    ELSE IF ToYou(MHeader) OR (MsgSysOp) THEN
                      SysOpLog('* Deleted private message to '+MHeader.MTo.A1S);
                  END;
                END
                ELSE
                BEGIN
                  NL;
                  Print('You can only delete private messages from/to you.');
                END;
              END;
         12 : IF (NOT Pub) THEN
              BEGIN
                NL;
                Print('This option is not available when reading private messages.');
              END
              ELSE
              BEGIN
                NL;
                Print('Highest-read pointer for this area set to message #'+IntToStr(Msg_On)+'.');
                IF (MHeader.Date <= GetPackDateTime) THEN
                  TempLastRead := MHeader.Date;
              END;
         13 : BEGIN
                IF (AskUpdate) THEN
                BEGIN
                  NL;
                  IF PYNQ('Update message read pointers for this area? ',0) THEN
                    SaveLastRead(GetPackDateTime);
                END;
                DoneScan := TRUE;
                Next := TRUE;
              END;
         14 : BEGIN
                DoneScan := TRUE;
                Abort := TRUE;
              END;
         15 : ListMessages;
         16 : IF (NOT CoSysOp) THEN
                Print('You do not have the required access level for this option.')
              ELSE IF (LastAuthor < 1) OR (LastAuthor > (MaxUsers - 1)) THEN
                Print('The sender of this message does not have an account on this BBS.')
              ELSE IF (CheckPW) THEN
                UserEditor(LastAuthor);
         17 : IF (NOT PUB) THEN
              BEGIN
                NL;
                Print('This option is not available when reading private messages.');
              END
              ELSE
              BEGIN
                IF (MAForceRead IN MemMsgArea.MAFlags) THEN
                BEGIN
                  NL;
                  Print('^5'+MemMsgArea.Name+'^3 cannot be removed from your NewScan.')
                END
                ELSE
                BEGIN
                  NL;
                  Print('^5'+MemMsgArea.Name+'^3 '+AOnOff(NewScanMsgArea,'will NOT','WILL')+
                        ' be scanned in future new scans.');
                  SysOpLog('* Toggled ^5'+MemMsgArea.Name+ '^1 '+AOnOff(NewScanMsgArea,'out of','back in')+ ' new scan.');
                  Reset(MsgAreaScanFile);
                  Seek(MsgAreaScanFile,(UserNum - 1));
                  Read(MsgAreaScanFile,LastReadRecord);
                  LastReadRecord.NewScan := NOT LastReadRecord.NewScan;
                  NewScanMsgArea := LastReadRecord.NewScan;
                  Seek(MsgAreaScanFile,(UserNum - 1));
                  Write(MsgAreaScanFile,LastReadRecord);
                  Close(MsgAreaScanFile);
                END;
              END;
         18 : Inc(Msg_On);
         19 : IF (NOT CoSysOp) THEN
                Print('You do not have the required access level for this option.')
              ELSE IF (LastAuthor < 1) OR (LastAuthor > (MaxUsers - 1)) THEN
                Print('The sender of this message does not have an account on this BBS.')
              ELSE
              BEGIN
                LoadURec(User,LastAuthor);
                ShowUserInfo(1,LastAuthor,User);
              END;
         20 : IF (NOT CoSysOp) THEN
                Print('You do not have the required access level for this option.')
              ELSE IF (LastAuthor < 1) OR (LastAuthor > (MaxUsers - 1)) THEN
                Print('The sender of this message does not have an account on this BBS.')
              ELSE
              BEGIN
                LoadURec(User,LastAuthor);
                AutoVal(User,LastAuthor);
              END;
         21 : ForwardMessage(Msg_On);
        END;
      UNTIL (TReadPrompt IN [1..2,7..10,13..15,18]) OR (Abort) OR (Next) OR (HangUp)
    ELSE
      Inc(Msg_On);
    IF (OncOnly) AND (TReadPrompt IN [13,14,18]) THEN
      DoneScan := TRUE;
  UNTIL (DoneScan) OR (HangUp);

  CurMenu := SaveMenu;

  NewMenuToLoad := TRUE;

  AllowContinue := FALSE;

  IF ((Pub) AND (HadUnVal) AND (MsgSysOp)) THEN
  BEGIN
    NL;
    IF PYNQ('Validate messages here? ',0) THEN
    BEGIN
      FOR MsgNum := 1 TO HiMsg DO
      BEGIN
        LoadHeader(MsgNum,MHeader);
        IF (UnValidated IN MHeader.Status) THEN
          Exclude(MHeader.Status,UnValidated);
        SaveHeader(MsgNum,MHeader);
      END;
    END;
  END;

  IF ((Pub) AND (AskPost) AND (AACS(MemMsgArea.PostACS)) AND
     (NOT (RPost IN ThisUser.Flags)) AND (PToday < General.MaxPubPost)) THEN
  BEGIN
    NL;
    IF (TReadPrompt <> 7) THEN
      IF PYNQ('Post on ^5'+MemMsgArea.Name+'^7? ',0) THEN
        IF (MAPrivate IN MemMsgArea.MAFlags) THEN
        BEGIN
          NL;
          Post(-1,MHeader.From,PYNQ('Is this to be a private message? ',0));
        END
        ELSE
          Post(-1,MHeader.From,FALSE);
  END;
END;

PROCEDURE ReadMessages(MenuOption: Str50);
VAR
  InputStr: AStr;
  SaveReadMsgArea: Integer;
BEGIN
  SaveReadMsgArea := ReadMsgArea;
  Abort := FALSE;
  Next := FALSE;
  IF (MenuOption = '') THEN
    MsgArea := -1;
  InitMsgArea(MsgArea);
  IF (HiMsg = 0) THEN
  BEGIN
    NL;
    Print('No messages on ^5'+MemMsgArea.Name+'^1.');
    IF (Novice IN ThisUser.Flags) THEN
      PauseScr(FALSE);
  END
  ELSE
  BEGIN
    Msg_On := 1;
    REPEAT
      ListMessages;
      NL;
      { Prompt(FString.ReadQ); }
      lRGLngStr(32,FALSE);
      ScanInput(InputStr,'Q'^M);
      IF (InputStr = ^M) THEN
        IF ((Msg_On + 1) = HiMsg) THEN
          Msg_On := 1
        ELSE
          Inc(Msg_On);
    UNTIL (InputStr <> ^M) OR (HangUp);
    IF (InputStr <> 'Q') AND (NOT HangUp) THEN
    BEGIN
      IF (StrToInt(InputStr) < 1) OR (StrToInt(InputStr) > HiMsg) THEN
        Msg_On := 1
      ELSE
        Msg_On := StrToInt(InputStr);
      IF (MsgArea <> -1) THEN
        TempLastRead := LastMsgRead;
      MainRead(FALSE,FALSE,(MsgArea <> -1));
      IF (MsgArea <> - 1) THEN
        SaveLastRead(TempLastRead);
    END;
  END;
  MsgArea := SaveReadMsgArea;
  LoadMsgArea(MsgArea);
END;

FUNCTION FirstNew: Word;
VAR
  MHeader: MHeaderRec;
  MaxMsgs,
  Cn: Word;
  Done: Boolean;
BEGIN
  MaxMsgs := HiMsg;
  Cn := 0;
  IF (MaxMsgs > 0) THEN
  BEGIN
    Done := FALSE;
    Cn := 1;
    WHILE (CN <= MaxMsgs) AND (NOT Done) DO
    BEGIN
      LoadHeader(Cn,MHeader);
      IF (LastMsgRead < MHeader.Date) THEN
        Done := TRUE
      ELSE
      BEGIN
        IF (CN < MaxMsgs) THEN
          Inc(Cn,1)
        ELSE
        BEGIN
          CN := 0;
          Done := TRUE;
        END;
      END;
    END;
  END;
  FirstNew := Cn;
END;

PROCEDURE ScanMessages(MArea: Integer; AskUpdate: Boolean; MenuOption: Str50);
VAR
  ScanFor: STRING[40];
  Cmd: Char;
  SaveMsgArea,
  MsgNum: Word;
  ScanNew,
  ScanGlobal: Boolean;

  PROCEDURE Searchboard(MArea1: Integer; Cmd1: Char);
  VAR
    MsgHeader: MHeaderRec;
    Searched: STRING;
    TotLoad: Word;
    Match,
    AnyShown: Boolean;
  BEGIN
    IF (MsgArea <> MArea1) THEN
      ChangeMsgArea(MArea1);
    IF (MsgArea = MArea1) THEN
    BEGIN
      InitMsgArea(MsgArea);
      AnyShown := FALSE;
      LIL := 0;
      CLS;
      Prompt('^1Scanning ^5'+MemMsgArea.Name+' #'+IntToStr(CompMsgArea(MsgArea))+'^1...');
      Reset(MsgHdrF);
      Reset(MsgTxtF,1);
      IF (IOResult <> 0) THEN
        Exit;
      IF (ScanNew) THEN
        MsgNum := FirstNew
      ELSE
        MsgNum := 1;
      IF (MsgNum > 0) AND (FileSize(MsgHdrF) > 0) THEN
        WHILE (MsgNum <= FileSize(MsgHdrF)) AND (NOT Next) AND (NOT Abort) AND (NOT HangUp) DO
        BEGIN
          LoadHeader(MsgNum,MsgHeader);
          Match := FALSE;
          IF (Cmd1 IN ['Y',^M] ) THEN
            IF ToYou(MsgHeader) THEN
              Match := TRUE;
          IF (Cmd1 IN ['F','A'] ) THEN
          BEGIN
            IF (MARealName IN MemMsgArea.MAFlags) THEN
              Searched := MsgHeader.From.Real
            ELSE
              Searched := MsgHeader.From.A1S;
            IF (MemMsgArea.MAtype = 0) THEN
              Searched := Searched;
            Searched := AllCaps(UseName(MsgHeader.From.Anon,Searched));
            IF (Pos(ScanFor,Searched) > 0) THEN
              Match := TRUE;
          END;
          IF (Cmd1 IN ['T','A'] ) THEN
          BEGIN
            IF (MARealName IN MemMsgArea.MAFlags) THEN
              Searched := MsgHeader.MTo.Real
            ELSE
              Searched := MsgHeader.MTo.A1S;
            IF (MemMsgArea.MAtype = 0) THEN
              Searched := Searched;
            Searched := AllCaps(UseName(MsgHeader.MTo.Anon,Searched));
            IF (Pos(ScanFor,Searched) > 0) THEN
              Match := TRUE;
          END;
          IF (Cmd1 IN ['S','A'] ) THEN
            IF (Pos(ScanFor,AllCaps(MsgHeader.Subject)) > 0) THEN
              Match := TRUE;
          IF (Cmd1 = 'A') AND (NOT Match) AND (MsgHeader.TextSize > 0) AND
             (((MsgHeader.Pointer - 1) + MsgHeader.TextSize) <= FileSize(MsgTxtF)) AND
             (MsgHeader.Pointer > 0) THEN
            WITH MsgHeader DO
            BEGIN
              Seek(MsgTxtF,(Pointer - 1));
              TotLoad := 0;
              REPEAT
                BlockRead(MsgTxtF,Searched[0],1);
                BlockRead(MsgTxtF,Searched[1],Ord(Searched[0]));
                LastError := IOResult;
                Inc(TotLoad,Length(Searched) + 1);
                IF (Pos(ScanFor,AllCaps(Searched)) > 0) THEN
                  Match := TRUE;
              UNTIL (TotLoad >= TextSize) OR (Match);
            END;
          IF (Match) THEN
          BEGIN
            Close(MsgHdrF);
            Close(MsgTxtF);
            Msg_On := MsgNum;
            MainRead(TRUE,AskUpdate,(MsgArea <> -1));
            NL;
            Reset(MsgHdrF);
            Reset(MsgTxtF,1);
            AnyShown := TRUE;
          END;
          Wkey;
          IF (Next) THEN
            Abort := TRUE;
          Inc(MsgNum);
        END;
      Close(MsgHdrF);
      Close(MsgTxtF);
      IF (NOT AnyShown) THEN
        BackErase(14 + Lennmci(MemMsgArea.Name) + Length(IntToStr(CompMsgArea(MsgArea) ) ) );
    END;
  END;

BEGIN
  SaveMsgArea := MsgArea;
  ScanNew := FALSE;
  ScanGlobal := FALSE;
  MenuOption := AllCaps(MenuOption);
  IF (MenuOption <> '') THEN
    Cmd := 'Y'
  ELSE
    Cmd := #0;
  IF (Pos('N',MenuOption) > 0) THEN
    ScanNew := TRUE;
  IF (Pos('G',MenuOption) > 0) THEN
    ScanGlobal := TRUE;
  IF (Cmd = #0) THEN
    REPEAT
      NL;
      Prt('Scan method (^5?^4=^5Help^4): ');
      Onek(Cmd,'FTSAY?Q'^M);
      IF (Cmd = '?') THEN
      BEGIN
        NL;
        LCmds(15,5,'From field','To field');
        LCmds(15,5,'Subject field','All text');
        LCmds(15,5,'Your messages','Quit');
      END;
    UNTIL (Cmd <> '?') OR (HangUp);
  NL;
  IF (Cmd <> 'Q') AND (Cmd <> ^M) THEN
  BEGIN
    IF (Cmd <> 'Y') THEN
    BEGIN
      Prt('Text to scan for: ');
      Input(ScanFor,40);
      IF (ScanFor = '') THEN
        Exit;
      NL;
    END;
    IF (MenuOption = '') THEN
    BEGIN
      Dyny := TRUE;
      ScanNew := PYNQ('Scan new messages only? ',0);
    END;
    IF (ScanGlobal) OR ((MenuOption = '') AND PYNQ('Global scan? ',0)) THEN
    BEGIN
      MArea := 1;
      WHILE (MArea <= NumMsgAreas) AND (NOT Next) AND (NOT Abort) AND (NOT HangUp) DO
      BEGIN
        IF (CompMsgArea(MArea) > 0) THEN
          Searchboard(MArea,Cmd);
        Wkey;
        IF (Next) THEN
        BEGIN
          Abort := FALSE;
          Next := FALSE;
        END;
        Inc(MArea);
      END;
    END
    ELSE
      Searchboard(MArea,Cmd);
  END;
  MsgArea := SaveMsgArea;
  LoadMsgArea(MsgArea);
END;

PROCEDURE ScanYours;
VAR
  FoundMap: ARRAY [0..255] OF SET OF 0..7;
  MsgHeader: MHeaderRec;
  SaveMsgArea,
  MArea: Integer;
  MsgNum,
  Found: Word;
  SaveConfSystem,
  AnyFound,
  FirstTime: Boolean;
BEGIN
  FillChar(FoundMap,SizeOf(FoundMap),0);
  SaveMsgArea := MsgArea;
  SaveConfSystem := ConfSystem;
  ConfSystem := FALSE;
  IF (SaveConfSystem) THEN
    NewCompTables;
  NL;
  Prompt('^5Scanning for your new public messages ... ');
  FirstTime := TRUE;
  AnyFound := FALSE;
  MArea := 1;
  WHILE (MArea <= NumMsgAreas) AND (NOT HangUp) DO
  BEGIN
    IF (CompMsgArea(MArea) > 0) THEN
    BEGIN
      IF (MsgArea <> MArea) THEN
        ChangeMsgArea(MArea);
      IF (MsgArea = MArea) THEN
      BEGIN
        InitMsgArea(MsgArea);
        IF (NewScanMsgArea) THEN
        BEGIN
          Reset(MsgHdrF);
          Reset(MsgTxtF,1);
          IF (IOResult = 0) THEN
          BEGIN
            Found := 0;
            MsgNum := FirstNew;
            IF (MsgNum > 0) AND (FileSize(MsgHdrF) > 0) THEN
              WHILE (MsgNum <= FileSize(MsgHdrF)) AND (NOT HangUp) DO
              BEGIN
                LoadHeader(MsgNum,MsgHeader);
                IF (ToYou(MsgHeader)) THEN
                BEGIN
                  FoundMap[MArea DIV 8] := FoundMap[MArea DIV 8] + [MArea MOD 8];
                  Inc(Found);
                END;
                Inc(MsgNum);
              END;
            Close(MsgHdrF);
            Close(MsgTxtF);
            IF (Found > 0) THEN
            BEGIN
              IF (FirstTime) THEN
              BEGIN
                NL;
                NL;
                FirstTime := FALSE;
              END;
              Print(PadLeftStr(MemMsgArea.Name,30)+' ^1'+IntToStr(Found));
              AnyFound := TRUE;
            END;
          END;
        END;
      END;
    END;
    Inc(MArea);
  END;
  IF (NOT AnyFound) THEN
    Print('^5No messages found.')
  ELSE
  BEGIN
    Abort := FALSE;
    Next := FALSE;
    NL;
    IF PYNQ('Read these now? ',0) THEN
    BEGIN
      MArea := 1;
      WHILE (MArea <= NumMsgAreas) AND (NOT Next) AND (NOT Abort) AND (NOT HangUp) DO
      BEGIN
        IF (MArea MOD 8) IN FoundMap[MArea DIV 8] THEN
          ScanMessages(MArea,TRUE,'N');
        WKey;
        IF (Next) THEN
        BEGIN
          Abort := FALSE;
          Next := FALSE;
        END;
        Inc(MArea);
      END;
    END;
  END;
  ConfSystem := SaveConfSystem;
  IF (SaveConfSystem) THEN
    NewCompTables;
  MsgArea := SaveMsgArea;
  LoadMsgArea(MsgArea);
  LastError := IOResult;
END;

PROCEDURE StartNewScan(MenuOption: Str50);
VAR
  MArea,
  SaveMsgArea: Integer;
  Global: Boolean;

  PROCEDURE NewScan(MArea1: Integer);
  BEGIN
    IF (MsgArea <> MArea1) THEN
      ChangeMsgArea(MArea1);
    IF (MsgArea = MArea1) THEN
    BEGIN
      InitMsgArea(MsgArea);
      TempLastRead := LastMsgRead;
      Lil := 0;
      { Prompt('^3'+FString.NewScan1);}
      lRGLngStr(8,FALSE);
      Msg_On := FirstNew;
      IF (Msg_On > 0) THEN
        MainRead(FALSE,FALSE,(MsgArea <> -1));
      (*  Add backarase *)
    END;
    SaveLastRead(TempLastRead);
  END;

BEGIN
  SaveMsgArea := MsgArea;
  MArea := MsgArea;
  Abort := FALSE;
  Next := FALSE;
  Global := FALSE;
  IF (UpCase(MenuOption[1]) = 'C') THEN
    MArea := MsgArea
  ELSE IF (UpCase(MenuOption[1]) = 'G') THEN
    Global := TRUE
  ELSE IF (StrToInt(MenuOption) <> 0) THEN
    MArea := StrToInt(MenuOption)
  ELSE IF (MenuOption = '') THEN
  BEGIN
    NL;
    Global := PYNQ('Scan all message areas? ',0)
  END;
  IF (NOT Global) THEN
    NewScan(MArea)
  ELSE
  BEGIN
    MArea := 1;
    WHILE (MArea <= NumMsgAreas) AND (NOT Next) AND (NOT Abort) AND (NOT HangUp) DO
    BEGIN
      IF (CompMsgArea(MArea) > 0) THEN
      BEGIN
        InitMsgArea(MArea);
        IF (NewScanMsgArea) OR ((MAForceRead IN MemMsgArea.MAFlags) AND (NOT CoSysOp)) THEN
          NewScan(MArea);
      END;
      WKey;
      IF (Next) THEN
      BEGIN
        Abort := FALSE;
        Next := FALSE;
      END;
      Inc(MArea);
    END;
    SysOpLog('Global new scan of message areas');
  END;
  MsgArea := SaveMsgArea;
  LoadMsgArea(MsgArea);
END;

END.
