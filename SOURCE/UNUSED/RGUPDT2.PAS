{$M 49152,0,65536}
PROGRAM RGUPDT1;

USES
  Crt,
  Dos;

{$I RECORDS.PAS}

CONST
  DYNY: BOOLEAN = FALSE;

TYPE
  ConfRec =                { CONFRENC.DAT : Conference data }
{$IFDEF WIN32} PACKED {$ENDIF} RECORD
    Conference: ARRAY ['@'..'Z'] OF
  {$IFDEF WIN32} PACKED {$ENDIF} RECORD
      ACS: ACString;       { access requirement }
      Name: STRING[40];    { name of conference }
    END;
  END;

function sqoutsp(s:string):string;
begin
  while (pos(' ',s)>0) do delete(s,pos(' ',s),1);
  sqoutsp:=s;
end;

function exist(fn: astr): boolean;
var
  srec: searchrec;
begin
  findfirst(sqoutsp(fn),anyfile,srec);
  exist := (doserror = 0);
end;

FUNCTION SYN(B: BOOLEAN): STRING;
BEGIN
  IF (B) THEN
    SYN := 'Yes'
  ELSE
    SYN := 'No ';
END;

FUNCTION YN: BOOLEAN;
VAR
  C: CHAR;
BEGIN
  Write(SQOutSp(SYN(DYNY)));
  REPEAT
    C := UpCase(Char(ReadKey));
  UNTIL (C IN ['Y','N',^M]);
  IF (DYNY) AND (C <> 'N') THEN
    C := 'Y';
  IF (DYNY) AND (C = 'N') THEN
    Write(#8#8#8'No ')
  ELSE IF (NOT DYNY) AND (C = 'Y') THEN
    Write(#8#8'Yes');
  WriteLn;
  YN := (C = 'Y');
  DYNY := FALSE;
end;

FUNCTION PYNQ(CONST S: AStr): BOOLEAN;
BEGIN
  Write(S);
  PYNQ := YN;
END;

FUNCTION Caps(s: STRING): STRING;
VAR
  Counter: Integer;  { must be Integer }
BEGIN
  IF (s[1] IN ['a'..'z']) THEN
    Dec(s[1],32);
  FOR Counter := 2 TO Length(s) DO
    IF (s[Counter - 1] IN ['a'..'z','A'..'Z']) THEN
      IF (s[Counter] IN ['A'..'Z']) THEN
        Inc(s[Counter],32)
      ELSE
    ELSE
      IF (s[Counter] IN ['a'..'z']) THEN
        Dec(s[Counter],32);
  Caps := s;
END;

FUNCTION IntToStr(L: LongInt): STRING;
VAR
  S: STRING[11];
BEGIN
  Str(L,S);
  IntToStr := S;
END;

PROCEDURE ConvertConferenceFile(General: GeneralRecordType);
VAR
  ConferenceFile: FILE OF ConferenceRecordType;
  Conference: ConferenceRecordType;
  OldConferenceFile: FILE OF ConfRec;
  OldConference: ConfRec;
  C: Char;
BEGIN
  Write('Converting "CONFRENC.DAT" file ... ');
  Assign(OldConferenceFile,General.DataPath+'CONFRENC.DAT');
  Reset(OldConferenceFile);
  Assign(ConferenceFile,General.DataPath+'CONFRENC.NEW');
  ReWrite(ConferenceFile);
  Seek(OldConferenceFile,0);
  Read(OldConferenceFile,OldConference);
  FOR C := '@' TO 'Z' DO
  BEGIN
    WITH Conference DO
    BEGIN
      Key := C;
      IF (C = '@') THEN
        Name := 'General'
      ELSE
        Name := OldConference.Conference[C].Name;
      ACS := OldConference.Conference[C].ACS;
    END;
    IF (OldConference.Conference[C].Name <> '') THEN
      Write(ConferenceFile,Conference);
  END;
  Close(OldConferenceFile);
  Close(ConferenceFile);
  Assign(OldConferenceFile,General.DataPath+'CONFRENC.DAT');
  Erase(OldConferenceFile);
  Assign(ConferenceFile,General.DataPath+'CONFRENC.NEW');
  ReName(ConferenceFile,General.DataPath+'CONFRENC.DAT');
  WriteLn('Done');
END;

VAR
  GeneralFile: FILE OF GeneralRecordType;
  General: GeneralRecordType;

BEGIN
  ClrScr;
  WriteLn('Renegade Update Utility (08.04/8 to 08.12/8)');
  WriteLn;
  Writeln('This utility will upgrade your Renegade BBS from');
  WriteLn('Version 08.04/8 to Version 08.12/8.');
  WriteLn;
  IF PYNQ('Do you wish to continue? ') THEN
  BEGIN
    WriteLn;
    Write('Reading "RENEGADE.DAT" file ... ');
    Assign(GeneralFile,'RENEGADE.DAT');
    Reset(GeneralFile);
    Read(GeneralFile,General);
    Close(GeneralFile);
    WriteLn('Done');
    WriteLn;
    ConvertConferenceFile(General);
    WriteLn;
    WriteLn(^G^G^G'Conversion complete!');
    WriteLn;
    WriteLn('Please replace your old RENEGADE.EXE/RENEGADE.OVR files');
    WriteLn('with the new files provided with this update.');
  END;
END.
