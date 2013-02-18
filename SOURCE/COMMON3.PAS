{$IFDEF WIN32}
{$I DEFINES.INC}
{$ENDIF}

{$A+,B-,D+,E-,F+,I-,L+,N-,O+,R-,S-,V-,X-}

UNIT Common3;

INTERFACE

USES
  Common;

PROCEDURE InputDefault(VAR S: STRING; v: STRING; MaxLen: Byte; InputFlags: InputFlagSet; LineFeed: Boolean);
PROCEDURE InputFormatted(DisplayStr: AStr; VAR InputStr: STRING; Format: STRING; Abortable: Boolean);
PROCEDURE InputLongIntWC(S: AStr; VAR L: LongInt; InputFlags: InputFlagSet; LowNum,HighNum: LongInt; VAR Changed: Boolean);
PROCEDURE InputLongIntWOC(S: AStr; VAR L: LongInt; InputFlags: InputFlagSet; LowNum,HighNum: LongInt);
PROCEDURE InputWordWC(S: AStr; VAR W: SmallWord; InputFlags: InputFlagSet; LowNum,HighNum: Word; VAR Changed: Boolean);
PROCEDURE InputWordWOC(S: AStr; VAR W: SmallWord; InputFlags: InputFlagSet; LowNum,HighNum: Word);
PROCEDURE InputIntegerWC(S: AStr; VAR I: SmallInt; InputFlags: InputFlagSet; LowNum,HighNum: Integer; VAR Changed: Boolean);
PROCEDURE InputIntegerWOC(S: AStr; VAR I: SmallInt; InputFlags: InputFlagSet; LowNum,HighNum: Integer);
PROCEDURE InputByteWC(S: AStr; VAR B: Byte; InputFlags: InputFlagSet; LowNum,HighNum: Byte; VAR Changed: Boolean);
PROCEDURE InputByteWOC(S: AStr; VAR B: Byte; InputFlags: InputFlagSet; LowNum,HighNum: Byte);
PROCEDURE InputWN1(DisplayStr: AStr; VAR InputStr: AStr; MaxLen: Byte; InputFlags: InputFlagSet; VAR Changed: Boolean);
PROCEDURE InputWNWC(DisplayStr: AStr; VAR InputStr: AStr; MaxLen: Byte; VAR Changed: Boolean);
PROCEDURE InputMain(VAR S: STRING; MaxLen: Byte; InputFlags: InputFlagSet);
PROCEDURE InputWC(VAR S: STRING; MaxLen: Byte);
PROCEDURE Input(VAR S: STRING; MaxLen: Byte);
PROCEDURE InputL(VAR S: STRING; MaxLen: Byte);
PROCEDURE InputCaps(VAR S: STRING; MaxLen: Byte);

IMPLEMENTATION

USES
  Crt
{$IFDEF WIN32}
  ,RPScreen
{$ENDIF}
  ;

PROCEDURE InputDefault(VAR S: STRING; v: STRING; MaxLen: Byte; InputFlags: InputFlagSet; LineFeed: Boolean);
VAR
  C: Char;
  Counter: Byte;
BEGIN
  MPL(MaxLen);
  MCIAllowed := FALSE;
  ColorAllowed := FALSE;
  Prompt(v);
  ColorAllowed := TRUE;
  MCIAllowed := TRUE;
  C := Char(GetKey);
  IF (C <> #13) THEN
  BEGIN
    FOR Counter := 1 TO Length(v) DO
      BackSpace;
    Buf := C + Buf;
    InputMain(S,MaxLen,InputFlags);
    IF (S = '') THEN
    BEGIN
      S := v;
      MPL(MaxLen);
      Prompt(S);
    END
    ELSE IF (S = ' ') THEN
      S := '';
  END
  ELSE
  BEGIN
    S := v;
    IF NOT (NolineFeed IN InputFlags) THEN
      NL;
  END;
  UserColor(1);
  IF (LineFeed) THEN
    NL;
END;


PROCEDURE InputFormatted(DisplayStr: AStr; VAR InputStr: STRING; Format: STRING; Abortable: Boolean);
VAR
  c: Char;
  i,
  FarBack: Byte;

  PROCEDURE UpdateString;
  BEGIN
    WHILE (NOT (Format[i] IN ['#','@']) AND (i <= Length(Format))) DO
    BEGIN
      OutKey(Format[i]);
      InputStr := InputStr + Format[i];
      Inc(i);
    END;
  END;

BEGIN
  InputStr := '';
  Prt(DisplayStr);
  MPL(Length(Format));
  i := 1;
  UpdateString;
  FarBack := i;
  REPEAT
    c := Char(GetKey);
    IF (i <= Length(Format)) THEN
      IF ((Format[i] = '@') AND (c IN ['a'..'z','A'..'Z'])) OR ((Format[i] = '#') AND (c IN ['0'..'9'])) THEN
      BEGIN
        c := UpCase(c);
        OutKey(c);
        InputStr := InputStr + c;
        Inc(i);
        UpdateString;
      END;
    IF (c = ^H) THEN
    BEGIN
      WHILE ((i > FarBack) AND NOT (Format[i - 1] IN ['#','@'])) DO
      BEGIN
        BackSpace;
        Dec(InputStr[0]);
        Dec(i);
      END;
      IF (i > FarBack) THEN
      BEGIN
        BackSpace;
        Dec(InputStr[0]);
        Dec(i);
      END;
    END;
  UNTIL (HangUp) OR ((i > Length(Format)) OR (Abortable)) AND (c = #13);
  UserColor(1);
  NL;
END;

PROCEDURE InputLongIntWC(S: AStr; VAR L: LongInt; InputFlags: InputFlagSet; LowNum,HighNum: LongInt; VAR Changed: Boolean);
VAR
  TempStr: Str10;
  SaveL: LongInt;
  TempL: Real;
BEGIN
  SaveL := L;
  IF (NOT (DisplayValue IN InputFlags)) THEN
    Prt(S+' (^5'+IntToStr(LowNum)+'^4-^5'+IntToStr(HighNum)+'^4): ')
  ELSE
    Prt(S+' (^5'+IntToStr(LowNum)+'^4-^5'+IntToStr(HighNum)+'^4) [^5'+IntToStr(L)+'^4]: ');
  MPL(Length(IntToStr(HighNum)));
  TempStr := IntToStr(L);
  InputMain(TempStr,Length(IntToStr(HighNum)),InputFlags);
  IF (TempStr <> '') THEN
  BEGIN
    TempL := ValueR(TempStr);
    IF ((Trunc(TempL) >= LowNum) AND (Trunc(TempL) <= HighNum)) THEN
      L := Trunc(TempL)
    ELSE
    BEGIN
      NL;
      Print('^7The range must be from '+IntToStr(LowNum)+' to '+IntToStr(HighNum)+'!^1');
      PauseScr(FALSE);
    END;
  END;
  IF (SaveL <> L) THEN
    Changed := TRUE;
END;

PROCEDURE InputLongIntWOC(S: AStr; VAR L: LongInt; InputFlags: InputFlagSet; LowNum,HighNum: LongInt);
VAR
  Changed: Boolean;
BEGIN
  Changed := FALSE;
  InputLongIntWC(S,L,InputFlags,LowNum,HighNum,Changed);
END;

PROCEDURE InputWordWC(S: AStr; VAR W: SmallWord; InputFlags: InputFlagSet; LowNum,HighNum: Word; VAR Changed: Boolean);
VAR
  TempStr: Str5;
  SaveW: Word;
  TempW: Longint;
BEGIN
  SaveW := W;
  IF (NOT (DisplayValue IN InputFlags)) THEN
    Prt(S+' (^5'+IntToStr(LowNum)+'^4-^5'+IntToStr(HighNum)+'^4): ')
  ELSE
    Prt(S+' (^5'+IntToStr(LowNum)+'^4-^5'+IntToStr(HighNum)+'^4) [^5'+IntToStr(W)+'^4]: ');
  MPL(Length(IntToStr(HighNum)));
  TempStr := IntToStr(W);
  InputMain(TempStr,Length(IntToStr(HighNum)),InputFlags);
  IF (TempStr <> '') THEN
  BEGIN
    TempW := StrToInt(TempStr);
    IF ((TempW >= LowNum) AND (TempW <= HighNum)) THEN
      W := TempW
    ELSE
    BEGIN
      NL;
      Print('^7The range must be from '+IntToStr(LowNum)+' to '+IntToStr(HighNum)+'!^1');
      PauseScr(FALSE);
    END;
  END;
  IF (SaveW <> W) THEN
    Changed := TRUE;
END;

PROCEDURE InputWordWOC(S: AStr; VAR W: SmallWord; InputFlags: InputFlagSet; LowNum,HighNum: Word);
VAR
  Changed: Boolean;
BEGIN
  Changed := FALSE;
  InputWordWC(S,W,InputFlags,LowNum,HighNum,Changed);
END;

PROCEDURE InputIntegerWC(S: AStr; VAR I: SmallInt; InputFlags: InputFlagSet; LowNum,HighNum: Integer; VAR Changed: Boolean);
VAR
  TempStr: Str5;
  SaveI: Integer;
  TempI: Longint;
BEGIN
  SaveI := I;
  IF (NOT (DisplayValue IN InputFlags)) THEN
    Prt(S+' (^5'+IntToStr(LowNum)+'^4-^5'+IntToStr(HighNum)+'^4): ')
  ELSE
    Prt(S+' (^5'+IntToStr(LowNum)+'^4-^5'+IntToStr(HighNum)+'^4) [^5'+IntToStr(I)+'^4]: ');
  MPL(Length(IntToStr(HighNum)));
  TempStr := IntToStr(I);
  InputMain(TempStr,Length(IntToStr(HighNum)),InputFlags);
  IF (TempStr <> '') THEN
  BEGIN
    TempI := StrToInt(TempStr);
    IF ((TempI >= LowNum) AND (TempI <= HighNum)) THEN
      I := TempI
    ELSE
    BEGIN
      NL;
      Print('^7The range must be from '+IntToStr(LowNum)+' to '+IntToStr(HighNum)+'!^1');
      PauseScr(FALSE);
    END;
  END;
  IF (SaveI <> I) THEN
    Changed := TRUE;
END;

PROCEDURE InputIntegerWOC(S: AStr; VAR I: SmallInt; InputFlags: InputFlagSet; LowNum,HighNum: Integer);
VAR
  Changed: Boolean;
BEGIN
  Changed := FALSE;
  InputIntegerWC(S,I,InputFlags,LowNum,HighNum,Changed);
END;

PROCEDURE InputByteWC(S: AStr; VAR B: Byte; InputFlags: InputFlagSet; LowNum,HighNum: Byte; VAR Changed: Boolean);
VAR
  TempStr: Str3;
  SaveB: Byte;
  TempB: Integer;
BEGIN
  SaveB := B;
  IF (NOT (DisplayValue IN InputFlags)) THEN
    Prt(S+' (^5'+IntToStr(LowNum)+'^4-^5'+IntToStr(HighNum)+'^4): ')
  ELSE
    Prt(S+' (^5'+IntToStr(LowNum)+'^4-^5'+IntToStr(HighNum)+'^4) [^5'+IntToStr(B)+'^4]: ');
  MPL(Length(IntToStr(HighNum)));
  TempStr := IntToStr(B);
  InputMain(TempStr,Length(IntToStr(HighNum)),InputFlags);
  IF (TempStr <> '') THEN
  BEGIN
    TempB := StrToInt(TempStr);
    IF ((TempB >= LowNum) AND (TempB <= HighNum)) THEN
      B := TempB
    ELSE
    BEGIN
      NL;
      Print('^7The range must be from '+IntToStr(LowNum)+' to '+IntToStr(HighNum)+'!^1');
      PauseScr(FALSE);
    END;
  END;
  IF (SaveB <> B) THEN
    Changed := TRUE;
END;

PROCEDURE InputByteWOC(S: AStr; VAR B: Byte; InputFlags: InputFlagSet; LowNum,HighNum: Byte);
VAR
  Changed: Boolean;
BEGIN
  Changed := FALSE;
  InputByteWC(S,B,InputFlags,LowNum,HighNum,Changed);
END;

PROCEDURE InputWN1(DisplayStr: AStr; VAR InputStr: AStr; MaxLen: Byte; InputFlags: InputFlagSet; VAR Changed: Boolean);
VAR
  SaveInputStr: AStr;
BEGIN
  Prt(DisplayStr);
  IF (NOT (ColorsAllowed IN InputFlags)) THEN
    MPL(MaxLen);
  SaveInputStr := InputStr;
  InputMain(SaveInputStr,MaxLen,InputFlags);
  IF (SaveInputStr = '') THEN
    SaveInputStr := InputStr;
  IF (SaveInputStr = ' ') THEN
    IF PYNQ('Blank String? ',0,FALSE) THEN
      SaveInputStr := ''
    ELSE
      SaveInputStr := InputStr;
  IF (SaveInputStr <> InputStr) THEN
    Changed := TRUE;
  InputStr := SaveInputStr;
END;

PROCEDURE InputWNWC(DisplayStr: AStr; VAR InputStr: AStr; MaxLen: Byte; VAR Changed: Boolean);
BEGIN
  InputWN1(DisplayStr,InputStr,MaxLen,[ColorsAllowed,InterActiveEdit],Changed);
END;

PROCEDURE InputMain(VAR S: STRING; MaxLen: Byte; InputFlags: InputFlagSet);
VAR
  SaveS: STRING;
  Is: STRING[2];
  Cp,
  Cl,
  Counter: Byte;
  c,
  C1: Word;
  InsertMode,
  FirstKey: Boolean;

  PROCEDURE MPrompt(S: STRING);
  BEGIN
    SerialOut(S);
    IF (WantOut) THEN
      Write(S);
  END;

  PROCEDURE Cursor_Left;
  BEGIN
    IF (NOT OkAvatar) THEN
      SerialOut(#27'[D')
    ELSE
      SerialOut(^V^E);
    IF (WantOut) THEN
      GotoXY((WhereX - 1),WhereY);
  END;

  PROCEDURE Cursor_Right;
  BEGIN
    OutKey(S[Cp]);
    Inc(Cp);
  END;

{$IFDEF MSDOS}
  PROCEDURE SetCursor(InsertMode: Boolean); ASSEMBLER;
  ASM
    cmp InsertMode,0
    je @turnon
    mov ch,0
    mov Cl,7
    jmp @goforit
    @turnon:
    mov ch,6
    mov Cl,7
    @goforit:
    mov ah,1
    int 10h
  END;
{$ENDIF}
{$IFDEF WIN32}
  PROCEDURE SetCursor(InsertMode: Boolean);
  BEGIN
    if (InsertMode) then
    begin
      RPInsertCursor;
    end else
    begin
      RPBlockCursor;
    end;
  END;
{$ENDIF}

BEGIN
  FirstKey := FALSE;

  IF (NOT (InterActiveEdit IN InputFlags)) OR NOT (Okansi OR OkAvatar) THEN
  BEGIN
    S := '';
    Cp := 1;
    Cl := 0;
  END
  ELSE
  BEGIN
    Cp := Length(S);
    Cl := Length(S);
    IF (Cp = 0) THEN
      Cp := 1;
    MPrompt(S);
    IF (Length(S) > 0) THEN
    BEGIN
      Cursor_Left;
      IF (Cp <= MaxLen) THEN  (* Was Cp < MaxLen *)
        Cursor_Right;
    END;
    FirstKey := TRUE;
  END;

  SaveS := S;
  InsertMode := FALSE;

  REPEAT
    MLC := S;
    SetCursor(InsertMode);
    c := GetKey;

    IF (FirstKey) AND (C = 32) THEN
      C := 24;

    FirstKey := FALSE;

    CASE c OF
      8 : IF (Cp > 1) THEN
          BEGIN
            Dec(Cl);
            Dec(Cp);
            Delete(S,Cp,1);
            BackSpace;
            IF (Cp < Cl) THEN
            BEGIN
              MPrompt(Copy(S,Cp,255)+' ');
              FOR Counter := Cp TO (Cl + 1) DO
                Cursor_Left;
            END;
          END;
     24 : BEGIN
            FOR Counter := Cp TO Cl DO
              OutKey(' ');
            FOR Counter := 1 TO Cl DO
              BackSpace;
            Cl := 0;
            Cp := 1;
          END;
     32..255:
          BEGIN
            IF (NOT (NumbersOnly IN InputFlags)) THEN
            BEGIN
              IF (UpperOnly IN InputFlags) THEN
                c := Ord(UpCase(Char(c)));
              IF (CapWords IN InputFlags) THEN
                IF (Cp > 1) THEN
                BEGIN
                  IF (S[Cp - 1] IN [#32..#64]) THEN
                    c := Ord(UpCase(Char(c)))
                  ELSE IF (c IN [Ord('A')..Ord('Z')]) THEN
                    Inc(c,32);
                END
                ELSE
                  c := Ord(UpCase(Char(c)));
            END;
            IF (NOT (NumbersOnly IN InputFlags)) OR (c IN [45,48..57]) THEN
            BEGIN
              IF ((InsertMode) AND (Cl < MaxLen)) OR ((NOT InsertMode) AND (Cp <= MaxLen)) THEN
              BEGIN
                OutKey(Char(c));
                IF (InsertMode) THEN
                BEGIN
                  Is := Char(c);
                  MPrompt(Copy(S,Cp,255));
                  Insert(Is,S,Cp);
                  FOR Counter := Cp TO Cl DO
                    Cursor_Left;
                END
                ELSE
                  S[Cp]:= Char(c);
                IF (InsertMode) OR ((Cp - 1) = Cl) THEN
                  Inc(Cl);
                Inc(Cp);
                IF (Trapping) THEN
                  Write(TrapFile,Char(c));
              END;
            END;
          END;
      F_END :
          WHILE (Cp < (Cl + 1)) AND (Cp <= MaxLen) DO
            Cursor_Right;
     F_HOME :
          WHILE (Cp > 1) DO
          BEGIN
            Cursor_Left;
            Dec(Cp);
          END;
     F_LEFT :
          IF (Cp > 1) THEN
          BEGIN
            Cursor_Left;
            Dec(Cp);
          END;
    F_RIGHT :
          IF (Cp <= Cl) THEN
            Cursor_Right;
      F_INS :
          BEGIN
            InsertMode := (NOT InsertMode);
            SetCursor(InsertMode);
          END;
      F_DEL :
          IF (Cp > 0) AND (Cp <= Cl) THEN
          BEGIN
            Dec(Cl);
            Delete(S,Cp,1);
            MPrompt(Copy(S,Cp,255)+' ');
            FOR Counter := Cp TO (Cl + 1) DO
              Cursor_Left;
          END;
    END;
    S[0] := Chr(Cl);
  UNTIL (c = 13) OR (HangUp);
  IF ((Redisplay IN InputFlags) AND (S = '')) THEN
  BEGIN
    S := SaveS;
    MPrompt(S);
  END;

  UserColor(1);

  IF (NOT (NoLineFeed IN InputFlags)) THEN
    NL;
  MLC := '';
  SetCursor(FALSE);
END;

PROCEDURE InputWC(VAR S: STRING; MaxLen: Byte);
BEGIN
  InputMain(S,MaxLen,[ColorsAllowed]);
END;

PROCEDURE Input(VAR S: STRING; MaxLen: Byte);
BEGIN
  InputMain(S,MaxLen,[UpperOnly]);
END;

PROCEDURE InputL(VAR S: STRING; MaxLen: Byte);
BEGIN
  InputMain(S,MaxLen,[]);
END;

PROCEDURE InputCaps(VAR S: STRING; MaxLen: Byte);
BEGIN
  InputMain(S,MaxLen,[CapWords]);
END;

END.
