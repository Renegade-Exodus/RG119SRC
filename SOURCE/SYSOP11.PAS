{$IFDEF WIN32}
{$I DEFINES.INC}
{$ENDIF}

{$A+,B-,D+,E-,F+,I-,L+,N-,O+,R-,S+,V-}

UNIT SysOp11;

INTERFACE

PROCEDURE ChangeUser;
PROCEDURE ShowLogs;

IMPLEMENTATION

USES
  Common,
  TimeFunc,
  MiscUser;

PROCEDURE ChangeUser;
VAR
  UNum: Integer;
BEGIN
  Prt('Change to which User (1-'+IntToStr(MaxUsers - 1)+'): ');
  FindUser(UNum);
  IF (UNum >= 1) THEN
  BEGIN
    SaveURec(ThisUser,UserNum);
    LoadURec(ThisUser,UNum);
    UserNum := UNum;
    ChopTime := 0;
    ExtraTime := 0;
    FreeTime := 0;
    IF (ComPortSpeed > 0) THEN
      SysOpLog('---> ^7Switched accounts to: ^5'+Caps(ThisUser.Name));
    Update_Screen;
    NewCompTables;
    LoadNode(ThisNode);
    WITH NodeR DO
    BEGIN
      User := UserNum;
      UserName := ThisUser.Name;
    END;
    SaveNode(ThisNode);
  END;
END;

PROCEDURE ShowLogs;
VAR
  TempStr: Str10;
  Day: Word;
BEGIN
  NL;
  Print('SysOp Logs available for up to '+IntToStr(General.BackSysOpLogs)+' days ago.');
  Prt('Date (MM/DD/YYYY) or # days ago (0-'+IntToStr(General.BackSysOpLogs)+') [0]: ');
  Input(TempStr,10);
  IF (Length(TempStr) = 10) AND (DayNum(TempStr) > 0) THEN
    Day := (DayNum(DateStr) - DayNum(TempStr))
  ELSE
    Day := StrToInt(TempStr);
  AllowContinue := TRUE;
  IF (Day = 0) THEN
    PrintF(General.LogsPath+'SYSOP.LOG')
  ELSE
    PrintF(General.LogsPath+'SYSOP'+IntToStr(Day)+'.LOG');
  AllowContinue := FALSE;
  IF (NoFile) THEN
  BEGIN
    NL;
    Print('SysOp log not found.');
  END;
  IF (UserOn) THEN
    SysOpLog('Viewed SysOp Log - '+AOnOff(Day = 0,'Today''s',IntToStr(Day)+' days ago'));
END;

END.
