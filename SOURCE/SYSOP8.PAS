{$IFDEF WIN32}
{$I DEFINES.INC}
{$ENDIF}

{$A+,B-,D+,E-,F+,I-,L+,N-,O+,R-,S+,V-}

UNIT SysOp8;

INTERFACE

PROCEDURE MessageAreaEditor;

IMPLEMENTATION

USES
  Common,
  File2,
  Mail0,
  SysOp7;

PROCEDURE MessageAreaEditor;
CONST
  DisplayType: Byte = 1;
VAR
  MsgareaDefFile: FILE OF MessageAreaRecordType;
  TempMemMsgArea: MessageAreaRecordType;
  Cmd: Char;
  RecNumToList: SmallInt;
  Ok,
  Changed,
  SaveTempPause: Boolean;

  FUNCTION DisplayNetFlags(MAFlags: MAFlagSet; C1,C2: Char): AStr;
  VAR
    MAFlagT: MessageAreaFlagType;
    TempS: AStr;
  BEGIN
    TempS := '';
    FOR MAFlagT := MASKludge TO MAInternet DO
      IF (MAFlagT IN MAFlags) THEN
        TempS := TempS + '^'+C1+Copy('RUAPFQKSOTI',(Ord(MAFlagT) + 1),1)
      ELSE
        TempS := TempS + '^'+C2+'-';
    DisplayNetFlags := TempS;
  END;

  FUNCTION DisplayMAFlags(MAFlags: MAFlagSet; C1,C2: Char): AStr;
  VAR
    MAFlagT: MessageAreaFlagType;
    TempS: AStr;
  BEGIN
    TempS := '';
    FOR MAFlagT := MARealName TO MAQuote DO
      IF (MAFlagT IN MAFlags) THEN
        TempS := TempS + '^'+C1+Copy('RUAPFQKSOTI',(Ord(MAFlagT) + 1),1)
      ELSE
        TempS := TempS + '^'+C2+'-';
    DisplayMAFlags := TempS;
  END;

  PROCEDURE ToggleMAFlag(MAFlagT: MessageAreaFlagType; VAR MAFlags: MAFlagSet);
  BEGIN
    IF (MAFlagT IN MAFlags) THEN
      Exclude(MAFlags,MAFlagT)
    ELSE
      Include(MAFlags,MAFlagT);
  END;

  PROCEDURE ToggleMAFlags(C: Char; VAR MAFlags: MAFlagSet; VAR Changed: Boolean);
  VAR
    TempMAFlags: MAFlagSet;
  BEGIN
    TempMAFlags := MAFlags;
    CASE C OF
      'R' : ToggleMAFlag(MARealName,MAFlags);
      'U' : ToggleMAFlag(MAUnHidden,MAFlags);
      'A' : ToggleMAFlag(MAFilter,MAFlags);
      'P' : ToggleMAFlag(MAPrivate,MAFlags);
      'F' : ToggleMAFlag(MAForceRead,MAFlags);
      'Q' : ToggleMAFlag(MAQuote,MAFlags);
      'K' : ToggleMAFlag(MASKludge,MAFlags);
      'S' : ToggleMAFlag(MASSeenby,MAFlags);
      'O' : ToggleMAFlag(MASOrigin,MAFlags);
      'T' : ToggleMAFlag(MAAddTear,MAFlags);
      'I' : ToggleMAFlag(MAInternet,MAFlags);
    END;
    IF (MAFlags <> TempMAFlags) THEN
      Changed := TRUE;
  END;

  FUNCTION AnonTypeChar(Anonymous: AnonTyp): Char;
  BEGIN
    CASE Anonymous OF
      ATYes      : AnonTypeChar := 'Y';
      ATNo       : AnonTypeChar := 'N';
      ATForced   : AnonTypeChar := 'F';
      ATDearAbby : AnonTypeChar := 'D';
      ATAnyName  : AnonTypeChar := 'A';
    END;
  END;

  FUNCTION NodeStr(AKA: BYTE): AStr;
  VAR
    TempS: AStr;
  BEGIN
    TempS := IntToStr(General.AKA[AKA].Zone)+':'+
             IntToStr(General.AKA[AKA].Net)+'/'+
             IntToStr(General.AKA[AKA].Node);
    IF (General.AKA[AKA].Point > 0) THEN
       TempS := TempS+'.'+IntToStr(General.AKA[AKA].Point);
    NodeStr := TempS;
  END;

  FUNCTION MATypeStr(MAType: Integer): AStr;
  BEGIN
    CASE MAType OF
      0 : MATypeStr := 'Local';
      1 : MATypeStr := 'EchoMail';
      2 : MATypeStr := 'GroupMail';
      3 : MATypeStr := 'QwkMail';
    END;
  END;

  FUNCTION AnonTypeStr(Anonymous: AnonTyp): ASTR;
  BEGIN
    CASE Anonymous OF
      ATYes      : AnonTypeStr := 'Yes';
      ATNo       : AnonTypeStr := 'No';
      ATForced   : AnonTypeStr := 'Forced';
      ATDearAbby : AnonTypeStr := 'Dear Abby';
      ATAnyName  : AnonTypeStr := 'Any Name';
    END;
  END;

  PROCEDURE InitMsgAreaVars(VAR MemMsgArea: MessageAreaRecordType);
  BEGIN
    FillChar(MemMsgArea,SizeOf(MemMsgArea),0);
    WITH MemMsgArea DO
    BEGIN
      Name := '<< New Message Area >>';
      FileName := 'NEWBOARD';
      MsgPath := '';
      ACS := '';
      PostACS := '';
      MCIACS := '';
      SysOpACS := '';
      MaxMsgs := 100;
      Anonymous := ATNo;
      Password := '';
      MAFlags := [];
      MAType := 0;
      Origin := '';
      Text_Color := General.Text_Color;
      Quote_Color := General.Quote_Color;
      Tear_Color := General.Tear_Color;
      Origin_Color := General.Origin_Color;
      MessageReadMenu := 0;
      QuoteStart := '|03Quoting message from |11@F |03to |11@T';
      QuoteEnd := '|03on |11@D|03.';
      PrePostFile := '';
      AKA := 0;
      QWKIndex := 0;
    END;
  END;

  PROCEDURE ChangeMsgAreaDrive(Drive: Char; FirstRecNum: SmallInt);
  VAR
    LastRecNum,
    RecNum: SmallInt;
  BEGIN
    IF (NumMsgAreas = 0) THEN
      Messages(4,0,'message areas')
    ELSE
    BEGIN
      FirstRecNum := -1;
      InputIntegerWOC('%LFMessage area to start at?',FirstRecNum,[NumbersOnly],1,NumMsgAreas);
      IF (FirstRecNum >= 1) AND (FirstRecNum <= NumMsgAreas) THEN
      BEGIN
        LastRecNum := -1;
        InputIntegerWOC('%LFMessage area to end at?',LastRecNum,[NumbersOnly],1,NumMsgAreas);
        IF (LastRecNum >= 1) AND (LastRecNum <= NumMsgAreas) THEN
        BEGIN
          IF (FirstRecNum > LastRecNum) OR (LastRecNum < FirstRecNum) THEN
            Messages(8,0,'')
          ELSE
          BEGIN
            LOneK('%LFChange to which drive? (^5A^4-^5Z^4): ',Drive,'ABCDEFGHIJKLMNOPQRSTUVWXYZ'^M,TRUE,TRUE);
            ChDir(Drive+':');
            IF (IOResult <> 0) THEN
              Messages(7,0,'')
            ELSE
            BEGIN
              ChDir(StartDir);
              Prompt('%LFUpdating the drive for message area '+IntToStr(FirstRecNum)+' to '+IntTostr(LastRecNum)+' ... ');
              Reset(MsgAreaFile);
              FOR RecNum := FirstRecNum TO LastRecNum DO
              BEGIN
                Seek(MsgAreaFile,(RecNum - 1));
                Read(MsgAreaFile,MemMsgArea);
                IF (MemMsgArea.MAType IN [1,2]) THEN
                  MemMsgArea.MsgPath[1] := Drive;
                Seek(MsgAreaFile,(RecNum - 1));
                Write(MsgAreaFile,MemMsgArea);
              END;
              Close(MsgAreaFile);
              LastError := IOResult;
              Print('Done');
              SysOpLog('* Changed message areas: ^5'+IntToStr(FirstRecNum)+'^1-^5'+IntToStr(LastRecNum)+'^1 to ^5'+Drive+':\');
            END;
          END;
        END;
      END;
    END
  END;

  PROCEDURE DeleteMsgArea(TempMemMsgArea1: MessageAreaRecordType; RecNumToDelete: SmallInt);
  VAR
    RecNum: Integer;
    Ok,
    Ok1: Boolean;
  BEGIN
    IF (NumMsgAreas = 0) THEN
      Messages(4,0,'message areas')
    ELSE
    BEGIN
      RecNumToDelete := -1;
      InputIntegerWOC('%LFMessage area to delete?',RecNumToDelete,[NumbersOnly],1,NumMsgAreas);
      IF (RecNumToDelete >= 1) AND (RecNumToDelete <= NumMsgAreas) THEN
      BEGIN
        Reset(MsgAreaFile);
        Seek(MsgAreaFile,(RecNumToDelete - 1));
        Read(MsgAreaFile,TempMemMsgArea1);
        Close(MsgAreaFile);
        LastError := IOResult;
        Print('%LFMessage area: ^5'+TempMemMsgArea1.Name);
        IF PYNQ('%LFAre you sure you want to delete it? ',0,FALSE) THEN
        BEGIN
          Print('%LF[> Deleting message area record ...');
          Dec(RecNumToDelete);
          Reset(MsgAreaFile);
          IF (RecNumToDelete >= 0) AND (RecNumToDelete <= (FileSize(MsgAreaFile) - 2)) THEN
            FOR RecNum := RecNumToDelete TO (FileSize(MsgAreaFile) - 2) DO
            BEGIN
              Seek(MsgAreaFile,(RecNum + 1));
              Read(MsgAreaFile,MemMsgArea);
              Seek(MsgAreaFile,RecNum);
              Write(MsgAreaFile,MemMsgArea);
            END;
          Seek(MsgAreaFile,(FileSize(MsgAreaFile) - 1));
          Truncate(MsgAreaFile);
          Close(MsgAreaFile);
          LastError := IOResult;
          Dec(NumMsgAreas);
          SysOpLog('* Deleted message area: ^5'+TempMemMsgArea1.Name);
          Ok := TRUE;
          Ok1 := TRUE;
          Reset(MsgAreaFile);
          FOR RecNum := 1 TO FileSize(MsgAreaFile) DO
          BEGIN
            Seek(MsgAreaFile,(RecNum - 1));
            Read(MsgAreaFile,MemMsgArea);
            IF (MemMsgArea.FileName = TempMemMsgArea1.FileName) THEN
              Ok := FALSE;
            IF (TempMemMsgArea1.MAType IN [1,2]) AND (MemMsgArea.MsgPath = TempMemMsgArea1.MsgPath) THEN
              Ok1 := FALSE;
          END;
          Close(MsgAreaFile);
          IF (Ok) THEN
            IF (PYNQ('%LFDelete message area data files also? ',0,FALSE)) THEN
            BEGIN
              Kill(General.MsgPath+MemMsgArea.FileName+'.HDR');
              Kill(General.MsgPath+MemMsgArea.FileName+'.DAT');
              Kill(General.MsgPath+MemMsgArea.FileName+'.SCN');
            END;
          IF (Ok1) AND (TempMemMsgArea1.MAType IN [1,2]) THEN
            IF PYNQ('%LFRemove the message directory? ',0,FALSE) THEN
              PurgeDir(TempMemMsgArea1.MsgPath,TRUE);
        END;
      END;
    END;
  END;

  PROCEDURE CheckMessageArea(MemMsgArea: MessageAreaRecordType; StartErrMsg,EndErrMsg: Byte; VAR Ok: Boolean);
  VAR
    Counter: Byte;
  BEGIN
    FOR Counter := StartErrMsg TO EndErrMsg DO
      CASE Counter OF
        1 : IF (MemMsgArea.Name = '') OR (MemMsgArea.Name = '<< New Message Area >>') THEN
            BEGIN
              Print('%LF^7The area name is invalid!^1');
              OK := FALSE;
            END;
        2 : IF (MemMsgArea.FileName = '') OR (MemMsgArea.FileName = 'NEWBOARD') THEN
            BEGIN
              Print('%LF^7The file name is invalid!^1');
              OK := FALSE;
            END;
        3 : IF (MemMsgArea.MAType IN [1,2]) AND (MemMsgArea.MsgPath = '') THEN
            BEGIN
              Print('%LF^7The message path is invalid!^1');
              OK := FALSE;
            END;
        4 : IF (MemMsgArea.MAType IN [1,2]) AND (General.AKA[MemMsgArea.AKA].Net = 0) THEN
            BEGIN
              Print('%LF^7The AKA address is invalid!^1');
              Ok := FALSE;
            END;
        5 : IF (MemMsgArea.MAType IN [1..3]) AND (MemMsgArea.Origin = '') THEN
            BEGIN
              Print('%LF^7The origin is invalid!^1');
              Ok := FALSE;
            END;
      END;
  END;

  PROCEDURE EditMessageArea(TempMemMsgArea1: MessageAreaRecordType; VAR MemMsgArea: MessageAreaRecordType; VAR Cmd1: Char;
                            VAR RecNumToEdit: SmallInt; VAR Changed: Boolean; Editing: Boolean);
  VAR
    TempFileName: Str8;
    Path1,
    Path2: Str52;
    CmdStr: AStr;
    RecNum,
    RecNum1,
    RecNumToList: Integer;
    SaveQWKIndex: Word;
    Ok: Boolean;
  BEGIN
    WITH MemMsgArea DO
      REPEAT
        IF (Cmd1 <> '?') THEN
        BEGIN
          MCIAllowed := FALSE;
          Abort := FALSE;
          Next := FALSE;
          CLS;
          IF (RecNumToEdit = -1) THEN
            PrintACR('^5Default Message Area Configuration:')
          ELSE
          BEGIN
            IF (Editing) THEN
              PrintACR('^5Editing '+AOnOff(RecNumToEdit = 0,'private mail','message area #'+IntToStr(RecNumToEdit)+
                       ' of '+IntToStr(NumMsgAreas)))
            ELSE
              PrintACR('^5Inserting message area #'+IntToStr(RecNumToEdit)+' of '+IntToStr(NumMsgAreas + 1));
          END;
          NL;
          PrintACR('^1A. Area name   : ^5'+Name);
          PrintACR('^1B. File name   : ^5'+FileName+'   ^7('+General.MsgPath+MemMsgArea.FileName+'.*)');
          PrintACR('^1C. Area type   : ^5'+MATypeStr(MAType));
          IF (MAType IN [1,2]) THEN
            PrintACR('^1   Message path: ^5'+MsgPath);
          PrintACR('^1D. ACS required: ^5'+AOnOff(ACS = '','*None*',ACS));
          PrintACR('^1E. Post/MCI ACS: ^5'+AOnOff(PostACS = '','*None*',PostACS)+'^1 / ^5'
                                       +AOnOff(MCIACS = '','*None*',MCIACS));
          PrintACR('^1G. Sysop ACS   : ^5'+AOnOff(SysOpACS = '','*None*',SysOpACS));
          PrintACR('^1H. Max messages: ^5'+IntToStr(MaxMsgs));
          PrintACR('^1I. Anonymous   : ^5'+AnonTypeStr(Anonymous));
          PrintACR('^1K. Password    : ^5'+AOnOff(Password = '','*None*',Password));
          IF (MAType IN [1,2]) THEN
            PrintACR('^1M. Net Address : ^5'+NodeStr(AKA));
          PrintACR('^1N. Colors      : ^1Text=^'+IntToStr(Text_Color)+IntToStr(Text_Color)+
                                      '^1, Quote=^'+IntToStr(Quote_Color)+IntToStr(Quote_Color)+
                                      '^1, Tear=^'+IntToStr(Tear_Color)+IntToStr(Tear_Color)+
                                      '^1, Origin=^'+IntToStr(Origin_Color)+IntToStr(Origin_Color));
          PrintACR('^1O. Read menu   : ^5'+IntToStr(MessageReadMenu));
          IF (MAType IN [1,2]) THEN
            PrintACR('^1P. Mail flags  : ^5'+DisplayNetFlags(MAFlags,'5','1'));
          IF (MAType IN [1..3]) THEN
            PrintACR('^1R. Origin line : ^5'+Origin);
          PrintACR('^1S. Start quote : ^5'+AOnOff(QuoteStart = '','*None*',QuoteStart));
          PrintACR('^1T. End quote   : ^5'+AOnOff(QuoteEnd = '','*None*',QuoteEnd));
          PrintACR('^1U. Post file   : ^5'+AOnOff(PrePostFile = '','*None*',PrePostFile));
          PrintACR('^1V. QWK Index   : ^5'+IntToStr(QWKIndex));
          PrintACR('^1W. Flags       : ^5'+DisplayMAFlags(MAFlags,'5','1'));
          MCIAllowed := TRUE;
        END;
        IF (RecNumToEdit = 0) THEN
          CmdStr := 'ADEGHNOSTUW'
        ELSE
        BEGIN
          IF (NOT Editing) THEN
            CmdStr := 'ABCDEGHIKNOSTUVW'
          ELSE
            CmdStr := 'ABCDEGHIKNOSTUVW[]FJL';
          IF (MAType IN [1,2]) THEN
            CmdStr := CmdStr + 'MP';
          IF (MAType IN [1..3]) THEN
            CmdStr := CmdStr + 'R';
        END;
        LOneK('%LFModify menu [^5?^4=^5Help^4]: ',Cmd1,'Q?'+CmdStr+^M,TRUE,TRUE);
        CASE Cmd1 OF
          'A' : REPEAT
                  TempMemMsgArea1.Name := MemMsgArea.Name;
                  Ok := TRUE;
                  InputWNWC('%LFNew area name: ',Name,(SizeOF(Name) - 1),Changed);
                  CheckMessageArea(MemMsgArea,1,1,Ok);
                  IF (NOT Ok) THEN
                    MemMsgArea.Name := TempMemMsgArea1.Name;
                UNTIL (Ok) OR (HangUp);
          'B' : REPEAT
                  Ok := TRUE;
                  TempFileName := FileName;
                  InputWN1('%LFNew file name (^5Do not enter ^4"^5.EXT^4"): ',TempFileName,(SizeOf(FileName) - 1),
                           [UpperOnly,InterActiveEdit],Changed);
                  TempFileName := SQOutSp(TempFileName);
                  IF (Pos('.',TempFileName) > 0) THEN
                    FileName := Copy(TempFileName,1,(Pos('.',TempFileName) - 1));
                  MemMsgArea.FileName := TempFileName;
                  CheckMessageArea(MemMsgArea,2,2,Ok);
                  TempFileName := MemMsgArea.FileName;
                  IF (Ok) AND (TempFileName <> MemMsgArea.FileName) THEN
                  BEGIN
                    RecNum1 := -1;
                    RecNum := 0;
                    WHILE (RecNum <= (FileSize(MsgAreaFile) - 1)) AND (RecNum1 = -1) DO
                    BEGIN
                      Seek(MsgAreaFile,RecNum);
                      Read(MsgAreaFile,TempMemMsgArea1);
                      IF (TempFileName = TempMemMsgArea1.FileName) THEN
                      BEGIN
                        Print('%LF^7The file name is already in use!^1');
                        RecNum1 := 1;
                        IF NOT PYNQ('%LFUse this file name anyway? ',0,FALSE) THEN
                          Ok := FALSE;
                      END;
                      Inc(RecNum);
                    END;
                  END;
                  IF (Ok) THEN
                  BEGIN
                    Path1 := General.MsgPath+MemMsgArea.FileName;
                    FileName := TempFileName;
                    IF (Editing) THEN
                    BEGIN
                      Path2 := General.MsgPath+MemMsgArea.FileName;
                      IF Exist(Path1+'.HDR') AND (NOT Exist(Path2+'.HDR')) THEN
                      BEGIN
                        Print('%LFOld HDR/DAT/SCN file names: "^5'+Path1+'.*^1"');
                        Print('%LFNew HDR/DAT/SCN file names: "^5'+Path2+'.*^1"');
                        IF PYNQ('%LFRename old data files? ',0,FALSE) THEN
                        BEGIN
                          CopyMoveFile(FALSE,'%LF^1Renaming "^5'+Path1+'.HDR^1" to "^5'+Path2+'.HDR^1": ',Path1+'.HDR',
                                       Path2+'.HDR',TRUE);
                          CopyMoveFile(FALSE,'%LF^1Renaming "^5'+Path1+'.DAT^1" to "^5'+Path2+'.DAT^1": ',Path1+'.DAT',
                                       Path2+'.DAT',TRUE);
                          CopyMoveFile(FALSE,'%LF^1Renaming "^5'+Path1+'.SCN^1" to "^5'+Path2+'.SCN^1": ',Path1+'.SCN',
                                       Path2+'.SCN',TRUE);
                        END;
                      END;
                    END;
                  END;
                UNTIL (Ok) OR (HangUp);
          'C' : BEGIN
                  TempMemMsgArea1.MAType := MaType;
                  Print('%LF^5Message area types:^1');
                  NL;
                  LCmds(10,3,'Local','');
                  LCmds(10,3,'Echomail','');
                  LCmds(10,3,'Groupmail','');
                  LCmds(10,3,'QWKmail','');
                  LOneK('%LFNew message area type [^5L^4,^5E^4,^5G^4,^5Q^4,^5<CR>^4=^5Quit^4]: ',Cmd1,'LEGQ'^M,TRUE,TRUE);
                  CASE Cmd1 OF
                    'L' : MAType := 0;
                    'E' : MAType := 1;
                    'G' : MAType := 2;
                    'Q' : MAType := 3;
                  END;
                  IF (MAType IN [1,2]) THEN
                  BEGIN
                    IF (MsgPath <> '') THEN
                      MsgPath := MsgPath
                    ELSE
                      MsgPath := General.DefEchoPath+FileName+'\';
                    InputPath('%LF^1New message path (^5End with a ^1"^5\^1"):%LF^4:',MsgPath,FALSE,FALSE,Changed);
                  END;
                  IF (TempMemMsgArea1.MAtype <> MaType) THEN
                  BEGIN
                    IF (MaType IN [0,3]) THEN
                    BEGIN
                      MsgPath := '';
                      IF (MASKludge IN MAFlags) THEN
                        Exclude(MAFlags,MASKludge);
                      IF (MASSeenby IN MAFlags) THEN
                        Exclude(MAFlags,MASSeenby);
                      IF (MASOrigin IN MAFlags) THEN
                        Exclude(MAFlags,MASOrigin);
                      IF (MAAddTear IN MAFlags) THEN
                        Exclude(MAFlags,MAAddTear);
                    END
                    ELSE
                    BEGIN
                      IF (General.SKludge) THEN
                        Include(MAFlags,MASKludge);
                      IF (General.SSeenby) THEN
                        Include(MAFlags,MASSeenby);
                      IF (General.SOrigin) THEN
                        Include(MAFlags,MASOrigin);
                      IF (General.Addtear) THEN
                        Include(MAFlags,MAAddTear);
                    END;
                    IF (MAType = 0) THEN
                      Origin := ''
                    ELSE
                    BEGIN
                      IF (General.Origin <> '') THEN
                        Origin := General.Origin;
                    END;
                    Changed := TRUE;
                  END;
                  Cmd1 := #0;
                END;
          'D' : InputWN1('%LFNew ACS: ',ACS,(SizeOf(ACS) - 1),[InterActiveEdit],Changed);
          'E' : BEGIN
                  InputWN1('%LFNew Post ACS: ',PostACS,(SizeOf(PostACS) - 1),[InterActiveEdit],Changed);
                  InputWN1('%LFNew MCI ACS: ',MCIACS,(SizeOf(MCIACS) - 1),[InterActiveEdit],Changed);
                END;
          'G' : InputWN1('%LFNew SysOp ACS: ',SysOpACS,(SizeOf(SysOpACS) - 1),[InterActiveEdit],Changed);
          'H' : InputWordWC('%LFMax messages',MaxMsgs,[DisplayValue,NumbersOnly],1,65535,Changed);
          'I' : BEGIN
                  TempMemMsgArea1.Anonymous := Anonymous;
                  Print('%LF^5Anonymous types:^1');
                  NL;
                  LCmds(40,3,'Yes, Anonymous allowed, selectively','');
                  LCmds(40,3,'No, Anonymous not allowed','');
                  LCmds(40,3,'Forced Anonymous','');
                  LCmds(40,3,'Dear Abby','');
                  LCmds(40,3,'Any Name','');
                  LOneK('%LFNew anonymous type [^5Y^4,^5N^4,^5F^4,^5D^4,^5A^4,^5<CR>^4=^5Quit^4]: ',Cmd1,'YNFDA'^M,TRUE,TRUE);
                  CASE Cmd1 OF
                    'Y' : Anonymous := ATYes;
                    'N' : Anonymous := ATNo;
                    'F' : Anonymous := ATForced;
                    'D' : Anonymous := ATDearAbby;
                    'A' : Anonymous := ATAnyName;
                  END;
                  IF (TempMemMsgArea1.Anonymous <> Anonymous) THEN
                    Changed := TRUE;
                  Cmd1 := #0;
                END;
          'K' : InputWN1('%LFNew password: ',Password,(SizeOf(Password) - 1),[InterActiveEdit,UpperOnly],Changed);
          'M' : IF (MAType IN [1,2]) THEN
                BEGIN
                  TempMemMsgArea1.AKA := AKA;
                  REPEAT
                    Ok := TRUE;
                    Print('%LF^5Network addresses:');
                    NL;
                    FOR RecNum := 0 TO 19 DO
                    BEGIN
                      Prompt('^1'+PadRightStr(IntToStr(RecNum),2)+'. ^5'+PadLeftStr(NodeStr(RecNum),25));
                      IF (Odd(RecNum)) THEN
                        NL;
                    END;
                    InputByteWOC('%LFNew AKA address',AKA,[DisplayValue,NumbersOnly],0,19);
                    CheckMessageArea(MemMsgArea,4,4,Ok);
                    IF (NOT Ok) THEN
                      AKA := TempMemMsgArea1.AKA;
                  UNTIL (Ok) OR (HangUp);
                  IF (TempMemMsgArea1.AKA <> AKA) THEN
                    Changed := TRUE;
                END;
          'N' : BEGIN
                  Prompt('%LF^5Colors: ');
                  ShowColors;
                  InputByteWC('%LFNew standard text color',Text_Color,[DisplayValue,NumbersOnly],0,9,Changed);
                  InputByteWC('%LFNew quoted text color',Quote_Color,[DisplayValue,NumbersOnly],0,9,Changed);
                  InputByteWC('%LFNew tear line color',Tear_Color,[DisplayValue,NumbersOnly],0,9,Changed);
                  InputByteWC('%LFNew origin line color',Origin_Color,[DisplayValue,NumbersOnly],0,9,Changed);
                END;
          'O' : FindMenu('%LFNew read menu (^50^4=^5Default^4)',MessageReadMenu,0,NumMenus,Changed);
          'P' : IF (MAType IN [1,2]) THEN
                BEGIN
                  REPEAT
                    LOneK('%LFToggle which network flag ('+DisplayNetFlags(MAFlags,'5','4')+
                        '^4) [^5?^4=^5Help^4,^5<CR>^4=^5Quit^4]: ',Cmd1,^M'IKSOCBMT?',TRUE,TRUE);
                    CASE Cmd1 OF
                      'K','S','O','T','I' :
                            ToggleMAFlags(Cmd1,MAFlags,Changed);
                      '?' : BEGIN
                              NL;
                              LCmds(22,3,'Kludge line strip','SEEN-BY line strip');
                              LCmds(22,3,'Origin line strip','Tear/Origin line add');
                              LCmds(22,3,'Internet flag','');
                            END;
                    END;
                  UNTIL (Cmd1 = ^M) OR (HangUp);
                  Cmd1 := #0;
                END;
          'R' : IF (MAType IN [1..3]) THEN
                REPEAT
                  OK := TRUE;
                  InputWN1('%LF^4New origin line:%LF: ',Origin,(SizeOf(Origin) - 1),[InterActiveEdit],Changed);
                  CheckMessageArea(MemMsgArea,5,5,Ok);
                UNTIL (Ok) OR (HangUp);
          'S' : InputWNWC('%LF^1New starting quote:%LF^4: ',QuoteStart,(SizeOf(QuoteStart) - 1),Changed);
          'T' : InputWNWC('%LF^1New ending quote:%LF^4: ',QuoteEnd,(SizeOf(QuoteEnd) - 1),Changed);
          'U' : InputWN1('%LFNew pre-post filename: ',PrePostFile,(SizeOf(PrePostFile) - 1),[],Changed);
          'V' : BEGIN
                  SaveQWKIndex := QWKIndex;
                  InputWordWOC('%LFNew permanent QWK Index',QWKIndex,[DisplayValue,NumbersOnly],1,(NumMsgAreas + 1));
                  IF (SaveQWKIndex <> QWKIndex) AND (QWKIndex >= 1) AND (QWKIndex <= (NumMsgAreas + 1)) THEN
                  BEGIN
                    RecNum1 := -1;
                    RecNum := 0;
                    WHILE (RecNum <= (FileSize(MsgAreaFile) - 1)) AND (RecNum1 = -1) DO
                    BEGIN
                      Seek(MsgAreaFile,RecNum);
                      Read(MsgAreaFile,TempMemMsgArea1);
                      IF (QWKIndex = TempMemMsgArea1.QWKIndex) THEN
                      BEGIN
                        Print('%LF^7The QWK Index number is already in use!^1');
                        PauseScr(FALSE);
                        RecNum1 := 1;
                        QWKIndex := SaveQWKIndex;
                      END;
                      Inc(RecNum);
                    END;
                  END;
                  IF (SaveQWKIndex <> QWKIndex) THEN
                    Changed := TRUE;
                END;
          'W' : BEGIN
                  REPEAT
                    LOneK('%LFToggle which flag ('+DisplayMAFlags(MAFlags,'5','4')+
                        '^4) [^5?^4=^5Help^4,^5<CR>^4=^5Quit^4]: ',Cmd1,^M'RUAPFQ?',TRUE,TRUE);
                    CASE Cmd1 OF
                      'R','U','A','P','F','Q' :
                            ToggleMAFlags(Cmd1,MAFlags,Changed);
                      '?' : BEGIN
                              NL;
                              LCmds(25,3,'Real names','Unhidden');
                              LCmds(25,3,'AFilter ANSI/8-bit ASCII','Private msgs allowed');
                              LCmds(25,3,'Force Read','Quote/Tagline');
                            END;
                    END;
                  UNTIL (Cmd1 = ^M) OR (HangUp);
                  Cmd1 := #0;
                END;
          '[' : IF (RecNumToEdit > 1) THEN
                  Dec(RecNumToEdit)
                ELSE
                BEGIN
                  Messages(2,0,'');
                  Cmd1 := #0;
                END;
          ']' : IF (RecNumToEdit < NumMsgAreas) THEN
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
                  InputIntegerWOC('%LFJump to entry?',RecNumToEdit,[NumbersOnly],1,NumMsgAreas);
                  IF (RecNumToEdit < 1) OR (RecNumToEdit > NumMsgAreas) THEN
                    Cmd1 := #0;
                END;
          'L' : IF (RecNumToEdit <> NumMsgAreas) THEN
                  RecNumToEdit := NumMsgAreas
                ELSE
                BEGIN
                  Messages(3,0,'');
                  Cmd1 := #0;
                END;
          '?' : BEGIN
                  Print('%LF^1<^3CR^1>Redisplay current screen');
                  Print('^3A^1-^3E^1,^3G^1-^3I^1,^3K^1,^3M^1-^3P^1,^3R^1-^3W^1:Modify item');
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

  PROCEDURE InsertMsgArea(TempMemMsgArea1: MessageAreaRecordType; Cmd1: Char; RecNumToInsertBefore: SmallInt);
  VAR
    MsgAreaScanFile: FILE OF ScanRec;
    RecNum,
    RecNum1,
    RecNumToEdit: SmallInt;
    Ok,
    Changed: Boolean;
  BEGIN
    IF (NumMsgAreas = MaxMsgAreas) THEN
      Messages(5,MaxMsgAreas,'message areas')
    ELSE
    BEGIN
      RecNumToInsertBefore := -1;
      InputIntegerWOC('%LFMessage area to insert before?',RecNumToInsertBefore,[NumbersOnly],1,(NumMsgAreas + 1));
      IF (RecNumToInsertBefore >= 1) AND (RecNumToInsertBefore <= (NumMsgAreas + 1)) THEN
      BEGIN
        Reset(MsgAreaFile);

        Assign(MsgAreaDefFile,General.DataPath+'MBASES.DEF');
        IF (NOT Exist(General.DataPath+'MBASES.DEF')) THEN
          InitMsgAreaVars(TempMemMsgArea1)
        ELSE
        BEGIN
          Reset(MsgAreaDefFile);
          Seek(MsgAreaDefFile,0);
          Read(MsgAreaDefFile,TempMemMsgArea1);
          Close(MsgAreaDefFile);
        END;

        TempMemMsgArea1.QWKIndex := (FileSize(MsgAreaFile) + 1);
        IF (RecNumToInsertBefore = 1) THEN
          RecNumToEdit := 1
        ELSE IF (RecNumToInsertBefore = (NumMsgAreas + 1)) THEN
          RecNumToEdit := (NumMsgAreas + 1)
        ELSE
          RecNumToEdit := RecNumToInsertBefore;
        REPEAT
          OK := TRUE;
          EditMessageArea(TempMemMsgArea1,TempMemMsgArea1,Cmd1,RecNumToEdit,Changed,FALSE);
          CheckMessageArea(TempMemMsgArea1,1,5,Ok);
          IF (NOT OK) THEN
            IF (NOT PYNQ('%LFContinue inserting message area? ',0,TRUE)) THEN
              Abort := TRUE;
        UNTIL (OK) OR (Abort) OR (HangUp);
        IF (NOT Abort) AND (PYNQ('%LFIs this what you want? ',0,FALSE)) THEN
        BEGIN
          Print('%LF[> Inserting message area record ...');
          Seek(MsgAreaFile,FileSize(MsgAreaFile));
          Write(MsgAreaFile,MemMsgArea);
          Dec(RecNumToInsertBefore);
          FOR RecNum := ((FileSize(MsgAreaFile) - 1) - 1) DOWNTO RecNumToInsertBefore DO
          BEGIN
            Seek(MsgAreaFile,RecNum);
            Read(MsgAreaFile,MemMsgArea);
            Seek(MsgAreaFile,(RecNum + 1));
            Write(MsgAreaFile,MemMsgArea);
          END;
          FOR RecNum := RecNumToInsertBefore TO ((RecNumToInsertBefore + 1) - 1) DO
          BEGIN
            IF (TempMemMsgArea1.MAType IN [1,2]) THEN
              MakeDir(TempMemMsgArea1.MsgPath,FALSE);
            IF (NOT Exist(General.MsgPath+TempMemMsgArea1.FileName+'.HDR')) THEN
            BEGIN
              Assign(MsgHdrF,General.MsgPath+TempMemMsgArea1.FileName+'.HDR');
              ReWrite(MsgHdrF);
              Close(MsgHdrF);
            END;
            IF (NOT Exist(General.MsgPath+TempMemMsgArea1.FileName+'.DAT')) THEN
            BEGIN
              Assign(MsgTxtF,General.MsgPath+TempMemMsgArea1.FileName+'.DAT');
              ReWrite(MsgTxtF,1);
              Close(MsgTxtF);
            END;
            IF (NOT Exist(General.MsgPath+TempMemMsgArea1.FileName+'.SCN')) THEN
            BEGIN
              Assign(MsgAreaScanFile,General.MsgPath+TempMemMsgArea1.FileName+'.SCN');
              ReWrite(MsgAreaScanFile);
              Close(MsgAreaScanFile);
            END;
            IF (Exist(General.MsgPath+TempMemMsgArea1.FileName+'.SCN')) THEN
            BEGIN
              Assign(MsgAreaScanFile,General.MsgPath+TempMemMsgArea1.FileName+'.SCN');
              Reset(MsgAreaScanFile);
              WITH LastReadRecord DO
              BEGIN
                LastRead := 0;
                NewScan := TRUE;
              END;
              FOR RecNum1 := (FileSize(MsgAreaScanFile) + 1) TO (MaxUsers - 1) DO
                Write(MsgAreaScanFile,LastReadRecord);
              Close(MsgAreaScanFile);
            END;
            Seek(MsgAreaFile,RecNum);
            Write(MsgAreaFile,TempMemMsgArea1);
            Inc(NumMsgAreas);
            SysOpLog('* Inserted message area: ^5'+TempMemMsgArea1.Name);
          END;
        END;
        Close(MsgAreaFile);
        LastError := IOResult;
      END;
    END;
  END;

  PROCEDURE ModifyMsgArea(TempMemMsgArea1: MessageAreaRecordType; Cmd1: Char; RecNumToEdit: SmallInt);
  VAR
    User: UserRecordType;
    MsgAreaScanFile: FILE OF ScanRec;
    RecNum1,
    SaveRecNumToEdit: Integer;
    Ok,
    Changed: Boolean;
  BEGIN
    RecNumToEdit := -1;
    InputIntegerWOC('%LFModify which message area?',RecNumToEdit,[NumbersOnly],0,NumMsgAreas);
    IF ((RecNumToEdit >= 0) AND (RecNumToEdit <= NumMsgAreas)) THEN
    BEGIN
      SaveRecNumToEdit := -1;
      Cmd1 := #0;
      IF (RecNumToEdit = 0) THEN
      BEGIN
        Assign(EMailFile,General.DataPath+'MEMAIL.DAT');
        Reset(EmailFile);
      END
      ELSE
      BEGIN
        Assign(MsgAreaFile,General.DataPath+'MBASES.DAT');
        Reset(MsgAreaFile);
      END;
      WHILE (Cmd1 <> 'Q') AND (NOT HangUp) DO
      BEGIN
        IF (SaveRecNumToEdit <> RecNumToEdit) THEN
        BEGIN
          IF (RecNumToEdit = 0) THEN
          BEGIN
            Seek(EMailFile,0);
            Read(EMailFile,MemMsgArea);
          END
          ELSE
          BEGIN
            Seek(MsgAreaFile,(RecNumToEdit - 1));
            Read(MsgAreaFile,MemMsgArea);
          END;
          SaveRecNumToEdit := RecNumToEdit;
          Changed := FALSE;
        END;
        REPEAT
          Ok := TRUE;
          EditMessageArea(TempMemMsgArea1,MemMsgArea,Cmd1,RecNumToEdit,Changed,TRUE);
          CheckMessageArea(MemMsgArea,1,5,Ok);
          IF (NOT OK) THEN
          BEGIN
            PauseScr(FALSE);
            IF (RecNumToEdit <> SaveRecNumToEdit) THEN
              RecNumToEdit := SaveRecNumToEdit;
          END;
        UNTIL (Ok) OR (HangUp);
        IF (MemMsgArea.MAType IN [1,2]) THEN
          MakeDir(MemMsgArea.MsgPath,FALSE);
        IF (NOT Exist(General.MsgPath+MemMsgArea.FileName+'.HDR')) THEN
        BEGIN
          Assign(MsgHdrF,General.MsgPath+MemMsgArea.FileName+'.HDR');
          ReWrite(MsgHdrF);
          Close(MsgHdrF);
        END;
        IF (NOT Exist(General.MsgPath+MemMsgArea.FileName+'.DAT')) THEN
        BEGIN
          Assign(MsgTxtF,General.MsgPath+MemMsgArea.FileName+'.DAT');
          ReWrite(MsgTxtF,1);
          Close(MsgTxtF);
        END;
        IF (RecNumToEdit <> 0) THEN
        BEGIN
          IF (NOT Exist(General.MsgPath+MemMsgArea.FileName+'.SCN')) THEN
          BEGIN
            Assign(MsgAreaScanFile,General.MsgPath+MemMsgArea.FileName+'.SCN');
            ReWrite(MsgAreaScanFile);
            Close(MsgAreaScanFile);
          END;
          IF (Exist(General.MsgPath+MemMsgArea.FileName+'.SCN')) THEN
          BEGIN
            Assign(MsgAreaScanFile,General.MsgPath+MemMsgArea.FileName+'.SCN');
            Reset(MsgAreaScanFile);
            WITH LastReadRecord DO
            BEGIN
              LastRead := 0;
              NewScan := TRUE;
            END;
            Seek(MsgAreaScanFile,FileSize(MsgAreaScanFile));
            FOR RecNum1 := (FileSize(MsgAreaScanFile) + 1) TO (MaxUsers - 1) DO
              Write(MsgAreaScanFile,LastReadRecord);
            Reset(UserFile);
            FOR RecNum1 := 1 TO (MaxUsers - 1) DO
            BEGIN
              LoadURec(User,RecNum1);
              IF (Deleted IN User.SFlags) THEN
              BEGIN
                Seek(MsgAreaScanFile,(RecNum1 - 1));
                Write(MsgAreaScanFile,LastReadRecord);
              END;
            END;
            Close(UserFile);
            Close(MsgAreaScanFile);
          END;
        END;
        IF (Changed) THEN
        BEGIN
          IF (RecNumToEdit = 0) THEN
          BEGIN
            Seek(EMailFile,0);
            Write(EMailFile,MemMsgArea);
          END
          ELSE
          BEGIN
            Seek(MsgAreaFile,(SaveRecNumToEdit - 1));
            Write(MsgAreaFile,MemMsgArea);
          END;
          SysOpLog('* Modified message area: ^5'+MemMsgArea.Name);
        END;
      END;
      IF (RecNumToEdit = 0) THEN
        Close(EmailFile)
      ELSE
        Close(MsgAreaFile);
      LastError := IOResult;
    END;
  END;

  PROCEDURE PositionMsgArea(TempMemMsgArea1: MessageAreaRecordType; RecNumToPosition: SmallInt);
  VAR
    RecNumToPositionBefore,
    RecNum1,
    RecNum2: SmallInt;
  BEGIN
    IF (NumMsgAreas = 0) THEN
      Messages(4,0,'message areas')
    ELSE IF (NumMsgAreas = 1) THEN
      Messages(6,0,'message areas')
    ELSE
    BEGIN
      RecNumToPosition := -1;
      InputIntegerWOC('%LFPosition which message area?',RecNumToPosition,[NumbersOnly],1,NumMsgAreas);
      IF (RecNumToPosition >= 1) AND (RecNumToPosition <= NumMsgAreas) THEN
      BEGIN
        RecNumToPositionBefore := -1;
        Print('%LFAccording to the current numbering system.');
        InputIntegerWOC('%LFPosition before which message area?',RecNumToPositionBefore,[NumbersOnly],1,(NumMsgAreas + 1));
        IF (RecNumToPositionBefore >= 1) AND (RecNumToPositionBefore <= (NumMsgAreas + 1)) AND
           (RecNumToPositionBefore <> RecNumToPosition) AND (RecNumToPositionBefore <> (RecNumToPosition + 1)) THEN
        BEGIN
          Print('%LF[> Positioning message area records ...');
          IF (RecNumToPositionBefore > RecNumToPosition) THEN
            Dec(RecNumToPositionBefore);
          Dec(RecNumToPosition);
          Dec(RecNumToPositionBefore);
          Reset(MsgAreaFile);
          Seek(MsgAreaFile,RecNumToPosition);
          Read(MsgAreaFile,TempMemMsgArea1);
          RecNum1 := RecNumToPosition;
          IF (RecNumToPosition > RecNumToPositionBefore) THEN
            RecNum2 := -1
          ELSE
            RecNum2 := 1;
          WHILE (RecNum1 <> RecNumToPositionBefore) DO
          BEGIN
            IF ((RecNum1 + RecNum2) < FileSize(MsgAreaFile)) THEN
            BEGIN
              Seek(MsgAreaFile,(RecNum1 + RecNum2));
              Read(MsgAreaFile,MemMsgArea);
              Seek(MsgAreaFile,RecNum1);
              Write(MsgAreaFile,MemMsgArea);
            END;
            Inc(RecNum1,RecNum2);
          END;
          Seek(MsgAreaFile,RecNumToPositionBefore);
          Write(MsgAreaFile,TempMemMsgArea1);
          Close(MsgAreaFile);
          LastError := IOResult;
        END;
      END;
    END;
  END;

  PROCEDURE RenumberQWKIndex;
  VAR
    RecNum: Integer;
  BEGIN
    IF (NumMsgAreas = 0) THEN
      Messages(4,0,'message areas')
    ELSE
    BEGIN
      IF PYNQ('%LFRenumber QWK Index for all message areas? ',0,FALSE) THEN
      BEGIN
        Prompt('%LFRenumbering the QWK index''s for all areas ... ');
        Reset(MsgAreaFile);
        RecNum := 1;
        WHILE (RecNum <= NumMsgAreas) DO
        BEGIN
          Seek(MsgAreaFile,(RecNum - 1));
          Read(MsgAreaFile,MemMsgArea);
          MemMsgArea.QWKIndex := RecNum;
          Seek(MsgAreaFile,(RecNum - 1));
          Write(MsgAreaFile,MemMsgArea);
          Inc(RecNum);
        END;
        Close(MsgAreaFile);
        LastError := IOResult;
        Print('Done');
        SysOpLog('* Renumbered the QWK index for all message areas.');
      END;
    END;
  END;

  PROCEDURE DisplayMsgArea(RecNumToList1: Integer);
  BEGIN
    WITH MemMsgArea DO
      CASE DisplayType OF
        1 : PrintACR('^0'+PadRightInt(RecNumToList1,5)+
                     ' ^5'+PadLeftStr(Name,24)+
                     ' ^3'+Copy('LEGQ',(MAType + 1),1)+DisplayMAFlags(MAFlags,'5','4')+
                     ' ^9'+PadLeftStr(AOnOff(ACS = '','*None*',ACS),10)+
                     ' '+PadLeftStr(AOnOff(PostACS = '','*None*',PostACS),9)+
                     ' '+PadLeftStr(AOnOff(MCIACS = '','*None*',MCIACS),9)+
                     ' ^3'+PadLeftInt(MaxMsgs,6)+
                     ' '+AnonTypeChar(Anonymous));
        2 : PrintACR('^0'+PadRightInt(RecNumToList1,5)+
                     ' ^5'+PadLeftStr(Name,27)+
                     ' ^3'+PadLeftStr(AOnOff(MAType IN [0,3],'*None*',NodeStr(AKA)),11)+
                     ' '+PadLeftStr(AOnOff(MsgPath = '','*None*',MsgPath),33));
      END;
  END;

  PROCEDURE ListMsgAreas(VAR RecNumToList1: SmallInt);
  VAR
    NumDone: Integer;
  BEGIN
    IF (RecNumToList1 < 0) OR (RecNumToList1 > NumMsgAreas) THEN
      RecNumToList1 := 0;
    MCIAllowed := FALSE;
    Abort := FALSE;
    Next := FALSE;
    CLS;
    CASE DisplayType OF
      1 : BEGIN
            PrintACR('^0#####^4:^3Message area name       ^4:^3Flag   ^4:^3ACS       ^4:^3Post ACS ^4:^3MCI ACS'+
                     '  ^4:^3MaxM  ^4:^3A');
            PrintACR('^4=====:========================:=======:==========:=========:=========:======:=');
          END;
      2 : BEGIN
            PrintACR('^0#####^4:^3Message area name          ^4:^3Address    ^4:^3Message path');
            PrintACR('^4=====:===========================:===========:=================================');
          END;
    END;
    IF (RecNumToList1 = 0) THEN
    BEGIN
      NumDone := 0;
      Assign(EmailFile,General.DataPath+'MEMAIL.DAT');
      Reset(EMailFile);
      Seek(EmailFile,RecNumToList1);
      Read(EMailFile,MemMsgArea);
      DisplayMsgArea(RecNumToList1);
      Close(EmailFile);
      LastError := IOResult;
      RecNumToList := 1;
    END;
    Assign(MsgAreaFile,General.DataPath+'MBASES.DAT');
    Reset(MsgAreaFile);
    NumDone := 1;
    WHILE (NumDone < (PageLength - 5)) AND (RecNumToList1 >= 1) AND (RecNumToList1 <= NumMsgAreas)
          AND (NOT Abort) AND (NOT HangUp) DO
    BEGIN
      Seek(MsgAreaFile,(RecNumToList1 - 1));
      Read(MsgAreaFile,MemMsgArea);
      DisplayMsgArea(RecNumToList1);
      Inc(RecNumToList1);
      Inc(NumDone);
    END;
    Close(MsgAreaFile);
    LastError := IOResult;
    MCIAllowed := TRUE;
  END;

BEGIN
  SaveTempPause := TempPause;
  TempPause := FALSE;
  RecNumToList := 0;
  Cmd := #0;
  REPEAT
    IF (Cmd <> '?') THEN
      ListMsgAreas(RecNumToList);
    LOneK('%LFMessage area editor [^5?^4=^5Help^4]: ',Cmd,'QCDIMPRTX?'^M,TRUE,TRUE);
    CASE Cmd OF
      ^M  : IF (RecNumToList < 0) OR (RecNumToList > NumMsgAreas) THEN
              RecNumToList := 0;
      'C' : ChangeMsgAreaDrive(Cmd,RecNumToList);
      'D' : DeleteMsgArea(TempMemMsgArea,RecNumToList);
      'I' : InsertMsgArea(TempMemMsgArea,Cmd,RecNumToList);
      'M' : ModifyMsgArea(TempMemMsgArea,Cmd,RecNumToList);
      'P' : PositionMsgArea(TempMemMsgArea,RecNumToList);
      'R' : ReNumberQWKIndex;
      'T' : DisplayType := ((DisplayType MOD 2) + 1);
      'X' : BEGIN
              Assign(MsgAreaDefFile,General.DataPath+'MBASES.DEF');
              IF (Exist(General.DataPath+'MBASES.DEF')) THEN
              BEGIN
                Reset(MsgAreaDefFile);
                Seek(MsgAreaDefFile,0);
                Read(MsgAreaDefFile,MemMsgArea);
              END
              ELSE
              BEGIN
                ReWrite(MsgAreaDefFile);
                InitMsgAreaVars(MemMsgArea);
              END;
              RecNumToList := -1;
              EditMessageArea(TempMemMsgArea,MemMsgArea,Cmd,RecNumToList,Changed,FALSE);
              Seek(MsgAreaDefFile,0);
              Write(MsgAreaDefFile,MemMsgArea);
              Close(MsgAreaDefFile);
              Cmd := #0;
            END;
      '?' : BEGIN
              Print('%LF^1<^3CR^1>Next screen or redisplay current screen');
              Print('^1(^3?^1)Help/First message area');
              LCmds(22,3,'Change message storage drive','');
              LCmds(22,3,'Delete message area','Insert message area');
              LCmds(22,3,'Modify message area','Position message area');
              LCmds(22,3,'Quit','Renumber QWK index');
              LCmds(22,3,'Toggle display format','XDefault configuration');
            END;
    END;
    IF (Cmd <> ^M) THEN
      RecNumToList := 0;
  UNTIL (Cmd = 'Q') OR (HangUp);
  TempPause := SaveTempPause;
  NewComptables;
  IF ((MsgArea < 1) OR (MsgArea > NumMsgAreas)) THEN
    MsgArea := 1;
  ReadMsgArea := -1;
  LoadMsgArea(MsgArea);
  LastError := IOResult;
END;

END.

