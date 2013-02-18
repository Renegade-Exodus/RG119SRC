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
  WriteLn('Renegade System Configuration String Compiler Version 1.0');
  Writeln('Copyright 2006 - The Renegade Developement Team');
  WriteLn;
  Write('Compiling strings ... ');
  Found := TRUE;
  Assign(StrPointerFile,'RGSCFGPR.DAT');
  ReWrite(StrPointerFile);
  Assign(RGStrFile,'RGSCFGTX.DAT');
  ReWrite(RGStrFile,1);
  Assign(F,'RGSCFG.TXT');
  Reset(F);
  WHILE NOT EOF(F) AND (Found) DO
  BEGIN
    ReadLn(F,S);
    IF (S <> '') AND (S[1] = '$') THEN
    BEGIN
      Delete(S,1,1);
      S := AllCaps(S);
      RGStrNum := -1;
      IF (S = 'SYSTEM_CONFIGURATION_MENU') THEN
        RGStrNum := 0
      ELSE IF (S = 'MAIN_BBS_CONFIGURATION') THEN
        RGStrNum := 1
      ELSE IF (S = 'MAIN_BBS_CONFIGURATION_BBS_NAME') THEN
        RGStrNum := 2
      ELSE IF (S = 'MAIN_BBS_CONFIGURATION_BBS_PHONE') THEN
        RGStrNum := 3
      ELSE IF (S = 'MAIN_BBS_CONFIGURATION_TELNET_URL') THEN
        RGStrNum := 4
      ELSE IF (S = 'MAIN_BBS_CONFIGURATION_SYSOP_NAME') THEN
        RGStrNum := 5
      ELSE IF (S = 'MAIN_BBS_CONFIGURATION_SYSOP_CHAT_HOURS') THEN
        RGStrNum := 6
      ELSE IF (S = 'MAIN_BBS_CONFIGURATION_MINIMUM_BAUD_HOURS') THEN
        RGStrNum := 7
      ELSE IF (S = 'MAIN_BBS_CONFIGURATION_DOWNLOAD_HOURS') THEN
        RGStrNum := 8
      ELSE IF (S = 'MAIN_BBS_CONFIGURATION_MINIMUM_BAUD_DOWNLOAD_HOURS') THEN
        RGStrNum := 9
      ELSE IF (S = 'MAIN_BBS_CONFIGURATION_SYSOP_PASSWORD_MENU') THEN
        RGStrNum := 10
      ELSE IF (S = 'MAIN_BBS_CONFIGURATION_SYSOP_PASSWORD') THEN
        RGStrNum := 11
      ELSE IF (S = 'MAIN_BBS_CONFIGURATION_NEW_USER_PASSWORD') THEN
        RGStrNum := 12
      ELSE IF (S = 'MAIN_BBS_CONFIGURATION_BAUD_OVERRIDE_PASSWORD') THEN
        RGStrNum := 13
      ELSE IF (S = 'MAIN_BBS_CONFIGURATION_PRE_EVENT_TIME') THEN
        RGStrNum := 14
      ELSE IF (S = 'MAIN_BBS_CONFIGURATION_SYSTEM_MENUS') THEN
        RGStrNum := 15
      ELSE IF (S = 'MAIN_BBS_CONFIGURATION_SYSTEM_MENUS_GLOBAL') THEN
        RGStrNum := 16
      ELSE IF (S = 'MAIN_BBS_CONFIGURATION_SYSTEM_MENUS_START') THEN
        RGStrNum := 17
      ELSE IF (S = 'MAIN_BBS_CONFIGURATION_SYSTEM_MENUS_SHUTTLE') THEN
        RGStrNum := 18
      ELSE IF (S = 'MAIN_BBS_CONFIGURATION_SYSTEM_MENUS_NEW_USER') THEN
        RGStrNum := 19
      ELSE IF (S = 'MAIN_BBS_CONFIGURATION_SYSTEM_MENUS_MESSAGE_READ') THEN
        RGStrNum := 20
      ELSE IF (S = 'MAIN_BBS_CONFIGURATION_SYSTEM_MENUS_FILE_LISTING') THEN
        RGStrNum := 21
      ELSE IF (S = 'MAIN_BBS_CONFIGURATION_BULLETIN_PREFIX') THEN
        RGStrNum := 22
      ELSE IF (S = 'MAIN_BBS_CONFIGURATION_LOCAL_SECURITY') THEN
        RGStrNum := 23

      ELSE IF (S = 'MAIN_BBS_CONFIGURATION_DATA_PATH') THEN
        RGStrNum := 24
      ELSE IF (S = 'MAIN_BBS_CONFIGURATION_MISC_PATH') THEN
        RGStrNum := 25
      ELSE IF (S = 'MAIN_BBS_CONFIGURATION_MSG_PATH') THEN
        RGStrNum := 26
      ELSE IF (S = 'MAIN_BBS_CONFIGURATION_NODELIST_PATH') THEN
        RGStrNum := 27
      ELSE IF (S = 'MAIN_BBS_CONFIGURATION_LOG_PATH') THEN
        RGStrNum := 28
      ELSE IF (S = 'MAIN_BBS_CONFIGURATION_TEMP_PATH') THEN
        RGStrNum := 29
      ELSE IF (S = 'MAIN_BBS_CONFIGURATION_PROTOCOL_PATH') THEN
        RGStrNum := 30
      ELSE IF (S = 'MAIN_BBS_CONFIGURATION_ARCHIVE_PATH') THEN
        RGStrNum := 31
      ELSE IF (S = 'MAIN_BBS_CONFIGURATION_ATTACH_PATH') THEN
        RGStrNum := 32
      ELSE IF (S = 'MAIN_BBS_CONFIGURATION_MULTNODE_PATH') THEN
        RGStrNum := 33;
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