{$IFDEF WIN32}
{$I DEFINES.INC}
{$ENDIF}

PROGRAM RGNOTE;

USES
  Crt;

TYPE
  StrPointerRec = RECORD
    Pointer,
    TextSize: LongInt;
  END;

VAR
  RGStrFile: FILE;
  StrPointerFile: FILE OF StrPointerRec;
  StrPointer: StrPointerRec;
  F: Text;
  S: STRING;
  RGStrNum: LongInt;
  Done,
  Found: Boolean;

FUNCTION AllCaps(S: STRING): STRING;
VAR
  I: Integer;
BEGIN
  FOR I := 1 TO Length(S) DO
    IF (S[I] IN ['a'..'z']) THEN
      S[I] := Chr(Ord(S[I]) - Ord('a')+Ord('A'));
  AllCaps := S;
END;

BEGIN
  CLrScr;
  WriteLn('Renegade System Notes String Compiler Version 1.0');
  Writeln('Copyright 2006 - The Renegade Developement Team');
  WriteLn;
  Write('Compiling strings ... ');
  Found := TRUE;
  Assign(StrPointerFile,'RGNOTEPR.DAT');
  ReWrite(StrPointerFile);
  Assign(RGStrFile,'RGNOTETX.DAT');
  ReWrite(RGStrFile,1);
  Assign(F,'RGNOTE.TXT');
  Reset(F);
  WHILE NOT EOF(F) AND (Found) DO
  BEGIN
    ReadLn(F,S);
    IF (S <> '') AND (S[1] = '$') THEN
    BEGIN
      Delete(S,1,1);
      S := AllCaps(S);
      RGStrNum := -1;
      IF (S = 'INTERNAL_USE_ONLY') THEN
        RGStrNum := 0
      ELSE IF (S = 'ONLY_CHANGE_LOCALLY') THEN
        RGStrNum := 1
      ELSE IF (S = 'INVALID_MENU_NUMBER') THEN
        RGStrNum := 2
      ELSE IF (S = 'MINIMUM_BAUD_LOGON_PW') THEN
        RGStrNum := 3
      ELSE IF (S = 'MINIMUM_BAUD_LOGON_HIGH_LOW_TIME_PW') THEN
        RGStrNum := 4
      ELSE IF (S = 'MINIMUM_BAUD_LOGON_HIGH_LOW_TIME_NO_PW') THEN
        RGStrNum := 5
      ELSE IF (S = 'LOGON_EVENT_RESTRICTED_1') THEN
        RGStrNum := 6
      ELSE IF (S = 'LOGON_EVENT_RESTRICTED_2') THEN
        RGStrNum := 7
      ELSE IF (S = 'NAME_NOT_FOUND') THEN
        RGStrNum := 8
      ELSE IF (S = 'ILLEGAL_LOGON') THEN
        RGStrNum := 9
      ELSE IF (S = 'LOGON_NODE_ACS') THEN
        RGStrNum := 10
      ELSE IF (S = 'LOCKED_OUT') THEN
        RGStrNum := 11
      ELSE IF (S = 'LOGGED_ON_ANOTHER_NODE') THEN
        RGStrNum := 12
      ELSE IF (S = 'INCORRECT_BIRTH_DATE') THEN
        RGStrNum := 13
      ELSE IF (S = 'INSUFFICIENT_LOGON_CREDITS') THEN
        RGStrNum := 14
      ELSE IF (S = 'LOGON_ONCE_PER_DAY') THEN
        RGStrNum := 15
      ELSE IF (S = 'LOGON_CALLS_ALLOWED_PER_DAY') THEN
        RGStrNum := 16
      ELSE IF (S = 'LOGON_TIME_ALLOWED_PER_DAY_OR_CALL') THEN
        RGStrNum := 17
      ELSE IF (S = 'LOGON_MINUTES_LEFT_IN_BANK') THEN
        RGStrNum := 18
      ELSE IF (S = 'LOGON_MINUTES_LEFT_IN_BANK_TIME_LEFT') THEN
        RGStrNum := 19
      ELSE IF (S = 'LOGON_BANK_HANGUP') THEN
        RGStrNum := 20
      ELSE IF (S = 'LOGON_ATTEMPT_IEMSI_NEGOTIATION') THEN
        RGStrNum := 21
      ELSE IF (S = 'LOGON_IEMSI_NEGOTIATION_SUCCESS') THEN
        RGStrNum := 22
      ELSE IF (S = 'LOGON_IEMSI_NEGOTIATION_FAILED') THEN
        RGStrNum := 23
      ELSE IF (S = 'LOGON_ATTEMPT_DETECT_EMULATION') THEN
        RGStrNum := 24
      ELSE IF (S = 'LOGON_RIP_DETECTED') THEN
        RGStrNum := 25
      ELSE IF (S = 'LOGON_ANSI_DETECT_OTHER') THEN
        RGStrNum := 26
      ELSE IF (S = 'LOGON_ANSI_DETECT') THEN
        RGStrNum := 27
      ELSE IF (S = 'LOGON_AVATAR_DETECT_OTHER') THEN
        RGStrNum := 28
      ELSE IF (S = 'LOGON_AVATAR_DETECT') THEN
        RGStrNum := 29
      ELSE IF (S = 'LOGON_EMULATION_DETECTED') THEN
        RGStrNum := 30
      ELSE IF (S = 'SHUTTLE_LOGON_VALIDATION_STATUS') THEN
        RGStrNum := 31
      ELSE IF (S = 'LOGON_CLOSED_BBS') THEN
        RGStrNum := 32
      ELSE IF (S = 'NODE_ACTIVITY_WAITING_ONE') THEN
        RGStrNum := 33
      ELSE IF (S = 'NODE_ACTIVITY_WAITING_TWO') THEN
        RGStrNum := 34
      ELSE IF (S = 'NODE_ACTIVITY_LOGGING_ON') THEN
        RGStrNum := 35
      ELSE IF (S = 'NODE_ACTIVITY_NEW_USER_LOGGING_ON') THEN
        RGStrNum := 36
      ELSE IF (S = 'NODE_ACTIVITY_MISCELLANEOUS') THEN
        RGStrNum := 37
      ELSE IF (S = 'NEW_USER_PASSWORD_INVALID') THEN
        RGStrNum := 38
      ELSE IF (S = 'NEW_USER_PASSWORD_ATTEMPT_EXCEEDED') THEN
        RGStrNum := 39
      ELSE IF (S = 'NEW_USER_RECORD_SAVING') THEN
        RGStrNum := 40
      ELSE IF (S = 'NEW_USER_RECORD_SAVED') THEN
        RGStrNum := 41
      ELSE IF (S = 'NEW_USER_APPLICATION_LETTER') THEN
        RGStrNum := 42
      ELSE IF (S = 'NEW_USER_IN_RESPONSE_TO_SUBJ') THEN
        RGStrNum := 43;

      IF (RGStrNum = -1) THEN
      BEGIN
        WriteLn('Error!');
        WriteLn;
        WriteLn(^G^G^G'The following string definition is invalid:');
        WriteLn;
        WriteLn('   '+S);
        Found := FALSE;
      END
      ELSE
      BEGIN
        Done := FALSE;
        WITH StrPointer DO
        BEGIN
          Pointer := (FileSize(RGStrFile) + 1);
          TextSize := 0;
        END;
        Seek(RGStrFile,FileSize(RGStrFile));
        WHILE NOT EOF(F) AND (NOT Done) DO
        BEGIN
          ReadLn(F,S);
          IF (S[1] = '$') THEN
            Done := TRUE
          ELSE
          BEGIN
            Inc(StrPointer.TextSize,(Length(S) + 1));
            BlockWrite(RGStrFile,S,(Length(S) + 1));
          END;
        END;
        Seek(StrPointerFile,RGStrNum);
        Write(StrPointerFile,StrPointer);
      END;
    END;
  END;
  Close(F);
  Close(RGStrFile);
  Close(StrPointerFile);
  IF (Found) THEN
    WriteLn('Done!')
  ELSE
  BEGIN
    Erase(StrPointerFile);
    Erase(RGStrFile);
  END;
END.