PROGRAM RGLNG;

USES
  Crt,
  Dos,
  Common;

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
  WriteLn('Renegade File Area Editor Compiler Version 1.0');
  Writeln('Copyright 2009 - The Renegade Developement Team');
  IF (NOT Exist('FAELNG.TXT')) THEN
  BEGIN
    WriteLn;
    WriteLn(^G^G^G'FAELNG.TXT does not exist!');
    Exit;
  END;
  CompileFileAreaEditorStrings;
END.