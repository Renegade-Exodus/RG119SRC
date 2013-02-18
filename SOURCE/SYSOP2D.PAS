{$IFDEF WIN32}
{$I DEFINES.INC}
{$ENDIF}

{$A+,B-,D-,E-,F+,I-,L-,N-,O+,R-,S+,V-}

UNIT SysOp2D;

INTERFACE

PROCEDURE SystemGeneralVariables;

IMPLEMENTATION

USES
  Common;

PROCEDURE SystemGeneralVariables;
VAR
  Cmd: Char;
  TempB,
  MinByte,
  MaxByte: Byte;
  TempI,
  MinInt,
  MaxInt: SmallInt;
  TempL,
  MinLongInt,
  MaxLongInt: LongInt;

  FUNCTION DisplaySwapTo(SwapTo: Byte): Str4;
  BEGIN
    CASE SwapTo OF
      0   : DisplaySwapTo := 'Disk';
      1   : DisplaySwapTo := 'XMS';
      2   : DisplaySwapTo := 'EMS';
      4   : DisplaySwapTo := 'EXT';
      255 : DisplaySwapTo := 'Any';
    END;
  END;

  PROCEDURE DisplayMacroo(CONST S: AStr; MaxLen: Byte);
  VAR
    TempStr: AStr;
    Counter: Byte;
  BEGIN
    TempStr := '';
    Prompt('^5"^1');
    FOR Counter := 1 TO Length(S) DO
      IF (S[Counter] >= ' ') THEN
        TempStr := TempStr + S[Counter]
      ELSE
        TempStr := TempStr +  '^3^'+Chr(Ord(S[Counter]) + 64)+'^1';
    Prompt(PadLeftStr(TempStr,MaxLen)+'^5"');
  END;

  PROCEDURE MMacroo(MacroNum: Byte);
  VAR
    S: AStr;
    C: Char;
    Counter: Byte;
  BEGIN
    Print('%CL^5Enter new F'+IntToStr(MacroNum + 1)+' macro now.');
    Print('^5Enter ^Z to end recording. 100 character limit.%LF');
    S := '';
    Counter := 1;
    REPEAT
      C := Char(GetKey);
      IF (C = ^H) THEN
      BEGIN
        C := #0;
        IF (Counter >= 2) THEN
        BEGIN
          BackSpace;
          Dec(Counter);
          IF (S[Counter] < #32) THEN
            BackSpace;
        END;
      END;
      IF (Counter <= 100) AND (C <> #0) THEN
      BEGIN
        IF (C IN [#32..#255]) THEN
        BEGIN
          OutKey(C);
          S[Counter] := C;
          Inc(Counter);
        END
        ELSE IF (C IN [^A,^B,^C,^D,^E,^F,^G,^H,^I,^J,^K,^L,^M,^N,^P,^Q,^R,^S,^T,^U,^V,^W,^X,^Y,#27,#28,#29,#30,#31]) THEN
        BEGIN
          IF (C = ^M) THEN
            NL
          ELSE
            Prompt('^3^'+Chr(Ord(C) + 64)+'^1');
          S[Counter] := C;
          Inc(Counter);
        END;
      END;
    UNTIL ((C = ^Z) OR (HangUp));
    S[0] := Chr(Counter - 1);
    Print('%LF%LF^3Your F'+IntToStr(MacroNum + 1)+' macro is now:%LF');
    DisplayMacroo(S,160);
    Com_Flush_Recv;
    IF (NOT PYNQ('%LFIs this what you want? ',0,FALSE)) THEN
      Print('%LFMacro not saved.')
    ELSE
    BEGIN
      General.Macro[MacroNum] := S;
      Print('%LFMacro saved.');
    END;
    PauseScr(FALSE);
  END;

BEGIN
  REPEAT
    WITH General DO
    BEGIN
      Abort := FALSE;
      Next := FALSE;
      Print('%CL^5System Variables:');
      NL;
      PrintACR('^1A. Max private sent per call: ^5'+PadLeftInt(MaxPrivPost,6)+
             '^1  B. Max feedback sent per call: ^5'+PadLeftInt(MaxFBack,6));
      PrintACR('^1C. Max public posts per call: ^5'+PadLeftInt(MaxPubPost,6)+
             '^1  D. Max chat attempts per call: ^5'+PadLeftInt(MaxChat,6));
      PrintACR('^1E. Normal max mail waiting  : ^5'+PadLeftInt(MaxWaiting,6)+
             '^1  F. CoSysOp max mail waiting  : ^5'+PadLeftInt(CSMaxWaiting,6));
      PrintACR('^1G. Max mass mail list       : ^5'+PadLeftInt(MaxMassMailList,6)+
             '^1  H. Logins before bday check  : ^5'+PadLeftInt(BirthDateCheck,6));
      PrintACR('^1I. Swap shell should use    : ^5'+PadLeftStr(DisplaySwapTo(SwapTo),6)+
             '^1  J. Number of logon attempts  : ^5'+PadLeftInt(MaxLogonTries,6));
      PrintACR('^1K. Password change in days  : ^5'+PadLeftInt(PasswordChange,6)+
             '^1  L. SysOp chat color          : ^5'+PadLeftInt(SysOpColor,6));
      PrintACR('^1M. User chat color          : ^5'+PadLeftInt(UserColor,6)+
             '^1  N. Min. space for posts      : ^5'+PadLeftInt(MinSpaceForPost,6));
      PrintACR('^1O. Min. space for uploads   : ^5'+PadLeftInt(MinSpaceForUpload,6)+
             '^1  P. Back SysOp Log keep days  : ^5'+PadLeftInt(BackSysOpLogs,6));
      PrintACR('^1R. Blank WFC menu minutes   : ^5'+PadLeftInt(WFCBlankTime,6)+
             '^1  S. Alert beep delay          : ^5'+PadLeftInt(AlertBeep,6));
      PrintACR('^1T. Number of system callers : ^5'+PadLeftInt(CallerNum,6)+
             '^1  U. Minimum logon baud rate   : ^5'+PadLeftInt(MinimumBaud,6));
      PrintACR('^1V. Minimum D/L baud rate    : ^5'+PadLeftInt(MinimumDLBaud,6)+
             '^1  W. Sec''s between Time Slices : ^5'+PadLeftInt(SliceTimer,6));
      PrintACR('^1X. TB max time allowed      : ^5'+PadLeftInt(MaxDepositEver,6)+
             '^1  Y. TB max per day deposit    : ^5'+PadLeftInt(MaxDepositPerDay,6));
      PrintACR('^1Z. TB max per day withdrawal: ^5'+PadLeftInt(MaxWithDrawalPerDay,6));
      NL;
      FOR TempB := 0 TO 9 DO
      BEGIN
        Prompt('^1'+IntToStr(TempB)+'. F'+IntToStr(TempB + 1)+' Macro :^5');
        DisplayMacroo(Macro[TempB],21);
        IF Odd(TempB) THEN
          NL
        ELSE
          Prompt('   ');
      END;
      Prt('%LFEnter selection [^5A^4-^5P^4,^5R^4-^5Z^4,^50^4-^59^4,^5Q^4=^5Quit^4]: ');
      OneK(Cmd,'QABCDEFGHIJKLMNOPRSTUVWXYZ1234567890'^M,TRUE,TRUE);
      CASE Cmd OF
        '0'..'9' :
              MMacroo(Ord(Cmd) - Ord('0'));
        'I' : BEGIN
                Print('%LF^5Swap locations:^1');
                Print('%LF^1(^3D^1)isk');
                Print('^1(^3E^1)MS');
                Print('^1(^3X^1)MS');
                Print('^1(^3N^1)on XMS Extended');
                Print('^1(^3A^1)ny');
                lOneK('%LFSwap to which? [^5D^4,^5E^4,^5X^4,^5N^4,^5A^4,^5<CR>^4=^5Quit^4]: ',Cmd,'DEXNA'^M,TRUE,TRUE);
                CASE Pos(Cmd,'DXENA') OF
                  1..3 : SwapTo := (Pos(Cmd,'DXE') - 1);
                     4 : SwapTo := 4;
                     5 : SwapTo := 255;
                END;
                Cmd := #0;
              END;
        'A'..'H','J'..'P','R'..'Z' :
              BEGIN
                CASE Cmd OF
                  'A' : BEGIN
                          MinByte := 0;
                          MaxByte := 255;
                          TempB := MaxPrivPost;
                        END;
                  'B' : BEGIN
                          MinByte := 0;
                          MaxByte := 255;
                          TempB := MaxFBack;
                        END;
                  'C' : BEGIN
                          MinByte := 0;
                          MaxByte := 255;
                          TempB := MaxPubPost;
                        END;
                  'D' : BEGIN
                          MinByte := 0;
                          MaxByte := 255;
                          TempB := MaxChat;
                        END;
                  'E' : BEGIN
                          MinByte := 0;
                          MaxByte := 255;
                          TempB := MaxWaiting;
                        END;
                  'F' : BEGIN
                          MinByte := 0;
                          MaxByte := 255;
                          TempB := CSMaxWaiting;
                        END;
                  'G' : BEGIN
                          MinByte := 2;
                          MaxByte := 255;
                          TempB := MaxMassMailList;
                        END;
                  'H' : BEGIN
                          MinInt := 0;
                          MaxInt := 365;
                          TempI := BirthDateCheck;
                        END;
                  'J' : BEGIN
                          MinByte := 0;
                          MaxByte := 255;
                          TempB := MaxLogonTries;
                        END;
                  'K' : BEGIN
                          MinInt := 0;
                          MaxInt := 32767;
                          TempI := PasswordChange;
                        END;
                  'L' : BEGIN
                          MinByte := 0;
                          MaxByte := 9;
                          TempB := SysOpColor;
                        END;
                  'M' : BEGIN
                          MinByte := 0;
                          MaxByte := 9;
                          TempB := UserColor;
                        END;
                  'N' : BEGIN
                          MinInt := 1;
                          MaxInt := 32767;
                          TempI := MinSpaceForPost;
                        END;
                  'O' : BEGIN
                          MinInt := 1;
                          MaxInt := 32767;
                          TempI := MinSpaceForUpload;
                        END;
                  'P' : BEGIN
                          MinByte := 1;
                          MaxByte := 255;
                          TempB := BackSysOpLogs;
                        END;
                  'R' : BEGIN
                          MinByte := 0;
                          MaxByte := 60;
                          TempB := WFCBlankTime;
                        END;
                  'S' : BEGIN
                          MinByte := 0;
                          MaxByte := 60;
                          TempB := AlertBeep;
                        END;
                  'T' : BEGIN
                          MinLongInt := 0;
                          MaxLongInt := 2147483647;
                          TempL := CallerNum;
                        END;
                  'U' : BEGIN
                          MinLongInt := 0;
                          MaxLongInt := 115200;
                          TempL := MinimumBaud;
                        END;
                  'V' : BEGIN
                          MinLongInt := 0;
                          MaxLongInt := 115200;
                          TempL := MinimumDLBaud;
                        END;
                  'W' : BEGIN
                          MinByte := 1;
                          MaxByte := 255;
                          TempB := SliceTimer;
                        END;
                  'X' : BEGIN
                          MinLongInt := 0;
                          MaxLongInt := 6000;
                          TempL := MaxDepositEver;
                        END;
                  'Y' : BEGIN
                          MinLongInt := 0;
                          MaxLongInt := 6000;
                          TempL := MaxDepositPerDay;
                        END;
                  'Z' : BEGIN
                          MinLongInt := 0;
                          MaxLongInt := 6000;
                          TempL := MaxWithdrawalPerDay
                        END;
                END;
                CASE Cmd OF
                  'H','K','N'..'O' :
                        InputIntegerWOC('%LFNew value',TempI,[NumbersOnly],MinInt,MaxInt);
                  'T'..'V','X'..'Z' :
                        InputLongIntWOC('%LFNew value',TempL,[DisplayValue,NumbersOnly],MinLongInt,MaxLongInt);
                ELSE
                  InputByteWOC('%LFNew value',TempB,[NumbersOnly],MinByte,MaxByte);
                END;
                CASE Cmd OF
                  'A' : MaxPrivPost := TempB;
                  'B' : MaxFBack := TempB;
                  'C' : MaxPubPost := TempB;
                  'D' : MaxChat := TempB;
                  'E' : MaxWaiting := TempB;
                  'F' : CSMaxWaiting := TempB; (* Not Hooked Up *)
                  'G' : MaxMassMailList := TempB;
                  'H' : BEGIN
                          BirthDateCheck := TempI;
                          (*
                          IF (BirthDateCheck = 0) THEN
                            NewUserToggles[9] := 0
                          ELSE
                            NewUserToggles[9] := 2;
                          *)
                        END;
                  'J' : MaxLogonTries := TempB;
                  'K' : PasswordChange := TempI;
                  'L' : SysOpColor := TempB;
                  'M' : UserColor := TempB;
                  'N' : MinSpaceForPost := TempI;
                  'O' : MinSpaceForUpload := TempI;
                  'P' : BackSysOpLogs := TempB;
                  'R' : WFCBlankTime := TempB;
                  'S' : AlertBeep := TempB;
                  'T' : CallerNum := TempL;
                  'U' : MinimumBaud := TempL;
                  'V' : MinimumDLBaud := TempL;
                  'W' : SliceTimer := TempB;
                  'X' : MaxDepositEver := TempL;
                  'Y' : MaxDepositPerDay := TempL;
                  'Z' : MaxWithDrawalPerDay := TempL;
                END;
              END;
      END;
    END;
  UNTIL (Cmd = 'Q') OR (HangUp);
END;

END.
