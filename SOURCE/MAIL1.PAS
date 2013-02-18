{$IFDEF WIN32}
{$I DEFINES.INC}
{$ENDIF}

{$A+,B-,D+,E-,F+,I-,L+,N-,O+,R-,S+,V-}

UNIT Mail1;

INTERFACE

USES
  Common;

FUNCTION Inputmessage(Pub,
                      IsReply: Boolean;
                      CONST MsgTitle: Str40;
                      VAR MHeader: MHeaderRec;
                      CONST ReadInMsg: AStr;
                      MaxLineLen: Byte;
                      MaxMsgLines: Integer): Boolean;
PROCEDURE Anonymous(Offline: Boolean; VAR MHeader: MHeaderRec);

IMPLEMENTATION

USES
  Crt,
  Common5,
  File8,
  File0,
  Mail0,
  TimeFunc;

VAR
  InportFile: Text;
  InportFileOpen: Boolean;
  Escp: Boolean;

PROCEDURE Anonymous(Offline: Boolean; VAR MHeader: MHeaderRec);
VAR
  An: Anontyp;
  HeaderL: AStr;
  UName,
  Junk: Str36;
  Cmd: Char;
  Counter: Byte;
BEGIN
  IF (ReadMsgArea <> -1) THEN
  BEGIN
    An := MemMsgArea.Anonymous;
    IF (An = ATNo) AND (AACS(General.AnonPubPost) AND (NOT Offline)) THEN
      An := ATYes;
    IF (RPostAn IN ThisUser.Flags) THEN
      An := ATNo;
  END
  ELSE IF (AACS(General.AnonPrivPost)) THEN
    An := ATYes
  ELSE
    An := ATNo;
  IF (Offline) THEN
  BEGIN
    Abort := FALSE;
    Next := FALSE;
    IF (An = ATNo) THEN
      FOR Counter := 1 TO 5 DO
      BEGIN
        HeaderL := Headerline(MHeader,FileSize(MsgHdrF),FileSize(MsgHdrF),Counter,Junk);
        IF (HeaderL <> '') THEN
          PrintACR(HeaderL);
      END
      ELSE
      BEGIN
        ReadMsg(FileSize(MsgHdrF),FileSize(MsgHdrF),FileSize(MsgHdrF));
        Reset(MsgHdrF);
        IF (IOResult = 2) THEN
          ReWrite(MsgHdrF);
        Reset(MsgTxtF,1);
        IF (IOResult = 2) THEN
          ReWrite(MsgTxtF,1);
        IF (IOResult <> 0) THEN
          SysOpLog('Anon: error opening message areas.');
      END;
  END;
  CASE An OF
    ATNo       : ;
    ATForced   : IF (CoSysOp) THEN
                   MHeader.From.Anon := 2
                 ELSE
                   MHeader.From.Anon := 1;
    ATYes      : BEGIN
                   NL;
                   IF PYNQ(AOnOff(ReadMsgArea <> - 1,'Post anonymously? ','Send anonymously? '),0,FALSE) THEN
                     IF (CoSysOp) THEN
                       MHeader.From.Anon := 2
                     ELSE
                       MHeader.From.Anon := 1;
                 END;
    ATDearAbby : BEGIN
                   NL;
                   Print(AOnOff(ReadMsgArea <> - 1,'Post as:','Send as:'));
                   NL;
                   Print('1. Abby');
                   Print('2. Problemed Person');
                   Print('3. '+Caps(ThisUser.Name));
                   NL;
                   Prt('Which? ');
                   OneK(Cmd,'123'^M,TRUE,TRUE);
                   CASE Cmd OF
                     '1' : MHeader.From.Anon := 3;
                     '2' : MHeader.From.Anon := 4;
                   END;
                 END;
     ATAnyName : BEGIN
                   NL;
                   Print('You can post under any name in this area.');
                   NL;
                   Prt('Name: ');
                   InputDefault(UName,MHeader.From.A1S,36,[InterActiveEdit],TRUE);
                   IF (UName <> MHeader.From.A1S) THEN
                   BEGIN
                     MHeader.From.Anon := 5;
                     MHeader.From.A1S := Caps(UName);
                   END;
                 END;
  END;
END;

PROCEDURE InputLine(VAR S: AStr; MaxLineLen: Byte);
VAR
  CKeyPos,
  RP,
  Counter,
  Counter1: Integer;
  CKey,
  ccc: Char;
  HitCmdKey,
  HitBkSpc,
  DoThisChar: Boolean;

  PROCEDURE BkSpc;
  BEGIN
    IF (CKeyPos > 1) THEN
    BEGIN
      IF (S[CKeyPos - 2] = '^') AND (S[CKeyPos - 1] IN [#0..#9]) THEN
        BEGIN
          Dec(CKeyPos);
          UserColor(1);
        END
      ELSE
        BEGIN
          BackSpace;
          Dec(RP);
        END;
      Dec(CKeyPos);
    END;
  END;

BEGIN
  Write_Msg := TRUE;
  HitCmdKey := FALSE;
  HitBkSpc := FALSE;
  ccc := '1';
  RP := 1;
  CKeyPos := 1;
  S := '';
  IF (LastLineStr <> '') THEN
  BEGIN
    Abort := FALSE;
    Next := FALSE;
    AllowAbort := FALSE;
    Reading_A_Msg := TRUE;
    PrintMain(LastLineStr);
    Reading_A_Msg := FALSE;
    AllowAbort := TRUE;
    S := LastLineStr;
    LastLineStr := '';
    IF (Pos(^[,S) > 0) THEN
      Escp := TRUE;
    CKeyPos := (Length(S) + 1);
    RP := CKeyPos;
  END;
  REPEAT
    IF ((InportFileOpen) AND (Buf = '')) THEN
      IF (NOT EOF(InportFile)) THEN
      BEGIN
        Counter1 := 0;
        REPEAT
          Inc(Counter1);
          Read(InportFile,Buf[Counter1]);
          IF (Buf[Counter1] = ^J) THEN
            Dec(Counter1);
        UNTIL (Counter1 >= 255) OR (Buf[Counter1] = ^M) OR (EOF(InportFile));
        Buf[0] := Chr(Counter1);
      END
      ELSE
      BEGIN
        Close(InportFile);
        InportFileOpen := FALSE;
        DOSANSIOn := FALSE;
        Buf := ^P+'1';
      END;
    CKey := Char(GetKey);
    DoThisChar := FALSE;
    IF ((CKey >= #32) AND (CKey <= #255)) THEN
    BEGIN
      IF (CKey = '/') AND (CKeyPos = 1) THEN
        HitCmdKey := TRUE
      ELSE
        DoThisChar := TRUE;
    END
    ELSE
      CASE CKey OF
        ^[ : DoThisChar := TRUE;
        ^H : IF (CKeyPos = 1) THEN
             BEGIN
               HitCmdKey := TRUE;
               HitBkSpc := TRUE;
             END
             ELSE
               BkSpc;
        ^I : BEGIN
               Counter := (5 - (CKeyPos MOD 5));
               IF ((CKeyPos + Counter) < StrLen) AND ((RP + Counter) < ThisUser.LineLen) THEN
                 FOR Counter1 := 1 TO Counter DO
                 BEGIN
                   OutKey(' ');
                   IF (Trapping) THEN
                     Write(TrapFile,' ');
                   S[CKeyPos] := ' ';
                   Inc(RP);
                   Inc(CKeyPos);
                 END;
             END;
        ^J : BEGIN
               OutKey(CKey);
               S[CKeyPos] := CKey;
               IF (Trapping) THEN
                 Write(TrapFile,^J);
               Inc(CKeyPos);
             END;
        ^N : BEGIN
               OutKey(^H);
               S[CKeyPos] := ^H;
               IF (Trapping) THEN
                 Write(TrapFile,^H);
               Inc(CKeyPos);
               Dec(RP);
             END;
        ^P : IF (OkANSI OR OkAvatar) AND (CKeyPos < (StrLen - 1)) THEN
             BEGIN
               CKey := Char(GetKey);
               IF (CKey IN ['0'..'9']) THEN
               BEGIN
                 ccc := CKey;
                 S[CKeyPos] := '^';
                 Inc(CKeyPos);
                 S[CKeyPos] := CKey;
                 Inc(CKeyPos);
                 UserColor(Ord(CKey) - Ord('0'));
               END;
               CKey := #0;
             END;
        ^W : IF (CKeyPos = 1) THEN
             BEGIN
               HitCmdKey := TRUE;
               HitBkSpc := TRUE;
             END
             ELSE
               REPEAT
                 BkSpc
               UNTIL (CKeyPos = 1) OR (S[CKeyPos] = ' ') OR ((S[CKeyPos] = ^H) AND (S[CKeyPos - 1] <> '^'));
     ^X,^Y : BEGIN
               CKeyPos := 1;
               FOR Counter := 1 TO (RP - 1) DO
                 BackSpace;
               RP := 1;
               IF (ccc <> '1') THEN
               BEGIN
                 CKey := ccc;
                 S[CKeyPos] := '^';
                 Inc(CKeyPos);
                 S[CKeyPos] := CKey;
                 Inc(CKeyPos);
                 UserColor(Ord(CKey) - Ord('0'));
               END;
               CKey := #0;
             END;
        END;
    IF (DoThisChar) AND ((CKey <> ^G) AND (CKey <> ^M)) THEN
      IF ((CKeyPos < StrLen) AND (Escp)) OR ((RP < ThisUser.LineLen) AND (NOT Escp)) THEN
      BEGIN
        IF (CKey = ^[) THEN
          Escp := TRUE;
        S[CKeyPos] := CKey;
        Inc(CKeyPos);
        Inc(RP);
        OutKey(CKey);
        IF (Trapping) THEN
          Write(TrapFile,CKey);
      END;
  UNTIL (((RP - 1) = MaxLineLen) AND (NOT Escp)) OR (CKeyPos = StrLen) OR (CKey = ^M) OR (HitCmdKey) OR (HangUp);
  IF (HitCmdKey) THEN
  BEGIN
    IF (HitBkSpc) THEN
      S := '/'^H
    ELSE
      S := '/';
  END
  ELSE
  BEGIN
    S[0] := Chr(CKeyPos - 1);
    IF (CKey <> ^M) AND (CKeyPos <> StrLen) AND (NOT Escp) THEN
    BEGIN
      Counter := (CKeyPos - 1);
      WHILE (Counter > 1) AND (S[Counter] <> ' ') AND ((S[Counter] <> ^H) OR (S[Counter - 1] = '^')) DO
        Dec(Counter);
      IF (Counter > (RP DIV 2)) AND (Counter <> (CKeyPos - 1)) THEN
      BEGIN
        LastLineStr := Copy(S,(Counter + 1),(CKeyPos - Counter));
        FOR Counter1 := (CKeyPos - 2) DOWNTO Counter DO
          BackSpace;
        S[0] := Chr(Counter - 1);
      END;
    END;
    IF (Escp) AND (RP = ThisUser.LineLen) THEN
      CKeyPos := StrLen;
    IF (CKeyPos <> StrLen) THEN
      NL
    ELSE
    BEGIN
      RP := 1;
      CKeyPos := 1;
      S := S + #29;
    END;
  END;
  Write_Msg := FALSE;
END;

FUNCTION Inputmessage(Pub,
                      IsReply: Boolean;
                      CONST MsgTitle: Str40;
                      VAR MHeader: MHeaderRec;
                      CONST ReadInMsg: AStr;
                      MaxLineLen: Byte;
                      MaxMsgLines: Integer): Boolean;
CONST
  TopScreen = 3;       {first screen line for Text entry}
  ScrollSize = 5;      {number OF lines to scroll by}
TYPE
  LinePointer = ^LineArray;
  LineArray = ARRAY [1..500] OF STRING[120];
VAR
  LinePtr: LinePointer;
  PhyLine: ARRAY [1..20] OF STRING[78];
  TotalLines: 1..500;

  MsgSubj: Str40;

  MsgTo: Str36;

  ScreenLines,
  MaxLines,
  LastQuoteLine,
  MaxQuoteLines,
  CurrentLine,
  TopLine,
  CCol: Integer;

  DisableMCI,
  CantAbort,
  Insert_Mode,
  SaveMsg: Boolean;

  PROCEDURE DoLines;
  BEGIN
    IF (OkANSI OR OkAvatar) THEN
      Print('^4旼컴:컴컴:컴컴:컴컴:컴컴:컴컴:컴컴:컴컴쩡컴�:컴컴:컴컴:컴컴:컴컴:컴컴:컴컴:컴커^1')
    ELSE
      Print('[---:----:----:----:----:----:----:----|----:----:----:----:----:----:----:---]');
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

  PROCEDURE Count_Lines;
  BEGIN
    TotalLines := MaxLines;
    WHILE (TotalLines > 0) AND (Length(LinePtr^[TotalLines]) = 0) DO
      Dec(TotalLines);
  END;

  PROCEDURE Append_Space;
  BEGIN
    LinePtr^[CurrentLine] := LinePtr^[CurrentLine]+' ';
  END;

  FUNCTION CurLength: Integer;
  BEGIN
    CurLength := Length(LinePtr^[CurrentLine]);
  END;

  FUNCTION Line_Boundry: Boolean;
   {is the cursor at either the start OF the END OF a line?}
  BEGIN
    Line_Boundry := (CCol = 1) OR (CCol > CurLength);
  END;

  FUNCTION CurChar: Char;
   {return the character under the cursor}
  BEGIN
    IF (CCol <= CurLength) THEN
      CurChar := LinePtr^[CurrentLine][CCol]
    ELSE
      CurChar := ' ';
  END;

  FUNCTION LastChar: Char;
   {return the last character on the current line}
  BEGIN
    IF (CurLength = 0) THEN
      LastChar := ' '
    ELSE
      LastChar := LinePtr^[CurrentLine][CurLength];
  END;

  PROCEDURE Remove_Trailing;
  BEGIN
    WHILE (Length(LinePtr^[CurrentLine]) > 0) AND (LinePtr^[CurrentLine][Length(LinePtr^[CurrentLine])] <= ' ') DO
      Dec(LinePtr^[CurrentLine][0]);
  END;

  FUNCTION Delimiter: Boolean;
   {return TRUE IF the current character is a Delimiter FOR words}
  BEGIN
    CASE CurChar OF
      '0'..'9', 'a'..'z', 'A'..'Z', '_':
            Delimiter := FALSE;
    ELSE
      Delimiter := TRUE;
    END;
  END;

  PROCEDURE Reposition(x: Boolean);
  VAR
    Eol: Integer;
  BEGIN
    IF (x) THEN
    BEGIN
      Eol := (CurLength + 1);
      IF (CCol > Eol) THEN
        CCol := Eol;
    END;
    Count_Lines;
    ANSIG(CCol,((CurrentLine - TopLine) + TopScreen));
    IF (Pos('>',Copy(LinePtr^[CurrentLine],1,4)) > 0) THEN
      Usercolor(3)
    ELSE
      Usercolor(1);
  END;

  PROCEDURE Set_PhyLine;
   {set physical line to match logical line (indicates display update)}
  BEGIN
    PhyLine[((CurrentLine - TopLine) + 1)] := LinePtr^[CurrentLine];
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

  PROCEDURE Truncate_Line;
   {update screen after changing END-OF-line}
  BEGIN
    IF (CCol > 0) THEN
      LinePtr^[CurrentLine][0] := Chr(CCol - 1);
    Reposition(TRUE);
    Clear_Eol;
    {Set_PhyLine;  don't understand this}
  END;

  PROCEDURE Refresh_Screen;
  VAR
    PLine,
    PCol,
    Phline,
    Junk: Integer;
  BEGIN
    IF (CurrentLine >= MaxLines) THEN
      CurrentLine := MaxLines;
    PLine := CurrentLine;
    CurrentLine := TopLine;
    PCol := CCol;
    CCol := 1;
    FOR Junk := TopLine TO ((TopLine + ScreenLines) - 1) DO
    BEGIN
      CurrentLine:= Junk;
      Phline := ((CurrentLine - TopLine) + 1);
      IF (CurrentLine > MaxLines) THEN
      BEGIN
        Reposition (TRUE);
        Prompt('^9--');
        PhyLine[Phline] := '--';
        Clear_Eol;
      END
      ELSE
      BEGIN
        IF (LinePtr^[CurrentLine] <> PhyLine[Phline]) THEN
        BEGIN
          Reposition (TRUE);
          MCIAllowed := FALSE;
          ColorAllowed := FALSE;
          AllowAbort := FALSE;
          PrintMain(Copy(LinePtr^[CurrentLine],1,MaxLineLen));
          MCIAllowed := TRUE;
          ColorAllowed := TRUE;
          AllowAbort := TRUE;
          IF (CurLength < Length(PhyLine[Phline])) THEN
            Clear_Eol;
          Set_PhyLine;
        END;
      END;
    END;
    Tleft;
    CCol := PCol;
    CurrentLine := PLine;
    Reposition(TRUE);
  END;

  PROCEDURE Scroll_Screen(Lines: Integer);
  BEGIN
    Inc(TopLine,Lines);
    IF (CurrentLine < TopLine) OR (CurrentLine >= (TopLine + ScreenLines)) THEN
      TopLine := ((CurrentLine - ScreenLines) DIV 2);
    IF (TopLine < 1) THEN
      TopLine := 1
    ELSE IF (TopLine >= MaxLines) THEN
      Dec(TopLine,ScrollSize DIV 2);
    Refresh_Screen;
  END;

  PROCEDURE Cursor_Up;
  BEGIN
    IF (CurrentLine > 1) THEN
      Dec(CurrentLine);
    IF (CurrentLine < TopLine) THEN
      Scroll_Screen(-ScrollSize)
    ELSE
      Reposition(FALSE);
  END;

  PROCEDURE Cursor_Down;
  BEGIN
    Inc(CurrentLine);
    IF (CurrentLine >= MaxLines) THEN
    BEGIN
      CurrentLine := MaxLines;
      IF (InportFileOpen) THEN
      BEGIN
        InportFileOpen := FALSE;
        Close(InportFile);
      END;
    END;
    IF ((CurrentLine - TopLine) >= ScreenLines) THEN
      Scroll_Screen(ScrollSize)
    ELSE
      Reposition(FALSE);
  END;

  PROCEDURE Cursor_EndLine;
  BEGIN
    CCol := (MaxLineLen + 1);  (* 78 or 79 chars, Test This *)
    Reposition(TRUE);
  END;

  PROCEDURE Cursor_StartLine;
  BEGIN
    CCol := 1;
    Reposition(TRUE);
  END;

  PROCEDURE Cursor_Left;
  BEGIN
    IF (CCol = 1) THEN
    BEGIN
      Cursor_Up;
      Cursor_EndLine;
    END
    ELSE
    BEGIN
      Dec(CCol);
      IF (NOT OkAvatar) THEN
        SerialOut(#27'[D')
      ELSE
        SerialOut(^V^E);
      GoToXY((WhereX - 1),WhereY);
    END;
  END;

  PROCEDURE Cursor_Right;
  BEGIN
    IF (CCol > CurLength) THEN
    BEGIN
      CCol := 1;
      Cursor_Down;
    END
    ELSE
    BEGIN
      OutKey(CurChar);
      Inc(CCol);
    END;
  END;

  PROCEDURE Cursor_WordRight;
  BEGIN
    IF (Delimiter) THEN
    BEGIN
      {skip blanks right}
      REPEAT
        Cursor_Right;
        IF (Line_Boundry) THEN
          Exit;
      UNTIL (NOT Delimiter);
    END
    ELSE
    BEGIN
      {find Next blank right}
      REPEAT
        Cursor_Right;
        IF (Line_Boundry) THEN
          Exit;
      UNTIL (Delimiter);
      {THEN move to a Word start (recursive)}
      Cursor_WordRight;
    END;
  END;

  PROCEDURE Cursor_WordLeft;
  BEGIN
    IF (Delimiter) THEN
    BEGIN
      {skip blanks left}
      REPEAT
        Cursor_Left;
        IF (Line_Boundry) THEN
          Exit;
      UNTIL (NOT Delimiter);
      {find Next blank left}
      REPEAT
        Cursor_Left;
        IF (Line_Boundry) THEN
          Exit;
      UNTIL (Delimiter);
      {move to start OF the Word}
      Cursor_Right;
    END
    ELSE
    BEGIN
      {find Next blank left}
      REPEAT
        Cursor_Left;
        IF (Line_Boundry) THEN
          Exit;
      UNTIL (Delimiter);
      {AND THEN move a Word left (recursive)}
      Cursor_WordLeft;
    END;
  END;

  PROCEDURE Delete_Line;
  {Delete the line at the cursor}
  VAR
    LineNum1: Integer;
  BEGIN
    FOR LineNum1 := CurrentLine TO (MaxLines - 1) DO
      LinePtr^[LineNum1] := LinePtr^[LineNum1 + 1];
    LinePtr^[MaxLines] := '';
    IF (CurrentLine <= TotalLines) AND (TotalLines > 1) THEN
      Dec(TotalLines);
  END;

  PROCEDURE Insert_Line(CONST Contents: AStr);
  {open a new line at the cursor}
  VAR
    LineNum1: Integer;
  BEGIN
    FOR LineNum1 := MaxLines DOWNTO (CurrentLine + 1) DO
      LinePtr^[LineNum1] := LinePtr^[LineNum1 - 1];
    LinePtr^[CurrentLine] := Contents;
    IF (CurrentLine < TotalLines) THEN
      Inc(TotalLines);
    IF (CurrentLine > TotalLines) THEN
      TotalLines := CurrentLine;
  END;

  PROCEDURE Reformat_Paragraph;
  BEGIN
    Remove_Trailing;
    CCol := CurLength;
    {FOR each line OF the paragraph}
    WHILE (CurChar <> ' ') DO
    BEGIN
      {FOR each Word OF the current line}
      REPEAT
        {determine Length OF first Word on the following line}
        Inc(CurrentLine);
        Remove_Trailing;
        CCol := 1;
        WHILE (CurChar <> ' ') DO
          Inc(CCol);
        Dec(CurrentLine);
        {hoist a Word From the following line IF it will fit}
        IF (CCol > 1) AND ((CCol + CurLength) < MaxLineLen) THEN
        BEGIN
          IF (CurLength > 0) THEN
          BEGIN
            {add a second space after sentences}
            CASE LastChar OF
              '.', '?', '!':
                    Append_Space;
            END;
            Append_Space;
          END;
          LinePtr^[CurrentLine] := LinePtr^[CurrentLine] + Copy(LinePtr^[CurrentLine + 1],1,(CCol - 1));
          {remove the hoisted Word}
          Inc(CurrentLine);
          WHILE (CurChar = ' ') AND (CCol <= CurLength) DO
            Inc(CCol);
          Delete(LinePtr^[CurrentLine],1,(CCol - 1));
          IF (CurLength = 0) THEN
            Delete_Line;
          Dec(CurrentLine);
        END
        ELSE
          CCol := 0;  {END OF line}
      UNTIL (CCol = 0);
      {no more lines will fit - either time FOR Next line, OR END OF paragraph}
      Inc(CurrentLine);
      CCol := 1;
      Remove_Trailing;
    END;
  END;

  PROCEDURE Word_Wrap;
  {line is full AND a character must be inserted.  perform Word-wrap,
   updating screen AND leave ready FOR the insertion}
  VAR
    TempStr1: AStr;
    PCol,
    PLine: Integer;
  BEGIN
    Remove_Trailing;
    PLine := CurrentLine;
    PCol := CCol;
    {find start OF Word to wrap}
    CCol := CurLength;
    WHILE (CCol > 0) AND (CurChar <> ' ') DO
      Dec(CCol);
    {cancel wrap IF no spaces IN whole line}
    IF (CCol = 0) THEN
    BEGIN
      CCol := 1;
      Cursor_Down;
      Exit;
    END;
    {get the portion to be moved down}
    Inc(CCol);
    TempStr1 := Copy(LinePtr^[CurrentLine],CCol,MaxLineLen);
    {remove it From current line AND refresh screen}
    Truncate_Line;
    {place Text on open a new line following the cursor}
    Inc(CurrentLine);
    Insert_Line(TempStr1);
    {join the wrapped Text WITH the following lines OF Text}
    Reformat_Paragraph;
    {restore cursor to proper position after the wrap}
    CurrentLine := PLine;
    IF (PCol > CurLength) THEN
    BEGIN
      CCol := (PCol - CurLength);   {position cursor after wrapped Word}
      Inc(CurrentLine); {Cursor_Down;}
    END
    ELSE
      CCol := PCol;               {restore original cursor position}
    IF ((CurrentLine - TopLine) >= ScreenLines) THEN
      Scroll_Screen(ScrollSize)
    ELSE
      Refresh_Screen;
  END;

  PROCEDURE Join_Lines;
  {join the current line WITH the following line, IF possible}
  BEGIN
    Inc(CurrentLine);
    Remove_Trailing;
    Dec(CurrentLine);
    Remove_Trailing;
    IF ((CurLength + Length(LinePtr^[CurrentLine + 1])) >= MaxLineLen) THEN
      Exit;
    IF (LastChar <> ' ') THEN
      Append_Space;
    LinePtr^[CurrentLine] := LinePtr^[CurrentLine]+LinePtr^[CurrentLine + 1];
    Inc(CurrentLine);
    Delete_Line;
    Dec(CurrentLine);
    Refresh_Screen;
  END;

  PROCEDURE Split_Line;
  {splits the current line at the cursor, leaves cursor IN original position}
  VAR
    TempStr1: AStr;
    PCol: Integer;
  BEGIN
    PCol := CCol;
    Remove_Trailing;                      {get the portion FOR the Next line}
    TempStr1 := Copy(LinePtr^[CurrentLine],CCol,MaxLineLen);
    Truncate_Line;
    CCol := 1;                             {open a blank line}
    Inc(CurrentLine);
    Insert_Line(TempStr1);
    IF ((CurrentLine - TopLine) > (ScreenLines - 2)) THEN
      Scroll_Screen(ScrollSize)
    ELSE
      Refresh_Screen;
    Dec(CurrentLine);
    CCol := PCol;
  END;

  PROCEDURE Cursor_NewLine;
  BEGIN
    IF (Insert_Mode) THEN
      Split_Line;
    CCol := 1;
    Cursor_Down;
  END;

  PROCEDURE Reformat;
  {reformat paragraph, update display}
  VAR
    PLine: Integer;
  BEGIN
    PLine := CurrentLine;
    Reformat_Paragraph;
    {find start OF Next paragraph}
    WHILE (CurLength = 0) AND (CurrentLine <= TotalLines) DO
      Inc(CurrentLine);
    {find top OF screen FOR Redisplay}
    WHILE ((CurrentLine - TopLine) > (ScreenLines - 2)) DO
    BEGIN
      Inc(TopLine,ScrollSize);
      PLine := TopLine;
    END;
    Refresh_Screen;
  END;

  PROCEDURE Insert_Char(C1: Char);
  BEGIN
    IF (CCol < CurLength) THEN
    BEGIN
      Remove_Trailing;
      IF (CCol > CurLength) THEN
        Reposition(TRUE);
    END;
    IF (Insert_Mode AND (CurLength >= MaxLineLen)) OR (CCol > MaxLineLen) THEN
    BEGIN
      IF (CCol <= MaxLineLen) THEN
        Word_Wrap
      ELSE IF (C1 = ' ') THEN
      BEGIN
        Cursor_NewLine;
        Exit;
      END
      ELSE IF (LastChar = ' ') THEN
        Cursor_NewLine   {nonspace w/space at END-line is newline}
      ELSE
        Word_Wrap;                      {otherwise wrap Word down AND continue}
    END;
    {Insert character into the middle OF a line}
    IF (Insert_Mode) AND (CCol <= CurLength) THEN
    BEGIN
      Insert(C1,LinePtr^[CurrentLine],CCol);
      {update display line following cursor}
      MCIAllowed := FALSE;
      ColorAllowed := FALSE;
      AllowAbort := FALSE;
      PrintMain(Copy(LinePtr^[CurrentLine],CCol,MaxLineLen));
      MCIAllowed := TRUE;
      ColorAllowed := TRUE;
      AllowAbort := TRUE;
      {position cursor FOR Next insertion}
      Inc(CCol);
      Reposition(TRUE);
    END
    ELSE
    BEGIN {append a character to the END OF a line}
      WHILE (CurLength < CCol) DO
        Append_Space;
      LinePtr^[CurrentLine][CCol] := C1;
      {advance the cursor, updating the display}
      Cursor_Right;
    END;
    Set_PhyLine;
  END;

  PROCEDURE Delete_Char;
  BEGIN
    {Delete whole line IF it is empty}
    IF (CCol > CurLength) AND (CurLength > 0) THEN
      Join_Lines
    ELSE IF (CCol <= CurLength) THEN
    BEGIN {Delete IN the middle OF a line}
      Delete(LinePtr^[CurrentLine],CCol,1);
      MCIAllowed := FALSE;
      ColorAllowed := FALSE;
      AllowAbort := FALSE;
      PrintMain(Copy(LinePtr^[CurrentLine],CCol,MaxLineLen)+' ');
      MCIAllowed := TRUE;
      ColorAllowed := TRUE;
      AllowAbort := TRUE;
      Reposition(TRUE);
      Set_PhyLine;
    END;
  END;

  PROCEDURE Delete_WordRight;
  BEGIN
    IF (CurChar = ' ') THEN
      REPEAT   {skip blanks right}
        Delete_Char;
      UNTIL (CurChar <> ' ') OR (CCol > CurLength)
    ELSE
    BEGIN
      REPEAT   {find Next blank right}
        Delete_Char;
      UNTIL (Delimiter);
      Delete_Char;
    END;
  END;

  PROCEDURE Page_Down;
  BEGIN
    IF ((TopLine + ScreenLines) < MaxLines) THEN
    BEGIN
      Inc(CurrentLine,ScrollSize);
      Scroll_Screen(ScrollSize);
    END;
  END;

  PROCEDURE Page_Up;
  BEGIN
    IF (TopLine > 1) THEN
    BEGIN
      Dec(CurrentLine,ScrollSize);
      IF (CurrentLine < 1) THEN
        CurrentLine := 1;
      Scroll_Screen(-ScrollSize);
    END
    ELSE
    BEGIN
      CurrentLine := 1;
      CCol := 1;
      Scroll_Screen(0);
    END;
  END;

  PROCEDURE FS_Delete_Line;
  {Delete the line at the cursor, update display}
  BEGIN
    Delete_Line;
    Refresh_Screen;
  END;

  PROCEDURE Display_Insert_Status;
  BEGIN
    ANSIG(69,1);
    Prompt('^1(Mode: ');
    IF (Insert_Mode) THEN
      Prompt('INS)')
    ELSE
      Prompt('OVR)');
  END;

  PROCEDURE Prepare_Screen;
  VAR
    Counter: Integer;
  BEGIN
    CLS;
    ANSIG(1,1);
    IF (TimeWarn) THEN
      Prompt(^G^G'          |12Warning: |10You have less than '+IntToStr(NSL DIV 60 + 1)+' '+
             Plural('minute',NSL DIV 60 + 1)+' remaining online!')
    ELSE
    BEGIN
      Prompt('^1(Ctrl-Z = Help)  ^5To:^1 '+PadLeftStr(MsgTo,20)+' ^5Subj: ^1');
      IF (MHeader.FileAttached = 0) THEN
        Print(PadLeftStr(MsgSubj,20))
      ELSE
        Print(PadLeftStr(StripName(MsgSubj),20));
      Display_Insert_Status;
    END;
    ANSIG(1,2);
    DoLines;
    FOR Counter := 1 TO ScreenLines DO  {physical lines are now invalid}
      PhyLine[Counter] := '';
    Scroll_Screen(0); {causes Redisplay}
  END;

  PROCEDURE Redisplay;
  BEGIN
    TopLine := ((CurrentLine - ScreenLines) DIV 2);
    Prepare_Screen;
  END;

  PROCEDURE FS_Help;
  BEGIN
    CLS;
    PrintF('FSHELP');
    PauseScr(FALSE);
    Prepare_Screen;
  END;

  PROCEDURE DoQuote(RedrawScreen: Boolean);
  VAR
    QuoteFile: Text;
    TempStr1: AStr;
    Fline,
    Nline,
    QuoteLi: Integer;
    Done: Boolean;

    PROCEDURE GetOut(x: Boolean);
    BEGIN
      IF (x) THEN
        Close(QuoteFile);
      IF (InvisEdit) AND (RedrawScreen) THEN
        Prepare_Screen;
      MCIAllowed := TRUE;
    END;

  BEGIN
    Assign(QuoteFile,'TEMPQ'+IntToStr(ThisNode));
    Reset(QuoteFile);
    IF (IOResult <> 0) THEN
      Exit;
    IF (MaxQuoteLines = 0) THEN
    BEGIN
      WHILE NOT EOF(QuoteFile) DO
      BEGIN
        ReadLn(QuoteFile,TempStr1);
        Inc(MaxQuoteLines);
      END;
      Close(QuoteFile);
      Reset(QuoteFile);
    END;

    MCIAllowed := FALSE;
    Done := FALSE;

    REPEAT
      Abort := FALSE;
      Next := FALSE;
      CLS;
      QuoteLi := 0;
      IF (LastQuoteLine > 0) THEN
        WHILE NOT EOF(QuoteFile) AND (QuoteLi < LastQuoteLine) DO
        BEGIN
          ReadLn(QuoteFile,TempStr1);
          Inc(QuoteLi);
        END;
      IF EOF(QuoteFile) THEN
      BEGIN
        LastQuoteLine := 0;
        QuoteLi := 0;
        Reset(QuoteFile);
      END;
      WHILE (NOT EOF(QuoteFile)) AND ((QuoteLi - LastQuoteLine) < (PageLength - 4)) DO
      BEGIN
        ReadLn(QuoteFile,TempStr1);
        Inc(QuoteLi);
        TempStr1 := Copy(PadRightInt(QuoteLi,Length(IntToStr(MaxQuoteLines)))+':'+TempStr1,1,MaxLineLen);
        PrintACR('^3'+TempStr1);
      END;
      Close(QuoteFile);
      Reset(QuoteFile);
      REPEAT
        NL;
        Prt('First line to quote [^5?^4=^5Help^4]: ');
        Scaninput(TempStr1,'HQ?'^M);
        IF (TempStr1 = '?') THEN
        BEGIN
          NL;
          Print('^1<^3Q^1>uit, <^3H^1>eader, <^3?^1>Help, or first line to quote.');
        END
        ELSE IF (TempStr1 = 'H') THEN
        BEGIN
          WHILE (TempStr1 > '') AND (NOT EOF(QuoteFile)) AND (CurrentLine <= MaxLines) DO
          BEGIN
            ReadLn(QuoteFile,TempStr1);
            IF (InvisEdit) THEN
              Insert_Line(TempStr1)
            ELSE
            BEGIN
              LinePtr^[TotalLines] := TempStr1;
              Inc(TotalLines);
            END;
            Inc(CurrentLine);
          END;
          Close(QuoteFile);
          Reset(QuoteFile);
          TempStr1 := 'H';
        END;
      UNTIL ((TempStr1 <> '?') AND (TempStr1 <> 'H')) OR (HangUp);
      Fline := StrToInt(TempStr1);
      IF (Fline <= 0) THEN
        LastQuoteLine := QuoteLi;
      IF (TempStr1 = 'Q') THEN
        Done := TRUE;
      IF (Fline > MaxQuoteLines) OR (HangUp) THEN
      BEGIN
        GetOut(TRUE);
        Exit;
      END;
      IF (Fline > 0) THEN
      BEGIN
        Prt('Last line to quote: ');
        Scaninput(TempStr1,'Q'^M);
        IF (TempStr1 <> #13) THEN
          Nline := StrToInt(TempStr1)
        ELSE
          Nline := Fline;
        IF (Nline < Fline) OR (Nline > MaxQuoteLines) THEN
        BEGIN
          GetOut(TRUE);
          Exit;
        END;
        Nline := ((Nline - Fline) + 1);
        WHILE (NOT EOF(QuoteFile)) AND (Fline > 1) DO
        BEGIN
          Dec(Fline);
          ReadLn(QuoteFile,TempStr1);
        END;
        IF (NOT InvisEdit) THEN
          CurrentLine := TotalLines;
        WHILE (NOT EOF(QuoteFile)) AND (Nline > 0) AND (CurrentLine <= MaxLines) DO
        BEGIN
          Dec(Nline);
          ReadLn(QuoteFile,TempStr1);
          IF (InvisEdit) THEN
            Insert_Line(TempStr1)
          ELSE
          BEGIN
            LinePtr^[TotalLines] := TempStr1;
            Inc(TotalLines);
          END;
          Inc(CurrentLine);
        END;
        Done := TRUE;
      END;
    UNTIL (Done) OR (HangUp);
    GetOut(TRUE);
    LastError := IOResult;
  END;

  PROCEDURE FS_Editor;
  VAR
    GKey: Word;
    SaveTimeWarn: Boolean;
  BEGIN
    InvisEdit := TRUE;
    Insert_Mode := TRUE;
    SaveTimeWarn := TimeWarn;
    Count_Lines;
    IF (TotalLines > 0) THEN
      CurrentLine := (TotalLines + 1)
    ELSE
      CurrentLine := 1;
    CCol := 1;
    TopLine := 1;
    ScreenLines := (PageLength - 4);
    IF (ScreenLines > 20) THEN
      ScreenLines := 20;
    WHILE (CurrentLine - TopLine) > (ScrollSize + 3) DO
      Inc(TopLine,ScrollSize);
    Prepare_Screen;
    REPEAT
      IF ((InportFileOpen) AND (Buf = '')) THEN
        IF (NOT EOF(InportFile)) THEN
        BEGIN
          ReadLn(InportFile,Buf);
          Buf := Buf + ^M
        END
        ELSE
        BEGIN
          Close(InportFile);
          InportFileOpen := FALSE;
        END;
      IF (TimeWarn) AND (NOT SaveTimeWarn) THEN
      BEGIN
        ANSIG(1,1);
        Prompt(^G^G'               |12Warning: |10You have '+IntToStr(NSL DIV 60)+' minute(s) remaining online!');
        ANSIG(CCol,((CurrentLine - TopLine) + TopScreen));
        SaveTimeWarn := TRUE;
      END;
      GKey := GetKey;
      CASE GKey OF
         47 :
             IF (CCol = 1) AND (NOT InportFileOpen) THEN
               GKey := 27
             ELSE
               Insert_Char(Char(GKey));
         127 :
             Delete_Char;
         32..46, 48..126, 128..254 :
             Insert_Char(Char(GKey));
         8 : BEGIN
               IF (CCol = 1) THEN
               BEGIN
                 Cursor_Left;
                 Join_Lines;
               END
               ELSE
               BEGIN
                 Cursor_Left;
                 Delete_Char;
               END;
             END;
         F_CTRLLEFT,1 :
             Cursor_WordLeft;  { ^A }
         2 : Reformat;      { ^B }
         F_PGDN,3 :
             Page_Down;        { ^C }
         F_RIGHT,4 :
             Cursor_Right;     { ^D }
         F_UP,5 :
             Cursor_Up;        { ^E }
         F_CTRLRIGHT,6 :
             Cursor_WordRight; { ^F }
         F_DEL,7 :
             Delete_Char;      { ^G }
         9 : REPEAT
               Insert_Char(' ');
             UNTIL ((CCol MOD 5) = 0);  { ^I }
         10 :
             Join_Lines;       { ^J }
         F_END,11 :
             Cursor_EndLine;   { ^K }
         12 :
             Redisplay;        { ^L }
         13 :
             Cursor_NewLine;   { ^M }
         14 :
             BEGIN
               Split_Line;
               Reposition(TRUE);
             END;              { ^N }
         16 :
             BEGIN             { ^P }
               GKey := GetKey;
               IF (GKey IN [0..9,Ord('0')..Ord('9')]) THEN
               BEGIN
                 Insert_Char('^');
                 Insert_Char(Char(GKey));
               END
               ELSE
                 Buf := Char(GKey);
               GKey := 0;
             END;
         17 :
             DoQuote(TRUE);   { ^Q }
         F_PGUP,18 :
             Page_Up;         { ^R }
         F_LEFT,19 :
             Cursor_Left;     { ^S }
         20 :
             Delete_WordRight;{ ^T }
         F_INS,22 :
             BEGIN            { ^V }
               Insert_Mode := NOT Insert_Mode;
               Display_Insert_Status;
               Reposition(TRUE);
             END;
         F_HOME,23 :
             Cursor_StartLine; { ^W }
         F_DOWN,24 :
             Cursor_Down;      { ^X }
         25 :
             FS_Delete_Line;   { ^Y }
         26 :
             FS_Help;          { ^Z }
      END;
    UNTIL ((GKey = 27) AND (NOT InportFileOpen)) OR (HangUp);
    IF (InportFileOpen) THEN
    BEGIN
      Close(InportFile);
      InportFileOpen := FALSE;
    END;
    Count_Lines;
    InvisEdit := FALSE;
  END;

  PROCEDURE PrintMsgTitle;
  BEGIN
    NL;
    (*
    Print(FString.lentermsg1);
    *)
    lRGLngStr(6,FALSE);
    (*
    Print(FString.lentermsg2);
    *)
    lRGLNGStr(7,FALSE);
    DoLines;
  END;

  PROCEDURE InputTheMessage(CantAbort1: Boolean; VAR DisableMCI1,SaveMsg1: Boolean);
  VAR
    LineStr,
    TempStr1,
    TempStr2,
    TempStr3: AStr;
    SaveMsgSubj: Str40;
    Cmd,
    Drive: Char;
    SaveFileAttached,
    HelpCounter: Byte;
    Counter,
    LineNum1,
    LineNum2: SmallInt;
    ShowCont,
    ExitMsg,
    SaveLine,
    AbortMsg: Boolean;

    PROCEDURE EditMsgTo(VAR MsgTo1: Str36);
    VAR
      User: UserRecordType;
      TempMsgTo: Str36;
      UNum: Integer;
    BEGIN
      { Print(FString.default + ^M^J); }
      lRGLngStr(34,FALSE);
      IF (Pub) AND (NOT (MAInternet IN MemMsgArea.MAFlags)) THEN
      BEGIN
        Prt('To: ');
        IF (MsgTo1 <> '') THEN
          InputDefault(TempMsgTo,MsgTo1,36,[NoLineFeed,CapWords],FALSE)
        ELSE
        BEGIN
          MPL(36);
          InputMain(TempMsgTo,36,[NoLineFeed,CapWords]);
        END;
        MsgTo1 := TempMsgTo;
        UserColor(6);
        FOR UNum := 1 TO LennMCI(MsgTo1) DO
          BackSpace;
        UNum := StrToInt(MsgTo1);
        IF (UNum >= 1) AND (UNum <= (MaxUsers - 1)) AND NOT (NetMail IN MHeader.Status) THEN
        BEGIN
          LoadURec(User,UNum);
          MsgTo1 := Caps(User.Name);
          MHeader.MTO.UserNum := UNum;
          MHeader.MTO.Real := User.RealName;
          IF (Pub) AND (MARealName IN MemMsgArea.MAFlags) THEN
            MsgTo1 := Caps(User.RealName)
          ELSE
            MsgTo1 := Caps(User.Name);
        END;
        IF (SQOutSp(MsgTo1) = '') THEN
           MsgTo1 := 'All';
        IF (MsgTo1 <> '') THEN
        BEGIN
          Prompt(MsgTo1);
          UserColor(1);
          NL;
        END;
      END
      ELSE IF (NOT (MAInternet IN MemMsgArea.MAFlags)) THEN
        Print(PadLeftStr('^4To: ^6'+Caps(MsgTo1),40));
    END;

    PROCEDURE EditMsgSubj(VAR MsgSubj1: Str40; CantAbort2: Boolean);
    VAR
      TempMsgSubj: Str40;
    BEGIN
      IF (MHeader.FileAttached = 0) AND (NOT CantAbort2) THEN
      BEGIN
        Prt('Subject: ');
        IF (MsgSubj1 <> '') THEN
          InputDefault(TempMsgSubj,MsgSubj1,40,[NoLineFeed],FALSE)
        ELSE
        BEGIN
          MPL(40);
          InputMain(TempMsgSubj,40,[NoLineFeed]);
        END;
        IF (TempMsgSubj <> '') THEN
          MsgSubj1 := TempMsgSubj
        ELSE
        BEGIN
          IF (MsgSubj1 <> '') THEN
            Prompt('^6'+MsgSubj1+'^1');
        END;
        NL;
      END
      ELSE
        MsgSubj1 := MHeader.Subject;
      UserColor(1);
    END;

    PROCEDURE FileAttach(VAR ExitMsg1: Boolean);
    VAR
      FileName: Str40;
      DOk,
      KAbort,
      AddBatch: Boolean;
      TransferTime: LongInt;
    BEGIN
      NL;
      Prt('File name: ');
      MPL(40);
      Input(FileName,40);
      NL;
      IF (NOT CoSysOp) OR (NOT IsUL(FileName)) THEN
        FileName := General.FileAttachPath+StripName(FileName);
      IF (NOT Exist(FileName)) AND (NOT InCom) AND (NOT Exist(FileName)) AND (FileName <> '') THEN
      BEGIN
        Print('^7That file does not exist!^1');
        ExitMsg1 := FALSE;
      END
      ELSE
      BEGIN
        IF Exist(FileName) AND (NOT CoSysOp) THEN
        BEGIN
          Print('^7You cannot use that file name!^1');
          ExitMsg1 := FALSE;
        END
        ELSE
        BEGIN
          IF (NOT Exist(FileName)) AND (InCom) THEN
          BEGIN
            Receive(FileName,TempDir+'\UP',FALSE,DOk,KAbort,AddBatch,TransferTime);
            MHeader.FileAttached := 1;
          END
          ELSE IF Exist(FileName) THEN
          BEGIN
            DOk := TRUE;
            MHeader.FileAttached := 2;
          END;
          IF (DOk) THEN
          BEGIN
            MsgSubj := FileName;
            IF (CoSysOp) AND (NOT (NetMail IN MHeader.Status)) THEN
            BEGIN
              IF PYNQ('Delete file upon receipt? ',0,FALSE) THEN
                MHeader.FileAttached := 1
              ELSE
                MHeader.FileAttached := 2
            END
            ELSE
              MHeader.FileAttached := 1;
          END
          ELSE
            MHeader.FileAttached := 0;
        END;
      END;
      UserColor(1);
    END;

    PROCEDURE ListMsg(LineNum1: Integer; DisplayLineNum: Boolean; VAR SaveLine: Boolean);
    BEGIN
      MCIAllowed := FALSE;
      AllowContinue := TRUE;
      DOSANSIOn := FALSE;
      Abort := FALSE;
      Next := FALSE;
      NL;
      WHILE ((LineNum1 <= (TotalLines - 1)) AND (NOT Abort) AND (NOT HangUp)) DO
      BEGIN
        IF (DisplayLineNum) THEN
          Print('^3'+IntToStr(LineNum1)+':');
        Reading_A_Msg := TRUE;
        IF (NOT DOSANSIOn) THEN
          IF (Pos('>',Copy(LinePtr^[LineNum1],1,4)) > 0) THEN
            UserColor(3)
          ELSE
            UserColor(1);
        PrintACR(LinePtr^[LineNum1]);
        Reading_A_Msg := FALSE;
        Inc(LineNum1);
      END;
      IF (DisplayLineNum) THEN
      BEGIN
        NL;
        Print('  ^7** ^3'+IntToStr(TotalLines - 1)+' '+(Plural('line',(TotalLines - 1))+' ^7**'));
      END;
      MCIAllowed := TRUE;
      AllowContinue := FALSE;
      DOSANSIOn := FALSE;
      SaveLine := FALSE;
      UserColor(1);
    END;

    PROCEDURE UploadFile;
    VAR
      TempStr1: AStr;
      DOk,
      KAbort,
      AddBatch: Boolean;
      TransferTime: LongInt;
    BEGIN
      NL;
      TempStr1 := '';
      IF (CoSysOp) THEN
      BEGIN
        Prt('Enter file to import [Enter=Upload]: ');
        MPL(40);
        Input(TempStr1,40);
      END;
      IF (TempStr1 = '') THEN
      BEGIN
        TempStr1 := 'TEMPMSG.'+IntToStr(ThisNode);
        IF Exist(TempStr1) THEN
          Kill(TempStr1);
      END;
      IF (NOT Exist(TempStr1)) AND (InCom) THEN
      BEGIN
        Receive(TempStr1,TempDir+'UP\',FALSE,DOk,KAbort,AddBatch,TransferTime);
        TempStr1 := TempDir+'UP\'+TempStr1;
      END;
      IF ((TempStr1 <> '') AND (NOT HangUp)) THEN
      BEGIN
        Assign(InportFile,TempStr1);
        Reset(InportFile);
        IF (IOResult = 0) THEN
          InportFileOpen := TRUE;
      END;
      UserColor(1);
    END;

  BEGIN
    FillChar(LinePtr^,(MaxLines * 121),0);
    Abort := FALSE;
    Next := FALSE;
    AbortMsg := FALSE;
    SaveMsg1 := FALSE;
    DisableMCI1 := FALSE;
    TotalLines := 1;
    LastLineStr := '';

    IF (NOT CheckDriveSpace('Message posting',General.MsgPath,General.MinSpaceForPost)) THEN
      MsgSubj := ''
    ELSE
    BEGIN
      IF (ReadInMsg <> '') THEN
      BEGIN
        Assign(InportFile,ReadInMsg);
        Reset(InportFile);
        IF (IOResult = 0) THEN
        BEGIN
          WHILE (NOT EOF(InportFile)) AND ((TotalLines - 1) <= MaxLines) DO
          BEGIN
            ReadLn(InportFile,LinePtr^[TotalLines]);
            Inc(TotalLines);
          END;
          Close(InportFile);
        END;
      END
      ELSE
      BEGIN
        EditMsgTo(MsgTo);
        NL;
        EditMsgSubj(MsgSubj,CantAbort1);
      END;
    END;

    IF (MsgSubj = '') THEN
      IF (NOT CantAbort1) THEN
      BEGIN
        SaveMsg1 := FALSE;
        NL;
        Print('Aborted!');
        Exit;
      END;

    IF (FSEditor IN ThisUser.SFlags) THEN
    BEGIN
      REPEAT
        FS_Editor;
        REPEAT
          ExitMsg := TRUE;
          NL;
          Prt('Full screen editor (^5?^4=^5Help^4): ');
          OneK(Cmd,^M'ACFMQSTU?',TRUE,TRUE);
          NL;
          CASE Cmd OF
            'A' : IF (CantAbort1) THEN
                  BEGIN
                    Print('^7You can not abort this message!^1');
                    ExitMsg := FALSE;
                  END
                  ELSE IF PYNQ('Abort message? ',0,FALSE) THEN
                  BEGIN
                    AbortMsg := TRUE;
                    SaveMsg1 := FALSE;
                    NL;
                    Print('Aborted!');
                  END;
            'C' : IF (TotalLines = 0) THEN
                  BEGIN
                    Print('^7Nothing to clear!^1');
                    ExitMsg := FALSE;
                  END
                  ELSE IF PYNQ('Clear message? ',0,FALSE) THEN
                    FOR LineNum1 := 1 TO TotalLines DO
                      LinePtr^[LineNum1][0] := #0;
            'F' : IF (NOT AACS(General.FileAttachACS)) THEN
                  BEGIN
                    Print('^7You do not have access to this command!^1');
                    ExitMsg := FALSE;
                  END
                  ELSE IF (CantAbort1) THEN
                  BEGIN
                    Print('^7You can not attach a file to this message!^1');
                    ExitMsg := FALSE;
                  END
                  ELSE IF (MHeader.FileAttached > 0) THEN
                  BEGIN
                    Print('File attached: ^5'+StripName(MsgSubj));
                    NL;
                    IF (PYNQ('Replace the attached file? ',0,FALSE)) THEN
                      FileAttach(ExitMsg)
                    ELSE
                    BEGIN
                      NL;
                      IF (PYNQ('Remove the attached file? ',0,FALSE)) THEN
                      BEGIN
                        SaveFileAttached := MHeader.FileAttached;
                        SaveMsgSubj := MsgSubj;
                        MHeader.FileAttached := 0;
                        MsgSubj := '';
                        NL;
                        EditMsgSubj(MsgSubj,CantAbort1);
                        IF (MsgSubj = '') THEN
                        BEGIN
                          MsgSubj := SaveMsgSubj;
                          MHeader.FileAttached := SaveFileAttached;
                          NL;
                          Print('Aborted!');
                        END;
                      END;
                    END;
                  END
                  ELSE IF PYNQ('Attach a file to this message? ',0,FALSE) THEN
                    FileAttach(ExitMsg);
            'M' : IF (NOT AACS(MemMsgArea.MCIACS)) THEN
                  BEGIN
                    Print('^7You do not have access to this command!^1');
                    ExitMsg := FALSE;
                  END
                  ELSE
                    DisableMCI1 := PYNQ('Disable MCI Codes for this message ['+SQOutSp(ShowYesNo(DisableMCI1))+']? ',0,FALSE);
            'Q' : IF (NOT Exist('TEMPQ'+IntToStr(ThisNode))) THEN
                  BEGIN
                    Print('^7You are not replying to a message!^1');
                    ExitMsg := FALSE;
                  END
                  ELSE IF ((TotalLines + 1) = MaxLines) THEN
                  BEGIN
                    Print('^7You have reached the maximum line limit!^1');
                    ExitMsg := FALSE;
                  END
                  ELSE
                  BEGIN
                    InvisEdit := TRUE;
                    DoQuote(FALSE);
                    InvisEdit := FALSE;
                  END;
            'S' : BEGIN
                    FOR Counter := TotalLines DOWNTO 1 DO
                    BEGIN
                      LineNum2 := 0;
                      FOR LineNum1 := 1 TO Length(LinePtr^[Counter]) DO
                        IF (LinePtr^[Counter][LineNum1] <> ' ') THEN
                          Inc(LineNum2);
                      IF (LineNum2 = 0) THEN
                      BEGIN
                        LinePtr^[Counter][0] := #0;
                        Dec(TotalLines)
                      END
                      ELSE
                        Counter := 1;
                    END;
                    IF (CantAbort1) AND (TotalLines = 0) THEN
                    BEGIN
                      Print('^7You must complete this message!^1');
                      ExitMsg := FALSE;
                    END
                    ELSE IF (TotalLines = 0) THEN
                    BEGIN
                      Print('^7Nothing to save!^1');
                      ExitMsg := FALSE;
                    END
                    ELSE
                    BEGIN
                      SaveMsg1 := TRUE;
                      AbortMsg := FALSE;
                      Inc(TotalLines);
                    END;
                  END;
            'T' : IF (CantAbort1) THEN
                  BEGIN
                    Print('^7The receiver and subject can not be changed!^1');
                    ExitMsg := FALSE;
                  END
                  ELSE
                  BEGIN
                    IF (NOT Pub) OR (MAInternet IN MemMsgArea.MAFlags) THEN
                    BEGIN
                      Print('^7The receiver of this message can not be changed!');
                      ExitMsg := FALSE;
                    END
                    ELSE
                      EditMsgTo(MsgTo);
                    NL;
                    IF (MHeader.FileAttached > 0) THEN
                    BEGIN
                      Print('^7The subject of this message can not be changed!');
                      ExitMsg := FALSE;
                    END
                    ELSE
                      EditMsgSubj(MsgSubj,CantAbort1);
                  END;
            'U' : IF ((TotalLines + 1) = MaxLines) THEN
                  BEGIN
                    Print('^7You have reached the maximum line limit!^1');
                    ExitMsg := FALSE;
                  END
                  ELSE IF PYNQ('Import a file to this message? ',0,FALSE) THEN
                    UploadFile;
            ^M  : ExitMsg := TRUE;
            '?' : BEGIN
                    PrintF('FSHELP');
                    ExitMsg := FALSE;
                  END;
          END;
        UNTIL (AbortMsg) OR (ExitMsg) OR (SaveMsg1) OR (HangUp);
      UNTIL ((AbortMsg) OR (SaveMsg1) OR (HangUp));
    END
    ELSE
    BEGIN
      PrintMsgTitle;
      HelpCounter := 1;
      REPEAT
        SaveLine := TRUE;
        ExitMsg := TRUE;
        InputLine(LineStr,MaxLineLen);
        REPEAT
          IF (LineStr = '/'^H) THEN
          BEGIN
            SaveLine := FALSE;
            IF ((TotalLines - 1) >= 1) THEN
            BEGIN
              Dec(TotalLines);
              LastLineStr := LinePtr^[TotalLines];
              IF (LastLineStr[Length(LastLineStr)] = #1) THEN
                LastLineStr := Copy(LastLineStr,1,(Length(LastLineStr) - 1));
              NL;
              Print('^3Backed up to line '+IntToStr(TotalLines)+':^1');
            END;
          END;
          IF (LineStr = '/') AND (NOT (InportFileOpen)) THEN
          BEGIN
            SaveLine := FALSE;
            ShowCont := TRUE;
            NL;
            Prt('Line editor (^5?^4=^5Help^4): ');
            OneK(Cmd,^M'ACDFILMOPQRSTUZ?',TRUE,TRUE);
            IF (Cmd <> ^M) THEN
              NL;
            CASE Cmd OF
              'A' : IF (CantAbort1) THEN
                      Print('^7You can not abort this message!^1')
                    ELSE IF PYNQ('Abort message? ',0,FALSE) THEN
                    BEGIN
                      AbortMsg := TRUE;
                      SaveMsg1 := FALSE;
                      ShowCont := FALSE;
                      NL;
                      Print('Aborted!');
                    END;
              'C' : IF ((TotalLines - 1) < 1) THEN
                      Print('^7Nothing to clear!^1')
                    ELSE IF PYNQ('Clear message? ',0,FALSE) THEN
                    BEGIN
                      IF ((TotalLines - 1) = MaxLines) THEN
                        ExitMsg := TRUE;
                      FOR LineNum1 := 1 TO (TotalLines - 1) DO
                        LinePtr^[LineNum1][0] := #0;
                      TotalLines := 1;
                      Escp := FALSE;
                      ShowCont := FALSE;
                      NL;
                      Print('^0Message cleared ... Start over ...^1');
                      NL;
                    END;
              'D' : IF ((TotalLines - 1) < 1) THEN
                      Print('^7No lines to delete!^1')
                    ELSE
                    BEGIN
                      LineNum1 := -1;
                      InputIntegerWOC('Delete which line',LineNum1,[NumbersOnly],1,(TotalLines - 1));
                      IF (LineNum1 >= 1) AND (LineNum1 <= (TotalLines - 1)) THEN
                      BEGIN
                        Abort := FALSE;
                        Next := FALSE;
                        NL;
                        Print('^3Line '+IntToStr(LineNum1)+':');
                        MCIAllowed := FALSE;
                        PrintAcr('^1'+LinePtr^[LineNum1]);
                        MCIAllowed := TRUE;
                        NL;
                        IF (PYNQ('Delete this line? ',0,FALSE)) THEN
                        BEGIN
                          IF ((TotalLines - 1) = MaxLines) THEN
                            ExitMsg := TRUE;
                          FOR LineNum2 := LineNum1 TO (TotalLines - 2) DO
                            LinePtr^[LineNum2] := LinePtr^[LineNum2 + 1];
                          Dec(TotalLines);
                          NL;
                          Print('^0Line '+IntToStr(LineNum1)+' deleted.^1');
                        END;
                      END;
                    END;
              'F' : IF (NOT AACS(General.FileAttachACS)) THEN
                      Print('^7You do not have access to this command!^1')
                    ELSE IF (CantAbort1) THEN
                      Print('^7You can not attach a file to this message!^1')
                    ELSE IF (MHeader.FileAttached > 0) THEN
                    BEGIN
                      Print('File attached: ^5'+StripName(MsgSubj));
                      NL;
                      IF (PYNQ('Replace the attached file? ',0,FALSE)) THEN
                      BEGIN
                        FileAttach(ExitMsg);
                        ExitMsg := TRUE;
                      END
                      ELSE
                      BEGIN
                        NL;
                        IF (PYNQ('Remove the attached file? ',0,FALSE)) THEN
                        BEGIN
                          SaveFileAttached := MHeader.FileAttached;
                          SaveMsgSubj := MsgSubj;
                          MHeader.FileAttached := 0;
                          MsgSubj := '';
                          NL;
                          EditMsgSubj(MsgSubj,CantAbort1);
                          IF (MsgSubj = '') THEN
                          BEGIN
                            MsgSubj := SaveMsgSubj;
                            MHeader.FileAttached := SaveFileAttached;
                            NL;
                            Print('Aborted!');
                          END;
                        END;
                      END;
                    END
                    ELSE IF PYNQ('Attach a file to this message? ',0,FALSE) THEN
                    BEGIN
                      FileAttach(ExitMsg);
                      ExitMsg := TRUE;
                    END;
              'I' : IF ((TotalLines - 1) < 1) THEN
                      Print('^7No lines to insert before!^1')
                    ELSE IF ((TotalLines - 1) >= MaxLines) THEN
                      Print('^7You have reached the maximum line limit!^1')
                    ELSE
                    BEGIN
                      LineNum1 := -1;
                      InputIntegerWOC('Insert before which line',LineNum1,[NumbersOnly],1,TotalLines);
                      IF (LineNum1 >= 1) AND (LineNum1 <= TotalLines) THEN
                      BEGIN
                        NL;
                        Print('^3Line '+IntToStr(LineNum1)+':');
                        UserColor(1);
                        InputLine(TempStr1,MaxLineLen);
                        NL;
                        IF (PYNQ('Insert this line? ',0,FALSE)) THEN
                        BEGIN
                          FOR LineNum2 := TotalLines DOWNTO (LineNum1 + 1) DO
                            LinePtr^[LineNum2] := LinePtr^[LineNum2 - 1];
                          LinePtr^[LineNum1] := TempStr1;
                          Inc(TotalLines);
                          IF ((TotalLines - 1) = MaxLines) THEN
                            ExitMsg := FALSE;
                          NL;
                          Print('^0Line '+IntToStr(LineNum1)+' inserted.^1');
                        END;
                      END;
                    END;
              'L' : IF ((TotalLines - 1) < 1) THEN
                      Print('^7Nothing to list!^1')
                    ELSE
                    BEGIN
                      IF (PYNQ('List entire message? ',0,TRUE)) THEN
                      BEGIN
                        NL;
                        ListMsg(1,PYNQ('List message with line numbers? ',0,FALSE),SaveLine);
                      END
                      ELSE
                      BEGIN
                        LineNum1 := -1;
                        InputIntegerWOC('%LFStaring line number',LineNum1,[NumbersOnly],1,(TotalLines - 1));
                        IF (LineNum1 >= 1) AND (LineNum1 <= (TotalLines - 1)) THEN
                        BEGIN
                          NL;
                          ListMsg(LineNum1,PYNQ('List message with line numbers? ',0,FALSE),SaveLine);
                        END;
                      END;
                      ShowCont := FALSE;
                    END;
              'M' : IF (NOT AACS(MemMsgArea.MCIACS)) THEN
                      Print('^7You do not have access to this command!^1')
                    ELSE
                     DisableMCI1 := PYNQ('Disable MCI Codes for this message ['+SQOutSp(ShowYesNo(DisableMCI1))+']? ',0,FALSE);
              'O' : PrintF('COLOR');
              'P' : IF ((TotalLines - 1) < 1) THEN
                      Print('^7No lines to replace a string!^1')
                    ELSE
                    BEGIN
                      LineNum1 := -1;
                      InputIntegerWOC('Line to replace string',LineNum1,[NumbersOnly],1,(TotalLines - 1));
                      IF (LineNum1 >= 1) AND (LineNum1 <= (TotalLines - 1)) THEN
                      BEGIN
                        TempStr3 := LinePtr^[LineNum1];
                        Abort := FALSE;
                        Next := FALSE;
                        NL;
                        Print('^3Old line '+IntToStr(LineNum1)+':');
                        MCIAllowed := FALSE;
                        PrintACR('^1'+TempStr3);
                        MCIAllowed := TRUE;
                        NL;
                        Print('^4Enter string to replace:');
                        Prt(': ');
                        InputL(TempStr1,MaxLineLen);
                        IF (TempStr1 <> '') THEN
                          IF (Pos(TempStr1,LinePtr^[LineNum1]) = 0) THEN
                          BEGIN
                            NL;
                            Print('^7String not found.^1');
                          END
                          ELSE
                          BEGIN
                            NL;
                            Print('^4Enter replacement string:');
                            Prt(': ');
                            InputL(TempStr2,MaxLineLen);
                            IF (TempStr2 <> '') THEN
                            BEGIN
                              IF (Pos(TempStr1,TempStr3) > 0) THEN
                              BEGIN
                                Insert(TempStr2,TempStr3,(Pos(TempStr1,TempStr3) + Length(TempStr1)));
                                Delete(TempStr3,Pos(TempStr1,TempStr3),Length(TempStr1));
                              END;
                              NL;
                              Print('^3New line '+IntToStr(LineNum1)+':');
                              MCIAllowed := FALSE;
                              PrintACR('^1'+TempStr3);
                              MCIAllowed := TRUE;
                              NL;
                              IF (PYNQ('Save this line? ',0,FALSE)) THEN
                              BEGIN
                                Insert(TempStr2,LinePtr^[LineNum1],(Pos(TempStr1,LinePtr^[LineNum1]) + Length(TempStr1)));
                                Delete(LinePtr^[LineNum1],Pos(TempStr1,LinePtr^[LineNum1]),Length(TempStr1));
                                NL;
                                Print('^0Line '+IntToStr(LineNum1)+' saved.^1');
                              END;
                            END;
                          END;
                      END;
                    END;
              'Q' : IF (NOT Exist('TEMPQ'+IntToStr(ThisNode))) THEN
                      Print('^7You are not replying to a message!^1')
                    ELSE IF ((TotalLines - 1) >= MaxLines) THEN
                      Print('^7You have reached the maximum line limit!^1')
                    ELSE
                    BEGIN
                      DoQuote(FALSE);
                      NL;
                      CLS;
                      PrintMsgTitle;
                      Print('^0Quoting complete ... Continue ...^1');
                      NL;
                      IF ((TotalLines - 1) >= 1) THEN
                        IF ((TotalLines - 1) > 10) THEN
                          ListMsg(((TotalLines - 1) - 10),FALSE,SaveLine)
                        ELSE
                          ListMsg(1,FALSE,SaveLine);
                      ShowCont := FALSE;
                    END;
              'R' : IF ((TotalLines - 1) < 1) THEN
                      Print('^7No last line to delete!^1')
                    ELSE
                    BEGIN
                      LineNum1 := (TotalLines - 1);
                      Print('^3Line '+IntToStr(LineNum1)+':');
                      MCIAllowed := FALSE;
                      PrintAcr('^1'+LinePtr^[(LineNum1)]);
                      MCIAllowed := TRUE;
                      NL;
                      IF (PYNQ('Delete the last line? ',0,FALSE)) THEN
                      BEGIN
                        IF ((TotalLines - 1) = MaxLines) THEN
                          ExitMsg := TRUE;
                        Dec(TotalLines);
                        NL;
                        Print('^0Line '+IntToStr(LineNum1)+' deleted.^1');
                      END;
                    END;
              'S' : BEGIN
                      WHILE (((TotalLines - 1) >= 1) AND ((LinePtr^[TotalLines - 1] = '') OR
                            (LinePtr^[TotalLines - 1] = ^J))) DO
                        Dec(TotalLines);
                      FOR Counter := (TotalLines - 1) DOWNTO 1 DO
                      BEGIN
                        LineNum2 := 0;
                        FOR LineNum1 := 1 TO Length(LinePtr^[Counter]) DO
                          IF (LinePtr^[Counter][LineNum1] <> ' ') THEN
                            Inc(LineNum2);
                        IF (LineNum2 = 0) THEN
                        BEGIN
                          LinePtr^[Counter][0] := #0;
                          Dec(TotalLines)
                        END
                        ELSE
                          Counter := 1;
                      END;
                      IF (CantAbort1) AND ((TotalLines - 1) < 1) THEN
                        Print('^7You must complete this message!^1')
                      ELSE IF ((TotalLines - 1) < 1) THEN
                        Print('^7Nothing to save!^1')
                      ELSE
                      BEGIN
                        SaveMsg1 := TRUE;
                        AbortMsg := FALSE;
                        ShowCont := FALSE;
                      END;
                    END;
              'T' : IF (CantAbort1) THEN
                      Print('^7The receiver and subject can not be changed!^1')
                    ELSE
                    BEGIN
                      IF (NOT Pub) OR (MAInternet IN MemMsgArea.MAFlags) THEN
                        Print('^7The receiver of this message can not be changed!')
                      ELSE
                        EditMsgTo(MsgTo);
                      NL;
                      IF (MHeader.FileAttached > 0) THEN
                        Print('^7The subject of this message can not be changed!')
                      ELSE
                        EditMsgSubj(MsgSubj,CantAbort1);
                    END;
              'U' : IF ((TotalLines - 1) >= MaxLines) THEN
                      Print('^7You have reached the maximum line limit!^1')
                    ELSE IF PYNQ('Import a file to this message? ',0,FALSE) THEN
                      UploadFile;
              'Z' : IF ((TotalLines - 1) < 1) THEN
                      Print('^7No lines to replace!')
                    ELSE
                    BEGIN
                      LineNum1 := -1;
                      InputIntegerWOC('Line number to replace',LineNum1,[NumbersOnly],1,(TotalLines - 1));
                      IF ((LineNum1 >= 1) AND (LineNum1 <= (TotalLines - 1))) THEN
                      BEGIN
                        Abort := FALSE;
                        Next := FALSE;
                        NL;
                        Print('^3Old line '+IntToStr(LineNum1)+':');
                        MCIAllowed := FALSE;
                        PrintACR('^1'+LinePtr^[LineNum1]);
                        MCIAllowed := TRUE;
                        Print('^3New line '+IntToStr(LineNum1)+':');
                        UserColor(1);
                        InputLine(TempStr1,MaxLineLen);
                        NL;
                        IF PYNQ('Replace this line? ',0,FALSE) THEN
                        BEGIN
                          IF (LinePtr^[LineNum1][Length(LinePtr^[LineNum1])] = #1) AND (TempStr1[Length(TempStr1)]<>#1) THEN
                            LinePtr^[LineNum1] := TempStr1 + #1
                          ELSE
                            LinePtr^[LineNum1] := TempStr1;
                          NL;
                          Print('^0Line '+IntToStr(LineNum1)+' replaced.^1');
                        END;
                      END;
                    END;
              ^M  : BEGIN
                      IF (HelpCounter = 5) THEN
                      BEGIN
                        NL;
                        PrintF('PRHELP');
                        HelpCounter := 0;
                      END;
                      Inc(HelpCounter);
                    END;
              '?' : PrintF('PRHELP');
            END;
            IF (ShowCont) AND (ExitMsg) THEN
            BEGIN
              NL;
              Print('^0Continue...^1');
              NL;
            END;
          END;
          IF (SaveLine) THEN
          BEGIN
            LinePtr^[TotalLines] := LineStr;
            Inc(TotalLines);
            IF (LineStr <> '') THEN
              HelpCounter := 1
            ELSE
            BEGIN
              IF (HelpCounter = 5) THEN
              BEGIN
                Print('^0Enter "/?" on a blank line for help.^1');
                Dec(TotalLines,5);
                HelpCounter := 0;
              END;
              Inc(HelpCounter);
            END;
            IF ((TotalLines - 1) >= MaxLines) THEN
            BEGIN
              NL;
              Print('^7You have reached the maximum line limit!');
              IF (InportFileOpen) THEN
              BEGIN
                InportFileOpen := FALSE;
                Close(InportFile);
              END;
              HelpCounter := 1;
              ExitMsg := FALSE;
              LineStr := '/';
            END;
          END;
        UNTIL (AbortMsg) OR (ExitMsg) OR (SaveMsg1) OR (HangUp);
      UNTIL ((AbortMsg) OR (SaveMsg1) OR (HangUp));
    END;
  END;

  PROCEDURE SaveIt(DisableMCI1: Boolean);
  VAR
    LineStr: AStr;
    UserName: Str36;
    C: Char;
    LineNum1,
    Counter: Integer;
    AddTagLine: Boolean;
  BEGIN

    IF (ReadInMsg <> '') THEN
    BEGIN

      Assign(InportFile,ReadInMsg);
      ReWrite(InportFile);
      IF (IOResult = 0) THEN
      BEGIN
        FOR LineNum1 := 1 TO (TotalLines - 1) DO
          WriteLn(InportFile,LinePtr^[LineNum1]);
        Close(InportFile);
      END;

    END
    ELSE
    BEGIN

      AddTagLine := FALSE;
      IF (MAQuote IN MemMsgArea.MAFlags) THEN
        AddTagLine := PYNQ('Add a tagline to your message? ',0,TRUE);

      MHeader.Subject := MsgSubj;
      MHeader.OriginDate := '';
      MHeader.From.Anon := 0;
      MHeader.MTO.Anon := 0;
      MHeader.Replies := 0;
      MHeader.ReplyTo := 0;
      MHeader.Date := GetPackDateTime;
      GetDayOfWeek(MHeader.DayOfWeek);

      IF (Pub AND (MemMsgArea.MAType IN [1,2])) OR (NOT Pub AND (NetMail IN MHeader.Status)) THEN
      BEGIN
        NewEchoMail := TRUE;
        IF (NOT (MAScanOut IN MemMsgArea.MAFlags)) THEN
          UpdateBoard;
      END;

      MHeader.From.UserNum := UserNum;

      UserName := AllCaps(ThisUser.Name);

      IF (NOT Pub) AND (NetMail IN MHeader.Status) AND (ThisUser.Name <> AllCaps(ThisUser.RealName)) THEN
        IF (General.AllowAlias) THEN
        BEGIN
          NL;
          IF PYNQ('Send this with your real name? ',0,TRUE) THEN
            UserName := AllCaps(ThisUser.RealName);
        END;

      MHeader.From.A1S := UserName;
      MHeader.From.Real := AllCaps(ThisUser.RealName);
      MHeader.From.Name := AllCaps(ThisUser.Name);

      MHeader.Status := [] + (MHeader.Status * [NetMail]);

      IF (Pub) AND (RValidate IN ThisUser.Flags) THEN
        Include(MHeader.Status,Unvalidated);

      IF (AACS(MemMsgArea.MCIACS)) THEN
      BEGIN
        Include(MHeader.Status,AllowMCI);
        IF (DisableMCI1) THEN
          Exclude(MHeader.Status,AllowMCI);
      END;

      IF (Pub) THEN
      BEGIN
        MHeader.MTO.Name := MsgTo;
        MHeader.MTO.Real := MsgTo;
        MHeader.MTO.A1S := MsgTo;
      END;

      IF (NOT (NetMail IN MHeader.Status)) THEN
        Anonymous(FALSE,MHeader);

      NL;
      Prompt('^5Saving...');

      Reset(MsgTxtF,1);
      IF (IOResult = 2) THEN
        ReWrite(MsgTxtF,1);
      MHeader.TextSize := 0;
      MHeader.Pointer := (FileSize(MsgTxtF) + 1);
      Seek(MsgTxtF,FileSize(MsgTxtF));

      IF (NetMail IN MHeader.Status) AND (Pos('@',MHeader.MTO.A1S) > 0) THEN
      BEGIN

        FOR Counter := 1 TO Length(MHeader.MTO.A1S) DO
          IF (MHeader.MTO.A1S[Counter] IN ['A'..'Z']) THEN
            Inc(MHeader.MTO.A1S[Counter],32);

        LineStr := 'To: '+MsgTo;
        BlockWrite(MsgTxtF,LineStr,Length(LineStr) + 1);
        Inc(MHeader.TextSize,Length(LineStr) + 1);

        MHeader.MTO.A1S := 'UUCP';
      END;

      IF ((Pub) AND (MAFilter IN MemMsgArea.MAFlags)) THEN
        FOR LineNum1 := 1 TO (TotalLines - 1) DO
          IF (Length(LinePtr^[LineNum1]) > 0) THEN
          BEGIN
            LinePtr^[LineNum1] := StripColor(LinePtr^[LineNum1]);
            FOR Counter := 1 TO Length(LinePtr^[LineNum1]) DO
            BEGIN
              C := LinePtr^[LineNum1][Counter];
              IF (C IN [#0..#1,#3..#31,#127..#255]) THEN
                C := '*';
              LinePtr^[LineNum1][Counter] := C;
            END;
          END;

      FOR LineNum1 := 1 TO (TotalLines - 1) DO
      BEGIN
        LineStr := LinePtr^[LineNum1];
        Inc(MHeader.TextSize,(Length(LineStr) + 1));
        BlockWrite(MsgTxtF,LineStr,(Length(LineStr) + 1));
      END;

      IF (AddTagLine) THEN
      BEGIN
        LineStr := '';
        Inc(MHeader.TextSize,(Length(LineStr) + 1));
        BlockWrite(MsgTxtF,LineStr,(Length(LineStr) + 1));
        LineStr := '... '+GetTagLine;
        Inc(MHeader.TextSize,(Length(LineStr) + 1));
        BlockWrite(MsgTxtF,LineStr,(Length(LineStr) + 1));
      END;

      IF (MemMsgArea.MAType IN [1,2]) AND (MAAddTear IN MemMsgarea.MAFlags) THEN
      BEGIN
        LineStr := '';
        Inc(MHeader.TextSize,(Length(LineStr) + 1));
        BlockWrite(MsgTxtF,LineStr,1);

        LineStr := '--- Renegade v'+General.Version;
        Inc(MHeader.TextSize,(Length(LineStr) + 1));
        BlockWrite(MsgTxtF,LineStr,(Length(LineStr) + 1));

        IF (MemMsgArea.AKA > 19) THEN
          MemMsgArea.AKA := 0;

        LineStr := ' * Origin: ';
        IF (MemMsgArea.Origin <> '') THEN
          LineStr := LineStr + MemMsgArea.Origin
        ELSE
          LineStr := LineStr + General.Origin;

        LineStr := LineStr + ' (';

        LineStr := LineStr + IntToStr(General.AKA[MemMsgArea.AKA].Zone)+':'+
                             IntToStr(General.AKA[MemMsgArea.AKA].Net)+'/'+
                             IntToStr(General.AKA[MemMsgArea.AKA].Node);

        IF (General.AKA[MemMsgArea.AKA].Point > 0) THEN
          LineStr := LineStr + '.'+IntToStr(General.AKA[MemMsgArea.AKA].Point);

        LineStr := LineStr + ')';
        Inc(MHeader.TextSize,(Length(LineStr) + 1));
        BlockWrite(MsgTxtF,LineStr,(Length(LineStr) + 1));

      END;

      Close(MsgTxtF);
      LastError := IOResult;

      BackErase(9);

    END;

    InputMessage := TRUE;

  END;

BEGIN
  CLS;
  InputMessage := FALSE;

  MaxLines := ((MaxAvail DIV 120) - 20);
  IF (MaxLines > MaxMsgLines) THEN
    MaxLines := MaxMsgLines;
  GetMem(LinePtr,(MaxLines * 120));

  InportFileOpen := FALSE;
  Escp := FALSE;
  MaxQuoteLines := 0;
  LastQuoteLine := 0;

  IF (NOT IsReply) THEN
    MsgTo := ''
  ELSE
  BEGIN
    IF (MARealName IN MemMsgArea.MAFlags) THEN
      MsgTo := Caps(MHeader.MTO.Real)
    ELSE
      MsgTo := Caps(MHeader.MTO.A1S)
  END;

  IF (InResponseTo <> '') THEN
    MsgSubj := InResponseTo
  ELSE
    MsgSubj := MsgTitle;

  IF (MsgSubj[1] <> '\') THEN
    CantAbort := FALSE
  ELSE
  BEGIN
    MsgSubj := Copy(MsgSubj,2,(Length(MsgSubj) - 1));
    MHeader.Subject := MsgSubj;
    CantAbort := TRUE;
  END;

  IF (MsgSubj[1] = #1) THEN
  BEGIN
    MsgSubj := Copy(MsgSubj,2,(Length(MsgSubj) - 1));
    IF (MHeader.Subject[1] = #1) THEN
      MHeader.Subject := Copy(MHeader.Subject,2,(Length(MHeader.Subject) - 1));
  END
  ELSE IF (MsgSubj <> '') AND (Copy(MsgSubj,1,3) <> 'Re:') THEN
    MsgSubj := 'Re: '+Copy(MsgSubj,1,36);

  MHeader.FileAttached := 0;

  InputTheMessage(CantAbort,DisableMCI,SaveMsg);

  IF (SaveMsg) THEN
    SaveIt(DisableMCI);

  Kill('TEMPQ'+IntToStr(ThisNode));

  DOSANSIOn := FALSE;

  FreeMem(LinePtr,(MaxLines * 120));
END;

END.
