{$A+,B-,D+,E-,F+,I-,L+,N-,O+,R-,S+,V-}

UNIT SysChat;

INTERFACE

USES
  Common;

PROCEDURE RequestSysOpChat(CONST MenuOption: STr50);
PROCEDURE ChatFileLog(b: Boolean);
PROCEDURE Chat;

IMPLEMENTATION

USES
  Crt,
  Dos,
  Email,
  Event,
  TimeFunc;

VAR
  UserChatArray: ARRAY [1..10] OF AStr;
  SysOpChatArray: ARRAY [1..10] OF AStr;
  UserXPos,
  UserYPos,
  SysOpXPos,
  SysOpYPos: Byte;

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
          END;
          NoSound;
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
                      Chat;
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

PROCEDURE ANSIG(X,Y: Byte);
BEGIN
  IF (ComPortSpeed > 0) THEN
    IF (OkAvatar) THEN
      SerialOut(^V^H+Chr(Y)+Chr(X))
    ELSE
      SerialOut(#27+'['+IntToStr(Y)+';'+IntToStr(X)+'H');
  IF (WantOut) THEN
    GoToXY(X,Y);
END;

PROCEDURE SysOpChatWindow;
BEGIN
  CLS;

  ANSIG(1,1);

  Prompt('嬪様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様邑');

  ANSIG(1,12);

  Prompt('塒様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様余');

  ANSIG(1,13);

  Prompt('嬪様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様邑');

  ANSIG(1,24);

  Prompt('塒様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様余');

  ANSIG(37,25);

  Prompt('Help');

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

PROCEDURE Chat;
VAR
  S,
  SysOpStr,
  UserStr,
  SysOpLastLineStr,
  UserLastLineStr: AStr;     (* Was S *)

  C: Char;
  Counter,
  Counter1,
  SysOpCPos,
  UserCPos: Byte;

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

  SysOpLastLineStr := '';
  UserLastLineStr := '';
  SysOpXPos := 2;
  SysOpYPos := 2;
  UserXPos := 2;
  UserYPos := 14;

  SysOpStr := '';
  UserStr := '';
  SysOpCPos := 1;
  UserCPos := 1;

  SysOpChatWindow;

  ANSIG(SysOpXPos,SysOpYPos);

  REPEAT

    C := Char(GetKey);

    CheckHangUp;

    CASE Ord(C) OF
      32..255 : IF (WColor) THEN
                BEGIN
                  IF (SysOpCPos < 79) THEN
                  BEGIN
                    SysOpStr[SysOpCPos] := C;
                    Inc(SysOpCPos);
                    ANSIG(SysOpXPos,SysOpYPos);
                    OutKey(C);
                    Inc(SysOpXPos);
                    IF (Trapping) THEN
                      Write(TrapFile,C);
                  END
                  ELSE
                  BEGIN
                    SysOpStr[0] := Chr(SysOpCPos - 1);

                    Counter := (SysOpCPos - 1);
                    WHILE (Counter > 0) AND (SysOpStr[Counter] <> ' ') AND (SysOpStr[Counter] <> ^H) DO
                      Dec(Counter);
                    IF (Counter > (SysOpCPos DIV 2)) AND (Counter <> (SysOpCPos - 1)) THEN
                    BEGIN
                      SysOpLastLineStr := Copy(SysOpStr,(Counter + 1),(SysOpCPos - Counter));
                      FOR Counter1 := (SysOpCPos - 2) DOWNTO Counter DO
                      BEGIN
                        ANSIG(SysOpXPos,SysOpYPos);
                        Prompt(^H);
                        Dec(SysOpXPos);
                      END;
                      FOR Counter1 := (SysOpCPos - 2) DOWNTO Counter DO
                      BEGIN
                        ANSIG(SysOpXPos,SysOpYPos);
                        Prompt(' ');
                        Inc(SysOpXPos);
                      END;
                      SysOpStr[0] := Chr(Counter - 1);
                    END;
                    NL;

                    Inc(SysOpYPos);
                    SysOpXPos := 2;
                    ANSIG(SysOpXPos,SysOpYPos);

                    SysOpCPos := 1;
                    SysOpStr := '';
                    IF (SysOpLastLineStr <> '') THEN
                    BEGIN
                      SysOpXPos := Length(SysOpLastLineStr) + 2;
                      Prompt(SysOpLastLineStr);
                      ANSIG(SysOpXPos,SysOpYPos);
                      SysOpStr := SysOpLastLineStr;
                      SysOpLastLineStr := '';
                      SysOpCPos := (Length(SysOpStr) + 1);
                    END;

                  END;

                END
                ELSE
                BEGIN
                  IF (UserCPos < 79) THEN
                  BEGIN
                    UserStr[UserCPos] := C;
                    Inc(UserCPos);
                    ANSIG(UserCPos,UserYPos);
                    OutKey(C);
                    Inc(UserXPos);
                    IF (Trapping) THEN
                      Write(TrapFile,C);
                  END
                  ELSE
                  BEGIN
                    UserStr[0] := Chr(UserCPos - 1);

                    Counter := (UserCPos - 1);
                    WHILE (Counter > 0) AND (UserStr[Counter] <> ' ') AND (UserStr[Counter] <> ^H) DO
                      Dec(Counter);
                    IF (Counter > (UserCPos DIV 2)) AND (Counter <> (UserCPos - 1)) THEN
                    BEGIN
                      UserLastLineStr := Copy(UserStr,(Counter + 1),(UserCPos - Counter));
                      FOR Counter1 := (UserCPos - 2) DOWNTO Counter DO
                      BEGIN
                        ANSIG(UserXPos,UserYPos);
                        Prompt(^H);
                        Dec(UserXPos);
                      END;
                      FOR Counter1 := (UserCPos - 2) DOWNTO Counter DO
                      BEGIN
                        ANSIG(UserXPos,UserYPos);
                        Prompt(' ');
                        Inc(UserXPos);
                      END;
                      UserStr[0] := Chr(Counter - 1);
                    END;
                    NL;

                    Inc(UserYPos);
                    UserXPos := 2;
                    ANSIG(UserXPos,UserYPos);

                    UserCPos := 1;
                    UserStr := '';
                    IF (UserLastLineStr <> '') THEN
                    BEGIN
                      UserXPos := Length(UserLastLineStr) + 2;
                      Prompt(UserLastLineStr);
                      ANSIG(UserXPos,UserYPos);
                      UserStr := UserLastLineStr;
                      UserLastLineStr := '';
                      UserCPos := (Length(UserStr) + 1);
                    END;

                  END;

               END;
      8 :      IF (WColor) THEN
               BEGIN
                 IF (SysOpCPos > 1) THEN
                 BEGIN
                   ANSIG(SysOpXPos,SysOpYPos);
                   Dec(SysOpCPos);
                   Dec(SysOpXPos);
                   BackSpace;
                 END;
               END
               ELSE
               BEGIN
                 IF (UserCPos > 1) THEN
                 BEGIN
                   ANSIG(UserXPos,UserYPos);
                   Dec(UserCPos);
                   Dec(UserXPos);
                   BackSpace;
                 END;
               END;
      13 :     IF (WColor) THEN
               BEGIN
                 SysOpStr[0] := Chr(SysOpCPos - 1);

               END
               ELSE
               BEGIN
                 UserStr[0] := Chr(UserCPos - 1);

               END;

    END;




    (*
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
      {
      Print('^5/BYE^3:   Hang up');
      Print('^5/CLS^3:   Clear the screen');
      Print('^5/PAGE^3:  Page the SysOp and User');
      Print('^5/Q^3:     Exit chat mode'^M^J);
      }
      lRGLngStr(65,FALSE);
    END
    ELSE IF (S = '/CLS') THEN
      CLS
    ELSE IF (S = '/PAGE') THEN
    BEGIN
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
    *)
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
