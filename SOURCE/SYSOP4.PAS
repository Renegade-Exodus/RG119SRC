{$IFDEF WIN32}
{$I DEFINES.INC}
{$ENDIF}

{$A+,B-,D-,E-,F+,I-,L-,N-,O+,R-,S-,V-}

UNIT SysOp4;

INTERFACE

USES
  Common;

PROCEDURE TEdit1;
PROCEDURE TEdit(CONST FSpec: AStr);

IMPLEMENTATION

USES
  Dos;

PROCEDURE TEdit1;
VAR
  FSpec: AStr;
  Dir: DirStr;
  Name: NameStr;
  Ext: ExtStr;
BEGIN
  NL;
  Prt('File name: ');
  IF (FileSysOp) THEN
  BEGIN
    MPL(50);
    Input(FSpec,50);
  END
  ELSE
  BEGIN
    MPL(12);
    Input(FSpec,12);
    FSplit(FSpec,Dir,Name,Ext);
    FSpec := Name+Ext;
  END;
  TEdit(FSpec);
END;

PROCEDURE TEdit(CONST FSpec: AStr);
TYPE
  StrPtr = ^StrRec;

  StrRec = RECORD
    S: AStr;
    Next,
    Last: StrPtr;
  END;

VAR
  TopHeap: ^Byte;
  Fil: Text;
  Cur,
  Nex,
  Las,
  Top,
  Bottom,
  Used: StrPtr;
  S: AStr;
  TotalLines,
  CurLine,
  I: Integer;
  Done,
  AllRead: Boolean;

  PROCEDURE InLi(VAR S1: AStr);
  VAR
    C,
    C1: Char;
    Cp,
    Rp,
    CV,
    CC: Integer;

    PROCEDURE BKSpc;
    BEGIN
      IF (Cp > 1) THEN
      BEGIN
        IF (S1[Cp - 2] = '^') AND (S1[Cp - 1] IN ['0'..'9']) THEN
        BEGIN
          UserColor(1);
          Dec(Cp);
        END
        ELSE IF (S1[Cp - 1] = #8) THEN
        BEGIN
          Prompt(' ');
          Inc(Rp);
        END
        ELSE IF (S1[Cp - 1] <> #10) THEN
        BEGIN
          Prompt(#8+' '+#8);
          Dec(Rp);
        END;
        Dec(Cp);
      END;
    END;

  BEGIN
    Rp := 1;
    Cp := 1;
    S1 := '';
    IF (LastLineStr <> '') THEN
    BEGIN
      Prompt(LastLineStr);
      S1 := LastLineStr;
      LastLineStr := '';
      Cp := (Length(S1) + 1);
      Rp := Cp;
    END;
    REPEAT
      C := Char(GetKey);
      CASE C of
        #32..#255 :
              IF (Cp < StrLen) AND (Rp < ThisUser.LineLen) THEN
              BEGIN
                S1[Cp] := C;
                Inc(Cp);
                Inc(Rp);
                OutKey(C);
              END;
         ^H : BKSpc;
         ^S : BEGIN
                CV := (5 - (Cp MOD 5));
                IF ((Cp + CV) < StrLen) AND ((Rp + CV) < ThisUser.LineLen) THEN
                  FOR CC := 1 TO CV DO
                  BEGIN
                    Prompt(' ');
                    S1[Cp] := ' ';
                    Inc(Rp);
                    Inc(Cp);
                  END;
              END;
         ^P : IF (OkANSI OR OkAvatar) AND (Cp < (StrLen - 1)) THEN
              BEGIN
                C1 := Char(GetKey);
                IF (C1 IN ['0'..'9']) THEN
                BEGIN
                  S1[Cp] := '^';
                  Inc(Cp);
                  S1[Cp] := C1;
                  Inc(Cp);
                  UserColor(Ord(S1[Cp - 1]));
                END;
              END;
         ^X : BEGIN
                Cp := 1;
                FOR CV := 1 TO (Rp - 1) DO
                  Prompt(#8+' '+#8);
                UserColor(1);
                Rp := 1;
              END;
      END;
    UNTIL ((C = ^M) OR (Rp = ThisUser.LineLen) OR (HangUp));
    S1[0] := Chr(Cp - 1);
    IF (C <> ^M ) THEN
    BEGIN
      CV := (Cp - 1);
      WHILE (CV > 1) AND (S1[CV] <> ' ') AND ((S1[CV] <> ^H) OR (S1[CV - 1] = '^')) DO
        Dec(CV);
      IF (CV > (Rp DIV 2)) AND (CV <> (Cp - 1)) THEN
      BEGIN
        LastLineStr := Copy(S1,(CV + 1),(Cp - CV));
        FOR CC := (Cp - 2) DOWNTO CV DO
          Prompt(^H);
        FOR CC := (Cp - 2) DOWNTO CV DO
          Prompt(' ');
        S1[0] := Chr(CV - 1);
      END;
    END;
    NL;
  END;

  FUNCTION NewPtr(VAR x: StrPtr): Boolean;
  BEGIN
    IF (Used <> NIL) THEN
    BEGIN
      x := Used;
      Used := Used^.Next;
      NewPtr := TRUE;
    END
    ELSE
    BEGIN
      IF (MaxAvail > 2048) THEN
      BEGIN
        New(x);
        NewPtr := TRUE;
      END
      ELSE
        NewPtr := FALSE;
    END;
  END;

  PROCEDURE OldPtr(VAR x: StrPtr);
  BEGIN
    x^.Next := Used;
    Used := x;
  END;

  PROCEDURE PLine(Cl: Integer; VAR Cp: StrPtr);
  VAR
    S1: AStr;
  BEGIN
    IF (NOT Abort) THEN
    BEGIN
      IF (Cp = NIL) THEN
        S1 := '      ^5'+'[^3'+'END^5'+']'
      ELSE
        S1 := PadRightInt(Cl,4)+': '+Cp^.S;
      PrintACR(S1);
    END;
  END;

  PROCEDURE PL;
  BEGIN
    Abort := FALSE;
    PLine(CurLine,Cur);
  END;

BEGIN
{$IFDEF MSDOS}
  Mark(TopHeap);
{$ENDIF}
{$IFDEF WIN32}
  // REETODO Prepare to leak memory...
{$ENDIF}
  Used := NIL;
  Top := NIL;
  Bottom := NIL;
  AllRead := TRUE;
  IF (FSpec = '') THEN
  BEGIN
    Print('Aborted.');
  END
  ELSE
  BEGIN
    Abort := FALSE;
    Next := FALSE;
    TotalLines := 0;
    New(Cur);
    Cur^.Last := NIL;
    Cur^.S := '';
    NL;
    Assign(Fil,FSpec);
    Reset(Fil);
    IF (IOResult <> 0) THEN
    BEGIN
      ReWrite(Fil);
      IF (IOResult <> 0) THEN
      BEGIN
        Print('Error reading file.');
        Abort := TRUE;
      END
      ELSE
      BEGIN
        Close(Fil);
        Erase(Fil);
        Print('New file.');
        TotalLines := 0;
        Cur := NIL;
        Top := Cur;
        Bottom := Cur;
      END;
    END
    ELSE
    BEGIN
      Abort := NOT NewPtr(Nex);
      Top := Nex;
      Print('^1Loading...');
      WHILE ((NOT EOF(Fil)) AND (NOT Abort)) DO
      BEGIN
        Inc(TotalLines);
        Cur^.Next := Nex;
        Nex^.Last := Cur;
        Cur := Nex;
        ReadLn(Fil,S);
        Cur^.S := S;
        Abort := NOT NewPtr(Nex);
      END;
      Close(Fil);
      Cur^.Next :=  NIL;
      IF (TotalLines = 0) THEN
      BEGIN
        Cur := NIL;
        Top := NIL;
      END;
      Bottom := Cur;
      IF (Abort) THEN
      BEGIN
        NL;
        Print(^G^G'|12WARNING: |10Not all of file read.^3');
        NL;
        AllRead := FALSE;
      END;
      Abort := FALSE;
    END;
    IF (NOT Abort) THEN
    BEGIN
      Print('Total lines: '+IntToStr(TotalLines));
      Cur := Top;
      IF (Top <> NIL) THEN
        Top^.Last := NIL;
      CurLine := 1;
      Done := FALSE;
      PL;
      REPEAT
        Prt(':');
        Input(S,10);
        IF (S = '') THEN
          S := '+';
        IF (StrToInt(S) > 0) THEN
        BEGIN
          I := StrToInt(S);
          IF ((I > 0) AND (I <= TotalLines)) THEN
          BEGIN
            WHILE (I <> CurLine) DO
              IF (I < CurLine) THEN
              BEGIN
                IF (Cur = NIL) THEN
                BEGIN
                  Cur := Bottom;
                  CurLine := TotalLines;
                END
                ELSE
                BEGIN
                  Dec(CurLine);
                  Cur := Cur^.Last;
                END;
              END
              ELSE
              BEGIN
                Inc(CurLine);
                Cur := Cur^.Next;
              END;
              PL;
          END;
        END
        ELSE
          CASE S[1] of
            '?' : BEGIN
                    LCmds(14,3,'+Forward line','-Back line');
                    LCmds(14,3,'Top','Bottom');
                    LCmds(14,3,'Print line','List');
                    LCmds(14,3,'Insert lines','Delete line');
                    LCmds(14,3,'Replace line','Clear all');
                    LCmds(14,3,'Quit (Abort)','Save');
                    LCmds(14,3,'*Center line','!Memory Available');
                  END;
            '!' : Print('Heap space available: '+IntToStr(MemAvail));
            '*' : IF (Cur <> NIL) THEN
                    Cur^.S := #2+Cur^.S;
            '+' : IF (Cur <> NIL) THEN
                  BEGIN
                    I := StrToInt(Copy(S,2,9));
                    IF (I = 0) THEN
                      I := 1;
                    WHILE (Cur <> NIL) AND (I > 0) DO
                    BEGIN
                      Cur := Cur^.Next;
                      Inc(CurLine);
                      Dec(I);
                    END;
                    PL;
                  END;
            '-' : BEGIN
                    I := StrToInt(Copy(S,2,9));
                    IF (I = 0) THEN
                      I := 1;
                    IF (Cur = NIL) THEN
                    BEGIN
                      Cur := Bottom;
                      CurLine := TotalLines;
                      Dec(I);
                    END;
                    IF (Cur <> NIL) THEN
                      IF (Cur^.Last <> NIL) THEN
                      BEGIN
                        WHILE ((Cur^.Last <> NIL) AND (I > 0)) DO
                        BEGIN
                          Cur := Cur^.Last;
                          Dec(CurLine);
                         Dec(I);
                        END;
                        PL;
                      END;
                  END;
            'B' : BEGIN
                    Cur := NIL;
                    CurLine := (TotalLines + 1);
                    PL;
                  END;
            'C' : IF PYNQ('Clear workspace? ',0,FALSE) THEN
                  BEGIN
                    TotalLines := 0;
                    CurLine := 1;
                    Cur := NIL;
                    Top := NIL;
                    Bottom := NIL;
{$IFDEF MSDOS}
                    Release(TopHeap);
{$ENDIF}
{$IFDEF WIN32}
  // REETODO Likely going to leak memory right about now
{$ENDIF}
                  END;
            'D' : BEGIN
                    I := StrToInt(Copy(S,2,9));
                    IF (I = 0) THEN
                      I := 1;
                    WHILE (Cur <> NIL) AND (I > 0) DO
                    BEGIN
                      Las := Cur^.Last;
                      Nex := Cur^.Next;
                      IF (Las <> NIL) THEN
                        Las^.Next := Nex;
                      IF (Nex <> NIL) THEN
                        Nex^.Last := Las;
                      OldPtr(Cur);
                      IF (Bottom = Cur) THEN
                        Bottom := Las;
                      IF (Top = Cur) THEN
                        Top := Nex;
                      Cur := Nex;
                      Dec(TotalLines);
                      Dec(I);
                    END;
                    PL;
                  END;
            'I' : BEGIN
                    Abort := FALSE;
                    Next := FALSE;
                    LastLineStr := '';
                    NL;
                    Print('   Enter "." on a separate line to exit insert mode.');
                    IF (OkANSI OR OkAvatar) THEN
                      Print('^2   อออออออออออออออออออออออออออออออออออออออออออออออออ^1');
                    Dec(ThisUser.LineLen,6);
                    S := '';
                    WHILE (S <> '.') AND (S <> '.'+#1) AND (NOT Abort) AND (NOT HangUp) DO
                    BEGIN
                      Prompt(PadRightInt(CurLine,4)+': ');
                      InLi(S);
                      IF (S <> '.') AND (S <> '.'+#1) THEN
                      BEGIN
                        Abort := NOT NewPtr(Nex);
                        IF (Abort) THEN
                          Print('Out of space.')
                        ELSE
                        BEGIN
                          Nex^.S := S;
                          IF (Top = Cur) THEN
                            IF (Cur = NIL) THEN
                            BEGIN
                              Nex^.Last := NIL;
                              Nex^.Next := NIL;
                              Top := Nex;
                              Bottom := Nex;
                            END
                            ELSE
                            BEGIN
                              Nex^.Next := Cur;
                              Cur^.Last := Nex;
                              Top := Nex;
                            END
                          ELSE
                          BEGIN
                            IF (Cur = NIL) THEN
                            BEGIN
                              Bottom^.Next := Nex;
                              Nex^.Last := Bottom;
                              Nex^.Next := NIL;
                              Bottom := Nex;
                            END
                            ELSE
                            BEGIN
                              Las := Cur^.Last;
                              Nex^.Last := Las;
                               Nex^.Next := Cur;
                              Cur^.Last := Nex;
                              Las^.Next := Nex;
                            END;
                          END;
                          Inc(CurLine);
                          Inc(TotalLines);
                        END
                      END;
                    END;
                    Inc(ThisUser.LineLen,6);
                  END;
            'L' : BEGIN
                    Abort := FALSE;
                    Next := FALSE;
                    Nex := Cur;
                    I := CurLine;
                    WHILE (Nex <> NIL) AND (NOT Abort) AND (NOT HangUp) DO
                    BEGIN
                      PLine(I,Nex);
                      Nex := Nex^.Next;
                      Inc(I);
                    END;
                  END;
            'P' : PL;
            'R' : IF (Cur <> NIL) THEN
                  BEGIN
                    PL;
                    Prompt(PadRightInt(CurLine,4)+': ');
                    InLi(S);
                    Cur^.S := S;
                  END;
            'Q' : Done := TRUE;
            'S' : BEGIN
                    IF (NOT AllRead) THEN
                    BEGIN
                      UserColor(5);
                      Prompt('Not all of file read.  ');
                      AllRead := PYNQ('Save anyway? ',0,FALSE);
                    END;
                    IF (AllRead) THEN
                    BEGIN
                      Done := TRUE;
                      Print('Saving ...');
                      SysOpLog('Saved "'+FSpec+'"');
                      ReWrite(Fil);
                      I := 0;
                      Cur := Top;
                      WHILE (Cur <> NIL) DO
                      BEGIN
                        WriteLn(Fil,Cur^.S);
                        Cur := Cur^.Next;
                        Dec(I);
                      END;

                      IF (I = 0) THEN
                        WriteLn(Fil);

                      Close(Fil);
                    END;
                  END;
            'T' : BEGIN
                    Cur := Top;
                    CurLine := 1;
                    PL;
                  END;
          END;
      UNTIL ((Done) OR (HangUp));
    END;
  END;
{$IFDEF MSDOS}  
  Release(TopHeap);
{$ENDIF}
{$IFDEF WIN32}
  // REETODO Likely going to leak memory right about now
{$ENDIF}
  PrintingFile := FALSE;
  LastError := IOResult;
END;

END.
