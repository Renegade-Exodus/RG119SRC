{$IFDEF WIN32}
{$I DEFINES.INC}
{$ENDIF}

{$A+,B-,D+,E-,F+,I-,L+,N-,O+,R-,S+,V-}

UNIT SysOp3;

INTERFACE

USES
  Common;

PROCEDURE ShowUserInfo(DisplayType: Byte; UNum: Integer; CONST User: UserRecordType);
PROCEDURE UserEditor(UNum: Integer);

IMPLEMENTATION

USES
  CUser,
  Mail0,
  Script,
  ShortMsg,
  SysOp2G,
  SysOp7,
  TimeFunc,
  MiscUser;

FUNCTION DisplayTerminalStr(StatusFlags: StatusFlagSet; Flags: FlagSet): Str8;
VAR
  TempS: Str8;
BEGIN
  IF (AutoDetect IN StatusFlags) THEN
    TempS := 'Auto'
  ELSE IF (RIP IN StatusFlags) THEN
    TempS := 'RIP'
  ELSE IF (Avatar IN Flags) THEN
    TempS := 'Avatar'
  ELSE IF (ANSI IN Flags) THEN
    TempS := 'Ansi'
  ELSE IF (OKVT100) THEN
    TempS := 'VT-100'
  ELSE
    TempS := 'None';
  DisplayTerminalStr := PadLeftStr(TempS,8);
END;

PROCEDURE ShowUserInfo(DisplayType: Byte; UNum: Integer; CONST User: UserRecordType);
VAR
  Counter: Byte;

  PROCEDURE ShowUser(VAR Counter1: Byte);
  VAR
    S: AStr;
  BEGIN
    WITH User DO
      CASE Counter1 OF
        1 : BEGIN
              IF (UNum = 0) THEN
                S := '^5New User Configuration:'
              ELSE
              BEGIN
                S := '^5User #'+IntToStr(UNum)+' of '+IntToStr(MaxUsers - 1);
                IF NOT (OnNode(UNum) IN [0,ThisNode]) THEN
                  S := PadLeftStr(S,45)+'^8Note: ^3User is on node '+IntToStr(OnNode(UNum));
              END;
              S := S + #13#10;
            END;
        2 : S := '^1A. User Name : ^3'+PadLeftStr(Name,29)+'^1 L. Security  : ^3'+IntToStr(SL);
        3 : S := '^1B. Real Name : ^3'+PadLeftStr(RealName,29)+'^1 M. D Security: ^3'+IntToStr(DSL);
        4 : S := '^1C. Address   : ^3'+PadLeftStr(Street,29)+'^1 N. AR: ^3'+DisplayARFlags(AR,'3','1');
        5 : S := '^1D. City/State: ^3'+PadLeftStr(CityState,29)+'^1 O. AC: ^3'+DisplayACFlags(Flags,'3','1');
        6 : S := '^1E. Zip code  : ^3'+PadLeftStr(ZipCode,29)+'^1 P. Sex/Age   : ^3'+
                                     Sex+IntToStr(AgeUser(BirthDate))+' ('+ToDate8(PD2Date(BirthDate))+')';
        7 : S := '^1F. SysOp note: ^3'+PadLeftStr(Note,29)+'^1 R. Phone num : ^3'+Ph;
        8 : S := '^1G. '+PadLeftStr(lRGLngStr(41,TRUE){FString.UserDefEd[1]},10)+': ^3'+PadLeftStr(UsrDefStr[1],29)+
                                                              '^1 T. Last/1st  : ^3'+ToDate8(PD2Date(LastOn))+
                                                              ' ('+ToDate8(PD2Date(FirstOn))+')';
        9 : BEGIN
              S := '^1H. '+PadLeftStr(lRGLngStr(42,TRUE){FString.UserDefEd[2]},10)+': ^3'+PadLeftStr(UsrDefStr[2],29)+
                   '^1 V. Locked out: '+AOnOff(LockedOut IN SFlags,'^7'+LockedFile+'.ASC','^3Inactive');
            END;
       10 : BEGIN
              S := '^1I. '+PadLeftStr(lRGLngStr(43,TRUE){FString.UserDefEd[3]},10)+': ^3'+PadLeftStr(UsrDefStr[3],29)+
                '^1 W. Password  : [Not Shown]';
            END;
       11 : BEGIN
              IF (Deleted IN SFlags) THEN
                S := '^8'
              ELSE
                S := '^1';
              S := S + '[DEL] ';
              IF (TrapActivity IN SFlags) AND ((UNum <> UserNum) OR (UserNum = 1)) THEN
                IF (TrapSeparate IN SFlags) THEN
                  S := S + '^8[TRP SEP] '
                ELSE
                  S := S + '^8[TRP COM] '
                ELSE
                  S := S + '^1[TRP OFF] ';
              IF (LockedOut IN SFlags) THEN
                S := S + '^8'
              ELSE
                S := S + '^1';
              S := S + '[LOCK] ';
              IF (Alert IN Flags) THEN
                S := S + '^8'
              ELSE
                S := S + '^1';
              S := S + '[ALRT] ';
              S := '^1J. Status    : ^3'+PadLeftStr(S,29)+'^1 X. Caller ID : ^3'+CallerID;
            END;
       12 : S := '^1K. QWK setup : ^3'+PadLeftStr(General.FileArcInfo[DefArcType].ext,29)+
                 '^1 Y. Start Menu: ^3'+IntToStr(UserStartMenu);
       13 : S := '^1Z. Forgot PW : ^3'+ForgotPWAnswer+#13#10;
       14 : S := '^11. Call records - TC: ^3'+PadLeftInt(LoggedOn,8)+
                                   ' ^1TT: ^3'+PadLeftInt(TTimeOn,8)+
                                   ' ^1CT: ^3'+PadLeftInt(OnToday,8)+
                                   ' ^1TL: ^3'+PadLeftInt(TLToday,8)+
                                   ' ^1TB: ^3'+IntToStr(TimeBank);
       15 : S := '^12. Mail records - PB: ^3'+PadLeftInt(MsgPost,8)+
                                   ' ^1PV: ^3'+PadLeftInt(EmailSent,8)+
                                   ' ^1FB: ^3'+PadLeftInt(FeedBack,8)+
                                   ' ^1WT: ^3'+IntToStr(Waiting);
       16 : S := '^13. File records - DL: ^3'+PadLeftStr(IntToStr(Downloads)+'-'+FormatNumber(DK)+'k',15)+
                                   ' ^1UL: ^3'+PadLeftStr(IntToStr(Uploads)+'-'+FormatNumber(UK)+'k',15)+
                                   ' ^1DT: ^3'+IntToStr(DLToday)+'-'+FormatNumber(DLKToday)+'k';
       17 : S := '                  ^1FP: ^3'+IntToStr(FilePoints);
       18 : S := '^14. Pref records - EM: ^3'+DisplayTerminalStr(SFlags,Flags)+
                                   ' ^1CS: ^3'+PadLeftStr(ShowYesNo(CLSMsg IN SFlags),8)+
                                   ' ^1PS: ^3'+PadLeftStr(ShowYesNo(Pause IN Flags),8)+
                                   ' ^1CL: ^3'+PadLeftStr(ShowYesNo(Color IN Flags),8)+
                                   ' ^1ED: ^3'+AOnOff((FSEditor IN SFlags),'F/S','Reg');
       19 : S := '^15. Subs records - CR: ^3'+PadLeftInt(lCredit,8)+
                                   ' ^1DB: ^3'+PadLeftInt(Debit,8)+
                                   ' ^1BL: ^3'+PadLeftInt(lCredit - Debit,8)+
                                   ' ^1ED: ^3'+AOnOff((Expiration > 0),ToDate8(PD2Date(Expiration)),'Never   ')+
                                   ' ^1ET: ^3'+AOnOff(ExpireTo <> ' ',ExpireTo,'None');
      END;
    PrintACR(S);
    Inc(Counter1);
  END;

BEGIN
  Abort := FALSE;
  Next := FALSE;
  CLS;
  Counter := 1;
  CASE DisplayType OF
    1 : WHILE (Counter <= 19) AND (NOT Abort) AND (NOT HangUp) DO
          ShowUser(Counter);
    2 : WHILE (Counter <= 5) AND (NOT Abort) AND (NOT HangUp) DO
          ShowUser(Counter);
  END;
END;

PROCEDURE UserEditor(UNum: Integer);
TYPE
  F_StatusFlagsRec = (FS_Deleted,FS_Trapping,FS_ChatBuffer,FS_LockedOut,FS_Alert,FS_SLogging);
CONST
  AutoList: Boolean = TRUE;
  UserInfoTyp: Byte = 1;
  F_State: ARRAY [0..14] OF Boolean = (FALSE,FALSE,FALSE,FALSE,FALSE,FALSE,FALSE,FALSE,
                                       FALSE,FALSE,FALSE,FALSE,FALSE,FALSE,FALSE);
  F_GenText: STRING[40] = '';
  F_ACS: STRING[20] = '';
  F_SL1: Byte = 0;
  F_SL2: Byte = 255;
  F_DSL1: Byte = 0;
  F_DSL2: Byte = 255;
  F_AR: ARFlagSet = [];
  F_AC: FlagSet = [];
  F_Status: SET OF F_StatusFlagsRec = [];
  F_LastOn1: LongInt = 0;
  F_LastOn2: LongInt = $FFFFFFF;
  F_FirstOn1: LongInt = 0;
  F_FirstOn2: LongInt = $FFFFFFF;
  F_NumCalls1: LongInt = 0;
  F_NumCalls2: LongInt = 2147483647;
  F_Age1: Byte = 0;
  F_Age2: Byte = 255;
  F_Gender: Char = 'M';
  F_PostRatio1: LongInt = 0;
  F_PostRatio2: LongInt = 2147483647;
  F_DLKRatio1: LongInt = 0;
  F_DLKRatio2: LongInt = 2147483647;
  F_DLRatio1: LongInt = 0;
  F_DLRatio2: LongInt = 2147483647;
VAR
  User: UserRecordType;
  TempStr: AStr;
  Cmd: Char;
  TempB,
  Counter: Byte;
  UNum1,
  SaveUNum,
  TempMaxUsers,
  RecNumToList: Integer;
  Changed,
  Save,
  Save1,
  Ok: Boolean;

  FUNCTION SearchType(SType: Byte): AStr;
  BEGIN
    CASE SType OF
      0 : SearchType := 'General text';
      1 : SearchType := 'Search ACS';
      2 : SearchType := 'User SL';
      3 : SearchType := 'User DSL';
      4 : SearchType := 'User AR Flags';
      5 : SearchType := 'User AC Flags';
      6 : SearchType := 'User status';
      7 : SearchType := 'Date since last on';
      8 : SearchType := 'Date since first on';
      9 : SearchType := 'Number of calls';
     10 : SearchType := 'User age';
     11 : SearchType := 'User gender';
     12 : SearchType := '# 1/10''s call/post';
     13 : SearchType := '#k DL/1k UL';
     14 : SearchType := '# DLs/1 UL';
    END;
  END;

  FUNCTION Find_FS: AStr;
  VAR
    FSF: F_StatusFlagsRec;
    TempStr1: AStr;
  BEGIN
    TempStr1 := '';
    FOR FSF := FS_Deleted TO FS_SLogging DO
      IF (FSF IN F_Status) THEN
        CASE FSF OF
          FS_Deleted   : TempStr1 := TempStr1 +'Deleted,';
          FS_Trapping  : TempStr1 := TempStr1 +'Trapping,';
          FS_ChatBuffer: TempStr1 := TempStr1 +'Chat Buffering,';
          FS_LockedOut : TempStr1 := TempStr1 +'Locked Out,';
          FS_Alert     : TempStr1 := TempStr1 +'Alert,';
          FS_SLogging  : TempStr1 := TempStr1 +'Sep. SysOp Log,';
        END;
    IF (TempStr1 <> '') THEN
      TempStr1 := Copy(TempStr1,1,(Length(TempStr1) - 1))
    ELSE
      TempStr1 := 'None.';
    Find_FS := TempStr1;
  END;

  PROCEDURE DisplaySearchOptions;
  VAR
    TempStr1: AStr;
    Cmd1: Char;
    Counter1: Byte;
  BEGIN
    Print('^5Search Criterea:^1');
    NL;
    Abort := FALSE;
    Next := FALSE;
    Counter1 := 0;
    WHILE ((Counter1 <= 14) AND (NOT Abort) AND (NOT HangUp)) DO
    BEGIN
      CASE Counter1 OF
        0..9 :
             Cmd1 := Chr(Counter1 + 48);
        10 : Cmd1 := 'A';
        11 : Cmd1 := 'G';
        12 : Cmd1 := 'P';
        13 : Cmd1 := 'K';
        14 : Cmd1 := 'N';
      END;
      Prompt('^1'+Cmd1+'. '+PadLeftStr(SearchType(Counter1),19)+': ');
      TempStr1 := '';
      IF (NOT F_State[Counter1]) THEN
        TempStr1 := '^5<INACTIVE>'
      ELSE
      BEGIN
        CASE Counter1 OF
          0 : TempStr1 := '"'+F_GenText+'"';
          1 : TempStr1 := '"'+F_ACS+'"';
          2 : TempStr1 := IntToStr(F_SL1)+' SL ... '+IntToStr(F_SL2)+' SL';
          3 : TempStr1 := IntToStr(F_DSL1)+' DSL ... '+IntToStr(F_DSL2)+' DSL';
          4 : TempStr1 := DisplayARFlags(F_AR,'3','1');
          5 : TempStr1 := DisplayACFlags(F_AC,'3','1');
          6 : TempStr1 := Find_FS;
          7 : TempStr1 := PD2Date(F_LastOn1)+' ... '+PD2Date(F_LastOn2);
          8 : TempStr1 := PD2Date(F_FirstOn1)+' ... '+PD2Date(F_FirstOn2);
          9 : TempStr1 := IntToStr(F_NumCalls1)+' calls ... '+IntToStr(F_NumCalls2)+' calls';
         10 : TempStr1 := IntToStr(F_Age1)+' years ... '+IntToStr(F_Age2)+' years';
         11 : TempStr1 := AOnOff(F_Gender = 'M','Male','Female');
         12 : TempStr1 := IntToStr(F_PostRatio1)+' ... '+IntToStr(F_PostRatio2);
         13 : TempStr1 := IntToStr(F_DLKRatio1)+' ... '+IntToStr(F_DLKRatio2);
         14 : TempStr1 := IntToStr(F_DLRatio1)+' ... '+IntToStr(F_DLRatio2);
        END;
        UserColor(3);
      END;
      Print(TempStr1);
      WKey;
      Inc(Counter1);
    END;
  END;

  FUNCTION OKUser(UNum1: Integer): Boolean;
  VAR
    FSF: F_StatusFlagsRec;
    User1: UserRecordType;
    Counter1: Byte;
    TempL: LongInt;
    Ok1: Boolean;

    FUNCTION NoFindIt(TempStr1: AStr): Boolean;
    BEGIN
      NoFindIt := (Pos(AllCaps(F_GenText),AllCaps(TempStr1)) = 0);
    END;

  BEGIN
    WITH User1 DO
    BEGIN
      LoadURec(User1,UNum1);
      Ok1 := TRUE;
      Counter1 := 0;
      WHILE ((Counter1 <= 14) AND (Ok1)) DO
      BEGIN
        IF (F_State[Counter1]) THEN
          CASE Counter1 OF
            0 : IF ((NoFindIt(Name)) AND (NoFindIt(RealName)) AND
                   (NoFindIt(Street)) AND (NoFindIt(CityState)) AND
                   (NoFindIt(ZipCode)) AND (NoFindIt(UsrDefStr[1])) AND
                   (NoFindIt(Ph)) AND (NoFindIt(Note)) AND
                   (NoFindIt(UsrDefStr[2])) AND (NoFindIt(UsrDefStr[3]))) THEN
                  Ok1 := FALSE;
            1 : IF (NOT AACS1(User1,UNum1,F_ACS)) THEN
                  Ok1 := FALSE;
            2 : IF ((SL < F_SL1) OR (SL > F_SL2)) THEN
                  Ok1 := FALSE;
            3 : IF ((DSL < F_DSL1) OR (DSL > F_DSL2)) THEN
                  Ok1 := FALSE;
            4 : IF (NOT (AR >= F_AR)) THEN
                  Ok1 := FALSE;
            5 : IF (NOT (Flags >= F_AC)) THEN
                  Ok1 := FALSE;
            6 : FOR FSF := FS_Deleted TO FS_SLogging DO
                  IF (FSF IN F_Status) THEN
                    CASE FSF OF
                      FS_Deleted    : IF NOT (Deleted IN User1.SFlags) THEN
                                        Ok1 := FALSE;
                      FS_Trapping   : IF NOT (TrapActivity IN User1.SFlags) THEN
                                        Ok1 := FALSE;
                      FS_ChatBuffer : IF NOT (ChatAuto IN User1.SFlags) THEN
                                        Ok1 := FALSE;
                      FS_LockedOut  : IF NOT (LockedOut IN User1.SFlags) THEN
                                        Ok1 := FALSE;
                      FS_Alert      : IF NOT ((Alert IN Flags)) THEN
                                        Ok1 := FALSE;
                      FS_SLogging   : IF NOT (SLogSeparate IN User1.SFlags) THEN
                                        Ok1 := FALSE;
                    END;
            7 : IF ((LastOn < F_LastOn1) OR (LastOn > F_LastOn2)) THEN
                  Ok1 := FALSE;
            8 : IF ((FirstOn < F_FirstOn1) OR (FirstOn > F_FirstOn2)) THEN
                  Ok1 := FALSE;
            9 : IF ((LoggedOn < F_NumCalls1) OR (LoggedOn > F_NumCalls2)) THEN
                  Ok1 := FALSE;
           10 : IF (((AgeUser(BirthDate) < F_Age1) OR (AgeUser(BirthDate) > F_Age2)) AND (AgeUser(BirthDate) <> 0)) THEN
                  Ok1 := FALSE;
           11 : IF (Sex <> F_Gender) THEN
                  Ok1 := FALSE;
           12 : BEGIN
                  IF (LoggedOn > 0) THEN
                    TempL := LoggedOn
                  ELSE
                    TempL := 1;
                  TempL := ((MsgPost DIV TempL) * 100);
                  IF ((TempL < F_PostRatio1) OR (TempL > F_PostRatio2)) THEN
                    Ok1 := FALSE;
                END;
           13 : BEGIN
                  IF (UK > 0) THEN
                    TempL := UK
                  ELSE
                    TempL := 1;
                  TempL := (DK DIV TempL);
                  IF ((TempL < F_DLKRatio1) OR (TempL > F_DLKRatio2)) THEN
                    Ok1 := FALSE;
                END;
           14 : BEGIN
                  IF (Uploads > 0) THEN
                    TempL := Uploads
                  ELSE
                    TempL := 1;
                  TempL := (Downloads DIV TempL);
                  IF ((TempL < F_DLRatio1) OR (TempL > F_DLRatio2)) THEN
                    Ok1 := FALSE;
                END;
          END;
        Inc(Counter1);
      END;
    END;
    OKUser := Ok1;
  END;

  PROCEDURE Search(i: Integer);
  VAR
    n,
    TempMaxUsers: Integer;
  BEGIN
    Prompt('Searching ... ');
    Reset(UserFile);
    TempMaxUsers := (MaxUsers - 1);
    n := UNum;
    REPEAT
      Inc(UNum,i);
      IF (UNum < 1) THEN
        UNum := TempMaxUsers;
      IF (UNum > TempMaxUsers) THEN
        UNum := 1;
    UNTIL ((OKUser(UNum)) OR (UNum = n));
    Close(UserFile);
  END;

  PROCEDURE Clear_F;
  VAR
    Counter1: Byte;
  BEGIN
    FOR Counter1 := 0 TO 14 DO
      F_State[Counter1] := FALSE;
    F_GenText := '';
    F_ACS := '';
    F_SL1 := 0;
    F_SL2 := 255;
    F_DSL1 := 0;
    F_DSL2 := 255;
    F_AR := [];
    F_AC := [];
    F_Status := [];
    F_LastOn1 := 0;
    F_LastOn2 := $FFFFFFF;
    F_FirstOn1 := 0;
    F_FirstOn2 := $FFFFFFF;
    F_NumCalls1 := 0;
    F_NumCalls2 := 2147483647;
    F_Age1 := 0;
    F_Age2 := 255;
    F_Gender := 'M';
    F_PostRatio1 := 0;
    F_PostRatio2 := 2147483647;
    F_DLKRatio1 := 0;
    F_DLKRatio2 := 2147483647;
    F_DLRatio1 := 0;
    F_DLRatio2 := 2147483647;
  END;

  PROCEDURE UserSearch;
  VAR
    User1: UserRecordType;
    FSF: F_StatusFlagsRec;
    TempStr1: AStr;
    Cmd1: Char;
    SType,
    UNum1,
    UserCount: Integer;
    Changed1: Boolean;
  BEGIN
    DisplaySearchOptions;
    REPEAT
      NL;
      Prt('Change [^5?^4=^5Help^4]: ');
      OneK(Cmd1,'Q0123456789AGPKNCLTU?'^M,TRUE,TRUE);
      NL;
      CASE Cmd1 OF
        '0'..'9' :
              SType := (Ord(Cmd1) - 48);
        'A' : SType := 10;
        'G' : SType := 11;
        'P' : SType := 12;
        'K' : SType := 13;
        'N' : SType := 14;
      ELSE
        SType := -1;
      END;
      IF (SType <> -1) THEN
      BEGIN
        Prompt('^5[>^0 ');
        IF (F_State[SType]) THEN
          Print(SearchType(SType)+'^1')
        ELSE
        BEGIN
          F_State[SType] := TRUE;
          Print(SearchType(SType)+' is now *ON*^1');
        END;
        NL;
      END;
      CASE Cmd1 OF
        '0' : BEGIN
                Print('General text ["'+F_GenText+'"]');
                Prt(': ');
                MPL(40);
                Input(TempStr1,40);
                IF (TempStr1 <> '') THEN
                  F_GenText := TempStr1;
              END;
        '1' : BEGIN
                Print('Search ACS ["'+F_ACS+'"]');
                Prt(': ');
                MPL(20);
                InputL(TempStr1,20);
                IF (TempStr1 <> '') THEN
                  F_ACS := TempStr1;
              END;
        '2' : BEGIN
                InputByteWOC('Lower limit',F_SL1,[DisplayValue,NumbersOnly],0,255);
                InputByteWOC('%LFUpper limit',F_SL2,[DisplayValue,NumbersOnly],(0 + F_SL1),255);
              END;
        '3' : BEGIN
                InputByteWOC('Lower limit',F_DSL1,[DisplayValue,NumbersOnly],0,255);
                InputByteWOC('%LFUpper limit',F_DSL2,[DisplayValue,NumbersOnly],(0 + F_DSL1),255);
              END;
        '4' : BEGIN
                REPEAT
                  Prt('Toggle which AR flag? ('+DisplayArFlags(F_AR,'5','4')+'^4) [^5?^4=^5Help^4,^5<CR>^4=^5Quit^4]: ');
                  OneK(Cmd1,^M'ABCDEFGHIJKLMNOPQRSTUVWXYZ?',TRUE,TRUE);
                  IF (Cmd1 = '?') THEN
                    PrintF('ARFLAGS')
                  ELSE IF (Cmd1 <> ^M) THEN
                    ToggleARFlag(Cmd1,F_AR,Changed);
                UNTIL ((Cmd1 = ^M) OR (HangUp));
                Cmd1 := #0;
              END;
        '5' : BEGIN
                REPEAT
                  Prt('Toggle which AC flag? ['+DisplayACFlags(F_AC,'5','4')+'] [?]Help: ');
                  OneK(Cmd1,^M'LCVUA*PEKM1234?',TRUE,TRUE);
                  IF (Cmd1 = '?') THEN
                    PrintF('ACFLAGS')
                  ELSE IF (Cmd1 <> ^M) THEN
                    ToggleACFlags(Cmd1,F_AC,Changed1);
                UNTIL (Cmd1 = ^M) OR (HangUp);
                Cmd1 := #0;
              END;
        '6' : BEGIN
                REPEAT
                  Print('^4Current flags: ^3'+Find_FS);
                  NL;
                  Prt('Toggle which status flag? (^5?^4=^5Help^4): ');
                  OneK(Cmd1,'QACDLST? '^M,TRUE,TRUE);
                  CASE Cmd1 OF
                    'A' : FSF := FS_Alert;
                    'C' : FSF := FS_ChatBuffer;
                    'D' : FSF := FS_Deleted;
                    'L' : FSF := FS_LockedOut;
                    'S' : FSF := FS_SLogging;
                    'T' : FSF := FS_Trapping;
                    '?' : BEGIN
                            NL;
                            LCmds(15,3,'Alert','Chat-buffering');
                            LCmds(15,3,'Deleted','Locked-out');
                            LCmds(15,3,'Separate SysOp logging','Trapping');
                          END;
                    END;
                    IF (Cmd1 IN ['A','C','D','L','S','T']) THEN
                      IF (FSF IN F_Status) THEN
                        Exclude(F_Status,FSF)
                      ELSE
                        Include(F_Status,FSF);
                UNTIL ((Cmd1 IN ['Q',' ',^M]) OR (HangUp));
                Cmd1 := #0;
              END;
        '7' : BEGIN
                Prt('Starting date: ');
                MPL(10);
                InputFormatted('',TempStr1,'##/##/####',TRUE);
                F_LastOn1 := Date2PD(TempStr1);
                NL;
                Prt('Ending date: ');
                MPL(10);
                InputFormatted('',TempStr1,'##/##/####',TRUE);
                F_LastOn2 := Date2PD(TempStr1);
              END;
        '8' : BEGIN
                Prt('Starting date: ');
                MPL(10);
                InputFormatted('',TempStr1,'##/##/####',TRUE);
                F_FirstOn1 := Date2PD(TempStr1);
                NL;
                Prt('Ending date: ');
                MPL(10);
                InputFormatted('',TempStr1,'##/##/####',TRUE);
                F_FirstOn2 := Date2PD(TempStr1);
              END;
        '9' : BEGIN
                InputLongIntWOC('%LFLower limit',F_NumCalls1,[DisplayValue,NumbersOnly],0,2147483647);
                InputLongIntWOC('%LFUpper limit',F_NumCalls2,[DisplayValue,NumbersOnly],(0 + F_NumCalls1),2147483647);
              END;
        'A' : BEGIN
                InputByteWOC('Lower limit',F_Age1,[DisplayValue,NumbersOnly],0,255);
                InputByteWOC('%LFUpper limit',F_Age2,[displayValue,NumbersOnly],(0 + F_Age1),255);
              END;
        'G' : BEGIN
                Prt('Gender ['+F_Gender+']: ');
                OneK(Cmd1,^M'MF',TRUE,TRUE);
                IF (Cmd1 IN ['F','M']) THEN
                  F_Gender := Cmd1;
              END;
        'P' : BEGIN
                InputLongIntWOC('%LFLower limit',F_PostRatio1,[DisplayValue,NumbersOnly],0,2147483647);
                InputLongIntWOC('%LFUpper limit',F_PostRatio2,[DisplayValue,NumbersOnly],(0 + F_PostRatio1),2147483647);
              END;
        'K' : BEGIN
                InputLongIntWOC('%LFLower limit',F_DLKRatio1,[DisplayValue,NumbersOnly],0,2147483647);
                InputLongIntWOC('%LFUpper limit',F_DLKRatio2,[DisplayValue,NumbersOnly],(0 + F_DLKRatio1),2147483647);
              END;
        'N' : BEGIN
                InputLongIntWOC('%LFLower limit',F_DLRatio1,[DisplayValue,NumbersOnly],0,2147483647);
                InputLongIntWOC('%LFUpper limit',F_DLRatio2,[DisplayValue,NumbersOnly],(0 + F_DLRatio1),2147483647);
              END;
        'C' : IF PYNQ('Are you sure? ',0,FALSE) THEN
                Clear_F;
        ^M,'L' :
              DisplaySearchOptions;
        'T' : BEGIN
                Prt('Which (0-9,A,G,P,K,N)? [Q]=Quit]: ');
                OneK(Cmd1,'Q0123456789AGPKN'^M,TRUE,TRUE);
                NL;
                CASE Cmd1 OF
                  '0'..'9' :
                        SType := (Ord(Cmd1) - 48);
                  'A' : SType := 10;
                  'G' : SType := 11;
                  'P' : SType := 12;
                  'K' : SType := 13;
                  'N' : SType := 14;
                ELSE
                  SType := -1;
                END;
                IF (SType <> -1) THEN
                BEGIN
                  F_State[SType] := NOT F_State[SType];
                  Prompt('^5[>^0 '+SearchType(SType)+' is now *'+AonOff(F_State[SType],'ON','OFF')+'*^1');
                  NL;
                END;
                Cmd1 := #0;
              END;
        'U' : BEGIN
                Abort := FALSE;
                Next := FALSE;
                Reset(UserFile);
                UserCount := 0;
                TempMaxUsers := (MaxUsers - 1);
                UNum1 := 1;
                WHILE (UNum1 <= TempMaxUsers) AND (NOT Abort) AND (NOT HangUp) DO
                BEGIN
                  IF (OKUser(UNum1)) THEN
                  BEGIN
                    LoadURec(User1,UNum1);
                    PrintACR('^3'+Caps(User1.Name)+' #'+IntToStr(UNum1));
                    Inc(UserCount);
                  END;
                  Inc(UNum1);
                END;
                Close(UserFile);
                IF (NOT Abort) THEN
                BEGIN
                  NL;
                  Print('^7 ** ^5'+IntToStr(UserCount)+' Users.^1');
                END;
              END;
        '?' : BEGIN
                Print('^30-9,AGPKN^1: Change option');
                LCmds(14,3,'List options','Toggle options on/off');
                LCmds(14,3,'Clear options','User''s who match');
                LCmds(14,3,'Quit','');
              END;
      END;
    UNTIL (Cmd1 = 'Q') OR (HangUp);
  END;

  PROCEDURE KillUserMail;
  VAR
    User1: UserRecordType;
    MHeader: MHeaderRec;
    SaveReadMsgArea: Integer;
    MsgNum: Word;
  BEGIN
    SaveReadMsgArea := ReadMsgArea;
    InitMsgArea(-1);
    Reset(MsgHdrF);
    FOR MsgNum := 1 TO HiMsg DO
    BEGIN
      LoadHeader(MsgNum,MHeader);
      IF (NOT (MDeleted IN MHeader.Status)) AND ((MHeader.MTO.UserNum = UNum) OR (MHeader.From.UserNum = UNum)) THEN
      BEGIN
        Include(MHeader.Status,MDeleted);
        SaveHeader(MsgNum,MHeader);
        LoadURec(User1,MHeader.MTO.UserNum);
        IF (User1.Waiting > 0) THEN
          Dec(User1.Waiting);
        SaveURec(User1,MHeader.MTO.UserNum);
        Reset(MsgHdrF);
      END;
    END;
    Close(MsgHdrF);
    InitMsgArea(SaveReadMsgArea);
  END;

  PROCEDURE KillUserVotes;
  VAR
    Counter1: Byte;
  BEGIN
    Assign(VotingFile,General.DataPath+'VOTING.DAT');
    Reset(VotingFile);
    IF (IOResult = 0) THEN
    BEGIN
      FOR Counter1 := 1 TO FileSize(VotingFile) DO
        IF (User.Vote[Counter1] > 0) THEN
        BEGIN
          Seek(VotingFile,(Counter1 - 1));
          Read(VotingFile,Topic);
          Dec(Topic.Answers[User.Vote[Counter1]].NumVotedAnswer);
          Dec(Topic.NumVotedQuestion);
          Seek(VotingFile,(Counter1 - 1));
          Write(VotingFile,Topic);
          User.Vote[Counter1] := 0;
        END;
      Close(VotingFile);
    END;
    LastError := IOResult;
  END;

  PROCEDURE ChangeRecords(On: Byte);
  VAR
    OneKCmds: AStr;
    Cmd1: Char;
    TempL1: LongInt;
  BEGIN
    WITH User DO
      REPEAT
        NL;
        CASE on OF
          1 : BEGIN
                Print('^5Call records:^1');
                NL;
                Print('^11. Total calls    : ^5'+IntToStr(LoggedOn));
                Print('^12. Total time on  : ^5'+IntToStr(TTimeOn));
                Print('^13. Calls today    : ^5'+IntToStr(OnToday));
                Print('^14. Time left today: ^5'+IntToStr(TLToday));
                Print('^15. Ill. logons    : ^5'+IntToStr(Illegal));
                Print('^16. Time Bank      : ^5'+IntToStr(TimeBank));
                NL;
                Prt('Select: (1-6) [M]ail [F]ile [P]ref [S]ubs: ');
                OneK(Cmd1,^M'123456MFPS',TRUE,TRUE);
              END;
          2 : BEGIN
                Print('^5Mail records:^1');
                NL;
                Print('^11. Pub. posts  : ^5'+IntToStr(MsgPost));
                Print('^12. Priv. posts : ^5'+IntToStr(EmailSent));
                Print('^13. Fback sent  : ^5'+IntToStr(FeedBack));
                Print('^14. Mail Waiting: ^5'+IntToStr(Waiting));
                NL;
                Prt('Select: (1-4) [C]all [F]ile [P]ref [S]ubs: ');
                OneK(Cmd1,^M'1234CFPS',TRUE,TRUE);
              END;
          3 : BEGIN
                Print('^5File records:^1');
                NL;
                Print('^11. # of DLs   : ^5'+IntToStr(Downloads));
                Print('^12. DL K       : ^5'+FormatNumber(DK)+'k');
                Print('^13. # of ULs   : ^5'+IntToStr(Uploads));
                Print('^14. UL K       : ^5'+FormatNumber(UK)+'k');
                Print('^15. # DLs today: ^5'+IntToStr(DLToday));
                Print('^16. DL K today : ^5'+FormatNumber(DLKToday)+'k');
                Print('^17. File Points: ^5'+FormatNumBer(FilePoints));
                NL;
                Prt('Select: (1-7) [C]all [M]ail [P]ref [S]ubs: ');
                OneK(Cmd1,^M'1234567CMPS',TRUE,TRUE);
              END;
          4 : BEGIN
                Print('^5Preference records:^1');
                NL;
                Print('^11. Emulation: ^5'+DisplayTerminalStr(SFlags,Flags));
                Print('^12. Clr Scrn : ^5'+AOnOff((CLSMsg IN SFlags),'On','Off'));
                Print('^13. Pause    : ^5'+AOnOff((Pause IN Flags),'On','Off'));
                Print('^14. Color    : ^5'+AOnOff((Color IN Flags),'On','Off'));
                Print('^15. Editor   : ^5'+AOnOff((FSEditor IN SFlags),'F/S','Reg'));
                NL;
                Prt('Select (1-5) [C]all [M]ail [F]ile [S]ubs: ');
                OneK(Cmd1,^M'12345CMFS',TRUE,TRUE);
              END;
          5 : BEGIN
                Print('^5Subscription records:^1');
                NL;
                Print('^11. Credit   : ^5'+IntToStr(lCredit));
                Print('^12. Debit    : ^5'+IntToStr(Debit));
                Print('^13. Expires  : ^5'+AOnOff(Expiration = 0,'Never',ToDate8(PD2Date(Expiration))));
                Print('^1   Expire to: ^5'+AOnOff(ExpireTo = ' ','None',ExpireTo));
                NL;
                Prt('Select: (1-3) [C]all [M]ail [P]ref [F]ile: ');
                OneK(Cmd1,^M'123CMPF',TRUE,TRUE);
              END;
        END;
        CASE Cmd1 OF
          'C' : on := 1;
          'M' : on := 2;
          'F' : on := 3;
          'P' : on := 4;
          'S' : on := 5;
          '1'..'7' :
                BEGIN
                  NL;
                  IF (on <> 4) THEN
                  BEGIN
                    IF (on <> 5) OR NOT (StrToInt(Cmd1) IN [3..4]) THEN
                    BEGIN
                      Prt('New value: ');
                      Input(TempStr,10);
                      TempL1 := StrToInt(TempStr);
                    END
                    ELSE
                      CASE StrToInt(Cmd1) OF
                        3 : IF (PYNQ('Reset expiration date & level? ',0,FALSE)) THEN
                            BEGIN
                              TempL1 := 0;
                              TempStr := ' ';
                            END
                            ELSE
                            BEGIN
                              NL;
                              Prt('New expiration date: ');
                              MPL(10);
                              InputFormatted('',TempStr,'##/##/####',TRUE);
                              IF (TempStr <> '') THEN
                                TempL1 := Date2PD(TempStr)
                              ELSE
                                TempL1 := 0;
                              OneKCmds := '';
                              FOR Cmd1 := '!' TO '~' DO
                                IF (Cmd1 IN ValKeys) THEN
                                    OneKCmds := OneKCmds + Cmd1;
                              NL;
                              Prt('Level to expire to (!-~) [Space=No Change]: ');
                              OneK1(Cmd1,^M' '+OneKCmds,TRUE,TRUE);
                              TempStr := Cmd1;
                              IF (TempL1 = 0) OR (TempStr = ' ') THEN
                              BEGIN
                                TempL1 := 0;
                                TempStr := ' ';
                              END;
                              Cmd1 := '3';
                            END;
                      END;
                      IF (TempStr <> '') THEN
                        CASE on OF
                          1 : CASE StrToInt(Cmd1) OF
                                1 : LoggedOn := TempL1;
                                2 : TTimeOn := TempL1;
                                3 : OnToday := TempL1;
                                4 : TLToday := TempL1;
                                5 : Illegal := TempL1;
                                6 : TimeBank := TempL1;
                              END;
                          2 : CASE StrToInt(Cmd1) OF
                                1 : MsgPost := TempL1;
                                2 : EmailSent := TempL1;
                                3 : FeedBack := TempL1;
                                4 : Waiting := TempL1;
                              END;
                          3 : CASE StrToInt(Cmd1) OF
                                1 : Downloads := TempL1;
                                2 : DK := TempL1;
                                3 : Uploads := TempL1;
                                4 : UK := TempL1;
                                5 : DLToday := TempL1;
                                6 : DLKToday := TempL1;
                                7 : FilePoints := TempL1;
                              END;
                          5 : CASE StrToInt(Cmd1) OF
                                1 : lCredit := TempL1;
                                2 : Debit := TempL1;
                                3 : BEGIN
                                      Expiration := TempL1;
                                      IF (TempStr[1] IN [' ','!'..'~']) THEN
                                        ExpireTo := TempStr[1];
                                    END;
                              END;
                        END;
                      END
                      ELSE
                        CASE StrToInt(Cmd1) OF
                          1 : CStuff(3,3,User);
                          2 : ToggleStatusFlag(CLSMsg,SFlags);
                          3 : ToggleACFlag(Pause,Flags);
                          4 : ToggleACFlag(Color,Flags);
                          5 : ToggleStatusFlag(FSEditor,SFlags);
                        END;
                END;
        END;
      UNTIL (Cmd1 = ^M) OR (HangUp);
  END;

BEGIN
  IF ((UNum < 1) OR (UNum > (MaxUsers - 1))) THEN
    Exit;
  IF (UNum = UserNum) THEN
  BEGIN
    User := ThisUser;
    SaveURec(User,UNum);
  END;
  LoadURec(User,UNum);
  Clear_F;
  SaveUNum := 0;
  Save := FALSE;
  REPEAT
    Abort := FALSE;
    IF (AutoList) OR (UNum <> SaveUNum) OR (Cmd = ^M) THEN
    BEGIN
      ShowUserInfo(UserInfoTyp,UNum,User);
      SaveUNum := UNum;
    END;
    NL;
    Prt('User editor [^5?^4=^5Help^4]: ');
    OneK(Cmd,'Q?[]=${}*ABCDEFGHIJKLMNOPRSTUVWXYZ12345-+_;:\/^'^M,TRUE,TRUE);
    IF (Cmd IN ['A','F','L'..'O','S'..'X','Z','/','{','}','-',';','^','?','<','\','=','_']) THEN
      NL;
    CASE Cmd OF
      '?' : BEGIN
              Abort := FALSE;
              PrintACR('^5Editor Help');
              NL;
              LCmds3(21,3,';New list mode',':AutoList toggle','\Show sysop log');
              LCmds3(21,3,'[Back one user',']Forward one user','=Reload old data');
              LCmds3(21,3,'{Search backward','}Search forward','*Validate user');
              LCmds3(21,3,'+Mailbox','UGoto user name/#','Search options');
              LCmds3(21,3,'-New user answers','_Other Q. answers','^Delete user');
              LCmds3(21,3,'/New user config','$Clear fields','');
              NL;
              PauseScr(FALSE);
              Save := FALSE;
            END;
      '[',']','/','{','}','U','Q' :
            BEGIN
              IF (Save) THEN
              BEGIN
                SaveURec(User,UNum);
                IF (UNum = UserNum) THEN
                  ThisUser := User;
                Save := FALSE;
              END;
              CASE Cmd OF
                '[' : BEGIN
                        Dec(UNum);
                        IF (UNum < 1) THEN
                          UNum := (MaxUsers - 1);
                      END;
                ']' : BEGIN
                        Inc(UNum);
                        IF (UNum > (MaxUsers - 1)) THEN
                          UNum := 1;
                      END;
                '/' : UNum := 0;
                '{' : Search(-1);
                '}' : Search(1);
                'U' : BEGIN
                        Print('Enter User Name, #, or partial search string.');
                        Prt(': ');
                        lFindUserWS(UNum1);
                        IF (UNum1 > 0) THEN
                        BEGIN
                          LoadURec(User,UNum1);
                          UNum := UNum1;
                        END;
                      END;
              END;
              LoadURec(User,UNum);
              IF (UNum = UserNum) THEN
                ThisUser := User;
            END;
      '=' : IF PYNQ('Reload old user data? ',0,FALSE) THEN
            BEGIN
              LoadURec(User,UNum);
              IF (UNum = UserNum) THEN
                ThisUser := User;
              Save := FALSE;
              Print('^7Old data reloaded.^1');
            END;
      'S','-','_',';',':','\' :
            BEGIN
              CASE Cmd OF
                'S' : UserSearch;
                '-' : BEGIN
                        ReadAsw(UNum,General.MiscPath+'NEWUSER');
                        PauseScr(FALSE);
                      END;
                '_' : BEGIN
                        Prt('Print questionairre file: ');
                        MPL(8);
                        Input(TempStr,8);
                        NL;
                        ReadAsw(UNum,General.MiscPath+TempStr);
                        PauseScr(FALSE);
                      END;
                ';' : BEGIN
                        Prt('(L)ong or (S)hort list mode: ');
                        OneK(Cmd,'QSL '^M,TRUE,TRUE);
                        CASE Cmd OF
                          'S' : UserInfoTyp := 2;
                          'L' : UserInfoTyp := 1;
                        END;
                        Cmd := #0;
                      END;
                ':' : AutoList := NOT AutoList;
                '\' : BEGIN
                        TempStr := General.LogsPath+'SLOG'+IntToStr(UNum)+'.LOG';
                        PrintF(TempStr);
                        IF (NoFile) THEN
                          Print('"'+TempStr+'": File not found.');
                        PauseScr(FALSE);
                      END;
              END;
            END;
      '$','*','+','A','B','C','D','E','F','G','H','I','J','K','L','M',
      'N','O','P','R','T','V','W','X','Y','Z','1','2','3','4','5','^' :
            BEGIN
              IF (((ThisUser.SL <= User.SL) OR (ThisUser.DSL <= User.DSL)) AND
                 (UserNum <> 1) AND (UserNum <> UNum)) THEN
              BEGIN
                SysOpLog('Tried to modify '+Caps(User.Name)+' #'+IntToStr(UNum));
                Print('Access denied.');
                NL;
                PauseScr(FALSE);
              END
              ELSE
              BEGIN
                Save1 := Save;
                Save := TRUE;
                CASE Cmd OF
                  '$' : BEGIN
                          REPEAT
                            NL;
                            Prt('Clear fields (^5A^4-^5J^4,^5Q^4=^5Quit^4,^5?^4=^5Help^4): ');
                            OneK(Cmd,'QABCDEFGHIJ?',TRUE,TRUE);
                            IF (Cmd = '?') THEN
                              NL;
                            CASE Cmd OF
                             'A' : User.RealName := User_String_Ask;
                             'B' : User.Street := User_String_Ask;
                             'C' : User.CityState := User_String_Ask;
                             'D' : User.ZipCode := User_String_Ask;
                             'E' : User.Birthdate := User_Date_Ask;
                             'F' : User.Ph := User_Phone_Ask;
                             'G' : User.UsrDefStr[1] := User_String_Ask;
                             'H' : User.UsrDefStr[2] := User_String_Ask;
                             'I' : User.UsrDefStr[3] := User_String_Ask;
                             'J' : User.ForgotPWAnswer := User_String_Ask;
                             '?' : BEGIN
                                     LCmds(20,3,'AReal Name','BStreet');
                                     LCmds(20,3,'CCity/State','DZip Code');
                                     LCmds(20,3,'EBirth Date','FPhone');
                                     LCmds(20,3,'GString 1','HString 2');
                                     LCmds(20,3,'IString 3','JPW Answer');
                                   END;
                            END;
                          UNTIL (Cmd = 'Q') OR (HangUp);
                          Cmd := #0;
                        END;
                  '*' : AutoVal(User,UNum);
                  '+' : CStuff(15,3,User);
                  '1'..'5' :
                        ChangeRecords(Ord(Cmd) - 48);
                  'A' : BEGIN
                          IF (Deleted IN User.SFlags) THEN
                            Print('Can''t rename deleted users.')
                          ELSE
                          BEGIN
                            Print('Enter new name.');
                            Prt(': ');
                            MPL((SizeOf(ThisUser.Name) - 1));
                            Input(TempStr,(SizeOf(ThisUser.Name) - 1));
                            UNum1 := SearchUser(TempStr,TRUE);
                            IF ((UNum1 = 0) OR (UNum1 = UNum)) AND (TempStr <> '') THEN
                            BEGIN
                              InsertIndex(User.Name,UNum,FALSE,TRUE);
                              User.Name := TempStr;
                              InsertIndex(User.Name,UNum,FALSE,FALSE);
                              Save := TRUE;
                              IF (UNum = UserNum) THEN
                                ThisUser.Name := TempStr;
                            END
                            ELSE
                              Print('Illegal Name.');
                          END;
                        END;
                  'B' : BEGIN
                          TempStr := User.RealName;
                          CStuff(10,3,User);
                          IF (User.RealName <> TempStr) THEN
                          BEGIN
                            InsertIndex(TempStr,UNum,TRUE,TRUE);
                            InsertIndex(User.RealName,UNum,TRUE,FALSE);
                          END;
                        END;
                  'C' : CStuff(1,3,User);
                  'D' : CStuff(4,3,User);
                  'E' : CStuff(14,3,User);
                  'F' : InputWN1('^1New SysOp note:%LF^4: ',User.Note,(SizeOf(User.Note) - 1),[ColorsAllowed],Next);
                  'G' : CStuff(5,3,User);
                  'H' : CStuff(6,3,User);
                  'I' : CStuff(13,3,User);
                  'J' : BEGIN
                          REPEAT
                            NL;
                            Print('^11. Trapping status: '+AOnOff((TrapActivity IN User.SFlags),
                                                         '^7'+AOnOff((TrapSeparate IN User.SFlags),
                                                         'Trapping to TRAP'+IntToStr(UNum)+'.LOG',
                                                         'Trapping to TRAP.LOG'),
                                                         'Off')+AOnOff(General.globaltrap,'^8 <GLOBAL>',''));
                            Print('^12. Auto-chat state: '+AOnOff((ChatAuto IN User.SFlags),
                                                         AOnOff((ChatSeparate IN User.SFlags),
                                                         '^7Output to CHAT'+IntToStr(UNum)+'.LOG',
                                                         '^7Output to CHAT.LOG'),'Off')+
                                                         AOnOff(General.autochatopen,'^8 <GLOBAL>',''));
                            Print('^13. SysOp Log state: '+AOnOff((SLogSeparate IN User.SFlags),
                                                         '^7Logging to SLOG'+IntToStr(UNum)+'.LOG',
                                                         '^3Normal output'));
                            Print('^14. Alert          : '+AOnOff((Alert IN User.Flags),
                                                         '^7Alert',
                                                         '^3Normal'));
                            NL;
                            Prt('Select (1-4): ');
                            OneK(Cmd,^M'1234',TRUE,TRUE);
                            IF (Cmd <> ^M) THEN
                              NL;
                            CASE Cmd OF
                              '1' : BEGIN
                                      IF PYNQ('Trap User activity? ['+ShowYesNo((TrapActivity IN User.SFlags))+']: ',
                                              0,TrapActivity IN User.SFlags) THEN
                                        Include(User.SFlags,TrapActivity)
                                      ELSE
                                        Exclude(User.SFlags,TrapActivity);
                                      IF (TrapActivity IN User.SFlags) THEN
                                      BEGIN
                                        IF PYNQ('Log to separate file? ['+ShowYesNo(TrapSeparate IN User.SFlags)+']: ',
                                                0,TrapSeparate IN User.SFlags) THEN
                                          Include(User.SFlags,TrapSeparate)
                                        ELSE
                                          Exclude(User.SFlags,TrapSeparate);
                                      END
                                      ELSE
                                        Exclude(User.SFlags,TrapSeparate);
                                    END;
                              '2' : BEGIN
                                      IF PYNQ('Auto-chat buffer open? ['+ShowYesNo(ChatAuto IN User.SFlags)+']: ',
                                              0,ChatAuto IN User.SFlags) THEN
                                        Include(User.SFlags,ChatAuto)
                                      ELSE
                                        Exclude(User.SFlags,ChatAuto);
                                      IF (ChatAuto IN User.SFlags) THEN
                                      BEGIN
                                        IF PYNQ('Separate buffer file? ['+ShowYesNo(ChatSeparate IN User.SFlags)+']: ',
                                                0,ChatSeparate IN User.SFlags) THEN
                                          Include(User.SFlags,ChatSeparate)
                                        ELSE
                                          Exclude(User.SFlags,ChatSeparate);
                                      END
                                      ELSE
                                        Exclude(User.SFlags,ChatSeparate);
                                    END;
                              '3' : BEGIN
                                 IF PYNQ('Output SysOp Log separately? ['+ShowYesNo(SLogSeparate IN User.SFlags)+']: ',
                                         0,SLogSeparate IN User.SFlags) THEN
                                        Include(User.SFlags,SLogSeparate)
                                      ELSE
                                        Exclude(User.SFlags,SLogSeparate);
                                    END;
                              '4' : ToggleACFlag(Alert,User.Flags);
                            END;
                          UNTIL (Cmd = ^M) OR (HangUp);
                          Cmd := #0;
                        END;
                  'K' : CStuff(27,3,User);
                  'L' : BEGIN
                          TempB := User.SL;
                          InputByteWOC('Enter new SL',TempB,[NumbersOnly],0,255);
                          IF (TempB >= 0) AND (TempB <= 255) THEN
                          BEGIN
                            Ok := TRUE;
                            IF (TempB < ThisUser.SL) OR (UserNum = 1) THEN
                            BEGIN
                              IF (UserNum = UNum) AND (TempB < ThisUser.SL) THEN
                              BEGIN
                                NL;
                                IF NOT PYNQ('Lower your own SL level? ',0,FALSE) THEN
                                  Ok := FALSE;
                              END;
                              IF (Ok) THEN
                              BEGIN
                                User.SL := TempB;
                                User.TLToday := (General.TimeAllow[User.SL] - User.TTimeOn);
                              END;
                            END
                            ELSE
                            BEGIN
                              NL;
                              Print('Access denied.'^G);
                              SysOpLog('Illegal SL edit attempt: '+Caps(User.Name)+' #'+IntToStr(UNum)+' to '+IntToStr(TempB));
                            END;
                          END;
                        END;
                  'M' : BEGIN
                          TempB := User.DSL;
                          InputByteWOC('Enter new DSL',TempB,[NumbersOnly],0,255);
                          IF (TempB >= 0) AND (TempB <= 255) THEN
                          BEGIN
                            Ok := TRUE;
                            IF (TempB < ThisUser.DSL) OR (UserNum = 1) THEN
                            BEGIN
                              IF (UserNum = UNum) AND (TempB < ThisUser.SL) THEN
                              BEGIN
                                NL;
                                IF NOT PYNQ('Lower your own DSL level? ',0,FALSE) THEN
                                  Ok := FALSE;
                              END;
                              IF (Ok) THEN
                                User.DSL := TempB;
                            END
                            ELSE
                            BEGIN
                              NL;
                              Print('Access denied.'^G);
                              SysOpLog('Illegal DSL edit attempt: '+Caps(User.Name)+' #'+IntToStr(UNum)+
                                       ' to '+IntToStr(TempB));
                            END;
                          END;
                        END;
                  'N' : BEGIN
                          REPEAT
                            Prt('Toggle which AR flag? ('+DisplayARFlags(User.AR,'5','4')+'^4)'+
                                ' [^5*^4=^5All^4,^5?^4=^5Help^4,^5<CR>^4=^5Quit^4]: ');
                            OneK(Cmd,^M'ABCDEFGHIJKLMNOPQRSTUVWXYZ*?',TRUE,TRUE);
                            IF (Cmd = '?') THEN
                              PrintF('ARFLAGS')
                            ELSE IF (Cmd <> ^M) THEN
                            BEGIN
                              IF (NOT (Cmd IN ThisUser.AR)) AND (NOT SysOp) THEN
                              BEGIN
                                Print('Access denied.'^G);
                                SysOpLog('Tried to give '+Caps(User.Name)+' #'+IntToStr(UNum)+' AR flag "'+Cmd+'"');
                              END
                              ELSE IF (Cmd IN ['A'..'Z']) THEN
                                ToggleARFlag(Cmd,User.AR,Changed)
                              ELSE IF (Cmd = '*') THEN
                              BEGIN
                                FOR Cmd := 'A' TO 'Z' DO
                                  ToggleARFlag(Cmd,User.AR,Changed);
                                Cmd := '*';
                              END;
                            END;
                          UNTIL (Cmd = ^M) OR (HangUp);
                          Cmd := #0;
                        END;
                  'O' : BEGIN
                          REPEAT
                            Prt('Toggle which AC flag? ('+DisplayACFlags(User.Flags,'5','4')+'^4)'+
                                ' [^5?^4=^5Help^4,^5<CR>^4=^5Quit^4]: ');
                            OneK(Cmd,^M'LCVUA*PEKM1234?',TRUE,TRUE);
                            IF (Cmd = '?') THEN
                              PrintF('ACFLAGS')
                            ELSE
                            BEGIN
                              IF (Cmd = '4') AND (NOT SysOp) THEN
                              BEGIN
                                Print('Access denied.'^G);
                                SysOpLog('Tried to change '+Caps(User.Name)+' #'+IntToStr(UNum)+' deletion status');
                              END
                              ELSE IF (Cmd <> ^M) THEN
                                ToggleACFlags(Cmd,User.Flags,Changed);
                            END;
                          UNTIL (Cmd = ^M) OR (HangUp);
                          Cmd := #0;
                        END;
                  'P' : BEGIN
                          CStuff(2,3,User);
                          CStuff(12,3,User);
                        END;
                  'R' : CStuff(8,3,User);
                  'T' : BEGIN
                          Print('New last on date (MM/DD/YYYY).');
                          Prt(': ');
                          MPL(10);
                          InputFormatted('',TempStr,'##/##/####',TRUE);
                          IF (TempStr <> '') THEN
                            User.LastOn := Date2PD(TempStr);
                        END;
                  'V' : BEGIN
                          IF (LockedOut IN User.SFlags) THEN
                            Exclude(User.SFlags,LockedOut)
                          ELSE
                            Include(User.SFlags,LockedOut);
                          IF (LockedOut IN User.SFlags) THEN
                          BEGIN
                            Print('User is now locked out.');
                            NL;
                            Print('Each time the user logs on from now on, a text file will');
                            Print('be displayed before user is terminated.');
                            NL;
                            Prt('Enter lockout filename: ');
                            MPL(8);
                            Input(TempStr,8);
                            IF (TempStr = '') THEN
                              Exclude(User.SFlags,LockedOut)
                            ELSE
                            BEGIN
                              User.LockedFile := TempStr;
                              SysOpLog('Locked '+Caps(User.Name)+' #'+IntToStr(UNum)+' out: Lockfile "'+TempStr+'"');
                            END;
                          END;
                          IF NOT (LockedOut IN User.SFlags) THEN
                          BEGIN
                            NL;
                            Print('User is no longer locked out of system.');
                          END;
                          NL;
                          PauseScr(FALSE);
                        END;
                  'W' : BEGIN
                          Print('Enter new password.');
                          Prt(': ');
                          MPL(20);
                          Input(TempStr,20);
                          IF (TempStr <> '') THEN
                            User.PW := CRC32(TempStr);
                        END;
                  'X' : BEGIN
                          Print('Enter new caller ID string.');
                          Prt(': ');
                          MPL((SizeOf(User.CallerID) - 1));
                          Input(TempStr,(SizeOf(User.CallerID) - 1));
                          IF (TempStr <> '') THEN
                            User.CallerID := TempStr;
                        END;
                  'Y' : FindMenu('%LFEnter new start menu (^50^4=^5Default^4)',User.UserStartMenu,0,NumMenus,Changed);
                  'Z' : BEGIN
                          Print('Question:');
                          NL;
                          Print(General.ForgotPWQuestion);
                          NL;
                          Print('Enter new forgot password answer.');
                          Prt(': ');
                          MPL((SizeOf(User.ForgotPWAnswer) - 1));
                          Input(TempStr,(SizeOf(User.ForgotPWAnswer) - 1));
                          IF (TempStr <> '') THEN
                            User.ForgotPWAnswer := TempStr;
                        END;
                  '^' : IF (Deleted IN User.SFlags) THEN
                        BEGIN
                          Print('User is currently deleted.');
                          NL;
                          IF PYNQ('Restore this user? ',0,FALSE) THEN
                          BEGIN
                            InsertIndex(User.Name,UNum,FALSE,FALSE);
                            InsertIndex(User.RealName,UNum,TRUE,FALSE);
                            Inc(LTodayNumUsers);
                            SaveGeneral(TRUE);
                            Exclude(User.SFlags,Deleted);
                          END
                          ELSE
                            Save := Save1;
                        END
                        ELSE IF (FNoDeletion IN User.Flags) THEN
                        BEGIN
                          Print('Access denied - This user is protected from deletion.');
                          SysOpLog('* Attempt to delete user: '+Caps(User.Name)+' #'+IntToStr(UNum));
                          NL;
                          PauseScr(FALSE);
                          Save := Save1;
                        END
                        ELSE
                        BEGIN
                          NL;
                          IF PYNQ('*DELETE* this User? ',0,FALSE) THEN
                          BEGIN
                            IF NOT (Deleted IN User.SFlags) THEN
                            BEGIN
                              Save := TRUE;
                              Include(User.SFlags,Deleted);
                              InsertIndex(User.Name,UNum,FALSE,TRUE);
                              InsertIndex(User.RealName,UNum,TRUE,TRUE);
                              Dec(LTodayNumUsers);
                              SaveGeneral(TRUE);
                              SysOpLog('* Deleted User: '+Caps(User.Name)+' #'+IntToStr(UNum));
                              UNum1 := UserNum;
                              UserNum := UNum;
                              ReadShortMessage;
                              UserNum := UNum1;
                              User.Waiting := 0;
                              KillUserMail;
                              KillUserVotes;
                            END
                            ELSE
                              Save := Save1;
                          END;
                        END;
                ELSE
                  Save := Save1;
                END;
            END;
          END;
    END;
    IF (UNum = UserNum) THEN
    BEGIN
      ThisUser := User;
      NewComptables;
    END;
  UNTIL (Cmd = 'Q') OR (HangUp);
  Update_Screen;
  LastError := IOResult;
END;

END.
