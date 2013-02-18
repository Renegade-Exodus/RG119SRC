{$IFDEF WIN32}
{$I DEFINES.INC}
{$ENDIF}

{$A+,B-,D-,E-,F+,I-,L-,N-,O+,R-,S+,V-}

UNIT TimeFunc;

INTERFACE

USES
  Dos;

CONST
  MonthString: ARRAY [1..12] OF STRING[9] = ('January','February','March','April','May','June',
                                             'July','August','September','October','November','December');

TYPE
  Str2 = STRING[2];
  Str5 = STRING[5];
  Str8 = STRING[8];
  Str10 = STRING[10];
  Str160 = STRING[160];

PROCEDURE ConvertAmPm(VAR Hour: Word; VAR AmPm: Str2);
FUNCTION ZeroPad(S: Str8): Str2;
PROCEDURE PackToDate(VAR DT: DateTime; L: LongInt);
FUNCTION DateToPack(VAR DT: DateTime): LongInt;
PROCEDURE GetDateTime(VAR DT: DateTime);
PROCEDURE GetYear(VAR Year: Word);
PROCEDURE GetDayOfWeek(VAR DOW: Byte);
FUNCTION GetPackDateTime: LongInt;
FUNCTION DoorToDate8(CONST SDate: Str10): Str8;
FUNCTION PD2Time24(CONST PD: LongInt): Str5;
FUNCTION ToDate8(CONST SDate: Str10): Str8;
FUNCTION PDT2Dat(VAR PDT: LongInt; CONST DOW: Byte): STRING;
FUNCTION PD2Date(CONST PD: LongInt): STR10;
FUNCTION Date2PD(CONST SDate: Str10): LongInt;
FUNCTION TimeStr: Str8;
FUNCTION DateStr: Str10;
FUNCTION CTim(L: LongInt): Str8;
FUNCTION Days(VAR Month,Year: Word): Word;
FUNCTION DayNum(DateStr: Str10): Word;
FUNCTION Dat: Str160;

IMPLEMENTATION

CONST
  DayString: ARRAY [0..6] OF STRING[9] = ('Sunday','Monday','Tuesday','Wednesday','Thursday','Friday','Saturday');

  SecondsPerYear: ARRAY [FALSE..TRUE] OF LongInt = (31536000,31622400);

  M31 = (86400 * 31);
  M30 = (86400 * 30);
  M28 = (86400 * 28);

  SecondsPerMonth: ARRAY [1..12] OF LongInt = (M31,M28,M31,M30,M31,M30,M31,M31,M30,M31,M30,M31);

TYPE
  Str11 = STRING[11];

(* Done - Lee Palmer 11/23/07 *)
FUNCTION IntToStr(L: LongInt): Str11;
VAR
  S: Str11;
BEGIN
  Str(L,S);
  IntToStr := S;
END;

(* Done - Lee Palmer 12/06/07 *)
FUNCTION StrToInt(S: Str11): LongInt;
VAR
  I: Integer;
  L: LongInt;
BEGIN
  Val(S,L,I);
  IF (I > 0) THEN
  BEGIN
    S[0] := Chr(I - 1);
    Val(S,L,I)
  END;
  IF (S = '') THEN
    StrToInt := 0
  ELSE
    StrToInt := L;
END;

(* Done - Lee Palmer 03/27/07 *)
FUNCTION ZeroPad(S: Str8): Str2;
BEGIN
  IF (Length(s) > 2) THEN
    s := Copy(s,(Length(s) - 1),2)
  ELSE IF (Length(s) = 1) THEN
    s := '0'+s;
  ZeroPad := s;
END;

(* Done - 10/25/07 - Lee Palmer *)
PROCEDURE ConvertAmPm(VAR Hour: Word; VAR AmPm: Str2);
BEGIN
  IF (Hour < 12) THEN
    AmPm := 'am'
  ELSE
  BEGIN
    AmPm := 'pm';
    IF (Hour > 12) THEN
      Dec(Hour,12);
  END;
  IF (Hour = 0) THEN
    Hour := 12;
END;

PROCEDURE February(VAR Year: Word);
BEGIN
  IF ((Year MOD 4) = 0) THEN
    SecondsPerMonth[2] := (86400 * 29)
  ELSE
    SecondsPerMonth[2] := (86400 * 28);
END;

PROCEDURE PackToDate(VAR DT: DateTime; L: LongInt);
BEGIN
  DT.Year := 1970;
  WHILE (L < 0) DO
  BEGIN
    Dec(DT.Year);
    Inc(L,SecondsPerYear[((DT.Year MOD 4) = 0)]);
  END;
  WHILE (L >= SecondsPerYear[((DT.Year MOD 4) = 0)]) DO
  BEGIN
    Dec(L,SecondsPerYear[((DT.Year MOD 4) = 0)]);
    Inc(DT.Year);
  END;
  DT.Month := 1;
  February(DT.Year);
  WHILE (L >= SecondsPerMonth[DT.Month]) DO
  BEGIN
    Dec(L,SecondsPerMonth[DT.Month]);
    Inc(DT.Month);
  END;
  DT.Day := (Word(L DIV 86400) + 1);
  L := (L MOD 86400);
  DT.Hour := Word(L DIV 3600);
  L := (L MOD 3600);
  DT.Min := Word(L DIV 60);
  DT.Sec := Word(L MOD 60);
END;

FUNCTION DateToPack(VAR DT: DateTime): LongInt;
VAR
  Month,
  Year: Word;
  DTP: LongInt;
BEGIN
  DTP := 0;
  Inc(DTP,LongInt(DT.Day - 1) * 86400);
  Inc(DTP,LongInt(DT.Hour) * 3600);
  Inc(DTP,LongInt(DT.Min) * 60);
  Inc(DTP,LongInt(DT.Sec));
  February(DT.Year);
  FOR Month := 1 TO (DT.Month - 1) DO
    Inc(DTP,SecondsPerMonth[Month]);
  Year := DT.Year;
  WHILE (Year <> 1970) DO
  BEGIN
    IF (DT.Year > 1970) THEN
    BEGIN
      Dec(Year);
      Inc(DTP,SecondsPerYear[(Year MOD 4 = 0)]);
    END
    ELSE
    BEGIN
      Inc(Year);
      Dec(DTP,SecondsPerYear[((Year - 1) MOD 4 = 0)]);
    END;
  END;
  DateToPack := DTP;
END;

PROCEDURE GetDateTime(VAR DT: DateTime);
VAR
  DayOfWeek,
  HundSec: Word;
BEGIN
  GetDate(DT.Year,DT.Month,DT.Day,DayOfWeek);
  GetTime(DT.Hour,DT.Min,DT.Sec,HundSec);
END;

FUNCTION GetPackDateTime: LongInt;
VAR
  DT: DateTime;
BEGIN
  GetDateTime(DT);
  GetPackDateTime := DateToPack(DT);
END;

PROCEDURE GetYear(VAR Year: Word);
VAR
  Month,
  Day,
  DayOfWeek: Word;
BEGIN
  GetDate(Year,Month,Day,DayOfWeek);
END;

PROCEDURE GetDayOfWeek(VAR DOW: Byte);
VAR
  Year,
  Month,
  Day,
  DayOfWeek: Word;
BEGIN
  GetDate(Year,Month,Day,DayOfWeek);
  DOW := DayOfWeek;
END;

FUNCTION DoorToDate8(CONST SDate: Str10): Str8;
BEGIN
  DoorToDate8 := Copy(SDate,1,2)+'/'+Copy(SDate,4,2)+'/'+Copy(SDate,9,2);
END;

FUNCTION PD2Time24(CONST PD: LongInt): Str5;
VAR
  DT: DateTime;
BEGIN
  PackToDate(DT,PD);
  PD2Time24 := ZeroPad(IntToStr(DT.Hour))+':'+ZeroPad(IntToStr(DT.Min));
END;

FUNCTION PD2Date(CONST PD: LongInt): Str10;
VAR
  DT: DateTime;
BEGIN
  PackToDate(DT,PD);
  PD2Date := ZeroPad(IntToStr(DT.Month))+'-'+ZeroPad(IntToStr(DT.Day))+'-'+IntToStr(DT.Year);
END;

FUNCTION Date2PD(CONST SDate: Str10): LongInt;
VAR
  DT: DateTime;
BEGIN
  FillChar(DT,SizeOf(DT),0);
  DT.Sec := 1;
  DT.Year := StrToInt(Copy(SDate,7,4));
  DT.Day := StrToInt(Copy(SDate,4,2));
  DT.Month := StrToInt(Copy(SDate,1,2));
  IF (DT.Year = 0) THEN
    DT.Year := 1;
  IF (DT.Month = 0) THEN
    DT.Month := 1;
  IF (DT.Day = 0) THEN
    DT.Day := 1;
  Date2PD := DateToPack(DT);
END;

FUNCTION ToDate8(CONST SDate: Str10): Str8;
BEGIN
  IF (Length(SDate) = 8) THEN
    ToDate8 := SDate
  ELSE
    ToDate8 := Copy(SDate,1,6)+Copy(SDate,9,2);
END;

(* Done - Lee Palmer 11/23/07 *)
FUNCTION PDT2Dat(VAR PDT: LongInt; CONST DOW: Byte): STRING;
(* Example Output: 12:00 am  Fri Nov 23, 2007 *)
VAR
  DT: DateTime;
  AmPm: Str2;
BEGIN
  PackToDate(DT,PDT);
  ConvertAmPm(DT.Hour,AmPm);
  PDT2Dat := IntToStr(DT.Hour)+
            ':'+ZeroPad(IntToStr(DT.Min))+
            ' '+AmPm+
            '  '+Copy(DayString[DOW],1,3)+
            ' '+Copy(MonthString[DT.Month],1,3)+
            ' '+IntToStr(DT.Day)+
            ', '+IntToStr(DT.Year);
END;

FUNCTION TimeStr: Str8;
VAR
  AmPm: Str2;
  Hour,
  Minute,
  Second,
  Sec100: Word;
BEGIN
  GetTime(Hour,Minute,Second,Sec100);
  ConvertAmPm(Hour,AmPm);
  TimeStr := IntToStr(Hour)+':'+ZeroPad(IntToStr(Minute))+' '+AmPm;
END;

FUNCTION DateStr: Str10;
VAR
  Year,
  Month,
  Day,
  DayOfWeek: Word;
BEGIN
  GetDate(Year,Month,Day,DayOfWeek);
  DateStr := ZeroPad(IntToStr(Month))+'-'+ZeroPad(IntToStr(Day))+'-'+IntToStr(Year);
END;

FUNCTION CTim(L: LongInt): Str8;
VAR
  Hour,
  Minute,
  Second: Str2;
BEGIN
  Hour := ZeroPad(IntToStr(L DIV 3600));
  L := (L MOD 3600);
  Minute := ZeroPad(IntToStr(L DIV 60));
  L := (L MOD 60);
  Second := ZeroPad(IntToStr(L));
  CTim := Hour+':'+Minute+':'+Second;
END;

(* Done - 10/25/07 - Lee Palmer *)
FUNCTION Days(VAR Month,Year: Word): Word;
VAR
  TotalDayCount: Word;
BEGIN
  TotalDayCount := StrToInt(Copy('312831303130313130313031',(1 + ((Month - 1) * 2)),2));
  IF ((Month = 2) AND (Year MOD 4 = 0)) THEN
    Inc(TotalDayCount);
  Days := TotalDaycount;
END;

(* Done - 10/25/07 - Lee Palmer *)
FUNCTION DayNum(DateStr: Str10): Word;
(* Range 01/01/85 - 07/26/3061 = 0-65535 *)
VAR
  Day,
  Month,
  Year,
  YearCounter,
  TotalDayCount: Word;

  FUNCTION DayCount(VAR Month1,Year1: Word): Word;
  VAR
    MonthCounter,
    TotalDayCount1: Word;
  BEGIN
    TotalDayCount1 := 0;
    FOR MonthCounter := 1 TO (Month1 - 1) DO
      Inc(TotalDayCount1,Days(MonthCounter,Year1));
    DayCount := TotalDayCount1;
  END;

BEGIN
  TotalDayCount := 0;
  Month := StrToInt(Copy(DateStr,1,2));
  Day := StrToInt(Copy(DateStr,4,2));
  Year := StrToInt(Copy(DateStr,7,4));
  IF (Year < 1985) THEN
     DayNum := 0
  ELSE
  BEGIN
    FOR YearCounter := 1985 TO (Year - 1) DO
      IF (YearCounter MOD 4 = 0) THEN
        Inc(TotalDayCount,366)
      ELSE
        Inc(TotalDayCount,365);
    TotalDayCount := ((TotalDayCount + DayCount(Month,Year)) + (Day - 1));
    DayNum := TotalDayCount;
  END;
END;

(* Done - 10/25/07 - Lee Palmer *)
FUNCTION Dat: Str160;
VAR
  DT: DateTime;
  AmPm: Str2;
  DayOfWeek,
  Sec100: Word;
BEGIN
  GetDate(DT.Year,DT.Month,DT.Day,DayOfWeek);
  GetTime(DT.Hour,DT.Min,DT.Sec,Sec100);
  ConvertAmPm(DT.Hour,AmPm);
  Dat := IntToStr(DT.Hour)+
         ':'+ZeroPad(IntToStr(DT.Min))+
         ' '+AmPm+
         '  '+Copy(DayString[DayOfWeek],1,3)+
         ' '+Copy(MonthString[DT.Month],1,3)+
         ' '+IntToStr(DT.Day)+
         ', '+IntToStr(DT.Year);
END;


END.
