{$IFDEF WIN32}
{$I DEFINES.INC}
{$ENDIF}

PROGRAM RGMAIN;

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
  Done,Found: Boolean;

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
  WriteLn('Renegade Main String Compiler Version 1.0');
  Writeln('Copyright 2006 - The Renegade Developement Team');
  WriteLn;
  Write('Compiling strings ... ');
  Found := TRUE;
  Assign(StrPointerFile,'RGMAINPR.DAT');
  ReWrite(StrPointerFile);
  Assign(RGStrFile,'RGMAINTX.DAT');
  ReWrite(RGStrFile,1);
  Assign(F,'RGMAIN.TXT');
  Reset(F);
  WHILE NOT EOF(F) AND (Found) DO
  BEGIN
    ReadLn(F,S);
    IF (S <> '') AND (S[1] = '$') THEN
    BEGIN
      Delete(S,1,1);
      S := AllCaps(S);
      RGStrNum := -1;
      IF (S = 'BAUD_OVERRIDE_PW') THEN
        RGStrNum := 0
      ELSE IF (S = 'CALLER_LOGON') THEN
        RGStrNum := 1
      ELSE IF (S = 'LOGON_AS_NEW') THEN
        RGStrNum := 2
      ELSE IF (S = 'USER_LOGON_PASSWORD') THEN
        RGStrNum := 3
      ELSE IF (S = 'USER_LOGON_PHONE_NUMBER') THEN
        RGStrNum := 4
      ELSE IF (S = 'SYSOP_LOGON_PASSWORD') THEN
        RGStrNum := 5
      ELSE IF (S = 'FORGOT_PW_QUESTION') THEN
        RGStrNum := 6
      ELSE IF (S = 'VERIFY_BIRTH_DATE') THEN
        RGStrNum := 7
      ELSE IF (S = 'LOGON_WITHDRAW_BANK') THEN
        RGStrNum := 8
      ELSE IF (S = 'SHUTTLE_LOGON') THEN
        RGStrNum := 9
      ELSE IF (S = 'NEW_USER_PASSWORD') THEN
        RGStrNum := 10;
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