UNIT RGApi;
{ Renegade Bulletin Board Software & Turbo Pascal/Borland Pascal API unit.  }
{  This unit uses commonly used routines in building a utility to work      }
{  with the Renegade BBS.                                                   }
{                                                                           }
{              Copyright 2003 - 2013 Chris Hoppman & T.J. McMillian         }

{

  This unit will be gave out and will there will never be a charge to use
  the API for Renegade.  This unit may be changed as wished and alter'd to
  suit the needs of the programmer that is using it.  Feel free to summit
  any changes or updates you might have for this unit to the Programmer of
  the Renegade BBS for thanks and for future releases of this API from other
  programmers

}

{
  Special thanks goes out to the orginal programmer (owner: see below)
  Copyright 1994 By Jeff Fanjoy and MatrixSoft(tm).  All Rights Reserved.
  Upon tring to contact and not being able to contact the authors we
  have decided to update and release new releases to the public ourselves.
  If the perivous owers would like for us to stop please let us know and
  we will comply with your wishes.  We regeat that we can't keep the orginal
  documention in as it's whole, because the lack of explaination of uses and
  the way to use the source.

  Here is a excert of the orginal documentation.
  "RGAPI is a PUBLIC DOMAIN product.  That means that anybody is free to
   modify and use this product at their own personal whim.  I would greatly
   appreciate it if myself and MatrixSoft(tm) were recognized in the
   documentation if this unit is used in any way."
}

{
  We would like to thank Swag for providing the RunTime Error Libary.
  Also, would like to thank the unknow author of the unit and if they
  wish to come forward and request for us to stop using the source we
  will respect the wishes of the author.

  Thank-you swag again for providing the Time Slice Routines.
}

INTERFACE

USES CRT,      {Turbo Pascal's standard CRT unit                       }
     DOS;      {Turbo Pascal's standard DOS unit                       }

{$I RECORDS.PAS}


{*** UNIX TIME CONVERSIONS *********************************************}

FUNCTION  LZero(W: Word) : String;
FUNCTION  GetTimeZone : ShortInt;
FUNCTION  IsLeapYear(Source : Word) : Boolean;
FUNCTION  Norm2Unix(Y, M, D, H, Min, S : Word) : LongInt;
PROCEDURE Unix2Norm(Date : LongInt; Var Y, M, D, H, Min, S : Word);
FUNCTION  TodayInUnix : LongInt;
FUNCTION  AddSlash(Str: String): String;

{*** RENEGADE COLOR CODE HANDLING **************************************}

FUNCTION  StripColor   ( Var InStr ): String;

{*** MISC ROUTINES *****************************************************}
function  IntToStr      ( IntIn: LongInt             ) : String;
function  StrToInt      ( InStr: String              ) : LongInt;
function  DirExists     ( InDir: DirStr              ) : Boolean;
function  FileExists    ( InFile: String             ) : Boolean;
procedure pipe          ( InStr : String             );
procedure pipexy        ( x,y : byte; instr : string );
procedure HandleError   ( ErrStr : String; ProgHalt : Boolean; StopWith : Byte );
function  takeoutblanks ( instr : string             ) : string;
function  detectOS : string;
procedure timeslice;
PROCEDURE FindRGDir;
{
function  InputStrxy ( x,y: byte      ) : string;
function  InputIntxy ( x,y: byte      ) : integer;


{*** RENEGADE.DAT ******************************************************}

PROCEDURE OpenRenegadeDat     ( Path: String; Var Err: Byte );
PROCEDURE ReadFromRenegadeDat ( Var RenegadeDatIn: GeneralRecordType; Var Err: Byte );
PROCEDURE WriteToRenegadeDat  ( Var RenegadeDatIn: GeneralRecordType; Var Err: Byte );
PROCEDURE CloseRenegadeDat;

{*** CONVERENC.DAT *****************************************************}

PROCEDURE OpenConferencDat     ( Path: String; Var Err: Byte );
PROCEDURE ReadFromConferencDat ( Var ConferencDatIn: ConferenceRecordType );
PROCEDURE WriteToConferencDat  ( Var ConferencDatIn: ConferenceRecordType );
PROCEDURE CloseConferencDat;

{*** SCHEME.DAT ********************************************************}

PROCEDURE OpenSchemeDat     ( Path: String; Var Err: Byte );
PROCEDURE ReadFromSchemeDat ( Var SchemeDatIn: SchemeRec  );
PROCEDURE WriteToSchemeDat  ( Var SchemeDatIn: SchemeRec  );
PROCEDURE CloseSchemeDat;

{*** MBASES.DAT ********************************************************}

PROCEDURE OpenMBasesDat     ( Path: String; Var Err: Byte              );
PROCEDURE ReadFromMBasesDat ( Var MBasesDatIn: MessageAreaRecordType; Rec: Integer  );
PROCEDURE WriteToMBasesDat  ( Var MBasesDatIn: MessageAreaRecordType; Rec: Integer  );
PROCEDURE CloseMBasesDat;

{*** *.HDR *************************************************************}

PROCEDURE OpenHdr     ( FileName: String; Path: String; Var Err: Byte );
PROCEDURE ReadFromHdr ( Var HdrIn: MHeaderRec; Rec: Integer           );
PROCEDURE WriteToHdr  ( Var HdrIn: MHeaderRec; Rec: Integer           );
PROCEDURE CloseHdr;

{*** *.DAT *************************************************************}

PROCEDURE OpenDat ( FileName: String; Path: String; Var Err: Byte );
PROCEDURE CloseDat;

{*** USERS.DAT *********************************************************}

PROCEDURE OpenUsersDat     ( Path: String; Var Err: Byte            );
PROCEDURE ReadFromUsersDat ( Var UsersDatIn: UserRecordType; Rec: Integer  );
PROCEDURE WriteToUsersDat  ( Var UsersDatIn: UserRecordType; Rec: Integer  );
PROCEDURE CloseUsersDat;

{*** USERS.IDX *********************************************************}
PROCEDURE OpenUsersIdx(Path: String; VAR Err: Byte);
PROCEDURE ReadFromUsersIdx(VAR UsersIdxIn: UserIdxRec; Rec: Integer);
PROCEDURE WriteToUsersIdx(VAR UsersIdxIn: UserIdxRec; Rec: Integer);
PROCEDURE CloseUsersIdx;

{*** HISTORY.DAT *******************************************************}

PROCEDURE OpenHistoryDat     ( Path: String; Var Err: Byte                );
PROCEDURE ReadFromHistoryDat ( Var HistoryDatIn: HistoryRecordType; Rec: Integer );
PROCEDURE WriteToHistoryDat  ( Var HistoryDatIn: HistoryRecordType; Rec: Integer );
PROCEDURE CloseHistoryDat;

{*** VOTING.DAT ********************************************************}

PROCEDURE OpenVotingDat     ( Path: String; Var Err: Byte            );
PROCEDURE ReadFromVotingDat ( Var VotingDatIn: VotingRecordType; Rec: Integer );
PROCEDURE WriteToVotingDat  ( Var VotingDatIn: VotingRecordType; Rec: Integer );
PROCEDURE CloseVotingDat;

{*** FBASES.DAT ********************************************************}

PROCEDURE OpenFBasesDat     ( Path: String; Var Err: Byte            );
PROCEDURE ReadFromFBasesDat ( Var FBasesDatIn: FileAreaRecordType; Rec: Integer   );
PROCEDURE WriteToFBasesDat  ( Var FBasesDatIn: FileAreaRecordType; Rec: Integer   );
PROCEDURE CloseFBasesDat;

{*** *.DIR *************************************************************}

PROCEDURE OpenDir     ( FileName: String; Path: String; Var Err: Byte );
PROCEDURE ReadFromDir ( Var DirIn: FileInfoRecordType; Rec: Integer               );
PROCEDURE WriteToDir  ( Var DirIn: FileInfoRecordType; Rec: Integer               );
PROCEDURE CloseDir;

{*** FILE DATE CONVERSION FROM STRING FORMAT ***************************}

PROCEDURE StrDate2FileDate ( S: String; Var Y: Word; Var M: Word; Var D: Word );

{*** EXTENDED.DAT ******************************************************}

PROCEDURE OpenExtendedDat     ( Path: String; Var Err: Byte              );
PROCEDURE ReadFromExtendedDat ( Var ExtendedDatIn: VerbRec; Rec: LongInt );
PROCEDURE WriteToExtendedDat  ( Var ExtendedDatIn: VerbRec; Rec: LongInt );
PROCEDURE CloseExtendedDat;

{*** LASTON.DAT ********************************************************}

PROCEDURE OpenLastOnDat     ( Path: String; Var Err: Byte                  );
PROCEDURE ReadFromLastOnDat ( Var LastOnDatIn: LastCallerRec; Rec: Integer );
PROCEDURE WriteToLastOnDat  ( Var LastOnDatIn: LastCallerRec; Rec: Integer );
PROCEDURE CloseLastOnDat;

{*** EVENTS.DAT ********************************************************}

PROCEDURE OpenEventsDat     ( Path: String; Var Err: Byte             );
PROCEDURE ReadFromEventsDat ( Var EventsDatIn: EventRec; Rec: Integer );
PROCEDURE WriteToEventsDat  ( Var EventsDatIn: EventRec; Rec: Integer );
PROCEDURE CloseEventsDat;

{*** PROTOCOL.DAT ******************************************************}

PROCEDURE OpenProtocolDat     ( Path: String; Var Err: Byte              );
PROCEDURE ReadFromProtocolDat ( Var ProtocolDatIn: ProtRec; Rec: Integer );
PROCEDURE WriteToProtocolDat  ( Var ProtocolDatIn: ProtRec; Rec: Integer );
PROCEDURE CloseProtocolDat;

{*** MULTNODE.DAT ******************************************************}

PROCEDURE OpenMultNodeDat     ( Path: String; Var Err: Byte              );
PROCEDURE ReadFromMultNodeDat ( Var MultNodeDatIn: NodeRec; Rec: Integer );
PROCEDURE WriteToMultNodeDat  ( Var MultNodeDatIn: NodeRec; Rec: Integer );
PROCEDURE CloseMultNodeDat;

{*** *.SCN *************************************************************}

PROCEDURE OpenScn     ( FileName: String; Path: String; Var Err: Byte );
PROCEDURE ReadFromScn ( Var ScnIn: ScanRec; Rec: Integer              );
PROCEDURE WriteToScn  ( Var ScnIn: ScanRec; Rec: Integer              );
PROCEDURE CloseScn;

{***********************************************************************}

CONST
   RGApiVer = '12-27.3 - DOS';
   RGApiAuthor = 'Bluewolf';
   MonthArray: Array[1..12] OF String[3] =
               ('Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct',
                'Nov','Dec');
   DowArray: Array[0..6] OF String[3] =
             ('Sun','Mon','Tue','Wed','Thu','Fri','Sat');

{*** USED BY UNIX-TIME CONVERTING PROCEDURES ***************************}

  DaysPerMonth :
    Array[1..12] of ShortInt =
    (031,028,031,030,031,030,031,031,030,031,030,031);
  DaysPerYear  :
    Array[1..12] of Integer  =
    (031,059,090,120,151,181,212,243,273,304,334,365);
  DaysPerLeapYear :
    Array[1..12] of Integer  =
    (031,060,091,121,152,182,213,244,274,305,335,366);
  SecsPerYear      : LongInt  = 31536000;
  SecsPerLeapYear  : LongInt  = 31622400;
  SecsPerDay       : LongInt  = 86400;
  SecsPerHour      : Integer  = 3600;
  SecsPerMinute    : ShortInt = 60;

(***************************************************************************)

type
  TaskRec = record
    OS      : Word;
    Version : Word; {writeln('Version ',hi(Version), '.', lo(Version) );}
    Delay   : Word;
  end;


const
  Task    : TaskRec = (
    OS      : 0;
    Version : 0;
    Delay   : 100
  );

Var
   OldExit      : Pointer;
   SchemeDat    : FILE of SchemeRec;
   MBasesDat    : FILE of MessageAreaRecordType;
   RenegadeDat  : FILE Of GeneralRecordType;
   StringDat    : FILE OF FStringRec;
   ConferencDat : FILE OF ConfRec;
   UsersDat     : FILE OF UserRecordType;
   Hdr          : FILE of MHeaderRec;
   HistoryDat   : FILE OF HistoryRec;
   Dat          : FILE;
   VotingDat    : FILE OF VotingR;
   FBasesDat    : FILE OF FileAreaRecordType;
   Dir          : FILE OF UlfRec;
   ExtendedDat  : FILE OF VerbRec;
   LastOnDat    : FILE OF LastCallerRec;
   EventsDat    : FILE OF EventRec;
   ProtocolDat  : FILE OF ProtRec;
   MultNodeDat  : FILE OF NodeRec;
   Scn          : FILE OF ScanRec;
   UsersIdx     : FILE OF UserIdxRec;

   RGDir        : String;
   CurrDir      : String;
   OSVer        : String;

IMPLEMENTATION

Procedure RunTimeExitProc;Far;
var Message : string;
begin
  if ErrorAddr<>Nil then { If error occurs }
    begin
        case ExitCode of { Pick the appropriate message }
            2:Message:='File not found ';
            3:Message:='Path not found ';
            4:Message:='Too many open files ';
            5:Message:='File access denied ';
            6:Message:='Invalid file handle ';
            8:Message:='Insufficient memory ';
           12:Message:='Invalid file access code ';
           15:Message:='Invalid drive number ';
           16:Message:='Cannot remove current directory ';
           17:Message:='Cannot rename across drives ';
          100:Message:='Disk read error ';
          100:Message:='Disk write error ';
          102:Message:='File not assigned ';
          103:Message:='File not open ';
          104:Message:='File not open for input ';
          105:Message:='File not open for output ';
          106:Message:='Invalid numeric format ';
          150:Message:='Disk is write-protected ';
          151:Message:='Unknown unit ';
          152:Message:='Drive not ready ';
          153:Message:='Unknown command ';
          154:Message:='CRC error in data ';
          155:Message:='Bad drive request structure length ';
          156:Message:='Disk seek error ';
          157:Message:='Unknown media type ';
          158:Message:='Sector not found ';
          159:Message:='Printer out of paper ';
          160:Message:='Device write fault ';
          161:Message:='Device read fault ';
          162:Message:='Hardware failure ';
          200:Message:='Division by zero ';
          201:Message:='Range check error ';
          202:Message:='Stack overflow error ';
          203:Message:='Heap overflow error ';
          204:Message:='Invalid pointer operation ';
          205:Message:='Floating-point overflow ';
          206:Message:='Floating-point underflow ';
          207:Message:='Invalid floating-point operation ';
          208:Message:='Overlay manager not installed ';
          209:Message:='Overlay file read error ';
          210:Message:='Object not initialized ';
          211:Message:='Call to abstract method ';
          212:Message:='Stream register error ';
          213:Message:='Collection index out of range ';
          214:Message:='Collection overflow error ';
        end;
      writeln;
      writeln('Error  : ',ExitCode,' - ',Message);
      writeln;

      ErrorAddr:=nil;
      ExitCode:=1;   { End program with errorlevel 1 }
    end;
  ExitProc:=OldExit; { Restore the original exit procedure }
end;

FUNCTION  AddSlash(Str: String): String;
BEGIN
   IF Str <> '' THEN
    BEGIN
       IF Str[Length(Str)] <> '\' THEN AddSlash := Str + '\'
       ELSE AddSlash := Str;
    END
   ELSE AddSlash := '';
END;


FUNCTION LZero( W: Word ) : String;
Var S1: String;
BEGIN
   Str(W:0,S1);
   IF LENGTH(S1) = 1 THEN S1 := '0' + S1;
   LZero := S1;
END;


FUNCTION GetTimeZone : ShortInt;
Var
   Environment : String;
   Index : Integer;
BEGIN
   GetTimeZone := 0;                            {Assume UTC}
   Environment := GetEnv('TZ');       {Grab TZ string}
   For Index := 1 TO Length(Environment) DO
    Environment[Index] := UpCase(Environment[Index]);
   IF Environment =  'EST05'    THEN GetTimeZone := -05; {USA EASTERN}
   IF Environment =  'EST05EDT' THEN GetTimeZone := -06;
   IF Environment =  'CST06'    THEN GetTimeZone := -06; {USA CENTRAL}
   IF Environment =  'CST06CDT' THEN GetTimeZone := -07;
   IF Environment =  'MST07'    THEN GetTimeZone := -07; {USA MOUNTAIN}
   IF Environment =  'MST07MDT' THEN GetTimeZone := -08;
   IF Environment =  'PST08'    THEN GetTimeZone := -08;
   IF Environment =  'PST08PDT' THEN GetTimeZone := -09;
   IF Environment =  'YST09'    THEN GetTimeZone := -09;
   IF Environment =  'AST10'    THEN GetTimeZone := -10;
   IF Environment =  'BST11'    THEN GetTimeZone := -11;
   IF Environment =  'CET-1'    THEN GetTimeZone :=  01;
   IF Environment =  'CET-01'   THEN GetTimeZone :=  01;
   IF Environment =  'EST-10'   THEN GetTimeZone :=  10;
   IF Environment =  'WST-8'    THEN GetTimeZone :=  08; {Perth, W. Aust.}
   IF Environment =  'WST-08'   THEN GetTimeZone :=  08;
END;

FUNCTION IsLeapYear( Source : Word ) : Boolean;
BEGIN
   IF (Source MOD 400 = 0) OR ((Source Mod 4 = 0) AND
      (Source MOD 100 <> 0)) THEN
    IsLeapYear := TRUE
   ELSE
    IsLeapYear := FALSE;
END;


FUNCTION Norm2Unix( Y,M,D,H,Min,S : Word ) : LongInt;
Var
  UnixDate : LongInt;
  Index    : Word;
BEGIN
  UnixDate := 0;                                                 {initialize}
  Inc(UnixDate,S);                                              {add seconds}
  Inc(UnixDate,(SecsPerMinute * Min));                          {add minutes}
  Inc(UnixDate,(SecsPerHour * H));                                {add hours}
  (*************************************************************************)
  (* If UTC = 0, and local time is -06 hours of UTC, then                  *)
  (* UTC := UTC - (-06 * SecsPerHour)                                      *)
  (* Remember that a negative # minus a negative # yields a positive value *)
  (*************************************************************************)
  UnixDate := UnixDate - (GetTimeZone * SecsPerHour);

  IF D > 1 THEN
    Inc(UnixDate,(SecsPerDay * (D-1)));

  IF IsLeapYear(Y) THEN
    DaysPerMonth[02] := 29
  ELSE
    DaysPerMonth[02] := 28;

  Index := 1;
  IF M > 1 THEN FOR Index := 1 TO (M-1) DO
    Inc(UnixDate,(DaysPerMonth[Index] * SecsPerDay));

  WHILE Y > 1970 DO
   BEGIN
      IF IsLeapYear((Y-1)) THEN
       Inc(UnixDate,SecsPerLeapYear)
      ELSE
       Inc(UnixDate,SecsPerYear);
      Dec(Y,1);
   END;

  Norm2Unix := UnixDate;
END;

PROCEDURE Unix2Norm( Date : LongInt; Var Y, M, D, H, Min, S : Word );
Var
   LocalDate : LongInt;
   Done      : Boolean;
   X         : ShortInt;
   TotDays   : Integer;
BEGIN
   Y   := 1970;
   M   := 1;
   D   := 1;
   H   := 0;
   Min := 0;
   S   := 0;
   LocalDate := Date + (GetTimeZone * SecsPerHour);
   Done := FALSE;
   WHILE NOT (Done) DO
    BEGIN
       IF LocalDate >= SecsPerYear THEN
        BEGIN
           Inc(Y,1);
           Dec(LocalDate,SecsPerYear);
        END
       ELSE
        Done := TRUE;
       IF (IsLeapYear(Y+1)) AND (LocalDate >= SecsPerLeapYear) AND
          (NOT (Done)) THEN
        BEGIN
           Inc(Y,1);
           Dec(LocalDate,SecsPerLeapYear);
        END;
    END;
   M := 1;
   D := 1;
   Done := FALSE;
   TotDays := LocalDate DIV SecsPerDay;
   IF IsLeapYear(Y) THEN
    BEGIN
       DaysPerMonth[02] := 29;
       X := 1;
       REPEAT
          IF (TotDays <= DaysPerLeapYear[x]) THEN
           BEGIN
              M := X;
              Done := TRUE;
              Dec(LocalDate,(TotDays * SecsPerDay));
              D := DaysPerMonth[M]-(DaysPerLeapYear[M]-TotDays) + 1;
           END
          ELSE
           Done := FALSE;
          Inc(X);
       UNTIL (Done) or (X > 12);
    END
   ELSE
    BEGIN
       DaysPerMonth[02] := 28;
       X := 1;
       REPEAT
          IF (TotDays <= DaysPerYear[x]) THEN
           BEGIN
              M := X;
              Done := TRUE;
              Dec(LocalDate,(TotDays * SecsPerDay));
              D := DaysPerMonth[M]-(DaysPerYear[M]-TotDays) + 1;
           END
          ELSE
           Done := FALSE;
          Inc(X);
       UNTIL Done = TRUE or (X > 12);
    END;
   H := LocalDate DIV SecsPerHour;
   Dec(LocalDate,(H * SecsPerHour));
   Min := LocalDate DIV SecsPerMinute;
   Dec(LocalDate,(Min * SecsPerMinute));
   S := LocalDate;
END;

FUNCTION TodayInUnix : LongInt;
Var
   Year, Month, Day, DayOfWeek: Word;
   Hour, Minute, Second, Sec100: Word;
BEGIN
   GetDate(Year, Month, Day, DayOfWeek);
   GetTime(Hour, Minute, Second, Sec100);
   TodayInUnix := Norm2Unix(Year,Month,Day,Hour,Minute,Second);
END;

FUNCTION StripColor( Var InStr ):String;
Var
   Temp: String;
   S: String Absolute InStr;
   I,
   Len: Integer;
BEGIN
   Len := Length(S);
   I := 1;
   Temp := '';
   REPEAT
      IF (S[I] = '|') THEN Inc(I,3)
      ELSE IF (S[I] = '^') THEN Inc(I,2)
      ELSE
       BEGIN
          Temp := Temp + S[I];
          Inc(I);
       END;
   UNTIL (I > Len);
   StripColor := Temp;
END;

function IntToStr( intin : longint) : string;
var s : string;
begin
    s:='';
    Str(intin, S);
    IntToStr := s;
end;

function StrToInt( InStr: String  ) : LongInt;
var i : longint;
 code : integer;
begin
    Val(InStr, I, Code);
    StrToInt := I;
end;



FUNCTION DirExists(inDir : dirstr) : boolean;
   var
     woFattr : word;
     fiTemp  : file;
   begin
     assign(fiTemp, (inDir + '.'));
     getfattr(fiTemp, woFattr);
     if (doserror <> 0) then DirExists := false
     else DirExists := ((woFattr and directory) <> 0)
   end;


function FileExists( inFile : string) : Boolean;
   var
     woFattr : word;
     fiTemp  : file;
   begin
     assign(fiTemp,inFile);
     getfattr(fiTemp, woFattr);
     if (doserror <> 0) then FileExists := false
     else FileExists := ((woFattr and Archive) <> 0)
   end;

PROCEDURE Pipe(InStr : String );
Var
   S      : String;
   I, Err : Integer;
   Col    : byte;
BEGIN
   S := InStr;
   I := 1;
   REPEAT
      IF (S[I] = '|') THEN
       BEGIN
          Val(COPY(S,I+1,2),Col,Err);
          IF (Err = 0) AND (Col IN [0..22]) THEN
             IF Col IN [0..15] THEN TextColor(Col)
             ELSE IF Col IN [16..22] THEN TextBackground(Col - 16);
          Inc(I,3);
       END
       ELSE BEGIN
          Write(S[I]);
          Inc(I);
       END;
   UNTIL (I > Length(S));
   Writeln;
END;

PROCEDURE Pipexy(x,y : byte; InStr : String );
BEGIN
  gotoxy(x,y);
  pipe(instr);
END;

{
  ErrStr   : String to display when a error occurs
  ProgHalt : 0: No, display the string and keep running
             1: Yes, stop the application
  HaltWith : if you want to halt the application you can
             provide a RunTime Error.
                                                         }
Procedure HandleError(ErrStr : String; ProgHalt : Boolean; StopWith : Byte );

 begin
   pipe('|11ú |12ERROR |11ú |14: |06#'++IntToStr(StopWith)+'|07');
   pipe(ErrStr+'|07');
   if ProgHalt then Halt(StopWith);
 end;

function takeoutblanks( instr : string) : string;
var t : string;
    a : byte;
begin
    t := '';
    for a := 1 to length(instr) do
      if instr[a] <> ' ' then t := t + instr[a];

    takeoutblanks := t;
end;

function  detectOS : string;
   Procedure InitMulti; Assembler;
   Asm
    mov  Task.OS, 0
    mov  Task.Version, 0
    mov  Ah, 30h
    mov  Al, 01h
    int  21h
    cmp  Al, 20
   je   @OS2

    mov  Ax, 160Ah
    int  2Fh
    cmp  Ax, 0
   je   @Windows

    mov  Ax, 1022h
    mov  Bx, 0000h
    int  15h
    cmp  Bx, 0
   jne  @DESQview


    mov  Ah, 2Bh
    mov  Al, 01h
    mov  Cx, 4445h
    mov  Dx, 5351h
    int  21h
    cmp  Al, $FF
   jne  @TopView

   jmp  @Fin

    @Windows:
     Mov  Task.OS, 1
     Mov  Task.Version, BX
     jmp  @Fin

    @OS2:
     Mov  Task.OS, 2
     Mov  Bh, Ah
     Xor  Ah, Ah
     Mov  Cl, 10
     Div  Cl
     Mov  Ah, Bh
     Xchg Ah, Al
     Mov  Task.Version, AX
    jmp  @Fin

    @DESQview:
     mov  Task.OS, 3
     jmp  @Fin

    @TopView:
     mov  Task.OS, 4

    @Fin:
   End;
begin
  InitMulti;
  case Task.OS of
     0 : detectOS := 'No MultiTasking';
     1 : detectOS := 'Windows';
     2 : detectOS := 'OS/2';
     3 : detectOS := 'DESQview';
     4 : detectOS := 'TopView';
  end;
end;
procedure TimeSlice;
var Regs : Registers;
   Procedure TimeSliceASM; Assembler;
    Asm
     cmp  Task.OS, 0
     je   @Fin
     cmp  Task.OS, 1
     je   @Win_OS2
     cmp  Task.OS, 2
     je   @Win_OS2
    @DV_TV:
     mov  Ax, 1000h
     int  15h
     jmp  @Fin
    @Win_OS2:
     mov  Ax, 1680h
     int  2Fh
    @Fin:
   End;

begin
  if Task.OS <> 0 then TimeSliceASM
  else  with Regs do Intr($28,Regs);
end;

PROCEDURE FindRGDir;
BEGIN
   GetDir(0,CurrDir);
   if paramstr(1) <> '' then RGDir := ParamStr(1);
   if (paramstr(1) = '') or (RGDir[2] <> ':') then RGDir := GetEnv('RENEGADE');
   if RGDir = '' then RGDir := GetEnv('RG');
   if RGDir = '' then RGDir := GetEnv('BBS');
   { work on more ..fexpand..
   if RGDir = '' then RGDir := FSearch('RENEGADE.DAT',GetEnv('PATH'))
    else if RGDir = '' then RGDir := FSearch('RENEGADE.EXE',GetEnv('PATH'));
   if RGDir = '' then RGDir := FSearch('RENEGADE.DAT',CurrDir)
    else if RGDir = '' then RGDir := FSearch('RENEGADE.EXE',CurrDir);
    }
   if (RGDir <> '') and (RGDir[length(RGDir)] <> '\') then RGDir := RGDir + '\';
   if (RGDir = '') or (not DirExists(RGDir)) then begin handleerror('þ Renegade.dat not found..',True,15); halt; end;
END;

PROCEDURE OpenRenegadeDat( Path: String; Var Err: Byte );
BEGIN
   If Path = '' then begin
      FindRGDir;
      if RGDir <> '' then Path := RGDir;
   end;
   Assign(RenegadeDat,AddSlash(Path) + 'RENEGADE.DAT');
   {$I-} Reset(RenegadeDat); {$I+}
   Err := IoResult;
END;

PROCEDURE ReadFromRenegadeDat( Var RenegadeDatIn: GeneralRecordType; Var Err: Byte );
BEGIN
   {$I-}Seek(RenegadeDat,0);{$I+}
   if ioresult = 0 then Read(RenegadeDat,RenegadeDatIn);
   Err := IOResult;
END;

PROCEDURE WriteToRenegadeDat(Var RenegadeDatIn: GeneralRecordType; Var Err: Byte );
BEGIN
   {$I-}Seek(RenegadeDat,0);{$I+}
   if ioresult = 0 then Write(RenegadeDat,RenegadeDatIn);
   Err := IOResult;
END;

PROCEDURE CloseRenegadeDat;
BEGIN
   Close(RenegadeDat);
END;

PROCEDURE OpenConferencDat(Path: String; Var Err: Byte);
BEGIN
   Assign(ConferencDat,AddSlash(Path) + 'CONFERENC.DAT');
   {$I-} Reset(ConferencDat); {$I+}
   Err := IoResult;
END;

PROCEDURE ReadFromConferencDat(Var ConferencDatIn: ConfRec);
BEGIN
   Seek(ConferencDat,0);
   Read(ConferencDat,ConferencDatIn);
END;

PROCEDURE WriteToConferencDat(Var ConferencDatIn: ConfRec);
BEGIN
   Seek(ConferencDat,0);
   Read(ConferencDat,ConferencDatIn);
END;

PROCEDURE CloseConferencDat;
BEGIN
   Close(ConferencDat);
END;

PROCEDURE OpenSchemeDat(Path: String; Var Err: Byte);

BEGIN
   Assign(SchemeDat,AddSlash(Path) + 'SCHEME.DAT');
   {$I-} Reset(SchemeDat); {$I+}
   Err := IoResult;
END;


PROCEDURE ReadFromSchemeDat(Var SchemeDatIn: SchemeRec);

BEGIN
   Seek(SchemeDat,0);
   Read(SchemeDat,SchemeDatIn);
END;


PROCEDURE WriteToSchemeDat(Var SchemeDatIn: SchemeRec);

BEGIN
   Seek(SchemeDat,0);
   Read(SchemeDat,SchemeDatIn);
END;


PROCEDURE CloseSchemeDat;

BEGIN
   Close(SchemeDat);
END;


PROCEDURE OpenMBasesDat(Path: String;
                        Var Err: Byte);

BEGIN
   Assign(MBasesDat,AddSlash(Path) + 'MBASES.DAT');
   {$I-} Reset(MBasesDat); {$I+}
   Err := IoResult;
END;


PROCEDURE ReadFromMBasesDat(Var MBasesDatIn: MessageAreaRecordType;
                        Rec: Integer);

BEGIN
   Seek(MBasesDat,Rec);
   Read(MBasesDat,MBasesDatIn);
END;


PROCEDURE WriteToMBasesDat(Var MBasesDatIn: MessageAreaRecordType;
                         Rec: Integer);

BEGIN
   Seek(MBasesDat,Rec);
   Write(MBasesDat,MBasesDatIn);
END;


PROCEDURE CloseMBasesDat;

BEGIN
   Close(MBasesDat);
END;


PROCEDURE OpenHdr(FileName: String;
                  Path: String;
                  Var Err: Byte);

BEGIN
   Assign(Hdr,AddSlash(Path) + FileName);
   {$I-} Reset(Hdr); {$I+}
   Err := IoResult;
END;


PROCEDURE ReadFromHdr(Var HdrIn: MHeaderRec;
                  Rec: Integer);

BEGIN
   Seek(Hdr,Rec);
   Read(Hdr,HdrIn);
END;


PROCEDURE WriteToHdr(Var HdrIn: MHeaderRec;
                   Rec: Integer);

BEGIN
   Seek(Hdr,Rec);
   Write(Hdr,HdrIn);
END;


PROCEDURE CloseHdr;

BEGIN
   Close(Hdr);
END;


PROCEDURE OpenDat(FileName: String;
                  Path: String;
                  Var Err: Byte);

BEGIN
   Assign(Dat,AddSlash(Path) + FileName);
   {$I-} Reset(Dat); {$I+}
   Err := IoResult;
END;


PROCEDURE CloseDat;

BEGIN
   Close(Dat);
END;


PROCEDURE OpenUsersDat(Path: String;
                       Var Err: Byte);

BEGIN
   Assign(UsersDat,AddSlash(Path) + 'USERS.DAT');
   {$I-} Reset(UsersDat); {$I+}
   Err := IoResult;
END;


PROCEDURE ReadFromUsersDat(Var UsersDatIn: UserRecordType;
                       Rec: Integer);

BEGIN
   Seek(UsersDat,Rec);
   Read(UsersDat,UsersDatIn);
END;


PROCEDURE WriteToUsersDat(Var UsersDatIn: UserRecordType;
                        Rec: Integer);

BEGIN
   Seek(UsersDat,Rec);
   Read(UsersDat,UsersDatIn);
END;


PROCEDURE CloseUsersDat;

BEGIN
   Close(UsersDat);
END;

{*** USERS.IDX *********************************************************}
PROCEDURE OpenUsersIdx(Path: String; VAR Err: Byte);
BEGIN
   Assign(UsersIdx,AddSlash(Path) + 'users.idx');
   {$I-} Reset(UsersIdx); {$I+}
   Err := IoResult;
END;
PROCEDURE ReadFromUsersIdx(VAR UsersIdxIn: UserIdxRec; Rec: Integer);
BEGIN
   Seek(UsersIdx,Rec);
   Read(UsersIdx,UsersIdxIn);
END;
PROCEDURE WriteToUsersIdx(VAR UsersIdxIn: UserIdxRec; Rec: Integer);
BEGIN
   Seek(UsersIdx,Rec);
   Write(UsersIdx,UsersIdxIn);
END;
PROCEDURE CloseUsersIdx;
BEGIN
   Close(UsersIdx);
END;




PROCEDURE OpenHistoryDat(Path: String;
                         Var Err: Byte);

BEGIN
   Assign(HistoryDat,AddSlash(Path) + 'HISTORY.DAT');
   {$I-} Reset(HistoryDat); {$I+}
   Err := IoResult;
END;


PROCEDURE ReadFromHistoryDat(Var HistoryDatIn: HistoryRec;
                         Rec: Integer);

BEGIN
   Seek(HistoryDat,Rec);
   Read(HistoryDat,HistoryDatIn);
END;


PROCEDURE WriteToHistoryDat(Var HistoryDatIn: HistoryRec;
                          Rec: Integer);

BEGIN
   Seek(HistoryDat,Rec);
   Write(HistoryDat,HistoryDatIn);
END;


PROCEDURE CloseHistoryDat;

BEGIN
   Close(HistoryDat);
END;


PROCEDURE OpenVotingDat(Path: String;
                        Var Err: Byte);

BEGIN
   Assign(VotingDat,AddSlash(Path) + 'VOTING.DAT');
   {$I-} Reset(VotingDat); {$I+}
   Err := IoResult;
END;


PROCEDURE ReadFromVotingDat(Var VotingDatIn: VotingR;
                        Rec: Integer);

BEGIN
   Seek(VotingDat,Rec);
   Read(VotingDat,VotingDatIn);
END;


PROCEDURE WriteToVotingDat(Var VotingDatIn: VotingR;
                         Rec: Integer);

BEGIN
   Seek(VotingDat,Rec);
   Read(VotingDat,VotingDatIn);
END;


PROCEDURE CloseVotingDat;

BEGIN
   Close(VotingDat);
END;

(* FBASES.DAT *)
PROCEDURE OpenFBasesDat(Path: String; Var Err: Byte);
BEGIN
   Assign(FBasesDat,AddSlash(Path) + 'FBASES.DAT');
   {$I-} Reset(FBasesDat); {$I+}
   Err := IoResult;
END;

PROCEDURE ReadFromFBasesDat(Var FBasesDatIn: FileAreaRecordType; Rec: Integer);
BEGIN
   Seek(FBasesDat,Rec);
   Read(FBasesDat,FBasesDatIn);
END;

PROCEDURE WriteToFBasesDat(Var FBasesDatIn: FileAreaRecordType; Rec: Integer);
BEGIN
   Seek(FBasesDat,Rec);
   Write(FBasesDat,FBasesDatIn);
END;

PROCEDURE CloseFBasesDat;

BEGIN
   Close(FBasesDat);
END;


PROCEDURE OpenDir(FileName: String;
                  Path: String;
                  Var Err: Byte);

BEGIN
   Assign(Dir,AddSlash(Path) + FileName);
   {$I-} Reset(Dir); {$I+}
   Err := IoResult;
END;


PROCEDURE ReadFromDir (Var DirIn: UlfRec; Rec: Integer );
BEGIN
   Seek(Dir,Rec);
   Read(Dir,DirIn);
END;

PROCEDURE WriteToDir ( Var DirIn: UlfRec; Rec: Integer );
BEGIN
   Seek(Dir,Rec);
   Write(Dir,DirIn);
END;


PROCEDURE CloseDir;
BEGIN
   Close(Dir);
END;


PROCEDURE StrDate2FileDate ( S: String; Var Y: Word; Var M: Word; Var D: Word );
Var Err: Integer;

BEGIN
   VAL(COPY(S,1,2),D,Err);
   VAL(COPY(S,4,2),M,Err);
   VAL(COPY(S,7,4),Y,Err);
END;


PROCEDURE OpenExtendedDat(Path: String;
                          Var Err: Byte);

BEGIN
   Assign(ExtendedDat,AddSlash(Path) + 'EXTENDED.DAT');
   {$I-} Reset(ExtendedDat); {$I+}
   Err := IoResult;
END;


PROCEDURE ReadFromExtendedDat(Var ExtendedDatIn: VerbRec;
                          Rec: LongInt);

BEGIN
   Seek(ExtendedDat,Rec);
   Read(ExtendedDat,ExtendedDatIn);
END;


PROCEDURE WriteToExtendedDat(Var ExtendedDatIn: VerbRec;
                           Rec: LongInt);

BEGIN
   Seek(ExtendedDat,Rec);
   Write(ExtendedDat,ExtendedDatIn);
END;


PROCEDURE CloseExtendedDat;

BEGIN
   Close(ExtendedDat);
END;


PROCEDURE OpenLastOnDat(Path: String;
                        Var Err: Byte);

BEGIN
   Assign(LastOnDat,AddSlash(Path) + 'LASTON.DAT');
   {$I-} Reset(LastOnDat); {$I+}
   Err := IoResult;
END;


PROCEDURE ReadFromLastOnDat(Var LastOnDatIn: LastCallerRec; Rec: Integer);
BEGIN
   Seek(LastOnDat,Rec);
   Read(LastOnDat,LastOnDatIn);
END;

PROCEDURE WriteToLastOnDat(Var LastOnDatIn: LastCallerRec; Rec: Integer);
BEGIN
   Seek(LastOnDat,Rec);
   Write(LastOnDat,LastOnDatIn);
END;

PROCEDURE CloseLastOnDat;
BEGIN
   Close(LastOnDat);
END;

PROCEDURE OpenEventsDat(Path: String; Var Err: Byte);
BEGIN
   Assign(EventsDat,AddSlash(Path) + 'EVENTS.DAT');
   {$I-} Reset(EventsDat); {$I+}
   Err := IoResult;
END;


PROCEDURE ReadFromEventsDat(Var EventsDatIn: EventRec;
                        Rec: Integer);

BEGIN
   Seek(EventsDat,Rec);
   Read(EventsDat,EventsDatIn);
END;


PROCEDURE WriteToEventsDat(Var EventsDatIn: EventRec;
                         Rec: Integer);

BEGIN
   Seek(EventsDat,Rec);
   Write(EventsDat,EventsDatIn);
END;


PROCEDURE CloseEventsDat;

BEGIN
   Close(EventsDat);
END;


PROCEDURE OpenProtocolDat(Path: String;
                          Var Err: Byte);

BEGIN
   Assign(ProtocolDat,AddSlash(Path) + 'PROTOCOL.DAT');
   {$I-} Reset(ProtocolDat); {$I+}
   Err := IoResult;
END;


PROCEDURE ReadFromProtocolDat(Var ProtocolDatIn: ProtRec;
                          Rec: Integer);

BEGIN
   Seek(ProtocolDat,Rec);
   Read(ProtocolDat,ProtocolDatIn);
END;


PROCEDURE WriteToProtocolDat(Var ProtocolDatIn: ProtRec;
                           Rec: Integer);

BEGIN
   Seek(ProtocolDat,Rec);
   Write(ProtocolDat,ProtocolDatIn);
END;


PROCEDURE CloseProtocolDat;

BEGIN
   Close(ProtocolDat);
END;


PROCEDURE OpenMultNodeDat(Path: String;
                          Var Err: Byte);

BEGIN
   Assign(MultNodeDat,AddSlash(Path) + 'MULTNODE.DAT');
   {$I-} Reset(MultNodeDat); {$I+}
   Err := IoResult;
END;


PROCEDURE ReadFromMultNodeDat(Var MultNodeDatIn: NodeRec;
                          Rec: Integer);

BEGIN
   Seek(MultNodeDat,Rec);
   Read(MultNodeDat,MultNodeDatIn);
END;


PROCEDURE WriteToMultNodeDat(Var MultNodeDatIn: NodeRec;
                           Rec: Integer);

BEGIN
   Seek(MultNodeDat,Rec);
   Write(MultNodeDat,MultNodeDatIn);
END;


PROCEDURE CloseMultNodeDat;

BEGIN
   Close(MultNodeDat);
END;


PROCEDURE OpenScn(FileName: String;
                  Path: String;
                  Var Err: Byte);

BEGIN
   Assign(Scn,AddSlash(Path) + FileName);
   {$I-} Reset(Scn); {$I+}
   Err := IoResult;
END;


PROCEDURE ReadFromScn(Var ScnIn: ScanRec;
                  Rec: Integer);

BEGIN
   Seek(Scn,Rec);
   Read(Scn,ScnIn);
END;


PROCEDURE WriteToScn(Var ScnIn: ScanRec;
                   Rec: Integer);

BEGIN
   Seek(Scn,Rec);
   Write(Scn,ScnIn);
END;


PROCEDURE CloseScn;

BEGIN
   Close(Scn);
END;


BEGIN
  OldExit:=ExitProc;          { Save the original exit procedure }
  ExitProc:=@RunTimeExitProc; { Insert the RunTime exit procedure }
  OSVer := detectOS;
END.

