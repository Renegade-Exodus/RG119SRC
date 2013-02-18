{$A+,B-,D+,E-,F+,I-,L+,N-,O+,R-,S+,V-}

UNIT Mail7;

INTERFACE

USES
  Common;

PROCEDURE MessageAreaList(ShowScan: Boolean);
PROCEDURE MessageAreaChange(VAR Done: Boolean; CONST MenuOption: Str50);

IMPLEMENTATION

USES
  Mail0;

(* Done - 06/21/07 - Lee Palmer *)
PROCEDURE MessageAreaList(ShowScan: Boolean);
VAR
  ScanChar,
  TempStr: AStr;
  NumOnline: Byte;
  MArea,
  NumMAreas,
  SaveMsgArea: Integer;
BEGIN
  SaveMsgArea := MsgArea;
  Abort := FALSE;
  Next := FALSE;
  AllowContinue := TRUE;
  NumOnline := 0;
  NumMAreas := 0;
  TempStr := '';
  ScanChar := lRGLngStr(55,TRUE); {FString.ScanCharCheck}
  (*
  CLS;
  IF (FString.MsgAreaHeader <> '') THEN
    PrintMain(FString.MsgAreaHeader)
  ELSE
  BEGIN
    PrintACR('7ÚÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿');
    PrintACR('7³8 Num 7³9 Name                           7³8 Num 7³9 Name                          7³');
    PrintACR('7ÀÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ');
  END;
  *)
  lRGLngStr(58,FALSE);
  Reset(MsgAreaFile);
  MArea := 1;
  WHILE (MArea <= NumMsgAreas) AND (NOT Abort) AND (NOT HangUp) DO
  BEGIN
    IF (ShowScan) THEN
      InitMsgArea(Marea)
    ELSE
      LoadMsgArea(MArea);
    IF (AACS(MemMsgArea.ACS)) OR (MAUnHidden IN MemMsgArea.MAFlags) THEN
    BEGIN
      TempStr := TempStr + PadLeftStr(PadRightStr(';'+IntToStr(CompMsgArea(MArea)),5)+
                           ' '+AOnOff(ShowScan AND NewScanMsgArea,':'+ScanChar[1],' ')+
                           '< '+MemMsgArea.Name,39);
      Inc(NumOnline);
      IF (NumOnline = 2) THEN
      BEGIN
        PrintaCR(TempStr);
        NumOnline := 0;
        TempStr := '';
      END;
      Inc(NumMAreas);
    END;
    WKey;
    Inc(MArea);
  END;
  Close(MsgAreaFile);
  AllowContinue := FALSE;
  IF (NumOnline = 1) AND (NOT Abort) THEN
    PrintaCR(TempStr);
  IF (NumMAreas = 0) AND (NOT Abort) THEN
    Print('^7No message areas.');
  NL;
  MsgArea := SaveMsgArea;
  LoadMsgArea(MsgArea);
END;

(* Done - 06/21/2007 - Lee Palmer *)
PROCEDURE MessageAreaChange(VAR Done: Boolean; CONST MenuOption: Str50);
VAR
  InputStr: Str4;
  MArea: Integer;
BEGIN
  IF (MenuOption <> '') THEN
    CASE UpCase(MenuOption[1]) OF
      '+' : BEGIN
              MArea := MsgArea;
              IF (MsgArea >= NumMsgAreas) THEN
                MArea := 0
              ELSE
              REPEAT
                Inc(MArea);
                ChangeMsgArea(MArea);
              UNTIL (MsgArea = MArea) OR (MArea > NumMsgAreas);
              IF (MsgArea <> MArea) THEN
              BEGIN
                NL;
                Print('Highest accessible message area.');
              END
              ELSE
                LastCommandOvr := TRUE;
            END;
      '-' : BEGIN
              MArea := MsgArea;
              IF (MsgArea <= 0) THEN
                MArea := NumMsgAreas
              ELSE
              REPEAT
                Dec(MArea);
                ChangeMsgArea(MArea);
              UNTIL (MsgArea = MArea) OR (MArea <= 0);
              IF (MsgArea <> MArea) THEN
              BEGIN
                NL;
                Print('Lowest accessible message area.');
              END
              ELSE
                LastCommandOvr := TRUE;
            END;
      'L' : BEGIN
              MessageAreaList(FALSE);
              IF (Novice IN ThisUser.Flags) THEN
                PauseScr(FALSE);
            END;
    ELSE
    BEGIN
      IF (StrToInt(MenuOption) > 0) THEN
      BEGIN
        MArea := StrToInt(MenuOption);
        IF (MArea <> MsgArea) THEN
          ChangeMsgArea(MArea);
        IF (Pos(';',MenuOption) > 0) THEN
        BEGIN
          CurMenu := StrToInt(Copy(MenuOption,(Pos(';',MenuOption) + 1),Length(MenuOption)));
          NewMenuToLoad := TRUE;
          Done := TRUE;
        END;
        LastCommandOvr := TRUE;
      END;
    END;
  END
  ELSE
  BEGIN
    InputStr := '?';
    REPEAT
      IF (InputStr = '?') THEN
        MessageAreaList(FALSE);
      Prt('Change message area (^5?^4=^5List^4,^5<CR>^4=^5Quit^4): ');
      MPL(4);
      ScanInput(InputStr,'?'^M);
      MArea := AMBase(StrToInt(InputStr));
      IF (MArea <> MsgArea) THEN
        ChangeMsgArea(MArea);
    UNTIL (InputStr <> '?') OR (HangUp);
    LastCommandOvr := TRUE;
  END;
END;

END.
