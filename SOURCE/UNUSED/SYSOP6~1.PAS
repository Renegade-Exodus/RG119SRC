{$A+,B+,D+,E+,F+,I+,L+,N-,O+,R-,S+,V-}
UNIT SYSOP6;

INTERFACE

PROCEDURE EventEditor;

IMPLEMENTATION

USES
  Common;

PROCEDURE EventEditor;
VAR
  EventTypeStr,
  UserCmds,
  OneKCmds: Str160;
  Cmd: CHAR;
  Counter,
  Counter1,
  Counter2,
  RecNum: INTEGER;
  Abort,
  Next: BOOLEAN;

  FUNCTION DActive(ed: eventdaystype): Str160;
  CONST
    days: Str7 = 'MTWTFSS';
  VAR
    s1: Str160;
    i: INTEGER;
  BEGIN
    s1 := '';
    FOR i := 0 TO 6 DO
     IF (i IN ed) THEN
       s1 := s1+days[i + 1]
     ELSE
       s1 := s1+'-';
    DActive := s1;
  END;

  (*
  FUNCTION LastDay(dt: Str8): Str8;
  VAR
    D,M,Y: INTEGER;
  BEGIN
    M := StrToInt(Copy(dt,1,2));
    D := StrToInt(Copy(dt,4,2));
    Y := StrToInt(Copy(dt,7,2));
    IF (D = 1) AND (M = 1) THEN
    BEGIN
      IF (Y > 0) then
        dec(Y)
      ELSE
        Y := 99;
      M := 12;
      D := DaysInMonth(M,Y);
    END
    ELSE IF (D > 1) THEN
      Dec(D)
    ELSE IF (M > 1) THEN
    BEGIN
      Dec(M);
      D := DaysInMonth(M,Y);
    END;
    LastDay := ZeroPad(M)+'/'+ZeroPad(D)+'/'+ZeroPad(Y);
  END;
  *)
  (*
  FUNCTION NextDay(dt: Str8): Str8;
  VAR
    D,M,Y: integer;
  BEGIN
    M := StrToInt(Copy(dt,1,2));
    D := StrToInt(Copy(dt,4,2));
    Y := StrToInt(Copy(dt,7,2));
    IF (D = 31) AND (M = 12) THEN
    BEGIN
      IF (Y < 99) THEN
        Inc(y)
      ELSE
        Y := 0;
      M := 1;
      D := 1;
    END
    ELSE
    BEGIN
      IF (D < DaysInMonth(M,Y)) THEN
        Inc(D)
      ELSE IF (M < 12) THEN
      BEGIN
        Inc(M);
        D := 1;
      END;
    END;
    NextDay := ZeroPad(m)+'/'+ZeroPad(d)+'/'+ZeroPad(y);
  END;
  *)

  (*
  FUNCTION ShowTime(W: WORD): Str5;
  BEGIN
    ShowTime := ZeroPad(W DIV 60)+':'+ZeroPad(W MOD 60);
  END;
  *)

  PROCEDURE ToggleEventFlag(EventFlagT: EventFlagType; VAR EventFlagS: EFlagSet);
  BEGIN
    IF (EventFlagT IN EventFlagS) THEN
      Exclude(EventFlagS,EventFlagT)
    ELSE
      Include(EventFlagS,EventFlagT);
  END;

  PROCEDURE ToggleEventFlags(Flag: BYTE; VAR EventFlagS: EFlagSet);
  BEGIN
    CASE Flag OF
       2 : ToggleEventFlag(EventIsExternal,EventFlagS);
       3 : ToggleEventFlag(EventIsActive,EventFlagS);
       4 : ToggleEventFlag(EventIsShell,EventFlagS);
       5 : ToggleEventFlag(EventIsMonthly,EventFlagS);
       6 : ToggleEventFlag(EventIsPermission,EventFlagS);
       7 : ToggleEventFlag(EventIsChat,EventFlagS);
       8 : ToggleEventFlag(EventIsSoft,EventFlagS);
       9 : ToggleEventFlag(BaudIsActive,EventFlagS);
      10 : ToggleEventFlag(SLisActive,EventFlagS);
      11 : ToggleEventFlag(DSLisActive,EventFlagS);
      12 : ToggleEventFlag(ARisActive,EventFlagS);
      13 : ToggleEventFlag(InRatioIsActive,EventFlagS);
      14 : ToggleEventFlag(TimeIsActive,EventFlagS);
      15 : ToggleEventFlag(SetARisActive,EventFlagS);
      16 : ToggleEventFlag(ClearARisActive,EventFlagS);
    END;
  END;

  PROCEDURE EventRecordDelete(RecNum1: INTEGER);
  VAR
    Counter: INTEGER;
  BEGIN
    IF ((RecNum1 >= 1) AND (RecNum1 <= NumEvents)) THEN
    BEGIN
      IF (RecNum1 <= (FileSize(EventFile) - 2)) THEN
        FOR Counter := RecNum1 TO (FileSize(EventFile) - 2) DO
        BEGIN
          Seek(EventFile,(Counter + 1));
          Read(EventFile,Events);
          Seek(EventFile,Counter);
          Write(EventFile,Events);
        END;
      Seek(EventFile,(FileSize(EventFile) - 1));
      Truncate(EventFile);
      Dec(NumEvents);
    END;
  END;

  PROCEDURE EventRecordInsert(RecNum1: INTEGER);
  VAR
    Counter: Integer;
  BEGIN
    IF ((RecNum1 >= 1) AND (RecNum1 <= FileSize(EventFile)) AND (NumEvents < MaxEvents)) THEN
    BEGIN
      FOR Counter := (FileSize(EventFile) - 1) DOWNTO RecNum1 DO
      BEGIN
        Seek(EventFile,Counter);
        Read(EventFile,Events);
        Write(EventFile,Events);
      END;
      WITH Events DO
      BEGIN
        EFlags := [];
        EventDayOfMonth := 1;
        EventDays := [0..6];
        EventStartTime := 0;
        EventFinishTime := 0;
        EventDescription := '<<< New Event >>>';
        EventQualMsg := '';
        EventNotQualMsg := '';
        EventPreTime := 5;
        EventOffHookTime := 0 {FALSE};
        EventLastDate := DateStr;
        EventErrorLevel := 0;
        EventShellPath := '';
        LoBaud := 300;
        HiBaud := 19200;
        LoSL := 'S0';
        HiSL := 'S255';
        LoDSL := 'D0';
        HiDSL := 'D255';
        ARflagRequired := #0;
        MaxTimeAllowed := 60;
        SetARflag := #0;
        ClearARflag := #0;
      END;
      Seek(EventFile,RecNum1);
      Write(EventFile,Events);
      Inc(NumEvents);
    END;
  END;

  PROCEDURE EventRecordModify(VAR RecNum1: INTEGER);
  VAR
    TempS: Str160;
    Cmd1: CHAR;
    TempB: BYTE;
    SaveRecNum1: INTEGER;
    TempW,
    TempW1: WORD;
    Changed: BOOLEAN;
  BEGIN
    RecNum1 := -1;
    InputIntegerWoc('Record number to start editing',RecNum1,1,NumEvents);
    IF (RecNum1 <> -1) THEN
    BEGIN
      SaveRecNum1 := -1;
      Cmd1 := #0;
      WHILE (Cmd1 <> 'Q') AND (NOT HangUp) DO
      BEGIN
        IF (SaveRecNum1 <> RecNum1) THEN
        BEGIN
          Seek(EventFile,RecNum1);
          Read(EventFile,Events);
          SaveRecNum1 := RecNum1;
          Changed := FALSE;
        END;
        WITH Events DO
          REPEAT
            IF (Cmd1 <> '?') THEN
            BEGIN
              CLS;
              Print(#3'31.'#3'1 Event type            : '#3'5'+AOnOff(EventIsExternal IN EFlags,'External','Internal'));
              Print(#3'32.'#3'1 Description           : '#3'5'+EventDescription);
              Print(#3'33.'#3'1 Active                : '#3'5'+AOnOff(EventIsActive IN EFlags,'Active','Inactive'));
              IF (EventIsExternal IN EFlags) THEN
              BEGIN
                Print(#3'34.'#3'1 Execution hard/soft   : '#3'5'+AOnOff(EventIsSoft IN EFlags,'Soft','Hard'));
                Print(#3'35.'#3'1 Error level/shell file: '#3'5'+AOnOff(EventIsShell IN EFlags,
                                                   'Shell file = "'+eventshellpath+'"',
                                                   'Error level = '+IntToStr(EventErrorLevel)));
                Print(#3'36.'#3'1 Scheduled day(s)      : '#3'5'+AOnOff(EventIsMonthly IN EFlags,
                                                   'Monthly - Day = '+IntToStr(EventDayOfMonth),
                                                   'Weekly - Days = '+DActive(EventDays)));
                (*
                Print(#3'37.'#3'1 Start time            : '#3'5'+ShowTime(EventStartTime));
                *)
                Print(#3'38.'#3'1 Phone status          : '#3'5'+AOnOff(EventOffHookTime <> 0,
                                                   'Off-hook ('+IntToStr(eventpretime)+' minutes before the Event)',
                                                   'Remain on-hook'));
                Print(#3'39.'#3'1 Executed today        : '#3'5'+ShowYesNo(EventLastDate = DateStr)+' '
                                                          +AOnOff(EventIsActive IN EFlags,
                                                                  '(Next scheduled date:'+EventLastDate+' - in ??? minutes)',
                                                                  '(Not scheduled for execution)'));
              END
              ELSE
              BEGIN
                Print(#3'34.'#3'1 Scheduled day(s)      : '#3'5'+AOnOff(EventIsMonthly IN EFlags,
                                                   'Monthly - Day = '+IntToStr(EventDayOfMonth),
                                                   'Weekly - Days = '+DActive(EventDays)));
                (*
                Print(#3'35.'#3'1 Time active           : '#3'5'+ShowTime(EventStartTime)+' to '+
                                                         ShowTime(EventFinishTime));
                *)
                Print(#3'36.'#3'1 Permission/restriction: '#3'5'+AOnOff(EventIsPermission IN EFlags,
                      'Permission','Restriction'));
                Print(#3'37.'#3'1 Logon/chat            : '#3'5'+AOnOff(EventIsChat IN EFlags,'Chat','Logon'));
                Print(#3'38.'#3'1 Affected message      : "'#3'5'+eventqualmsg+#3'1"');
                Print(#3'39.'#3'1 Unaffected message    : "'#3'5'+eventnotqualmsg+#3'1"');
                NL;
                Print('       '#3'4<<<'#3'5 Qualifiers '#3'4>>>');
                NL;
                Print(#3'3A.'#3'1 Baud rate range  : '#3'5'+AOnOff(BaudIsActive IN EFlags,
                                                            IntToStr(LoBaud)+' to '+IntToStr(HiBaud),
                                                            '<<Inactive>>'));
                (*
                Print(#3'3B.'#3'1 SL range         : '#3'5'+AOnOff(SlIsActive IN EFlags,
                                                            IntToStr(LoSl)+' to '+IntToStr(HiSl),
                                                            '<<Inactive>>'));
                Print(#3'3C.'#3'1 DSL range        : '#3'5'+AOnOff(DslIsActive IN EFlags,
                                                            IntToStr(LoDsl)+' to '+IntToStr(HiDsl),
                                                            '<<Inactive>>'));
                *)
                IF (EventIsPermission IN EFlags) THEN
                  Print(#3'3D.'#3'1 Maximum time     : '#3'5'+AOnOff(TimeIsActive IN EFlags,
                                                            IntToStr(MaxTimeAllowed),
                                                            '<<Inactive>>'));
                Print(#3'3E.'#3'1 AR flag required : '#3'5'+AOnOff(ArIsActive IN EFlags,
                                                            ArFlagRequired,
                                                            '<<Inactive>>'));
                IF (EventIsPermission IN EFlags) THEN
                BEGIN
                  Print(#3'3F.'#3'1 Set AR flag      : '#3'5'+AOnOff(SetArIsActive IN EFlags,
                                                            SetArFlag,
                                                            '<<Inactive>>'));
                  Print(#3'3G.'#3'1 Clear AR flag    : '#3'5'+AOnOff(ClearArIsActive IN EFlags,
                                                            ClearArFlag,
                                                            '<<Inactive>>'));
                END;
                Print(#3'3H.'#3'1 UL/DL ratio check: '#3'5'+AOnOff(InRatioIsActive IN EFlags,
                                                            'Active',
                                                            '<<Inactive>>'));
              END;
            END;
            IF (EventIsExternal IN EFlags) THEN
            BEGIN
              EventTypeStr := 'EXTERNAL';
              UserCmds := '';
              OneKCmds := 'Q123456789';
            END
            ELSE
            BEGIN
              EventTypeStr := 'INTERNAL';
              IF (EventIsPermission IN EFlags) THEN
              BEGIN
                UserCmds := ',A-H';
                OneKCmds := 'ABCDEFGH';
              END
              ELSE
              BEGIN
                UserCmds := ',A-C,E,H';
                OneKCmds := 'ABCEH';
              END;
            END;
            NL;
            Prt('Modify '+EventTypeStr+' event: (1-9'+UserCmds+',Q=Quit): ');
            OneK(Cmd1,'Q123456789'+OneKCmds);
            IF (Cmd1 IN ['2','4'..'9','E'..'G']) THEN
              NL;
            CASE Cmd1 OF
              '1' : BEGIN
                      ToggleEventFlag(EventIsExternal,EFlags);
                      Changed := TRUE;
                    END;
              '2' : BEGIN
                      Prt('New description: ');
                      Mpl(32);
                      InputWn1(EventDescription,32,[],Changed);
                    END;
              '3' : BEGIN
                      ToggleEventFlag(EventIsActive,EFlags);
                      Changed := TRUE;
                    END;
              '4' : IF (EventIsExternal IN EFlags) THEN
                    BEGIN
                      ToggleEventFlag(EventIsSoft,EFlags);
                      Changed := TRUE;
                    END
                    ELSE
                    BEGIN
                      Prt('Schedule: (D:aily,M:onthly,Q:uit): ');
                      OneK(Cmd1,'QDM');
                      CASE Cmd1 OF
                        'D' : BEGIN
                                IF (EventIsMonthly IN EFlags) THEN
                                  Exclude(EFlags,EventIsMonthly);
                                REPEAT
                                  NL;
                                  Print('Active Days: '#3'5'+DActive(EventDays));
                                  NL;
                                  Prt('Toggle day: (1:Mon,2:Tue,3:Wed,4:Thu,5:Fri,6:Sat,7:Sun,Q:uit): ');
                                  OneK(Cmd1,'Q1234567');
                                  IF (Cmd1 <> 'Q') THEN
                                    IF (StrToInt(Cmd1) - 1 IN EventDays) THEN
                                      Exclude(EventDays,StrToInt(Cmd1) - 1)
                                    ELSE
                                      Include(EventDays,StrToInt(Cmd1) - 1);
                                UNTIL (Cmd1 = 'Q') OR (HangUp);
                                Cmd1 := #0;
                              END;
                        'M' : BEGIN
                                IF NOT (EventIsMonthly IN EFlags) THEN
                                  Include(EFlags,EventIsMonthly);
                                InputByteWC('Day of the month',EventDayOfMonth,[],1,31,Changed);
                              END;
                      END;
                      Cmd1 := #0;
                    END;
              '5' : IF (EventIsExternal IN EFlags) THEN
                    BEGIN
                      Prt('Excution method: (S:hell,E:rrorlevel,Q:uit): ');
                      OneK(Cmd1,'QSE');
                      CASE Cmd1 OF
                        'S' : BEGIN
                                IF NOT (EventIsShell IN EFlags) THEN
                                  Include(EFlags,EventIsShell);
                                NL;
                                Prt('Shell file: ');
                                Mpl(8);
                                InputWn1(eventshellpath,8,[upperonly],Changed);
                              END;
                        'E' : BEGIN
                                IF (EventIsShell IN EFlags) THEN
                                  Exclude(EFlags,EventIsShell);
                                TempB := 255;
                                InputByteWc('Error Level',TempB,[],0,255,Changed);
                                EventErrorLevel := TempB;
                              END;
                      END;
                      Cmd1 := #0;
                    END
                    ELSE
                    BEGIN
                      Prt('Event Start Time (HH:MM): ');
                      Mpl(5);
                      Input(TempS,5);
                      IF (TempS <> '') AND (Length(TempS) = 5) AND (Pos(':',TempS) = 3) THEN
                      BEGIN
                        TempW := StrToInt(Copy(TempS,1,2));
                        TempW1 := StrToInt(Copy(TempS,4,2));
                        IF (((TempW * 60) + TempW1) >= 0) AND (((TempW * 60) + TempW1) <= 1440) THEN
                        BEGIN
                          EventStartTime := (TempW * 60) + TempW1;
                          Changed := TRUE;
                        END
                        ELSE
                        BEGIN
                          NL;
                          Print(#3'5Invalid time - Format is HH:MM (24 hour military)');
                        END;
                      END;
                      NL;
                      Prt('Event Finish Time (HH:MM): ');
                      Mpl(5);
                      Input(TempS,5);
                      IF (TempS <> '') AND (Length(TempS) = 5) AND (Pos(':',TempS) = 3) THEN
                      BEGIN
                        TempW := StrToInt(Copy(TempS,1,2));
                        TempW1 := StrToInt(Copy(TempS,4,2));
                        IF (((TempW * 60) + TempW1) >= 0) AND (((TempW * 60) + TempW1) <= 1440) THEN
                        BEGIN
                          EventFinishTime := (TempW * 60) + TempW1;
                          Changed := TRUE;
                        END
                        ELSE
                        BEGIN
                          NL;
                          Print(#3'5Invalid time - Format is HH:MM (24 hour military)');
                        END;
                      END;
                    END;
              '6' : IF (EventIsExternal IN EFlags) THEN
                    BEGIN
                      Prt('Schedule: (D:aily,M:onthly,Q:uit): ');
                      OneK(Cmd1,'QDM');
                      CASE Cmd1 OF
                        'D' : BEGIN
                                IF (EventIsMonthly IN EFlags) THEN
                                  Exclude(EFlags,EventIsMonthly);
                                REPEAT
                                  NL;
                                  Print('Active Days: '#3'5'+DActive(EventDays));
                                  NL;
                                  Prt('Toggle day: (1:Mon,2:Tue,3:Wed,4:Thu,5:Fri,6:Sat,7:Sun,Q:uit): ');
                                  OneK(Cmd1,'Q1234567');
                                  IF (Cmd1 <> 'Q') THEN
                                    IF (StrToInt(Cmd1) - 1 IN EventDays) THEN
                                      Exclude(EventDays,StrToInt(Cmd1) - 1)
                                    ELSE
                                      Include(EventDays,StrToInt(Cmd1) - 1);
                                UNTIL (Cmd1 = 'Q') OR (HangUp);
                                Cmd1 := #0;
                              END;
                        'M' : BEGIN
                                IF NOT (EventIsMonthly IN EFlags) THEN
                                  Include(EFlags,EventIsMonthly);
                                InputByteWc('Day of the month',EventDayOfMonth,[],1,31,Changed);
                              END;
                      END;
                      Cmd1 := #0;
                    END
                    ELSE
                    BEGIN
                      ToggleEventFlag(EventIsPermission,EFlags);
                      Changed := TRUE;
                    END;
              '7' : IF (EventIsExternal IN EFlags) THEN
                    BEGIN
                      Prt('Event Start Time (HH:MM): ');
                      Mpl(5);
                      Input(TempS,5);
                      IF (TempS <> '') AND (Length(TempS) = 5) AND (Pos(':',TempS) = 3) THEN
                      BEGIN
                        TempW := StrToInt(Copy(TempS,1,2));
                        TempW1 := StrToInt(Copy(TempS,4,2));
                        IF (((TempW * 60) + TempW1) >= 0) AND (((TempW * 60) + TempW1) <= 1440) THEN
                        BEGIN
                          EventStartTime := (TempW * 60) + TempW1;
                          Changed := TRUE;
                        END
                        ELSE
                        BEGIN
                          NL;
                          Print(#3'5Invalid time - Format is HH:MM (24 hour military)');
                        END;
                      END;
                    END
                    ELSE
                    BEGIN
                      ToggleEventFlag(EventIsChat,EFlags);
                      Changed := TRUE;
                    END;
              '8' : IF (EventIsExternal IN EFlags) THEN
                    BEGIN
                      (*
                      IF (EventOffHookTime) THEN
                        EventOffHookTime := FALSE
                      ELSE
                      BEGIN
                        InputByteWc('Minutes before Event to take phone OffHook',eventpretime,[],0,255,3,Changed,TRUE);
                        EventOffHookTime := TRUE;
                      END;
                      *)
                    END
                    ELSE
                    BEGIN
                      Print('Message/@File if the user is effected by the event');
                      Prt(': ');
                      InputWn1(EventQualMsg,64,[],Changed);
                    END;
              '9' : IF (EventIsExternal IN EFlags) THEN
                    BEGIN
                      (*
                      IF (EventLastDate = DateStr) THEN
                        EventLastDate := NextDay(EventLastDate)
                      ELSE
                        EventLastDate := DateStr;
                      *)
                    END
                    ELSE
                    BEGIN
                      Print('Message/@File if the user IS NOT effected by the event');
                      Prt(': ');
                      InputWn1(EventNotQualMsg,64,[],Changed);
                    END;
              'A' : IF NOT (EventIsExternal IN EFlags) THEN
                    BEGIN
                      IF (BaudIsActive IN EFlags) THEN
                      BEGIN
                        Exclude(EFlags,BaudIsActive);
                        LoBaud := 300;
                        HiBaud := 19200;
                      END
                      ELSE
                      BEGIN
                        Include(EFlags,BaudIsActive);
                        InputLongIntWoc('Baud lower limit',LoBaud,0,65535);
                        InputLongIntWoc('Baud upper limit',HiBaud,0,65535);
                      END;
                      Changed := TRUE;
                    END;
              'B' : IF NOT (EventIsExternal IN EFlags) THEN
                    BEGIN
                      IF (SlIsActive IN EFlags) THEN
                      BEGIN
                        Exclude(EFlags,SlIsActive);
                        LoSl := 'S0';
                        HiSl := 'S255';
                      END
                      ELSE
                      BEGIN
                        Include(EFlags,SlIsActive);
                        (*
                        InputByteWoc('SL lower limit',LoSl,0,255);
                        InputByteWoc('SL upper limit',HiSl,0,255);
                        *)
                      END;
                      Changed := TRUE;
                    END;
              'C' : IF NOT (EventIsExternal IN EFlags) THEN
                    BEGIN
                      IF (DslIsActive IN EFlags) THEN
                      BEGIN
                        Exclude(EFlags,DslIsActive);
                        LoDsl := 'd0';
                        HiDsl := 'd255';
                      END
                      ELSE
                      BEGIN
                        Include(EFlags,DslIsActive);
                        (*
                        InputByteWoc('DSL lower limit',LoDsl,0,255);
                        InputByteWoc('DSL upper limit',HiDsl,0,255);
                        *)
                      END;
                      Changed := TRUE;
                    END;
              'D' : IF NOT (EventIsExternal IN EFlags) THEN
                      IF (EventIsPermission IN EFlags) THEN
                      BEGIN
                        IF (TimeIsActive IN EFlags) THEN
                        BEGIN
                          Exclude(EFlags,TimeIsActive);
                          MaxTimeAllowed := 60;
                        END
                        ELSE
                        BEGIN
                          Include(EFlags,TimeIsActive);
                          InputWordWoc('Maximum time allowed on-line (minutes)',MaxTimeAllowed,0,65535);
                        END;
                        Changed := TRUE;
                      END;
              'E' : IF NOT (EventIsExternal IN EFlags) THEN
                    BEGIN
                      IF (ArIsActive IN EFlags) THEN
                      BEGIN
                        Exclude(EFlags,ArIsActive);
                        ArFlagRequired := #0;
                      END
                      ELSE
                      BEGIN
                        Include(EFlags,ArIsActive);
                        Prt('AR flag required (A-Z): ');
                        Mpl(1);
                        OneK(Cmd1,'ABCDEFGHIJKLMNOPQRSTUVWXYZ');
                        ArFlagRequired := Cmd1;
                        Cmd1 := #0;
                      END;
                      Changed := TRUE;
                    END;
              'F' : IF NOT (EventIsExternal IN EFlags) THEN
                      IF (EventIsPermission IN EFlags) THEN
                      BEGIN
                        IF (SetArIsActive IN EFlags) THEN
                        BEGIN
                          Exclude(EFlags,SetArIsActive);
                          SetArFlag := #0;
                        END
                        ELSE
                        BEGIN
                          Include(EFlags,SetArIsActive);
                          Prt('AR flag to set (A-Z): ');
                          Mpl(1);
                          OneK(Cmd1,'ABCDEFGHIJKLMNOPQRSTUVWXYZ');
                          SetArFlag := Cmd1;
                          Cmd1 := #0;
                        END;
                        Changed := TRUE;
                      END;
              'G' : IF NOT (EventIsExternal IN EFlags) THEN
                      IF (EventIsPermission IN EFlags) THEN
                      BEGIN
                        IF (ClearArIsActive IN EFlags) THEN
                        BEGIN
                          Exclude(EFlags,ClearArIsActive);
                          ClearArFlag := #0;
                        END
                        ELSE
                        BEGIN
                          Include(EFlags,ClearArIsActive);
                          Prt('AR flag to clear (A-Z): ');
                          Mpl(1);
                          OneK(Cmd1,'ABCDEFGHIJKLMNOPQRSTUVWXYZ');
                          ClearArFlag := Cmd1;
                          Cmd1 := #0;
                        END;
                        Changed := TRUE;
                      END;
              'H' : IF NOT (EventIsExternal IN EFlags) THEN
                    BEGIN
                      IF (InRatioIsActive IN EFlags) THEN
                        Exclude(EFlags,InRatioIsActive)
                      ELSE
                        Include(EFlags,InRatioIsActive);
                      Changed := TRUE;
                    END;
            END;
          UNTIL (Cmd1 = 'Q') OR (HangUp);
        IF (Changed) THEN
        BEGIN
          Seek(EventFile,SaveRecNum1);
          Write(EventFile,Events);
          Changed := FALSE;
        END;
      END;
    END;
  END;

BEGIN
    Reset(EventFile);
    REPEAT
      CLS;
      (*
      TStr(419);
      *)
      Abort := FALSE;
      RecNum := 1;
      WHILE (RecNum <= NumEvents) AND NOT (Abort) AND NOT (HangUp) DO
      BEGIN
        Seek(EventFile,RecNum);
        Read(EventFile,Events);
        WITH Events DO
          PrintaCr(PadRightInt(RecNum,3)+
                   ' '#3'2'+PadRightStr(AOnOff(EventIsActive IN EFlags,'YES','NO'),6)+
                   ' '#3'5'+PadRightStr(EventDescription,32)+
                   ' '#3'3'+AOnOff(EventIsExternal IN EFlags,'External','Internal')+
                   (*
                   ' '#3'0'+ShowTime(EventStartTime)+
                   *)
                   (*
                   ' '#3'0'+AOnOff(EventIsExternal in EFlags,'-----',ShowTime(EventFinishTime))+
                   *)
                   ' '#3'4'+AOnOff(EventIsMonthly IN EFlags,'Day = '+IntToStr(EventDayOfMonth),DActive(EventDays)));
        Inc(RecNum);
      END;
      IF (NumEvents = 0) THEN
        Print('No Events Defined.');
      NL;
      Prt('Event Editor: (D:elete,I:nsert,M:odify,Q:uit): ');
      OneK(Cmd,'QDIM');
      CASE Cmd OF
        'D' : BEGIN
                RecNum := -1;
                InputIntegerWoc('Event number to delete',RecNum,1,NumEvents);
                IF (RecNum <> -1) THEN
                BEGIN
                  Seek(EventFile,RecNum);
                  Read(EventFile,Events);
                  NL;
                  Print('Event: '+Events.EventDescription);
                  NL;
                  IF PYNQ('Are you sure you want to delete it',0) THEN
                    EventRecordDelete(RecNum);
                END;
              END;
        'I' : IF (NumEvents = MaxEvents) THEN
              BEGIN
                NL;
                Print('No more then '+IntToStr(MaxEvents)+' events can exist.');
                PauseScr(FALSE);
              END
              ELSE
                EventRecordInsert(FileSize(EventFile));
        'M' : EventRecordModify(RecNum);
      END;
    UNTIL (Cmd = 'Q') OR (HangUp);
    Close(EventFile);
END;

END.

