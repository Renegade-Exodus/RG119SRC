{$IFDEF WIN32}
{$I DEFINES.INC}
{$ENDIF}

PROGRAM RGQUOTE;

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
  StrPointer: StrPointerRec;
  F: Text;
  S: STRING;
  RGStrNum: LongInt;
  Done,Found: Boolean;

FUNCTION AllCaps(S: STRING): STRING;
VAR
  I: Integer;
BEGIN
  FOR I := 1 TO Length(S) DO
    IF (S[I] IN ['a'..'z']) THEN
      S[I] := Chr(Ord(S[I]) - Ord('a')+Ord('A'));
  AllCaps := S;
END;

FUNCTION Exist(FN: STRING): Boolean;
VAR
  DirInfo: SearchRec;
BEGIN
  FindFirst(FN,AnyFile,DirInfo);
  Exist := (DosError = 0);
end;


BEGIN
  CLrScr;
  WriteLn('Renegade Quote String Compiler Version 1.0');
  Writeln('Copyright 2006 - The Renegade Developement Team');
  WriteLn;
  IF (ParamCount < 1) THEN
    Writeln(^G^G^G'Please specify a file name!')
  ELSE IF (Pos('.',ParamStr(1)) = 0) THEN
    WriteLn(^G^G^G'Please Specify a valid file name (Example: "Name.Ext")')
  ELSE IF (Length(ParamStr(1)) > 12) THEN
    Writeln(^G^G^G'The file name must not be longer then twelve characters!')
  ELSE IF (NOT Exist(ParamStr(1))) THEN
    WriteLn(^G^G^G'That file name was not found!')
  ELSE
  BEGIN
    S := ParamStr(1);
    Write('Compiling strings ... ');
    Found := TRUE;
    Assign(StrPointerFile,Copy(S,1,(Pos('.',S) - 1))+'.PTR');
    ReWrite(StrPointerFile);
    Assign(RGStrFile,Copy(S,1,(Pos('.',S) - 1))+'.DAT');
    ReWrite(RGStrFile,1);
    Assign(F,ParamStr(1));
    Reset(F);
    WHILE NOT EOF(F) DO
    BEGIN
      ReadLn(F,S);
      IF (S <> '') AND (S[1] = '$') THEN
      BEGIN
        Delete(S,1,1);
        S := AllCaps(S);
        Done := FALSE;
        WITH StrPointer DO
        BEGIN
          Pointer := (FileSize(RGStrFile) + 1);
          TextSize := 0;
        END;
        Seek(RGStrFile,FileSize(RGStrFile));
        WHILE NOT EOF(F) AND (NOT Done) DO
        BEGIN
          ReadLn(F,S);
          IF (S[1] = '$') THEN
            Done := TRUE
          ELSE
          BEGIN
            Inc(StrPointer.TextSize,(Length(S) + 1));
            BlockWrite(RGStrFile,S,(Length(S) + 1));
          END;
        END;
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