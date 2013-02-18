{$IFDEF WIN32}
{$I DEFINES.INC}
{$ENDIF}

{$A+,B-,D+,E-,F+,I-,L+,N-,O+,R-,S+,V-}

UNIT Mail2;

INTERFACE

USES
  Common;

PROCEDURE Post(ReplyTo: LongInt; VAR TToI: FromToInfo; PvtMsg: Boolean);
PROCEDURE ReadAllMessages(MenuOption: Str50);
PROCEDURE ScanMessages(MArea: Integer; AskUpDate: Boolean; MenuOption: Str50);
PROCEDURE StartNewScan(MenuOption: Str50);
PROCEDURE ScanYours;
FUNCTION FirstNew: Word;

IMPLEMENTATION

USES
  Dos,
  Common5,
  Mail0,
  Mail1,
  EMail,
  Mail3,
  Menus,
  ShortMsg,
  SysOp2G,
  SysOp3,
  TimeFunc;

VAR
  TempLastRead: LongInt;

PROCEDURE Post(ReplyTo: LongInt; VAR TToI: FromToInfo; PvtMsg: Boolean);
VAR
  MHeader: MHeaderRec;
  PostOk: Boolean;
BEGIN

  LoadMsgArea(MsgArea);

  PostOk := TRUE;

  IF (NOT AACS(MemMsgArea.PostACS)) THEN
  BEGIN
    NL;
    Print('^7Your access level does not permit you to post in this message area!^1');
    PostOk := FALSE;
  END
  ELSE IF (AccountBalance < General.CreditPost) AND (NOT (FNoCredits IN ThisUser.Flags)) THEN
  BEGIN
    NL;
    Print('^7Insufficient account balance to post a public message!^1');
    PostOk := FALSE;
  END
  ELSE IF (RPost IN ThisUser.Flags) OR (NOT AACS(General.NormPubPost)) THEN
  BEGIN
    NL;
    Print('^7Your access priviledges do not include posting a public messages!^1');
    PostOk := FALSE;
  END
  ELSE IF (PublicPostsToday >= General.MaxPubPost) AND (NOT MsgSysOp) THEN
  BEGIN
    NL;
    Print('^7You have already sent the maximum public messages allowed per day!^1');
    PostOk := FALSE;
  END;

  IF (NOT PostOk) THEN
    Exit;

  InitMsgArea(MsgArea);

  MHeader.Status := [];

  MHeader.FileAttached := 0;

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

  IF (InputMessage(TRUE,(ReplyTo <> -1),'',MHeader,'',78,500)) THEN
  BEGIN

    IF (ReplyTo <> -1) THEN
      MHeader.ReplyTo := ((HiMsg + 1) - ReplyTo);

    IF (PvtMsg) THEN
      Include(MHeader.Status,Prvt);

    SaveHeader((HiMsg + 1),MHeader);

    Print('^1Message posted on ^5'+MemMsgArea.Name+'^1.');

    SysOpLog(MHeader.Subject+' posted on ^5'+MemMsgArea.Name);

    IF (MHeader.MTo.A1S <> '') THEN
      SysOpLog('  To: "'+MHeader.MTo.A1S+'"');

    IF (ReplyTo <> -1) THEN
    BEGIN
      LoadHeader(ReplyTo,MHeader);
      Inc(MHeader.Replies);
      SaveHeader(ReplyTo,MHeader);
    END;

    IF (ThisUser.MsgPost < 2147483647) THEN
      Inc(ThisUser.MsgPost);

    IF (PublicPostsToday < 255) THEN
      Inc(PublicPostsToday);

    IF (NOT (FNoCredits IN ThisUser.Flags)) THEN
      AdjustBalance(General.CreditPost);

    SaveURec(ThisUser,UserNum);

    Update_Screen;

  END;
END;

PROCEDURE ListMessages(Pub: Boolean);
VAR
  MHeader: MHeaderRec;
  S,
  S1: STRING;
  TempHiMsg: Word;
  ADate: DateTime;
  NumDone: Byte;
BEGIN
  TempHiMsg := HiMsg;
  IF ((Msg_On < 1) OR (Msg_On > TempHiMsg)) THEN
    Exit;
  Abort := FALSE;
  Next := FALSE;
  CLS;
  PrintACR('旼컴컴컫컴컴컴컴컴컴컴컴컴컫컴컴컴컴컴컴컴컴컴컴쩡컴컴컴컴컴컴컴컴컴쩡컴컴컴커');
  PrintACR('� Msg# � Sender            � Receiver           �  '+'Subject           �! Posted �');
  PrintACR('읕컴컴컨컴컴컴컴컴컴컴컴컴컨컴컴컴컴컴컴컴컴컴컴좔컴컴컴컴컴컴컴컴컴좔컴컴컴켸');
  Dec(Msg_On);
  NumDone := 0;
  WHILE ((NumDone < (PageLength - 7)) AND (Msg_On >= 0) AND (Msg_On < TempHiMsg) AND (NOT Abort) AND (NOT HangUp)) DO
  BEGIN
    Inc(Msg_On);

    LoadHeader(Msg_On,MHeader);

    IF ((NOT (UnValidated IN MHeader.Status)) AND (NOT (MDeleted IN MHeader.Status))) OR (MsgSysOp) THEN
    BEGIN

      IF (MDeleted IN MHeader.Status) THEN
        S := '''D'
      ELSE IF (UnValidated IN MHeader.Status) THEN
        S := '''U'
      ELSE IF ToYou(MHeader) OR FromYou(MHeader) THEN
        S := '''>'
      ELSE IF (Pub) AND (TempLastRead < MHeader.Date) THEN
        S := '''*'
      ELSE
        S := ' ';

      S := S + ' "'+PadLeftInt(Msg_On,5)+'  #';

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
  END;
END;

PROCEDURE MainRead(OncOnly,AskUpdate,Pub: Boolean);
VAR
  User: UserRecordType;
  MHeader: MHeaderRec;
  Cmd,
  NewMenuCmd: AStr;
  Junk: Str36;
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
    CantBeSeen := (NOT MsgSysOp) AND ((UnValidated IN MHeader.Status) OR (MDeleted IN MHeader.Status) OR
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
        IF (Pub) THEN
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
      IF (Pub) AND (UnValidated IN MHeader.Status) THEN
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
        IF (Pub) THEN
          AskPost := TRUE;
      END
      ELSE
      BEGIN
        IF ((CLSMsg IN ThisUser.SFlags) AND (NOT Contlist)) THEN
          Cls
        ELSE
          NL;
        ReadMsg(Msg_On,Msg_On,HiMsg);
        IF (Pub) AND (TempLastRead < MHeader.Date) AND (MHeader.Date <= GetPackDateTime) THEN
          TempLastRead := MHeader.Date;
        IF (Pub) THEN
          IF (PublicReadThisCall < 32767) THEN
            Inc(PublicReadThisCall);
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
          1 : ;             { Read Again }
          2 : Dec(Msg_On);  { Previous Message }

          3 : IF (NOT MsgSysOp) THEN
                Print('^7You do not have the required access level for this option!^1')
              ELSE
                MoveMsg(Msg_On);

          4 : IF (NOT CoSysOp) THEN
                Print('^7You do not have the required access level for this option!^1')
              ELSE
                ExtractMsgToFile(Msg_On,Mheader);

          5 : IF (NOT FromYou(MHeader)) AND (NOT MsgSysOp) THEN
              BEGIN
                NL;
                Print('^7You can only edit messages that you have sent!^1');
              END
              ELSE
              BEGIN
                REPEAT
                  NL;
                  Prt('Message editing [^5?^4=^5Help^4]: ');
                  IF (MsgSysOp) THEN
                    Onek(Cmd1,'QADEFOPRSTV?'^M,TRUE,TRUE)
                  ELSE
                    Onek(Cmd1,'QDEFOST?'^M,TRUE,TRUE);
                  CASE Cmd1 OF
                    (*
                    'D' : FOR Counter := 1 TO 6 DO
                            IF (HeaderLine(MHeader,Msg_On,HiMsg,Counter,Junk) <> '') THEN
                              PrintACR(Headerline(MHeader,Msg_On,HiMsg,Counter,Junk));
                    'O' : IF PYNQ('Reload old information? ',0,FALSE) THEN
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
                            Onek(Cmd1,'Q123'^M,TRUE,TRUE);
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
                            Onek(Cmd1,'Q123'^M,TRUE,TRUE);
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
                    *)
                    'A' : IF (NOT MsgSysOp) THEN
                          BEGIN
                            NL;
                            Print('^7You do not have the required access level for this option!^1')
                          END
                          ELSE
                          BEGIN
                            IF (MHeader.From.Anon IN [1,2]) THEN
                            BEGIN
                              MHeader.From.Anon := 0;
                              NL;
                              Print('Message status is not anonymous.');
                              SysOpLog('Message status is not anonymous.');
                            END
                            ELSE
                            BEGIN
                              LoadURec(User,MHeader.From.UserNum);
                              IF AACS1(User,MHeader.From.UserNum,General.CSOP) THEN
                                MHeader.From.Anon := 2
                              ELSE
                                MHeader.From.Anon := 1;
                              NL;
                              Print('Message status is anonymous.');
                              SysOpLog('Message status is anonymous.');
                            END;
                          END;

                    'D' : BEGIN
                            NL;
                            FOR Counter := 1 TO 6 DO
                              IF (HeaderLine(MHeader,Msg_On,HiMsg,Counter,Junk) <> '') THEN
                                PrintACR(Headerline(MHeader,Msg_On,HiMsg,Counter,Junk));
                          END;

                    'E' : BEGIN
                            EditMessageText(Msg_On);
                            LoadHeader(Msg_On,MHeader);
                          END;

                    'F' : IF (MHeader.From.Anon > 0) OR (MsgSysOp) THEN
                          BEGIN
                            NL;
                            Print('^11. Posted from: ^5'+MHeader.From.A1S);
                            Print('^12. Real name  : ^5'+MHeader.From.Real);
                            Print('^13. System name: ^5'+MHeader.From.Name);
                            NL;
                            Prt('Edit name [^51^4-^53^4,^5<CR>^4=^5Quit^4]: ');
                            Onek(Cmd1,^M'123',TRUE,TRUE);
                            CASE Cmd1 OF
                              '1' : BEGIN
                                      NL;
                                      Prt('Posted from: ');
                                      InputDefault(MHeader.From.A1S,MHeader.From.A1S,36,[],FALSE);
                                    END;
                              '2' : BEGIN
                                      NL;
                                      Prt('Real name: ');
                                      InputDefault(MHeader.From.Real,MHeader.From.Real,36,[],FALSE);
                                    END;
                              '3' : BEGIN
                                      NL;
                                      Prt('System name: ');
                                      InputDefault(MHeader.From.Name,MHeader.From.Name,36,[],FALSE);
                                    END;
                            END;
                            Cmd1 := #0;
                          END;

                    'O' : BEGIN
                            NL;
                            IF PYNQ('Reload old information? ',0,FALSE) THEN
                              LoadHeader(Msg_On,MHeader);
                          END;
                    'P' : IF (NOT Pub) THEN
                          BEGIN
                            NL;
                            Print('^7This option is not available when reading private messages!^1');
                          END
                          ELSE IF (NOT MsgSysOp) THEN
                          BEGIN
                            NL;
                            Print('^7You do not have the required access level for this option!^1')
                          END
                          ELSE
                          BEGIN
                            IF (Permanent IN MHeader.Status) THEN
                            BEGIN
                              Exclude(MHeader.Status,Permanent);
                              NL;
                              Print('Message status is not permanent.');
                              SysOpLog('Message status is not permanent.');
                            END
                            ELSE
                            BEGIN
                              Include(MHeader.Status,Permanent);
                              NL;
                              Print('Message status is permanent.');
                              SysOpLog('Message status is permanent.');
                            END;
                          END;


                    'R' : IF (NOT MsgSysOp) THEN
                          BEGIN
                            NL;
                            Print('^7You do not have the required access level for this option!^1')
                          END
                          ELSE
                          BEGIN
                            IF (Sent IN MHeader.Status) THEN
                            BEGIN
                              Exclude(MHeader.Status,Sent);
                              IF (PUB) AND (MemMsgArea.MAType IN [1..2]) AND (NOT (MAScanOut IN MemMsgArea.MAFlags)) THEN
                                UpdateBoard;
                              NL;
                              Print('Message status is not sent.');
                              SysOpLog('Message status is not sent.');
                            END
                            ELSE
                            BEGIN
                              Include(MHeader.Status,Sent);
                              NL;
                              Print('Message status is sent.');
                              SysOpLog('Message status is sent.');
                            END;
                          END;

                    'S' : IF (NOT MsgSysOp) THEN
                          BEGIN
                            NL;
                            Print('^7You do not have the required access level for this option!^1')
                          END
                          ELSE IF (MHeader.FileAttached > 0) THEN
                          BEGIN
                            NL;
                            Print('^7There is no file attached to this message!^1');
                          END
                          ELSE
                          BEGIN
                            NL;
                            Prt('Subj: ');
                            InputDefault(MHeader.Subject,MHeader.Subject,40,[ColorsAllowed],FALSE);
                            SysOpLog('Message subject has been modified.');
                          END;

                    'T' : BEGIN
                            NL;
                            Print('^11. Posted to  : ^5'+MHeader.MTo.A1S);
                            Print('^12. Real name  : ^5'+MHeader.MTo.Real);
                            Print('^13. System name: ^5'+MHeader.MTo.Name);
                            NL;
                            Prt('Edit name [^51^4-^53^4,^5<CR>^4=^5Quit^4]: ');
                            Onek(Cmd1,^M'123',TRUE,TRUE);
                            CASE Cmd1 OF
                              '1' : BEGIN
                                      NL;
                                      Prt('Posted to: ');
                                      InputDefault(MHeader.MTo.A1S,MHeader.MTo.A1S,36,[],FALSE);
                                    END;
                              '2' : BEGIN
                                      NL;
                                      Prt('Real name: ');
                                      InputDefault(MHeader.MTo.Real,MHeader.MTo.Real,36,[],FALSE);
                                    END;
                              '3' : BEGIN
                                      NL;
                                      Prt('System name: ');
                                      InputDefault(MHeader.MTo.Name,MHeader.MTo.Name,36,[],FALSE);
                                    END;
                            END;
                            Cmd1 := #0;
                          END;

                    'V' : IF (NOT Pub) THEN
                          BEGIN
                            NL;
                            Print('^7This option is not available when reading private messages!^1');
                          END
                          ELSE IF (NOT MsgSysOp) THEN
                          BEGIN
                            NL;
                            Print('^7You do not have the required access level for this option!^1')
                          END
                          ELSE
                          BEGIN
                            IF (UnValidated IN MHeader.Status) THEN
                            BEGIN
                              Exclude(MHeader.Status,UnValidated);
                              NL;
                              Print('Message status is validated.');
                              SysOpLog('Message status is validated.');
                            END
                            ELSE
                            BEGIN
                              Include(MHeader.Status,UnValidated);
                              NL;
                              Print('Message status is unvalidated.');
                              SysOpLog('Message status is unvalidated.');
                            END;
                          END;

                    '?' : BEGIN
                            NL;
                            LCmds(15,3,'From','To');
                            LCmds(15,3,'Subject','Edit text');
                            LCmds(15,3,'Oops','Display header');
                            IF (MsgSysOp) THEN
                            BEGIN
                              LCmds(15,5,'Permanent','Validation');
                              LCmds(15,5,'Rescan','Anonymous');
                            END;
                            LCmds(15,3,'Quit','');
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
                  IF (MHeader.From.Anon = 0) OR (AACS(General.AnonPubRead)) THEN
                    IF PYNQ('Is this to be a private reply? ',0,Prvt IN MHeader.Status) THEN
                      IF (MAPrivate IN MemMsgArea.MAFlags) THEN
                        IF PYNQ('Reply in Email? ',0,FALSE) THEN
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
                IF (Pub) THEN
                BEGIN
                  LoadHeader(HiMsg,MHeader);
                  IF (MHeader.Date <= GetPackDateTime) THEN
                    TempLastRead := MHeader.Date;
                END;
                Next := FALSE;
              END;

          8 : IF (Pub) AND ((Msg_On - MHeader.ReplyTo) > 0) AND (MHeader.ReplyTo > 0) THEN
              BEGIN
                IF (ThreadStart = 0) THEN
                  ThreadStart := Msg_On;
                Dec(Msg_On,MHeader.ReplyTo);
              END;

          9 : IF (Pub) AND ((ThreadStart >= 1) AND (ThreadStart <= HiMsg)) THEN
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
                  Print('^7This is a permanent public message!^1');
                END
                ELSE
                BEGIN
                  IF (Msg_On >= 1) AND (Msg_On <= HiMsg) AND (MsgSysOp OR FromYou(MHeader)) THEN
                  BEGIN
                    LoadHeader(Msg_On,MHeader);
                    IF (MDeleted IN MHeader.Status) THEN
                      Exclude(MHeader.Status,MDeleted)
                    ELSE
                      Include(MHeader.Status,MDeleted);
                    SaveHeader(Msg_On,MHeader);
                    IF (NOT (MDeleted IN MHeader.Status)) THEN
                    BEGIN
                      IF FromYou(MHeader) THEN
                      BEGIN
                        IF (ThisUser.MsgPost < 2147483647) THEN
                          Inc(ThisUser.MsgPost);
                        AdjustBalance(General.Creditpost);
                      END;
                      NL;
                      Print('Public message undeleted.');
                      SysOpLog('* Undeleted public message: ^5'+MHeader.Subject);
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
                      SysOpLog('* Deleted public message: ^5'+MHeader.Subject);
                    END;
                  END
                  ELSE
                  BEGIN
                    NL;
                    Print('^7You can only delete public messages from you!^1');
                  END;
                END;
              END
              ELSE
              BEGIN
                IF (Msg_On >= 1) AND (Msg_On <= HiMsg) AND (MsgSysOp OR FromYou(MHeader) OR ToYou(MHeader)) THEN
                BEGIN
                  LoadHeader(Msg_On,MHeader);
                  IF (MDeleted IN MHeader.Status) THEN
                    Exclude(MHeader.Status,MDeleted)
                  ELSE
                    Include(MHeader.Status,MDeleted);
                  SaveHeader(Msg_On,MHeader);
                  IF (NOT (MDeleted IN MHeader.Status)) THEN
                  BEGIN
                    LoadURec(User,MHeader.MTo.UserNum);
                    IF (User.Waiting < 255) THEN
                      Inc(User.Waiting);
                    SaveURec(User,MHeader.MTo.UserNum);
                    NL;
                    Print('Private message undeleted.');
                    IF FromYou(MHeader) OR (MsgSysOp) THEN
                      SysOpLog('* Undeleted private message from: ^5'+Caps(MHeader.From.A1S))
                    ELSE IF ToYou(MHeader) OR (MsgSysOp) THEN
                      SysOpLog('* Undeleted private message to: ^5'+Caps(MHeader.MTo.A1S));
                  END
                  ELSE
                  BEGIN
                    LoadURec(User,MHeader.MTo.UserNum);
                    IF (User.Waiting > 0) THEN
                      Dec(User.Waiting);
                    SaveURec(User,MHeader.MTo.UserNum);
                    NL;
                    Print('Private message deleted.');
                    IF FromYou(MHeader) OR (MsgSysOp) THEN
                      SysOpLog('* Deleted private message from: ^5'+Caps(MHeader.From.A1S))
                    ELSE IF ToYou(MHeader) OR (MsgSysOp) THEN
                      SysOpLog('* Deleted private message to: ^5'+Caps(MHeader.MTo.A1S));
                  END;
                END
                ELSE
                BEGIN
                  NL;
                  Print('^7You can only delete private messages from or to you!^1');
                END;
              END;
         12 : IF (NOT Pub) THEN
              BEGIN
                NL;
                Print('^7This option is not available when reading private messages!^1');
              END
              ELSE
              BEGIN
                NL;
                Print('Highest-read pointer for this area set to message #'+IntToStr(Msg_On)+'.');
                IF (MHeader.Date <= GetPackDateTime) THEN
                  TempLastRead := MHeader.Date;
              END;
         13 : BEGIN
                IF (Pub) AND (AskUpdate) THEN
                BEGIN
                  NL;
                  IF PYNQ('Update message read pointers for this area? ',0,FALSE) THEN
                  BEGIN
                    LoadLastReadRecord(LastReadRecord);
                    LastReadRecord.LastRead := GetPackDateTime;
                    SaveLastReadRecord(LastReadRecord);
                  END;
                END;
                DoneScan := TRUE;
                Next := TRUE;
              END;
         14 : BEGIN
                DoneScan := TRUE;
                Abort := TRUE;
              END;
         15 : ListMessages(Pub);
         16 : IF (NOT CoSysOp) THEN
                Print('^7You do not have the required access level for this option!^1')
              ELSE IF (LastAuthor < 1) OR (LastAuthor > (MaxUsers - 1)) THEN
                Print('^7The sender of this message does not have an account on this BBS!^1')
              ELSE IF (CheckPW) THEN
                UserEditor(LastAuthor);
         17 : IF (NOT PUB) THEN
              BEGIN
                NL;
                Print('^7This option is not available when reading private messages!^1');
              END
              ELSE
              BEGIN
                IF (MAForceRead IN MemMsgArea.MAFlags) THEN
                BEGIN
                  NL;
                  Print('^7This message area can not be removed from your new scan!^1')
                END
                ELSE
                BEGIN

                  NL;
                  Print('^5'+MemMsgArea.Name+'^3 '+AOnOff(LastReadRecord.NewScan,'will NOT','WILL')+
                        ' be scanned in future new scans.');
                  SysOpLog('* Toggled ^5'+MemMsgArea.Name+ '^1 '+AOnOff(LastReadRecord.NewScan,'out of','back in')+
                           ' new scan.');

                  LoadLastReadRecord(LastReadRecord);
                  LastReadRecord.NewScan := (NOT LastReadRecord.NewScan);
                  SaveLastReadRecord(LastReadRecord);
                END;
              END;
         18 : Inc(Msg_On);
         19 : IF (NOT CoSysOp) THEN
                Print('^7You do not have the required access level for this option!^1')
              ELSE IF (LastAuthor < 1) OR (LastAuthor > (MaxUsers - 1)) THEN
                Print('^7The sender of this message does not have an account on this BBS!^1.')
              ELSE
              BEGIN
                LoadURec(User,LastAuthor);
                ShowUserInfo(1,LastAuthor,User);
              END;
         20 : IF (NOT CoSysOp) THEN
                Print('^7You do not have the required access level for this option!^1')
              ELSE IF (LastAuthor < 1) OR (LastAuthor > (MaxUsers - 1)) THEN
                Print('^7The sender of this message does not have an account on this BBS!^1')
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
    IF PYNQ('%LFValidate all messages here? ',0,FALSE) THEN
    BEGIN
      FOR MsgNum := 1 TO HiMsg DO
      BEGIN
        LoadHeader(MsgNum,MHeader);
        IF (UnValidated IN MHeader.Status) THEN
          Exclude(MHeader.Status,UnValidated);
        SaveHeader(MsgNum,MHeader);
      END;
    END;

  IF ((Pub) AND (AskPost) AND (AACS(MemMsgArea.PostACS)) AND
     (NOT (RPost IN ThisUser.Flags)) AND (PublicPostsToday < General.MaxPubPost)) THEN
    IF (TReadPrompt <> 7) THEN
      IF PYNQ('%LFPost on ^5'+MemMsgArea.Name+'^7? ',0,FALSE) THEN
        IF (MAPrivate IN MemMsgArea.MAFlags) THEN
          Post(-1,MHeader.From,PYNQ('%LFIs this to be a private message? ',0,FALSE))
        ELSE
          Post(-1,MHeader.From,FALSE);
END;

PROCEDURE ReadAllMessages(MenuOption: Str50);
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
    Print('%LFNo messages on ^5'+MemMsgArea.Name+'^1.');
    IF (Novice IN ThisUser.Flags) THEN
      PauseScr(FALSE);
  END
  ELSE
  BEGIN

    Msg_On := 1;
    Inputstr := '?';
    REPEAT
      IF (InputStr = '?') THEN
        ListMessages(MsgArea <> -1);
      NL;
      { Prompt(FString.ReadQ); }
      Prt('Select message (^51^4-^5'+IntToStr(HiMsg)+'^4) [^5?^4=^5First^4,^5<CR>^4=^5Next^4,^5Q^4=^5Quit^4)]: ');
      (*
      lRGLngStr(32,FALSE);
      *)
      ScanInput(InputStr,'Q?'^M);

      IF (InputStr = 'Q') THEN
        Msg_On := 0
      ELSE
      BEGIN

        IF (InputStr = ^M) THEN
        BEGIN
          InputStr := '?';
          IF (Msg_On >= HiMsg) THEN
            Msg_On := 1;
        END
        ELSE IF (InputStr = '?') THEN
        BEGIN
          Msg_On := 1;
          InputStr := '?';
        END
        ELSE
        BEGIN
          Msg_On := StrToInt(InputStr);
          IF (Msg_On >= 1) AND (Msg_On <= HIMsg) THEN
            InputStr := 'Q'
          ELSE
          BEGIN
            NL;
            Print('^7The range must be from 1 to '+IntToStr(HiMsg)+'^1');
            PauseScr(FALSE);
            Msg_On := 1;
            InputStr := '?';
          END;
        END;
      END;
    UNTIL (InputStr = 'Q') OR (HangUp);

    IF (Msg_On >= 1) AND (Msg_On <= HiMsg) AND (NOT HangUp) THEN
    BEGIN
      IF (MsgArea <> -1) THEN
      BEGIN
        LoadLastReadRecord(LastReadRecord);
        TempLastRead := LastReadRecord.LastRead;
      END;
      MainRead(FALSE,FALSE,(MsgArea <> -1));
      IF (MsgArea <> -1) THEN
      BEGIN
        LastReadRecord.LastRead := TempLastRead;
        SaveLastReadRecord(LastReadRecord);
      END;
    END;

  END;
  MsgArea := SaveReadMsgArea;
  LoadMsgArea(MsgArea);
END;

FUNCTION FirstNew: Word;
VAR
  MHeader: MHeaderRec;
  MaxMsgs,
  MsgNum: Word;
  Done: Boolean;
BEGIN
  MaxMsgs := HiMsg;
  MsgNum := 0;
  IF (MaxMsgs > 0) THEN
  BEGIN
    Done := FALSE;
    MsgNum := 1;
    WHILE (MsgNum <= MaxMsgs) AND (NOT Done) DO
    BEGIN
      LoadHeader(MsgNum,MHeader);
      IF (LastReadRecord.LastRead < MHeader.Date) THEN
        Done := TRUE
      ELSE
      BEGIN
        IF (MsgNum < MaxMsgs) THEN
          Inc(MsgNum,1)
        ELSE
        BEGIN
          MsgNum := 0;
          Done := TRUE;
        END;
      END;
    END;
  END;
  FirstNew := MsgNum;
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
      Prompt('^1Scanning ^5'+MemMsgArea.Name+' #'+IntToStr(CompMsgArea(MsgArea,0))+' ^1...');
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
          IF (Cmd1 IN ['Y',^M]) THEN
            IF ToYou(MsgHeader) THEN
              Match := TRUE;
          IF (Cmd1 IN ['F','A']) THEN
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
            NL;
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
        BackErase(14 + Lennmci(MemMsgArea.Name) + Length(IntToStr(CompMsgArea(MsgArea,0))));
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
      Onek(Cmd,'QFTSAY?'^M,TRUE,TRUE);
      IF (Cmd = '?') THEN
      BEGIN
        NL;
        LCmds(15,5,'From field','To field');
        LCmds(15,5,'Subject field','All text');
        LCmds(15,5,'Your messages','Quit');
      END;
    UNTIL (Cmd <> '?') OR (HangUp);
  NL;
  IF (NOT (Cmd IN ['Q',^M])) THEN
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
      ScanNew := PYNQ('Scan new messages only? ',0,TRUE);
    IF (ScanGlobal) OR ((MenuOption = '') AND PYNQ('Global scan? ',0,FALSE)) THEN
    BEGIN
      MArea := 1;
      WHILE (MArea >= 1) AND (MArea <= NumMsgAreas) AND (NOT Abort) AND (NOT HangUp) DO
      BEGIN
        Searchboard(MArea,Cmd);
        Wkey;
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
  ScanAllPublicMsgFile: FILE OF Boolean;
  MsgHeader: MHeaderRec;
  MArea,
  SaveMsgArea: Integer;
  MsgNum,
  PubMsgsFound: Word;
  SaveConfSystem,
  AnyFound,
  FirstTime,
  MsgsFound: Boolean;
BEGIN
  SaveMsgArea := MsgArea;
  SaveConfSystem := ConfSystem;
  ConfSystem := FALSE;
  IF (SaveConfSystem) THEN
    NewCompTables;
  Assign(ScanAllPublicMsgFile,TempDir+'SAPM'+IntToStr(ThisNode)+'.DAT');
  ReWrite(ScanAllPublicMsgFile);
  FOR MArea := 1 TO NumMsgAreas DO
  BEGIN
    MsgsFound := FALSE;
    Write(ScanAllPublicMsgFile,MsgsFound);
  END;
  Prompt('%LF^5Scanning for your new public messages ... ^1');
  FirstTime := TRUE;
  AnyFound := FALSE;
  MArea := 1;
  WHILE (MArea >= 1) AND (MArea <= NumMsgAreas) AND (NOT Abort) AND (NOT HangUp) DO
  BEGIN
    IF (MsgArea <> MArea) THEN
      ChangeMsgArea(MArea);
    IF (MsgArea = MArea) THEN
    BEGIN
      InitMsgArea(MsgArea);
      IF (LastReadRecord.NewScan) THEN
      BEGIN
        Reset(MsgHdrF);
        Reset(MsgTxtF,1);
        IF (IOResult = 0) THEN
        BEGIN
          PubMsgsFound := 0;
          MsgNum := FirstNew;
          IF (MsgNum > 0) AND (FileSize(MsgHdrF) > 0) THEN
            WHILE (MsgNum <= FileSize(MsgHdrF)) AND (NOT HangUp) DO
            BEGIN
              LoadHeader(MsgNum,MsgHeader);
              IF (ToYou(MsgHeader)) THEN
              BEGIN
                Seek(ScanAllPublicMsgFile,(MArea - 1));
                MsgsFound := TRUE;
                Write(ScanAllPublicMsgFile,MsgsFound);
                Inc(PubMsgsFound);
              END;
              Inc(MsgNum);
            END;
          Close(MsgHdrF);
          Close(MsgTxtF);
          IF (PubMsgsFound > 0) THEN
          BEGIN
            IF (FirstTime) THEN
            BEGIN
              NL;
              NL;
              FirstTime := FALSE;
            END;
            Print('^5'+PadLeftStr(MemMsgArea.Name,30)+' ^1'+IntToStr(PubMsgsFound));
            AnyFound := TRUE;
          END;
        END;
      END;
    END;
    Inc(MArea);
  END;
  Close(ScanAllPublicMsgFile);
  IF (NOT AnyFound) THEN
    Print('^5No messages found.^1')
  ELSE
  BEGIN
    Abort := FALSE;
    Next := FALSE;
    NL;
    IF PYNQ('Read your new public messages now? ',0,FALSE) THEN
    BEGIN
      Assign(ScanAllPublicMsgFile,TempDir+'SAPM'+IntToStr(ThisNode)+'.DAT');
      Reset(ScanAllPublicMsgFile);
      MArea := 1;
      WHILE (MArea >= 1) AND (MArea <= NumMsgAreas) AND (NOT Abort) AND (NOT HangUp) DO
      BEGIN
        Seek(ScanAllPublicMsgFile,(MArea - 1));
        Read(ScanAllPublicMsgFile,MsgsFound);
        IF (MsgsFound) THEN
          ScanMessages(MArea,TRUE,'N');
        WKey;
        Inc(MArea);
      END;
      Close(ScanAllPublicMsgFile);
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
      IF (LastReadRecord.NewScan) OR ((MAForceRead IN MemMsgArea.MAFlags) AND (NOT CoSysOp)) THEN
      BEGIN
        TempLastRead := LastReadRecord.LastRead;
        Lil := 0;
        { Prompt('^3'+FString.NewScan1);}
        lRGLngStr(8,FALSE);
        Msg_On := FirstNew;
        IF (Msg_On > 0) THEN
          MainRead(FALSE,FALSE,(MsgArea <> -1));

        LastReadRecord.LastRead := TempLastRead;
        SaveLastReadRecord(LastReadRecord);

        (*  Add backarase *)
      END;
    END;
  END;

BEGIN
  SaveMsgArea := MsgArea;
  MArea := MsgArea;
  Global := FALSE;
  Abort := FALSE;
  Next := FALSE;
  IF (UpCase(MenuOption[1]) = 'C') THEN
    MArea := MsgArea
  ELSE IF (UpCase(MenuOption[1]) = 'G') THEN
    Global := TRUE
  ELSE IF (StrToInt(MenuOption) <> 0) THEN
    MArea := StrToInt(MenuOption)
  ELSE IF (MenuOption = '') THEN
    Global := PYNQ('%LFScan all message areas? ',0,FALSE);
  IF (NOT Global) THEN
    NewScan(MArea)
  ELSE
  BEGIN
    MArea := 1;
    WHILE (MArea >= 1) AND (MArea <= NumMsgAreas) AND (NOT Abort) AND (NOT HangUp) DO
    BEGIN
      NewScan(MArea);
      WKey;
      Inc(MArea);
    END;
    SysOpLog('Global new scan of message areas');
  END;
  MsgArea := SaveMsgArea;
  LoadMsgArea(MsgArea);
END;

END.
