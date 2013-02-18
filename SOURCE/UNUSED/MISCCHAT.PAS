{$A+,B-,D+,E-,F+,I-,L+,N-,O+,R-,S+,V-}

UNIT MiscChat;

INTERFACE

USES
  Common;

PROCEDURE RequestSysOpChat(CONST MenuOption: STr50);
PROCEDURE ChatFileLog(b: Boolean);

IMPLEMENTATION

USES
  Crt,
  Dos,
  Email,
  Event,
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

END.
