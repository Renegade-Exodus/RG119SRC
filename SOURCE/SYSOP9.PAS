{$IFDEF WIN32}
{$I DEFINES.INC}
{$ENDIF}

{$A+,B-,D+,E-,F+,I-,L+,N-,O+,R-,S+,V-}
UNIT SysOp9;

INTERFACE

PROCEDURE FileAreaEditor;

IMPLEMENTATION

USES
  Common,
  File0,
  File2,
  SysOp2K;

PROCEDURE FileAreaEditor;
TYPE
  MCIVarRecord = Record
    OldPath,
    NewPath: AStr;
    Drive: Char;
    FirstRecNum,
    LastRecNum,
    RecNumToEdit: SmallInt;
  END;

CONST
  DisplayType: Byte = 1;

VAR
  TempMemFileArea: FileAreaRecordType;
  MCIVars: MCIVarRecord;
  Cmd: Char;
  RecNumToList: Integer;
  SaveTempPause: Boolean;

  FUNCTION DisplayFAFlags(FAFlags: FAFlagSet; C1,C2: Char): AStr;
  VAR
    FAFlagT: FileAreaFlagType;
    DisplayStr: AStr;
  BEGIN
    DisplayStr := '';
    FOR FAFlagT := FANoRatio TO FANoDupeCheck DO
    BEGIN
      IF (FAFlagT IN FAFlags) THEN
        DisplayStr := DisplayStr + '^'+C1+Copy('NUISGCDP',(Ord(FAFlagT) + 1),1)
      ELSE
        DisplayStr := DisplayStr + '^'+C2+'-'
    END;
    DisplayFAFlags := DisplayStr;
  END;

  PROCEDURE ToggleFAFlag(FAFlagT: FileAreaFlagType; VAR FAFlags: FAFlagSet);
  BEGIN
    IF (FAFlagT IN FAFlags) THEN
      Exclude(FAFlags,FAFlagT)
    ELSE
      Include(FAFlags,FAFlagT);
  END;

  PROCEDURE ToggleFAFlags(C: Char; VAR FAFlags: FAFlagSet; VAR Changed: Boolean);
  VAR
    SaveFAFlags: FAFlagSet;
  BEGIN
    SaveFAFlags := FAFlags;
    CASE C OF
      'N' : ToggleFAFlag(FANoRatio,FAFlags);
      'U' : ToggleFAFlag(FAUnHidden,FAFlags);
      'I' : ToggleFAFlag(FADirDLPath,FAFlags);
      'S' : ToggleFAFlag(FAShowName,FAFlags);
      'G' : ToggleFAFlag(FAUseGIFSpecs,FAFlags);
      'C' : ToggleFAFlag(FACDRom,FAFlags);
      'D' : ToggleFAFlag(FAShowDate,FAFlags);
      'P' : ToggleFAFlag(FANoDupeCheck,FAFlags);
    END;
    IF (FAFlags <> SaveFAFlags) THEN
      Changed := TRUE;
  END;

  PROCEDURE InitFileAreaVars(VAR MemFileArea: FileAreaRecordType);
  BEGIN
    FillChar(MemFileArea,SizeOf(MemFileArea),0);
    WITH MemFileArea DO
    BEGIN
      AreaName := '<< New File Area >>';
      FileName := 'NEWDIR';
      DLPath := StartDir[1]+':\';
      ULPath := DLPath;
      MaxFiles := 2000;
      Password := '';
      ArcType := 0;
      CmtType := 0;
      ACS := '';
      ULACS := '';
      DLACS := '';
      FAFlags := [];
    END;
  END;

  FUNCTION FAEMCI(CONST S: STRING; MemFileArea: FileAreaRecordType; MCIVars1: MCIVarRecord): STRING;
  VAR
    Temp: STRING;
    Add: AStr;
    Index: Byte;
  BEGIN
    Temp := '';
    FOR Index := 1 TO Length(S) DO
      IF (S[Index] = '%') AND (Index + 1 < Length(S)) THEN
      BEGIN
        Add := '%' + S[Index + 1] + S[Index + 2];
          CASE UpCase(S[Index + 1]) OF
          'A' : CASE UpCase(S[Index + 2]) OF
                  'N' : Add := MemFileArea.AreaName;
                  'R' : Add := AOnOff((MemFileArea.ACS = ''),'*None*',MemFileArea.ACS);
                  'T' : Add := AOnOff((MemFileArea.ArcType = 0),'*None*',General.FileArcInfo[MemFileArea.ArcType].Ext);
                END;
          'C' : CASE UpCase(S[Index + 2]) OF
                  'T' : Add := +AOnOff((MemFileArea.CmtType = 0),'*None*',IntToStr(MemFileArea.CmtType));
                END;
          'D' : CASE UpCase(S[Index + 2]) OF
                  'D' : Add := MCIVars1.Drive;
                  'P' : Add := MemFileArea.DLPath;
                  'R' : Add := AOnOff((MemFileArea.DLACS = ''),'*None*',MemFileArea.DLACS);
                END;
          'F' : CASE UpCase(S[Index + 2]) OF
                  'N' : Add := MemFileArea.FileName;
                  'R' : Add := IntToStr(MCIVars1.FirstRecNum);
                  'S' : Add := DisplayFAFlags(MemFileArea.FAFlags,'5','1');
                  'T' : Add := DisplayFAFlags(MemFileArea.FAFlags,'5','4');
                END;
          'G' : CASE UpCase(S[Index + 2]) OF
                  'D' : Add := GetDirPath(MemFileArea);
                END;
          'L' : CASE UpCase(S[Index + 2]) OF
                  'R' : Add := IntToStr(MCIVars1.LastRecNum);
                END;
          'M' : CASE UpCase(S[Index + 2]) OF
                  'A' : Add := IntToStr(MaxFileAreas);
                  'F' : Add := IntToStr(MemFileArea.MaxFiles);
                END;
          'N' : CASE UpCase(S[Index + 2]) OF
                  'A' : Add := IntToStr(NumFileAreas);
                  'F' : Add := IntToStr(NumFileAreas + 1);
                  'P' : Add := MCIVars1.NewPath;
                END;
          'O' : CASE UpCase(S[Index + 2]) OF
                  'P' : Add := MCIVars1.OldPath;
                END;
          'P' : CASE UpCase(S[Index + 2]) OF
                  'W' : Add := AOnOff((MemFileArea.Password = ''),'*None*',MemFileArea.Password);
                END;
          'R' : CASE UpCase(S[Index + 2]) OF
                  'E' : Add := IntToStr(MCIVars1.RecNumToEdit);
                END;
          'U' : CASE UpCase(S[Index + 2]) OF
                  'P' : Add := MemFileArea.ULPath;
                  'R' : Add := AOnOff((MemFileArea.ULACS = ''),'*None*',MemFileArea.ULACS);
                END;
          END;
        Temp := Temp + Add;
        Inc(Index,2);
      END
      ELSE
        Temp := Temp + S[Index];
    FAEMCI := Temp;
  END;

  FUNCTION FAELngStr(StrNum: LongInt; MemFileArea: FileAreaRecordType; MCIVars1: MCIVarRecord; PassValue: Boolean): AStr;
  VAR
    StrPointerFile: FILE OF StrPointerRec;
    StrPointer: StrPointerRec;
    RGStrFile: FILE;
    S: STRING;
    TotLoad: LongInt;
    Found: Boolean;
  BEGIN
    Assign(StrPointerFile,General.LMultPath+'FAEPR.DAT');
    Reset(StrPointerFile);
    Seek(StrPointerFile,StrNum);
    Read(StrPointerFile,StrPointer);
    Close(StrPointerFile);
    LastError := IOResult;
    TotLoad := 0;
    Assign(RGStrFile,General.LMultPath+'FAETX.DAT');
    Reset(RGStrFile,1);
    Seek(RGStrFile,(StrPointer.Pointer - 1));
    REPEAT
      BlockRead(RGStrFile,S[0],1);
      BlockRead(RGStrFile,S[1],Ord(S[0]));
      Inc(TotLoad,(Length(S) + 1));
      S := FAEMCI(S,MemFileArea,MCIVars1);
      IF (PassValue) THEN
      BEGIN
        IF (S[Length(s)] = '@') THEN
          Dec(S[0]);
      END
      ELSE
      BEGIN
        IF (S[Length(S)] = '@') THEN
        BEGIN
          Dec(S[0]);
          Prompt(S);
        END
        ELSE
          PrintACR(S);
      END;
    UNTIL (TotLoad >= StrPointer.TextSize) OR (Abort) OR (HangUp);
    Close(RGStrFile);
    LastError := IOResult;
    FAELNGStr := S;
  END;

  {
  ChangeFileArea External String Table

     1.  NO_FILE_AREAS

         %LF^7No file areas exist!^1
         %PA

     2.  FILE_CHANGE_DRIVE_START

         %LFFile area to start at? @

     3.  FILE_CHANGE_DRIVE_END

         %LFFile area to end at?' @

     4.  FILE_CHANGE_INVALID_ORDER

         %LF^7Invalid record number order!^1
         %PA

     5.  FILE_CHANGE_DRIVE_DRIVE

         %LFChange to which drive? (^5A^4-^5Z^4): @

     6.  FILE_CHANGE_INVALID_DRIVE

         %LF^7Invalid drive!^1
         %PA

     7.  FILE_CHANGE_UPDATING_DRIVE

         %LFUpdating the drive for file area %FR to %LR ...

     8.  FILE_CHANGE_UPDATING_DRIVE_DONE

         Done!

     9.  FILE_CHANGE_UPDATING_SYSOPLOG

         * Changed file areas: ^5%FR^1-^5%LR^1 to ^5%DD:\
  }

  PROCEDURE ChangeFileAreaDrive(MCIVars1: MCIVarRecord);
  VAR
    RecNum: Integer;
  BEGIN
    IF (NumFileAreas = 0) THEN
      FAELngStr(5,MemFileArea,MCIVars1,FALSE)
    ELSE
    BEGIN
      MCIVars1.FirstRecNum := -1;
      InputIntegerWOC(FAELngStr(6,MemFileArea,MCIVars1,TRUE),MCIVars1.FirstRecNum,[NumbersOnly],1,NumFileAreas);
      IF (MCIVars1.FirstRecNum >= 1) AND (MCIVars1.FirstRecNum <= NumFileAreas) THEN
      BEGIN
        MCIVars1.LastRecNum := -1;
        InputIntegerWOC(FAELngStr(7,MemFileArea,MCIVars1,TRUE),MCIVars1.LastRecNum,[NumbersOnly],1,NumFileAreas);
        IF (MCIVars1.LastRecNum >= 1) AND (MCIVars1.LastRecNum <= NumFileAreas) THEN
        BEGIN
          IF (MCIVars1.FirstRecNum > MCIVars1.LastRecNum) OR (MCIVars1.LastRecNum < MCIVars1.FirstRecNum) THEN
            FAELngStr(9,MemFileArea,MCIVars1,FALSE)
          ELSE
          BEGIN
            LOneK(FAELngStr(8,MemFileArea,MCIVars1,TRUE),MCIVars1.Drive,'ABCDEFGHIJKLMNOPQRSTUVWXYZ'^M,TRUE,TRUE);
            ChDir(MCIVars1.Drive+':');
            IF (IOResult <> 0) THEN
              FAELngStr(10,MemFileArea,MCIVars1,FALSE)
            ELSE
            BEGIN
              ChDir(StartDir);
              FAELngStr(11,MemFileArea,MCIVars1,FALSE);
              Reset(FileAreaFile);
              FOR RecNum := MCIVars1.FirstRecNum TO MCIVars1.LastRecNum DO
              BEGIN
                Seek(FileAreaFile,(RecNum - 1));
                Read(FileAreaFile,MemFileArea);
                MemFileArea.ULPath[1] := MCIVars1.Drive;
                MemFileArea.DLPath[1] := MCIVars1.Drive;
                Seek(FileAreaFile,(RecNum - 1));
                Write(FileAreaFile,MemFileArea);
              END;
              Close(FileAreaFile);
              LastError := IOResult;
              FAELngStr(12,MemFileArea,MCIVars1,FALSE);
              FAELngStr(13,MemFileArea,MCIVars1,FALSE);
            END;
          END;
        END;
      END;
    END;
  END;

  {
  DeleteFileArea External String Table

     1. NO_FILE_AREAS

        %LF^7No file areas exist!^1
        %PA

     2. FILE_DELETE_PROMPT

        %LFFile area to delete? @

     3. FILE_DELETE_DISPLAY_AREA

        %LFFile area: ^5%AN^1

     4. FILE_DELETE_VERIFY_DELETE

        %LFAre you sure you want to delete it? @

     5. FILE_DELETE_NOTICE

        %LF[> Deleting file area ...

     6. FILE_DELETE_SYSOPLOG

        * Deleted file area: ^5%AN

     7. FILE_DELETE_DATA_FILES

        %LFDelete file area data files also? @

     8. FILE_DELETE_REMOVE_DL_DIRECTORY

        %LFRemove the download directory? @

     9. FILE_DELETE_REMOVE_UL_DIRECTORY

        %LFRemove the upload directory? @
  }


  PROCEDURE DeleteFileArea(TempMemFileArea1: FileAreaRecordType; MCIVars1: MCIVarRecord);
  VAR
    RecNum,
    RecNumToDelete: SmallInt;
    Ok,
    OK1,
    Ok2: Boolean;
  BEGIN
    IF (NumFileAreas = 0) THEN
      FAELngStr(5,MemFileArea,MCIVars1,FALSE)
    ELSE
    BEGIN
      RecNumToDelete := -1;
      InputIntegerWOC(FAELngStr(14,MemFileArea,MCIVars1,TRUE),RecNumToDelete,[NumbersOnly],1,NumFileAreas);
      IF (RecNumToDelete >= 1) AND (RecNumToDelete <= NumFileAreas) THEN
      BEGIN
        Reset(FileAreaFile);
        Seek(FileAreaFile,(RecNumToDelete - 1));
        Read(FileAreaFile,TempMemFileArea1);
        Close(FileAreaFile);
        LastError := IOResult;
        FAELngStr(15,TempMemFileArea1,MCIVars1,FALSE);
        IF PYNQ(FAELngStr(16,MemFileArea,MCIVars1,TRUE),0,FALSE) THEN
        BEGIN
          FAELngStr(17,MemFileArea,MCIVars1,FALSE);
          Dec(RecNumToDelete);
          Reset(FileAreaFile);
          IF (RecNumToDelete >= 0) AND (RecNumToDelete <= (FileSize(FileAreaFile) - 2)) THEN
            FOR RecNum := RecNumToDelete TO (FileSize(FileAreaFile) - 2) DO
            BEGIN
              Seek(FileAreaFile,(RecNum + 1));
              Read(FileAreaFile,MemFileArea);
              Seek(FileAreaFile,RecNum);
              Write(FileAreaFile,MemFileArea);
            END;
          Seek(FileAreaFile,(FileSize(FileAreaFile) - 1));
          Truncate(FileAreaFile);
          Close(FileAreaFile);
          LastError := IOResult;
          Dec(NumFileAreas);
          SysOpLog(FAELngStr(18,TempMemFileArea1,MCIVars1,TRUE));
          Ok := TRUE;
          Ok1 := TRUE;
          OK2 := TRUE;
          Reset(FileAreaFile);
          FOR RecNum := 1 TO FileSize(FileAreaFile) DO
          BEGIN
            Seek(FileAreaFile,(RecNum - 1));
            Read(FileAreaFile,MemFileArea);
            IF (MemFileArea.FileName = TempMemFileArea1.FileName) THEN
              Ok := FALSE;
            IF (MemFileArea.DLPath = TempMemFileArea1.DLPath) THEN
              Ok1 := FALSE;
            IF (MemFileArea.ULPath = TempMemFileArea1.ULPath) THEN
              Ok2 := FALSE;
          END;
          Close(FileAreaFile);
          IF (Ok) AND (PYNQ(FAELngStr(19,TempMemFileArea1,MCIVars1,TRUE),0,FALSE)) THEN
          BEGIN
            Kill(GetDirPath(TempMemFileArea1)+'.DIR');
            Kill(GetDirPath(TempMemFileArea1)+'.EXT');
            Kill(GetDirPath(TempMemFileArea1)+'.SCN');
          END;
          IF (Ok1) AND (ExistDir(TempMemFileArea1.DLPath)) THEN
            IF PYNQ(FAELngStr(20,TempMemFileArea1,MCIVars1,TRUE),0,FALSE) THEN
              PurgeDir(TempMemFileArea1.DLPath,TRUE);
          IF (Ok2) AND (ExistDir(TempMemFileArea1.ULPath)) THEN
            IF PYNQ(FAELngStr(21,TempMemFileArea1,MCIVars1,TRUE),0,FALSE) THEN
              PurgeDir(TempMemFileArea1.ULPath,TRUE);
        END;
      END;
    END;
  END;

  {
  DeleteFileArea External String Table

     1. CHECK_AREA_NAME_ERROR

        %LF^7The area name is invalid!^1

     2. CHECK_FILE_NAME_ERROR

        %LF^7The file name is invalid!^1'

     3. CHECK_DL_PATH_ERROR

        %LF^7The download path is invalid!^1

     4. CHECK_UL_PATH_ERROR

        %LF^7The upload path is invalid!^1

     5. CHECK_ARCHIVE_TYPE_ERROR

        %LF^7The archive type is invalid!^1

     6. CHECK_COMMENT_TYPE_ERROR

        %LF^7The comment type is invalid!^1

  }

  PROCEDURE CheckFileArea(MemFileArea: FileAreaRecordType;
                          MCIVars1: MCIVarRecord;
                          StartErrMsg,
                          EndErrMsg: Byte;
                          VAR Ok: Boolean);
  VAR
    Counter: Byte;
  BEGIN
    FOR Counter := StartErrMsg TO EndErrMsg DO
      CASE Counter OF
        1 : IF (MemFileArea.AreaName = '') OR (MemFileArea.AreaName = '<< New File Area >>') THEN
            BEGIN
              FAELngStr(65,MemFileArea,MCIVars1,FALSE);
              OK := FALSE;
            END;
        2 : IF (MemFileArea.FileName = '') OR (MemFileArea.FileName = 'NEWDIR') THEN
            BEGIN
              FAELngStr(66,MemFileArea,MCIVars1,FALSE);
              OK := FALSE;
            END;
        3 : IF (MemFileArea.DLPath = '') THEN
            BEGIN
              FAELngStr(67,MemFileArea,MCIVars1,FALSE);
              OK := FALSE;
            END;
        4 : IF (MemFileArea.ULPath = '') THEN
            BEGIN
              FAELngStr(68,MemFileArea,MCIVars1,FALSE);
              OK := FALSE;
            END;
        5 : IF (MemFileArea.ArcType <> 0) AND (NOT General.FileArcInfo[MemFileArea.ArcType].Active) THEN
            BEGIN
              FAELngStr(69,MemFileArea,MCIVars1,FALSE);
              OK := FALSE;
            END;
        6 : IF (MemFileArea.CmtType <> 0) AND (General.FileArcComment[MemFileArea.CmtType] = '') THEN
            BEGIN
              FAELngStr(70,MemFileArea,MCIVars1,FALSE);
              OK := FALSE;
            END;
      END;
  END;

  {
  DeleteFileArea External String Table

     1. FILE_EDITING_AREA_HEADER

        ^5Editing file area #%RE of %NA

     2. FILE_INSERTING_AREA_HEADER

        ^5Inserting file area #%RE of %NF

     3. FILE_EDITING_INSERTING_SCREEN

        %LF^11. Area name   : ^5%AN
        ^12. File name   : ^5%FN   ^7(%GD.*)
        ^13. DL path     : ^5%DP
        ^14. UL path     : ^5%UP
        ^15. ACS required: ^5%AR
        ^16. DL/UL ACS   : ^5%DR^1 / ^5%UR
        ^17. Max files   : ^5%MF
        ^18. Password    : ^5%PW
        ^19. Arc/cmt type: ^5%AT^1 / ^5%CT
        ^1T. Flags       : ^5%FS

     4.  FILE_EDITING_INSERTING_PROMPT

         %LFModify menu [^5?^4=^5Help^4]: @

     5.  FILE_AREA_NAME_CHANGE

         %LFNew area name: @

     6.  FILE_FILE_NAME_CHANGE

         %LFNew file name (^5Do not enter ^4"^5.EXT^4"): @

     7.  FILE_DUPLICATE_FILE_NAME_ERROR

         %LF^7The file name is already in use!^1

     8.  FILE_USE_DUPLICATE_FILE_NAME

         %LFUse this file name anyway? @

     9.  FILE_OLD_DATA_FILES_PATH

         %LFOld DIR/EXT/SCN file names: "^5%OP.*^1"

    10.  FILE_NEW_DATA_FILES_PATH

         %LFNew DIR/EXT/SCN file names: "^5%NP.*^1"

    11.  FILE_RENAME_DATA_FILES

         %LFRename old data files? @

    12.  FILE_DL_PATH

         ^4New download path @

    13.  FILE_SET_DL_PATH_TO_UL_PATH

         %LFSet the upload path to the download path? @

    14.  FILE_UL_PATH

         ^4New upload path @

    15.  FILE_ACS

         %LFNew ACS: @

    16.  FILE_DL_ACCESS

         %LFNew download ACS: @

    17.  FILE_UL_ACCESS

         %LFNew upload ACS: @

    18.  FILE_MAX_FILES

         %LFNew max files @

    19.  FILE_PASSWORD

         %LFNew password: @

    20.  FILE_ARCHIVE_TYPE

         %LFNew archive type (^50^4=^5None^4) @

    21.  FILE_COMMENT_TYPE

         %LFNew comment type (^50^4=^5None^4) @

    22.  FILE_TOGGLE_FLAGS

         %LFToggle which flag (%FT)+'^4) [^5?^4=^5Help^4,^5<CR>^4=^5Quit^4]: @

    23.  FILE_MOVE_DATA_FILES

         %LFMove old data files to new directory? @

    24.  FILE_TOGGLE_HELP

         %LF^1(^3N^1)oRatio        ^1(^3U^1)nhidden
         ^1(^3G^1)ifSpecs       ^1(^3I^1)*.DIR file in DLPath
         ^1(^3C^1)D-ROM         ^1(^3S^1)how uploader Name
         ^1(^3D^1)ate uploaded  ^1du(^3P^1)e checking off

    25.  FILE_JUMP_TO

         %LFJump to entry?

    26.  FILE_FIRST_VALID_RECORD

         %LF^7You are at the first valid record!^1

    27.  FILE_LAST_VALID_RECORD

         %LF^7You are at the last valid record!^1

    28.  FILE_INSERT_EDIT_HELP

         %LF^1<^3CR^1>Redisplay current screen
         ^31-9,T^1:Modify item

    29.  FILE_INSERT_HELP

         ^1(^3Q^1)uit and save

    30.  FILE_EDIT_HELP

         ^1(^3[^1)Back entry          ^1(^3]^1)Forward entry');
         ^1(^3F^1)irst entry in list  ^1(^3J^1)ump to entry');
         ^1(^3L^1)ast entry in list   ^1(^3Q^1)uit and save');
  }

  PROCEDURE EditFileArea(TempMemFileArea1: FileAreaRecordType; VAR MemFileArea: FileAreaRecordType; VAR Cmd1: Char;
                         VAR MCIVars1: MCIVarRecord; VAR Changed: Boolean; Editing: Boolean);
  VAR
    TempFileName: Str8;
    CmdStr: AStr;
    RecNum,
    RecNum1: Integer;
    Ok: Boolean;
  BEGIN
    WITH MemFileArea DO
      REPEAT
        IF (Cmd1 <> '?') THEN
        BEGIN
          Abort := FALSE;
          Next := FALSE;
          CLS;
          IF (Editing) THEN
            FAELngStr(35,MemFileArea,MCIVars1,FALSE)
          ELSE
            FAELngStr(36,MemFileArea,MCIVars1,FALSE);
          FAELngStr(37,MemFileArea,MCIVars1,FALSE);
        END;
        IF (NOT Editing) THEN
          CmdStr := '123456789T'
        ELSE
          CmdStr := '123456789T[]FJL';
        LOneK(FAELngStr(38,MemFileArea,MCIVars1,TRUE),Cmd1,'Q?'+CmdStr+^M,TRUE,TRUE);
        CASE Cmd1 OF
          '1' : REPEAT
                  TempMemFileArea1.AreaName := MemFileArea.AreaName;
                  OK := TRUE;
                  InputWNWC(FAELngStr(39,MemFileArea,MCIVars1,TRUE),AreaName,(SizeOf(AreaName) - 1),Changed);
                  CheckFileArea(MemFileArea,MCIVars1,1,1,Ok);
                  IF (NOT Ok) THEN
                    MemFileArea.AreaName := TempMemFileArea1.AreaName;
                UNTIL (OK) OR (HangUp);
          '2' : REPEAT
                  OK := TRUE;
                  TempFileName := FileName;
                  InputWN1(FAELngStr(40,MemFileArea,MCIVars1,TRUE),TempFileName,(SizeOf(FileName) - 1),
                           [UpperOnly,InterActiveEdit],Changed);
                  TempFileName := SQOutSp(TempFileName);
                  IF (Pos('.',TempFileName) > 0) THEN
                    TempFileName := Copy(TempFileName,1,(Pos('.',TempFileName) - 1));
                  TempMemFileArea1.FileName := TempFileName;
                  CheckFileArea(TempMemFileArea1,MCIVars1,2,2,Ok);
                  IF (Ok) AND (TempFileName <> MemFileArea.FileName) THEN
                  BEGIN
                    RecNum1 := -1;
                    RecNum := 0;
                    WHILE (RecNum <= (FileSize(FileAreaFile) - 1)) AND (RecNum1 = -1) DO
                    BEGIN
                      Seek(FileAreaFile,RecNum);
                      Read(FileAreaFile,TempMemFileArea1);
                      IF (TempFileName = TempMemFileArea1.FileName) THEN
                      BEGIN
                        FAELngStr(41,MemFileArea,MCIVars1,FALSE);
                        RecNum1 := 1;
                        IF NOT PYNQ(FAELngStr(42,MemFileArea,MCIVars1,TRUE),0,FALSE) THEN
                          Ok := FALSE;
                      END;
                      Inc(RecNum);
                    END;
                  END;
                  IF (Ok) THEN
                  BEGIN
                    MCIVars1.OldPath := GetDirPath(MemFileArea);
                    FileName := TempFileName;
                    IF (Editing) THEN
                    BEGIN
                      MCIVars1.NewPath := GetDirPath(MemFileArea);
                      IF Exist(MCIVars1.OldPath+'.DIR') AND (NOT Exist(MCIVars1.NewPath+'.DIR')) THEN
                      BEGIN
                        FAELngStr(43,MemFileArea,MCIVars1,FALSE);
                        FAELngStr(44,MemFileArea,MCIVars1,FALSE);
                        IF PYNQ(FAELngStr(45,MemFileArea,MCIVars1,TRUE),0,FALSE) THEN
                        BEGIN
                          CopyMoveFile(FALSE,'%LF^1Renaming "^5'+MCIVars1.OldPath+'.DIR^1" to "^5'+
                                       MCIVars1.NewPath+'.DIR^1": ',MCIVars1.OldPath+'.DIR',MCIVars1.NewPath+'.DIR',TRUE);
                          CopyMoveFile(FALSE,'%LF^1Renaming "^5'+MCIVars1.OldPath+'.EXT^1" to "^5'+
                                       MCIVars1.NewPath+'.EXT^1": ',MCIVars1.OldPath+'.EXT',MCIVars1.NewPath+'.EXT',TRUE);
                          CopyMoveFile(FALSE,'%LF^1Renaming "^5'+MCIVars1.OldPath+'.SCN^1" to "^5'+
                                       MCIVars1.NewPath+'.SCN^1": ',MCIVars1.OldPath+'.SCN',MCIVars1.NewPath+'.SCN',TRUE);
                        END;
                      END;
                    END;
                  END;
                UNTIL (Ok) OR (HangUp);
          '3' : BEGIN
                  InputPath(FAELngStr(46,MemFileArea,MCIVars1,TRUE),DLPath,Editing,FALSE,Changed);
                  IF (ULPath <> DLPath) AND (PYNQ(FAELngStr(47,MemFileArea,MCIVars1,TRUE),0,FALSE)) THEN
                  BEGIN
                    ULPath := DLPath;
                    Changed := TRUE;
                  END;
                END;
          '4' : InputPath(FAELngStr(48,MemFileArea,MCIVars1,TRUE),ULPath,Editing,FALSE,Changed);
          '5' : InputWN1(FAELngStr(49,MemFileArea,MCIVars1,TRUE),ACS,(SizeOf(ACS) - 1),[InterActiveEdit],Changed);
          '6' : BEGIN
                  InputWN1(FAELngStr(50,MemFileArea,MCIVars1,TRUE),DLACS,(SizeOf(DLACS) - 1),[InterActiveEdit],Changed);
                  InputWN1(FAELngStr(51,MemFileArea,MCIVars1,TRUE),ULACS,(SizeOf(ULACS) - 1),[InterActiveEdit],Changed);
                END;
          '7' : InputIntegerWC(FAELngStr(52,MemFileArea,MCIVars1,TRUE),MaxFiles,[DisplayValue,NumbersOnly],0,32767,Changed);
          '8' : InputWN1(FAELngStr(53,MemFileArea,MCIVars1,TRUE),Password,(SizeOf(Password) - 1),
                         [InterActiveEdit,UpperOnly],Changed);
          '9' : BEGIN
                  REPEAT
                    OK := TRUE;
                    NL;
                    DisplayARCS;
                    InputByteWC(FAELngStr(54,MemFileArea,MCIVars1,TRUE),MemFileArea.ArcType,
                                [DisplayValue,NumbersOnly],0,NumArcs,Changed);
                    CheckFileArea(MemFileArea,MCIVars1,5,5,Ok);
                  UNTIL (Ok) OR (HangUp);
                  REPEAT
                    OK := TRUE;
                    NL;
                    DisplayCmt;
                    InputByteWC(FAELngStr(55,MemFileArea,MCIVars1,TRUE),CmtType,[DisplayValue,NumbersOnly],0,3,Changed);
                    CheckFileArea(MemFileArea,MCIVars1,6,6,Ok);
                  UNTIL (Ok) OR (HangUp)
                END;
          'T' : BEGIN
                  REPEAT
                    LOneK(FAELngStr(56,MemFileArea,MCIVars1,TRUE),Cmd1,^M'CDGINPSU?',TRUE,TRUE);
                    CASE (Cmd1) OF
                      'C','D','G','N','P','S','U' :
                         ToggleFAFlags(Cmd1,FAFlags,Changed);
                      'I' : BEGIN
                              MCIVars1.OldPath := GetDIRPath(MemFileArea);
                              ToggleFAFlags('I',FAFlags,Changed);
                              IF (Editing) THEN
                              BEGIN
                                MCIVars1.NewPath := GetDIRPath(MemFileArea);
                                IF (Exist(MCIVars1.OldPath+'.DIR')) AND (NOT Exist(MCIVars1.NewPath+'.DIR')) THEN
                                BEGIN
                                  FAELngStr(43,MemFileArea,MCIVars1,FALSE);
                                  FAELngStr(44,MemFileArea,MCIVars1,FALSE);
                                  IF PYNQ(FAELngStr(57,MemFileArea,MCIVars1,TRUE),0,FALSE) THEN
                                  BEGIN
                                    CopyMoveFile(FALSE,'%LF^1Moving "^5'+MCIVars1.OldPath+'.DIR^1" to "^5'+
                                                 MCIVars1.NewPath+'.DIR^1": ',MCIVars1.OldPath+'.DIR',MCIVars1.NewPath+'.DIR',
                                                 TRUE);
                                    CopyMoveFile(FALSE,'%LF^1Moving "^5'+MCIVars1.OldPath+'.EXT^1" to "^5'+
                                                 MCIVars1.NewPath+'.EXT^1": ',MCIVars1.OldPath+'.EXT',MCIVars1.NewPath+'.EXT',
                                                 TRUE);
                                    CopyMoveFile(FALSE,'%LF^1Moving "^5'+MCIVars1.OldPath+'.SCN^1" to "^5'+
                                                 MCIVars1.NewPath+'.SCN^1": ',MCIVars1.OldPath+'.SCN',MCIVars1.NewPath+'.SCN',
                                                 TRUE);
                                  END;
                                END;
                              END;
                            END;
                      '?' : FAELngStr(58,MemFileArea,MCIVars1,FALSE);
                    END;
                  UNTIL (Cmd1 = ^M) OR (HangUp);
                  Cmd1 := #0;
                END;
          '[' : IF (MCIVars1.RecNumToEdit > 1) THEN
                  Dec(MCIVars1.RecNumToEdit)
                ELSE
                BEGIN
                  FAELngStr(60,MemFileArea,MCIVars1,FALSE);
                  Cmd1 := #0;
                END;
          ']' : IF (MCIVars1.RecNumToEdit < NumFileAreas) THEN
                  Inc(MCIVars1.RecNumToEdit)
                ELSE
                BEGIN
                  FAELngStr(61,MemFileArea,MCIVars1,FALSE);
                  Cmd1 := #0;
                END;
          'F' : IF (MCIVars1.RecNumToEdit <> 1) THEN
                  MCIVars1.RecNumToEdit := 1
                ELSE
                BEGIN
                  FAELngStr(60,MemFileArea,MCIVars1,FALSE);
                  Cmd1 := #0;
                END;
          'J' : BEGIN
                  InputIntegerWOC(FAELngStr(59,MemFileArea,MCIVars1,TRUE),MCIVars1.RecNumToEdit,[Numbersonly],1,NumFileAreas);
                  IF (MCIVars1.RecNumToEdit < 1) OR (MCIVars1.RecNumToEdit > NumFileAreas) THEN
                    Cmd1 := #0;
                END;
          'L' : IF (MCIVars1.RecNumToEdit <> NumFileAreas) THEN
                  MCIVars1.RecNumToEdit := NumFileAreas
                ELSE
                BEGIN
                  FAELngStr(61,MemFileArea,MCIVars1,FALSE);
                  Cmd1 := #0;
                END;
          '?' : BEGIN
                  FAELngStr(62,MemFileArea,MCIVars1,FALSE);
                  IF (NOT Editing) THEN
                    FAELngStr(63,MemFileArea,MCIVars1,FALSE)
                  ELSE
                    FAELngStr(64,MemFileArea,MCIVars1,FALSE);
                END;
        END;
      UNTIL (Pos(Cmd1,'Q[]FJL') <> 0) OR (HangUp);
  END;

  {
  InsertFileArea External String Table

     1. FILE_INSERT_MAX_FILE_AREAS

        %LF^7No more then %MA file areas can exist!^1
        %PA

     2. FILE_INSERT_PROMPT

        %LFFile area to insert before? @

     3. FILE_INSERT_AFTER_ERROR_PROMPT

        %LFContinue inserting file area? @

     4. FILE_INSERT_CONFIRM_INSERT

        %LFIs this what you want? @

     5. FILE_INSERT_NOTICE

        %LF[> Inserting file area ...

     6. FILE_INSERT_SYSOPLOG

        * Inserted file area: ^5%AN
  }

  PROCEDURE InsertFileArea(TempMemFileArea1: FileAreaRecordType; MCIVars1: MCIVarRecord);
  VAR
    FileAreaScanFile: FILE OF Boolean;
    Cmd1: Char;
    RecNum,
    RecNum1,
    RecNumToInsertBefore: SmallInt;
    Ok,
    Changed: Boolean;
  BEGIN
    IF (NumFileAreas = MaxFileAreas) THEN
      FAELngStr(22,MemFileArea,MCIVars1,FALSE)
    ELSE
    BEGIN
      RecNumToInsertBefore := -1;
      InputIntegerWOC(FAELngStr(23,MemFileArea,MCIVars1,TRUE),RecNumToInsertBefore,[NumbersOnly],1,(NumFileAreas + 1));
      IF (RecNumToInsertBefore >= 1) AND (RecNumToInsertBefore <= (NumFileAreas + 1)) THEN
      BEGIN
        Reset(FileAreaFile);
        InitFileAreaVars(TempMemFileArea1);
        IF (RecNumToInsertBefore = 1) THEN
          MCIVars1.RecNumToEdit := 1
        ELSE IF (RecNumToInsertBefore = (NumFileAreas + 1)) THEN
          MCIVars1.RecNumToEdit := (NumFileAreas + 1)
        ELSE
          MCIVars1.RecNumToEdit := RecNumToInsertBefore;
        REPEAT
          OK := TRUE;
          EditFileArea(TempMemFileArea1,TempMemFileArea1,Cmd1,MCIVars1,Changed,FALSE);
          CheckFileArea(TempMemFileArea1,MCIVars1,1,6,Ok);
          IF (NOT OK) THEN
            IF (NOT PYNQ(FAELngStr(24,MemFileArea,MCIVars1,TRUE),0,TRUE)) THEN
              Abort := TRUE;
        UNTIL (OK) OR (Abort) OR (HangUp);
        IF (NOT Abort) AND (PYNQ(FAELngStr(25,MemFileArea,MCIVars1,TRUE),0,FALSE)) THEN
        BEGIN
          FAELngStr(26,MemFileArea,MCIVars1,FALSE);
          Seek(FileAreaFile,FileSize(FileAreaFile));
          Write(FileAreaFile,MemFileArea);
          Dec(RecNumToInsertBefore);
          FOR RecNum := ((FileSize(FileAreaFile) - 1) - 1) DOWNTO RecNumToInsertBefore DO
          BEGIN
            Seek(FileAreaFile,RecNum);
            Read(FileAreaFile,MemFileArea);
            Seek(FileAreaFile,(RecNum + 1));
            Write(FileAreaFile,MemFileArea);
          END;
          FOR RecNum := RecNumToInsertBefore TO ((RecNumToInsertBefore + 1) - 1) DO
          BEGIN
            MakeDir(TempMemFileArea1.DLPath,FALSE);
            MakeDir(TempMemFileArea1.ULPath,FALSE);
            IF (NOT Exist(GetDirPath(TempMemFileArea1)+'.DIR')) THEN
            BEGIN
              Assign(FileInfoFile,GetDIRPath(TempMemFileArea1)+'.DIR');
              ReWrite(FileInfoFile);
              Close(FileInfoFile);
            END;
            IF (NOT Exist(GetDirPath(TempMemFileArea1)+'.EXT')) THEN
            BEGIN
              Assign(ExtInfoFile,GetDIRPath(TempMemFileArea1)+'.EXT');
              ReWrite(ExtInfoFile,1);
              Close(ExtInfoFile);
            END;
            IF (NOT Exist(GetDirPath(TempMemFileArea1)+'.SCN')) THEN
            BEGIN
              Assign(FileAreaScanFile,GetDIRPath(TempMemFileArea1)+'.SCN');
              ReWrite(FileAreaScanFile);
              Close(FileAreaScanFile);
            END;
            IF (Exist(GetDirPath(TempMemFileArea1)+'.SCN')) THEN
            BEGIN
              Assign(FileAreaScanFile,GetDIRPath(TempMemFileArea1)+'.SCN');
              Reset(FileAreaScanFile);
              NewScanFileArea := TRUE;
              FOR RecNum1 := (FileSize(FileAreaScanFile) + 1) TO (MaxUsers - 1) DO
                Write(FileAreaScanFile,NewScanFileArea);
              Close(FileAreaScanFile);
            END;
            Seek(FileAreaFile,RecNum);
            Write(FileAreaFile,TempMemFileArea1);
            Inc(NumFileAreas);
            SysOpLog(FAELngStr(27,TempMemFileArea1,MCIVars1,TRUE));
          END;
        END;
        Close(FileAreaFile);
        LastError := IOResult;
      END;
    END;
  END;

  {
  ModifyFileArea External String Table

     1. NO_FILE_AREAS

        %LF^7No file areas exist!^1
        %PA

     2. FILE_MODIFY_PROMPT

        %LFFile area to modify? @

     3. FILE_MODIFY_SYSOPLOG

        * Modified file area: ^5%AN
  }

  PROCEDURE ModifyFileArea(TempMemFileArea1: FileAreaRecordType; MCIVars1: MCIVarRecord);
  VAR
    FileAreaScanFile: FILE OF Boolean;
    User: UserRecordType;
    Cmd1: Char;
    RecNum1,
    SaveRecNumToEdit: Integer;
    Ok,
    Changed: Boolean;
  BEGIN
    IF (NumFileAreas = 0) THEN
      FAELngStr(5,MemFileArea,MCIVars1,FALSE)
    ELSE
    BEGIN
      MCIVars1.RecNumToEdit := -1;
      InputIntegerWOC(FAELngStr(28,MemFileArea,MCIVars1,TRUE),MCIVars1.RecNumToEdit,[NumbersOnly],1,NumFileAreas);
      IF (MCIVars1.RecNumToEdit >= 1) AND (MCIVars1.RecNumToEdit <= NumFileAreas) THEN
      BEGIN
        SaveRecNumToEdit := -1;
        Cmd1 := #0;
        Reset(FileAreaFile);
        WHILE (Cmd1 <> 'Q') AND (NOT HangUp) DO
        BEGIN
          IF (SaveRecNumToEdit <> MCIVars1.RecNumToEdit) THEN
          BEGIN
            Seek(FileAreaFile,(MCIVars1.RecNumToEdit - 1));
            Read(FileAreaFile,MemFileArea);
            SaveRecNumToEdit := MCIVars1.RecNumToEdit;
            Changed := FALSE;
          END;
          REPEAT
            Ok := TRUE;
            EditFileArea(TempMemFileArea1,MemFileArea,Cmd1,MCIVars1,Changed,TRUE);
            CheckFileArea(MemFileArea,MCIVars1,1,6,Ok);
            IF (NOT OK) THEN
            BEGIN
              PauseScr(FALSE);
              IF (MCIVars1.RecNumToEdit <> SaveRecNumToEdit) THEN
                MCIVars1.RecNumToEdit := SaveRecNumToEdit;
            END;
          UNTIL (OK) OR (HangUp);
          MakeDir(MemFileArea.DLPath,FALSE);
          MakeDir(MemFileArea.ULPath,FALSE);
          IF (NOT Exist(GetDirPath(MemFileArea)+'.DIR')) THEN
          BEGIN
            Assign(FileInfoFile,GetDIRPath(MemFileArea)+'.DIR');
            ReWrite(FileInfoFile);
            Close(FileInfoFile);
          END;
          IF (NOT Exist(GetDirPath(MemFileArea)+'.EXT')) THEN
          BEGIN
            Assign(ExtInfoFile,GetDIRPath(MemFileArea)+'.EXT');
            ReWrite(ExtInfoFile,1);
            Close(ExtInfoFile);
          END;
          IF (NOT Exist(GetDirPath(MemFileArea)+'.SCN')) THEN
          BEGIN
            Assign(FileAreaScanFile,GetDIRPath(MemFileArea)+'.SCN');
            ReWrite(FileAreaScanFile);
            Close(FileAreaScanFile);
          END;
          IF (Exist(GetDirPath(MemFileArea)+'.SCN')) THEN
          BEGIN
            Assign(FileAreaScanFile,GetDIRPath(MemFileArea)+'.SCN');
            Reset(FileAreaScanFile);
            NewScanFileArea := TRUE;
            Seek(FileAreaScanFile,FileSize(FileAreaScanFile));
            FOR RecNum1 := (FileSize(FileAreaScanFile) + 1) TO (MaxUsers - 1) DO
              Write(FileAreaScanFile,NewScanFileArea);
            Reset(UserFile);
            FOR RecNum1 := 1 TO (MaxUsers - 1) DO
            BEGIN
              LoadURec(User,RecNum1);
              IF (Deleted IN User.SFlags) THEN
              BEGIN
                Seek(FileAreaScanFile,(RecNum1 - 1));
                Write(FileAreaScanFile,NewScanFileArea);
              END;
            END;
            Close(UserFile);
            Close(FileAreaScanFile);
          END;
          IF (Changed) THEN
          BEGIN
            Seek(FileAreaFile,(SaveRecNumToEdit - 1));
            Write(FileAreaFile,MemFileArea);
            Changed := FALSE;
            SysOpLog(FAELngStr(29,MemFileArea,MCIVars1,TRUE));
          END;
        END;
        Close(FileAreaFile);
        LastError := IOResult;
      END;
    END;
  END;

  {
  PositionFileArea External String Table

     1. NO_FILE_AREAS

        %LF^7No file areas exist!^1
        %PA

     2. FILE_POSITION_NO_AREAS

        %LF^7No file areas to position!^1
        %PA

     3. FILE_POSITION_PROMPT

        %LFPosition which file area? @

     4. FILE_POSITION_NUMBERING

        %LFAccording to the current numbering system.

     5. FILE_POSITION_BEFORE_WHICH

        %LFPosition before which file area?'

     6. FILE_POSITION_NOTICE

        %LF[> Positioning file areas ...
  }

  PROCEDURE PositionFileArea(TempMemFileArea1: FileAreaRecordType; MCIVars1: MCIVarRecord);
  VAR
    RecNumToPosition,
    RecNumToPositionBefore,
    RecNum1,
    RecNum2: SmallInt;
  BEGIN
    IF (NumFileAreas = 0) THEN
      FAELngStr(5,MemFileArea,MCIVars1,FALSE)
    ELSE IF (NumFileAreas = 1) THEN
      FAELngStr(30,MemFileArea,MCIVars1,FALSE)
    ELSE
    BEGIN
      RecNumToPosition := -1;
      InputIntegerWOC(FAELngStr(31,MemFileArea,MCIVars1,TRUE),RecNumToPosition,[NumbersOnly],1,NumFileAreas);
      IF (RecNumToPosition >= 1) AND (RecNumToPosition <= NumFileAreas) THEN
      BEGIN
        RecNumToPositionBefore := -1;
        FAELngStr(32,MemFileArea,MCIVars1,FALSE);
        InputIntegerWOC(FAELngStr(33,MemFileArea,MCIVars1,TRUE),RecNumToPositionBefore,[Numbersonly],1,(NumFileAreas + 1));
        IF (RecNumToPositionBefore >= 1) AND (RecNumToPositionBefore <= (NumFileAreas + 1)) AND
           (RecNumToPositionBefore <> RecNumToPosition) AND (RecNumToPositionBefore <> (RecNumToPosition + 1)) THEN
        BEGIN
          FAELngStr(34,MemFileArea,MCIVars1,FALSE);
          Reset(FileAreaFile);
          IF (RecNumToPositionBefore > RecNumToPosition) THEN
            Dec(RecNumToPositionBefore);
          Dec(RecNumToPosition);
          Dec(RecNumToPositionBefore);
          Seek(FileAreaFile,RecNumToPosition);
          Read(FileAreaFile,TempMemFileArea1);
          RecNum1 := RecNumToPosition;
          IF (RecNumToPosition > RecNumToPositionBefore) THEN
            RecNum2 := -1
          ELSE
            RecNum2 := 1;
          WHILE (RecNum1 <> RecNumToPositionBefore) DO
          BEGIN
            IF ((RecNum1 + RecNum2) < FileSize(FileAreaFile)) THEN
            BEGIN
              Seek(FileAreaFile,(RecNum1 + RecNum2));
              Read(FileAreaFile,MemFileArea);
              Seek(FileAreaFile,RecNum1);
              Write(FileAreaFile,MemFileArea);
            END;
            Inc(RecNum1,RecNum2);
          END;
          Seek(FileAreaFile,RecNumToPositionBefore);
          Write(FileAreaFile,TempMemFileArea1);
          Close(FileAreaFile);
          LastError := IOResult;
        END;
      END;
    END;
  END;

  {
  ListFileAreas External String Table

     1. FILE_AREA_HEADER_TOGGLE_ONE

        ^0#####^4:^3File area name           ^4:^3Flags   ^4:^3ACS       ^4:^3UL ACS    ^4:^3DL ACS   ^4:^3MaxF
        ^4=====:=========================:========:==========:==========:==========:=====

     2. FILE_AREA_HEADER_TOGGLE_TWO

        ^0#####^4:^3File area name  ^4:^3FileName^4:^3Download path          ^4:^3Upload path
        ^4=====:================:========:=======================:=======================

     3. FILE_AREA_HEADER_NO_FILE_AREAS

        #7*** No file areas defined ***^1
  }

  PROCEDURE ListFileAreas(VAR RecNumToList1: Integer; MCIVars1: MCIVarRecord);
  VAR
    NumDone: Integer;
  BEGIN
    IF (RecNumToList1 < 1) OR (RecNumToList1 > NumFileAreas) THEN
      RecNumToList1 := 1;
    Abort := FALSE;
    Next := FALSE;
    CLS;
    CASE DisplayType OF
      1 : FAELngStr(0,MemFileArea,MCIVars1,FALSE);
      2 : FAELngStr(1,MemFileArea,MCIVars1,FALSE);
    END;
    Reset(FileAreaFile);
    NumDone := 0;
    WHILE (NumDone < (PageLength - 5)) AND (RecNumToList1 >= 1) AND (RecNumToList1 <= NumFileAreas)
          AND (NOT Abort) AND (NOT HangUp) DO
    BEGIN
      Seek(FileAreaFile,(RecNumToList1 - 1));
      Read(FileAreaFile,MemFileArea);
      WITH MemFileArea DO
        CASE DisplayType OF
          1 : PrintACR('^0'+PadRightInt(RecNumToList1,5)+
                       ' ^5'+PadLeftStr(AreaName,25)+
                       ' ^3'+DisplayFAFlags(FAFlags,'5','4')+
                       ' ^9'+PadLeftStr(AOnOff(ACS = '','*None*',ACS),10)+
                       ' '+PadLeftStr(AOnOff(ULACS = '','*None*',ULACS),10)+
                       ' '+PadLeftStr(AOnOff(DLACS = '','*None*',DLACS),10)+
                       ' ^3'+PadRightInt(MaxFiles,5));
          2 : PrintACR('^0'+PadRightInt(RecNumToList1,5)+
                       ' ^5'+PadLeftStr(AreaName,16)+
                       ' ^3'+PadLeftStr(FileName,8)+
                       ' '+PadLeftStr(DLPath,23)+
                       ' '+PadLeftStr(ULPath,23));
        END;
      Inc(RecNumToList1);
      Inc(NumDone);
    END;
    Close(FileAreaFile);
    LastError := IOResult;
    IF (NumFileAreas = 0) AND (NOT Abort) AND (NOT HangUp) THEN
      FAELngStr(2,MemFileArea,MCIVars1,FALSE);
  END;

  {
  MainFileArea External String Table

     1. FILE_AREA_EDITOR_PROMPT

        %LFFile area editor [^5?^4=^5Help^4]:

     2. FILE_AREA_EDITOR_HELP

        %LF^1<^3CR^1>Next screen or redisplay current screen
        ^1(^3C^1)hange file area storage drive
        ^1(^3D^1)elete area   ^1(^3I^1)nsert area
        ^1(^3M^1)odify area   ^1(^3P^1)osition area
        ^1(^3Q^1)uit          ^1(^3T^1)oggle display format
   }

BEGIN
  SaveTempPause := TempPause;
  TempPause := FALSE;
  RecNumToList := 1;
  Cmd := #0;
  REPEAT
    IF (Cmd <> '?') THEN
      ListFileAreas(RecNumToList,MCIVars);
    LOneK(FAELngStr(3,MemFileArea,MCIVars,TRUE),Cmd,'QCDIMPT?'^M,TRUE,TRUE);
    CASE Cmd OF
      ^M  : IF (RecNumToList < 1) OR (RecNumToList > NumFileAreas) THEN
              RecNumToList := 1;
      'C' : ChangeFileAreaDrive(MCIVars);
      'D' : DeleteFileArea(TempMemFileArea,MCIVars);
      'I' : InsertFileArea(TempMemFileArea,MCIVars);
      'M' : ModifyFileArea(TempMemFileArea,MCIVars);
      'P' : PositionFileArea(TempMemFileArea,MCIVars);
      'T' : DisplayType := ((DisplayType MOD 2) + 1);
      '?' : FAELngStr(4,MemFileArea,MCIVars,FALSE);
    END;
    IF (Cmd <> ^M) THEN
      RecNumToList := 1;
  UNTIL (Cmd = 'Q') OR (HangUp);
  TempPause := SaveTempPause;
  NewCompTables;
  IF ((FileArea < 1) OR (FileArea > NumFileAreas)) THEN
    FileArea := 1;
  ReadFileArea := -1;
  LoadFileArea(FileArea);
  LastError := IOResult;
END;

END.
