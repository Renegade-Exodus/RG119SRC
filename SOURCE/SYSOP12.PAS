{$IFDEF WIN32}
{$I DEFINES.INC}
{$ENDIF}

{$A+,B-,D+,E-,F+,I-,L+,N-,O+,R-,S+,V-}
UNIT SysOp12;

INTERFACE

USES
  Common;

FUNCTION FindConference(Key: Char; VAR Conference: ConferenceRecordType): Boolean;
FUNCTION ShowConferences: AStr;
PROCEDURE ChangeConference(MenuOption: Str50);
PROCEDURE ConferenceEditor;

IMPLEMENTATION

FUNCTION FindConference(Key: Char; VAR Conference: ConferenceRecordType): Boolean;
VAR
  RecNumToList: Integer;
  Found: Boolean;
BEGIN
  Found := FALSE;
  Reset(ConferenceFile);
  RecNumToList := 1;
  WHILE (RecNumToList <= NumConfKeys) AND (NOT Found) DO
  BEGIN
    Seek(ConferenceFile,(RecNumToList - 1));
    Read(ConferenceFile,Conference);
    IF (Key = Conference.Key) THEN
      Found := TRUE;
    Inc(RecNumToList);
  END;
  Close(ConferenceFile);
  LastError := IOResult;
  FindConference := Found;
END;

FUNCTION ShowConferences: AStr;
VAR
  TempStr: AStr;
  RecNumToList: Integer;
BEGIN
  Abort := FALSE;
  Next := FALSE;
  TempStr := '';
  Reset(ConferenceFile);
  RecNumToList := 1;
  WHILE (RecNumToList <= NumConfKeys) AND (NOT Abort) AND (NOT HangUp) DO
  BEGIN
    Seek(ConferenceFile,(RecNumToList - 1));
    Read(ConferenceFile,Conference);
    IF AACS(Conference.ACS) THEN
    BEGIN
      TempStr := TempStr + Conference.Key;
      IF (RecNumToList < NumConfKeys) THEN
        TempStr := TempStr + ',';
    END;
    Inc(RecNumToList);
  END;
  Close(ConferenceFile);
  LastError := IOResult;
  IF (TempStr[Length(TempStr)] = ',') THEN
    Dec(TempStr[0]);
  ShowConferences := TempStr;
END;

PROCEDURE DisplayConferenceRecords(RecNumToList: Integer; DisplayListNum: Boolean);
VAR
  TempStr: AStr;
  NumOnline: Byte;
BEGIN
  AllowContinue := TRUE;
  Abort := FALSE;
  Next := FALSE;
  CLS;
  IF (DisplayListNum) THEN
  BEGIN
    PrintACR('^0##^4:^3C^4:^3Name                            ^0##^4:^3C^4:^3Name');
    PrintACR('^4==:=:==============================  ==:=:==============================');
  END
  ELSE
  BEGIN
    PrintACR(' ^3C^4:^3Name                            ^3C^4:^3Name');
    PrintACR(' ^4=:==============================  =:==============================');
  END;
  Reset(ConferenceFile);
  TempStr := '';
  NumOnline := 0;
  RecNumToList := 1;
  WHILE (RecNumToList <= NumConfKeys) AND (NOT Abort) AND (NOT HangUp) DO
  BEGIN
    Seek(ConferenceFile,(RecNumToList - 1));
    Read(ConferenceFile,Conference);
    IF (DisplayListNum) THEN
      TempStr := TempStr + PadLeftStr('^0'+PadRightInt(RecNumToList,2)+
                           ' ^3'+Conference.Key+
                           ' ^5'+Conference.Name,37)
    ELSE
      TempStr := TempStr + PadLeftStr(' ^3'+Conference.Key+
                           ' ^5'+Conference.Name,34);
    Inc(NumOnline);
    IF (NumOnline = 2) THEN
    BEGIN
      PrintaCR(TempStr);
      NumOnline := 0;
      TempStr := '';
    END;
    Inc(RecNumToList);
  END;
  Close(ConferenceFile);
  LastError := IOResult;
  AllowContinue := FALSE;
  IF (NumOnline = 1) AND (NOT Abort) AND (NOT HangUp) THEN
    PrintaCR(TempStr);
  IF (NumConfKeys = 0) AND (NOT Abort) AND (NOT HangUp) THEN
    Print('^7No conference records.');
END;

PROCEDURE ChangeConference(MenuOption: Str50);
VAR
  OneKCmds: AStr;
  Cmd: Char;
  RecNumToList: Integer;
BEGIN
  MenuOption := AllCaps(SQOutSp(MenuOption));
  IF (MenuOption <> '') THEN
    Cmd := MenuOption[1]
  ELSE
    Cmd := #0;
  IF (Cmd <> #0) AND (Cmd <> '?') AND (NOT (Cmd IN ConfKeys)) THEN
  BEGIN
    Print('%NLCommand error, operation aborted!');
    SysOpLog('^7Change conference cmd error, invalid options: "'+Cmd+'".');
    Exit;
  END;
  IF (Cmd = '?') THEN
  BEGIN
    PrintF('CONFLIST');
    IF (NoFile) THEN
      DisplayConferenceRecords(RecNumToList,FALSE);
  END
  ELSE IF (Cmd IN ConfKeys) AND FindConference(Cmd,Conference) THEN
  BEGIN
    IF ((AACS(Conference.ACS))) THEN
    BEGIN
      CurrentConf := Cmd;
      ThisUser.LastConf := CurrentConf;
    END;
  END
  ELSE
  BEGIN
    OneKCmds := '';
    FOR Cmd := '@' TO 'Z' DO
      IF (Cmd IN ConfKeys) THEN
        OneKCmds := OneKCmds + Cmd;
    Print('%LF^4Current conference: ^5%CT - %CN');
    REPEAT
      LOneK('%LFJoin which conference? (^5?^4=^5List^4,<^5CR^4>=^5Quit^4): ',Cmd,^M'?'+OneKCmds,TRUE,TRUE);
      IF (Cmd = '?') THEN
      BEGIN
        PrintF('CONFLIST');
        IF (NoFile) THEN
          DisplayConferenceRecords(RecNumToList,FALSE);
      END
      ELSE IF (Cmd IN ConfKeys) AND FindConference(Cmd,Conference) THEN
        IF (NOT AACS(Conference.ACS)) THEN
          Print('%LF^7You do not have the required access level for this conference!^1')
        ELSE
        BEGIN
          CurrentConf := Cmd;
          ThisUser.LastConf := CurrentConf;
          PrintF('CONF'+Cmd);
          IF (NoFile) THEN
            Print('%LFJoined conference: ^5%CT - %CN');
          Cmd := ^M;
        END;
    UNTIL (Cmd = ^M) OR (HangUp);
  END;
  NewCompTables;
END;

PROCEDURE ConferenceEditor;
VAR
  TempConference: ConferenceRecordType;
  Cmd: Char;
  RecNumToList: Integer;

  PROCEDURE InitConferenceVars(VAR Conference: ConferenceRecordType);
  BEGIN
    FillChar(Conference,SizeOf(Conference),0);
    WITH Conference DO
    BEGIN
      Key := ' ';
      Name := '<< New Conference Record >>';
      ACS := ''
    END;
  END;

  PROCEDURE DeleteConference(TempConference1: ConferenceRecordType; RecNumToDelete: SmallInt);
  VAR
    User: UserRecordType;
    RecNum: Integer;
  BEGIN
    IF (NumConfKeys = 0) THEN
      Messages(4,0,'conference records')
    ELSE
    BEGIN
      RecNumToDelete := -1;
      InputIntegerWOC('%LFConference record to delete?',RecNumToDelete,[NumbersOnly],1,NumConfKeys);
      IF (RecNumToDelete >= 1) AND (RecNumToDelete <= NumConfKeys) THEN
      BEGIN
        Reset(ConferenceFile);
        Seek(ConferenceFile,(RecNumToDelete - 1));
        Read(ConferenceFile,TempConference1);
        Close(ConferenceFile);
        LastError := IOResult;
        IF (TempConference1.Key = '@') THEN
        BEGIN
          Print('%LF^7You can not delete the general conference key!^1');
          PauseScr(FALSE);
        END
        ELSE
        BEGIN
          Print('%LFConference record: ^5'+TempConference1.Name);
          IF PYNQ('%LFAre you sure you want to delete it? ',0,FALSE) THEN
          BEGIN
            Print('%LF[> Deleting conference record ...');
            FOR RecNum := 1 TO (MaxUsers - 1) DO
            BEGIN
              LoadURec(User,RecNum);
              IF (User.LastConf = TempConference1.Key) THEN
                User.LastConf := '@';
              SaveURec(User,RecNum);
            END;
            Exclude(ConfKeys,TempConference1.Key);
            Dec(RecNumToDelete);
            Reset(ConferenceFile);
            IF (RecNumToDelete >= 0) AND (RecNumToDelete <= (FileSize(ConferenceFile) - 2)) THEN
              FOR RecNum := RecNumToDelete TO (FileSize(ConferenceFile) - 2) DO
              BEGIN
                Seek(ConferenceFile,(RecNum + 1));
                Read(ConferenceFile,Conference);
                Seek(ConferenceFile,RecNum);
                Write(ConferenceFile,Conference);
              END;
            Seek(ConferenceFile,(FileSize(ConferenceFile) - 1));
            Truncate(ConferenceFile);
            Close(ConferenceFile);
            LastError := IOResult;
            Dec(NumConfKeys);
            SysOpLog('* Deleted conference: ^5'+TempConference1.Name);
          END;
        END;
      END;
    END;
  END;

  PROCEDURE CheckConference(Conference: ConferenceRecordType; StartErrMsg,EndErrMsg: Byte; VAR Ok: Boolean);
  VAR
    Counter: Byte;
  BEGIN
    FOR Counter := StartErrMsg TO EndErrMsg DO
      CASE Counter OF
        1 : IF (Conference.Name = '') OR (Conference.Name = '<< New Conference Record >>') THEN
            BEGIN
              Print('%LF^7The description is invalid!^1');
              OK := FALSE;
            END;
    END;
  END;

  PROCEDURE EditConference(TempConference1: ConferenceRecordType; VAR Conference: ConferenceRecordType; VAR Cmd1: Char;
                           VAR RecNumToEdit: SmallInt; VAR Changed: Boolean; Editing: Boolean);
  VAR
    CmdStr: AStr;
    Ok: Boolean;
  BEGIN
    WITH Conference DO
      REPEAT
        IF (Cmd1 <> '?') THEN
        BEGIN
          Abort := FALSE;
          Next := FALSE;
          CLS;
          IF (Editing) THEN
            PrintACR('^5Editing conference record #'+IntToStr(RecNumToEdit)+' of '+IntToStr(NumConfKeys))
          ELSE
            PrintACR('^5Inserting conference record #'+IntToStr(RecNumToEdit)+' of '+IntToStr(NumConfKeys + 1));
          NL;
          PrintACR('^1A. Key        : ^5'+Key);
          PrintACR('^1B. Description: ^5'+Name);
          PrintACR('^1C. ACS        : ^5'+AOnOff(ACS = '','*None*',ACS));
        END;
        IF (NOT Editing) THEN
          CmdStr := 'ABC'
        ELSE
          CmdStr := 'ABC[]FJL';
        LOneK('%LFModify menu [^5?^4=^5Help^4]: ',Cmd1,'Q?'+CmdStr+^M,TRUE,TRUE);
        CASE Cmd1 OF
          'A' : BEGIN
                  Print('%LF^7You can not modify the conference key.');
                  PauseScr(FALSE);
                END;
          'B' : REPEAT
                  TempConference1.Name := Conference.Name;
                  OK := TRUE;
                  InputWNWC('%LFNew description: ',Name,(SizeOf(Name) - 1),Changed);
                  CheckConference(Conference,1,1,Ok);
                  IF (NOT Ok) THEN
                    Conference.Name := TempConference1.Name;
                UNTIL (OK) OR (HangUp);
          'C' : InputWN1('%LFNew ACS: ',ACS,(SizeOf(ACS) - 1),[InterActiveEdit],Changed);
          '[' : IF (RecNumToEdit > 1) THEN
                  Dec(RecNumToEdit)
                ELSE
                BEGIN
                  Messages(2,0,'');
                  Cmd1 := #0;
                END;
          ']' : IF (RecNumToEdit < NumConfKeys) THEN
                  Inc(RecNumToEdit)
                ELSE
                BEGIN
                  Messages(3,0,'');
                  Cmd1 := #0;
                END;
          'F' : IF (RecNumToEdit <> 1) THEN
                  RecNumToEdit := 1
                ELSE
                BEGIN
                  Messages(2,0,'');
                  Cmd1 := #0;
                END;
          'J' : BEGIN
                  InputIntegerWOC('%LFJump to entry',RecNumToEdit,[NumbersOnly],1,NumConfKeys);
                  IF (RecNumToEdit < 1) OR (RecNumToEdit > NumConfKeys) THEN
                    Cmd1 := #0;
                END;
          'L' : IF (RecNumToEdit <> NumConfKeys) THEN
                  RecNumToEdit := NumConfKeys
                ELSE
                BEGIN
                  Messages(3,0,'');
                  Cmd1 := #0;
                END;
          '?' : BEGIN
                  Print('%LF^1<^3CR^1>Redisplay current screen');
                  Print('^3A^1-^3C^1:Modify item');
                  IF (NOT Editing) THEN
                    LCmds(20,3,'Quit and save','')
                  ELSE
                  BEGIN
                    LCmds(20,3,'[Back entry',']Forward entry');
                    LCmds(20,3,'First entry in list','Jump to entry');
                    LCmds(20,3,'Last entry in list','Quit and save');
                  END;
                END;
        END;
      UNTIL (Pos(Cmd1,'Q[]FJL') <> 0) OR (HangUp);
  END;

  PROCEDURE InsertConference(TempConference1: ConferenceRecordType; Cmd1: Char; RecNumToInsertBefore: SmallInt);
  VAR
    OneKCmds: AStr;
    RecNum,
    RecNumToEdit: SmallInt;
    Ok,
    Changed: Boolean;
  BEGIN
    IF (NumConfKeys = MaxConfKeys) THEN
      Messages(5,MaxConfKeys,'conference records')
    ELSE
    BEGIN
      RecNumToInsertBefore := -1;
      InputIntegerWOC('%LFConference record to insert before?',RecNumToInsertBefore,[NumbersOnly],1,(NumConfKeys + 1));
      IF (RecNumToInsertBefore >= 1) AND (RecNumToInsertBefore <= (NumConfKeys + 1)) THEN
      BEGIN
        OneKCmds := '';
        FOR Cmd1 := '@' TO 'Z' DO
          IF (NOT (Cmd1 IN ConfKeys)) THEN
            OneKCmds := OneKCmds + Cmd1;
        LOneK('%LFChoose conference key [^5@^4-^5Z^4,^5<CR>^4=^5Quit^4]: ',Cmd1,^M+OneKCmds,TRUE,TRUE);
        IF (Cmd1 <> ^M) THEN
        BEGIN
          Reset(ConferenceFile);
          InitConferenceVars(TempConference1);
          TempConference1.Key := Cmd1;
          IF (RecNumToInsertBefore = 1) THEN
            RecNumToEdit := 1
          ELSE IF (RecNumToInsertBefore = (NumConfKeys + 1)) THEN
            RecNumToEdit := (NumConfKeys + 1)
          ELSE
            RecNumToEdit := RecNumToInsertBefore;
          REPEAT
            OK := TRUE;
            EditConference(TempConference1,TempConference1,Cmd1,RecNumToEdit,Changed,FALSE);
            CheckConference(TempConference1,1,1,Ok);
            IF (NOT OK) THEN
              IF (NOT PYNQ('%LFContinue inserting conference record? ',0,TRUE)) THEN
                Abort := TRUE;
          UNTIL (OK) OR (Abort) OR (HangUp);
          IF (NOT Abort) AND (PYNQ('%LFIs this what you want? ',0,FALSE)) THEN
          BEGIN
            Print('%LF[> Inserting conference record ...');
            Include(ConfKeys,Cmd1);
            Seek(ConferenceFile,FileSize(ConferenceFile));
            Write(ConferenceFile,Conference);
            Dec(RecNumToInsertBefore);
            FOR RecNum := ((FileSize(ConferenceFile) - 1) - 1) DOWNTO RecNumToInsertBefore DO
            BEGIN
              Seek(ConferenceFile,RecNum);
              Read(ConferenceFile,Conference);
              Seek(ConferenceFile,(RecNum + 1));
              Write(ConferenceFile,Conference);
            END;
            FOR RecNum := RecNumToInsertBefore TO ((RecNumToInsertBefore + 1) - 1) DO
            BEGIN
              Seek(ConferenceFile,RecNum);
              Write(ConferenceFile,TempConference1);
              Inc(NumConfKeys);
              SysOpLog('* Inserted conference: ^5'+TempConference1.Name);
            END;
          END;
          Close(ConferenceFile);
          LastError := IOResult;
        END;
      END;
    END;
  END;

  PROCEDURE ModifyConference(TempConference1: ConferenceRecordType; Cmd1: Char; RecNumToEdit: SmallInt);
  VAR
    SaveRecNumToEdit: Integer;
    Ok,
    Changed: Boolean;
  BEGIN
    IF (NumConfKeys = 0) THEN
      Messages(4,0,'conference records')
    ELSE
    BEGIN
      RecNumToEdit := -1;
      InputIntegerWOC('%LFConference record to modify?',RecNumToEdit,[NumbersOnly],1,NumConfKeys);
      IF (RecNumToEdit >= 1) AND (RecNumToEdit <= NumConfKeys) THEN
      BEGIN
        SaveRecNumToEdit := -1;
        Cmd1 := #0;
        Reset(ConferenceFile);
        WHILE (Cmd1 <> 'Q') AND (NOT HangUp) DO
        BEGIN
          IF (SaveRecNumToEdit <> RecNumToEdit) THEN
          BEGIN
            Seek(ConferenceFile,(RecNumToEdit - 1));
            Read(ConferenceFile,Conference);
            SaveRecNumToEdit := RecNumToEdit;
            Changed := FALSE;
          END;
          REPEAT
            Ok := TRUE;
            EditConference(TempConference1,Conference,Cmd1,RecNumToEdit,Changed,TRUE);
            CheckConference(Conference,1,1,Ok);
            IF (NOT OK) THEN
            BEGIN
              PauseScr(FALSE);
              IF (RecNumToEdit <> SaveRecNumToEdit) THEN
                RecNumToEdit := SaveRecNumToEdit;
            END;
          UNTIL (OK) OR (HangUp);
          IF (Changed) THEN
          BEGIN
            Seek(ConferenceFile,(SaveRecNumToEdit - 1));
            Write(ConferenceFile,Conference);
            Changed := FALSE;
            SysOpLog('* Modified conference: ^5'+Conference.Name);
          END;
        END;
        Close(ConferenceFile);
        LastError := IOResult;
      END;
    END;
  END;

  PROCEDURE PositionConference(TempConference1: ConferenceRecordType; RecNumToPosition: SmallInt);
  VAR
    RecNumToPositionBefore,
    RecNum1,
    RecNum2: SmallInt;
  BEGIN
    IF (NumConfKeys = 0) THEN
      Messages(4,0,'conference records')
    ELSE IF (NumConfKeys = 1) THEN
      Messages(6,0,'conference records')
    ELSE
    BEGIN
      RecNumToPosition := -1;
      InputIntegerWOC('%LFPosition which conference record?',RecNumToPosition,[NumbersOnly],1,NumConfKeys);
      IF (RecNumToPosition >= 1) AND (RecNumToPosition <= NumConfKeys) THEN
      BEGIN
        RecNumToPositionBefore := -1;
        Print('%LFAccording to the current numbering system.');
        InputIntegerWOC('%LFPosition before which conference record?',RecNumToPositionBefore,
                        [NumbersOnly],1,(NumConfKeys + 1));
        IF (RecNumToPositionBefore >= 1) AND (RecNumToPositionBefore <= (NumConfKeys + 1)) AND
           (RecNumToPositionBefore <> RecNumToPosition) AND (RecNumToPositionBefore <> (RecNumToPosition + 1)) THEN
        BEGIN
          Print('%LF[> Positioning conference records ...');
          Reset(ConferenceFile);
          IF (RecNumToPositionBefore > RecNumToPosition) THEN
            Dec(RecNumToPositionBefore);
          Dec(RecNumToPosition);
          Dec(RecNumToPositionBefore);
          Seek(ConferenceFile,RecNumToPosition);
          Read(ConferenceFile,TempConference1);
          RecNum1 := RecNumToPosition;
          IF (RecNumToPosition > RecNumToPositionBefore) THEN
            RecNum2 := -1
          ELSE
            RecNum2 := 1;
          WHILE (RecNum1 <> RecNumToPositionBefore) DO
          BEGIN
            IF ((RecNum1 + RecNum2) < FileSize(ConferenceFile)) THEN
            BEGIN
              Seek(ConferenceFile,(RecNum1 + RecNum2));
              Read(ConferenceFile,Conference);
              Seek(ConferenceFile,RecNum1);
              Write(ConferenceFile,Conference);
            END;
            Inc(RecNum1,RecNum2);
          END;
          Seek(ConferenceFile,RecNumToPositionBefore);
          Write(ConferenceFile,TempConference1);
          Close(ConferenceFile);
          LastError := IOResult;
        END;
      END;
    END;
  END;

BEGIN
  Cmd := #0;
  REPEAT
    IF (Cmd <> '?') THEN
      DisplayConferenceRecords(RecNumToList,TRUE);
    LOneK('%LFConference editor [^5?^4=^5Help^4]: ',Cmd,'QDIMP?'^M,TRUE,TRUE);
    CASE Cmd OF
      'D' : DeleteConference(TempConference,RecNumToList);
      'I' : InsertConference(TempConference,Cmd,RecNumToList);
      'M' : ModifyConference(TempConference,Cmd,RecNumToList);
      'P' : PositionConference(TempConference,RecNumToList);
      '?' : BEGIN
              Print('%LF^1<^3CR^1>Next Screen or redisplay screen');
              Print('^1(^3?^1)Help/First conference');
              LCmds(18,3,'Delete conference','Insert conference');
              LCmds(18,3,'Modify conference','Position conference');
              LCmds(18,3,'Quit','');
            END;
    END;
    IF (Cmd <> ^M) THEN
      RecNumToList := 1;
  UNTIL (Cmd = 'Q') OR (HangUp);
  LastError := IOResult;
END;

END.