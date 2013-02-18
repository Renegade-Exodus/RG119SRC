{$IFDEF WIN32}
{$I DEFINES.INC}
{$ENDIF}

{$A+,B-,D+,E-,F+,I-,L+,N-,O+,R-,S+,V-}

UNIT SysOp5;

INTERFACE

PROCEDURE HistoryEditor;

IMPLEMENTATION

USES
  Common,
  TimeFunc;

PROCEDURE HistoryEditor;
CONST
  MaxHistoryDates = 32767;
VAR
  HistoryFile: FILE OF HistoryRecordType;
  History: HistoryRecordType;
  TempHistory: HistoryRecordType;
  Cmd: Char;
  RecNumToList,
  NumHistoryDates: Integer;
  SaveTempPause: Boolean;

  PROCEDURE InitHistoryVars(VAR History: HistoryRecordType);
  VAR
    Counter: Byte;
  BEGIN
    FillChar(History,SizeOf(History),0);
    WITH History DO
    BEGIN
      Date := 0;
      FOR Counter := 0 TO 20 DO
        UserBaud[Counter] := 0;
      Active := 0;
      Callers := 0;
      NewUsers := 0;
      Posts := 0;
      EMail := 0;
      FeedBack := 0;
      Errors := 0;
      Uploads := 0;
      Downloads := 0;
      UK := 0;
      Dk := 0;
    END;
  END;

  PROCEDURE LocateHistoryDate(DisplayStr: AStr; TempHistory1: HistoryRecordType; VAR DateToLocate: Str10;
                              VAR RecNum1: SmallInt; ShowErr,Searching: Boolean);
  VAR
    RecNum: Integer;
  BEGIN
    RecNum1 := -1;
    InputFormatted(DisplayStr,DateToLocate,'##-##-####',TRUE);
    IF (DateToLocate <> '') AND (Length(DateToLocate) = 10) THEN
    BEGIN
      IF (Searching) THEN
        Reset(HistoryFile);
      RecNum := 1;
      WHILE (RecNum <= FileSize(HistoryFile)) AND (RecNum1 = -1) DO
      BEGIN
        Seek(HistoryFile,(RecNum - 1));
        Read(HistoryFile,TempHistory1);
        IF (PD2Date(TempHistory1.Date) = DateToLocate) THEN
           RecNum1 := RecNum;
        Inc(RecNum);
      END;
      IF (Searching) THEN
        Close(HistoryFile);
      IF (ShowErr) AND (RecNum1 = -1) THEN
      BEGIN
        Print('%LF^7The date entered is invalid!^1');
        PauseScr(FALSE);
      END;
    END;
  END;

  PROCEDURE DeleteHistoryRecord(TempHistory1: HistoryRecordType; RecNumToDelete: SmallInt);
  VAR
    DateToDelete: Str10;
    RecNum: Integer;
  BEGIN
    IF (NumHistoryDates = 0) THEN
      Messages(4,0,'history dates')
    ELSE
    BEGIN
      LocateHistoryDate('%LFHistory date to delete: ',TempHistory1,DateToDelete,RecNumToDelete,TRUE,TRUE);
      IF (RecNumToDelete >= 1) AND (RecNumToDelete <= NumHistoryDates) THEN
      BEGIN
        Reset(HistoryFile);
        Seek(HistoryFile,(RecNumToDelete - 1));
        Read(HistoryFile,TempHistory1);
        Close(HistoryFile);
        LastError := IOResult;
        IF (PD2Date(TempHistory1.Date) = DateStr) THEN
        BEGIN
          Print('%LF^7The current history date can not be deleted!^1');
          PauseScr(FALSE);
        END
        ELSE
        BEGIN
          Print('%LFHistory date: ^5'+PD2Date(TempHistory1.Date));
          IF PYNQ('%LFAre you sure you want to delete it? ',0,FALSE) THEN
          BEGIN
            Print('%LF[> Deleting history record ...');
            Dec(RecNumToDelete);
            Reset(HistoryFile);
            IF (RecNumToDelete >= 0) AND (RecNumToDelete <= (FileSize(HistoryFile) - 2)) THEN
              FOR RecNum := RecNumToDelete TO (FileSize(HistoryFile) - 2) DO
              BEGIN
                Seek(HistoryFile,(RecNum + 1));
                Read(HistoryFile,History);
                Seek(HistoryFile,RecNum);
                Write(HistoryFile,History);
              END;
            Seek(HistoryFile,(FileSize(HistoryFile) - 1));
            Truncate(HistoryFile);
            Close(HistoryFile);
            LastError := IOResult;
            Dec(NumHistoryDates);
            SysOpLog('* Deleted history date: ^5'+Pd2Date(TempHistory1.Date));
          END;
        END;
      END;
    END;
  END;

  PROCEDURE CheckHistoryRecord(History: HistoryRecordType; StartErrMsg,EndErrMsg: Byte; VAR Ok: Boolean);
  VAR
    Counter: Byte;
  BEGIN
    FOR Counter := StartErrMsg TO EndErrMsg DO
      CASE Counter OF
        1 : ;
      END;
  END;

  PROCEDURE EditHistoryRecord(TempHistory1: HistoryRecordType; VAR History: HistoryRecordType; VAR Cmd1: Char;
                            VAR RecNumToEdit,SaveRecNumToEdit: SmallInt; VAR Changed: Boolean; Editing: Boolean);
  VAR
    CmdStr,
    TempStr1: AStr;
    DateToLocate: Str10;
    RecNum: SmallInt;
    Ok: Boolean;
  BEGIN
    WITH History DO
      REPEAT
        IF (Cmd1 <> '?') THEN
        BEGIN
          Abort := FALSE;
          Next := FALSE;
          CLS;
          IF (Editing) THEN
            PrintACR('^5Editing history record #'+IntToStr((NumHistoryDates  + 1) - RecNumToEdit)+
                     ' of '+IntToStr(NumHistoryDates))
          ELSE
            PrintACR('^5Inserting history record #'+IntToStr((NumHistoryDates + 1) - RecNumToEdit)+
                     ' of '+IntToStr(NumHistoryDates + 1));
          NL;
          IF (Callers > 0) THEN
            TempStr1 := IntToStr(Active DIV Callers)
          ELSE
            TempStr1 := '0';
          PrintACR('^1A. Date          : ^5'+PD2Date(Date)+AOnOff(RecNumToEdit = NumHistoryDates,' (Today)',''));
          PrintACR('^1B. Minutes Active: ^5'+FormatNumber(Active));
          PrintACR('^1C. Calls         : ^5'+FormatNumber(Callers));
          PrintACR('^1D. Percent Active: ^5'+SQOutSp(CTP(Active,1440)));
          PrintACR('^1E. New Users     : ^5'+FormatNumber(NewUsers));
          PrintACR('^1G. Time/User     : ^5'+TempStr1);
          PrintACR('^1H. Public Posts  : ^5'+FormatNumber(Posts));
          PrintACR('^1I. Private Posts : ^5'+FormatNumber(EMail));
          PrintACR('^1K. SysOp FeedBack: ^5'+FormatNumber(FeedBack));
          PrintACR('^1M. Errors        : ^5'+FormatNumber(Errors));
          PrintACR('^1N. Uploads       : ^5'+FormatNumber(Uploads));
          PrintACR('^1O. Upload K      : ^5'+FormatNumber(UK));
          PrintACR('^1P. DownLoads     : ^5'+FormatNumber(DownLoads));
          PrintACR('^1R. Download K    : ^5'+FormatNumber(DK));
          PrintACR('^1S. Baud Rates');
        END;
        IF (NOT Editing) THEN
          CmdStr := 'ABCDEGHIKMNOPRS'
        ELSE
          CmdStr := 'ABCDEGHIKMNOPRS[]FJL';
        LOneK('%LFModify menu [^5?^4=^5Help^4]: ',Cmd1,'Q?'+CmdStr+^M,TRUE,TRUE);
        CASE Cmd1 OF
          'A' : IF (PD2Date(Date) = DateStr) THEN
                BEGIN
                  Print('%LF^7The current history date can not be changed!^1');
                  PauseScr(FALSE);
                END
                ELSE
                BEGIN
                  REPEAT
                    Ok := TRUE;
                    LocateHistoryDate('%LFNew history date: ',TempHistory1,DateToLocate,RecNum,FALSE,FALSE);
                    IF (DateToLocate <> '') AND (NOT (DateToLocate = PD2Date(History.Date))) THEN
                    BEGIN
                      IF (RecNum <> -1) THEN
                      BEGIN
                        Print('%LF^7The date entered is invalid!^1');
                        Ok := FALSE;
                      END
                      ELSE IF (DayNum(DateToLocate) > DayNum(DateStr)) THEN
                      BEGIN
                        Print('%LF^7The date can not be changed to a future date!^1');
                        Ok := FALSE;
                      END
                      ELSE IF (DateToLocate <> '') THEN
                      BEGIN
                        Date := Date2PD(DateToLocate);
                        Changed := TRUE;
                      END;
                    END;
                  UNTIL (Ok) OR (HangUp);
                END;
          'B' : InputLongIntWC('%LFNew minutes active for this date',Active,
                               [DisplayValue,NumbersOnly],0,2147483647,Changed);
          'C' : InputLongIntWC('%LFNew number of system callers for this date',Callers,
                               [DisplayValue,NumbersOnly],0,2147483647,Changed);
          'D' : BEGIN
                  Print('%LF^7This is for internal use only.');
                  PauseScr(FALSE);
                END;
          'E' : InputLongIntWC('%LFNew new user''s for this date',NewUsers,
                               [DisplayValue,NumbersOnly],0,2147483647,Changed);
          'G' : BEGIN
                  Print('%LF^7This is for internal use only.');
                  PauseScr(FALSE);
                END;
          'H' : InputLongIntWC('%LFNew public message post''s this date',Posts,
                               [DisplayValue,NumbersOnly],0,2147483647,Changed);
          'I' : InputLongIntWC('%LFNew private message post''s this date',Email,
                               [DisplayValue,NumbersOnly],0,2147483647,Changed);
          'K' : InputLongIntWC('%LFNew sysop feedback sent this date',FeedBack,
                               [DisplayValue,NumbersOnly],0,2147483647,Changed);
          'M' : InputLongIntWC('%LFNew system error''s this date',Errors,
                               [DisplayValue,NumbersOnly],0,2147483647,Changed);
          'N' : InputLongIntWC('%LFNew user upload''s for this date',Uploads,
                               [DisplayValue,NumbersOnly],0,2147483647,Changed);
          'O' : InputLongIntWC('%LFNew user kbytes uploaded this date',UK,
                               [DisplayValue,NumbersOnly],0,2147483647,Changed);
          'P' : InputLongIntWC('%LFNew user download''s this date',Downloads,
                               [DisplayValue,NumbersOnly],0,2147483647,Changed);
          'R' : InputLongIntWC('%LFNew user kbytes downloaded this date',DK,
                               [DisplayValue,NumbersOnly],0,2147483647,Changed);
          'S' : BEGIN
                  REPEAT
                    Print('%CL^5User Baud Rates');
                    Print('%LF'+PadLeftStr('^1A. Telnet/Other: ^5'+FormatNumber(UserBaud[0]),32)+
                          '^1B. 300 Baud    : ^5'+IntToStr(UserBaud[1]));
                    Print(PadLeftStr('^1C. 600 Baud    : ^5'+IntToStr(UserBaud[2]),32)+
                          '^1D. 1200 Baud   : ^5'+FormatNumber(UserBaud[3]));
                    Print(PadLeftStr('^1E. 2400 Baud   : ^5'+FormatNumber(UserBaud[4]),32)+
                          '^1F. 4800 Baud   : ^5'+FormatNumber(UserBaud[5]));
                    Print(PadLeftStr('^1G. 7200 Baud   : ^5'+FormatNumber(UserBaud[6]),32)+
                          '^1H. 9600 Baud   : ^5'+FormatNumber(UserBaud[7]));
                    Print(PadLeftStr('^1I. 12000 Baud  : ^5'+FormatNumber(UserBaud[8]),32)+
                          '^1J. 14400 Baud  : ^5'+FormatNumber(UserBaud[9]));
                    Print(PadLeftStr('^1K. 16800 Baud  : ^5'+FormatNumber(UserBaud[10]),32)+
                          '^1L. 19200 Baud  : ^5'+FormatNumber(UserBaud[11]));
                    Print(PadLeftStr('^1M. 21600 Baud  : ^5'+FormatNumber(UserBaud[12]),32)+
                          '^1N. 24000 Baud  : ^5'+FormatNumber(UserBaud[13]));
                    Print(PadLeftStr('^1O. 26400 Baud  : ^5'+FormatNumber(UserBaud[14]),32)+
                          '^1P. 28800 Baud  : ^5'+FormatNumber(UserBaud[15]));
                    Print(PadLeftStr('^1Q. 31200 Baud  : ^5'+FormatNumber(UserBaud[16]),32)+
                          '^1R. 33600 Baud  : ^5'+FormatNumber(UserBaud[17]));
                    Print(PadLeftStr('^1S. 38400 Baud  : ^5'+FormatNumber(UserBaud[18]),32)+
                          '^1T. 57600 Baud  : ^5'+FormatNumber(UserBaud[19]));
                    Print(PadLeftStr('^1U. 115200 Baud : ^5'+FormatNumber(UserBaud[20]),32));
                    LOneK('%LFModify menu [^5A^4-^5U^4,^5<CR>^4=^5Quit^4]: ',Cmd1,^M'ABCDEFGHIJKLMNOPQRSTU',TRUE,TRUE);
                    IF (Cmd1 <> ^M) THEN
                      InputLongIntWC('%LFNew value',UserBaud[Ord(Cmd1) - 65],
                                     [DisplayValue,NumbersOnly],0,2147483647,Changed);
                  UNTIL (Cmd1 = ^M) OR (HangUp);
                  Cmd1 := #0;
                END;
          ']' : IF (RecNumToEdit > 1) THEN
                   Dec(RecNumToEdit)
                ELSE
                BEGIN
                  Messages(3,0,'');
                  Cmd1 := #0;
                END;
          '[' : IF (RecNumToEdit < NumHistoryDates) THEN
                  Inc(RecNumToEdit)
                ELSE
                BEGIN
                  Messages(2,0,'');
                  Cmd1 := #0;
                END;
          'F' : IF (RecNumToEdit <> NumHistoryDates) THEN
                  RecNumToEdit := NumHistoryDates
                ELSE
                BEGIN
                  Messages(2,0,'');
                  Cmd1 := #0;
                END;
          'J' : BEGIN
                  RecNumToEdit := -1;
                  InputIntegerWOC('%LFJump to entry?',RecNumToEdit,[NumbersOnly],1,NumHistoryDates);
                  IF (RecNumToEdit < 1) OR (RecNumToEdit > NumHistoryDates) THEN
                  BEGIN
                    RecNumToEdit := SaveRecNumToEdit;
                    Cmd1 := #0;
                  END
                  ELSE
                    RecNumToEdit := ((NumHistoryDates - RecNumToEdit) + 1);
                END;
          'L' : IF (RecNumToEdit <> 1) THEN
                  RecNumToEdit := 1
                ELSE
                BEGIN
                  Messages(3,0,'');
                  Cmd1 := #0;
                END;
          '?' : BEGIN
                  Print('%LF^1<^3CR^1>Redisplay current screen');
                  Print('^3A^1-^3E^1,^3G^1-^3I^1,^3K^1,^3M^1-^3P^1,^3R^1-^3S^1:Modify item');
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

  PROCEDURE InsertHistoryRecord(TempHistory1: HistoryRecordType; Cmd1: Char; RecNumToInsertBefore: SmallInt);
  VAR
    DateToInsert,
    DateToInsertBefore: Str10;
    RecNum,
    RecNum1,
    SaveRecNumToEdit: SmallInt;
    Ok,
    Changed: Boolean;
  BEGIN
    IF (NumHistoryDates = MaxHistoryDates) THEN
      Messages(5,MaxHistoryDates,'history dates')
    ELSE
    BEGIN
      LocateHistoryDate('%LFHistory date to insert before: ',TempHistory1,DateToInsertBefore,RecNumToInsertBefore,TRUE,TRUE);
      IF (RecNumToInsertBefore >= 1) AND (RecNumToInsertBefore <= (NumHistoryDates + 1)) THEN
      BEGIN
        LocateHistoryDate('%LFNew history date to insert: ',TempHistory1,DateToInsert,RecNum1,FALSE,TRUE);
        IF (RecNum1 <> -1) THEN
        BEGIN
          Print('%LF^7Duplicate date entered!^1');
          PauseScr(FALSE);
        END
        ELSE IF (DayNum(DateToInsert) > DayNum(DateStr)) THEN
        BEGIN
          Print('%LF^7Future dates can not be entered!^1');
          PauseScr(FALSE);
        END
        ELSE
        BEGIN
          IF (DayNum(DateToInsert) > DayNum(DateToInsertBefore)) THEN
            Inc(RecNumToInsertBefore);
          Reset(HistoryFile);
          InitHistoryVars(TempHistory1);
          TempHistory1.Date := Date2PD(DateToInsert);
          IF (RecNumToInsertBefore = 1) THEN
            RecNum1 := 0
          ELSE IF (RecNumToInsertBefore = NumHistoryDates) THEN
            RecNum1 := (RecNumToInsertBefore - 1)
          ELSE
            RecNum1 := RecNumToInsertBefore;
          REPEAT
            OK := TRUE;
            EditHistoryRecord(TempHistory1,TempHistory1,Cmd1,RecNum1,SaveRecNumToEdit,Changed,FALSE);
            CheckHistoryRecord(TempHistory1,1,1,Ok);
            IF (NOT OK) THEN
              IF (NOT PYNQ('%LFContinue inserting history date? ',0,TRUE)) THEN
                Abort := TRUE;
          UNTIL (OK) OR (Abort) OR (HangUp);
          IF (NOT Abort) AND (PYNQ('%LFIs this what you want? ',0,FALSE)) THEN
          BEGIN
            Print('%LF[> Inserting history record ...');
            Seek(HistoryFile,FileSize(HistoryFile));
            Write(HistoryFile,History);
            Dec(RecNumToInsertBefore);
            FOR RecNum := ((FileSize(HistoryFile) - 1) - 1) DOWNTO RecNumToInsertBefore DO
            BEGIN
              Seek(HistoryFile,RecNum);
              Read(HistoryFile,History);
              Seek(HistoryFile,(RecNum + 1));
              Write(HistoryFile,History);
            END;
            FOR RecNum := RecNumToInsertBefore TO ((RecNumToInsertBefore + 1) - 1) DO
            BEGIN
              Seek(HistoryFile,RecNum);
              Write(HistoryFile,TempHistory1);
              Inc(NumHistoryDates);
              SysOpLog('* Inserted history date: ^5'+PD2Date(TempHistory1.Date));
            END;
          END;
          Close(HistoryFile);
          LastError := IOResult;
        END;
      END;
    END;
  END;

  PROCEDURE ModifyHistoryRecord(TempHistory1: HistoryRecordType; Cmd1: Char; RecNumToEdit: SmallInt);
  VAR
    DateToEdit: Str10;
    SaveRecNumToEdit: SmallInt;
    Ok,
    Changed: Boolean;
  BEGIN
    IF (NumHistoryDates = 0) THEN
      Messages(4,0,'history dates')
    ELSE
    BEGIN
      LocateHistoryDate('%LFHistory date to modify: ',TempHistory1,DateToEdit,RecNumToEdit,TRUE,TRUE);
      IF (RecNumToEdit >= 1) AND (RecNumToEdit <= NumHistoryDates) THEN
      BEGIN
        SaveRecNumToEdit := -1;
        Cmd1 := #0;
        Reset(HistoryFile);
        WHILE (Cmd1 <> 'Q') AND (NOT HangUp) DO
        BEGIN
          IF (SaveRecNumToEdit <> RecNumToEdit) THEN
          BEGIN
            Seek(HistoryFile,(RecNumToEdit - 1));
            Read(HistoryFile,History);
            SaveRecNumToEdit := RecNumToEdit;
            Changed := FALSE;
          END;
          REPEAT
            Ok := TRUE;
            EditHistoryRecord(TempHistory1,History,Cmd1,RecNumToEdit,SaveRecNumToEdit,Changed,TRUE);
            CheckHistoryRecord(History,1,1,Ok);
            IF (NOT OK) THEN
            BEGIN
              PauseScr(FALSE);
              IF (RecNumToEdit <> SaveRecNumToEdit) THEN
                RecNumToEdit := SaveRecNumToEdit;
            END;
          UNTIL (OK) OR (HangUp);
          IF (Changed) THEN
          BEGIN
            Seek(HistoryFile,(SaveRecNumToEdit - 1));
            Write(HistoryFile,History);
            Changed := FALSE;
            SysOpLog('* Modified history date: ^5'+PD2Date(History.Date));
          END;
        END;
        Close(HistoryFile);
        LastError := IOResult;
      END;
    END;
  END;

  PROCEDURE ListHistoryDates(VAR RecNumToList1: Integer);
  VAR
    TempStr: AStr;
    NumDone: Integer;
  BEGIN
    IF (RecNumToList1 < 1) OR (RecNumToList1 > NumHistoryDates) THEN
      RecNumToList1 := NumHistoryDates;
    Abort := FALSE;
    Next := FALSE;
    CLS;
    PrintACR('^3        ^4:^3Mins ^4:^3    ^4:^3      ^4:^3#New^4:^3Tim/^4:^3Pub ^4:^3Priv^4:^3Feed^4:^3    ^4:^3'+
             '    ^4:^3     ^4:^3    ^4:^3');
    PrintACR('^3  Date  ^4:^3Activ^4:^3Call^4:^3%Activ^4:^3User^4:^3User^4:^3Post^4:^3Post'+
             '^4:^3Back^4:^3Errs^4:^3#ULs^4:^3UL-k ^4:^3#DLs^4:^3DL-k');
    PrintACR('^4========:=====:====:======:====:====:====:====:====:====:====:=====:====:=====');
    Reset(HistoryFile);
    NumDone := 0;
    WHILE (NumDone < (PageLength - 6)) AND (RecNumToList1 >= 1) AND (RecNumToList1 <= NumHistoryDates)
          AND (NOT Abort) AND (NOT HangUp) DO
    BEGIN
      Seek(HistoryFile,(RecNumToList1 - 1));
      Read(HistoryFile,History);
      WITH History DO
      BEGIN
        IF (Callers > 0) THEN
          TempStr := PadRightInt(Active DIV Callers,4)
        ELSE
          TempStr := '    ';
        PrintACR('^1'+AOnOff((RecNumToList1 = NumHistoryDates),'Today''s ',ToDate8(PD2Date(Date)))+
                 ' '+PadRightInt(Active,5)+
                 ' '+PadRightInt(Callers,4)+
                 ' '+CTP(Active,1440)+
                 ' '+PadRightInt(NewUsers,4)+
                 ' '+TempStr+
                 ' '+PadRightInt(Posts,4)+
                 ' '+PadRightInt(EMail,4)+
                 ' '+PadRightInt(FeedBack,4)+
                 ' '+PadRightInt(Errors,4)+
                 ' '+PadRightInt(Uploads,4)+
                 ' '+PadRightInt(UK,5)+
                 ' '+PadRightInt(DownLoads,4)+
                 ' '+PadRightInt(DK,5));
      END;
      Dec(RecNumToList1);
      Inc(NumDone);
    END;
    Close(HistoryFile);
    LastError := IOResult;
    IF (NumHistoryDates = 0) THEN
      Print('*** No history dates defined ***');
  END;

BEGIN
  SaveTempPause := TempPause;
  TempPause := FALSE;
  Assign(HistoryFile,General.DataPath+'HISTORY.DAT');
  Reset(HistoryFile);
  NumHistoryDates := FileSize(HistoryFile);
  Close(HistoryFile);
  RecNumToList := NumHistoryDates;
  Cmd := #0;
  REPEAT
    IF (Cmd <> '?') THEN
      ListHistoryDates(RecNumToList);
    LOneK('%LFHistory editor [^5?^4=^5Help^4]: ',Cmd,'QDIM?'^M,TRUE,TRUE);
    CASE Cmd OF
      ^M  : IF (RecNumToList < 1) OR (RecNumToList > NumHistoryDates) THEN
              RecNumToList := NumHistoryDates;
      'D' : DeleteHistoryRecord(TempHistory,RecNumToList);
      'I' : InsertHistoryRecord(TempHistory,Cmd,RecNumToList);
      'M' : ModifyHistoryRecord(TempHistory,Cmd,RecNumToList);
      '?' : BEGIN
              Print('%LF^1<^3CR^1>Next screen or redisplay current screen');
              Print('^1(^3?^1)Help/First history date');
              LCmds(20,3,'Delete history date','Insert history date');
              LCmds(20,3,'Modify history date','Quit');
            END;
    END;
    IF (Cmd <> ^M) THEN
      RecNumToList := NumHistoryDates;
  UNTIL (Cmd = 'Q') OR (HangUp);
  TempPause := SaveTempPause;
  LastError := IOResult;
END;

END.
