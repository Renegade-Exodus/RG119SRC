{$IFDEF WIN32}
{$I DEFINES.INC}
{$ENDIF}

{$A+,B-,D-,E-,F+,I-,L-,N-,O+,R-,S+,V-}

UNIT SplitCha;

INTERFACE

USES
  Common,
  MyIO;

PROCEDURE RequestSysOpChat(CONST MenuOption: Str50);
PROCEDURE ChatFileLog(b: Boolean);
PROCEDURE SysOpSplitChat;

IMPLEMENTATION

USES
  Crt,
  Dos,
  Email,
  Events,
  TimeFunc;

TYPE
  ChatStrArray = ARRAY [1..10] OF AStr;

VAR
  UserChat: ChatStrArray;
  SysOpChat: ChatStrArray;
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
  WriteLn('REETODO SPLITCHA RequestSysOpChat'); Halt;
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
                      SysOpSplitChat;
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

PROCEDURE Clear_Eol;
BEGIN
  IF (NOT OkAvatar) THEN
    SerialOut(#27'[K')
  ELSE
    SerialOut(^V^G);
  IF (WantOut) THEN
    ClrEOL;
END;

PROCEDURE SysOpChatWindow;
BEGIN
  CLS;
  ANSIG(1,1);
  Prompt('������������������������������������������������������������������������������͸');
  ANSIG(1,12);
  Prompt('�������������������������������͵ CTRL-Z Help ��������������������������������͵');
  ANSIG(1,23);
  Prompt('������������������������������������������������������������������������������;');
END;

PROCEDURE SysOpSplitChat;
VAR
  S,
  SysOpStr,
  UserStr,
  SysOpLastLineStr,
  UserLastLineStr: AStr;

  SysOpLine,
  UserLine,
  SaveWhereX,
  SaveWhereY,
  SaveTextAttr: Byte;

  C: Char;
  SysOpCPos,
  UserCPos: Byte;

  ChatTime: LongInt;
  SaveEcho,
  SavePrintingFile,
  SaveMCIAllowed: Boolean;

  PROCEDURE DoChar(C: Char; VAR CPos,XPos,YPos,Line: Byte; VAR ChatArray: ChatStrArray; VAR WrapLine: AStr);
  VAR
    Counter,
    Counter1: Byte;
  BEGIN
    IF (CPos < 79) THEN
    BEGIN
      ANSIG(XPos,YPos);
      ChatArray[Line][CPos] := C;
      OutKey(C);
      Inc(CPos);
      Inc(XPos);

      ChatArray[Line][0] := Chr(CPos - 1);

      IF (Trapping) THEN
        Write(TrapFile,C);

    END
    ELSE
    BEGIN
      ChatArray[Line][CPos] := C;
      Inc(CPos);

      ChatArray[Line][0] := Chr(CPos - 1);
      Counter := (CPos - 1);
      WHILE (Counter > 0) AND (ChatArray[Line][Counter] <> ' ') AND (ChatArray[Line][Counter] <> ^H) DO
        Dec(Counter);
      IF (Counter > (CPos DIV 2)) AND (Counter <> (CPos - 1)) THEN
      BEGIN
        WrapLine := Copy(ChatArray[Line],(Counter + 1),(CPos - Counter));
        FOR Counter1 := (CPos - 2) DOWNTO Counter DO
        BEGIN
          ANSIG(XPos,YPos);
          Prompt(^H);
          Dec(XPos);
        END;
        FOR Counter1 := (CPos - 2) DOWNTO Counter DO
        BEGIN
          ANSIG(XPos,YPos);
          Prompt(' ');
          Inc(XPos);
        END;
        ChatArray[Line][0] := Chr(Counter - 1);
      END;

      NL;

      XPos := 2;

      IF (YPos > 1) AND (YPos < 11) OR (YPos > 12) AND (YPos < 22) THEN
      BEGIN
        Inc(YPos);
        Inc(Line);
      END
      ELSE
      BEGIN

        FOR Counter := 1 TO 9 DO
          ChatArray[Counter] := ChatArray[Counter + 1];

        ChatArray[10] := '';


        FOR Counter := 10 DOWNTO 1 DO
        BEGIN
          ANSIG(2,Counter + 1);
          PrintMain(ChatArray[Counter]);
          Clear_EOL;
        END;

      END;

      ANSIG(XPos,YPos);

      CPos := 1;

      ChatArray[Line] := '';

      IF (WrapLine <> '') THEN
      BEGIN
        Prompt(WrapLine);
        ChatArray[Line] := WrapLine;
        WrapLine := '';
        CPos := (Length(ChatArray[Line]) + 1);
        XPos := Length(ChatArray[Line]) + 2;
      END;

    END;

  END;

  PROCEDURE DOBackSpace(VAR Cpos,XPos: Byte; YPos: Byte; VAR S: AStr);
  BEGIN
    IF (CPos > 1) THEN
    BEGIN
      ANSIG(XPos,YPos);
      BackSpace;
      Dec(CPos);
      Dec(XPos);
      S[0] := Chr(CPos - 1);
    END;
  END;

  PROCEDURE DoTab(VAR CPos,XPos: Byte; YPos: Byte; VAR S: AStr);
  VAR
    Counter,
    Counter1: Byte;
  BEGIN
    Counter := (5 - (CPos MOD 5));
    IF ((CPos + Counter) < 79) THEN
    BEGIN
      FOR Counter1 := 1 TO Counter DO
      BEGIN
        ANSIG(XPos,YPos);
        Prompt(' ');
        S[CPos] := ' ';
        Inc(CPos);
        Inc(XPos);
      END;
      S[0] := Chr(CPos - 1);
    END;
  END;

  PROCEDURE DOCarriageReturn(VAR CPos,XPos,YPos: Byte; VAR S: AStr);
  BEGIN

    S[0] := Chr(CPos - 1);

    (* Check Scrool here *)

    Inc(YPos);
    XPos := 2;
    { Fix Splitscreen so user and op stay on their own sides }
    If (YPos = 12) Then 
     Begin
      For i := 2 To 11 Do
       Begin
        ANSIG(1,i);
        Clear_EOL;
       End;
      YPos := 2;
    End
    Else If (YPos = 23) Then
     Begin
      For i := 13 To 22 Do
       Begin
        ANSIG(1,i);
        Clear_EOL;
       End;
    YPos := 13;
    End;
    
   ANSIG(XPos,YPos);

    (* Do Cmds Here or add as Ctrl *)

    CPos := 1;
    S := '';
  END;

  PROCEDURE DOBackSpaceWord(VAR CPos,XPos: Byte; YPos: Byte; VAR S: AStr);
  BEGIN
    IF (CPos > 1) THEN
    BEGIN
      REPEAT
        ANSIG(XPos,YPos);
        BackSpace;
        Dec(CPos);
        Dec(XPos);
      UNTIL (CPos = 1) OR (S[CPos] = ' ');
      S[0] := Chr(CPos - 1);
    END;
  END;

  PROCEDURE DOBackSpaceLine(VAR CPos,Xpos: Byte; YPos: Byte; VAR S: AStr);
  VAR
    Counter: Byte;
  BEGIN
    IF (CPos > 1) THEN
    BEGIN
      FOR Counter := 1 TO (CPos - 1) DO
      BEGIN
        ANSIG(XPos,YPos);
        BackSpace;
        Dec(CPos);
        Dec(XPos);
      END;
      S[0] := Chr(CPos - 1);
    END;
  END;

BEGIN
  SaveWhereX := WhereX;
  SaveWhereY := WhereY;
  SaveTextAttr := TextAttr;
  SaveScreen(Wind);

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
  {
  PrintF('CHATINIT');
  IF (NoFile) THEN
    (*
    Prompt('^5'+FString.EnGage);
    *)
    lRGLNGStr(2,FALSE);
  }


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
  UserYPos := 13;

  SysOpStr := '';
  UserStr := '';
  SysOpCPos := 1;
  UserCPos := 1;
  SysOpLine := 1;
  UserLine := 1;

  SysOpChatWindow;

  ANSIG(SysOpXPos,SysOpYPos);

  UserColor(General.SysOpColor);
  WColor := TRUE;

  REPEAT

    C := Char(GetKey);

    CheckHangUp;

    CASE Ord(C) OF
      32..255 :
          IF (WColor) THEN
            DoChar(C,SysOpCPos,SysOpXPos,SysOpYPos,SysOpLine,SysOpChat,SysOpLastLineStr)
          ELSE
            DoChar(C,UserCPos,UserXPos,UserYPos,UserLine,UserChat,UserLastLineStr);
      7 : IF (OutCom) THEN
            Com_Send(^G);
      8 : IF (WColor) THEN
            DOBackSpace(SysOpCpos,SysOpXPos,SysOpYPos,SysOpStr)
          ELSE
            DOBackSpace(UserCpos,UserXPos,UserYPos,UserStr);
      9 : IF (WColor) THEN
            DoTab(SysOpCPos,SysOpXPos,SysOpYPos,SysOpStr)
          ELSE
            DoTab(UserCPos,UserXPos,UserYPos,UserStr);
     13 : IF (WColor) THEN
            DOCarriageReturn(SysOpCPos,SysOpXPos,SysOpYPos,SysOpStr)
          ELSE
            DOCarriageReturn(UserCPos,UserXPos,UserYPos,UserStr);

     17 : InChat := FALSE;

     23 : IF (WColor) THEN
            DOBackSpaceWord(SysOpCPos,SysOpXPos,SysOpYPos,SysOpStr)
          ELSE
            DOBackSpaceWord(UserCPos,UserXPos,UserYPos,UserStr);
     24 : IF (WColor) THEN
            DOBackSpaceLine(SysOpCPos,SysOpXpos,SysOpYPos,SysOpStr)
          ELSE
            DOBackSpaceLine(UserCPos,UserXpos,UserYPos,UserStr);

     26 : ; { Help }
    END;

    (*

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

  RemoveWindow(Wind);
  ANSIG(SaveWhereX,SaveWhereY);
  TextAttr := SaveTextAttr;

  {
  PrintF('CHATEND');
  IF (NoFile) THEN
    (*
    Print('^5'+FString.lEndChat);
    *)
    lRGLngStr(3,FALSE);
  }
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
