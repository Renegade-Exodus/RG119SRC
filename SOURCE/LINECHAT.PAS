{$IFDEF WIN32}
{$I DEFINES.INC}
{$ENDIF}

{$A+,B-,D+,E-,F+,I-,L+,N-,O+,R-,S+,V-}

UNIT LineChat;

INTERFACE

USES
  Common;

PROCEDURE RequestSysOpChat(CONST MenuOption: Str50);
PROCEDURE ChatFileLog(b: Boolean);
PROCEDURE SysOpLineChat;

IMPLEMENTATION

USES
  Crt,
  Dos,
  Email,
  Events,
  TimeFunc;

PROCEDURE RequestSysOpChat(CONST MenuOption: Str50);
VAR
  User: UserRecordType;
  MHeader: MHeaderRec;
  Reason: AStr;
  Cmd: Char;
  Counter: Byte;
  UNum,
  Counter1: Integer;
  Chatted: Boolean;
BEGIN
  IF (ChatAttempts < General.MaxChat) OR (CoSysOp) THEN
  BEGIN
    NL;
    IF (Pos(';',MenuOption) <> 0) THEN
      Print(Copy(MenuOption,(Pos(';',MenuOption) + 1),Length(MenuOption)))
    ELSE
      lRGLngStr(37,FALSE); { FString.ChatReason; }
    Chatted := FALSE;
    Prt(': ');
    MPL(60);
    InputL(Reason,60);
    IF (Reason <> '') THEN
    BEGIN
      Inc(ChatAttempts);
      SysOpLog('^4Chat attempt:');
      SL1(Reason);
      IF (NOT SysOpAvailable) AND AACS(General.OverRideChat) THEN
        PrintF('CHATOVR');
      IF (SysOpAvailable) OR (AACS(General.OverRideChat) AND PYNQ(^M^J'SysOp is not available. Override? ',0,FALSE)) THEN
      BEGIN
        lStatus_Screen(100,'Press [SPACE] to chat or [ENTER] for silence.',FALSE,Reason);
        { Print(FString.ChatCall1); }
        lRGLngStr(14,FALSE);
        Counter := 0;
        Abort := FALSE;
        NL;
        REPEAT
          Inc(Counter);
          WKey;
          IF (OutCom) THEN
            Com_Send(^G);
          { Prompt(FString.ChatCall2); }
          lRGLngStr(15,FALSE);
          IF (OutCom) THEN
            Com_Send(^G);
          IF (ShutUpChatCall) THEN
            Delay(600)
          ELSE
          BEGIN
{$IFDEF MSDOS}
            FOR Counter1 := 300 DOWNTO 2 DO
            BEGIN
              Delay(1);
              Sound(Counter1 * 10);
            END;
            FOR Counter1 := 2 TO 300 DO
            BEGIN
              Delay(1);
              Sound(Counter1 * 10);
            END;
            NoSound;
{$ENDIF}
{$IFDEF WIN32}
            Sound(3000, 200);
			Sound(1000, 200);
			Sound(3000, 200);
{$ENDIF}
          END;
          IF (KeyPressed) THEN
          BEGIN
            Cmd := ReadKey;
            CASE Cmd OF
               #0 : BEGIN
                      Cmd := ReadKey;
                      SKey1(Cmd);
                    END;
              #32 : BEGIN
                      Chatted := TRUE;
                      ChatAttempts := 0;
                      SysOpLineChat;
                    END;
               ^M : ShutUpChatCall := TRUE;
            END;
          END;
        UNTIL (Counter = 9) OR (Chatted) OR (Abort) OR (HangUp);
        NL;
      END;
      lStatus_Screen(100,'Chat Request: '+Reason,FALSE,Reason);
      IF (Chatted) THEN
        ChatReason := ''
      ELSE
      BEGIN
        ChatReason := Reason;
        PrintF('NOSYSOP');
        UNum := StrToInt(MenuOption);
        IF (UNum > 0) THEN
        BEGIN
          InResponseTo := #1'Tried chatting';
          LoadURec(User,UNum);
          NL;
          IF PYNQ('Send mail to '+Caps(User.Name)+'? ',0,FALSE) THEN
          BEGIN
            MHeader.Status := [];
            SEmail(UNum,MHeader);
          END;
        END;
      END;
      TLeft;
    END;
  END
  ELSE
  BEGIN
    PrintF('GOAWAY');
    UNum := StrToInt(MenuOption);
    IF (UNum > 0) THEN
    BEGIN
      InResponseTo := 'Tried chatting (more than '+IntToStr(General.MaxChat)+' times!)';
      SysOpLog(InResponseTo);
      MHeader.Status := [];
      SEmail(UNum,MHeader);
    END;
  END;
END;

PROCEDURE ChatFileLog(b: Boolean);
VAR
  s: AStr;
BEGIN
  s := 'Chat';
  IF (ChatSeparate IN ThisUser.SFlags) THEN
    s := s + IntToStr(UserNum);
  s := General.LogsPath+s+'.LOG';
  IF (NOT b) THEN
  BEGIN
    IF (CFO) THEN
    BEGIN
      lStatus_Screen(100,'Chat recorded to '+s,FALSE,s);
      CFO := FALSE;
      IF (TextRec(ChatFile).Mode <> FMClosed) THEN
        Close(ChatFile);
    END;
  END
  ELSE
  BEGIN
    CFO := TRUE;
    IF (TextRec(ChatFile).Mode = FMOutPut) THEN
      Close(ChatFile);
    Assign(ChatFile,s);
    Append(ChatFile);
    IF (IOResult = 2) THEN
      ReWrite(ChatFile);
    IF (IOResult <> 0) THEN
      SysOpLog('Cannot open chat log file: '+s);
    lStatus_Screen(100,'Recording chat to '+s,FALSE,s);
    WriteLn(ChatFile);
    WriteLn(ChatFile);
    WriteLn(ChatFile,Dat);
    WriteLn(ChatFile);
    Writeln(ChatFile,'Recorded with user: '+Caps(ThisUser.Name));
    WriteLn(ChatFile);
    WriteLn(ChatFile,'Chat reason: '+AOnOff(ChatReason = '','None',ChatReason));
    WriteLn(ChatFile);
    WriteLn(ChatFile);
    WriteLn(ChatFile,'------------------------------------');
    WriteLn(ChatFile);
  END;
END;

PROCEDURE InLi1(VAR S: STRING);
VAR
  C,
  C1: Char;
  Counter,
  Counter1,
  CPos: Byte;
BEGIN
  CPos := 1;
  S := '';
  IF (LastLineStr <> '') THEN
  BEGIN
    Prompt(LastLineStr);
    S := LastLineStr;
    LastLineStr := '';
    CPos := (Length(S) + 1);
  END;

  REPEAT
    C := Char(GetKey);
    CheckHangUp;
    CASE Ord(C) OF
      32..255 :
            IF (CPos < 79) THEN
            BEGIN
              S[CPos] := C;
              Inc(CPos);
              OutKey(C);
              IF (Trapping) THEN
                Write(TrapFile,C);
            END;
       16 : IF (OkANSI OR OkAvatar) THEN
            BEGIN
              C1 := Char(GetKey);
              UserColor(Ord(C1) - 48);
            END;
       27 : IF (CPos < 79) THEN
            BEGIN
              S[CPos] := C;
              Inc(CPos);
              OutKey(C);
              IF (Trapping) THEN
                Write(TrapFile,C);
            END;
        8 : IF (CPos > 1) THEN
            BEGIN
              Dec(CPos);
              BackSpace;
            END;
       24 : BEGIN
              FOR Counter := 1 TO (CPos - 1) DO
                BackSpace;
              CPos := 1;
            END;
        7 : IF (OutCom) THEN
              Com_Send(^G);
       23 : IF (CPos > 1) THEN
              REPEAT
                Dec(CPos);
                BackSpace;
              UNTIL (CPos = 1) OR (S[CPos] = ' ');
        9 : BEGIN
              Counter := (5 - (CPos MOD 5));
              IF ((CPos + Counter) < 79) THEN
                FOR Counter1 := 1 TO Counter DO
                BEGIN
                  S[CPos] := ' ';
                  Inc(CPos);
                  Prompt(' ');
                END;
           END;
    END;
  UNTIL ((C = ^M) OR (CPos = 79) OR (HangUp) OR (NOT InChat));
  IF (NOT InChat) THEN
  BEGIN
    C := #13;
    InChat := FALSE;
  END;
  S[0] := Chr(CPos - 1);
  IF (C <> ^M) THEN
  BEGIN
    Counter := (CPos - 1);
    WHILE (Counter > 0) AND (S[Counter] <> ' ') AND (S[Counter] <> ^H) DO
      Dec(Counter);
    IF (Counter > (CPos DIV 2)) AND (Counter <> (CPos - 1)) THEN
    BEGIN
      LastLineStr := Copy(S,(Counter + 1),(CPos - Counter));
      FOR Counter1 := (CPos - 2) DOWNTO Counter DO
        Prompt(^H);
      FOR Counter1 := (CPos - 2) DOWNTO Counter DO
        Prompt(' ');
      S[0] := Chr(Counter - 1);
    END;
  END;
  NL;
END;

PROCEDURE SysOpLineChat;
VAR
  S: AStr;
  Counter: Integer;
  ChatTime: LongInt;
  SaveEcho,
  SavePrintingFile,
  SaveMCIAllowed: Boolean;
BEGIN
  UserColor(1);
  SaveMCIAllowed := MCIAllowed;
  MCIAllowed := TRUE;
  ChatTime := GetPackDateTime;
  DOSANSIOn := FALSE;
  IF (General.MultiNode) THEN
  BEGIN
    LoadNode(ThisNode);
    SaveNAvail := (NAvail IN Noder.Status);
    Exclude(Noder.Status,NAvail);
    SaveNode(ThisNode);
  END;
  SavePrintingFile := PrintingFile;
  InChat := TRUE;
  ChatCall := FALSE;
  SaveEcho := Echo;
  Echo := TRUE;
  IF (General.AutoChatOpen) THEN
    ChatFileLog(TRUE)
  ELSE IF (ChatAuto IN ThisUser.SFlags) THEN
    ChatFileLog(TRUE);
  NL;
  Exclude(ThisUser.Flags,Alert);
  PrintF('CHATINIT');
  IF (NoFile) THEN
    (*
    Prompt('^5'+FString.EnGage);
    *)
    lRGLNGStr(2,FALSE);

  UserColor(General.SysOpColor);
  WColor := TRUE;

  IF (ChatReason <> '') THEN
  BEGIN
    lStatus_Screen(100,ChatReason,FALSE,S);
    ChatReason := '';
  END;

  REPEAT

    InLi1(S);

    IF (S[1] = '/') THEN
      S := AllCaps(S);

    IF (Copy(S,1,6) = '/TYPE ') AND (SysOp) THEN
    BEGIN
      S := Copy(S,7,(Length(S) - 6));
      IF (S <> '') THEN
      BEGIN
        PrintFile(S);
        IF (NoFile) THEN
          Print('*File not found*');
      END;
    END
    ELSE IF ((S = '/HELP') OR (S = '/?')) THEN
    BEGIN
      IF (SysOp) THEN
        Print('^5/TYPE d:\path\filename.ext^3: Type a file');
      (*
      Print('^5/BYE^3:   Hang up');
      Print('^5/CLS^3:   Clear the screen');
      Print('^5/PAGE^3:  Page the SysOp and User');
      Print('^5/Q^3:     Exit chat mode'^M^J);
      *)
      lRGLngStr(65,FALSE);
    END
    ELSE IF (S = '/CLS') THEN
      CLS
    ELSE IF (S = '/PAGE') THEN
    BEGIN
{$IFDEF MSDOS}
      FOR Counter := 650 TO 700 DO
      BEGIN
        Sound(Counter);
        Delay(4);
        NoSound;
      END;
      REPEAT
        Dec(Counter);
        Sound(Counter);
        Delay(2);
        NoSound;
      UNTIL (Counter = 200);
{$ENDIF}
{$IFDEF WIN32}
      Sound(650, 200);
	  Sound(700, 200);
	  Sound(600, 200);
	  Sound(500, 200);
	  Sound(400, 200);
	  Sound(300, 200);
{$ENDIF}
      Prompt(^G^G);
    END
    ELSE IF (S = '/BYE') THEN
    BEGIN
      Print('Hanging up ...');
      HangUp := TRUE;
    END
    ELSE IF (S = '/Q') THEN
    BEGIN
      InChat := FALSE;
      Print('Chat Aborted ...');
    END;
    IF (CFO) THEN
      WriteLn(ChatFile,S);
  UNTIL ((NOT InChat) OR (HangUp));

  PrintF('CHATEND');
  IF (NoFile) THEN
    (*
    Print('^5'+FString.lEndChat);
    *)
    lRGLngStr(3,FALSE);
  IF (General.MultiNode) THEN
  BEGIN
    LoadNode(ThisNode);
    IF (SaveNAvail) THEN
      Include(Noder.Status,NAvail);
    SaveNode(ThisNode);
  END;
  ChatTime := (GetPackDateTime - ChatTime);
  IF (ChopTime = 0) THEN
    Inc(FreeTime,ChatTime);
  TLeft;
  S := 'Chatted for '+FormattedTime(ChatTime);
  IF (CFO) THEN
  BEGIN
    S := S+'  -{ Recorded in Chat';
    IF (ChatSeparate IN ThisUser.SFlags) THEN
      S := S + IntToStr(UserNum);
    S := S+'.LOG }-';
  END;
  SysOpLog(S);
  InChat := FALSE;
  Echo := SaveEcho;
  IF ((HangUp) AND (CFO)) THEN
  BEGIN
    WriteLn(ChatFile);
    WriteLn(ChatFile,'=> User disconnected');
    WriteLn(ChatFile);
  END;
  PrintingFile := SavePrintingFile;
  IF (CFO) THEN
    ChatFileLog(FALSE);
  IF (InVisEdit) THEN
    Buf := ^L;
  MCIAllowed := SaveMCIAllowed;
END;

END.
