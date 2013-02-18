{$IFDEF WIN32}
{$I DEFINES.INC}
{$ENDIF}

{$A+,B-,D+,E-,F+,I-,L+,N-,O+,R-,S+,V-}

UNIT SysOp1;

INTERFACE

PROCEDURE ProtocolEditor;

IMPLEMENTATION

USES
  Common;

PROCEDURE ProtocolEditor;
VAR
  TempProtocol: ProtocolRecordType;
  Cmd: Char;
  RecNumToList: Integer;
  SaveTempPause: Boolean;

  PROCEDURE ToggleXBFlag(XBFlagT: ProtocolFlagType; VAR XBFlags: PRFlagSet);
  BEGIN
    IF (XBFlagT IN XBFlags) THEN
      Exclude(XBFlags,XBFlagT)
    ELSE
      Include(XBFlags,XBFlagT);
  END;

  PROCEDURE ToggleXBFlags(C: Char; VAR XBFlags: PRFlagSet; VAR Changed: Boolean);
  VAR
    TempXBFlags: PRFlagSet;
  BEGIN
    TempXBFlags := XBFlags;
    CASE C OF
      '1' : ToggleXBFlag(ProtActive,XBFlags);
      '2' : ToggleXBFlag(ProtIsBatch,XBFlags);
      '3' : ToggleXBFlag(ProtIsResume,XBFlags);
      '4' : ToggleXBFlag(ProtBiDirectional,XBFlags);
      '5' : ToggleXBFlag(ProtReliable,XBFlags);
      '6' : ToggleXBFlag(ProtXferOkCode,XBFlags);
    END;
    IF (XBFlags <> TempXBFlags) THEN
      Changed := TRUE;
  END;

  PROCEDURE InitProtocolVars(VAR Protocol: ProtocolRecordType);
  VAR
    Counter: BYTE;
  BEGIN
    FillChar(Protocol,SizeOf(Protocol),0);
    WITH Protocol DO
    BEGIN
      PRFlags := [ProtXferOkCode];
      CKeys := '!';
      Description := '<< New Protocol >>';
      ACS := '';
      TempLog := '';
      DLoadLog := '';
      ULoadLog := '';
      DLCmd := '';
      ULCmd := '';
      FOR Counter := 1 TO 6 DO
      BEGIN
        DLCode[Counter] := '';
        ULCode[Counter] := '';
      END;
      EnvCmd := '';
      DLFList := '';
      MaxChrs := 127;
      TempLogPF := 0;
      TempLogPS := 0;
    END;
  END;

  PROCEDURE DeleteProtocol(TempProtocol1: ProtocolRecordType; RecNumToDelete: SmallInt);
  VAR
    RecNum: Integer;
  BEGIN
    IF (NumProtocols = 0) THEN
      Messages(4,0,'protocols')
    ELSE
    BEGIN
      RecNumToDelete := -1;
      InputIntegerWOC('%LFProtocol to delete?',RecNumToDelete,[NumbersOnly],1,NumProtocols);
      IF (RecNumToDelete >= 1) AND (RecNumToDelete <= NumProtocols) THEN
      BEGIN
        Reset(ProtocolFile);
        Seek(ProtocolFile,(RecNumToDelete - 1));
        Read(ProtocolFile,TempProtocol1);
        Close(ProtocolFile);
        LastError := IOResult;
        Print('%LFProtocol: ^5'+TempProtocol1.Description);
        IF PYNQ('%LFAre you sure you want to delete it? ',0,FALSE) THEN
        BEGIN
          Print('%LF[> Deleting protocol record ...');
          Dec(RecNumToDelete);
          Reset(ProtocolFile);
          IF (RecNumToDelete >= 0) AND (RecNumToDelete <= (FileSize(ProtocolFile) - 2)) THEN
            FOR RecNum := RecNumToDelete TO (FileSize(ProtocolFile) - 2) DO
            BEGIN
              Seek(ProtocolFile,(RecNum + 1));
              Read(ProtocolFile,Protocol);
              Seek(ProtocolFile,RecNum);
              Write(ProtocolFile,Protocol);
            END;
          Seek(ProtocolFile,(FileSize(ProtocolFile) - 1));
          Truncate(ProtocolFile);
          Close(ProtocolFile);
          LastError := IOResult;
          Dec(NumProtocols);
          SysOpLog('* Deleted Protocol: ^5'+TempProtocol1.Description);
        END;
      END;
    END;
  END;

  FUNCTION CmdOk(Protocol: ProtocolRecordType): Boolean;
  VAR
    Ok1: Boolean;
  BEGIN
    Ok1 := TRUE;
    WITH Protocol DO
      IF (DLCmd = 'ASCII') OR (DLCmd = 'BATCH') OR (DLCmd = 'EDIT') OR
         (DLCmd = 'NEXT') OR (DLCmd = 'QUIT') OR (ULCmd = 'ASCII') OR
         (ULCmd = 'BATCH') OR (ULCmd = 'EDIT') OR (ULCmd = 'NEXT') OR
         (ULCmd = 'QUIT') THEN
      OK1 := FALSE;
    CmdOk := Ok1;
  END;

  FUNCTION DLCodesEmpty(Protocol: ProtocolRecordType): Boolean;
  VAR
    Counter1: Byte;
  BEGIN
    DLCodesEmpty := TRUE;
    FOR Counter1 := 1 TO 6 DO
      IF (Protocol.DLCode[Counter1] <> '') THEN
        DLCodesEmpty := FALSE;
  END;

  FUNCTION ULCodesEmpty(Protocol: ProtocolRecordType): Boolean;
  VAR
    Counter1: Byte;
  BEGIN
    ULCodesEmpty := TRUE;
    FOR Counter1 := 1 TO 6 DO
      IF (Protocol.ULCode[Counter1] <> '') THEN
        ULCodesEmpty := FALSE;
  END;

  PROCEDURE CheckProtocol(Protocol: ProtocolRecordType; StartErrMsg,EndErrMsg: Byte; VAR Ok: Boolean);
  VAR
    Counter: Byte;
  BEGIN
    FOR Counter := StartErrMsg TO EndErrMsg DO
      CASE Counter OF
        1 : IF (Protocol.Ckeys = '') THEN
            BEGIN
              Print('%LF^7The command keys are invalid!^1');
              Ok := FALSE;
            END;
        2 : IF (Protocol.Description = '<< New Protocol >>') THEN
            BEGIN
              Print('%LF^7The description is invalid!^1');
              Ok := FALSE;
            END;
        3 : IF (CmdOk(Protocol)) AND (ProtIsBatch IN Protocol.PRFLags) AND (Protocol.TempLog <> '') AND
               (Protocol.TempLogPF = 0) THEN
            BEGIN
              Print('%LF^7You must specify the file name position if you utilize the Temp Log.^1');
              Ok := FALSE;
            END;
        4 : IF (CmdOk(Protocol)) AND (ProtIsBatch IN Protocol.PRFLags) AND (Protocol.TempLog <> '') AND
              (Protocol.TempLogPS = 0) THEN
            BEGIN
              Print('%LF^7You must specify the status position if you utilize the Temp Log.');
              Ok := FALSE;
            END;
        5 : IF (CmdOk(Protocol)) AND (ProtIsBatch IN Protocol.PRFLags) AND (Protocol.TempLog <> '') AND
              (DLCodesEmpty(Protocol)) THEN
            BEGIN
              Print('%LF^7You must specify <D>L codes if you utilize the Temp. Log.^1');
              Ok := FALSE;
            END;
        6 : IF (CMDOk(Protocol)) AND (ProtIsBatch IN Protocol.PRFlags) AND (Protocol.DLoadLog <> '') AND
               (Protocol.TempLog = '') THEN
            BEGIN
              Print('%LF^7You must specify a Temp. Log if you utilize the <D>L Log.^1');
              Ok := FALSE;
            END;
        7 : IF (CmdOk(Protocol)) AND (NOT (ProtIsBatch IN Protocol.PRFlags)) AND (Protocol.ULCmd <> '') AND
               (ULCodesEmpty(Protocol)) THEN
            BEGIN
              Print('%LF^7You must specify <U>L Codes if you utilize the <U>L Command.^1');
              Ok := FALSE;
            END;
        8 : IF (CmdOk(Protocol)) AND (NOT (ProtIsBatch IN Protocol.PRFlags)) AND (Protocol.DLCmd <> '') AND
               (DLCodesEmpty(Protocol)) THEN
            BEGIN
              Print('%LF^7You must specify <D>L Codes if you utilize the <D>L Command.^1');
              Ok := FALSE;
            END;
        9 : IF (CmdOk(Protocol)) AND (ProtIsBatch IN Protocol.PRFlags) AND (Protocol.DLCmd <> '') AND
               (Protocol.DLFList = '') THEN
            BEGIN
              Print('%LF^7You must specify a DL File List if you utilize the <D>L Command.^1');
              Ok := FALSE;
            END;
       10 : IF (CmdOk(Protocol)) AND (ProtIsBatch IN Protocol.PRFlags) AND (Protocol.DLCmd <> '') AND
               (Protocol.MaxChrs = 0) THEN
            BEGIN
              Print('%LF^7You must specify the Max DOS Chars if you utilize the <D>L Command.^1');
              Ok := FALSE;
            END;
       11 : IF (Protocol.ULCmd = '') AND (Protocol.DLCmd = '') THEN
            BEGIN
              Print('%LF^7You must specify a <U>L or <D>L Command.^1');
              Ok := FALSE;
            END;
       12 : IF (CmdOk(Protocol)) AND (NOT (ProtIsBatch IN Protocol.PRFlags)) AND (Protocol.DLCmd = '') AND
              (NOT DLCodesEmpty(Protocol)) THEN
            BEGIN
              Print('%LF^7You must specify a <D>L Command if you utilize <D>L Codes.^1');
              Ok := FALSE;
            END;
       13 : IF (CmdOk(Protocol)) AND (NOT (ProtIsBatch IN Protocol.PRFlags)) AND (Protocol.ULCmd = '') AND
              (NOT ULCodesEmpty(Protocol)) THEN
            BEGIN
              Print('%LF^7You must specify a <U>L Command if you utilize <U>L Codes.^1');
              Ok := FALSE;
            END;
       14 : IF (CmdOk(Protocol)) AND (ProtIsBatch IN Protocol.PRFlags) AND (Protocol.TempLog = '') AND
              (NOT DLCodesEmpty(Protocol)) THEN
            BEGIN
              Print('%LF^7You must specify a Temp Log if you utilize <D>L Codes.^1');
              Ok := FALSE;
            END;
      END;
  END;

  PROCEDURE EditProtocol(TempProtocol1: ProtocolRecordType; VAR Protocol: ProtocolRecordType; VAR Cmd1: Char;
                         VAR RecNumToEdit: SmallInt; VAR Changed: Boolean; Editing: Boolean);
  VAR
    TempStr,
    CmdStr: AStr;
    Cmd2: Char;
    Counter: Byte;
    OK: Boolean;
  BEGIN
    WITH Protocol DO
      REPEAT
        IF (Cmd1 <> '?') THEN
        BEGIN
          MCIAllowed := FALSE;
          Abort := FALSE;
          Next := FALSE;
          CLS;
          IF (Editing) THEN
            PrintACR('^5Editing protocol #'+IntToStr(RecNumToEdit)+' of '+IntToStr(NumProtocols))
          ELSE
            PrintACR('^5Inserting protocol #'+IntToStr(RecNumToEdit)+' of '+IntToStr(NumProtocols + 1));
          NL;
          PrintACR('^1!. Type/protocl: ^5'+
                   AOnOff(ProtActive IN PRFlags,'Active','INACTIVE')+' - '+
                   AOnOff(ProtIsBatch IN PRFlags,'Batch','Single')+
                   AOnOff(ProtIsResume IN PRFlags,' - Resume','')+
                   AOnOff(ProtBiDirectional IN PRFlags,' - Bidirectional','')+
                   AOnOff(ProtReliable IN PRFlags,' - Reliable only',''));
          PrintACR('^11. Keys/descrip: ^5'+CKeys+'^1 / ^5'+AOnOff(Description = '','*None*',Description)+'^1');
          PrintACR('^12. ACS required: ^5'+AOnOff(ACS = '','*None*',ACS)+'^1');
          IF (CmdOk(Protocol)) AND (ProtIsBatch IN PRFLags) THEN
          BEGIN
            PrintACR('^13. Temp. log   : ^5'+AOnOff(TempLog = '','*None*',TempLog));
            IF (Protocol.TempLog <> '') THEN
              PrintACR('^1               : File name position: ^5'+IntToStr(TempLogPF)+
                       ' ^1/ Status position: ^5'+IntToStr(TempLogPS));
          END;
          IF (CmdOk(Protocol)) AND (ProtIsBatch IN PRFLags) THEN
          BEGIN
            PrintACR('^14. <U>L log    : ^5'+AOnOff(ULoadLog = '','*None*',ULoadLog));
            PrintACR('^1   <D>L log    : ^5'+AOnOff(DLoadLog = '','*None*',DLoadLog));
          END;
          PrintACR('^15. <U>L command: ^5'+AOnOff(ULCmd = '','*None*',ULCmd));
          PrintACR('^1   <D>L command: ^5'+AOnOff(DLCmd = '','*None*',DLCmd));
          IF (ProtIsBatch IN PRFLags) AND (CMDOk(Protocol)) AND (Protocol.DLCmd <> '') THEN
            PrintACR('^1               : DL File List: ^5'+AOnOff(DLFList = '','*None*',DLFList)+
                     ' ^1/ Max DOS chars: ^5'+IntToStr(MaxChrs));
          IF (CmdOk(Protocol)) THEN
            PrintACR('^16. Codes mean  : ^5'+AOnOff(ProtXferOkCode IN PRFlags,'Transfer Successful','Transfer Failed'));
          IF (CmdOk(Protocol)) THEN
          BEGIN
            TempStr := '^17. <U>L codes  :';
            FOR Counter := 1 TO 3 DO
              TempStr := TempStr + PadLeftStr('^1 ('+IntToStr(Counter)+') "^5'+ULCode[Counter]+'^1" ',13);
            PrintACR(TempStr);
            TempStr := '^1               :';
            FOR Counter := 4 TO 6 DO
              TempStr := TempStr + PadLeftStr('^1 ('+IntToStr(Counter)+') "^5'+ULCode[Counter]+'^1" ',13);
            PrintACR(TempStr);
            TempStr := '^1   <D>L codes  :';
            FOR Counter := 1 TO 3 DO
              TempStr := TempStr + PadLeftStr('^1 ('+IntToStr(Counter)+') "^5'+DLCode[Counter]+'^1" ',13);
            PrintACR(TempStr);
            TempStr := '^1               :';
            FOR Counter := 4 TO 6 DO
              TempStr := TempStr + PadLeftStr('^1 ('+IntToStr(Counter)+') "^5'+DLCode[Counter]+'^1" ',13);
            PrintACR(TempStr);
          END;
          IF (CmdOk(Protocol)) THEN
            PrintACR('^18. Environ. cmd: ^5'+AOnOff(EnvCmd = '','*None*',EnvCmd));
          MCIAllowed := TRUE;
        END;
        IF (NOT Editing) THEN
          CmdStr := '!12345678'
        ELSE
          CmdStr := '!12345678[]FJL';
        LOneK('%LFModify menu [^5?^4=^5Help^4]: ',Cmd1,'Q?'+CmdStr+^M,TRUE,TRUE);
        CASE Cmd1 OF
          '!' : BEGIN
                  REPEAT
                    Print('%LF^5Protocol types:^1');
                    Print('%LF^11. Protocol active   : ^5'+ShowYesNo(ProtActive IN PRFlags));
                    Print('^12. Is batch protocol : ^5'+ShowYesNo(ProtIsBatch IN PRFlags));
                    Print('^13. Is resume protocol: ^5'+ShowYesNo(ProtIsResume IN PRFlags));
                    Print('^14. Is bidirectional  : ^5'+ShowYesNo(ProtBiDirectional IN PRFlags));
                    Print('^15. For reliable only : ^5'+ShowYesNo(ProtReliable IN PRFlags));
                    LOneK('%LFNew protocol type? [^51^4-^55^4,^5<CR>^4=^5Quit^4]: ',Cmd1,^M'12345',TRUE,TRUE);
                    IF (Cmd1 IN ['1'..'5']) THEN
                      ToggleXBFlags(Cmd1,PRFlags,Changed);
                  UNTIL (Cmd1 = ^M) OR (HangUp);
                  Cmd1 := #0;
                END;
          '1' : BEGIN
                  REPEAT
                    Ok := TRUE;
                    TempProtocol1.Ckeys := CKeys;
                    InputWN1('%LFNew command keys: ',CKeys,(SizeOf(Ckeys) - 1),[InterActiveEdit],Changed);
                    CheckProtocol(Protocol,1,1,Ok);
                    IF (NOT Ok) THEN
                      Ckeys := TempProtocol1.Ckeys;
                  UNTIL (Ok) OR (HangUp);
                  REPEAT
                    Ok := TRUE;
                    TempProtocol1.Description := Description;
                    InputWNWC('%LFNew description: ',Description,(SizeOf(Description) - 1),Changed);
                    CheckProtocol(Protocol,2,2,Ok);
                    IF (NOT Ok) THEN
                      Description := TempProtocol1.Description;
                  UNTIL (Ok) OR (HangUp);
                END;
          '2' : InputWN1('%LFNew ACS: ',ACS,(SizeOf(ACS) - 1),[InterActiveEdit],Changed);
          '3' : IF (CmdOk(Protocol)) AND (ProtIsBatch IN PRFlags) THEN
                BEGIN
                  Print('%LFIf you specify a Temporary Log file, you must also');
                  Print('specify the "File Name" position, "Status" position and');
                  Print('the corresponding Batch <D>L Codes.');
                  InputWN1('%LFNew temporary log: ',TempLog,(SizeOf(TempLog) - 1),[InterActiveEdit],Changed);
                  IF (Protocol.TempLog = '') THEN
                  BEGIN
                    Protocol.TempLogPF := 0;
                    Protocol.TempLogPS := 0;
                  END;
                  IF (ProtIsBatch IN PRFLags) AND (CMDOk(Protocol)) AND (Protocol.TempLog <> '') THEN
                  BEGIN
                    REPEAT
                      Ok := TRUE;
                      TempProtocol1.TempLogPF := TempLogPF;
                      InputByteWC('%LFNew file name log position',TempLogPF,[DisplayValue,NumbersOnly],0,127,Changed);
                      CheckProtocol(Protocol,3,3,Ok);
                      IF (NOT Ok) THEN
                        TempLogPF := TempProtocol1.TempLogPF;
                    UNTIL (Ok) OR (HangUp);
                    REPEAT
                      Ok := TRUE;
                      TempProtocol1.TempLogPS := TempLogPS;
                      InputByteWC('%LFNew status log position',TempLogPS,[DisplayValue,NumbersOnly],0,127,Changed);
                      CheckProtocol(Protocol,4,4,Ok);
                      IF (NOT Ok) THEN
                        TempLogPS := TempProtocol1.TempLogPS;
                    UNTIL (Ok) OR (HangUp);
                  END;
                END;
          '4' : IF (CmdOk(Protocol)) AND (ProtIsBatch IN PRFlags) THEN
                BEGIN
                  LOneK('%LFFile transfer type? [^5U^4=^5Upload^4,^5D^4=^5Download^4,^5<CR>^4=^5Quit^4]: ',
                        Cmd1,^M'UD',TRUE,TRUE);
                  CASE Cmd1 OF
                    'U' : BEGIN
                            Print('%LF^7The permanent batch upload log is not utilized by Renegade!^1');
                            PauseScr(FALSE);
                          END;
                    'D' : BEGIN
                            Print('%LFIf you specify a permanent batch download log, you must also');
                            Print('specify a temporary log.');
                            InputWN1('%LFNew permanent download log: ',DLoadLog,(SizeOf(DloadLog) - 1),
                                     [InterActiveEdit],Changed);
                          END;
                  END;
                  Cmd1 := #0;
                END;
          '5' : BEGIN
                  TempStr := #0;
                  LOneK('%LFFile transfer type? [^5U^4=^5Upload^4,^5D^4=^5Download^4,^5<CR>^4=^5Quit^4]: ',
                        Cmd1,^M'UD',TRUE,TRUE);
                  IF (Cmd1 <> ^M) THEN
                  BEGIN
                    LOneK('%LFFile transfer method? [^5E^4=^5External^4,^5I^4=^5Internal^4,^5O^4=^5Off^4,^5<CR>^4=^5Quit^4]: ',
                          Cmd2,^M'EIO',TRUE,TRUE);
                    CASE Cmd2 OF
                      'E' : CASE Cmd1 OF
                              'U' : BEGIN
                                      TempStr := ULCmd;
                                      IF (CmdOk(Protocol)) AND (NOT (ProtIsBatch IN PRFlags)) THEN
                                      BEGIN
                                        Print('%LFIf you specify an external single upload protocol, you must also');
                                        Print('specify single upload <U>L codes.');
                                      END;
                                      InputWN1('%LF^1New external upload protocol:%LF^4: ',TempStr,(SizeOf(DlCmd) - 1),
                                               [InterActiveEdit],Changed);
                                    END;
                              'D' : BEGIN
                                      TempStr := DLCmd;
                                      IF (CmdOk(Protocol)) THEN
                                        IF (ProtIsBatch IN PRFlags) THEN
                                        BEGIN
                                          Print('%LFIf you specify an external batch download protocol, you must');
                                          Print('also specify a batch file list and the maximum DOS characters');
                                          Print('allowed on the DOS commandline.');
                                        END
                                        ELSE
                                        BEGIN
                                          Print('%LFIf you specify an external single download protocol, you must also');
                                          Print('specify single download <D>L codes.');
                                        END;
                                      InputWN1('%LF^1New external download protocol:%LF^4: ',TempStr,(SizeOf(DlCmd) - 1),
                                               [InterActiveEdit],Changed);
                                      IF (TempStr = '') THEN
                                      BEGIN
                                        Protocol.DLFList := '';
                                        Protocol.MaxChrs := 127;
                                      END;
                                      IF (CmdOk(Protocol)) AND (ProtIsBatch IN PRFlags) AND (TempStr <> '') THEN
                                      BEGIN
                                        REPEAT
                                          Ok := TRUE;
                                          TempProtocol1.DLFList := DLFList;
                                          InputWN1('%LFNew batch file list: ',DLFList,(SizeOf(DLFList) - 1),
                                                   [InterActiveEdit],Changed);
                                          CheckProtocol(Protocol,9,9,Ok);
                                          IF (NOT Ok) THEN
                                            DLFList := TempProtocol1.DLFList;
                                        UNTIL (Ok) OR (HangUp);
                                        REPEAT
                                          Ok := TRUE;
                                          TempProtocol1.MaxChrs := MaxChrs;
                                          InputByteWC('%LFNew max DOS characters in commandline',MaxChrs,
                                                      [DisplayValue,NumbersOnly],0,127,Changed);
                                          CheckProtocol(Protocol,10,10,Ok);
                                          IF (NOT Ok) THEN
                                            MaxChrs := TempProtocol1.MaxChrs;
                                        UNTIL (Ok) OR (HangUp);
                                      END;
                                    END;
                            END;
                      'I' : BEGIN
                              Print('%LF^5Internal protocol types:^1');
                              NL;
                              LCmds(40,3,'ASCII','');
                              LCmds(40,3,'BATCH','');
                              LCmds(40,3,'EDIT','');
                              LCmds(40,3,'NEXT','');
                              LCmds(40,3,'QUIT','');
                              LOneK('%LFNew internal protocol? [^5A^4,^5B^4,^5E^4,^5N^4,^5Q^4,^5<CR>^4=^5Quit^4]: ',
                                    Cmd2,^M'ABENQ',TRUE,TRUE);
                              IF (Cmd2 <> ^M) THEN
                                CASE Cmd2 OF
                                  'A' : TempStr := 'ASCII';
                                  'B' : TempStr := 'BATCH';
                                  'E' : TempStr := 'EDIT';
                                  'N' : TempStr := 'NEXT';
                                  'Q' : TempStr := 'QUIT';
                                END;
                              IF (Cmd2 <> ^M) THEN
                                Changed := TRUE;
                              Cmd2 := #0;
                            END;
                      'O' : IF PYNQ('%LFSet to NULL string? ',0,FALSE) THEN
                            BEGIN
                              TempStr := '';
                              Changed := TRUE;
                            END;
                    END;
                    IF (TempStr <> #0) THEN
                      CASE Cmd1 OF
                        'D' : DLCmd := TempStr;
                        'U' : ULCmd := TempStr;
                      END;
                    IF (NOT CmdOk(Protocol)) THEN
                    BEGIN
                      TempLog := '';
                      ULoadLog := '';
                      DLoadLog := '';
                      FOR Counter := 1 TO 6 DO
                      BEGIN
                        ULCode[Counter] := '';
                        DLCode[Counter] := '';
                      END;
                      EnvCmd := '';
                      DLFList := '';
                      MaxChrs := 127;
                      TempLogPF := 0;
                      TempLogPS := 0;
                    END;
                  END;
                  Cmd1 := #0;
                  Cmd2 := #0;
                END;
          '6' : IF (CmdOk(Protocol)) THEN
                  ToggleXBFlags('6',PRFlags,Changed);
          '7' : IF (CmdOk(Protocol)) THEN
                BEGIN
                  LOneK('%LFFile transfer type? [^5U^4=^5Upload^4,^5D^4=^5Download^4,^5<CR>^4=^5Quit^4]: ',
                        Cmd1,'UD'^M,TRUE,TRUE);
                  CASE Cmd1 OF
                    'U' : BEGIN
                            IF (ProtIsBatch IN PRFlags) THEN
                            BEGIN
                              Print('%LF^7The batch upload codes are not utilized by Renegade!^1');
                              PauseScr(FALSE);
                            END
                            ELSE
                            BEGIN
                              Print('%LF^5New upload codes:^1');
                              FOR Counter := 1 TO 6 DO
                                InputWN1('%LFCode #'+IntToStr(Counter)+': ',ULCode[Counter],
                                         (SizeOf(ULCode[Counter]) - 1),[InterActiveEdit],Changed);
                            END;
                          END;
                    'D' : BEGIN
                            Print('%LF^5New download codes:^1');
                            FOR Counter := 1 TO 6 DO
                              InputWN1('%LFCode #'+IntToStr(Counter)+': ',DLCode[Counter],
                                       (SizeOf(DlCode[Counter]) - 1),[InterActiveEdit],Changed);
                          END;
                  END;
                  Cmd1 := #0;
                END;
          '8' : IF (CmdOk(Protocol)) THEN
                  InputWN1('%LFNew environment setup commandline:%LF: ',EnvCmd,(SizeOf(EnvCmd) - 1),[InterActiveEdit],Changed);
          '[' : IF (RecNumToEdit > 1) THEN
                  Dec(RecNumToEdit)
                ELSE
                BEGIN
                  Messages(2,0,'');
                  Cmd1 := #0;
                END;
          ']' : IF (RecNumToEdit < NumProtocols) THEN
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
                  InputIntegerWOC('%LFJump to entry?',RecNumToEdit,[NumbersOnly],1,NumProtocols);
                  IF (RecNumToEdit < 1) OR (RecNumToEdit > NumProtocols) THEN
                    Cmd1 := #0;
                END;
          'L' : IF (RecNumToEdit <> NumProtocols) THEN
                  RecNumToEdit := NumProtocols
                ELSE
                BEGIN
                  Messages(3,0,'');
                  Cmd1 := #0;
                END;
          '?' : BEGIN
                  Print('%LF^1<^3CR^1>Redisplay current screen');
                  Print('^31^1-^38^1:Modify item');
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

  PROCEDURE InsertProtocol(TempProtocol1: ProtocolRecordType; RecNumToInsertBefore: SmallInt);
  VAR
    Cmd1: Char;
    RecNum,
    RecNumToEdit: SmallInt;
    Ok,
    Changed: Boolean;
  BEGIN
    IF (NumProtocols = MaxProtocols) THEN
      Messages(5,MaxProtocols,'protocols')
    ELSE
    BEGIN
      RecNumToInsertBefore := -1;
      InputIntegerWOC('%LFProtocol to insert before?',RecNumToInsertBefore,[NumbersOnly],1,(NumProtocols + 1));
      IF (RecNumToInsertBefore >= 1) AND (RecNumToInsertBefore <= (NumProtocols + 1)) THEN
      BEGIN
        Reset(ProtocolFile);
        InitProtocolVars(TempProtocol1);
        IF (RecNumToInsertBefore = 1) THEN
          RecNumToEdit := 1
        ELSE IF (RecNumToInsertBefore = (NumProtocols + 1)) THEN
          RecNumToEdit := (NumProtocols + 1)
        ELSE
          RecNumToEdit := RecNumToInsertBefore;
        REPEAT
          OK := TRUE;
          EditProtocol(TempProtocol1,TempProtocol1,Cmd1,RecNumToEdit,Changed,FALSE);
          CheckProtocol(TempProtocol1,1,14,Ok);
          IF (NOT OK) THEN
            IF (NOT PYNQ('%LFContinue inserting protocol? ',0,TRUE)) THEN
              Abort := TRUE;
        UNTIL (OK) OR (Abort) OR (HangUp);
        IF (NOT Abort) AND (PYNQ('%LFIs this what you want? ',0,FALSE)) THEN
        BEGIN
          Print('%LF[> Inserting protocol record ...');
          Seek(ProtocolFile,FileSize(ProtocolFile));
          Write(ProtocolFile,Protocol);
          Dec(RecNumToInsertBefore);
          FOR RecNum := ((FileSize(ProtocolFile) - 1) - 1) DOWNTO RecNumToInsertBefore DO
          BEGIN
            Seek(ProtocolFile,RecNum);
            Read(ProtocolFile,Protocol);
            Seek(ProtocolFile,(RecNum + 1));
            Write(ProtocolFile,Protocol);
          END;
          FOR RecNum := RecNumToInsertBefore TO ((RecNumToInsertBefore + 1) - 1) DO
          BEGIN
            Seek(ProtocolFile,RecNum);
            Write(ProtocolFile,TempProtocol1);
            Inc(NumProtocols);
            SysOpLog('* Inserted protocol: ^5'+TempProtocol1.Description);
          END;
          Close(ProtocolFile);
          LastError := IOResult;
        END;
      END;
    END;
  END;

  PROCEDURE ModifyProtocol(TempProtocol1: ProtocolRecordType; Cmd1: Char; RecNumToEdit: SmallInt);
  VAR
    SaveRecNumToEdit: Integer;
    Ok,
    Changed: Boolean;
  BEGIN
    IF (NumProtocols = 0) THEN
      Messages(4,0,'protocols')
    ELSE
    BEGIN
      RecNumToEdit := -1;
      InputIntegerWOC('%LFProtocol to modify?',RecNumToEdit,[NumbersOnly],1,NumProtocols);
      IF (RecNumToEdit >= 1) AND (RecNumToEdit <= NumProtocols) THEN
      BEGIN
        SaveRecNumToEdit := -1;
        Cmd1 := #0;
        Reset(ProtocolFile);
        WHILE (Cmd1 <> 'Q') AND (NOT HangUp) DO
        BEGIN
          IF (SaveRecNumToEdit <> RecNumToEdit) THEN
          BEGIN
            Seek(ProtocolFile,(RecNumToEdit - 1));
            Read(ProtocolFile,Protocol);
            SaveRecNumToEdit := RecNumToEdit;
            Changed := FALSE;
          END;
          REPEAT
            Ok := TRUE;
            EditProtocol(TempProtocol1,Protocol,Cmd1,RecNumToEdit,Changed,TRUE);
            CheckProtocol(Protocol,1,14,Ok);
            IF (NOT OK) THEN
            BEGIN
              PauseScr(FALSE);
              IF (RecNumToEdit <> SaveRecNumToEdit) THEN
                RecNumToEdit := SaveRecNumToEdit;
            END;
          UNTIL (OK) OR (HangUp);
          IF (Changed) THEN
          BEGIN
            Seek(ProtocolFile,(SaveRecNumToEdit - 1));
            Write(ProtocolFile,Protocol);
            Changed := FALSE;
            SysOpLog('* Modified protocol: ^5'+Protocol.Description);
          END;
        END;
        Close(ProtocolFile);
        LastError := IOResult;
      END;
    END;
  END;

  PROCEDURE PositionProtocol(TempProtocol1: ProtocolRecordType; RecNumToPosition: SmallInt);
  VAR
    RecNumToPositionBefore,
    RecNum1,
    RecNum2: SmallInt;
  BEGIN
    IF (NumProtocols = 0) THEN
      Messages(4,0,'protocols')
    ELSE IF (NumProtocols = 1) THEN
      Messages(6,0,'protocols')
    ELSE
    BEGIN
      RecNumToPosition := -1;
      InputIntegerWOC('%LFPosition which protocol?',RecNumToPosition,[NumbersOnly],1,NumProtocols);
      IF (RecNumToPosition >= 1) AND (RecNumToPosition <= NumProtocols) THEN
      BEGIN
        RecNumToPositionBefore := -1;
        Print('%LFAccording to the current numbering system.');
        InputIntegerWOC('%LFPosition before which protocol?',RecNumToPositionBefore,[NumbersOnly],1,(NumProtocols + 1));
        IF (RecNumToPositionBefore >= 1) AND (RecNumToPositionBefore <= (NumProtocols + 1)) AND
           (RecNumToPositionBefore <> RecNumToPosition) AND (RecNumToPositionBefore <> (RecNumToPosition + 1)) THEN
        BEGIN
          Print('%LF[> Positioning protocol records ...');
          IF (RecNumToPositionBefore > RecNumToPosition) THEN
            Dec(RecNumToPositionBefore);
          Dec(RecNumToPosition);
          Dec(RecNumToPositionBefore);
          Reset(ProtocolFile);
          Seek(ProtocolFile,RecNumToPosition);
          Read(ProtocolFile,TempProtocol1);
          RecNum1 := RecNumToPosition;
          IF (RecNumToPosition > RecNumToPositionBefore) THEN
            RecNum2 := -1
          ELSE
            RecNum2 := 1;
          WHILE (RecNum1 <> RecNumToPositionBefore) DO
          BEGIN
            IF ((RecNum1 + RecNum2) < FileSize(ProtocolFile)) THEN
            BEGIN
              Seek(ProtocolFile,(RecNum1 + RecNum2));
              Read(ProtocolFile,Protocol);
              Seek(ProtocolFile,RecNum1);
              Write(ProtocolFile,Protocol);
            END;
            Inc(RecNum1,RecNum2);
          END;
          Seek(ProtocolFile,RecNumToPositionBefore);
          Write(ProtocolFile,TempProtocol1);
          Close(ProtocolFile);
          LastError := IOResult;
        END;
      END;
    END;
  END;

  PROCEDURE ListProtocols(VAR RecNumToList1: Integer);
  VAR
    NumDone: Integer;
  BEGIN
    IF (RecNumToList1 < 1) OR (RecNumToList1 > NumProtocols) THEN
      RecNumToList1 := 1;
    Abort := FALSE;
    Next := FALSE;
    CLS;
    PrintACR('^0 ###^4:^3ACS       ^4:^3Description');
    PrintACR('^4 ===:==========:=============================================================');
    Reset(ProtocolFile);
    NumDone := 0;
    WHILE (NumDone < (PageLength - 5)) AND (RecNumToList1 >= 1) AND (RecNumToList1 <= NumProtocols)
          AND (NOT Abort) AND (NOT HangUp) DO
    BEGIN
      Seek(ProtocolFile,(RecNumToList1 - 1));
      Read(ProtocolFile,Protocol);
      WITH Protocol DO
        PrintACR(AOnOff((ProtActive IN PRFlags),'^5+','^1-')+
                 '^0'+PadRightInt(RecNumToList1,3)+
                 ' ^9'+PadLeftStr(ACS,10)+
                 ' ^1'+Description);
      Inc(RecNumToList1);
      Inc(Numdone);
    END;
    Close(ProtocolFile);
    LastError := IOResult;
    IF (NumProtocols = 0) THEN
      Print('*** No protocols defined ***');
  END;

BEGIN
  SaveTempPause := TempPause;
  TempPause := FALSE;
  RecNumToList := 1;
  Cmd := #0;
  REPEAT
    IF (Cmd <> '?') THEN
      ListProtocols(RecNumToList);
    LOneK('%LFProtocol editor [^5?^4=^5Help^4]: ',Cmd,'QDIMP?'^M,TRUE,TRUE);
    CASE Cmd OF
      ^M  : IF (RecNumToList < 1) OR (RecNumToList > NumProtocols) THEN
              RecNumToList := 1;
      'D' : DeleteProtocol(TempProtocol,RecNumToList);
      'I' : InsertProtocol(TempProtocol,RecNumToList);
      'M' : ModifyProtocol(TempProtocol,Cmd,RecNumToList);
      'P' : PositionProtocol(TempProtocol,RecNumToList);
      '?' : BEGIN
              Print('%LF^1<^3CR^1>Next screen or redisplay current screen');
              Print('^1(^3?^1)Help/First protocol');
              LCmds(16,3,'Delete protocol','Insert protocol');
              LCmds(16,3,'Modify protocol','Position protocol');
              LCmds(16,3,'Quit','');
            END;
    END;
    IF (Cmd <> ^M) THEN
      RecNumToList := 1;
  UNTIL (Cmd = 'Q') OR (HangUp);
  TempPause := SaveTempPause;
  LastError := IOResult;
END;

END.
