{$IFDEF WIN32}
{$I DEFINES.INC}
{$ENDIF}

{$A+,B-,D-,E-,F+,I-,L-,N-,O+,R-,S+,V-}
UNIT Bulletin;

INTERFACE

USES
  Common;

FUNCTION FindOnlyOnce: Boolean;
FUNCTION NewBulletins: Boolean;
PROCEDURE Bulletins(MenuOption: Str50);
PROCEDURE UList(MenuOption: Str50);
PROCEDURE TodaysCallers(x: Byte; MenuOptions: Str50);
PROCEDURE RGQuote(MenuOption: Str50);

IMPLEMENTATION

USES
  Dos,
  Common5,
  Mail1,
  ShortMsg,
  TimeFunc;

TYPE
  LastCallerPtrType = ^LastCallerRec;
  UserPtrType = ^UserRecordType;

PROCEDURE Bulletins(MenuOption: Str50);
VAR
  Main,
  Subs,
  InputStr: ASTR;
BEGIN
  NL;
  IF (MenuOption = '') THEN
    IF (General.BulletPrefix = '') THEN
      MenuOption := 'BULLETIN;BULLET'
    ELSE
      MenuOption := 'BULLETIN;'+General.BulletPrefix;
  IF (Pos(';',MenuOption) <> 0) THEN
  BEGIN
    Main := Copy(MenuOption,1,(Pos(';',MenuOption) - 1));
    Subs := Copy(MenuOption,(Pos(';',MenuOption) + 1),(Length(MenuOption) - Pos(';',MenuOption)));
  END
  ELSE
  BEGIN
    Main := MenuOption;
    Subs := MenuOption;
  END;
  PrintF(Main);
  IF (NOT NoFile) THEN
    REPEAT
      NL;
      { Prt(FString.BulletinLine); }
      lRGLngStr(16,FALSE);
      ScanInput(InputStr,'ABCDEFGHIJKLMNOPQRSTUVWXYZ?');
      IF (NOT HangUp) THEN
      BEGIN
        IF (InputStr = '?') THEN
          PrintF(Main);
        IF (InputStr <> '') AND NOT (InputStr[1] IN ['Q','?']) THEN
          PrintF(Subs+InputStr);
      END;
    UNTIL (InputStr = 'Q') OR (HangUp);
END;

FUNCTION FindOnlyOnce: Boolean;
VAR
  (*
  DirInfo: SearchRec;
  *)
  DT: DateTime;
BEGIN
  FindOnlyOnce := FALSE;
  FindFirst(General.MiscPath+'ONLYONCE.*',AnyFile - Directory - VolumeID- DOS.Hidden,DirInfo);
  IF (DosError = 0) THEN
  BEGIN
    UnPackTime(DirInfo.Time,DT);
    IF (DateToPack(DT) > ThisUser.LastOn) THEN
      FindOnlyOnce := TRUE;
  END;
END;

FUNCTION NewBulletins: Boolean;
TYPE
  BulletinType = ARRAY [0..255] OF Byte;
VAR
  BulletinArray: ^BulletinType;
  DT: DateTime;
  (*
  DirInfo: SearchRec;
  *)
  BullCount,
  Biggest,
  LenOfBullPrefix,
  LenToCopy: Byte;
  Found: Boolean;

  PROCEDURE ShowBulls;
  VAR
    Counter,
    Counter1,
    Counter2: Byte;
  BEGIN
    FOR Counter := 0 TO BullCount DO
    BEGIN
      FOR Counter1 := 0 TO BullCount DO
        IF (BulletinArray^[Counter] < BulletinArray^[Counter1]) THEN
        BEGIN
          Counter2 := BulletinArray^[Counter];
          BulletinArray^[Counter] := BulletinArray^[Counter1];
          BulletinArray^[Counter1] := Counter2;
        END;
    END;
    Counter1 := 1;
    Prt('|01[ |11');
    FOR Counter2 := 0 TO (BullCount) DO
    BEGIN
      IF (Counter1 = 15) THEN
      BEGIN
        Prt(PadRightInt(BulletinArray^[Counter2],2));
        IF (Counter2 < BullCount) THEN
          Prt(' |01]'+^M^J+'|01[ |11')
        ELSE
          Prt(' |01]');
        Counter1 := 0;
      END
      ELSE
      BEGIN
        Prt(PadRightInt(BulletinArray^[Counter2],2));
        IF (Counter2 < BullCount) THEN
          Prt('|07,|11 ')
        ELSE
          Prt(' |01]');
      END;
      Inc(Counter1);
    END;
    NL;
 END;

BEGIN
  New(BulletinArray);
  FOR BullCount := 0 TO 255 DO
    BulletinArray^[BullCount] := 0;
  Found := FALSE;
  Biggest := 0;
  BullCount := 0;
  LenOfBullPrefix := (Length(General.BulletPrefix) + 1);
  FindFirst(General.MiscPath+General.BulletPrefix+'*.ASC',AnyFile - Directory - VolumeID - DOS.Hidden,DirInfo);
  WHILE (DosError = 0) DO
  BEGIN
    IF (((Pos(General.BulletPrefix,General.MiscPath+General.BulletPrefix+'*.ASC') > 0) AND
       (Pos('BULLETIN',AllCaps(DirInfo.Name)) = 0)) AND
       (Pos('~',DirInfo.Name) = 0)) THEN
    BEGIN
      UnPackTime(DirInfo.Time,DT);
      IF (DateToPack(DT) > ThisUser.LastOn) THEN
      BEGIN
        Found := TRUE;
        LenToCopy := (Pos('.',DirInfo.Name) - 1) - Length(General.BulletPrefix);
        BulletinArray^[BullCount] := StrToInt(Copy(DirInfo.Name,LenOfBullPrefix,LenToCopy));
        IF (BulletinArray^[BullCount] > Biggest) THEN
          Biggest := BulletinArray^[BullCount];
        Inc(BullCount);
      END;
    END;
    IF (BullCount > 254) THEN
      Exit;
    FindNext(DirInfo);
  END;
  IF (Found) THEN
  BEGIN
    Dec(BullCount);
    ShowBulls;
  END;
  Dispose(BulletinArray);
  NewBulletins := Found;
END;

FUNCTION UlistMCI(CONST S: ASTR; Data1,Data2: Pointer): STRING;
VAR
  UserPtr: UserPtrType;
BEGIN
  UlistMCI := S;
  UserPtr := Data1;
  CASE S[1] OF
    'A' : CASE S[2] OF
            'G' : UListMCI := IntToStr(AgeUser(UserPtr^.BirthDate));
          END;
    'D' : CASE S[2] OF
            'K' : UListMCI := IntToStr(UserPtr^.DK);
            'L' : UListMCI := IntToStr(UserPtr^.Downloads);
          END;
    'L' : CASE S[2] OF
            'C' : UListMCI := UserPtr^.CityState;
            'O' : UListMCI := ToDate8(PD2Date(UserPtr^.LastOn));
          END;
    'M' : CASE S[2] OF
            'P' : UListMCI := IntToStr(UserPtr^.MsgPost);
          END;
    'N' : CASE S[2] OF
            'O' : UListMCI := Userptr^.Note;
          END;
    'R' : CASE S[2] OF
            'N' : UListMCI := UserPtr^.RealName;
          END;
    'S' : CASE S[2] OF
            'X' : UListMCI := UserPtr^.Sex;
          END;
    'U' : CASE S[2] OF
            'K' : UListMCI := IntToStr(UserPtr^.UK);
            'L' : UListMCI := IntToStr(UserPtr^.Uploads);
            'N' : UListMCI := Caps(UserPtr^.Name);
            '1' : UListMCI := UserPtr^.UsrDefStr[1];
            '2' : UListMCI := UserPtr^.UsrDefStr[2];
            '3' : UListMCI := UserPtr^.UsrDefStr[3];
          END;
  END;
END;

PROCEDURE UList(MenuOption: Str50);
VAR
  Junk: Pointer;
  User: UserRecordType;
  Cmd: Char;
  TempStr: ASTR;
  Gender: Str1;
  State,
  UState: Str2;
  Age: Str3;
  DateLastOn: Str8;
  City,
  UCity: Str30;
  RName,
  UName: Str36;
  FN: Str50;
  RecNum: Integer;

  PROCEDURE Option(c1: Char; s1,s2: Str160);
  BEGIN
    Prompt('^4<^5'+c1+'^4>'+s1+': ');
    IF (s2 <> '') THEN
      Print('^5"^4'+s2+'^5"^1')
    ELSE
      Print('^5<<INACTIVE>>^1');
  END;

BEGIN
  IF (RUserList IN ThisUser.Flags) THEN
  BEGIN
    Print('You are restricted from listing users.');
    Exit;
  END;
  Age := '';
  City := '';
  DateLastOn := '';
  Gender := '';
  RName := '';
  State := '';
  UName := '';
  REPEAT
    NL;
    Print('^5User lister search options:');
    NL;
    Option('A','ge match string             ',Age);
    Option('C','ity match string            ',City);
    Option('D','ate last online match string',DateLastOn);
    Option('G','ender match string          ',Gender);
    Option('R','eal name match string       ',RName);
    Option('S','tate match string           ',State);
    Option('U','ser name match string       ',UName);
    NL;
    Prompt('^4Enter choice (^5A^4,^5C^4,^5D^4,^5G^4,^5R^4,^5S^4,^5U^4) [^5L^4]ist [^5Q^4]uit: ');
    OneK(Cmd,'QACDGLRSU'^M,TRUE,TRUE);
    NL;
    IF (Cmd IN ['A','C','D','G','R','S','U']) THEN
    BEGIN
      TempStr := 'Enter new match string for the ';
      CASE Cmd OF
        'A' : TempStr := TempStr + 'age';
        'C' : TempStr := TempStr + 'city';
        'D' : TempStr := TempStr + 'date last online';
        'G' : TempStr := TempStr + 'gender';
        'R' : TempStr := TempStr + 'real name';
        'S' : TempStr := TempStr + 'state';
        'U' : TempStr := TempStr + 'user name';
      END;
      TempStr := TempStr + ' (<CR>=Make INACTIVE)';
      Print('^4'+TempStr);
      Prompt('^4: ');
    END;
    CASE Cmd OF
      'A' : BEGIN
              Mpl(3);
              Input(Age,3);
            END;
      'C' : BEGIN
              Mpl(30);
              Input(City,30);
            END;
      'D' : BEGIN
              Mpl(8);
              InputFormatted('',DateLastOn,'##/##/##',TRUE);
              IF (DayNum(DateLastOn) <> 0) AND (DayNum(DateLastOn) <= DayNum(DateStr)) THEN
              BEGIN
                Delete(DateLastOn,3,1);
                Insert('-',DateLastOn,3);
                Delete(DateLastOn,6,1);
                Insert('-',DateLastOn,6);
              END;
            END;
      'G' : BEGIN
              Mpl(1);
              Input(Gender,1);
            END;
      'R' : BEGIN
              Mpl(36);
              Input(RName,36);
            END;
      'S' : BEGIN
              Mpl(2);
              Input(State,2);
            END;
      'U' : BEGIN
              Mpl(36);
              Input(UName,36);
            END;
    END;
  UNTIL (Cmd IN ['L','Q',^M]) OR (HangUp);
  IF (Cmd IN ['L',^M]) THEN
  BEGIN
    Abort := FALSE;
    Next := FALSE;
    AllowContinue := TRUE;
    IF (Pos(';',MenuOption) > 0) THEN
    BEGIN
      FN := Copy(MenuOption,(Pos(';',MenuOption) + 1),255);
      MenuOption := Copy(MenuOption,1,(Pos(';',MenuOption) - 1));
    END
    ELSE
      FN := 'USER';
    IF (NOT ReadBuffer(FN+'M')) THEN
      Exit;
    PrintF(FN+'H');
    Reset(UserFile);
    RecNum := 1;
    WHILE (RecNum <= (FileSize(UserFile) - 1)) AND (NOT Abort) AND (NOT HangUp) DO
    BEGIN
      LoadURec(User,RecNum);
      UCity := (Copy(User.CityState,1,(Pos(',',User.CityState) - 1)));
      UState := SQOutSP((Copy(User.CityState,(Pos(',',User.CityState) + 2),(Length(User.CityState)))));
      IF (AACS1(User,RecNum,MenuOption)) AND NOT (Deleted IN User.SFlags) THEN
        IF (Age = '') OR (Pos(Age,IntToStr(AgeUser(User.BirthDate))) > 0) THEN
          IF (City = '') OR (Pos(City,AllCaps(UCity)) > 0) THEN
            IF (DateLastOn = '') OR (Pos(DateLastOn,ToDate8(PD2Date(User.LastOn))) > 0) THEN
              IF (Gender = '') OR (Pos(Gender,User.Sex) > 0) THEN
                IF (RName = '') OR (Pos(RName,AllCaps(User.RealName)) > 0) THEN
                  IF (State = '') OR (Pos(State,AllCaps(UState)) > 0) THEN
                     IF (UName = '') OR (Pos(UName,User.Name) > 0) THEN
                        DisplayBuffer(UlistMCI,@User,Junk);
      Inc(RecNum);
    END;
    Close(UserFile);
    IF (NOT Abort) AND (NOT HangUp) THEN
      PrintF(FN+'T');
    AllowContinue := FALSE;
  END;
  SysOpLog('Viewed User Listing.');
  LastError := IOResult;
END;

FUNCTION TodaysCallerMCI(CONST S: ASTR; Data1,Data2: Pointer): STRING;
VAR
  LastCallerPtr: LastCallerPtrType;
  s1: STRING[100];
BEGIN
  LastCallerPtr := Data1;
  TodaysCallerMCI := S;
  CASE S[1] OF
    'C' : CASE S[2] OF
            'A' : TodaysCallerMCI := FormatNumber(LastCallerPtr^.Caller);
          END;
    'D' : CASE S[2] OF
            'K' : TodaysCallerMCI := IntToStr(LastCallerPtr^.DK);
            'L' : TodaysCallerMCI := IntToStr(LastCallerPtr^.Downloads);
          END;
    'E' : CASE S[2] OF
            'S' : TodaysCallerMCI := IntToStr(LastCallerPtr^.EmailSent);
          END;
    'F' : CASE S[2] OF
            'S' : TodaysCallerMCI := IntToStr(LastCallerPtr^.FeedbackSent);
          END;
    'L' : CASE S[2] OF
            'C' : TodaysCallerMCI := LastCallerPtr^.Location;
            'O' : BEGIN
                    s1 := PDT2Dat(LastCallerPtr^.LogonTime,0);
                    s1[0] := Char(Pos('m',s1) - 2);
                    s1[Length(s1)] := s1[Length(s1) + 1];
                    TodaysCallerMCI := s1;
                  END;
            'T' : BEGIN
                    IF (LastCallerPtr^.LogoffTime = 0) THEN
                      S1 := 'Online'
                    ELSE
                    BEGIN
                      s1 := PDT2Dat(LastCallerPtr^.LogoffTime,0);
                      s1[0] := Char(Pos('m',s1) - 2);
                      s1[Length(s1)] := s1[Length(s1) + 1];
                    END;
                    TodaysCallerMCI := s1;
                  END;
          END;
    'M' : CASE S[2] OF
            'P' : TodaysCallerMCI := IntToStr(LastCallerPtr^.MsgPost);
            'R' : TodaysCallerMCI := IntToStr(LastCallerPtr^.MsgRead);
          END;
    'N' : CASE S[2] OF
            'D' : TodaysCallerMCI := IntToStr(LastCallerPtr^.Node);
            'U' : IF (LastCallerPtr^.NewUser) THEN
                    TodaysCallerMCI := '*'
                  ELSE
                    TodaysCallerMCI := ' ';
          END;
    'S' : CASE S[2] OF
            'P' : IF (LastCallerPtr^.Speed = 0) THEN
                    TodaysCallerMCI := 'Local'
                  ELSE IF (Telnet) THEN
                    TodaysCallerMCI := 'Telnet'
                  ELSE
                    TodaysCallerMCI := IntToStr(LastCallerPtr^.Speed);
          END;
    'T' : CASE S[2] OF
            'O' : WITH LastCallerPtr^ DO
                    TodaysCallerMCI := IntToStr((LogoffTime - LogonTime) DIV 60);
          END;
    'U' : CASE S[2] OF
            'K' : TodaysCallerMCI := IntToStr(LastCallerPtr^.UK);
            'L' : TodaysCallerMCI := IntToStr(LastCallerPtr^.Uploads);
            'N' : TodaysCallerMCI := LastCallerPtr^.UserName;
          END;
  END;
END;

PROCEDURE TodaysCallers(x: Byte; MenuOptions: Str50);
VAR
  Junk: Pointer;
  LastCallerFile: FILE OF LastCallerRec;
  LastCaller: LastCallerRec;
  RecNum: Integer;
BEGIN
  Abort := FALSE;
  Next := FALSE;
  AllowContinue := TRUE;
  IF (MenuOptions = '') THEN
    MenuOptions := 'LAST';
  IF (NOT ReadBuffer(MenuOptions+'M')) THEN
    Exit;
  Assign(LastCallerFile,General.DataPath+'LASTON.DAT');
  Reset(LastCallerFile);
  IF (IOResult <> 0) THEN
    Exit;
  RecNum := 0;
  IF (x > 0) AND (x <= FileSize(LastCallerFile)) THEN
    RecNum := (FileSize(LastCallerFile) - x);
  PrintF(MenuOptions+'H');
  Seek(LastCallerFile,RecNum);
  WHILE (NOT EOF(LastCallerFile)) AND (NOT Abort) AND (NOT HangUp) DO
  BEGIN
    Read(LastCallerFile,LastCaller);
    IF (((LastCaller.LogonTime DIV 86400) <> (GetPackDateTime DIV 86400)) AND (x > 0)) OR
       (((LastCaller.LogonTime DIV 86400) = (GetPackDateTime DIV 86400))) AND (NOT LastCaller.Invisible) THEN
      DisplayBuffer(TodaysCallerMCI,@LastCaller,Junk);
  END;
  Close(LastCallerFile);
  IF (NOT Abort) THEN
    PrintF(MenuOptions+'T');
  AllowContinue := FALSE;
  SysOpLog('Viewed Todays Callers.');
  LastError := IOResult;
END;

PROCEDURE RGQuote(MenuOption: Str50);
VAR
  StrPointerFile: FILE OF StrPointerRec;
  StrPointer: StrPointerRec;
  RGStrFile: FILE;
  F,
  F1: Text;
  MHeader: MHeaderRec;
  S: STRING;
  StrNum: Word;
  TotLoad: LongInt;
BEGIN
  IF (MenuOption = '') THEN
    Exit;
  Assign(StrPointerFile,General.LMultPath+MenuOption+'.PTR');
  Reset(StrPointerFile);
  TotLoad := FileSize(StrPointerFile);
  IF (TotLoad < 1) THEN
    Exit;
  IF (TotLoad > 65535) THEN
    Totload := 65535
  ELSE
    Dec(TotLoad);
  Randomize;
  StrNum := Random(Totload);
  Seek(StrPointerFile,StrNum);
  Read(StrPointerFile,StrPointer);
  Close(StrPointerFile);
  LastError := IOResult;
  IF (Exist(General.MiscPath+'QUOTEHDR.*')) THEN
    PrintF('QUOTEHDR')
  ELSE
  BEGIN
    NL;
    Print('|03[컴컴컴컴컴컴컴컴컴컴컴�[ |11And Now |03... |11A Quote For You! |03]컴컴컴컴컴컴컴컴컴컴컴]');
    NL;
  END;
  TotLoad := 0;
  Assign(RGStrFile,General.LMultPath+MenuOption+'.DAT');
  Reset(RGStrFile,1);
  Seek(RGStrFile,(StrPointer.Pointer - 1));
  REPEAT
    BlockRead(RGStrFile,S[0],1);
    BlockRead(RGStrFile,S[1],Ord(S[0]));
    Inc(TotLoad,(Length(S) + 1));
    IF (S[Length(S)] = '@') THEN
    BEGIN
      Dec(S[0]);
      Prt(Centre(S));
    END
    ELSE
      PrintACR(Centre(S));
  UNTIL (TotLoad >= StrPointer.TextSize) OR EOF(RGStrFile);
  Close(RGStrFile);
  LastError := IOResult;
  IF (Exist(General.MiscPath+'QUOTEFTR.*')) THEN
    PrintF('QUOTEFTR')
  ELSE
  BEGIN
    NL;
    Print('|03[컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴�]');
    NL;
  END;
  IF (NOT General.UserAddQuote) THEN
    PauseScr(FALSE)
  ELSE IF (PYNQ('Would you like to add a quote? ',0,FALSE)) THEN
  BEGIN
    PrintF('QUOTE');
    InResponseTo := '';
    MHeader.Status := [];
    IF (InputMessage(TRUE,FALSE,'New Quote',MHeader,General.LMultPath+MenuOption+'.TMP',78,500)) then
      IF Exist(General.LMultPath+MenuOption+'.TMP') THEN
      BEGIN
        Assign(F,General.LMultPath+MenuOption+'.NEW');
        Reset(F);
        IF (IOResult <> 0) THEN
          ReWrite(F)
        ELSE
          Append(F);
        Assign(F1,General.LMultPath+MenuOption+'.TMP');
        Reset(F1);
        IF (IOResult <> 0) THEN
          Exit;
        WriteLn(F,'New quote from: '+Caps(ThisUser.Name)+' #'+IntToStr(UserNum)+'.');
        WriteLn(F,'');
        WriteLn(F,'$');
        WHILE (NOT EOF(F1)) DO
        BEGIN
          ReadLn(F1,S);
          WriteLn(F,S);
        END;
        WriteLn(F,'$');
        WriteLn(F,'');
        WriteLn(F);
        Close(F);
        Close(F1);
        Kill(General.LMultPath+MenuOption+'.TMP');
        NL;
        Print('^7Your new quote was saved.');
        PauseScr(FALSE);
        SendShortMessage(1,Caps(ThisUser.Name)+' added a new quote to "'+MenuOption+'.NEW".');
      END;
  END;
END;

END.
