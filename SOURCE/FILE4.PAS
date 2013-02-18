{$IFDEF WIN32}
{$I DEFINES.INC}
{$ENDIF}

{$A+,B-,D+,E-,F+,I-,L+,N-,O+,R-,S+,V-}

UNIT File4;

INTERFACE

USES
  Common;

PROCEDURE ExecProtocol(TextFN,
                       Dir,
                       BatLine: AStr;
                       OKLevel: Integer;
                       VAR ReturnCode: Integer;
                       VAR TransferTime: LongInt);
FUNCTION FindReturnCode(ProtCode: ProtocolCodeType; XBStat: PRFlagSet; ReturnCode: AStr): Boolean;
FUNCTION DoProtocol(VAR Protocol: ProtocolRecordType; UL,DL,Batch,Resume: Boolean): Integer;

IMPLEMENTATION

USES
  ExecBat,
  TimeFunc;

FUNCTION FindReturnCode(ProtCode: ProtocolCodeType; XBStat: PRFlagSet; ReturnCode: AStr): Boolean;
VAR
  Counter: Byte;
  Found: Boolean;
BEGIN
  FindReturnCode := FALSE;
  Found := FALSE;
  FOR Counter := 1 TO 6 DO
    IF (ProtCode[Counter] <> '') THEN
      IF (Pos(ProtCode[Counter],Copy(ReturnCode,1,Length(ProtCode[Counter]))) <> 0) THEN
        Found := TRUE;
  IF (Found) AND (NOT (ProtXferOkCode IN Protocol.PRFlags)) THEN
    Exit;
  IF (NOT Found) AND (ProtXferOkCode IN Protocol.PRFlags) THEN
    Exit;
  FindReturnCode := Found;
END;

PROCEDURE ExecProtocol(TextFN,
                       Dir,
                       BatLine: AStr;
                       OKLevel: Integer;
                       VAR ReturnCode: Integer;
                       VAR TransferTime: LongInt);
VAR
  SaveSwapShell,
  ResultOk: Boolean;
BEGIN
  IF (General.MultiNode) THEN
  BEGIN
    LoadNode(ThisNode);
    SaveNAvail := (NAvail IN NodeR.Status);
    Exclude(NodeR.Status,NAvail);
    SaveNode(ThisNode);
  END;

  TransferTime := GetPackDateTime;

  IF (TextFN <> '') THEN
  BEGIN
    AllowContinue := TRUE;
    Abort := FALSE;
    Next := FALSE;
    CLS;
    UserColor(1);
    ReturnCode := 0;
    PrintF(TextFN);
    IF (NoFile) THEN
      ReturnCode := 2;
    NL;
    PauseScr(FALSE);
    UserColor(1);
    AllowContinue := FALSE;
  END
  ELSE
  BEGIN
    SaveSwapShell := General.SwapShell;
    General.SwapShell := FALSE;
    ExecWindow(ResultOK,
               Dir,
               BatLine,
               OKLevel,
               ReturnCode);
    General.SwapShell := SaveSwapShell;
  END;

  TransferTime := (GetPackDateTime - TransferTime);

  IF (General.MultiNode) THEN
  BEGIN
    LoadNode(ThisNode);
    IF (SaveNAvail) THEN
      Include(NodeR.Status,NAvail);
    SaveNode(ThisNode);
  END;
END;

FUNCTION OkProt(Protocol: ProtocolRecordType; UL,DL,Batch,Resume: Boolean): Boolean;
VAR
  ULDLCmdStr: AStr;
BEGIN
  OkProt := FALSE;
  WITH Protocol DO
  BEGIN
    IF (UL) THEN
      ULDLCmdStr := ULCmd
    ELSE IF (DL) THEN
      ULDLCmdStr := DLCmd
    ELSE
      ULDLCmdStr := '';
    IF (ULDLCmdStr = '') THEN
      Exit;
    IF (ULDLCmdStr = 'NEXT') AND ((UL) OR (Batch) OR (Resume)) THEN
      Exit;
    IF (ULDLCmdStr = 'ASCII') AND ((UL) OR (Batch) OR (Resume)) THEN
      Exit;
    IF (ULDLCmdStr = 'BATCH') AND ((Batch) OR (Resume)) AND (NOT Write_Msg) THEN
      Exit;
    IF (Batch <> (ProtIsBatch in PRFlags)) THEN
      Exit;
    IF (Resume <> (ProtIsResume in PRFlags)) THEN
      Exit;
    IF (ProtReliable in PRFlags) AND (NOT Reliable) THEN
      Exit;
    IF (NOT (ProtActive in PRFlags)) THEN
      Exit;
    IF (NOT AACS(ACS)) THEN
      Exit;
  END;
  OkProt := TRUE;
END;

PROCEDURE ShowProts(VAR CmdStr: AStr; UL,DL,Batch,Resume: Boolean);
VAR
  RecNum: Integer;
BEGIN
  NoFile := TRUE;
  IF (Resume) THEN
    PrintF('PROTRES')
  ELSE
  BEGIN
    IF (Batch) THEN
      IF (UL) THEN
        PrintF('PROTBUL')
      ELSE
        PrintF('PROTBDL')
    ELSE IF (UL) THEN
      PrintF('PROTSUL')
    ELSE
      PrintF('PROTSDL');
  END;
  Abort := FALSE;
  Next := FALSE;
  CmdStr := '';
  RecNum := 1;
  WHILE (RecNum <= NumProtocols) AND (NOT Abort) AND (NOT HangUp) DO
  BEGIN
    Seek(ProtocolFile,(RecNum - 1));
    Read(ProtocolFile,Protocol);
    IF (OkProt(Protocol,UL,DL,Batch,Resume)) THEN
    BEGIN
      IF (NoFile) AND (Protocol.Description <> '') THEN
        Print(Protocol.Description);
      IF (Protocol.CKeys = 'ENTER') then
        CmdStr := CmdStr + ^M
      ELSE
        CmdStr := CmdStr + Protocol.CKeys[1];
    END;
    Inc(RecNum);
  END;
  IF (NoFile) THEN
    NL;
END;

FUNCTION FindProt(Cmd: Char; UL,DL,Batch,Resume: Boolean): Integer;
VAR
  ULDLCmdStr: AStr;
  RecNum,
  RecNum1: Integer;
BEGIN
  RecNum1 := -99;
  RecNum := 1;
  WHILE (RecNum <= NumProtocols) AND (RecNum1 = -99) DO
  BEGIN
    Seek(ProtocolFile,(RecNum - 1));
    Read(ProtocolFile,Protocol);
    IF (Cmd = Protocol.Ckeys[1]) OR ((Cmd = ^M) AND (Protocol.Ckeys = 'ENTER')) THEN
      IF (OkProt(Protocol,UL,DL,Batch,Resume)) THEN
      BEGIN
        IF (UL) THEN
          ULDLCmdStr := Protocol.ULCmd
        ELSE IF (DL) THEN
          ULDLCmdStr := Protocol.DLCmd
        ELSE
          ULDLCmdStr := '';
        IF (ULDLCmdStr = 'ASCII') THEN
          RecNum1 := -1
        ELSE IF (ULDLCmdStr = 'QUIT') THEN
          RecNum1 := -2
        ELSE IF (ULDLCmdStr = 'NEXT') THEN
          RecNum1 := -3
        ELSE IF (ULDLCmdStr = 'BATCH') THEN
          RecNum1 := -4
        ELSE IF (ULDLCmdStr = 'EDIT') THEN
          RecNum1 := -5
        ELSE IF (ULDLCmdStr <> '') THEN
          RecNum1 := RecNum;
      END;
    Inc(RecNum);
  END;
  FindProt := RecNum1;
END;

FUNCTION DoProtocol(VAR Protocol: ProtocolRecordType; UL,DL,Batch,Resume: Boolean): Integer;
VAR
  CmdStr: AStr;
  Cmd: Char;
  RecNum: Integer;
BEGIN
  Reset(ProtocolFile);
  REPEAT
    ShowProts(CmdStr,UL,DL,Batch,Resume);
    { Prompt('%DFPROTLIST%^4Selection^2: ');}
    lRGLngStr(17,FALSE);;
    OneK(Cmd,CmdStr,TRUE,TRUE);
    RecNum := FindProt(Cmd,UL,DL,Batch,Resume);
    IF (RecNum = -99) THEN
    BEGIN
      NL;
      Print('Invalid option.');
    END
    ELSE IF (RecNum >= 1) AND (RecNum <= NumProtocols) THEN
    BEGIN
      Seek(ProtocolFile,(RecNum - 1));
      Read(ProtocolFile,Protocol);
    END
  UNTIL (RecNum <> -99) OR (HangUp);
  Close(ProtocolFile);
  LastError := IOResult;
  DoProtocol := RecNum;
END;

END.