{$IFDEF WIN32}
{$I DEFINES.INC}
{$ENDIF}

{$A+,B-,D-,E-,F+,I-,L-,N-,O+,R-,S+,V-}

UNIT Script;

INTERFACE

USES
   Common;

PROCEDURE ReadQ(CONST FileN: AStr);
PROCEDURE ReadASW(UserN: Integer; FN: AStr);
PROCEDURE ReadASW1(MenuOption: Str50);

IMPLEMENTATION

USES
  Dos,
  Doors,
  MiscUser,
  SysOp2G,
  TimeFunc;

PROCEDURE ReadQ(CONST FileN: AStr);
VAR
  InFile,
  OutFile,
  OutFile1: Text;
  C: Char;
  OutP,
  Lin,
  S,
  Mult,
  Got,
  LastInp,
  InFileName,
  OutFileName: AStr;
  PS: PathStr;
  NS: NameStr;
  ES: ExtStr;
  I,
  X: Integer;

  PROCEDURE GoToLabel(Got: AStr);
  VAR
    S: AStr;
  BEGIN
    Got := ':'+AllCaps(Got);
    Reset(InFile);
    REPEAT
      ReadLn(InFile,S);
    UNTIL (EOF(InFile)) OR (AllCaps(S) = Got);
  END;

  PROCEDURE DumpToFile;
  VAR
    NewOutFile: Text;
    WriteOut: Boolean; { goes to false when passing OLD infoform }
  BEGIN
    Assign(NewOutFile,General.MiscPath+'INF'+IntToStr(ThisNode)+'.TMP');
    ReWrite(NewOutFile);
    Reset(OutFile);
    WriteOut := TRUE;
    WHILE (NOT EOF(OutFile)) DO
    BEGIN
      ReadLn(OutFile,S);
      IF (Pos('User: '+Caps(ThisUser.Name), S) > 0) THEN
        WriteOut := FALSE
      ELSE IF (NOT WriteOut) THEN
        IF (Pos('User: ', S) > 0) THEN
          WriteOut := TRUE;
      IF (WriteOut) THEN
        WriteLn(NewOutFile,S);
    END;
    Reset(OutFile1);
    WHILE (NOT EOF(OutFile1)) DO
    BEGIN
      ReadLn(OutFile1,S);
      WriteLn(NewOutFile,S);
    END;
    Close(OutFile1);
    Close(OutFile);
    Close(NewOutFile);
    Kill(General.MiscPath+NS+'.ASW');
    Erase(OutFile1);
    ReName(NewOutFile,General.MiscPath+NS+'.ASW');
    LastError := IOResult;
  END;

BEGIN
  InFileName := FileN;
  FSplit(InFileName,PS,NS,ES);
  InFileName := PS+NS+'.INF';
  IF (NOT Exist(InFileName)) THEN
  BEGIN
    InFileName := General.MiscPath+NS+'.INF';
    IF (NOT Exist(InFileName)) THEN
    BEGIN
      S := '* Infoform not found: '+FileN;
      SysOpLog(S);
      Exit;
    END;
    IF (OkAvatar) AND Exist(General.MiscPath+NS+'.INV') THEN
      InFileName := General.MiscPath+NS+'.INV'
    ELSE IF (OkAnsi) AND Exist(General.MiscPath+NS+'.INA') THEN
      InFileName := General.MiscPath+NS+'.INA';
  END
  ELSE IF (OkAvatar) AND Exist(PS+NS+'.INV') THEN
    InFileName := PS+NS+'.INV'
  ELSE IF (OkAnsi) AND Exist(PS+NS+'.INA') THEN
    InFileName := PS+NS+'.INA';
  Assign(InFile,InFileName);
  Reset(InFile);
  IF (IOResult <> 0) THEN
  BEGIN
    SysOpLog('* Infoform not found: '+FileN);
    SysOpLog(S);
    Exit;
  END;
  FSplit(InFileName,PS,NS,ES);
  OutFileName := General.MiscPath+NS+'.ASW';
  Assign(OutFile1,General.MiscPath+'TMP'+IntToStr(ThisNode)+'.ASW');
  ReWrite(OutFile1);
  SysOpLog('* Answered InfoForm "'+FileN+'"');
  Assign(OutFile,OutFileName);
  WriteLn(OutFile1,'User: '+Caps(ThisUser.name));
  WriteLn(OutFile1,'Date: '+Dat);
  WriteLn(OutFile1);
  NL;
  PrintingFile := TRUE;
  REPEAT
    Abort := FALSE;
    X := 0;
    REPEAT
      Inc(X);
      Read(InFile,OutP[X]);
      IF EOF(InFile) THEN                {check again incase avatar parameter}
      BEGIN
        Inc(X);
        Read(InFile,OutP[X]);
        IF EOF(InFile) THEN
          Dec(X);
      END;
    UNTIL ((OutP[X] = ^M) AND NOT (OutP[X - 1] IN [^V,^Y])) OR (X = 159) OR EOF(InFile) OR HangUp;
    OutP[0] := Chr(X);
    IF (Pos(^[,OutP) > 0) OR (Pos(^V,OutP) > 0) THEN
    BEGIN
      CROff := TRUE;
      CtrlJOff := TRUE;
    END
    ELSE
    BEGIN
      IF (OutP[X] = ^M) THEN
        Dec(OutP[0]);
      IF (OutP[1] = ^J) THEN
        Delete(OutP,1,1);
    END;
    IF (Pos('*',OutP) <> 0) AND (OutP[1] <> ';') THEN
      OutP := ';A'+OutP;
    IF (Length(OutP) = 0) THEN
      NL
    ELSE
      CASE OutP[1] OF
        ';' : BEGIN
                IF (Pos('*',OutP) <> 0) THEN
                  IF (OutP[2] <> 'D') THEN
                    OutP := Copy(OutP,1,(Pos('*',OutP) - 1));
                Lin := Copy(OutP,3,255);
                I := (80 - Length(Lin));
                S := Copy(OutP,1,2);
                IF (S[1] = ';') THEN
                  CASE S[2] OF
                    'R','F','V','C','D','G','I','K','L','Q','S','T',';': I := 1; { DO nothing }
                  ELSE IF (Lin[1] = ';') THEN
                    Prompt(Copy(Lin,2,255))
                  ELSE
                    Prompt(Lin);
                  END;
                S := #1#1#1;
                CASE OutP[2] OF
                  'A' : InputL(S,I);
                  'B' : Input(S,I);
                  'C' : BEGIN
                          Mult := '';
                          I := 1;
                          S := Copy(OutP,Pos('"',OutP),(Length(OutP) - Pos('"',OutP)));
                          REPEAT
                            Mult := Mult + S[I];
                            Inc(I);
                          UNTIL (S[I] = '"') OR (I > Length(S));
                          Lin := Copy(OutP,(I + 3),(Length(S) - (I - 1)));
                          Prompt(Lin);
                          OneK(C,Mult,TRUE,TRUE);
                          S := C;
                        END;
                  'D' : BEGIN
                          DoDoorFunc(OutP[3],Copy(OutP,4,(Length(OutP) - 3)));
                          S := #0#0#0;
                        END;
                  'F' : BEGIN
                          ChangeARFlags(Copy(OutP,3,255));
                          OutP := #0#0#0
                        END;
                  'G' : BEGIN
                          Got := Copy(OutP,3,(Length(OutP) - 2));
                          GoToLabel(Got);
                          S := #0#0#0;
                        END;
                  'S' : BEGIN
                          Delete(OutP,1,3);
                          IF AACS(Copy(OutP,1,(Pos('"',OutP) - 1))) THEN
                          BEGIN
                            Got := Copy(OutP,(Pos(',',OutP) + 1),255);
                            GoToLabel(Got);
                          END;
                          S := #0#0#0;
                        END;
                  'H' : HangUp := TRUE;
                  'I' : BEGIN
                          Mult := Copy(OutP,3,(Length(OutP) - 2));
                          I := Pos(',',Mult);
                          IF (I <> 0) THEN
                          BEGIN
                            Got := Copy(Mult,(I + 1),(Length(Mult) - I));
                            Mult := Copy(Mult,1,(I - 1));
                            IF (AllCaps(LastInp) = AllCaps(Mult)) THEN
                              GoToLabel(Got);
                          END;
                          S := #1#1#1;
                          OutP := #0#0#0;
                        END;
                  'K' : BEGIN
                          Close(InFile);
                          Close(OutFile1);
                          Erase(OutFile1);
                          SysOpLog('* InfoForm aborted.');
                          PrintingFile := FALSE;
                          Exit;
                        END;
                  'L' : BEGIN
                          S := Copy(OutP,3,(Length(OutP) - 2));
                          WriteLn(OutFile1,MCI(S));
                          S := #0#0#0;
                        END;
                  'Q' : BEGIN
                          WHILE NOT EOF(InFile) DO
                            ReadLn(InFile,S);
                          S := #0#0#0;
                        END;
                  'R' : BEGIN
                          ChangeACFlags(Copy(OutP,3,255));
                          OutP := #0#0#0;
                        END;
                  'T' : BEGIN
                          S := Copy(OutP,3,(Length(OutP) - 2));
                          PrintF(S);
                          S := #0#0#0;
                        END;
                  'Y' : BEGIN
                          IF YN(0,TRUE) THEN
                            S := 'YES'
                          ELSE
                            S := 'NO';
                          IF (Lin[1] = ';') THEN
                            OutP := #0#0#0;
                        END;
                  'N' : BEGIN
                          IF YN(0,FALSE) THEN
                            S := 'YES'
                          ELSE
                            S := 'NO';
                          IF (Lin[1] = ';') THEN
                            OutP := #0#0#0
                        END;
                  'V' : IF (UpCase(OutP[3]) IN ['!'..'~']) THEN
                          AutoValidate(ThisUser,UserNum,UpCase(OutP[3]));
                  ';' : S := #0#0#0;
                END;
                IF (S <> #1#1#1) THEN
                BEGIN
                  IF (OutP <> #0#0#0) THEN
                    OutP := Lin + S;
                  LastInp := S;
                END;
                IF (S = #0#0#0) THEN
                  OutP := #0#0#0;
              END;
        ':' : OutP := #0#0#0;
      ELSE
        PrintACR(OutP);
      END;
    IF (OutP <> #0#0#0) THEN
    BEGIN
      IF (Pos('%CL',OutP) <> 0) THEN
        Delete(OutP,Pos('%CL',OutP),3);
      WriteLn(OutFile1,MCI(OutP));
    END;
  UNTIL ((EOF(InFile)) OR (HangUp));
  Close(OutFile1);
  Close(InFile);
  IF (HangUp) THEN
  BEGIN
    WriteLn(OutFile1);
    WriteLn(OutFile1,'** HUNG UP **');
  END
  ELSE
    DumpToFile;
  PrintingFile := FALSE;
  LastError := IOResult;
END;

PROCEDURE ReadASW(UserN: Integer; FN: AStr);
VAR
  QF: Text;
  User: UserRecordType;
  QS: AStr;
  PS: PathStr;
  NS: NameStr;
  ES: ExtStr;
  UserFound: Boolean;

  PROCEDURE ExactMatch;
  BEGIN
    Reset(QF);
    REPEAT
      ReadLn(QF,QS);
      IF (Pos('User: '+Caps(User.Name),QS) > 0) THEN
        UserFound := TRUE;
      IF (NOT Empty) THEN
        WKey;
    UNTIL (EOF(QF)) OR (UserFound) OR (Abort);
  END;

BEGIN
  IF ((UserN >= 1) AND (UserN <= (MaxUsers - 1))) THEN
    LoadURec(User,UserN)
  ELSE
  BEGIN
    Print('Invalid user number.');
    Exit;
  END;
  Abort := FALSE;
  Next := FALSE;
  FSplit(FN,PS,NS,ES);
  FN := General.MiscPath+NS+'.ASW';
  IF (NOT Exist(FN)) THEN
  BEGIN
    FN := General.DataPath+NS+'.ASW';
    IF (NOT Exist(FN)) THEN
    BEGIN
      Print('Answers file not found.');
      Exit;
    END;
  END;
  Assign(QF,FN);
  Reset(QF);
  IF (IOResult <> 0) THEN
    Print('"'+FN+'": unable to open.')
  ELSE
  BEGIN
    UserFound := FALSE;
    ExactMatch;
    IF (NOT UserFound) AND (NOT Abort) THEN
      Print('That user has not completed the questionnaire.')
    ELSE
    BEGIN
      IF (CoSysOp) THEN
        Print(QS);
      REPEAT
        WKey;
        ReadLn(QF,QS);
        IF (Copy(QS,1,6) <> 'Date: ') OR (CoSysOp) THEN
          IF (Copy(QS,1,6) <> 'User: ') THEN
            PrintACR(QS)
          ELSE
            UserFound := FALSE;
      UNTIL EOF(QF) OR (NOT UserFound) OR (Abort) OR (HangUp);
    END;
    Close(QF);
  END;
  LastError := IOResult;
END;

PROCEDURE ReadASW1(MenuOption: Str50);
VAR
  PS: PathStr;
  NS: NameStr;
  ES: ExtStr;
  UserN: Integer;
BEGIN
  IF (MenuOption = '') THEN
  BEGIN
    Prt('Enter filename: ');
    MPL(8);
    Input(MenuOption,8);
    NL;
    IF (MenuOption = '') THEN
      Exit;
  END;
  FSplit(MenuOption,PS,NS,ES);
  MenuOption := AllCaps(General.DataPath+NS+'.ASW');
  IF (NOT Exist(MenuOption)) THEN
  BEGIN
    MenuOption := AllCaps(General.MiscPath+NS+'.ASW');
    IF (NOT Exist(MenuOption)) THEN
    BEGIN
      Print('InfoForm answer file not found: "'+MenuOption+'"');
      Exit;
    END;
  END;
  NL;
  Print('Enter the name of the user to view: ');
  Prt(':');
  LFindUserWS(UserN);
  IF (UserN <> 0) THEN
    ReadASW(UserN,MenuOption)
  ELSE IF (CoSysOp) THEN
  BEGIN
    NL;
    IF PYNQ('List entire answer file? ',0,FALSE) THEN
    BEGIN
      NL;
      PrintF(NS+'.ASW');
    END;
  END;
END;

END.
