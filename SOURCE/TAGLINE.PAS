{$IFDEF WIN32}
{$I DEFINES.INC}
{$ENDIF}

PROGRAM TAGLINE;

USES
  Crt,
  Dos;

TYPE
  StrPointerRec = RECORD
    Pointer,
    TextSize: LongInt;
  END;

VAR
  RGStrFile: FILE;
  StrPointerFile: FILE OF StrPointerRec;
  F: Text;
  StrPointer: StrPointerRec;
  S: STRING;
  RGStrNum,
  Counter: Word;

FUNCTION Exist(FN: STRING): Boolean;
VAR
  DirInfo: SearchRec;
BEGIN
  FindFirst(FN,AnyFile,DirInfo);
  Exist := (DosError = 0);
END;

BEGIN
  CLrScr;
  WriteLn('Renegade Tagline Compiler Version 1.1');
  Writeln('Copyright 2006-2009 - The Renegade Developement Team');
  WriteLn;
  IF (NOT Exist('TAGLINE.TXT')) THEN
    WriteLn(^G^G^G'TAGLINE.TXT file was not found!')
  ELSE
  BEGIN
    Counter := 0;
    Write('Checking maximum string length of 74 characters ... ');
    Assign(F,'TAGLINE.TXT');
    Reset(F);
    WHILE NOT EOF(F) DO
    BEGIN
      ReadLn(F,S);
      IF (Length(S) > 74) THEN
      BEGIN
        WriteLn;
        WriteLn;
        WriteLn('This string is longer then 74 characters:');
        WriteLn;
        Writeln(^G^G^G'-> '+S);
        WriteLn;
        WriteLn('Please reduce it''s length or delete from TAGLINE.TXT!');
        Halt;
      END;
      Inc(Counter);
    END;
    WriteLn('Done!');
    IF (Counter > 65535) THEN
    BEGIN
      WriteLn;
      WriteLn;
      WriteLn(^G^G^G'This file contains more then 65,535 lines');
      WriteLn;
      Writeln('Please reduce the number of lines in TAGLINE.TXT!');
      WriteLn;
      WriteLn('NOTE: Blank lines between Taglines are not required.');
      Writeln;
      Halt;
    END;
    WriteLn;
    Write('Compiling taglines ... ');
    Assign(StrPointerFile,'TAGLINE.PTR');
    ReWrite(StrPointerFile);
    Assign(RGStrFile,'TAGLINE.DAT');
    ReWrite(RGStrFile,1);
    Reset(F);
    WHILE NOT EOF(F) DO
    BEGIN
      ReadLn(F,S);
      IF (S <> '') THEN
      BEGIN
        WITH StrPointer DO
        BEGIN
          Pointer := (FileSize(RGStrFile) + 1);
          TextSize := 0;
        END;
        Seek(RGStrFile,FileSize(RGStrFile));
        Inc(StrPointer.TextSize,(Length(S) + 1));
        BlockWrite(RGStrFile,S,(Length(S) + 1));
        Seek(StrPointerFile,FileSize(StrPointerFile));
        Write(StrPointerFile,StrPointer);
      END;
    END;
    Close(F);
    Close(RGStrFile);
    Close(StrPointerFile);
    WriteLn('Done!')
  END;
END.
