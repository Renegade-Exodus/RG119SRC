{$IFDEF WIN32}
{$I DEFINES.INC}
{$ENDIF}

{$A+,B+,D+,E+,F+,I+,L+,N-,O+,R-,S+,V-}
UNIT SysOp7;

INTERFACE

USES
 Common;

PROCEDURE FindMenu(DisplayStr: AStr;
                   VAR MenuNum: Byte;
                   LowMenuNum,
                   HighMenuNum: Byte;
                   VAR Changed: Boolean);
PROCEDURE MenuEditor;

IMPLEMENTATION

USES
  Common5,
  Menus2,
  SysOp7M;

PROCEDURE DisplayMenus(VAR RecNumToList1: Integer; DisplayListNum: Boolean);
VAR
  NumDone: Byte;
BEGIN
  Abort := FALSE;
  Next := FALSE;
  AllowContinue := TRUE;
  MCIAllowed := FALSE;
  CLS;
  IF (DisplayListNum) THEN
  BEGIN
    PrintACR('^0###^4:^3Menu #^4:^3Menu name');
    PrintACR('^4===:======:====================================================================');
  END
  ELSE
  BEGIN
    PrintACR('^0Menu #^4:^3Menu name');
    PrintACR('^4======:====================================================================');
  END;
  Reset(MenuFile);
  NumDone := 0;
  WHILE (NumDone < (PageLength - 7)) AND (RecNumToList1 >= 1) AND (RecNumToList1 <= NumMenus)
        AND (NOT Abort) AND (NOT HangUp) DO
  BEGIN
    Seek(MenuFile,MenuRecNumArray[RecNumToList1]);
    Read(MenuFile,MenuR);
    WITH MenuR DO
    BEGIN
      IF (DisplayListNum) THEN
        PrintACR('^0'+PadRightInt(RecNumToList1,3)+
                 ' ^5'+PadRightInt(MenuNum,6)+
                 ' ^3'+PadLeftStr(LDesc[1],68))
      ELSE
        PrintACR('^5'+PadRightInt(MenuNum,6)+
                 ' ^3'+PadLeftStr(LDesc[1],68));
    END;
    Inc(RecNumToList1);
    Inc(NumDone);
  END;
  Close(MenuFile);
  LastError := IOResult;
  MCIAllowed := TRUE;
  AllowContinue := FALSE;
  IF (NumMenus = 0) THEN
     Print('*** No menus defined ***');
  IF (DisplayListNum) THEN
    PrintACR('%LF^1[Users start at menu number: ^5'+IntToStr(General.AllStartMenu)+'^1]');
END;

PROCEDURE FindMenu(DisplayStr: AStr;
                   VAR MenuNum: Byte;
                   LowMenuNum,
                   HighMenuNum: Byte;
                   VAR Changed: Boolean);
VAR
  TempMenuR: MenuRec;
  InputStr: AStr;
  SaveMenuNum: Byte;
  RecNum,
  RecNum1,
  RecNumToList: Integer;
BEGIN
  SaveMenuNum := MenuNum;
  RecNumToList := 1;
  InputStr := '?';
  REPEAT
    IF (InputStr = '?') THEN
      DisplayMenus(RecNumToList,FALSE);
    Prt(DisplayStr+' (^5'+IntToStr(LowMenuNum)+'^4-^5'+IntToStr(HighMenuNum)+'^4)'+
        ' [^5?^4=^5First^4,^5<CR>^4=^5Next^4,^5Q^4=^5Quit^4): ');
    MPL(Length(IntToStr(NumMenus)));
    ScanInput(InputStr,'Q?'^M);
    IF (InputStr = '-') THEN
      InputStr := 'Q';
    IF (InputStr <> 'Q') THEN
    BEGIN
      IF (InputStr = ^M) THEN
      BEGIN
        InputStr := '?';
        IF (RecNumToList < 1) OR (RecNumToList > NumMenus) THEN
          RecNumToList := 1
      END
      ELSE IF (InputStr = '?') THEN
        RecNumToList := 1
      ELSE IF (StrToInt(InputStr) < LowMenuNum) OR (StrToInt(InputStr) > HighMenuNum) THEN
        Print('%LF^7The range must be from '+IntToStr(LowMenuNum)+' to '+IntToStr(HighMenuNum)+'!^1')
      ELSE IF (InputStr = '0') AND (LowMenuNum = 0) THEN
      BEGIN
        MenuNum := StrToInt(InputStr);
        InputStr := 'Q';
        Changed := TRUE;
      END
      ELSE
      BEGIN
        RecNum1 := -1;
        RecNum := 1;

        Reset(MenuFile);

        WHILE (RecNum <= NumMenus) AND (RecNum1 = -1) DO
        BEGIN
          Seek(MenuFile,MenuRecNumArray[RecNum]);
          Read(MenuFile,TempMenuR);
          IF (StrToInt(InputStr) = TempMenuR.MenuNum) THEN
            RecNum1 := TempMenuR.MenuNum;
          Inc(RecNum);
        END;

        Close(MenuFile);

        IF (RecNum1 = -1) THEN
        BEGIN
          RGNoteStr(2,FALSE);
          MenuNum := SaveMenuNum;
        END
        ELSE
        BEGIN
          MenuNum := StrToInt(InputStr);
          InputStr := 'Q';
          Changed := TRUE;
        END;
      END;
    END;
  UNTIL (InputStr = 'Q') OR (HangUp);
END;

PROCEDURE MenuEditor;
VAR
  Cmd: Char;
  SaveCurMenu: Byte;
  RecNumToList: Integer;
  SaveTempPause: Boolean;

  FUNCTION DisplayMenuFlags(MenuFlags: MenuFlagSet; C1,C2: Char): AStr;
  VAR
    MenuFlagT: MenuFlagType;
    TempS: AStr;
  BEGIN
    TempS := '';
    FOR MenuFlagT := ClrScrBefore TO NoGlobalUsed DO
      IF (MenuFlagT IN MenuFlags) THEN
        TempS := TempS + '^'+C1+Copy('CDTNPAF12345',(Ord(MenuFlagT) + 1),1)
      ELSE
        TempS := TempS + '^'+C2+'-';
    DisplayMenuFlags := TempS;
  END;

  PROCEDURE ToggleMenuFlag(MenuFlagT: MenuFlagType; VAR MenuFlags: MenuFlagSet);
  BEGIN
    IF (MenuFlagT IN MenuFlags) THEN
      Exclude(MenuFlags,MenuFlagT)
    ELSE
      Include(MenuFlags,MenuFlagT);
  END;

  PROCEDURE ToggleMenuFlags(C: Char; VAR MenuFlags: MenuFlagSet; VAR Changed: Boolean);
  VAR
    TempMenuFlags: MenuFlagSet;
  BEGIN
    TempMenuFlags := MenuFlags;
    CASE C OF
      'C' : ToggleMenuFlag(ClrScrBefore,MenuFlags);
      'D' : ToggleMenuFlag(DontCenter,MenuFlags);
      'T' : ToggleMenuFlag(NoMenuTitle,MenuFlags);
      'N' : ToggleMenuFlag(NoMenuPrompt,MenuFlags);
      'P' : ToggleMenuFlag(ForcePause,MenuFlags);
      'A' : ToggleMenuFlag(AutoTime,MenuFlags);
      'F' : ToggleMenuFlag(ForceLine,MenuFlags);
      '1' : ToggleMenuFlag(NoGenericAnsi,MenuFlags);
      '2' : ToggleMenuFlag(NoGenericAvatar,MenuFlags);
      '3' : ToggleMenuFlag(NoGenericRIP,MenuFlags);
      '4' : ToggleMenuFlag(NoGlobalDisplayed,MenuFlags);
      '5' : ToggleMenuFlag(NoGlobalUsed,MenuFlags);
    END;
    IF (MenuFlags <> TempMenuFlags) THEN
      Changed := TRUE;
  END;

  PROCEDURE InitMenuVars(VAR MenuR: MenuRec);
  BEGIN
    FillChar(MenuR,SizeOf(MenuR),0);
    WITH MenuR DO
    BEGIN
      LDesc[1] := '<< New Menu >>';
      LDesc[2] := '';
      LDesc[3] := '';
      ACS := '';
      NodeActivityDesc := '';
      Menu := TRUE;
      MenuFlags := [AutoTime];
      LongMenu := '';
      MenuNum := 0;
      MenuPrompt := 'Command? ';
      Password := '';
      FallBack := 0;
      Directive := '';
      ForceHelpLevel := 0;
      GenCols := 4;
      GCol[1] := 4;
      GCol[2] := 3;
      GCol[3] := 5;
    END;
  END;

  PROCEDURE DeleteMenu;
  VAR
    RecNumToDelete,
    RecNum: SmallInt;
    DeleteOk: Boolean;
  BEGIN
    IF (NumMenus = 0) THEN
      Messages(4,0,'menus')
    ELSE
    BEGIN
      RecNumToDelete := -1;
      InputIntegerWOC('%LFMenu number to delete?',RecNumToDelete,[NumbersOnly],1,NumMenus);
      IF (RecNumToDelete >= 1) AND (RecNumToDelete <= NumMenus) THEN
      BEGIN
        Reset(MenuFile);
        Seek(MenuFile,MenuRecNumArray[RecNumToDelete]);
        Read(MenuFile,MenuR);
        Close(MenuFile);
        LastError := IOResult;
        DeleteOK := TRUE;
        IF (MenuR.MenuNum = General.AllStartMenu) THEN
        BEGIN
          Print('%LFYou can not delete the menu new users start at.');
          DeleteOK := FALSE;
        END
        ELSE IF (MenuR.MenuNum = General.NewUserInformationMenu) THEN
        BEGIN
          Print('%LFYou can not delete the new user information menu.');
          DeleteOK := FALSE;
        END
        ELSE IF (MenuR.MenuNum = General.FileListingMenu) THEN
        BEGIN
          Print('%LFYou can not delete the file listing menu.');
          DeleteOK := FALSE;
        END
        ELSE IF (MenuR.MenuNum = General.MessageReadMenu) THEN
        BEGIN
          Print('%LFYou can not delete the message read menu.');
          DeleteOK := FALSE;
        END
        ELSE IF (CmdNumArray[RecNumToDelete] <> 0) THEN
        BEGIN
          Print('%LFThis menu is not empty.');
          DeleteOK := FALSE;
        END;
        IF (NOT DeleteOK) THEN
          PauseScr(FALSE)
        ELSE
        BEGIN
          Print('%LFMenu: ^5'+MenuR.LDesc[1]);
          IF PYNQ('%LFAre you sure you want to delete it? ',0,FALSE) THEN
          BEGIN
            Print('%LF[> Deleting menu record ...');
            SysOpLog('* Deleted menu: ^5'+MenuR.LDesc[1]);
            RecNumToDelete := MenuRecNumArray[RecNumToDelete];  { Convert To Real Record Number }
            Reset(MenuFile);
            IF (RecNumToDelete >= 0) AND (RecNumToDelete <= (FileSize(MenuFile) - 2)) THEN
              FOR RecNum := RecNumToDelete TO (FileSize(MenuFile) - 2) DO
              BEGIN
                Seek(MenuFile,(RecNum + 1));
                Read(MenuFile,MenuR);
                Seek(MenuFile,RecNum);
                Write(MenuFile,MenuR);
              END;
            Seek(MenuFile,(FileSize(MenuFile) - 1));
            Truncate(MenuFile);
            LoadMenuPointers;
            Close(MenuFile);
            LastError := IOResult;
          END;
        END;
      END;
    END;
  END;

  PROCEDURE InsertMenu;
  VAR
    RecNumToInsertBefore,
    NewMenuNum,
    RecNum: SmallInt;
  BEGIN
    IF (NumMenus = MaxMenus) THEN
      Messages(5,MaxMenus,'menus')
    ELSE
    BEGIN
      RecNumToInsertBefore := -1;
      InputIntegerWOC('%LFMenu number to insert before?',RecNumToInsertBefore,[NumbersOnly],1,(NumMenus + 1));
      IF (RecNumToInsertBefore >= 1) AND (RecNumToInsertBefore <= (NumMenus + 1)) THEN
      BEGIN
        Print('%LF[> Inserting menu record ...');
        SysOpLog('* Inserted 1 menu.');
        IF (RecNumToInsertBefore = (NumMenus + 1)) THEN
          MenuRecNumArray[RecNumToInsertBefore] := (MenuRecNumArray[NumMenus] + CmdNumArray[NumMenus] + 1);
        RecNumToInsertBefore := MenuRecNumArray[RecNumToInsertBefore];  {Convert To Real Record Number }
        NewMenuNum := 0;
        Reset(MenuFile);
        RecNum := 1;
        WHILE (RecNum <= NumMenus) DO
        BEGIN
          Seek(MenuFile,MenuRecNumArray[RecNum]);
          Read(MenuFile,MenuR);
          IF (MenuR.MenuNum > NewMenuNum) THEN
            NewMenuNum := MenuR.MenuNum;
          Inc(RecNum);
        END;
        FOR RecNum := 1 TO 1 DO
        BEGIN
          Seek(MenuFile,FileSize(MenuFile));
          Write(MenuFile,MenuR);
        END;
        FOR RecNum := ((FileSize(MenuFile) - 1) - 1) DOWNTO RecNumToInsertBefore DO
        BEGIN
          Seek(MenuFile,RecNum);
          Read(MenuFile,MenuR);
          Seek(MenuFile,(RecNum + 1));
          Write(MenuFile,MenuR);
        END;
        InitMenuVars(MenuR);
        FOR RecNum := RecNumToInsertBefore TO ((RecNumToInsertBefore + 1) - 1) DO
        BEGIN
          Seek(MenuFile,RecNum);
          MenuR.MenuNum := (NewMenuNum + 1);
          Write(MenuFile,MenuR);
        END;
        LoadMenuPointers;
        Close(MenuFile);
        LastError := IOResult;
      END;
    END;
  END;

  PROCEDURE ModifyMenu;
  VAR
    TempMenuR: MenuRec;
    Cmd1: Char;
    SaveMenuNum: Byte;
    RecNum,
    RecNum1,
    RecNumToModify,
    SaveRecNumToModify: SmallInt;
    Changed: Boolean;
  BEGIN
    IF (NumMenus = 0) THEN
      Messages(4,0,'menus')
    ELSE
    BEGIN
      RecNumToModify := -1;
      InputIntegerWOC('%LFMenu number to modify?',RecNumToModify,[NumbersOnly],1,NumMenus);
      IF (RecNumToModify >= 1) AND (RecNumToModify <= NumMenus) THEN
      BEGIN
        SaveRecNumToModify := -1;
        Cmd1 := #0;
        Reset(MenuFile);
        WHILE (Cmd1 <> 'Q') AND (NOT HangUp) DO
        BEGIN
          IF (SaveRecNumToModify <> RecNumToModify) THEN
          BEGIN
            Seek(MenuFile,MenuRecNumArray[RecNumToModify]);
            Read(MenuFile,MenuR);
            SaveRecNumToModify := RecNumToModify;
            Changed := FALSE;
          END;
          WITH MenuR DO
            REPEAT
              IF (Cmd1 <> '?') THEN
              BEGIN
                Abort := FALSE;
                Next := FALSE;
                MCIAllowed := FALSE;
                CLS;
                PrintACR('^5Menu #'+IntToStr(RecNumToModify)+' of '+IntToStr(NumMenus));
                NL;
                PrintACR('^11. Menu number   : ^5'+IntToStr(MenuNum));
                PrintACR('^12. Menu titles   : ^5'+LDesc[1]);
                IF (LDesc[2] <> '') THEN
                  PrintACR('^1   Menu title #2 : ^5'+LDesc[2]);
                IF (LDesc[3] <> '') THEN
                  PrintACR('^1   Menu title #3 : ^5'+LDesc[3]);
                PrintACR('^13. Help files    : ^5'+AOnOff((Directive = ''),'*Generic*',Directive)+'/'+
                                               AOnOff((LongMenu = ''),'*Generic*',LongMenu));
                PrintACR('^14. Menu prompt   : ^5'+MenuPrompt);
                PrintACR('^15. ACS required  : ^5"'+ACS+'"');
                PrintACR('^16. Password      : ^5'+AOnOff((Password = ''),'*None*',Password));
                PrintACR('^17. Fallback menu : ^5'+IntToStr(FallBack));
                PrintACR('^18. Forced ?-level: ^5'+AOnOff((ForceHelpLevel=0),'*None*',IntToStr(ForceHelpLevel)));
                PrintACR('^19. Generic info  : ^5'+IntToStr(GenCols)+' cols - '+IntToStr(GCol[1])+'/'+IntToStr(GCol[2])+
                                                   '/'+IntToStr(GCol[3]));
                IF (General.MultiNode) THEN
                  PrintACR('^1N. Node activity : ^5'+NodeActivityDesc);
                PrintACR('^1T. Flags         : ^5'+DisplayMenuFlags(MenuFlags,'5','1'));
                MCIAllowed := TRUE;
                Print('%LF^1[Commands on this menu: ^5'+IntToStr(CmdNumArray[RecNumToModify])+'^1]');
                IF (NumMenus = 0) THEN
                  Print('*** No menus defined ***');
              END;
              IF (General.MultiNode) THEN
                LOneK('%LFModify menu [^5C^4=^5Command Editor^4,^5?^4=^5Help^4]: ',Cmd1,'Q123456789CNT[]FJL?'^M,TRUE,TRUE)
              ELSE
                LOneK('%LFModify menu [^5C^4=^5Command Editor^4,^5?^4=^5Help^4]: ',Cmd1,'Q123456789CT[]FJL?'^M,TRUE,TRUE);
              CASE Cmd1 OF
                '1' : BEGIN
                        REPEAT
                          SaveMenuNum := MenuNum;
                          RecNum1 := -1;
                          InputByteWC('%LFNew menu number',MenuNum,[DisplayValue,NumbersOnly],1,(NumMenus + 1),Changed);
                          IF (MenuNum <> SaveMenuNum) AND (MenuNum >= 1) AND (MenuNum <= (NumMenus + 1)) THEN
                          BEGIN
                            RecNum := 1;
                            WHILE (Recnum <= NumMenus) AND (RecNum1 = -1) DO
                            BEGIN
                              Seek(MenuFile,MenuRecNumArray[RecNum]);
                              Read(MenuFile,TempMenuR);
                              IF (MenuNum = TempMenuR.MenuNum) THEN
                                RecNum1 := TempMenuR.MenuNum;
                              Inc(RecNum);
                            END;
                            IF (RecNum1 <> -1) THEN
                            BEGIN
                              NL;
                              Print('^7Duplicate menu number!^1');
                              MenuNum := SaveMenuNum;
                            END;
                          END;
                        UNTIL (RecNum1 = -1) OR (HangUp);
                        Changed := TRUE;
                      END;
                '2' : BEGIN
                        InputWNWC('%LFNew menu title #1: ',LDesc[1],
                                  (SizeOf(LDesc[1]) - 1),Changed);
                        IF (LDesc[1] <> '') THEN
                          InputWNWC('New menu title #2: ',LDesc[2],
                                    (SizeOf(LDesc[2]) - 1),Changed);
                        IF (LDesc[2] <> '') THEN
                          InputWNWC('New menu title #3: ',LDesc[3],
                                    (SizeOf(LDesc[3]) - 1),Changed);
                      END;
                '3' : BEGIN
                        InputWN1('%LFNew file displayed for help: ',Directive,(SizeOf(Directive) - 1),
                                 [InterActiveEdit,UpperOnly],Changed);
                        InputWN1('%LFNew file displayed for extended help: ',LongMenu,(SizeOf(LongMenu) - 1),
                                 [InterActiveEdit,UpperOnly],Changed);
                      END;
                '4' : InputWNWC('%LFNew menu prompt: ',MenuPrompt,(SizeOf(MenuPrompt) - 1),Changed);
                '5' : InputWN1('%LFNew menu ACS: ',ACS,(SizeOf(ACS) - 1),[InterActiveEdit],Changed);
                '6' : InputWN1('%LFNew password: ',Password,(SizeOf(Password) - 1),[InterActiveEdit,UpperOnly],Changed);
                '7' : BEGIN
                        SaveMenuNum := FallBack;
                        IF (Changed) THEN
                        BEGIN
                          Seek(MenuFile,MenuRecNumArray[SaveRecNumToModify]);
                          Write(MenuFile,MenuR);
                          Changed := FALSE;
                        END;
                        Close(MenuFile);
                        FindMenu('%LFNew fallback menu (^50^4=^5None^4)',SaveMenuNum,0,NumMenus,Changed);
                        Reset(MenuFile);
                        Seek(MenuFile,MenuRecNumArray[SaveRecNumToModify]);
                        Read(MenuFile,MenuR);
                        IF (Changed) THEN
                          FallBack := SaveMenuNum;
                      END;
                '8' : InputByteWC('%LFNew forced menu help-level (0=None)',ForceHelpLevel,
                                   [DisplayValue,NumbersOnly],0,3,Changed);
                '9' : BEGIN
                        REPEAT
                          NL;
                          PrintACR('^1C. Generic columns  : ^5'+IntToStr(GenCols));
                          PrintACR('^11. Bracket color    : ^5'+IntToStr(GCol[1]));
                          PrintACR('^12. Command color    : ^5'+IntToStr(GCol[2]));
                          PrintACR('^13. Description color: ^5'+IntToStr(GCol[3]));
                          PrintACR('^1S. Show menu');
                          LOneK('%LFSelect (CS,1-3,Q=Quit): ',Cmd1,'QCS123'^M,TRUE,TRUE);
                          CASE Cmd1 OF
                            'S' : BEGIN
                                    IF (Changed) THEN
                                    BEGIN
                                      Seek(MenuFile,MenuRecNumArray[SaveRecNumToModify]);
                                      Write(MenuFile,MenuR);
                                      Changed := FALSE;
                                    END;
                                    Seek(MenuFile,MenuRecNumArray[SaveRecNumToModify]);
                                    Read(MenuFile,MenuR);
                                    CurMenu := MenuR.MenuNum;
                                    LoadMenu;
                                    Reset(MenuFile);
                                    GenericMenu(2);
                                    NL;
                                    PauseSCR(FALSE);
                                    Seek(MenuFile,MenuRecNumArray[SaveRecNumToModify]);
                                    Read(MenuFile,MenuR);
                                  END;
                            'C' : InputByteWC('%LFNew number of generic columns',GenCols,
                                              [DisplayValue,NumbersOnly],0,7,Changed);
                            '1' : InputByteWC('%LFNew bracket color',GCol[1],[DisplayValue,NumbersOnly],0,9,Changed);
                            '2' : InputByteWC('%LFNew command color',GCol[2],[DisplayValue,NumbersOnly],0,9,Changed);
                            '3' : InputByteWC('%LFNew description color',GCol[3],[DisplayValue,NumbersOnly],0,9,Changed);
                          END;
                        UNTIL (Cmd1 IN ['Q',^M]) OR (HangUp);
                        Cmd1 := #0;
                      END;
                'C' : BEGIN
                        IF (Changed) THEN
                        BEGIN
                          Seek(MenuFile,MenuRecNumArray[SaveRecNumToModify]);
                          Write(MenuFile,MenuR);
                          Changed := FALSE;
                        END;
                        CommandEditor(RecNumToModify,MenuNum,LDesc[1]);
                        SaveRecNumToModify := -1;
                      END;
                'N' : IF (General.MultiNode) THEN
                        InputWNWC('%LF^1New node activity description:%LF^4: ',NodeActivityDesc,
                                  (SizeOf(NodeActivityDesc) - 1),Changed);
                'T' : BEGIN
                        REPEAT
                          LOneK('%LFToggle which flag? ('+DisplayMenuFlags(MenuFlags,'5','4')+'^4)'+
                                ' [^5?^4=^5Help^4,^5<CR>^4=^5Quit^4]: ',Cmd1,^M'CDTNPAF12345?',TRUE,TRUE);
                          CASE Cmd1 OF
                            'C','D','T','N','P','A','F','1'..'5' :
                                    ToggleMenuFlags(Cmd1,MenuFlags,Changed);
                            '?' : BEGIN
                                    NL;
                                    LCmds(21,3,'Clear screen','Don''t center titles');
                                    LCmds(21,3,'No menu prompt','Pause before display');
                                    LCmds(21,3,'Auto Time display','Force line input');
                                    LCmds(21,3,'Titles not displayed','1 No ANS prompt');
                                    LCmds(21,3,'2 No AVT prompt','3 No RIP prompt');
                                    LCmds(21,3,'4 No Global disp','5 No global use');
                                  END;
                          END;
                        UNTIL (Cmd1 = ^M) OR (HangUp);
                        Cmd1 := #0;
                      END;
                '[' : IF (RecNumToModify > 1) THEN
                        Dec(RecNumToModify)
                      ELSE
                      BEGIN
                        Messages(2,0,'');
                        Cmd1 := #0;
                      END;
                ']' : IF (RecNumToModify < NumMenus) THEN
                        Inc(RecNumToModify)
                      ELSE
                      BEGIN
                        Messages(3,0,'');
                        Cmd1 := #0;
                      END;
                'F' : IF (RecNumToModify <> 1) THEN
                        RecNumToModify := 1
                      ELSE
                      BEGIN
                        Messages(2,0,'');
                        Cmd1 := #0;
                      END;
                'J' : BEGIN
                        InputIntegerWOC('%LFJump to entry?',RecNumToModify,[NumbersOnly],1,NumMenus);
                        IF (RecNumToModify < 1) AND (RecNumToModify > NumMenus) THEN
                          Cmd1 := #0;
                      END;
                'L' : IF (RecNumToModify <> NumMenus) THEN
                        RecNumToModify := NumMenus
                      ELSE
                      BEGIN
                        Messages(3,0,'');
                        Cmd1 := #0;
                      END;
                '?' : BEGIN
                        Print('%LF^1<^3CR^1>Redisplay screen');
                        Print('^31-9,C,N,T^1:Modify item');
                        LCmds(16,3,'[Back entry',']Forward entry');
                        LCmds(16,3,'Command Editor','First entry in list');
                        LCmds(16,3,'Jump to entry','Last entry in list');
                        LCmds(16,3,'Quit and save','');
                      END;
              END;
            UNTIL (Pos(Cmd1,'QC[]FJL') <> 0) OR (HangUp);
          IF (Changed) THEN
          BEGIN
            Seek(MenuFile,MenuRecNumArray[SaveRecNumToModify]);
            Write(MenuFile,MenuR);
            Changed := FALSE;
            SysOpLog('* Modified menu: ^5'+Menur.LDesc[1]);
          END;
        END;
        Close(MenuFile);
        LastError := IOResult;
      END;
    END;
  END;

BEGIN
  LoadMenuPointers;
  SaveTempPause := TempPause;
  TempPause := FALSE;
  RecNumToList := 1;
  Cmd := #0;
  REPEAT
    IF (Cmd <> '?') THEN
      DisplayMenus(RecNumToList,TRUE);
    LOneK('%LFMenu editor [^5?^4=^5Help^4]: ',Cmd,'QDIM?'^M,TRUE,TRUE);
    CASE Cmd OF
      ^M  : IF (RecNumToList < 1) OR (RecNumToList > NumMenus) THEN
              RecNumToList := 1;
      'D' : DeleteMenu;
      'I' : InsertMenu;
      'M' : ModifyMenu;
      '?' : BEGIN
              Print('%LF^1<^3CR^1>Redisplay screen');
              LCmds(12,3,'Delete menu','Insert menu');
              LCmds(12,3,'Modify menu','Quit');
            END;
    END;
    IF (CMD <> ^M) THEN
      RecNumToList := 1;
  UNTIL (Cmd = 'Q') OR (HangUp);
  TempPause := SaveTempPause;
  LastError := IOResult;
  LoadMenuPointers;
  IF (UserOn) THEN
  BEGIN
    SaveCurMenu := CurMenu;
    NumCmds := 0;
    GlobalCmds := 0;
    IF (General.GlobalMenu > 0) THEN
    BEGIN
      CurMenu := General.GlobalMenu;
      LoadMenu;
      GlobalCmds := NumCmds;
    END;
    CurMenu := SaveCurMenu;
    LoadMenu;
  END;
END;

END.
