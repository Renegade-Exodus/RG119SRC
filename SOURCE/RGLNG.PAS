{$IFDEF WIN32}
{$I DEFINES.INC}
{$ENDIF}

PROGRAM RGLNG;

USES
  Crt,
  Dos;

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

FUNCTION SQOutSp(S: STRING): STRING;
BEGIN
  WHILE (Pos(' ',S) > 0) DO
    Delete(s,Pos(' ',S),1);
  SQOutSp := S;
END;

FUNCTION Exist(FN: STRING): Boolean;
VAR
  DirInfo: SearchRec;
BEGIN
  FindFirst(SQOutSp(FN),AnyFile,DirInfo);
  Exist := (DOSError = 0);
END;

PROCEDURE CompileLanguageStrings;
BEGIN
  WriteLn;
  Write('Compiling language strings ... ');
  Found := TRUE;
  Assign(StrPointerFile,'RGLNGPR.DAT');
  ReWrite(StrPointerFile);
  Assign(RGStrFile,'RGLNGTX.DAT');
  ReWrite(RGStrFile,1);
  Assign(F,'RGLNG.TXT');
  Reset(F);
  WHILE NOT EOF(F) AND (Found) DO
  BEGIN
    ReadLn(F,S);
    IF (S <> '') AND (S[1] = '$') THEN
    BEGIN
      Delete(S,1,1);
      S := AllCaps(S);
      RGStrNum := -1;
      IF (S = 'ANONYMOUS_STRING') THEN
        RGStrNum := 0
      ELSE IF (S = 'ECHO_CHAR_FOR_PASSWORDS') THEN
        RGStrNum := 1
      ELSE IF (S = 'ENGAGE_CHAT') THEN
        RGStrNum := 2
      ELSE IF (S = 'END_CHAT') THEN
        RGStrNum := 3
      ELSE IF (S = 'SYSOP_WORKING') THEN
        RGStrNum := 4
      ELSE IF (S = 'PAUSE') THEN
        RGStrNum := 5
      ELSE IF (S = 'ENTER_MESSAGE_LINE_ONE') THEN
        RGStrNum := 6
      ELSE IF (S = 'ENTER_MESSAGE_LINE_TWO') THEN
        RGStrNum := 7
      ELSE IF (S = 'NEWSCAN_BEGIN') THEN
        RGStrNum := 8
      ELSE IF (S = 'NEWSCAN_DONE') THEN
        RGStrNum := 9
      ELSE IF (S = 'AUTO_MESSAGE_TITLE') THEN
        RGStrNum := 10
      ELSE IF (S = 'AUTO_MESSAGE_BORDER_CHARACTERS') THEN
        RGStrNum := 11
      ELSE IF (S = 'SYSOP_SHELLING_TO_DOS') THEN
        RGStrNum := 12
      ELSE IF (S = 'READ_MAIL') THEN
        RGStrNum := 13
      ELSE IF (S = 'PAGING_SYSOP') THEN
        RGStrNum := 14
      ELSE IF (S = 'CHAT_CALL') THEN
        RGStrNum := 15
      ELSE IF (S = 'BULLETIN_PROMPT') THEN
        RGstrNum := 16
      ELSE IF (S = 'PROTOCOL_PROMPT') THEN
        RGStrNum := 17
      ELSE IF (S = 'LIST_FILES') THEN
        RGStrNum := 18
      ELSE IF (S = 'SEARCH_FOR_NEW_FILES') THEN
        RGStrNum := 19
      ELSE IF (S = 'SEARCH_ALL_DIRS_FOR_FILE_MASK') THEN
        RGStrNum := 20
      ELSE IF (S = 'SEARCH_FOR_DESCRIPTIONS') THEN
        RGStrNum := 21
      ELSE IF (S = 'ENTER_THE_STRING_TO_SEARCH_FOR') THEN
        RGStrNum := 22
      ELSE IF (S = 'DOWNLOAD') THEN
        RGStrNum := 23
      ELSE IF (S = 'UPLOAD') THEN
        RGStrNum := 24
      ELSE IF (S = 'VIEW_INTERIOR_FILES') THEN
        RGStrNum := 25
      ELSE IF (S = 'INSUFFICIENT_FILE_CREDITS') THEN
        RGStrNum := 26
      ELSE IF (S = 'RATIO_IS_UNBALANCED') THEN
        RGStrNum := 27
      ELSE IF (S = 'ALL_FILES') THEN
        RGStrNum := 28
      ELSE IF (S = 'FILE_MASK') THEN
        RGStrNum := 29
      ELSE IF (S = 'FILE_ADDED_TO_BATCH_QUEUE') THEN
        RGStrNum := 30
      ELSE IF (S = 'BATCH_DOWNLOAD_FLAGGING') THEN
        RGStrNum := 31
      ELSE IF (S = 'READ_QUESTION_PROMPT') THEN
        RGStrNum := 32
      ELSE IF (S = 'SYSTEM_PASSWORD_PROMPT') THEN
        RGStrNum := 33
      ELSE IF (S = 'DEFAULT_MESSAGE_TO') THEN
        RGStrNum := 34
      ELSE IF (S = 'NEWSCAN_ALL') THEN
        RGStrNum := 35
      ELSE IF (S = 'NEWSCAN_DONE') THEN
        RGStrNum := 36
      ELSE IF (S = 'CHAT_REASON') THEN
        RGStrNum := 37
      ELSE IF (S = 'USER_DEFINED_QUESTION_ONE') THEN
        RGStrNum := 38
      ELSE IF (S = 'USER_DEFINED_QUESTION_TWO') THEN
        RGStrNum := 39
      ELSE IF (S = 'USER_DEFINED_QUESTION_THREE') THEN
        RGStrNum := 40
      ELSE IF (S = 'USER_DEFINED_QUESTION_EDITOR_ONE') THEN
        RGStrNum := 41
      ELSE IF (S = 'USER_DEFINED_QUESTION_EDITOR_TWO') THEN
        RGStrNum := 42
      ELSE IF (S = 'USER_DEFINED_QUESTION_EDITOR_THREE') THEN
        RGStrNum := 43
      ELSE IF (S = 'CONTINUE_PROMPT') THEN
        RGStrNum := 44
      ELSE IF (S = 'INVISIBLE_LOGIN') THEN
        RGStrNum := 45
      ELSE IF (S = 'CANT_EMAIL') THEN
        RGStrNum := 46
      ELSE IF (S = 'SEND_EMAIL') THEN
        RGStrNum := 47
      ELSE IF (S = 'SENDING_MASS_MAIL_TO') THEN
        RGStrNum := 48
      ELSE IF (S = 'SENDING_MASS_MAIL_TO_ALL_USERS') THEN
        RGStrNum := 49
      ELSE IF (S = 'NO_NETMAIL') THEN
        RGStrNum := 50
      ELSE IF (S = 'NETMAIL_PROMPT') THEN
        RGStrNum := 51
      ELSE IF (S = 'NO_MAIL_WAITING') THEN
        RGStrNum := 52
      ELSE IF (S = 'MUST_READ_MESSAGE') THEN
        RGStrNum := 53
      ELSE IF (S = 'SCAN_FOR_NEW_FILES') THEN
        RGStrNum := 54
      ELSE IF (S = 'NEW_SCAN_CHAR_FILE') THEN
        RGStrNum := 55
      ELSE IF (S = 'BULLETINS_PROMPT') THEN
        RGStrNum := 56
      ELSE IF (S = 'QUICK_LOGON') THEN
        RGStrNum := 57
      ELSE IF (S = 'MESSAGE_AREA_SELECT_HEADER') THEN
        RGStrNum := 58
      ELSE IF (S = 'FILE_AREA_SELECT_HEADER') THEN
        RGStrNum := 59
      ELSE IF (S = 'RECEIVE_EMAIL_HEADER') THEN
        RGStrNum := 60
      ELSE IF (S = 'VOTE_LIST_TOPICS_HEADER') THEN
        RGStrNum := 61
      ELSE IF (S = 'VOTE_TOPIC_RESULT_HEADER') THEN
        RGStrNum := 62
      ELSE IF (S = 'FILE_AREA_NAME_HEADER_NO_RATIO') THEN
        RGStrNum := 63
      ELSE IF (S = 'FILE_AREA_NAME_HEADER_RATIO') THEN
        RGStrNum := 64
      ELSE IF (S = 'SYSOP_CHAT_HELP') THEN
        RGStrNum := 65
      ELSE IF (S = 'NEW_SCAN_CHAR_MESSAGE') THEN
        RGStrNum := 66
      ELSE IF (S = 'FILE_AREA_SELECT_NO_FILES') THEN
        RGStrNum := 67
      ELSE IF (S = 'MESSAGE_AREA_SELECT_NO_FILES') THEN
        RGStrNum := 68
      ELSE IF (S = 'MESSAGE_AREA_LIST_PROMPT') THEN
        RGStrNum := 69
      ELSE IF (S = 'FILE_AREA_LIST_PROMPT') THEN
        RGStrNum := 70
      ELSE IF (S = 'FILE_MESSAGE_AREA_LIST_HELP') THEN
        RGStrNum := 71
      ELSE IF (S = 'FILE_AREA_CHANGE_PROMPT') THEN
        RGStrNum := 72
      ELSE IF (S = 'MESSAGE_AREA_CHANGE_PROMPT') THEN
        RGStrNum := 73
      ELSE IF (S = 'FILE_AREA_NEW_SCAN_TOGGLE_PROMPT') THEN
        RGStrNum := 74
      ELSE IF (S = 'MESSAGE_AREA_NEW_SCAN_TOGGLE_PROMPT') THEN
        RGStrNum := 75
      ELSE IF (S = 'FILE_AREA_MOVE_FILE_PROMPT') THEN
        RGStrNum := 76
      ELSE IF (S = 'MESSAGE_AREA_MOVE_MESSAGE_PROMPT') THEN
        RGStrNum := 77
      ELSE IF (S = 'FILE_AREA_CHANGE_MIN_MAX_ERROR') THEN
        RGStrNum := 78
      ELSE IF (S = 'MESSAGE_AREA_CHANGE_MIN_MAX_ERROR') THEN
        RGStrNum := 79
      ELSE IF (S = 'FILE_AREA_CHANGE_NO_AREA_ACCESS') THEN
        RGStrNum := 80
      ELSE IF (S = 'MESSAGE_AREA_CHANGE_NO_AREA_ACCESS') THEN
        RGStrNum := 81
      ELSE IF (S = 'FILE_AREA_CHANGE_LOWEST_AREA') THEN
        RGStrNum := 82
      ELSE IF (S = 'FILE_AREA_CHANGE_HIGHEST_AREA') THEN
        RGStrNum := 83
      ELSE IF (S = 'MESSAGE_AREA_CHANGE_LOWEST_AREA') THEN
        RGStrNum := 84
      ELSE IF (S = 'MESSAGE_AREA_CHANGE_HIGHEST_AREA') THEN
        RGStrNum := 85
      ELSE IF (S = 'FILE_AREA_NEW_SCAN_SCANNING_ALL_AREAS') THEN
        RGStrNum := 86
      ELSE IF (S = 'MESSAGE_AREA_NEW_SCAN_SCANNING_ALL_AREAS') THEN
        RGStrNum := 87
      ELSE IF (S = 'FILE_AREA_NEW_SCAN_NOT_SCANNING_ALL_AREAS') THEN
        RGStrNum := 88
      ELSE IF (S = 'MESSAGE_AREA_NEW_SCAN_NOT_SCANNING_ALL_AREAS') THEN
        RGStrNum := 89
      ELSE IF (S = 'FILE_AREA_NEW_SCAN_MIN_MAX_ERROR') THEN
        RGStrNum := 90
      ELSE IF (S = 'MESSAGE_AREA_NEW_SCAN_MIN_MAX_ERROR') THEN
        RGStrNum := 91
      ELSE IF (S = 'FILE_AREA_NEW_SCAN_AREA_ON_OFF') THEN
        RGStrNum := 92
      ELSE IF (S = 'MESSAGE_AREA_NEW_SCAN_AREA_ON_OFF') THEN
        RGStrNum := 93
      ELSE IF (S = 'MESSAGE_AREA_NEW_SCAN_AREA_NOT_REMOVED') THEN
        RGStrNum := 94;

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
END;

PROCEDURE CompileMainStrings;
BEGIN
  WriteLn;
  Write('Compiling main strings ... ');
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
END;

PROCEDURE CompileNoteStrings;
BEGIN
  WriteLn;
  Write('Compiling Note strings ... ');
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
END;

PROCEDURE CompileSysOpStrings;
BEGIN
  WriteLn;
  Write('Compiling sysop strings ... ');
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
      ELSE IF (S = 'MAIN_BBS_CONFIGURATION_STRING_PATH') THEN
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
END;

PROCEDURE CompileFileAreaEditorStrings;
BEGIN
  WriteLn;
  Write('Compiling file area editor strings ... ');
  Found := TRUE;
  Assign(StrPointerFile,'FAEPR.DAT');
  ReWrite(StrPointerFile);
  Assign(RGStrFile,'FAETX.DAT');
  ReWrite(RGStrFile,1);
  Assign(F,'FAELNG.TXT');
  Reset(F);
  WHILE NOT EOF(F) AND (Found) DO
  BEGIN
    ReadLn(F,S);
    IF (S <> '') AND (S[1] = '$') THEN
    BEGIN
      Delete(S,1,1);
      S := AllCaps(S);
      RGStrNum := -1;
      IF (S = 'FILE_AREA_HEADER_TOGGLE_ONE') THEN
        RGStrNum := 0
      ELSE IF (S = 'FILE_AREA_HEADER_TOGGLE_TWO') THEN
        RGStrNum := 1
      ELSE IF (S = 'FILE_AREA_HEADER_NO_FILE_AREAS') THEN
        RGStrNum := 2
      ELSE IF (S = 'FILE_AREA_EDITOR_PROMPT') THEN
        RGStrNum := 3
      ELSE IF (S = 'FILE_AREA_EDITOR_HELP') THEN
        RGStrNum := 4
      ELSE IF (S = 'NO_FILE_AREAS') THEN
        RGStrNum := 5
      ELSE IF (S = 'FILE_CHANGE_DRIVE_START') THEN
        RGStrNum := 6
      ELSE IF (S = 'FILE_CHANGE_DRIVE_END') THEN
        RGStrNum := 7
      ELSE IF (S = 'FILE_CHANGE_DRIVE_DRIVE') THEN
        RGStrNum := 8
      ELSE IF (S = 'FILE_CHANGE_INVALID_ORDER') THEN
        RGStrNum := 9
      ELSE IF (S = 'FILE_CHANGE_INVALID_DRIVE') THEN
        RGStrNum := 10
      ELSE IF (S = 'FILE_CHANGE_UPDATING_DRIVE') THEN
        RGStrNum := 11
      ELSE IF (S = 'FILE_CHANGE_UPDATING_DRIVE_DONE') THEN
        RGStrNum := 12
      ELSE IF (S = 'FILE_CHANGE_UPDATING_SYSOPLOG') THEN
        RGStrNum := 13
      ELSE IF (S = 'FILE_DELETE_PROMPT') THEN
        RGStrNum := 14
      ELSE IF (S = 'FILE_DELETE_DISPLAY_AREA') THEN
        RGStrNum := 15
      ELSE IF (S = 'FILE_DELETE_VERIFY_DELETE') THEN
        RGStrNum := 16
      ELSE IF (S = 'FILE_DELETE_NOTICE') THEN
        RGStrNum := 17
      ELSE IF (S = 'FILE_DELETE_SYSOPLOG') THEN
        RGStrNum := 18
      ELSE IF (S = 'FILE_DELETE_DATA_FILES') THEN
        RGStrNum := 19
      ELSE IF (S = 'FILE_DELETE_REMOVE_DL_DIRECTORY') THEN
        RGStrNum := 20
      ELSE IF (S = 'FILE_DELETE_REMOVE_UL_DIRECTORY') THEN
        RGStrNum := 21
      ELSE IF (S = 'FILE_INSERT_MAX_FILE_AREAS') THEN
        RGStrNum := 22
      ELSE IF (S = 'FILE_INSERT_PROMPT') THEN
        RGStrNum := 23
      ELSE IF (S = 'FILE_INSERT_AFTER_ERROR_PROMPT') THEN
        RGStrNum := 24
      ELSE IF (S = 'FILE_INSERT_CONFIRM_INSERT') THEN
        RGStrNum := 25
      ELSE IF (S = 'FILE_INSERT_NOTICE') THEN
        RGStrNum := 26
      ELSE IF (S = 'FILE_INSERT_SYSOPLOG') THEN
        RGStrNum := 27
      ELSE IF (S = 'FILE_MODIFY_PROMPT') THEN
        RGStrNum := 28
      ELSE IF (S = 'FILE_MODIFY_SYSOPLOG') THEN
        RGStrNum := 29
      ELSE IF (S = 'FILE_POSITION_NO_AREAS') THEN
        RGStrNum := 30
      ELSE IF (S = 'FILE_POSITION_PROMPT') THEN
        RGStrNum := 31
      ELSE IF (S = 'FILE_POSITION_NUMBERING') THEN
        RGStrNum := 32
      ELSE IF (S = 'FILE_POSITION_BEFORE_WHICH') THEN
        RGStrNum := 33
      ELSE IF (S = 'FILE_POSITION_NOTICE') THEN
        RGStrNum := 34
      ELSE IF (S = 'FILE_EDITING_AREA_HEADER') THEN
        RGStrNum := 35
      ELSE IF (S = 'FILE_INSERTING_AREA_HEADER') THEN
        RGStrNum := 36
      ELSE IF (S = 'FILE_EDITING_INSERTING_SCREEN') THEN
        RGStrNum := 37
      ELSE IF (S = 'FILE_EDITING_INSERTING_PROMPT') THEN
        RGStrNum := 38
      ELSE IF (S = 'FILE_AREA_NAME_CHANGE') THEN
        RGStrNum := 39
      ELSE IF (S = 'FILE_FILE_NAME_CHANGE') THEN
        RGStrNum := 40
      ELSE IF (S = 'FILE_DUPLICATE_FILE_NAME_ERROR') THEN
        RGStrNum := 41
      ELSE IF (S = 'FILE_USE_DUPLICATE_FILE_NAME') THEN
        RGStrNum := 42
      ELSE IF (S = 'FILE_OLD_DATA_FILES_PATH') THEN
        RGStrNum := 43
      ELSE IF (S = 'FILE_NEW_DATA_FILES_PATH') THEN
        RGStrNum := 44
      ELSE IF (S = 'FILE_RENAME_DATA_FILES') THEN
        RGStrNum := 45
      ELSE IF (S = 'FILE_DL_PATH') THEN
        RGStrNum := 46
      ELSE IF (S = 'FILE_SET_DL_PATH_TO_UL_PATH') THEN
        RGStrNum := 47
      ELSE IF (S = 'FILE_UL_PATH') THEN
        RGStrNum := 48
      ELSE IF (S = 'FILE_ACS') THEN
        RGStrNum := 49
      ELSE IF (S = 'FILE_DL_ACCESS') THEN
        RGStrNum := 50
      ELSE IF (S = 'FILE_UL_ACCESS') THEN
        RGStrNum := 51
      ELSE IF (S = 'FILE_MAX_FILES') THEN
        RGStrNum := 52
      ELSE IF (S = 'FILE_PASSWORD') THEN
        RGStrNum := 53
      ELSE IF (S = 'FILE_ARCHIVE_TYPE') THEN
        RGStrNum := 54
      ELSE IF (S = 'FILE_COMMENT_TYPE') THEN
        RGStrNum := 55
      ELSE IF (S = 'FILE_TOGGLE_FLAGS') THEN
        RGStrNum := 56
      ELSE IF (S = 'FILE_MOVE_DATA_FILES') THEN
        RGStrNum := 57
      ELSE IF (S = 'FILE_TOGGLE_HELP') THEN
        RGStrNum := 58
      ELSE IF (S = 'FILE_JUMP_TO') THEN
        RGStrNum := 59
      ELSE IF (S = 'FILE_FIRST_VALID_RECORD') THEN
        RGStrNum := 60
      ELSE IF (S = 'FILE_LAST_VALID_RECORD') THEN
        RGStrNum := 61
      ELSE IF (S = 'FILE_INSERT_EDIT_HELP') THEN
        RGStrNum := 62
      ELSE IF (S = 'FILE_INSERT_HELP') THEN
        RGStrNum := 63
      ELSE IF (S = 'FILE_EDIT_HELP') THEN
        RGStrNum := 64
      ELSE IF (S = 'CHECK_AREA_NAME_ERROR') THEN
        RGStrNum := 65
      ELSE IF (S = 'CHECK_FILE_NAME_ERROR') THEN
        RGStrNum := 66
      ELSE IF (S = 'CHECK_DL_PATH_ERROR') THEN
        RGStrNum := 67
      ELSE IF (S = 'CHECK_UL_PATH_ERROR') THEN
        RGStrNum := 68
      ELSE IF (S = 'CHECK_ARCHIVE_TYPE_ERROR') THEN
        RGStrNum := 69
      ELSE IF (S = 'CHECK_COMMENT_TYPE_ERROR') THEN
        RGStrNum := 70;
      IF (RGStrNum = -1) THEN
      BEGIN
        WriteLn('Error!');
        WriteLn;
        WriteLn('The following string definition is invalid:');
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
END;

BEGIN
  CLrScr;
  WriteLn('Renegade Language String Compiler Version 3.1');
  Writeln('Copyright 2009 - The Renegade Developement Team');
  IF (NOT Exist('RGLNG.TXT')) THEN
  BEGIN
    WriteLn;
    WriteLn(^G^G^G'RGLNG.TXT does not exist!');
    Exit;
  END;
  IF (NOT Exist('RGMAIN.TXT')) THEN
  BEGIN
    WriteLn;
    WriteLn(^G^G^G'RGMAIN.TXT does not exists!');
    Exit;
  END;
  IF (NOT Exist('RGNOTE.TXT')) THEN
  BEGIN
    WriteLn;
    WriteLn(^G^G^G'RGNOTE.TXT does not exists!');
    Exit;
  END;
  IF (NOT Exist('RGSCFG.TXT')) THEN
  BEGIN
    WriteLn;
    WriteLn(^G^G^G'RGSCFG.TXT does not exists!');
    Exit;
  END;
  IF (NOT Exist('FAELNG.TXT')) THEN
  BEGIN
    WriteLn;
    WriteLn(^G^G^G'FAELNG.TXT does not exists!');
    Exit;
  END;
  CompileLanguageStrings;
  CompileMainStrings;
  CompileNoteStrings;
  CompileSysOpStrings;
  CompileFileAreaEditorStrings;
END.