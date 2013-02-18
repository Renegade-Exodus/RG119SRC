PROGRAM RGVERUDT;

USES
  CRT,
  Common1;

{$I RECORDS.PAS}

CONST
  DYNY: BOOLEAN = FALSE;

VAR
  GeneralFile: FILE OF GeneralRecordType;
  General: GeneralRecordType;
  VerStr: STRING;

function sqoutsp(s:string):string;
begin
  while (pos(' ',s)>0) do delete(s,pos(' ',s),1);
  sqoutsp:=s;
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

BEGIN
  ClrScr;
  WriteLn('Renegade Version Update Utility Version 1.0a');
  WriteLn;
  Writeln('This utility will upgrade the Renegade Data Files.');
  WriteLn;
  IF PYNQ('Do you wish to continue? ') THEN
  BEGIN
  {  WriteLn;
    WriteLn('Example: 07-12.8/Alpha');
    WriteLn;
    Write('Please enter the new version: ');
    Local_Input1(VerStr,20,TRUE);}
    VerStr := '1.19/Alpha';
    {IF (VerStr = '') THEN
      WriteLn(^G^G^G'Aborted!')
    ELSE
    BEGIN
      WriteLn;
      WriteLn('You entered '+VerStr);
      WriteLn;
      IF PYNQ('Is this what you want? ') THEN}
      BEGIN
        WriteLn;
        Write('Updating "RENEGADE.DAT" file ... ');
        Assign(GeneralFile,'RENEGADE.DAT');
        Reset(GeneralFile);
        Seek(GeneralFile,0);
        Read(GeneralFile,General);
        General.Version := VerStr;
        Seek(GeneralFile,0);
        Write(GeneralFile,General);
        Close(GeneralFile);
        WriteLn('Done');
        WriteLn;
        WriteLn(^G^G^G'Update complete!');
      END;
    END;

END.
