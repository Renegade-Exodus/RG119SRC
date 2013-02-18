{$IFDEF WIN32}
{$I DEFINES.INC}
{$ENDIF}

{$A+,B-,D+,E-,F+,I-,L+,N-,O+,R-,S+,V-}

UNIT SysOp6;

INTERFACE

PROCEDURE EventEditor;

IMPLEMENTATION

USES
  Common,
  TimeFunc;

PROCEDURE EventEditor;
VAR
  TempEvent: EventRecordType;
  Cmd: Char;
  RecNumToList: Integer;
  SaveTempPause: Boolean;

  FUNCTION DaysEventActive(EventDays: EventDaysType; C1,C2: Char): AStr;
  CONST
    Days: Str7 = 'SMTWTFS';
  VAR
    TempStr: AStr;
    Counter: Byte;
  BEGIN
    TempStr := '';
    FOR Counter := 0 TO 6 DO
     IF (Counter IN EventDays) THEN
       TempStr := TempStr + '^'+C1+Days[Counter + 1]
     ELSE
       TempStr := TempStr + '^'+C2+'-';
    DaysEventActive := TempStr;
  END;

  FUNCTION NextDay(Date: Str10): LongInt;
  VAR
    Day,
    Month,
    Year: Word;
  BEGIN
    Month := StrToInt(Copy(Date,1,2));
    Day := StrToInt(Copy(Date,4,2));
    Year := StrToInt(Copy(Date,7,4));
    IF (Day = 31) AND (Month = 12) THEN
    BEGIN
      Inc(Year);
      Month := 1;
      Day := 1;
    END
    ELSE
    BEGIN
      IF (Day < Days(Month,Year)) THEN
        Inc(Day)
      ELSE IF (Month < 12) THEN
      BEGIN
        Inc(Month);
        Day := 1;
      END;
    END;
    NextDay := Date2PD(ZeroPad(IntToStr(Month))+'/'+ZeroPad(IntToStr(Day))+'/'+IntToStr(Year));
  END;

  FUNCTION ShowTime(W: Word): Str5;
  BEGIN
    ShowTime := ZeroPad(IntToStr(W DIV 60))+':'+ZeroPad(IntToStr(W MOD 60));
  END;

  PROCEDURE ToggleEFlag(EFlagT: EventFlagType; VAR EFlags: EFlagSet);
  BEGIN
    IF (EFlagT IN EFlags) THEN
      Exclude(EFlags,EFlagT)
    ELSE
      Include(EFlags,EFlagT);
  END;

  PROCEDURE ToggleEFlags(C: Char; VAR EFlags: EFlagSet; VAR Changed: Boolean);
  VAR
    SaveEFlags: EFlagSet;
  BEGIN
    SaveEFlags := EFlags;
    CASE C OF
      'A' : ToggleEFlag(EventIsExternal,EFlags);
      'B' : ToggleEFlag(EventIsActive,EFlags);
      'C' : ToggleEFlag(EventIsShell,EFlags);
      'D' : ToggleEFlag(EventIsOffhook,EFlags);
      'E' : ToggleEFlag(EventIsMonthly,EFlags);
      'F' : ToggleEFlag(EventIsPermission,EFlags);
      'G' : ToggleEFlag(EventIsLogon,EFlags);
      'H' : ToggleEFlag(EventIsChat,EFlags);
      'I' : ToggleEFlag(EventIsPackMsgAreas,EFlags);
      'J' : ToggleEFlag(EventIsSortFiles,EFlags);
      'K' : ToggleEFlag(EventIsSoft,EFlags);
      'L' : ToggleEFlag(EventIsMissed,EFlags);
      'M' : ToggleEFlag(BaudIsActive,EFlags);
      'N' : ToggleEFlag(AcsIsActive,EFlags);
      'O' : ToggleEFlag(TimeIsActive,EFlags);
      'P' : ToggleEFlag(ARisActive,EFlags);
      'Q' : ToggleEFlag(SetARisActive,EFlags);
      'R' : ToggleEFlag(ClearARisActive,EFlags);
      'S' : ToggleEFlag(InRatioIsActive,EFlags);
    END;
    IF (EFlags <> SaveEFlags) THEN
      Changed := TRUE;
  END;

  PROCEDURE InitEventVars(VAR Event: EventRecordType);
  BEGIN
    FillChar(Event,SizeOf(Event),0);
    WITH Event DO
    BEGIN
      EventDescription := '<< New Event >>';
      EventDayOfMonth := 0;
      EventDays := [];
      EventStartTime := 0;
      EventFinishTime := 0;
      EventQualMsg := '';
      EventNotQualMsg := '';
      EventPreTime := 0;
      EventNode := 0;
      EventLastDate := 0;
      EventErrorLevel := 0;
      EventShellPath := '';
      LoBaud := 300;
      HiBaud := 19200;
      EventACS := 's10';
      MaxTimeAllowed := 60;
      SetARflag := '@';
      ClearARflag := '@';
      EFlags := [EventIsExternal,EventIsShell];
    END;
  END;

  PROCEDURE DeleteEvent(TempEvent1: EventRecordType; RecNumToDelete: SmallInt);
  VAR
    RecNum: Integer;
  BEGIN
    IF (NumEvents = 0) THEN
      Messages(4,0,'events')
    ELSE
    BEGIN
      RecNumToDelete := -1;
      InputIntegerWOC('%LFEvent to delete?',RecNumToDelete,[NumbersOnly],1,NumEvents);
      IF (RecNumToDelete >= 1) AND (RecNumToDelete <= NumEvents) THEN
      BEGIN
        Reset(EventFile);
        Seek(EventFile,(RecNumToDelete - 1));
        Read(EventFile,TempEvent1);
        Close(EventFile);
        LastError := IOResult;
        Print('%LFEvent: ^5'+TempEvent1.EventDescription);
        IF PYNQ('%LFAre you sure you want to delete it? ',0,FALSE) THEN
        BEGIN
          Print('%LF[> Deleting event record ...');
          Dec(RecNumToDelete);
          Reset(EventFile);
          IF (RecNumToDelete >= 0) AND (RecNumToDelete <= (FileSize(EventFile) - 2)) THEN
            FOR RecNum := RecNumToDelete TO (FileSize(EventFile) - 2) DO
            BEGIN
              Seek(EventFile,(RecNum + 1));
              Read(EventFile,Event);
              Seek(EventFile,RecNum);
              Write(EventFile,Event);
            END;
          Seek(EventFile,(FileSize(EventFile) - 1));
          Truncate(EventFile);
          Close(EventFile);
          LastError := IOResult;
          Dec(NumEvents);
          SysOpLog('* Deleted event: ^5'+TempEvent1.EventDescription);
        END;
      END;
    END;
  END;

  PROCEDURE CheckEvent(Event: EventRecordType; StartErrMsg,EndErrMsg: Byte; VAR Ok: Boolean);
  VAR
    Counter: Byte;
  BEGIN
    FOR Counter := StartErrMsg TO EndErrMsg DO
      CASE Counter OF
        1 : ;
      END;
  END;



  PROCEDURE EditEvent(TempEvent1: EventRecordType; VAR Event: EventRecordType; VAR Cmd1: Char;
                      VAR RecNumToEdit: SmallInt; VAR Changed: Boolean; Editing: Boolean);
  CONST
    BaudRates: ARRAY [1..20] OF LongInt = (300,600,1200,2400,4800,7200,9600,
                                          12000,14400,16800,19200,21600,24000,
                                          26400,28800,31200,33600,38400,57600,
                                          115200);
  VAR
    OneKCmds,
    TempStr: AStr;
    Counter: Byte;
  BEGIN
    WITH Event DO
      REPEAT
        IF (Cmd1 <> '?') THEN
        BEGIN
          Abort := FALSE;
          Next := FALSE;
          CLS;
          IF (Editing) THEN
            PrintACR('^5Editing event #'+IntToStr(RecNumToEdit)+' of '+IntToStr(NumEvents))
          ELSE
            PrintACR('^5Inserting event #'+IntToStr(RecNumToEdit)+' of '+IntToStr(NumEvents + 1));
          NL;
          PrintACR('^1A. Event type            : ^5'+AOnOff(EventIsExternal IN EFlags,'External','Internal'));
          PrintACR('^1B. Description           : ^5'+EventDescription);
          PrintACR('^1C. Active                : ^5'+AOnOff(EventIsActive IN EFlags,'Active','Inactive'));
          IF (EventIsExternal IN EFlags) THEN
          BEGIN
            PrintACR('^1D. Execution hard/soft   : ^5'+AOnOff(EventIsSoft IN EFlags,'Soft','Hard'));
            TempStr := '^1E. Event type            : ^5';
            IF (EventIsErrorLevel IN EFlags) THEN
              TempStr := TempStr + 'Error level = '+IntToStr(EventErrorLevel)
            ELSE IF (EventIsShell IN EFlags) THEN
              TempStr := TempStr + 'Shell file = "'+EventShellPath+'"'
            ELSE IF (EventIsSortFiles IN EFlags) THEN
              TempStr := TempStr + 'Sort Files'
            ELSE IF (EventIsPackMsgAreas IN EFlags) THEN
              TempStr := TempStr + 'Pack Message Areas'
            ELSE IF (EventIsFilesBBS IN EFlags) THEN
              TempStr := TempStr + 'Check Files.BBS';
            PrintACR(TempStr);
            PrintACR('^1G. Scheduled day(s)      : ^5'+AOnOff(EventIsMonthly IN EFlags,
                                                   'Monthly ^1-^5 Day ^1=^5 '+IntToStr(EventDayOfMonth),
                                                   'Weekly ^1-^5 Days ^1=^5 '+DaysEventActive(EventDays,'5','1')));
            PrintACR('^1H. Start time            : ^5'+ShowTime(EventStartTime));
            PrintACR('^1I. Phone status          : ^5'+AOnOff(EventIsOffHook IN EFlags,
                                                   'Off-hook ('+IntToStr(EventPreTime)+' minutes before the Event)',
                                                   'Remain on-hook'));
            PrintACR('^1K. Executed today        : ^5'+ShowYesNo(PD2Date(EventLastDate) = DateStr)+' '
                                                   +AOnOff(EventIsActive IN EFlags,
                                                   '(Next scheduled date: '+PD2Date(EventLastDate)+')',
                                                   '(Not scheduled for execution)'));
          END
          ELSE
          BEGIN
            PrintACR('^1D. Scheduled day(s)      : ^5'+AOnOff(EventIsMonthly IN EFlags,
                                                   'Monthly ^1-^5 Day ^1=^5 '+IntToStr(EventDayOfMonth),
                                                   'Weekly ^1-^5 Days ^1=^5 '+DaysEventActive(EventDays,'5','1')));
            PrintACR('^1E. Time active           : ^5'+ShowTime(EventStartTime)+' to '+
                                                   ShowTime(EventFinishTime));
            PrintACR('^1G. Permission/restriction: ^5'+AOnOff(EventIsPermission IN EFlags,
                                                   'Permission','Restriction'));
            PrintACR('^1H. Event type            : ^5'+AOnOff(EventIsChat IN EFlags,'Chat','Logon'));
            PrintACR('^1I. Affected message      : "^5'+eventqualmsg+'^1"');
            PrintACR('^1K. Unaffected message    : "^5'+eventnotqualmsg+'^1"');
          END;
          PrintACR('^1M. Run if missed         : ^5'+ShowYesNo(EventIsMissed IN EFlags));
          PrintACR('^1N. Node number           : ^5'+IntToStr(EventNode));
          IF (NOT (EventIsExternal IN EFlags)) THEN
          BEGIN
            NL;
            PrintACR('       ^4<<<^5 Qualifiers ^4>>>');
            NL;
            PrintACR('^11. Baud rate range  : ^5'+AOnOff(BaudIsActive IN EFlags,
                                              IntToStr(LoBaud)+' to '+IntToStr(HiBaud),
                                              '<<Inactive>>'));
            PrintACR('^12. ACS              : ^5'+AOnOff(ACSIsActive IN EFlags,EventACS,'<<Inactive>>'));
            IF (EventIsPermission IN EFlags) THEN
              PrintACR('^13. Maximum time     : ^5'+AOnOff(TimeIsActive IN EFlags,
                                                IntToStr(MaxTimeAllowed),
                                                '<<Inactive>>'));
            IF (EventIsPermission IN EFlags) THEN
            BEGIN
              PrintACR('^14. Set AR flag      : ^5'+AOnOff(SetArIsActive IN EFlags,
                                                SetArFlag,
                                                '<<Inactive>>'));
              PrintACR('^15. Clear AR flag    : ^5'+AOnOff(ClearArIsActive IN EFlags,
                                                ClearArFlag,
                                                '<<Inactive>>'));
            END;
            PrintACR('^16. UL/DL ratio check: ^5'+AOnOff(InRatioIsActive IN EFlags,
                                              'Active',
                                              '<<Inactive>>'));
          END;
        END;
        IF (EventIsExternal IN EFlags) THEN
          OneKCmds := ''
        ELSE
        BEGIN
          IF (EventIsPermission IN EFlags) THEN
            OneKCmds := '123456'
          ELSE
            OneKCmds := '126';
        END;
        LOneK('%LFModify '+AOnOff(EventIsExternal IN EFlags,'external','internal')+' event [^5?^4=^5Help^4]: ',
              Cmd1,'QABCDEGHIKMN'+OneKCmds+'[]FJL?'^M,TRUE,TRUE);
        CASE Cmd1 OF
          'A' : ToggleEFlagS('A',EFlags,Changed);  { External/Internal }
          'B' : InputWN1('%LFNew description: ',EventDescription,30,[InterActiveEdit],Changed);
          'C' : ToggleEFlags('B',EFlags,Changed);  { Active/InActive }
          'D' : IF (EventIsExternal IN EFlags) THEN
                  ToggleEFlags('K',EFlags,Changed) { Soft/Hard }
                ELSE                               { Dialy/Monthly }
                BEGIN
                  LOneK('%LFSchedule? [^5D^4=^5Daily^4,^5M^4=^5Monthly^4,^5<CR>^4=^5Quit^4]: ',Cmd1,^M'DM',TRUE,TRUE);
                  CASE Cmd1 OF
                    'D' : BEGIN
                            IF (EventIsMonthly IN EFlags) THEN
                            BEGIN
                              Exclude(EFlags,EventIsMonthly);
                              EventDayOfMonth := 0;
                              Changed := TRUE;
                            END;
                            REPEAT
                              Print('%LF^5Active Days: ^3'+DaysEventActive(EventDays,'5','4')+'^1');
                              NL;
                              LCmds(11,3,'1Sunday','');
                              LCmds(11,3,'2Monday','');
                              LCmds(11,3,'3Tuesday','');
                              LCmds(11,3,'4Wednesday','');
                              LCmds(11,3,'5Thursday','');
                              LCmds(11,3,'6Friday','');
                              LCmds(11,3,'7Saturday','');
                              LOneK('%LFToggle which day? [^51^4-^57^4,^5<CR>^4=^5Quit^4]: ',Cmd1,^M'1234567',TRUE,TRUE);
                              IF (Cmd1 <> ^M) THEN
                              BEGIN
                                IF ((StrToInt(Cmd1) - 1) IN EventDays) THEN
                                  Exclude(EventDays,(StrToInt(Cmd1) - 1))
                                ELSE
                                  Include(EventDays,(StrToInt(Cmd1) - 1));
                                Changed := TRUE;
                              END;
                            UNTIL (Cmd1 = ^M) OR (HangUp);
                            Cmd1 := #0;
                          END;
                    'M' : BEGIN
                            IF (NOT (EventIsMonthly IN EFlags)) THEN
                            BEGIN
                              Include(EFlags,EventIsMonthly);
                              EventDays := [];
                              Changed := TRUE;
                            END;
                            InputByteWC('%LFDay of the month',EventDayOfMonth,[],1,31,Changed);
                          END;
                  END;
                  Cmd1 := #0;
                END;
          'E' : IF (EventIsExternal IN EFlags) THEN
                BEGIN
                  Print('%LF^5External event type');
                  NL;
                  LCmds(18,3,'1Errorlevel','');
                  LCmds(18,3,'2Shell','');
                  LCmds(18,3,'3Sort Files','');
                  LCmds(18,3,'4Pack Message Areas','');
                  LCmds(18,3,'5Files.BBS','');
                  LOneK('%LFWhich external event? [^51^4-^55^4,^5<CR>^4=^5Quit^4]: ',Cmd1,^M'12345',TRUE,TRUE);
                  IF (Cmd1 <> ^M) THEN
                  BEGIN
                    CASE Cmd1 OF
                      '1' : BEGIN
                              IF (EventIsShell IN EFlags) THEN
                              BEGIN
                                Exclude(EFlags,EventIsShell);
                                EventShellPath := '';
                              END;
                              IF (EventIsSortFiles IN EFlags) THEN
                                Exclude(EFlags,EventIsSortFiles);
                              IF (EventIsPackMsgAreas IN EFlags) THEN
                                Exclude(EFlags,EventIsPackMsgAreas);
                              IF (EventIsFilesBBS IN EFlags) THEN
                                Exclude(EFlags,EventIsFilesBBS);
                              Include(EFlags,EventIsErrorLevel);
                              InputByteWC('%LFError Level',EventErrorLevel,[],0,255,Changed);
                            END;
                      '2' : BEGIN
                              IF (EventIsErrorLevel IN EFlags) THEN
                              BEGIN
                                Exclude(EFlags,EventIsErrorLevel);
                                EventErrorLevel := 0;
                              END;
                              IF (EventIsSortFiles IN EFlags) THEN
                                Exclude(EFlags,EventIsSortFiles);
                              IF (EventIsPackMsgAreas IN EFlags) THEN
                                Exclude(EFlags,EventIsPackMsgAreas);
                              IF (EventIsFilesBBS IN EFlags) THEN
                                Exclude(EFlags,EventIsFilesBBS);
                              Include(EFlags,EventIsShell);
                              InputWN1('%LFShell file: ',EventShellPath,8,[UpperOnly],Changed);
                            END;
                      '3' : BEGIN
                              IF (EventIsShell IN EFlags) THEN
                              BEGIN
                                Exclude(EFlags,EventIsShell);
                                EventShellPath := '';
                              END;
                              IF (EventIsErrorLevel IN EFlags) THEN
                              BEGIN
                                Exclude(EFlags,EventIsErrorLevel);
                                EventErrorLevel := 0;
                              END;
                              IF (EventIsPackMsgAreas IN EFlags) THEN
                                Exclude(EFlags,EventIsPackMsgAreas);
                              IF (EventIsFilesBBS IN EFlags) THEN
                                Exclude(EFlags,EventIsFilesBBS);
                              Include(EFlags,EventIsSortFiles);
                            END;
                      '4' : BEGIN
                              IF (EventIsShell IN EFlags) THEN
                              BEGIN
                                Exclude(EFlags,EventIsShell);
                                EventShellPath := '';
                              END;
                              IF (EventIsErrorLevel IN EFlags) THEN
                              BEGIN
                                Exclude(EFlags,EventIsErrorLevel);
                                EventErrorLevel := 0;
                              END;
                              IF (EventIsSortFiles IN EFlags) THEN
                                Exclude(EFlags,EventIsSortFiles);
                              IF (EventIsFilesBBS IN EFlags) THEN
                                Exclude(EFlags,EventIsFilesBBS);
                              Include(EFlags,EventIsPackMsgAreas);
                            END;
                      '5' : BEGIN
                              IF (EventIsShell IN EFlags) THEN
                              BEGIN
                                Exclude(EFlags,EventIsShell);
                                EventShellPath := '';
                              END;
                              IF (EventIsErrorLevel IN EFlags) THEN
                              BEGIN
                                Exclude(EFlags,EventIsErrorLevel);
                                EventErrorLevel := 0;
                              END;
                              IF (EventIsSortFiles IN EFlags) THEN
                                Exclude(EFlags,EventIsSortFiles);
                              IF (EventIsPackMsgAreas IN EFlags) THEN
                                Exclude(EFlags,EventIsPackMsgAreas);
                              Include(EFlags,EventIsFilesBBS);
                            END;
                    END;
                    Changed := TRUE;
                  END;
                  Cmd1 := #0;
                END
                ELSE
                BEGIN
                  Prt('%LFNew event start time? (24 Hour Format) Hour: (0-23), Minute: (0-59): ');
                  InputFormatted('',TempStr,'##:##',TRUE);
                  IF (TempStr <> '') AND (Length(TempStr) = 5) AND (Pos(':',TempStr) = 3) THEN
                  BEGIN
                    IF (StrToInt(Copy(TempStr,1,2)) IN [0..23]) AND (StrToInt(Copy(TempStr,4,2)) IN [0..59]) THEN
                    BEGIN
                      EventStartTime := ((StrToInt(Copy(TempStr,1,2)) * 60) + StrToInt(Copy(TempStr,4,2)));
                      Changed := TRUE;
                    END
                    ELSE
                    BEGIN
                      Print('%LF^5Invalid time - Format is HH:MM (24 hour military)');
                      PauseScr(FALSE);
                    END;
                  END;
                  Prt('%LFNew event finish time? (24 Hour Format) Hour: (0-23), Minute: (0-59): ');
                  InputFormatted('',TempStr,'##:##',TRUE);
                  IF (TempStr <> '') AND (Length(TempStr) = 5) AND (Pos(':',TempStr) = 3) THEN
                  BEGIN
                    IF (StrToInt(Copy(TempStr,1,2)) IN [0..23]) AND (StrToInt(Copy(TempStr,4,2)) IN [0..59]) THEN
                    BEGIN
                      EventFinishTime := ((StrToInt(Copy(TempStr,1,2)) * 60) + StrToInt(Copy(TempStr,4,2)));
                      Changed := TRUE;
                    END
                    ELSE
                    BEGIN
                      Print('%LF^5Invalid time - Format is HH:MM (24 hour military)');
                      PauseScr(FALSE);
                    END;
                  END;
                END;
          'G' : IF (EventIsExternal IN EFlags) THEN
                BEGIN
                  LOneK('%LFSchedule? [^5D^4=^5Daily^4,^5M^4=^5Monthly^4,^5<CR>^4=^5Quit^4]: ',Cmd1,^M'DM',TRUE,TRUE);
                  CASE Cmd1 OF
                    'D' : BEGIN
                            IF (EventIsMonthly IN EFlags) THEN
                            BEGIN
                              Exclude(EFlags,EventIsMonthly);
                              EventDayOfMonth := 0;
                              Changed := TRUE;
                            END;
                            REPEAT
                              Print('%LF^5Active Days: ^3'+DaysEventActive(EventDays,'5','4')+'^1');
                              NL;
                              LCmds(11,3,'1Sunday','');
                              LCmds(11,3,'2Monday','');
                              LCmds(11,3,'3Tuesday','');
                              LCmds(11,3,'4Wednesday','');
                              LCmds(11,3,'5Thursday','');
                              LCmds(11,3,'6Friday','');
                              LCmds(11,3,'7Saturday','');
                              LOneK('%LFToggle which day? [^51^4-^57^4,^5<CR>^4=^5Quit^4]: ',Cmd1,^M'1234567',TRUE,TRUE);
                              IF (Cmd1 <> ^M) THEN
                              BEGIN
                                IF (StrToInt(Cmd1) - 1 IN EventDays) THEN
                                  Exclude(EventDays,StrToInt(Cmd1) - 1)
                                ELSE
                                  Include(EventDays,StrToInt(Cmd1) - 1);
                                Changed := TRUE;
                              END;
                            UNTIL (Cmd1 = ^M) OR (HangUp);
                            Cmd1 := #0;
                          END;
                    'M' : BEGIN
                            IF (NOT (EventIsMonthly IN EFlags)) THEN
                            BEGIN
                              Include(EFlags,EventIsMonthly);
                              EventDays := [];
                              Changed := TRUE;
                            END;
                            InputByteWC('%LFDay of the month',EventDayOfMonth,[],1,31,Changed);
                          END;
                  END;
                  Cmd1 := #0;
                END
                ELSE
                BEGIN
                  ToggleEFlag(EventIsPermission,EFlags);
                  Changed := TRUE;
                END;
          'H' : IF (EventIsExternal IN EFlags) THEN
                BEGIN
                  Prt('%LFNew event start time? (24 Hour Format) Hour: (0-23), Minute: (0-59): ');
                  InputFormatted('',TempStr,'##:##',TRUE);
                  IF (TempStr <> '') AND (Length(TempStr) = 5) AND (Pos(':',TempStr) = 3) THEN
                  BEGIN
                    IF (StrToInt(Copy(TempStr,1,2)) IN [0..23]) AND (StrToInt(Copy(TempStr,4,2)) IN [0..59]) THEN
                    BEGIN
                      EventStartTime := ((StrToInt(Copy(TempStr,1,2)) * 60) + StrToInt(Copy(TempStr,4,2)));
                      Changed := TRUE;
                    END
                    ELSE
                    BEGIN
                      Print('%LF^5Invalid time - Format is HH:MM (24 hour military)');
                      PauseScr(FALSE);
                    END;
                  END;
                END
                ELSE
                BEGIN
                  Print('%LF^5Internal event type:');
                  NL;
                  LCmds(7,3,'1Logon','');
                  LCmds(7,3,'2Chat','');
                  LOneK('%LFWhich internal event? [^51^4-^52^4,^5<CR>^4=^5Quit^4]: ',Cmd1,^M'12',TRUE,TRUE);
                  IF (Cmd1 <> ^M) THEN
                  BEGIN
                    CASE Cmd1 OF
                      '1' : BEGIN
                              IF (EventIsChat IN EFlags) THEN
                                Exclude(EFlags,EventIsChat);
                              Include(EFlags,EventIsLogon);
                            END;
                      '2' : BEGIN
                              IF (EventIsLogon IN EFlags) THEN
                                Exclude(EFlags,EventIsLogon);
                              Include(EFlags,EventIsChat);
                            END;
                    END;
                    Changed := TRUE;
                  END;
                  Cmd1 := #0;
                END;
          'I' : IF (EventIsExternal IN EFlags) THEN
                BEGIN
                  IF (EventIsOffHook IN EFlags) THEN
                  BEGIN
                    Exclude(EFlags,EventIsOffHook);
                    EventPreTime := 0;
                    Changed := TRUE;
                  END
                  ELSE
                  BEGIN
                    Include(EFlags,EventIsOffHook);
                    InputByteWC('%LFMinutes before event to take phone offhook',EventPreTime,[],0,255,Changed);
                  END;
                END
                ELSE
                  InputWN1('%LF^1Message/@File if the user is effected by the event:%LF^4: ',EventQualMsg,64,[],Changed);
          'K' : IF (EventIsExternal IN EFlags) THEN
                BEGIN
                  IF (PD2Date(EventLastDate) = DateStr) THEN
                    EventLastDate := NextDay(PD2Date(EventLastDate))
                  ELSE
                    EventLastDate := Date2PD(DateStr);
                  Changed := TRUE;
                END
                ELSE
                  InputWN1('%LF^1Message/@File if the user IS NOT effected by the event:%LF^4: ',
                           EventNotQualMsg,64,[],Changed);
          'M' : BEGIN
                  IF PYNQ('%LFRun this event later if the event time is missed? ',0,FALSE) THEN
                    Include(EFlags,EventIsMissed)
                  ELSE
                    Exclude(EFlags,EventIsMissed);
                  Changed := TRUE;
                END;
          'N' : InputByteWC('%LFNode number to execute event from (0=All)',EventNode,
                            [DisplayValue,NumbersOnly],0,MaxNodes,Changed);
          '1' : IF (NOT (EventIsExternal IN EFlags)) THEN
                  IF (BaudIsActive IN EFlags) THEN
                  BEGIN
                    Exclude(EFlags,BaudIsActive);
                    LoBaud := 300;
                    HiBaud := 115200;
                    Changed := TRUE;
                  END
                  ELSE
                  BEGIN
                    Include(EFlags,BaudIsActive);
                    Print('%LF^5Baud lower limit:^1%LF');
                    Counter := 1;
                    WHILE (Counter <= 20) AND (NOT Abort) AND (NOT HangUp) DO
                    BEGIN
                      PrintACR(Char(Counter + 64)+'. '+IntToStr(BaudRates[Counter]));
                      Inc(Counter);
                    END;
                    LOneK('%LFWhich? (^5A^4-^5T^4): ',Cmd1,'ABCDEFGHIJKLMNOPQRST',TRUE,TRUE);
                    LoBaud := BaudRates[Ord(Cmd1) - 64];
                    Print('%LF^5Baud upper limit:^1%LF');
                    Counter := 1;
                    WHILE (Counter <= 20) AND (NOT Abort) AND (NOT HangUp) DO
                    BEGIN
                      PrintACR(Char(Counter + 64)+'. '+IntToStr(BaudRates[Counter]));
                      Inc(Counter);
                    END;
                    LOneK('%LFWhich? (^5A^4-^5T^4): ',Cmd1,'ABCDEFGHIJKLMNOPQRST',TRUE,TRUE);
                    HiBaud := BaudRates[Ord(Cmd1) - 64];
                    Changed := TRUE;
                    Cmd1 := #0;
                  END;
          '2' : IF (NOT (EventIsExternal IN EFlags)) THEN
                  IF (ACSIsActive IN EFlags) THEN
                  BEGIN
                    Exclude(EFlags,ACSIsActive);
                    EventACS := 's10';
                    Changed := TRUE;
                  END
                  ELSE
                  BEGIN
                    Include(EFlags,ACSIsActive);
                    InputWN1('%LFSL ACS: ',EventACS,(SizeOf(EventACS) - 1),[InterActiveEdit],Changed);
                  END;
          '3' : IF (NOT (EventIsExternal IN EFlags)) THEN
                  IF (EventIsPermission IN EFlags) THEN
                  BEGIN
                    IF (TimeIsActive IN EFlags) THEN
                    BEGIN
                      Exclude(EFlags,TimeIsActive);
                      MaxTimeAllowed := 60;
                      Changed := TRUE;
                    END
                    ELSE
                    BEGIN
                      Include(EFlags,TimeIsActive);
                      InputWordWoc('%LFMaximum time allowed on-line (minutes)',MaxTimeAllowed,
                                   [DisplayValue,NumbersOnly],0,65535);
                    END;
                  END;
          '4' : IF NOT (EventIsExternal IN EFlags) THEN
                  IF (EventIsPermission IN EFlags) THEN
                  BEGIN
                    IF (SetArIsActive IN EFlags) THEN
                    BEGIN
                      Exclude(EFlags,SetArIsActive);
                      SetArFlag := '@';
                      Changed := TRUE;
                    END
                    ELSE
                    BEGIN
                      Include(EFlags,SetArIsActive);
                      LOneK('%LFAR flag to set (^5A^4-^5Z^4): ',Cmd1,'ABCDEFGHIJKLMNOPQRSTUVWXYZ',TRUE,TRUE);
                      SetArFlag := Cmd1;
                      Cmd1 := #0;
                    END;
                  END;
          '5' : IF NOT (EventIsExternal IN EFlags) THEN
                  IF (EventIsPermission IN EFlags) THEN
                  BEGIN
                    IF (ClearArIsActive IN EFlags) THEN
                    BEGIN
                      Exclude(EFlags,ClearArIsActive);
                      ClearArFlag := '@';
                      Changed := TRUE;
                    END
                    ELSE
                    BEGIN
                      Include(EFlags,ClearArIsActive);
                      LOneK('%LFAR flag to clear (^5A^4-^5Z^4): ',Cmd1,'ABCDEFGHIJKLMNOPQRSTUVWXYZ',TRUE,TRUE);
                      ClearArFlag := Cmd1;
                      Cmd1 := #0;
                    END;
                  END;
          '6' : IF (NOT (EventIsExternal IN EFlags)) THEN
                  ToggleEFlags('S',EFlags,Changed);
          '[' : IF (RecNumToEdit > 1) THEN
                  Dec(RecNumToEdit)
                ELSE
                BEGIN
                  Messages(2,0,'');
                  Cmd1 := #0;
                END;
          ']' : IF (RecNumToEdit < NumEvents) THEN
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
                  InputIntegerWOC('%LFJump to entry?',RecNumToEdit,[NumbersOnly],1,NumEvents);
                  IF (RecNumToEdit < 1) OR (RecNumToEdit > NumEvents) THEN
                    Cmd1 := #0;
                END;
          'L' : IF (RecNumToEdit <> NumEvents) THEN
                  RecNumToEdit := NumEvents
                ELSE
                BEGIN
                  Messages(3,0,'');
                  Cmd1 := #0;
                END;
          '?' : BEGIN
                  Print('%LF^1<^3CR^1>Redisplay screen');
                  Print('^3<Fill Me in:Modify item');
                  LCmds(20,3,'[Back entry',']Forward entry');
                  LCmds(20,3,'First entry in list','Jump to entry');
                  LCmds(20,3,'Last entry in list','Quit and save');
                END;
        END;
      UNTIL (Pos(Cmd1,'Q[]FJL') <> 0) OR (HangUp);
  END;

  PROCEDURE InsertEvent(TempEvent1: EventRecordType; Cmd1: Char; RecNumToInsertBefore: SmallInt);
  VAR
    RecNum,
    RecNumToEdit: SmallInt;
    Ok,
    Changed: Boolean;
  BEGIN
    IF (NumEvents = MaxEvents) THEN
      Messages(5,MaxEvents,'events')
    ELSE
    BEGIN
      RecNumToInsertBefore := -1;
      InputIntegerWOC('%LFEvent to insert before?',RecNumToInsertBefore,[NumbersOnly],1,(NumEvents + 1));
      IF (RecNumToInsertBefore >= 1) AND (RecNumToInsertBefore <= (NumEvents + 1)) THEN
      BEGIN
        Reset(EventFile);
        InitEventVars(TempEvent1);
        IF (RecNumToInsertBefore = 1) THEN
          RecNumToEdit := 1
        ELSE IF (RecNumToInsertBefore = (NumEvents + 1)) THEN
          RecNumToEdit := (NumEvents + 1)
        ELSE
          RecNumToEdit := RecNumToInsertBefore;
        REPEAT
          OK := TRUE;
          EditEvent(TempEvent1,TempEvent1,Cmd1,RecNumToEdit,Changed,FALSE);
          CheckEvent(TempEvent1,1,1,Ok);
          IF (NOT OK) THEN
            IF (NOT PYNQ('%LFContinue inserting event? ',0,TRUE)) THEN
              Abort := TRUE;
        UNTIL (OK) OR (Abort) OR (HangUp);
        IF (NOT Abort) AND (PYNQ('%LFIs this what you want? ',0,FALSE)) THEN
        BEGIN
          Print('%LF[> Inserting event record ...');
          Seek(EventFile,FileSize(EventFile));
          Write(EventFile,Event);
          Dec(RecNumToInsertBefore);
          FOR RecNum := ((FileSize(EventFile) - 1) - 1) DOWNTO RecNumToInsertBefore DO
          BEGIN
            Seek(EventFile,RecNum);
            Read(EventFile,Event);
            Seek(EventFile,(RecNum + 1));
            Write(EventFile,Event);
          END;
          FOR RecNum := RecNumToInsertBefore TO ((RecNumToInsertBefore + 1) - 1) DO
          BEGIN
            Seek(EventFile,RecNum);
            Write(EventFile,TempEvent1);
            Inc(NumEvents);
            SysOpLog('* Inserted event: ^5'+TempEvent1.EventDescription);
          END;
        END;
        Close(EventFile);
        LastError := IOResult;
      END;
    END;
  END;

  PROCEDURE ModifyEvent(TempEvent1: EventRecordType; Cmd1: Char; RecNumToEdit: SmallInt);
  VAR
    SaveRecNumToEdit: Integer;
    Ok,
    Changed: Boolean;
  BEGIN
    IF (NumEvents = 0) THEN
      Messages(4,0,'events')
    ELSE
    BEGIN
      RecNumToEdit := -1;
      InputIntegerWOC('%LFModify which event?',RecNumToEdit,[NumbersOnly],1,NumEvents);
      IF (RecNumToEdit >= 1) AND (RecNumToEdit <= NumEvents) THEN
      BEGIN
        SaveRecNumToEdit := -1;
        Cmd1 := #0;
        Reset(EventFile);
        WHILE (Cmd1 <> 'Q') AND (NOT HangUp) DO
        BEGIN
          IF (SaveRecNumToEdit <> RecNumToEdit) THEN
          BEGIN
            Seek(EventFile,(RecNumToEdit - 1));
            Read(EventFile,Event);
            SaveRecNumToEdit := RecNumToEdit;
            Changed := FALSE;
          END;
          REPEAT
            Ok := TRUE;
            EditEvent(TempEvent1,Event,Cmd1,RecNumToEdit,Changed,TRUE);
            CheckEvent(Event,1,1,Ok);
            IF (NOT OK) THEN
            BEGIN
              PauseScr(FALSE);
              IF (RecNumToEdit <> SaveRecNumToEdit) THEN
                RecNumToEdit := SaveRecNumToEdit;
            END;
          UNTIL (Ok) OR (HangUp);
          IF (Changed) THEN
          BEGIN
            Seek(EventFile,(SaveRecNumToEdit - 1));
            Write(EventFile,Event);
            Changed := FALSE;
            SysOpLog('* Modified event: ^5'+Event.EventDescription);
          END;
        END;
        Close(EventFile);
        LastError := IOResult;
      END;
    END;
  END;

  PROCEDURE PositionEvent(TempEvent1: EventRecordType; RecNumToPosition: SmallInt);
  VAR
    RecNumToPositionBefore,
    RecNum1,
    RecNum2: SmallInt;
  BEGIN
    IF (NumEvents = 0) THEN
      Messages(4,0,'events')
    ELSE IF (NumEvents = 1) THEN
      Messages(6,0,'events')
    ELSE
    BEGIN
      InputIntegerWOC('%LFPosition which event?',RecNumToPosition,[NumbersOnly],1,NumEvents);
      IF (RecNumToPosition >= 1) AND (RecNumToPosition <= NumEvents) THEN
      BEGIN
        Print('%LFAccording to the current numbering system.');
        InputIntegerWOC('%LFPosition before which event?',RecNumToPositionBefore,[Numbersonly],1,(NumEvents + 1));
        IF (RecNumToPositionBefore >= 1) AND (RecNumToPositionBefore <= (NumEvents + 1)) AND
           (RecNumToPositionBefore <> RecNumToPosition) AND (RecNumToPositionBefore <> (RecNumToPosition + 1)) THEN
        BEGIN
          Print('%LF[> Positioning event.');
          Reset(EventFile);
          IF (RecNumToPositionBefore > RecNumToPosition) THEN
            Dec(RecNumToPositionBefore);
          Dec(RecNumToPosition);
          Dec(RecNumToPositionBefore);
          Seek(EventFile,RecNumToPosition);
          Read(EventFile,TempEvent1);
          RecNum1 := RecNumToPosition;
          IF (RecNumToPosition > RecNumToPositionBefore) THEN
            RecNum2 := -1
          ELSE
            RecNum2 := 1;
          WHILE (RecNum1 <> RecNumToPositionBefore) DO
          BEGIN
            IF ((RecNum1 + RecNum2) < FileSize(EventFile)) THEN
            BEGIN
              Seek(EventFile,(RecNum1 + RecNum2));
              Read(EventFile,Event);
              Seek(EventFile,RecNum1);
              Write(EventFile,Event);
            END;
            Inc(RecNum1,RecNum2);
          END;
          Seek(EventFile,RecNumToPositionBefore);
          Write(EventFile,TempEvent1);
          Close(EventFile);
          LastError := IOResult;
        END;
      END;
    END;
  END;

  PROCEDURE ListEvents(VAR RecNumToList1: Integer);
  VAR
    NumDone: Integer;
  BEGIN
    IF (RecNumToList1 < 1) OR (RecNumToList1 > NumFileAreas) THEN
      RecNumToList1 := 1;
    Abort := FALSE;
    Next := FALSE;
    CLS;
    PrintACR('^0 ##^4:^3Description                   ^4:^3Typ^4:^3Bsy^4:^3Time ^4:^3Len^4:^3Days   ^4:^3Execinfo');
    PrintACR('^4 ==:==============================:===:===:=====:===:=======:============');
    Reset(EventFile);
    NumDone := 0;
    WHILE (NumDone < (PageLength - 5)) AND (RecNumToList1 >= 1) AND (RecNumToList1 <= NumEvents)
          AND (NOT Abort) AND (NOT HangUp) DO
    BEGIN
      Seek(EventFile,(RecNumToList1 - 1));
      Read(EventFile,Event);
      WITH Event DO
        PrintACR(AOnOff(EventIsActive IN EFlags,'^5+','^1-')+
                 '^0'+PadRightInt(RecNumToList1,2)+
                 ' ^3'+PadLeftStr(EventDescription,30)+
                 (*
                 ' '+SchedT(FALSE,EType)+
                 *)
                 ' ^5'+PadLeftInt(EventPreTime,3)+
                 ' '+Copy(CTim(EventStartTime),4,5));
                 (*
                 ' '+PadLeftInt(DurationOrLastDay,3)+
                 ' '+DActiv(FALSE,ExecDays,Monthly)+
                 ' ^3'+PadLeftStr(lExecData,9));
                 *)
      Inc(RecNumToList1);
      Inc(NumDone);
    END;
    Close(EventFile);
    LastError := IOResult;
    IF (NumEvents = 0) THEN
      Print('*** No events defined ***');
  END;


BEGIN
  IF (MemEventArray[Numevents] <> NIL) THEN
    FOR RecNumToList := 1 TO NumEvents DO
      IF (MemEventArray[RecNumToList] <> NIL) THEN
        Dispose(MemEventArray[RecNumToList]);
  SaveTempPause := TempPause;
  TempPause := FALSE;
  RecNumToList := 1;
  Cmd := #0;
  REPEAT
    IF (Cmd <> '?') THEN
      ListEvents(RecNumToList);
    LOneK('%LFEvent editor [^5?^4=^5Help^4]: ',Cmd,'QDIMP?'^M,TRUE,TRUE);
    CASE Cmd OF
      ^M  : IF (RecNumToList < 1) OR (RecNumToList > NumEvents) THEN
              RecNumToList := 1;
      'D' : DeleteEvent(TempEvent,RecNumToList);
      'I' : InsertEvent(TempEvent,Cmd,RecNumToList);
      'M' : ModifyEvent(TempEvent,Cmd,RecNumToList);
      'P' : PositionEvent(TempEvent,RecNumToList);
      '?' : BEGIN
              Print('%LF^1<^3CR^1>Next screen or redisplay current screen');
              Print('^1(^3?^1)Help/First event');
              LCmds(13,3,'Delete event','Insert event');
              LCmds(13,3,'Modify event','Position event');
              LCmds(13,3,'Quit','');
            END;
    END;
    IF (Cmd <> ^M) THEN
      RecNumToList := 1;
  UNTIL (Cmd = 'Q') OR (HangUp);
  TempPause := SaveTempPause;
  NumEvents := 0;
  Reset(EventFile);
  WHILE NOT EOF(EventFile) DO
  BEGIN
    Inc(NumEvents);
    New(MemEventArray[NumEvents]);
    Read(EventFile,MemEventArray[NumEvents]^);
  END;
  Close(EventFile);
  LastError := IOResult;
END;

END.
