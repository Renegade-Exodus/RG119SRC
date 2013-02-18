{$IFDEF WIN32}
{$I DEFINES.INC}
{$ENDIF}

{$A+,B-,D+,E-,F+,I-,L+,N-,O+,R-,S-,V-}

UNIT Common1;

INTERFACE

FUNCTION CheckPW: Boolean;
PROCEDURE NewCompTables;
PROCEDURE Wait(b: Boolean);
PROCEDURE InitTrapFile;
PROCEDURE Local_Input1(VAR S: STRING; MaxLen: Byte; LowerCase: Boolean);
PROCEDURE Local_Input(VAR S: STRING; MaxLen: Byte);
PROCEDURE Local_InputL(VAR S: STRING; MaxLen: Byte);
PROCEDURE Local_OneK(VAR C: Char; S: STRING);
PROCEDURE SysOpShell;
PROCEDURE ReDrawForANSI;

IMPLEMENTATION

USES
  Crt,
  Common,
  File0,
  Mail0,
  TimeFunc;

FUNCTION CheckPW: Boolean;
VAR
  Password: STR20;
BEGIN
  IF (NOT General.SysOpPWord) OR (InWFCMenu) THEN
  BEGIN
    CheckPW := TRUE;
    Exit;
  END;
  CheckPW := FALSE;
  { Prompt(FString.SysOpPrompt); }
  lRGLngStr(33,FALSE);
  GetPassword(Password,20);
  IF (Password = General.SysOpPW) THEN
    CheckPW := TRUE
  ELSE IF (InCom) AND (Password <> '') THEN
    SysOpLog('--> SysOp Password Failure = '+Password+' ***');
END;

PROCEDURE NewCompTables;
VAR
  FileCompArrayFile: FILE OF CompArrayType;
  MsgCompArrayFile: FILE OF CompArrayType;
  CompFileArray: CompArrayType;
  CompMsgArray: CompArrayType;
  Counter,
  Counter1,
  Counter2,
  SaveReadMsgArea,
  SaveReadFileArea: Integer;
BEGIN
  SaveReadMsgArea := ReadMsgArea;
  SaveReadFileArea := ReadFileArea;
  Reset(FileAreaFile);
  IF (IOResult <> 0) THEN
  BEGIN
    SysOpLog('Error opening FBASES.DAT (Procedure: NewCompTables)');
    Exit;
  END;
  NumFileAreas := FileSize(FileAreaFile);
  Assign(FileCompArrayFile,TempDir+'FACT'+IntToStr(ThisNode)+'.DAT');
  ReWrite(FileCompArrayFile);
  CompFileArray[0] := 0;
  CompFileArray[1] := 0;
  FOR Counter := 1 TO FileSize(FileAreaFile) DO
    Write(FileCompArrayFile,CompFileArray);
  Reset(FileCompArrayFile);
  IF (NOT General.CompressBases) THEN
  BEGIN
    FOR Counter := 1 TO FileSize(FileAreaFile) DO
    BEGIN
      Seek(FileAreaFile,(Counter - 1));
      Read(FileAreaFile,MemFileArea);
      IF (NOT AACS(MemFileArea.ACS)) THEN
      BEGIN
        CompFileArray[0] := 0;
        CompFileArray[1] := 0;
      END
      ELSE
      BEGIN
        CompFileArray[0] := Counter;
        CompFileArray[1] := Counter;
      END;
      Seek(FileCompArrayFile,(Counter - 1));
      Write(FileCompArrayFile,CompFileArray);
    END;
  END
  ELSE
  BEGIN
    Counter2 := 0;
    Counter1 := 0;
    FOR Counter := 1 TO FileSize(FileAreaFile) DO
    BEGIN
      Seek(FileAreaFile,(Counter - 1));
      Read(FileAreaFile,MemFileArea);
      Inc(Counter1);
      IF (NOT AACS(MemFileArea.ACS)) THEN
      BEGIN
        Dec(Counter1);
        CompFileArray[0] := 0;
      END
      ELSE
      BEGIN
        CompFileArray[0] := Counter1;
        Seek(FileCompArrayFile,(Counter - 1));
        Write(FileCompArrayFile,CompFileArray);
        Inc(Counter2);
        Seek(FileCompArrayFile,(Counter2 - 1));
        Read(FileCompArrayFile,CompFileArray);
        CompFileArray[1] := Counter;
        Seek(FileCompArrayFile,(Counter2 - 1));
        Write(FileCompArrayFile,CompFileArray);
      END;
    END;
  END;
  Close(FileAreaFile);
  LastError := IOResult;
  LowFileArea := 0;
  Counter1 := 0;
  Counter := 1;
  WHILE (Counter <= FileSize(FileCompArrayFile)) AND (Counter1 = 0) DO
  BEGIN
    Seek(FileCompArrayFile,(Counter - 1));
    Read(FileCompArrayFile,CompFileArray);
    IF (CompFileArray[0] <> 0) THEN
      Counter1 := CompFileArray[0];
    Inc(Counter);
  END;
  LowFileArea := Counter1;
  HighFileArea := 0;
  Counter1 := 0;
  Counter := 1;
  WHILE (Counter <= FileSize(FileCompArrayFile)) DO
  BEGIN
    Seek(FileCompArrayFile,(Counter - 1));
    Read(FileCompArrayFile,CompFileArray);
    IF (CompFileArray[0] <> 0) THEN
      Counter1 := CompFileArray[0];
    Inc(Counter);
  END;
  HighFileArea := Counter1;
  Close(FileCompArrayFile);
  LastError := IOResult;
  Reset(MsgAreaFile);
  IF (IOResult <> 0) THEN
  BEGIN
    SysOpLog('Error opening MBASES.DAT (Procedure: NewCompTables)');
    Exit;
  END;
  NumMsgAreas := FileSize(MsgAreaFile);
  Assign(MsgCompArrayFile,TempDir+'MACT'+IntToStr(ThisNode)+'.DAT');
  ReWrite(MsgCompArrayFile);
  CompMsgArray[0] := 0;
  CompMsgArray[1] := 0;
  FOR Counter := 1 TO FileSize(MsgAreaFile) DO
    Write(MsgCompArrayFile,CompMsgArray);
  Reset(MsgCompArrayFile);
  IF (NOT General.CompressBases) THEN
  BEGIN
    FOR Counter := 1 TO FileSize(MsgAreaFile) DO
    BEGIN
      Seek(MsgAreaFile,(Counter - 1));
      Read(MsgAreaFile,MemMsgArea);
      IF (NOT AACS(MemMsgArea.ACS)) THEN
      BEGIN
        CompMsgArray[0] := 0;
        CompMsgArray[1] := 0;
      END
      ELSE
      BEGIN
        CompMsgArray[0] := Counter;
        CompMsgArray[1] := Counter;
      END;
      Seek(MsgCompArrayFile,(Counter - 1));
      Write(MsgCompArrayFile,CompMsgArray);
    END;
  END
  ELSE
  BEGIN
    Counter2 := 0;
    Counter1 := 0;
    FOR Counter := 1 TO FileSize(MsgAreaFile) DO
    BEGIN
      Seek(MsgAreaFile,(Counter - 1));
      Read(MsgAreaFile,MemMsgArea);
      Inc(Counter1);
      IF (NOT AACS(MemMsgArea.ACS)) THEN
      BEGIN
        Dec(Counter1);
        CompMsgArray[0] := 0;
      END
      ELSE
      BEGIN
        CompMsgArray[0] := Counter1;
        Seek(MsgCompArrayFile,(Counter - 1));
        Write(MsgCompArrayFile,CompMsgArray);
        Inc(Counter2);
        Seek(MsgCompArrayFile,(Counter2 - 1));
        Read(MsgCompArrayFile,CompMsgArray);
        CompMsgArray[1] := Counter;
        Seek(MsgCompArrayFile,(Counter2 - 1));
        Write(MsgCompArrayFile,CompMsgArray);
      END;
    END;
  END;
  Close(MsgAreaFile);
  LastError := IOResult;
  LowMsgArea := 0;
  Counter1 := 0;
  Counter := 1;
  WHILE (Counter <= FileSize(MsgCompArrayFile)) AND (Counter1 = 0) DO
  BEGIN
    Seek(MsgCompArrayFile,(Counter - 1));
    Read(MsgCompArrayFile,CompMsgArray);
    IF (CompMsgArray[0] <> 0) THEN
      Counter1 := CompMsgArray[0];
    Inc(Counter);
  END;
  LowMsgArea := Counter1;
  HighMsgArea := 0;
  Counter1 := 0;
  Counter := 1;
  WHILE (Counter <= FileSize(MsgCompArrayFile)) DO
  BEGIN
    Seek(MsgCompArrayFile,(Counter - 1));
    Read(MsgCompArrayFile,CompMsgArray);
    IF (CompMsgArray[0] <> 0) THEN
      Counter1 := CompMsgArray[0];
    Inc(Counter);
  END;
  HighMsgArea := Counter1;
  Close(MsgCompArrayFile);
  LastError := IOResult;
  ReadMsgArea := -1;
  ReadFileArea := -1;
  IF (NOT FileAreaAC(FileArea)) THEN
    ChangeFileArea(CompFileArea(1,1));
  IF (NOT MsgAreaAC(MsgArea)) THEN
    ChangeMsgArea(CompMsgArea(1,1));
  LoadMsgArea(SaveReadMsgArea);
  LoadFileArea(SaveReadFileArea);
END;

PROCEDURE Wait(b: Boolean);
CONST
  SaveCurrentColor: Byte = 0;
BEGIN
  IF (B) THEN
  BEGIN
    SaveCurrentColor := CurrentColor;
    { Prompt(FString.lWait); }
    lRGLngStr(4,FALSE);
  END
  ELSE
  BEGIN
    BackErase(LennMCI(lRGLngStr(4,TRUE){FString.lWait}));
    SetC(SaveCurrentColor);
  END;
END;

PROCEDURE InitTrapFile;
BEGIN
  Trapping := FALSE;
  IF (General.GlobalTrap) OR (TrapActivity IN ThisUser.SFlags) THEN
    Trapping := TRUE;
  IF (Trapping) THEN
  BEGIN
    IF (TrapSeparate IN ThisUser.SFlags) THEN
      Assign(TrapFile,General.LogsPath+'TRAP'+IntToStr(UserNum)+'.LOG')
    ELSE
      Assign(TrapFile,General.LogsPath+'TRAP.LOG');
    Append(TrapFile);
    IF (IOResult = 2) THEN
    BEGIN
      ReWrite(TrapFile);
      WriteLn(TrapFile);
    END;
    WriteLn(TrapFile,'***** Renegade User Audit - '+Caps(ThisUser.Name)+' on at '+DateStr+' '+TimeStr+' *****');
  END;
END;

PROCEDURE Local_Input1(VAR S: STRING; MaxLen: Byte; LowerCase: Boolean);
VAR
  C: Char;
  B: Byte;
BEGIN
  B := 1;
  REPEAT
    C := ReadKey;
    IF (NOT LowerCase) THEN
      C := UpCase(C);
    IF (C IN [#32..#255]) THEN
      IF (B <= MaxLen) THEN
      BEGIN
        S[B] := C;
        Inc(B);
        Write(C);
      END
      ELSE
    ELSE
      CASE C of
        ^H : IF (B > 1) THEN
             BEGIN
               Write(^H' '^H);
               C := ^H;
               Dec(B);
             END;
     ^U,^X : WHILE (B <> 1) DO
             BEGIN
               Write(^H' '^H);
               Dec(B);
             END;
      END;
  UNTIL (C IN [^M,^N]);
  S[0] := Chr(B - 1);
  IF (WhereY <= Hi(WindMax) - Hi(WindMin)) THEN
    WriteLn;
END;

PROCEDURE Local_Input(VAR S: STRING; MaxLen: Byte);
BEGIN
  Local_Input1(S,MaxLen,FALSE);
END;

PROCEDURE Local_InputL(VAR S: STRING; MaxLen: Byte);
BEGIN
  Local_Input1(S,MaxLen,TRUE);
END;

PROCEDURE Local_OneK(VAR C: Char; S: STRING);
BEGIN
  REPEAT
    C := UpCase(ReadKey)
  UNTIL (Pos(C,S) > 0);
  WriteLn(C);
END;

PROCEDURE SysOpShell;
VAR
  SavePath: STRING;
  SaveWhereX,
  SaveWhereY,
  SaveCurCo: Byte;
  ReturnCode: Integer;
  SaveTimer: LongInt;
BEGIN
  SaveCurCo := CurrentColor;
  GetDir(0,SavePath);
  SaveTimer := Timer;
  IF (UserOn) THEN
  BEGIN
    { Prompt(FString.ShellDOS1); }
    lRGLngStr(12,FALSE);
    Com_Flush_Send;
    Delay(100);
  END;
  SaveWhereX := WhereX;
  SaveWhereY := WhereY;
  Window(1,1,80,25);
  TextBackGround(Black);
  TextColor(LightGray);
  ClrScr;
  TextColor(LightCyan);
  WriteLn('Type "EXIT" to return to Renegade.');
  WriteLn;
  TimeLock := TRUE;
  ShellDOS(FALSE,'',ReturnCode);
  TimeLock := FALSE;
  IF (UserOn) THEN
    Com_Flush_Recv;
  ChDir(SavePath);
  TextBackGround(Black);
  TextColor(LightGray);
  ClrScr;
  TextAttr := SaveCurCo;
  GoToXY(SaveWhereX,SaveWhereY);
  IF (UserOn) THEN
  BEGIN
    IF (NOT InChat) THEN
      FreeTime := ((FreeTime + Timer) - SaveTimer);
    Update_Screen;
    FOR SaveCurCo := 1 TO LennMCI(lRGLngStr(12,TRUE){FString.ShellDOS1}) DO
      BackSpace;
  END;
END;

PROCEDURE ReDrawForANSI;
BEGIN
  IF (DOSANSIOn) THEN
  BEGIN
    DOSANSIOn := FALSE;
    Update_Screen;
  END;
  TextAttr := 7;
  CurrentColor := 7;
  IF (OutCom) THEN
    IF (OKAvatar) THEN
      SerialOut(^V^A^G)
    ELSE IF (OkANSI) THEN
      SerialOut(#27+'[0m');
END;

END.

