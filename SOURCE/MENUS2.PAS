{$IFDEF WIN32}
{$I DEFINES.INC}
{$ENDIF}

{$A+,B-,D+,E-,F+,I-,L+,N-,O+,R-,S+,V-}

UNIT Menus2;

INTERFACE

USES
  Common;

PROCEDURE LoadMenu;
PROCEDURE ShowCmds(MenuOption: Str50);
FUNCTION OkSecurity(CmdToExec: Byte; VAR CmdNotHid: Boolean): Boolean;
PROCEDURE GenericMenu(ListType: Byte);
PROCEDURE ShowThisMenu;

IMPLEMENTATION

PROCEDURE LoadMenu;
VAR
  Counter,
  MenuNum: Integer;
  TempCkeys: CHAR;
  FoundMenu: Boolean;
BEGIN
  IF (GlobalCmds > 0) THEN
    Move(MemCmd^[((NumCmds - GlobalCmds) + 1)],MemCmd^[((MaxCmds - GlobalCmds) + 1)],(GlobalCmds * Sizeof(MemCmdRec)));
  NumCmds := 0;
  FoundMenu := FALSE;
  Reset(MenuFile);
  MenuNum := 1;
  WHILE (MenuNum <= NumMenus) AND (NOT FoundMenu) DO
  BEGIN
    Seek(MenuFile,MenuRecNumArray[MenuNum]);
    Read(MenuFile,MenuR);
    IF (MenuR.MenuNum = CurMenu) THEN
    BEGIN
      FallBackMenu := MenuR.FallBack;
      FoundMenu := TRUE;
    END;
    Inc(MenuNum);
  END;
  Dec(MenuNum);
  IF (NOT FoundMenu) THEN
  BEGIN
    NL;
    Print('That menu is missing, dropping to fallback ...');
    SysOpLog('Menu #'+IntToStr(CurMenu)+' is missing - Dropping to FallBack #'+IntToStr(FallBackMenu));
    IF (FallBackMenu > 0) THEN
    BEGIN
      FoundMenu := FALSE;
      MenuNum := 1;
      WHILE (MenuNum <= NumMenus) AND (NOT FoundMenu) DO
      BEGIN
        Seek(MenuFile,MenuRecNumArray[MenuNum]);
        Read(MenuFile,MenuR);
        IF (MenuR.MenuNum = FallBackMenu) THEN
        BEGIN
          CurMenu := FallBackMenu;
          FallBackMenu := MenuR.FallBack;
          FoundMenu := TRUE;
        END;
        Inc(MenuNum);
      END;
      Dec(MenuNum);
    END;
    IF (FallBackMenu = 0) OR (NOT FoundMenu) THEN
    BEGIN
      NL;
      Print('Emergency System shutdown. Please call back later.');
      NL;
      Print('Critical error; hanging up.');
      IF (FallBackMenu = 0) THEN
        SysOpLog('FallBack menu is set to ZERO - Hung user up.')
      ELSE
        SysOpLog('FallBack #'+IntToStr(FallBackMenu)+' is MISSING - Hung user up.');
      HangUp := TRUE;
    END;
  END;
  IF (FoundMenu) THEN
  BEGIN
    Seek(MenuFile,MenuRecNumArray[MenuNum]);
    Read(MenuFile,MenuR);
    WITH MemMenu DO
    BEGIN
      FOR Counter := 1 TO 3 DO
        LDesc[Counter] := MenuR.LDesc[Counter];
      ACS := MenuR.ACS;
      NodeActivityDesc := MenuR.NodeActivityDesc;
      MenuFlags := MenuR.MenuFlags;
      LongMenu := MenuR.LongMenu;
      MenuNum := MenuR.MenuNum;
      MenuPrompt := MenuR.MenuPrompt;
      Password := MenuR.Password;
      FallBack := MenuR.FallBack;
      Directive := MenuR.Directive;
      ForceHelpLevel := MenuR.ForceHelpLevel;
      GenCols := MenuR.GenCols;
      FOR Counter := 1 TO 3 DO
        GCol[Counter] := MenuR.GCol[Counter];
    END;

    Update_Node(MemMenu.NodeActivityDesc,TRUE);

    MQArea := FALSE;
    FQArea := FALSE;
    VQArea := FALSE;
    RQArea := FALSE;
    MenuKeys := '';
    NumCmds := 1;
    WHILE (NumCmds <= CmdNumArray[MenuNum]) DO
    BEGIN
      Read(MenuFile,MenuR);
      WITH MemCmd^[NumCmds] DO
      BEGIN
        LDesc := MenuR.LDesc[1];
        ACS := MenuR.ACS;
        NodeActivityDesc := MenuR.NodeActivityDesc;
        CmdFlags := MenuR.CmdFlags;
        SDesc := MenuR.SDesc;
        CKeys := MenuR.CKeys;
        IF (CKeys = 'ENTER') THEN
          TempCkeys := #13
        ELSE IF (CKeys = 'UP_ARROW') THEN
          TempCkeys := #255
        ELSE IF (CKeys = 'DOWN_ARROW') THEN
          TempCkeys := #254
        ELSE IF (CKeys = 'LEFT_ARROW') THEN
          TempCkeys := #253
        ELSE IF (CKeys = 'RIGHT_ARROW') THEN
          TempCkeys := #252
        ELSE IF (Length(CKeys) > 1) THEN
          TempCkeys := '/'
        ELSE
          TempCkeys := UpCase(CKeys[1]);
        IF (Pos(TempCkeys,MenuKeys) = 0) THEN
          MenuKeys := MenuKeys + TempCkeys;
        CmdKeys := MenuR.CmdKeys;
        IF (CmdKeys = 'M#') THEN
          MQArea := TRUE
        ELSE IF (CmdKeys = 'F#') THEN
          FQArea := TRUE
        ELSE IF (CmdKeys = 'V#') THEN
          VQArea := TRUE
        ELSE IF (CmdKeys = 'R#') THEN
          RQArea := TRUE;
        Options := MenuR.Options;
      END;
      Inc(NumCmds);
    END;
  END;
  Dec(NumCmds);
  Close(MenuFile);
  LastError := IOResult;
  IF (GlobalCmds > 0) THEN
  BEGIN
    Move(MemCmd^[((MaxCmds - GlobalCmds) + 1)],MemCmd^[(NumCmds + 1)],(GlobalCmds * Sizeof(MemCmdRec)));
    Inc(NumCmds,GlobalCmds);
  END;
END;

PROCEDURE ShowCmds(MenuOption: Str50);
VAR
  TempStr,
  TempStr1: AStr;
  CmdToList,
  Counter,
  NumRows: Byte;

  FUNCTION Type1(CTL: Byte): AStr;
  BEGIN
    Type1 := '^0'+PadRightInt(CTL,3)+
             ' ^3'+PadLeftStr(MemCmd^[CTL].CKeys,2)+
             ' ^3'+PadLeftStr(MemCmd^[CTL].CmdKeys,2)+
             ' '+PadLeftStr(MemCmd^[CTL].Options,15);
  END;

BEGIN
  IF (MenuOption = '') THEN
    Exit;
  IF (NumCmds = 0) THEN
    Print('*** No commands on this menu ***')
  ELSE
  BEGIN
    AllowAbort := TRUE;
    MCIAllowed := FALSE;
    Abort := FALSE;
    Next := FALSE;
    CLS;
    NL;
    CASE MenuOption[1] OF
      '1' : BEGIN
              PrintACR('^0###^4:^3KK            ^4:^3CF^4:^3ACS       ^4:^3CK^4:^3Options');
              PrintACR('^4===:==============:==:==========:==:========================================');
              CmdToList := 1;
              WHILE (CmdToList <= NumCmds) AND (NOT Abort) AND (NOT HangUp) DO
              BEGIN
                PrintACR('^0'+PadRightInt(CmdToList,3)+
                         ' ^3'+PadLeftStr(MemCmd^[CmdToList].CKeys,14)+
                         ' '+AOnOff(Hidden IN MemCmd^[CmdToList].CmdFlags,'H','-')+
                         AOnOff(UnHidden IN MemCmd^[CmdToList].CmdFlags,'U','-')+
                         ' ^9'+PadLeftStr(MemCmd^[CmdToList].ACS,10)+
                         ' ^3'+PadLeftStr(MemCmd^[CmdToList].CmdKeys,2)+
                         ' '+PadLeftStr(MemCmd^[CmdToList].Options,40));
                Inc(CmdToList);
              END;
            END;
      '2' : BEGIN
              NumRows := ((NumCmds + 2) DIV 3);
              TempStr := '^0###^4:^3KK^4:^3CK^4:^3Options        ';
              TempStr1 := '^4===:==:==:===============';
              CmdToList := 1;
              WHILE (CmdToList <= NumRows) AND (CmdToList < 3) DO
              BEGIN
                TempStr := TempStr+' ^0###^4:^3KK^4:^3CK^4:^3Options        ';
                TempStr1 := TempStr1 + ' ^4===:==:==:===============';
                Inc(CmdToList);
              END;
              PrintACR(TempStr);
              PrintACR(TempStr1);
              CmdToList := 0;
              REPEAT
                Inc(CmdToList);
                TempStr := Type1(CmdToList);
                FOR Counter := 1 TO 2 DO
                  IF ((CmdToList + (Counter * NumRows)) <= NumCmds) THEN
                    TempStr := TempStr + ' '+Type1(CmdToList + (Counter * NumRows));
                PrintACR('^1'+TempStr);
              UNTIL ((CmdToList >= NumRows) OR (Abort) OR (HangUp));
            END;
    END;
    AllowAbort := FALSE;
    MCIAllowed := TRUE;
  END;
END;

FUNCTION OkSecurity(CmdToExec: Byte; VAR CmdNotHid: Boolean): Boolean;
BEGIN
  OkSecurity := FALSE;
  IF (UnHidden IN MemCmd^[CmdToExec].CmdFlags) THEN
    CmdNotHid := TRUE;
  IF (NOT AACS(MemCmd^[CmdToExec].ACS)) THEN
    EXIT;
  OkSecurity := TRUE;
END;

PROCEDURE GenericMenu(ListType: Byte);
VAR
  GColors: ARRAY [1..3] OF Byte;
  Counter,
  ColSiz,
  NumCols: Byte;

  FUNCTION GenColored(CONST Keys: AStr; Desc: AStr; Acc: Boolean): AStr;
  VAR
    j: Byte;
  BEGIN
    j := Pos(AllCaps(Keys),AllCaps(Desc));
    IF (j <> 0) AND (Pos('^',Desc) = 0) THEN
    BEGIN
      Insert('^'+IntToStr(GColors[3]),Desc,((j + Length(Keys) + 1)));
      Insert('^'+IntToStr(GColors[1]),Desc,j + Length(Keys));
      IF (acc) THEN
        Insert('^'+IntToStr(GColors[2]),Desc,j);
      IF (j <> 1) THEN
        Insert('^'+IntToStr(GColors[1]),Desc,j - 1);
    END;
    GenColored := '^'+IntToStr(GColors[3])+Desc;
  END;

  FUNCTION TCentered(c: Integer; CONST s: AStr): AStr;
  CONST
    SpaceStr = '                                               ';
  BEGIN
    c := (c DIV 2) - (LennMCI(s) DIV 2);
    IF (c < 1) THEN
      c := 0;
    TCentered := Copy(SpaceStr,1,c) + s;
  END;

  PROCEDURE NewGColors(CONST S: STRING);
  VAR
    TempStr: STRING;
  BEGIN
    TempStr := SemiCmd(s,1);
    IF (TempStr <> '') THEN
      GColors[1] := StrToInt(TempStr);
    TempStr := SemiCmd(s,2);
    IF (TempStr <> '') THEN
      GColors[2] := StrToInt(TempStr);
    TempStr := SemiCmd(s,3);
    IF (TempStr <> '') THEN
      GColors[3] := StrToInt(TempStr);
  END;

  PROCEDURE GetMaxRight(VAR MaxRight: Byte);
  VAR
    CmdToList,
    Len,
    Onlin: Byte;
    TempStr: AStr;
  BEGIN
    MaxRight := 0;
    OnLin := 0;
    TempStr := '';
    FOR CmdToList := 1 TO NumCmds DO
      IF (MemCmd^[CmdToList].CKeys <> 'GTITLE') THEN
      BEGIN
        Inc(OnLin);
        IF (OnLin <> NumCols) THEN
          TempStr := TempStr + PadLeftStr(MemCmd^[CmdToList].SDesc,ColSiz)
        ELSE
        BEGIN
          TempStr := TempStr + MemCmd^[CmdToList].SDesc;
          OnLin := 0;
          Len := LennMCI(TempStr);
          IF (Len > MaxRight) THEN
            MaxRight := Len;
          TempStr := '';
        END;
      END
      ELSE
      BEGIN
        TempStr := '';
        OnLin := 0;
      END;
  END;

  PROCEDURE DoMenuTitles(MaxRight: Byte);
  VAR
    Counter1: Byte;
    ShownAlready: Boolean;
  BEGIN
    IF (ClrScrBefore IN MemMenu.MenuFlags) THEN
    BEGIN
      CLS;
      NL;
      NL;
    END;
    IF (NOT (NoMenuTitle IN MemMenu.MenuFlags)) THEN
    BEGIN
      ShownAlready := FALSE;
      FOR Counter1 := 1 TO 3 DO
        IF (MemMenu.LDesc[Counter1] <> '') THEN
        BEGIN
          IF (NOT ShownAlready) THEN
          BEGIN
            NL;
            ShownAlready := TRUE;
          END;
          IF (DontCenter IN MemMenu.MenuFlags) THEN
            PrintACR(MemMenu.LDesc[Counter1])
          ELSE
            PrintACR(TCentered(MaxRight,MemMenu.LDesc[Counter1]));
        END;
    END;
    NL;
  END;

  PROCEDURE GenTuto;
  VAR
    CmdToList,
    MaxRight: Byte;
    Acc,
    CmdNotHid: Boolean;
  BEGIN
    Abort := FALSE;
    Next := FALSE;
    GetMaxRight(MaxRight);
    DoMenuTitles(MaxRight);
    IF (NoGlobalDisplayed IN MemMenu.MenuFlags) OR (NoGlobalUsed IN MemMenu.MenuFlags) THEN
      Dec(NumCmds,GlobalCmds);
    CmdToList := 0;
    WHILE (CmdToList < NumCmds) AND (NOT Abort) AND (NOT HangUp) DO
    BEGIN
      Inc(CmdToList);
      CmdNotHid := FALSE;
      Acc := OkSecurity(CmdToList,CmdNotHid);
      IF (((Acc) OR (UnHidden IN MemCmd^[CmdToList].CmdFlags)) AND (NOT (Hidden IN MemCmd^[CmdToList].CmdFlags))) THEN
        IF (MemCmd^[CmdToList].CKeys = 'GTITLE') THEN
        BEGIN
          PrintACR(MemCmd^[CmdToList].LDesc);
          IF (MemCmd^[CmdToList].Options <> '') THEN
            NewGColors(MemCmd^[CmdToList].Options);
        END
        ELSE IF (MemCmd^[CmdToList].LDesc <> '') THEN
          PrintACR(GenColored(MemCmd^[CmdToList].CKeys,MemCmd^[CmdToList].LDesc,Acc));
    END;
    IF (NoGlobalDisplayed IN MemMenu.MenuFlags) OR (NoGlobalUsed IN MemMenu.MenuFlags) THEN
      Inc(NumCmds,GlobalCmds);
  END;

  PROCEDURE GenNorm;
  VAR
    TempStr,
    TempStr1: AStr;
    CmdToList,
    Onlin,
    MaxRight: Byte;
    Acc,
    CmdNotHid: Boolean;
  BEGIN
    TempStr1 := '';
    OnLin := 0;
    TempStr := '';
    Abort := FALSE;
    Next := FALSE;
    GetMaxRight(MaxRight);
    DoMenuTitles(MaxRight);
    IF (NoGlobalDisplayed IN MemMenu.MenuFlags) OR (NoGlobalUsed IN MemMenu.MenuFlags) THEN
      Dec(NumCmds,GlobalCmds);
    CmdToList := 0;
    WHILE (CmdToList < NumCmds) AND (NOT Abort) AND (NOT HangUp) DO
    BEGIN
      Inc(CmdToList);
      CmdNotHid := FALSE;
      Acc := OkSecurity(CmdToList,CmdNotHid);
      IF (((Acc) OR (UnHidden IN MemCmd^[CmdToList].CmdFlags)) AND (NOT (Hidden IN MemCmd^[CmdToList].CmdFlags))) THEN
      BEGIN
        IF (MemCmd^[CmdToList].CKeys = 'GTITLE') THEN
        BEGIN
          IF (OnLin <> 0) THEN
            PrintACR(TempStr);
          PrintACR(TCentered(MaxRight,MemCmd^[CmdToList].LDesc));
          TempStr := '';
          OnLin := 0;
          IF (MemCmd^[CmdToList].Options <> '') THEN
            NewGColors(MemCmd^[CmdToList].Options);
        END
        ELSE
        BEGIN
          IF (MemCmd^[CmdToList].SDesc <> '') THEN
          BEGIN
            Inc(OnLin);
            TempStr1 := GenColored(MemCmd^[CmdToList].CKeys,MemCmd^[CmdToList].SDesc,Acc);
            IF (OnLin <> NumCols) THEN
              TempStr1 := PadLeftStr(TempStr1,ColSiz);
            TempStr := TempStr + TempStr1;
          END;
          IF (OnLin = NumCols) THEN
          BEGIN
            OnLin := 0;
            PrintACR(TempStr);
            TempStr := '';
          END;
        END;
      END;
    END;
    IF (NoGlobalDisplayed IN MemMenu.MenuFlags) OR (NoGlobalUsed IN MemMenu.MenuFlags) THEN
      Inc(NumCmds,GlobalCmds);
    IF (OnLin > 0) THEN
      PrintACR(TempStr);
  END;

BEGIN
  FOR Counter := 1 TO 3 DO
    GColors[Counter] := MemMenu.GCol[Counter];
  NumCols := MemMenu.GenCols;
  CASE NumCols OF
    2 : ColSiz := 39;
    3 : ColSiz := 25;
    4 : ColSiz := 19;
    5 : ColSiz := 16;
    6 : ColSiz := 12;
    7 : ColSiz := 11;
  END;
  IF ((NumCols * ColSiz) >= ThisUser.LineLen) THEN
    NumCols := (ThisUser.LineLen DIV ColSiz);
  DisplayingMenu := TRUE;
  IF (ListType = 2) THEN
    GenNorm
  ELSE
    GenTuto;
  DisplayingMenu := FALSE;
END;

PROCEDURE ShowThisMenu;
VAR
  TempStr: AStr;
BEGIN
  CASE CurHelpLevel OF
    2 : BEGIN
          DisplayingMenu := TRUE;
          NoFile := TRUE;
          TempStr := MemMenu.Directive;
          IF (TempStr <> '') THEN
          BEGIN
            IF (Pos('@S',TempStr) > 0) THEN
              PrintF(Substitute(TempStr,'@S',IntToStr(ThisUser.SL)));
            IF (NoFile) THEN
              PrintF(Substitute(TempStr,'@S',''));
          END;
          DisplayingMenu := FALSE;
        END;
    3 : BEGIN
          DisplayingMenu := TRUE;
          NoFile := TRUE;
          TempStr := MemMenu.LongMenu;
          IF (TempStr <> '') THEN
          BEGIN
            IF (Pos('@C',TempStr) <> 0) THEN
              PrintF(Substitute(TempStr,'@C',CurrentConf));
            IF (NoFile) AND (Pos('@S',TempStr) <> 0) THEN
              PrintF(Substitute(TempStr,'@S',IntToStr(ThisUser.SL)));
            IF (NoFile) THEN
              PrintF(Substitute(TempStr,'@S',''));
          END;
          DisplayingMenu := FALSE;
        END;
  END;
  IF ((NoFile) AND (CurHelpLevel IN [2,3])) THEN
    GenericMenu(CurHelpLevel);
END;

END.
