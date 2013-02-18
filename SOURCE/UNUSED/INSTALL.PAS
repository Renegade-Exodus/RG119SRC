{$M $4000,0,0 }   { 16K stack, no heap }
PROGRAM RGINSTAL;

USES
  Crt,
  Dos;

{$I records.pas}

CONST
  DYNY: BOOLEAN = FALSE;

VAR
  GeneralFile: FILE OF GeneralRecordType;
  General: GeneralRecordType;
  F: FILE;
  S: STRING;

function bslash(b: boolean; s: STRING): STRING;
begin
  if (b) then
  begin
    while (copy(s,(length(s) - 1),2) = '\\') do
      s := copy(s,1,(length(s) - 2));
    if (copy(s,length(s),1) <> '\') then
      s := s + '\';
  end
  else
    while (s[length(s)] = '\') do
      dec(s[0]);
  bslash := s;
end;

FUNCTION ExistDir(Fn: STRING): Boolean;
VAR
  DirInfo: SearchRec;
BEGIN
  Fn := BSlash(FALSE,FN);
  IF (Length(Fn) = 2) AND (Fn[2] = ':') THEN
    ExistDir := TRUE
  ELSE
  BEGIN
    findfirst(Fn,AnyFile,DirInfo);
    ExistDir := (DOSError = 0) AND (DirInfo.Attr AND $10 = $10);
  END;
END;

function sqoutsp(s: string):string;
begin
  while (pos(' ',s)>0) do
    delete(s,pos(' ',s),1);
  sqoutsp := s;
end;

function exist(fn: STRING): boolean;
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

FUNCTION PYNQ(CONST S: STRING): BOOLEAN;
BEGIN
  Write(S);
  PYNQ := YN;
END;

PROCEDURE UnArc(FileName,Path: STRING);
BEGIN
  SwapVectors;
  Exec('PKUNZIP.EXE','-EN '+FileName+' '+Path);
  SwapVectors;
END;

procedure Kill(const fn: STRING);
var
  f:file;
begin
  assign(f,fn);
  erase(f);
end;

function allcaps(s:string):string;
var
  i:integer;
begin
  for i:=1 to length(s) do
    if (s[i] in ['a'..'z']) then
      s[i] := chr(ord(s[i]) - ord('a')+ord('A'));
  allcaps:=s;
end;

BEGIN
  ClrScr;
  WriteLn('Renegade Version 1.10 Install Utility');
  WriteLn;
  WriteLn('This utility will install Renegade BBS Version 1.10.');
  WriteLn('Please make sure that PKUNZIP.EXE and this file are located');
  WriteLn('in the same directory as the archive RGV110.ZIP.');
  Writeln;
  WriteLn('You will only be asked to enter the main path for the BBS');
  WriteLn('directory.');
  WriteLn;
  IF PYNQ('Install Renegade BBS Version 1.10? ') THEN
  BEGIN
    Writeln;
    WriteLn('Please enter main path for the bbs (Example: C:\RG');
    Write(': ');
    ReadLn(S);
    IF (S <> '') THEN
    BEGIN
      S := AllCaps(S);
      IF (S[Length(S)] = '\') THEN
        Dec(S[0]);
      IF (S <> '') AND (NOT ExistDir(S)) THEN
        MkDir(S);
      IF (Exist(S+'\RENEGADE.DAT')) THEN
      BEGIN
        WriteLn;
        Writeln(^G^G^G'Renegade is already installed in directory "'+S+'"');
        Exit;
      END
      ELSE
      BEGIN
        UnArc('RGV10.ZIP',S);
        MkDir(S+'\ARCS');
        MkDir(S+'\DATA');
        MKDir(S+'\LOGS');
        MkDir(S+'\MISC');
        MkDir(S+'\MSGS');
        MkDir(S+'\NETFOSS');
        MkDir(S+'\PROTOCOL');
        UNArc(S+'\BBS.RGD',S);
        UnArc(S+'\DATA.RGD',S+'\DATA');
        UnArc(S+'\MISC.RGD',S+'\MISC');
        UnArc(S+'\MSGS.RGD',S+'\MSGS');
        UnArc(S+'\NETFOSS.RGD',S+'\NETFOSS');
        UnArc(S+'\PROT.RGD',S+'\PROTOCOL');
        Kill(S+'\BBS.RGD');
        Kill(S+'\DATA.RGD');
        Kill(S+'\MISC.RGD');
        Kill(S+'\MSGS.RGD');
        Kill(S+'\NETFOSS.RGD');
        Kill(S+'\PROT.RGD');
        Assign(GeneralFile,S+'\RENEGADE.DAT');
        Reset(GeneralFile);
        Seek(GeneralFile,0);
        Read(GeneralFile,General);
        WITH General Do
        BEGIN
          General.Version := '1.10';    (* <-- Update this with version *)
          DataPath := S+'\DATA\';
          MiscPath := S+'\MISC\';
          MsgPath := S+'\MSGS\';
          LogsPath := S+'\LOGS\';
          TempPath := S+'\TEMP\';
          ProtPath := S+'\PROTOCOL\';
          ArcsPath := S+'\ARCS\';
          FileAttachPath := S+'\TEMP\';
          MultPath := S+'\DATA\';
          NodePath := S+'\NODELIST\';
          NetMailPath := S+'\NETMAIL\';
          DefEchoPath := S+'\ECHOMAIL\';
        END;
        Seek(GeneralFile,0);
        Write(GeneralFile,General);
        Close(GeneralFile);
      END;
      Writeln;
      WriteLn(^G^G^G'Installation complete!');
    END;
  END;
END.
