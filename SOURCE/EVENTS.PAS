{$IFDEF WIN32}
{$I DEFINES.INC}
{$ENDIF}

{$A+,B-,D+,E-,F+,I-,L+,N-,O+,R-,S+,V-}

UNIT Events;

INTERFACE

FUNCTION InTime(Tim,Tim1,Tim2: LongInt): Boolean;
FUNCTION CheckPreEventTime(EventNum: Integer; T: LongInt): Boolean;
FUNCTION CheckEventTime(EventNum: Integer; T: LongInt): Boolean;
FUNCTION CheckEvents(T: LongInt): Integer;
FUNCTION SysOpAvailable: Boolean;

IMPLEMENTATION

USES
  Dos,
  Common,
  TimeFunc
{$IFDEF WIN32}
  ,Windows
{$ENDIF}
  ;

FUNCTION InTime(Tim,Tim1,Tim2: LongInt): Boolean;
BEGIN
  InTime := TRUE;
  WHILE (Tim >= 86400) DO
    Dec(Tim,86400);
  IF (Tim1 <> Tim2) THEN
    IF (Tim2 > Tim1) THEN
      IF (Tim <= (Tim1 * 60)) OR (Tim >= (Tim2 * 60)) THEN
        InTime := FALSE
      ELSE
    ELSE
      IF (Tim <= (Tim1 * 60)) AND (Tim >= (Tim2 * 60)) THEN
        InTime := FALSE;
END;

(*
function checkeventday(i:integer; t:longint):boolean;
var
  year,month,day,dayofweek:word;
  e:integer;
begin
  e := 0;
  checkeventday := FALSE;
  if not events[i]^.active then
    exit;
  with events[i]^ do
  begin
    getdate(year,month,day,dayofweek);
    if (timer + t >= 86400.0) then
    begin
      inc(dayofweek);
      e := 1;
      if (dayofweek > 6) then
        dayofweek := 0;
    end;
    if (monthly) then
    begin
      if (value(copy(date,4,2)) + e = execdays) then
        checkeventday := TRUE;
    end
    else
    begin
      e := 1 shl (dayofweek + 1);
      if (execdays and e = e) then
        checkeventday:=TRUE;
    end;
  end;
end;
*)

FUNCTION lCheckEventDay(EventNum: Integer; T: LongInt): Boolean;
VAR
  DayOfWeek,
  Day: Byte;
BEGIN

  lCheckEventDay := FALSE;
  WITH MemEventArray[EventNum]^ DO
  BEGIN
    IF (NOT (EventIsActive IN EFlags)) THEN
      Exit;
    Day := 0;
    GetDayOfWeek(DayOfWeek);
    IF ((Timer + T) >= 86400) THEN
    BEGIN
      Inc(DayOfWeek);
      IF (DayOfWeek > 6) THEN
        DayOfWeek := 0;
      Day := 1;
    END;
    IF (EventIsMonthly IN EFlags) THEN
    BEGIN
      IF ((StrToInt(Copy(DateStr,4,2)) + Day) = MemEventArray[EventNum]^.EventDayOfMonth) THEN
        lCheckEventDay := TRUE;
    END
    ELSE IF (DayOfWeek IN EventDays) THEN
      lCheckEventDay := TRUE;
  END;
END;

(*
function checkpreeventtime(i:integer; t:longint):boolean;
begin
  with events[i]^ do
    if (offhooktime = 0) or
       (durationorlastday=daynum(date)) or
       ((Enode > 0) and (Enode <> node)) or
       (not events[i]^.active) or not
       (checkeventday(i,t)) then
      checkpreeventtime:=FALSE
    else
      checkpreeventtime:=intime(timer+t,exectime-offhooktime,exectime);
end;
*)

FUNCTION CheckPreEventTime(EventNum: Integer; T: LongInt): Boolean;

BEGIN
  WITH MemEventArray[EventNum]^ DO
    IF (NOT (EventIsActive IN EFlags)) OR
       (EventPreTime = 0) OR
       (PD2Date(EventLastDate) = DateStr) OR
       ((EventNode > 0) AND (EventNode <> ThisNode)) OR
       NOT (lCheckEventDay(EventNum,T)) THEN
      CheckPreEventTime := FALSE
    ELSE
      CheckPreEventTime := InTime((Timer + T),(EventStartTime - EventPreTime),EventStartTime);
      (*
      checkpreeventtime := intime(timer + t,exectime-offhooktime,exectime);
      *)
END;

(*
function checkeventtime(i:integer; t:longint):boolean;
begin
  with events[i]^ do
    if (durationorlastday=daynum(date)) or
       ((Enode > 0) and (Enode <> node)) or
       (not events[i]^.active) or not
       (checkeventday(i,t)) then
      checkeventtime:=FALSE
    else
      if (etype in ['A','C']) then
        checkeventtime:=intime(timer+t,exectime,exectime+durationorlastday)
      else
        if (missed) then
          checkeventtime := (((timer + t) div 60) > exectime)
        else
          checkeventtime := (((timer + t) div 60) = exectime);
end;
*)

FUNCTION CheckEventTime(EventNum: Integer; T: LongInt): Boolean;
BEGIN
  WITH MemEventArray[EventNum]^ DO
    IF (PD2Date(EventLastDate) = DateStr) OR
       ((EventNode > 0) AND (EventNode <> ThisNode)) OR
       (NOT (EventIsActive IN EFlags)) OR
       NOT (lCheckEventDay(EventNum,T)) THEN
      CheckEventTime := FALSE
    ELSE
      IF (EventIsLogon IN EFlags) OR (EventIsChat IN EFlags) THEN
        CheckEventTime := InTime((Timer + T),EventStartTime,(EventStartTime + EventFinishTime))
        (*
        checkeventtime := intime(timer + t,exectime,exectime+durationorlastday)
        *)
      ELSE
        IF (EventIsMissed IN EFlags) THEN
          CheckEventTime := (((Timer + T) DIV 60) > EventStartTime)
        ELSE
          CheckEventTime := (((Timer + T) DIV 60) = EventStartTime);
END;

(*
function checkevents(t:longint):integer;
var i:integer;
begin
  for i := 1 to numevents do
    with events[i]^ do
      if (active) and ((Enode = 0) or (Enode = node)) then
        if (checkeventday(i,t)) then begin
           if (softevent) and (not inwfcmenu) then
             checkevents:=0
           else
             checkevents:=i;
           if (checkpreeventtime(i,t)) or (checkeventtime(i,t)) then begin
             if (etype in ['D','E','P']) then exit;
             if ((etype='A') and (not aacs(execdata)) and (useron)) then exit;
           end;
        end;
  checkevents:=0;
end;
*)

FUNCTION CheckEvents(T: LongInt): Integer;
VAR
  EventNum: Integer;
BEGIN
  FOR EventNum := 1 TO NumEvents DO
    WITH MemEventArray[EventNum]^ DO
      IF (EventIsActive IN EFlags) AND ((EventNode = 0) OR (EventNode = ThisNode)) THEN
        IF (lCheckEventDay(EventNum,T)) THEN
        BEGIN
          IF (EventIsSoft IN EFlags) AND (NOT InWFCMenu) THEN
            CheckEvents := 0
          ELSE
            CheckEvents := EventNum;
          IF (CheckPreEventTime(EventNum,T)) OR (CheckEventTime(EventNum,T)) THEN
          BEGIN
            IF (EventIsExternal IN EFlags) THEN
              IF (EventIsShell IN EFlags) OR
                 (EventIsErrorLevel IN EFlags) OR
                 (EventIsPackMsgAreas IN EFlags) OR
                 (EventIsSortFiles IN EFlags) OR
                 (EventIsFilesBBS IN EFlags) THEN
              Exit;
            IF ((EventIsLogon IN EFlags) AND (NOT AACS(EventACS)) AND (UserOn)) THEN
              Exit;
          END;
        END;
  CheckEvents := 0;
END;

FUNCTION SysOpAvailable: Boolean;
VAR
{$IFDEF MSDOS}
  A: Byte ABSOLUTE $0000:$0417;
{$ENDIF}
  EventNum: Integer;
  ChatOk: Boolean;
BEGIN
{$IFDEF MSDOS}
  ChatOk := ((A AND 16) = 0);
{$ENDIF}
{$IFDEF WIN32}
  // Availability is togged with scroll lock key
  ChatOk := (GetKeyState($91) and $ffff) <> 0;
{$ENDIF}  

  IF (RChat IN ThisUser.Flags) THEN
    ChatOk := FALSE;

  FOR EventNum := 1 TO NumEvents DO
    WITH MemEventArray[EventNum]^ DO
      IF (EventIsActive IN EFlags) AND (EventIsChat IN EFlags) AND (CheckEventTime(EventNum,0)) THEN
        ChatOk := TRUE;

  SysOpAvailable := ChatOk;
END;

END.
