{$IFDEF WIN32}
{$I DEFINES.INC}
{$ENDIF}

{$A+,B-,D+,E-,F+,I-,L+,N-,O+,R-,S+,V-}

UNIT EMail;

INTERFACE

USES
  Common;

PROCEDURE SSMail(MenuOption: Str50);
PROCEDURE SMail(MassMail: Boolean);
PROCEDURE SEMail(UNum: Integer; ReplyHeader: MHeaderRec);
PROCEDURE AutoReply(ReplyHeader: MHeaderRec);
PROCEDURE ReadMail;
PROCEDURE ShowEmail;

IMPLEMENTATION

USES
  Dos,
  Common5,
  File6,
  Mail0,
  Mail1,
  Mail3,
  SysOp2G,
  SysOp3,
  ShortMsg,
  TimeFunc,
  NodeList,
  MiscUser;

PROCEDURE SSMail(MenuOption: Str50);
VAR
  MHeader: MHeaderRec;
BEGIN
  InResponseTo := '';
  IF (Pos(';',MenuOption) = 0) AND (MenuOption <> '') THEN
    InResponseTo := #1'FeedBack'
  ELSE IF (MenuOption <> '') THEN
    IF (MenuOption[Pos(';', MenuOption) + 1] = '\') THEN
      InResponseTo := '\'+#1+Copy(MenuOption,(Pos(';',MenuOption) + 2),255)
    ELSE
      InResponseTo := #1+Copy(MenuOption,(Pos(';',MenuOption) + 1),255);
  IF (StrToInt(MenuOption) < 1) THEN
    SMail(FALSE)
  ELSE
  BEGIN
    MHeader.Status := [];
    SEMail(StrToInt(MenuOption),MHeader);
  END;
END;

PROCEDURE SMail(MassMail: Boolean);
VAR
  MaxMailListArray: ARRAY [1..255] OF Integer;
  User: UserRecordType;
  MHeader: MHeaderRec;
  SysOpName: STRING[36];
  MassACS: ACString;
  Cmd: Char;
  Counter,
  NumMassMailList: Byte;
  UNum: Integer;
  SaveEmailSent,
  Fee: Word;
  EmailOK: Boolean;

  PROCEDURE CheckItOut(VAR UNum1: Integer; ShowIt: Boolean);
  VAR
    User1: UserRecordType;
    ForUsrUNum,
    SaveUNum1,
    UNum2: Integer;
  BEGIN
    SaveUnum1 := UNum1;
    IF ((UNum1 < 1) OR (UNum1 > (MaxUsers - 1))) THEN
    BEGIN
      UNum1 := 0;
      Exit;
    END;
    LoadURec(User,UNum1);
    IF (User.Waiting >= General.MaxWaiting) OR (NoMail IN User.Flags) AND (NOT CoSysOp) THEN
    BEGIN
      UNum1 := 0;
      { Print(FString.CantEmail); }
      lRGLngStr(46,FALSE);
      Exit;
    END;
    ForUsrUNum := User.ForUsr;
    IF (ForUsrUNum < 1) OR (ForUsrUNum > (MaxUsers - 1)) THEN
      ForUsrUNum := 0;
    IF (ForUsrUNum <> 0) THEN
    BEGIN
      LoadURec(User1,ForUsrUNum);
      IF (ShowIt) THEN
        Print('[> '+Caps(User.Name)+' #'+IntToStr(UNum1)+': message forwarded to '+Caps(User1.Name)+'.');
      UNum1 := ForUsrUNum;
    END;
    IF (ShowIt) THEN
      FOR UNum2 := 1 TO NumMassMailList DO
        IF (MaxMailListArray[UNum2] = UNum1) THEN
        BEGIN
          IF (ShowIt) THEN
            Print('[> '+Caps(User.Name)+' #'+IntToStr(UNum1)+': Can''t send more than once.');
          UNum1 := 0;
          Exit;
        END;
    IF (SaveUNum1 <> UNum1) THEN
      IF ((SaveUNum1 >= 1) AND (SaveUNum1 <= (MaxUsers - 1))) THEN
        LoadURec(User,SaveUNum1);
  END;

  PROCEDURE SendIt(UNum1: Integer);
  BEGIN
    CheckItOut(UNum1,FALSE);
    IF (UNum1 = 0) OR (UNum1 = UserNum) THEN
      Exit;
    IF ((UNum1 >= 1) AND (UNum1 <= (MaxUsers - 1))) THEN
    BEGIN
      LoadURec(User,UNum1);
      IF (UNum1 = 1) THEN
      BEGIN
        Inc(ThisUser.FeedBack);

        IF (FeedBackPostsToday < 255) THEN
          Inc(FeedBackPostsToday);

      END
      ELSE
      BEGIN
        Inc(ThisUser.EmailSent);
        AdjustBalance(General.CreditEmail);

        IF (PrivatePostsToday < 255) THEN
          Inc(PrivatePostsToday);

      END;
      Inc(User.Waiting);
      SaveURec(User,UNum1);
    END;
    WITH MHeader.MTO DO
    BEGIN
      UserNum := UNum1;
      A1S := AllCaps(User.Name);
      Real := AllCaps(User.RealName);
      Name := AllCaps(User.Name);
    END;
    SaveHeader((HiMsg + 1),MHeader);
  END;

  PROCEDURE DoIt(Cmd1: Char);
  VAR
    UNum1: Integer;
  BEGIN
    InitMsgArea(-1);
    FillChar(MHeader,SizeOf(MHeader),0);
    MHeader.MTO.A1S := 'Mass private message';
    MHeader.MTO.Real := MHeader.MTO.A1S;
    IF (NOT InputMessage(FALSE,TRUE,'',MHeader,'',78,500)) THEN
      Exit;
    CASE Cmd1 OF
      '1' : BEGIN
              { Print(FString.MassEmail); }
              lRGLngStr(48,FALSE);
              SysOpLog('Mass-private message sent to: (by ACS "'+MassACS+'")');
              FOR UNum1 := 1 TO (MaxUsers - 1) DO
              BEGIN
                LoadURec(User,UNum1);
                IF (AACS1(User,UNum1,MassACS)) AND (UNum1 <> UserNum) AND (NOT (Deleted IN User.SFlags))
                   AND (NOT (LockedOut IN User.SFlags)) THEN
                BEGIN
                  SendIt(UNum1);
                  SysOpLog('   '+Caps(User.Name));
                  Print('   '+Caps(User.Name));
                END;
              END;
            END;
      '2' : BEGIN
              { Print(FString.MassEmailAll); }
              lRGLngStr(49,FALSE);
              SysOpLog('Mass-private message sent to ALL USERS.');
              FOR UNum1 := 1 TO (MaxUsers - 1) DO
              BEGIN
                LoadURec(User,UNum1);
                IF (UNum1 <> UserNum) AND (NOT (Deleted IN User.SFlags))
                   AND (NOT (LockedOut IN User.SFlags)) THEN
                  SendIt(UNum1);
              END;
            END;
      '3' : BEGIN
              { Print(FString.MassEmail); }
              lRGLngStr(48,FALSE);
              SysOpLog('Mass-private message sent to:');
              FOR UNum1 := 1 TO NumMassMailList DO
              BEGIN
                SendIt(MaxMailListArray[UNum1]);
                SysOpLog('   '+Caps(User.Name));
                Print('   '+Caps(User.Name));
              END;
            END;
    END;
  END;

BEGIN
  EmailOK := TRUE;

  IF ((REmail IN ThisUser.Flags) OR (NOT AACS(General.NormPrivPost))) AND (NOT CoSysOp) THEN
  BEGIN
    NL;
    Print('^7Your access privledges do not include sending private messages!^1');
    EmailOk := FALSE;
  END
  ELSE IF ((PrivatePostsToday >= General.MaxPrivPost) AND (NOT CoSysOp)) THEN
  BEGIN
    NL;
    Print('^7You have already sent the maximum private messages allowed per day!^1');
    EmailOk := FALSE;
  END
  ELSE IF (AccountBalance < General.CreditEmail) AND (General.CreditEmail > 0) AND (NOT (FNoCredits IN ThisUser.Flags)) THEN
  BEGIN
    NL;
    Print('^7Insufficient account balance to send private messages!^1');
    EmailOk := FALSE;
  END;

  IF (NOT EmailOk) THEN
  BEGIN
    IF (InWFCMenu) THEN
      PauseScr(FALSE);
    Exit;
  END;

  IF (NOT MassMail) THEN
  BEGIN
    IF (AACS(General.NetMailACS)) AND PYNQ(lRGLngStr(51,TRUE){FString.IsNetMail},0,FALSE) THEN
    BEGIN

      PrintF('NETMHELP');

      SysOpName := '';

      WITH MHeader.From DO
        GetNetAddress(SysOpName,Zone,Net,Node,Point,Fee,FALSE);

      IF (SysOpName = '') THEN
        Exit;

      MHeader.From.Name := SysOpName;

      MHeader.Status := [NetMail];

      SaveEmailSent := ThisUser.EmailSent;

      SEMail(0,MHeader);

      IF (ThisUser.EmailSent > SaveEmailSent) THEN
        Inc(ThisUser.Debit,Fee);

    END
    ELSE
    BEGIN

      { Print(FString.SendEMail); }
      lRGLngStr(47,FALSE);
      NL;
      Print('Enter User Number, Name, or Partial Search String.');
      Prt(': ');
      lFindUserWS(UNum);
      IF (UNum < 1) THEN
      BEGIN
        NL;
        PauseScr(FALSE);
      END
      ELSE
      BEGIN
        MHeader.Status := [];
        SEMail(UNum,MHeader);
      END;
    END;
  END
  ELSE
  BEGIN
    InResponseTo := '';
    NumMassMailList := 0;
    FillChar(MaxMailListArray,SizeOf(MaxMailListArray),0);
    NL;
    Print('Mass private message: Send message to multiple users.');
    IF (NOT CoSysOp) THEN
      Cmd := '3'
    ELSE
    BEGIN
      NL;
      Print('(1) Send to users with a certain ACS.');
      Print('(2) Send to all system users.');
      Print('(3) Send private messages to a list of users.');
      NL;
      Prt('Your choice [^51^4-^53^4,^5Q^4=^5Quit^4]: ');
      OneK(Cmd,'Q123',TRUE,TRUE);
    END;
    CASE Cmd OF
      '1' : BEGIN
              NL;
              Prt('Enter ACS: ');
              MPL((SizeOf(ACString) - 1));
              InputL(MassACS,(SizeOf(ACString) - 1));
              IF (MassACS <> '') THEN
              BEGIN
                NL;
                Print('Users marked by ACS "'+MassACS+'":');
                Abort := FALSE;
                Next := FALSE;
                Reset(UserFile);
                UNum := 1;
                WHILE (UNum <= (MaxUsers - 1)) AND (NOT Abort) AND (NOT HangUp) DO
                BEGIN
                  LoadURec(User,UNum);
                  IF (AACS1(User,UNum,MassACS)) AND (UNum <> UserNum) AND (NOT (Deleted IN User.SFlags))
                     AND (NOT (LockedOut IN User.SFlags)) THEN
                  BEGIN
                    PrintACR('   '+Caps(User.Name));
                    Inc(NumMassMailList);
                  END;
                  Inc(UNum);
                  WKey;
                END;
                Close(UserFile);
              END;
            END;
      '2' : BEGIN
              NL;
              Print('All users marked for mass-private messages.');
              Abort := FALSE;
              Next := FALSE;
              Reset(UserFile);
              UNum := 1;
              WHILE (UNum <= (MaxUsers - 1)) AND (NOT Abort) AND (NOT HangUp) DO  (* Was X - 1 *)
              BEGIN
                LoadURec(User,UNum);
                IF (UNum <> UserNum) AND (NOT (Deleted IN User.SFlags)) AND (NOT (LockedOut IN User.SFlags)) THEN
                BEGIN
                  PrintACR('   '+Caps(User.Name));
                  Inc(NumMassMailList);
                END;
                Inc(UNum);
                WKey;
              END;
              Close(UserFile);
            END;
      '3' : BEGIN
              NL;
              Print('You can send mass private messages to '
                    +AOnOff(CoSysOp,'255',IntToStr(General.MaxMassMailList))+' user''s');
              Print('Enter a blank line to stop entering names.');
              UNum := 1;
              WHILE (UNum <> 0) AND (NumMassMailList < General.MaxMassMailList) OR (UNum <> 0) AND (NumMassMailList < 255)
                AND (CoSysOp) DO
              BEGIN
                NL;
                Print('Enter User Number, Name, or Partial Search String.');
                Prt(': ');
                lFindUserWS(UNum);
                FOR Counter := 1 TO NumMassMailList DO
                  IF (MaxMailListArray[Counter] = UNum) THEN
                    UNum := 0;
                IF (UNum = UserNum) THEN
                  UNum := 0;
                IF (UNum > 0) THEN
                BEGIN
                  LoadURec(User,UNum);
                  IF (LockedOut IN User.SFlags) OR (Deleted IN User.SFlags) THEN
                    UNum := 0
                  ELSE
                  BEGIN
                    Inc(NumMassMailList);
                    MaxMailListArray[NumMassMailList] := UNum;
                  END;
                END;
              END;
              IF (NumMassMailList > 0) THEN
              BEGIN
                NL;
                Print('Users marked:');
                Abort := FALSE;
                Next := FALSE;
                Reset(UserFile);
                UNum := 1;
                WHILE (UNum <= NumMassMailList) AND (NOT Abort) AND (NOT HangUp) DO
                BEGIN
                  LoadURec(User,MaxMailListArray[UNum]);
                  PrintACR('   '+Caps(User.Name));
                  Inc(UNum);
                  WKey;
                END;
                Close(UserFile);
              END;
            END;
    END;
    IF (Cmd <> 'Q') THEN
    BEGIN
      NL;
      Print('Total users listed: '+IntToStr(NumMassMailList));
      IF (NumMassMailList > 0) THEN
      BEGIN
        NL;
        IF PYNQ('Send mass-private messages to the above list? ',0,FALSE) THEN
          DoIt(Cmd);
      END;
    END;
  END;
  SaveURec(ThisUser,UserNum);
END;

PROCEDURE SEMail(UNum: Integer; ReplyHeader: MHeaderRec);
VAR
  User: UserRecordType;
  MHeader: MHeaderRec;
  Counter,
  Counter1: Byte;
  SaveReadMsgArea: Integer;
  EmailOk: Boolean;
BEGIN

  IF (NOT (NetMail IN ReplyHeader.Status)) THEN
  BEGIN

    IF (UNum < 1) OR (UNum > (MaxUsers - 1)) THEN
      Exit;

    LoadURec(User,UNum);

    MHeader.Status := [];

    EmailOk := TRUE;

    IF ((REmail IN ThisUser.Flags) OR (NOT AACS(General.NormPrivPost))) AND (NOT CoSysOp) THEN
    BEGIN
      NL;
      Print('^7Your access privledges do not include sending private messages!^1');
      EmailOk := FALSE;
    END
    ELSE IF (AccountBalance < General.CreditEmail) AND (General.CreditEmail > 0) AND (NOT (FNoCredits IN ThisUser.Flags)) THEN
    BEGIN
      NL;
      Print('^7Insufficient account balance to send private messages!^1');
      EmailOk := FALSE;
    END
    ELSE IF (PrivatePostsToday >= General.MaxPrivPost) AND (NOT CoSysOp) THEN
    BEGIN
      NL;
      Print('^7You have already sent the maximum private messages allowed per day!^1');
      EmailOk := FALSE;
    END
    ELSE IF ((UNum = 1) AND (FeedbackPostsToday >= General.MaxFBack) AND (NOT CoSysOp)) THEN
    BEGIN
      NL;
      Print('^7You have already sent the maximum allowed feedback per day!^1');
      EmailOk := FALSE;
    END
    ELSE IF (User.Waiting >= General.MaxWaiting) AND (NOT CoSysOp) THEN
    BEGIN
      NL;
      Print('^7The mailbox for this user is full!^1');
      EmailOk := FALSE;
    END
    ELSE IF (NoMail IN User.Flags) AND (NOT CoSysOp) THEN
    BEGIN
      NL;
      Print('^7The mailbox for this user is closed!^1');
      EmailOk := FALSE;
    END;

    IF (NOT EmailOk) THEN
    BEGIN
      IF (INWFCMenu) THEN
        PauseScr(FALSE);
      Exit;
    END;

    IF ((User.ForUsr < 1) OR (User.ForUsr > (MaxUsers - 1))) THEN
      User.ForUsr := 0;

    IF (User.ForUsr > 0) THEN
    BEGIN
      UNum := User.ForUsr;
      LoadURec(User,UNum);
      IF (CoSysOp) THEN
      BEGIN
        NL;
        IF (NOT PYNQ('Send private message to '+Caps(User.Name)+'? ',0,FALSE)) THEN
          Exit;
      END;
    END;
  END
  ELSE
  BEGIN

    IF (NOT AACS(General.NetMailACS)) THEN
    BEGIN
      { Print(FString.NoNetMail); }
      lRGLngStr(50,FALSE);
      PauseScr(FALSE);
      Exit;
    END;

    User.Name := ReplyHeader.From.Name;
    User.RealName := ReplyHeader.From.Name;
    UNum := 0;
    MHeader.Status := [NetMail];

  END;

  SaveReadMsgArea := ReadMsgArea;

  InitMsgArea(-1);

  WITH MHeader.MTO DO
  BEGIN
    UserNum := UNum;
    A1S := AllCaps(User.Name);
    Real := AllCaps(User.RealName);
    Name := AllCaps(User.Name);
  END;

  IF (InputMessage(FALSE,TRUE,'',MHeader,'',78,500)) THEN
  BEGIN

    IF (NetMail IN ReplyHeader.Status) THEN
    BEGIN
      Include(MHeader.Status,NetMail);

      MHeader.NetAttribute := General.NetAttribute * [Intransit,Private,Crash,KillSent,Hold,Local];

      ChangeFlags(MHeader);

      Counter1 := 0;
      Counter := 0;
      WHILE (Counter <= 19) AND (Counter1 = 0) DO
      BEGIN
        IF (General.AKA[Counter].Zone = ReplyHeader.From.Zone) AND (General.AKA[Counter].Zone <> 0) THEN
          Counter1 := Counter;
        Inc(Counter);
      END;

      IF (CoSysop) AND (General.AKA[Counter1].Zone <> ReplyHeader.From.Zone) THEN
      BEGIN
        FOR Counter := 0 TO 19 DO
          IF (General.AKA[Counter].Net > 0) THEN
          BEGIN
            PrintACR(PadLeftInt((Counter + 1),2)+'. '+
                     IntToStr(General.AKA[Counter].Zone)+':'+
                     IntToStr(General.AKA[Counter].Net)+'/'+
                     IntToStr(General.AKA[Counter].Node)+
                     AOnOff((General.AKA[Counter].Point > 0),'.'+IntToStr(General.AKA[Counter].Point),''));
          END;
        InputByteWOC('%LFUse which AKA',Counter,[NumbersOnly],1,20);
        IF (Counter >= 1) OR (Counter <= 20) THEN
          Counter1 := (Counter - 1);
      END;

      WITH MHeader.From DO
      BEGIN
        Zone := General.AKA[Counter1].Zone;
        Net := General.AKA[Counter1].Net;
        Node := General.AKA[Counter1].Node;
        Point := General.AKA[Counter1].Point;
      END;

      WITH MHeader.MTO DO
      BEGIN
        Zone := ReplyHeader.From.Zone;
        Net := ReplyHeader.From.Net;
        Node := ReplyHeader.From.Node;
        Point := ReplyHeader.From.Point;
      END;

    END;

    IF (UNum = 1) THEN
    BEGIN
      Inc(ThisUser.FeedBack);

      IF (FeedBackPostsToday < 255) THEN
        Inc(FeedbackPostsToday);

    END
    ELSE
    BEGIN
      Inc(ThisUser.EmailSent);
      AdjustBalance(General.CreditEmail);

      IF (PrivatePostsToday < 255) THEN
        Inc(PrivatePostsToday);
    END;

    IF (UNum >= 1) AND (UNum <= (MaxUsers - 1)) THEN
    BEGIN
      LoadURec(User,UNum);
      Inc(User.Waiting);
      SaveURec(User,UNum);
    END;

    SaveHeader((HiMsg + 1),MHeader);

    IF (UserOn) THEN
      SysOpLog(AOnOff((NetMail IN MHeader.Status),'Netmail','Private message')+' sent to ^5'+Caps(User.Name)+'.');

    Print('^1'+AOnOff((NetMail IN MHeader.Status),'Netmail','Private message')+' sent to ^5'+Caps(User.Name)+'^1.');

    Update_Screen;
  END;

  InitMsgArea(SaveReadMsgArea);

  SaveURec(ThisUser,UserNum);
END;

PROCEDURE AutoReply(ReplyHeader: MHeaderRec);
VAR
  SysOpName: Str36;
  Fee: Word;
  TotPrivMsg: LongInt;
BEGIN

  IF AACS(General.NetMailACS) AND (NOT (NetMail IN ReplyHeader.Status)) AND
     PYNQ(lRGLngStr(51,TRUE){FString.IsNetMail},0,FALSE) THEN
  BEGIN
    ReplyHeader.Status := [NetMail];
    LastAuthor := 0;
    SysOpName := UseName(ReplyHeader.From.Anon,
                         AOnOff(MARealName IN MemMsgArea.MAFlags,
                         ReplyHeader.From.Real,
                         ReplyHeader.From.A1S));
    WITH ReplyHeader.From DO
      GetNetAddress(SysOpName,Zone,Net,Node,Point,Fee,FALSE);
    IF (SysOpName = '') THEN
      Exit;
    ReplyHeader.From.Name := SysOpName;
  END;

  TotPrivMsg := (ThisUser.EmailSent + ThisUser.FeedBack);

  IF (LastAuthor = 0) AND (NOT (NetMail IN ReplyHeader.Status)) THEN
  BEGIN
    LastAuthor := SearchUser(ReplyHeader.From.A1S,TRUE);
    IF (LastAuthor = 0) THEN
      Print('^7That user does not have an account on this BBS!^1')
    ELSE
      SEMail(LastAuthor,ReplyHeader);
  END
  ELSE
  BEGIN
    SEMail(LastAuthor,ReplyHeader);
    IF ((ThisUser.EmailSent + ThisUser.FeedBack) > TotPrivMsg) THEN
      IF (NetMail IN ReplyHeader.Status) THEN
      BEGIN
        WITH ReplyHeader.From DO
          GetNetAddress(SysOpName,Zone,Net,Node,Point,Fee,TRUE);
        Inc(ThisUser.Debit,Fee)
      END
      ELSE
        SendShortMessage(ReplyHeader.From.UserNum,
                         Caps(ThisUser.Name)+' replied to "'+AOnOff((ReplyHeader.FileAttached > 0),
                         StripName(ReplyHeader.Subject),ReplyHeader.Subject)+'" on '+DateStr+' '+TimeStr+'.');
  END;
END;

PROCEDURE ReadMail;
TYPE
  MessageArrayType = ARRAY [1..255] OF SmallWord;
VAR
  MessageArray: MessageArrayType;
  User: UserRecordType;
  MHeader: MHeaderRec;
  InputStr: AStr;
  Cmd: Char;
  SNum,
  MNum: Byte;
  UNum,
  SaveReadMsgArea: Integer;
  DeleteOk,
  ReplyOk: Boolean;

  PROCEDURE RemoveCurrent(VAR SNum1,MNum1: Byte; VAR MessageArray1: MessageArrayType);
  VAR
    MsgNum: Byte;
  BEGIN
    Dec(MNum1);
    FOR MsgNum := SNum1 TO MNum1 DO
      MessageArray1[MsgNum] := MessageArray1[MsgNum + 1];
    IF (SNum1 > MNum1) THEN
      SNum1 := MNum1;
  END;

  PROCEDURE ReScan(VAR MNum1: Byte; VAR MessageArray1: MessageArrayType);
  VAR
    MsgNum: Word;
  BEGIN
    FillChar(MessageArray1,SizeOf(MessageArray1),0);
    MNum1 := 0;
    MsgNum := 1;
    WHILE (MsgNum <= HiMsg) DO
    BEGIN
      LoadHeader(MsgNum,MHeader);
      IF (MHeader.MTO.UserNum = UserNum) AND (NOT (MDeleted IN MHeader.Status)) THEN
      BEGIN
        Inc(MNum1);
        MessageArray1[MNum1] := MsgNum;
      END;
      Inc(MsgNum);
    END;
    ThisUser.Waiting := 0;
    SaveURec(ThisUser,UserNum);
  END;

  PROCEDURE ListYourEmail(VAR SNum1: Byte; MNum1: Byte; MessageArray1: MessageArrayType);
  VAR
    DT: DateTime;
    TempStr: AStr;
    j,
    NumDone: Byte;
  BEGIN
    IF (SNum1 < 1) OR (SNum1 > MNum1) THEN
      SNum1 := 1;
    Abort := FALSE;
    Next := FALSE;
    (*
    CLS;
    PrintACR('á⁄ƒƒƒƒƒ¬ƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒ¬ƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒ¬ƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒø');
    PrintACR('á≥à Num á≥â Date/Time         á≥ä Sender                 á≥ã Subject                  á≥');
    PrintACR('á¿ƒƒƒƒƒ¡ƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒ¡ƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒ¡ƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒŸ');
    *)
    lRGLngStr(60,FALSE);
    NumDone := 1;
    WHILE (NumDone < (PageLength - 5)) AND (SNum1 >= 1) AND (SNum1 <= MNum) AND (NOT Abort) AND (NOT HangUp) DO
    BEGIN
      LoadHeader(MessageArray1[SNum1],MHeader);
      TempStr := 'å'+PadRightInt(SNum1,5);
      IF (MHeader.From.Anon IN [1,2]) THEN
        TempStr := TempStr + '  ç[Unknown]          '
      ELSE
      BEGIN
        PackToDate(DT,MHeader.Date);
        j := DT.Hour;
        IF (j > 12) THEN
          Dec(j,12);
        IF (j = 0) THEN
          j := 12;
        TempStr := TempStr + '  ç'+ZeroPad(IntToStr(DT.Day))+
                             ' '+Copy(MonthString[DT.Month],1,3)+
                             ' '+IntToStr(DT.Year)+
                             '  '+ZeroPad(IntToStr(j))+
                             ':'+ZeroPad(IntToStr(DT.Min))+
                             AOnOff((DT.Hour >= 12),'p','a');
      END;
      TempStr := TempStr + ' é'+PadLeftStr(UseName(MHeader.From.Anon,MHeader.From.A1S),23);
      IF (MHeader.FileAttached = 0) THEN
        TempStr := TempStr + '  è'+Copy(MHeader.Subject,1,25)
      ELSE
        TempStr := TempStr + '  è'+StripName(Copy(MHeader.Subject,1,25));
      PrintACR(TempStr);
      WKey;
      Inc(SNum1);
      Inc(NumDone);
    END;
  END;

BEGIN
  ReadingMail := TRUE;
  SaveReadMsgArea := ReadMsgArea;
  InitMsgArea(-1);
  ReScan(MNum,MessageArray);
  IF (MNum = 0) THEN
    lRGLngStr(52,FALSE) { Print(FString.NoMailWaiting); }
  ELSE
  BEGIN
    Abort := FALSE;
    Next := FALSE;
    SNum := 1;
    Cmd := 'L';
    REPEAT

      REPEAT
        IF (Cmd = 'L') THEN
          ListYourEmail(SNum,MNum,MessageArray);
        NL;
        Prt('Select message (^51^4-^5'+IntToStr(MNum)+'^4) [^5?^4=^5First^4,^5<CR>^4=^5Next^4,^5Q^4=^5Quit^4)]: ');
        MPL(Length(IntToStr(MNum)));
        ScanInput(InputStr,'Q?'^M);
        Cmd := InputStr[1];
        IF (Cmd = 'Q') THEN
          SNum := 0
        ELSE
        BEGIN
          IF (Cmd IN ['-',^M]) THEN
            Cmd := 'L'
          ELSE IF (Cmd = '?') THEN
          BEGIN
            SNum := 1;
            Cmd := 'L';
          END
          ELSE
          BEGIN
            SNum := StrToInt(InputStr);
            IF (SNum >= 1) AND (SNum <= MNum) THEN
              Cmd := 'Q'
            ELSE
            BEGIN
              NL;
              Print('^7The range must be from 1 to '+IntToStr(MNum)+'^1');
              PauseScr(FALSE);
              SNum := 1;
              Cmd := 'L';
            END;
          END;
        END;
      UNTIL (Cmd = 'Q') OR (HangUp);

      IF (SNum >= 1) AND (SNum <= MNum) AND (NOT HangUp) THEN
      BEGIN
        Cmd := #0;
        REPEAT
          LoadHeader(MessageArray[SNum],MHeader);
          IF (Cmd <> '?') THEN
          BEGIN
            CLS;
            ReadMsg(MessageArray[SNum],SNum,MNum);
          END;
          { Prt(FString.ReadingEmail); }
          LOneK(lRGLngStr(13,TRUE),Cmd,'Q-ADFGLNRSUVXZM?'^M,TRUE,TRUE);
          CASE Cmd OF
            '-' : IF (SNum > 1) THEN
                    Dec(SNum)
                  ELSE
                    SNum := MNum;
            'A' : ;
            'D' : BEGIN
                    DeleteOk := TRUE;
                    IF (MHeader.FileAttached > 0) THEN
                      IF (CheckBatchDL(MHeader.Subject)) THEN
                      BEGIN
                        NL;
                        Print('If you delete this message, you will not be able to download');
                        Print('the attached file currently in your batch queue.');
                        NL;
                        IF NOT PYNQ('Continue with deletion? ',0,FALSE) THEN
                          DeleteOk := FALSE;
                      END;
                    IF (DeleteOk) THEN
                    BEGIN
                      Include(MHeader.Status,MDeleted);
                      SaveHeader(MessageArray[SNum],MHeader);
                      IF (MHeader.FileAttached = 1) THEN
                        Kill(MHeader.Subject);

                      IF (NOT (NetMail IN Mheader.Status)) AND
                         (MHeader.From.UserNum >= 1) AND
                         (MHeader.From.UserNum >= (MaxUsers - 1)) THEN
                        SendShortMessage(MHeader.From.UserNum,Caps(ThisUser.Name)+' read "'+StripName(MHeader.Subject)+
                                         '" on '+DateStr+' '+TimeStr+'.');
                      RemoveCurrent(SNum,MNum,MessageArray);
                    END;
                  END;
            'F' : ForwardMessage(MessageArray[SNum]);
            'G' : InputByteWOC('%LFGoto message',SNum,[NumbersOnly],1,MNum);
            'M' : IF (NOT MsgSysOp) THEN
                    Print('%LF^7You do not have the required access level for this option!^1%LF%PA')
                  ELSE
                  BEGIN
                    MoveMsg(MessageArray[SNum]);
                    LoadHeader(MessageArray[SNum],MHeader);
                    IF (MDeleted IN MHeader.Status) THEN
                      RemoveCurrent(SNum,MNum,MessageArray);
                  END;
            'R' : BEGIN
                    ReplyOk := TRUE;
                    IF (MHeader.From.Anon IN [1,2]) THEN
                      CASE MHeader.From.Anon OF
                        1 : ReplyOk := AACS(General.AnonPrivRead);
                        2 : ReplyOk := AACS(General.CSOP);
                      END;
                    IF (NOT ReplyOk) THEN
                      Print('%LF^7You can not reply to an anonymous message!^1%LF%PA')
                    ELSE
                    BEGIN
                      DumpQuote(MHeader);
                      AutoReply(MHeader);
                      DeleteOk := TRUE;
                      NL;
                      IF (NOT PYNQ('Delete original message? ',0,TRUE)) THEN
                        DeleteOk := FALSE;
                      IF (DeleteOk) AND (MHeader.FileAttached > 0) THEN
                        IF (CheckBatchDL(MHeader.Subject)) THEN
                        BEGIN
                          NL;
                          Print('If you delete this message, you will not be able to download the attached');
                          Print('file currently in your batch queue.');
                          NL;
                          IF NOT PYNQ('Continue with deletion? ',0,FALSE) THEN
                            DeleteOk := FALSE;
                        END;
                      IF (DeleteOk) THEN
                      BEGIN
                        Include(MHeader.Status,MDeleted);
                        IF (MHeader.FileAttached = 1) THEN
                          Kill(MHeader.Subject);
                        SaveHeader(MessageArray[SNum],MHeader);
                        RemoveCurrent(SNum,MNum,MessageArray);
                      END;
                    END;
                  END;
            'S' : IF (NOT CoSysOp) THEN
                    Print('%LF^7You do not have the required access level for this option!^1%LF%PA')
                  ELSE IF (LastAuthor < 1) OR (LastAuthor > (MaxUsers - 1)) THEN
                    Print('%LF^7The sender of this message does not have an account on this BBS!^1%LF%PA')
                  ELSE
                  BEGIN
                    LoadURec(User,LastAuthor);
                    ShowUserInfo(1,LastAuthor,User);
                    NL;
                    PauseScr(FALSE);
                  END;
            'U' : IF (NOT CoSysOp) THEN
                    Print('%LF^7You do not have the required access level for this option!^1%LF%PA')
                  ELSE IF (LastAuthor < 1) OR (LastAuthor > (MaxUsers - 1)) THEN
                    Print('%LF^7The sender of this message does not have an account on this BBS!^1%LF%PA')
                  ELSE IF (CheckPW) THEN
                    UserEditor(LastAuthor);
            'V' : IF (NOT CoSysOp) THEN
                    Print('%LF^7You do not have the required access level for this option!^1%LF%PA')
                  ELSE IF (LastAuthor < 1) OR (LastAuthor > (MaxUsers - 1)) THEN
                    Print('%LF^7The sender of this message does not have an account on this BBS!^1%LF%PA')
                  ELSE
                  BEGIN
                    LoadURec(User,LastAuthor);
                    AutoVal(User,LastAuthor);
                  END;
            'X' : IF (NOT CoSysOp) THEN
                    Print('%LF^7You do not have the required access level for this option!^1%LF%PA')
                  ELSE
                    ExtractMsgToFile(MessageArray[SNum],MHeader);
            'Z' : IF (NOT MsgSysOp) THEN
                    Print('%LF^7You do not have the required access level for this option!^1%LF%PA')
                  ELSE
                  BEGIN
                    DeleteOk := TRUE;
                    IF (MHeader.FileAttached > 0) THEN
                      IF CheckBatchDL(MHeader.Subject) THEN
                      BEGIN
                        NL;
                        Print('If you zap this message, you will not be able to download the attached');
                        Print('file currently in your batch queue.');
                        NL;
                        IF NOT PYNQ('Continue with zapping? ',0,FALSE) THEN
                          DeleteOk := FALSE;
                      END;
                    IF (DeleteOk) THEN
                    BEGIN
                      Include(MHeader.Status,MDeleted);
                      SaveHeader(MessageArray[SNum],MHeader);
                      IF (MHeader.FileAttached = 1) THEN
                        Kill(MHeader.Subject);
                      RemoveCurrent(SNum,MNum,MessageArray);
                    END;
                  END;
            '?' : BEGIN
                    NL;
                    LCmds(17,3,'-Read previous','Again');
                    LCmds(17,3,'Delete message','Forward messages');
                    LCmds(17,3,'Goto message','List messages');
                    LCmds(17,3,'Move message','Next message');
                    LCmds(17,3,'Reply to message','Show user');
                    LCmds(17,3,'User editor','Validate user');
                    LCmds(17,3,'Xtract to file','Zap (Delete w/o reciept)');
                    LCmds(17,3,'Quit','');
                  END;
          ELSE
            IF (SNum < MNum) THEN
              Inc(SNum)
            ELSE
              SNum := 1;
          END;
          IF (MNum = 0) THEN
            Cmd := 'Q';
        UNTIL (Cmd IN ['L','Q']) OR (HangUp);
      END;
      IF (Cmd = 'Q') THEN
        IF (RMsg IN ThisUser.Flags) AND (NOT CoSysOp) AND (MNum > 0) AND (NOT InWFCMenu) THEN
        BEGIN
          { Print(FString.SorryReply); }
          lRGLngStr(53,FALSE);
          SNum := 1;
          Cmd := 'L';
        END;
    UNTIL (Cmd = 'Q') OR (HangUp);
  END;
  Inc(ThisUser.Waiting,MNum);
  SaveURec(ThisUser,UserNum);
  LoadMsgArea(SaveReadMsgArea);
  ReadingMail := FALSE;
END;

PROCEDURE ShowEmail;
VAR
  User: UserRecordType;
  MHeader: MHeaderRec;
  Cmd: Char;
  SaveReadMsgArea: Integer;
  MsgNum,
  PreviousMsgNum,
  MaxMsgs: Word;
  AnyFound: Boolean;
BEGIN
  ReadingMail := TRUE;
  SaveReadMsgArea := ReadMsgArea;
  InitMsgArea(-1);
  Abort := FALSE;
  Next := FALSE;
  AnyFound := FALSE;
  Cmd := #0;
  MaxMsgs := HiMsg;
  MsgNum := 1;
  WHILE ((MsgNum <= MaxMsgs) AND (Cmd <> 'Q') AND (NOT HangUp)) DO
  BEGIN
    LoadHeader(MsgNum,MHeader);
    IF (MHeader.From.UserNum <> UserNum) THEN
      Inc(MsgNum)
    ELSE
    BEGIN
      AnyFound := TRUE;
      IF (Cmd <> '?') THEN
      BEGIN
        CLS;
        ReadMsg(MsgNum,MsgNum,MaxMsgs);
      END;
      NL;
      Prt('Private messages sent [^5?^4=^5Help^4]: ');
      IF (CoSysOp) THEN
        OneK(Cmd,'Q-ADENX?'^M,TRUE,TRUE)
      ELSE
        OneK(Cmd,'Q-ADEN?'^M,TRUE,TRUE);
      CASE Cmd OF
        '-' : BEGIN
                PreviousMsgNum := (MsgNum - 1);
                WHILE (PreviousMsgNum >= 1) AND (PreviousMsgNum <> MsgNum) DO
                BEGIN
                  LoadHeader(PreviousMsgNum,MHeader);
                  IF (MHeader.From.UserNum <> UserNum) THEN
                    Dec(PreviousMsgNum)
                  ELSE
                    MsgNum := PreviousMsgNum;
                END;
              END;
        'A' : ;
        'D' : IF (NOT (MDeleted IN MHeader.Status)) THEN
              BEGIN
                Include(MHeader.Status,MDeleted);
                SaveHeader(MsgNum,MHeader);
                LoadURec(User,MHeader.MTO.UserNum);
                IF (User.Waiting > 0) THEN
                  Dec(User.Waiting);
                SaveURec(User,MHeader.MTO.UserNum);
                Print('%LFPrivate message deleted.');
                SysOpLog('* Deleted private message to '+Caps(MHeader.From.A1S));
              END
              ELSE
              BEGIN
                Exclude(MHeader.Status,MDeleted);
                SaveHeader(MsgNum,MHeader);
                LoadURec(User,MHeader.MTO.UserNum);
                IF (User.Waiting < 255) THEN
                  Inc(User.Waiting);
                SaveURec(User,MHeader.MTO.UserNum);
                Print('%LFPrivate message undeleted.');
                SysOpLog('* Undeleted private message to '+Caps(MHeader.From.A1S));
              END;
        'E' : EditMessageText(MsgNum);
        'X' : IF (NOT CoSysOp) THEN
                Print('%LF^7You do not have the required access level for this option!^1%LF%PA')
              ELSE
                ExtractMsgToFile(MsgNum,MHeader);
        '?' : BEGIN
                Print('%LF<^3CR^1>Next message');
                LCmds(20,3,'Again','Edit message');
                LCmds(20,3,'Delete message','-Previous message');
                IF (CoSysOp) THEN
                  LCmds(20,3,'Xtract to file','Quit')
                ELSE
                  LCmds(20,3,'Quit','');
              END;
      ELSE
        Inc(MsgNum);
      END;
    END;
  END;
  IF (NOT AnyFound) THEN
  BEGIN
    NL;
    Print('^3No private messages sent.');
  END;
  LoadMsgArea(SaveReadMsgArea);
  ReadingMail := FALSE;
END;

END.
