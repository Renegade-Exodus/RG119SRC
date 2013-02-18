{$IFDEF WIN32}
{$I DEFINES.INC}
{$ENDIF}

{$A+,B-,D+,E-,F+,I-,L+,N-,O-,R-,S+,V-}

UNIT Menus;

INTERFACE

USES
  Common,
  MyIO;

PROCEDURE AutoExecCmd(AutoCmd: AStr);
PROCEDURE MenuExec;
PROCEDURE LoadMenuPW;
PROCEDURE MainMenuHandle(VAR Cmd: AStr);
PROCEDURE FCmd(CONST Cmd: AStr; VAR CmdToExec: Byte; VAR CmdExists,CmdNotHid: Boolean);
PROCEDURE DoMenuExec(Cmd: AStr; VAR NewMenuCmd: AStr);
PROCEDURE DoMenuCommand(VAR Done: Boolean;
                        Cmd,
                        MenuOption: AStr;
                        VAR NewMenuCmd: AStr;
                        NodeActivityDesc: AStr);

IMPLEMENTATION

USES
  Arcview,
  Archive1,
  Archive2,
  Archive3,
  Automsg,
  BBSList,
  Boot,
  Bulletin,
  CUser,
  Doors,
  Email,
  File0,
  File1,
  File2,
  File3,
  File5,
  File6,
  File7,
  File8,
  File9,
  File10,
  File11,
  File12,
  File13,
  File14,
  Mail0,
  Mail1,
  Mail2,
  Mail3,
  Mail4,
  Menus2,
  Menus3,
  MiscUser,
  MsgPack,
  Multnode,
  OffLine,
  Script,
  Stats,
  LineChat,
  Sysop1,
  Sysop2,
  SysOp2G,
  Sysop3,
  Sysop4,
  SysOp5,
  Sysop6,
  Sysop7,
  Sysop8,
  Sysop9,
  Sysop10,
  Sysop11,
  SysOp12,
  TimeBank,
  TimeFunc,
  Vote;


    (*
    I := 1;
    Newmenucmd := '';
    while ((I <= Noc) and (Newmenucmd = '') ) do
    begin
      if (Menucommand^[I].Ckeys = 'FIRSTCMD') then
      begin
        if (Aacs(Menucommand^[I].Acs)) then
        begin
          Newmenucmd := 'FIRSTCMD';
          Domenuexec(Cmd,Newmenucmd);
        end;
      end;
      inc(I);
    end;
    *)
PROCEDURE AutoExecCmd(AutoCmd: AStr);
VAR
  NewMenuCmd: AStr;
  Counter: Byte;
  Done: Boolean;
BEGIN
  NewMenuCmd := '';
  Done := FALSE;
  Counter := 1;
  WHILE (Counter <= NumCmds) AND (NewMenuCmd = '') AND (NOT Done) AND (NOT HangUp) DO
  BEGIN
    IF (MemCmd^[Counter].Ckeys = AutoCmd) then
      IF (AACS(MemCmd^[Counter].ACS)) THEN
      BEGIN
        NewMenuCmd := AutoCmd;
        DoMenuCommand(Done,
                      MemCmd^[Counter].CmdKeys,
                      MemCmd^[Counter].Options,
                      NewMenuCmd,
                      MemCmd^[Counter].NodeActivityDesc);
      END;
    Inc(Counter);
  END;
END;

PROCEDURE MenuExec;
VAR
  Cmd,
  NewMenuCmd: AStr;
  Done: Boolean;
BEGIN
  MainMenuHandle(Cmd);
  IF ((Copy(Cmd,1,2) = '\\') AND (SysOp)) THEN
  BEGIN
    DoMenuCommand(Done,Copy(Cmd,1,2),Copy(Cmd,3,Length(Cmd) - 2),NewMenuCmd,'Activating SysOp Cmd');
    IF (NewMenuCmd <> '') THEN
      Cmd := NewMenuCmd
    ELSE
      Cmd := '';
  END;
  NewMenuCmd := '';
  REPEAT
    DoMenuExec(Cmd,NewMenuCmd)
  UNTIL (NewMenuCmd = '') OR (HangUp);
END;

PROCEDURE CheckHelpLevel;
BEGIN
  IF (MemMenu.ForceHelpLevel <> 0) THEN
    CurHelpLevel := MemMenu.ForceHelpLevel
  ELSE IF (Novice IN ThisUser.Flags) OR (OkRIP) THEN
    CurHelpLevel := 2
  ELSE
    CurHelpLevel := 1;
END;

PROCEDURE LoadMenuPW;
VAR
  s: Str20;
  NACC: Boolean;
BEGIN
  LoadMenu;
  NACC := FALSE;
  IF (NOT AACS(MemMenu.ACS)) OR (MemMenu.Password <> '') THEN
  BEGIN
    NACC := TRUE;
    IF (MemMenu.Password <> '') THEN
    BEGIN
      NL;
      Prt('Password: ');
      GetPassword(s,20);
      IF (s = MemMenu.Password) THEN
        NACC := FALSE;
    END;
    IF (NACC) THEN
    BEGIN
      PrintF('NOACCESS');
      IF (NoFile) THEN
      BEGIN
        NL;
        Print('Access denied.');
        PauseScr(FALSE);
      END;
      CurMenu := FallBackMenu;
      LoadMenu;
    END;
  END;
  IF (NOT NACC) THEN
    CheckHelpLevel;
END;

PROCEDURE CheckForceLevel;
BEGIN
  IF (CurHelpLevel < MemMenu.ForceHelpLevel) THEN
    CurHelpLevel := MemMenu.ForceHelpLevel;
END;

PROCEDURE GetCmd(VAR Cmd: AStr);
VAR
  S1,
  SS,
  SaveSS,
  SHas0,
  SHas1: AStr;
  C: Char;
  CmdToExec,
  Counter,
  SaveCurrentColor: Byte;
  Key: Word;
  GotCmd,
  Has0,
  Has1,
  Has2: Boolean;
BEGIN
  Cmd := '';
  IF (Buf <> '') THEN
    IF (Buf[1] = '`') THEN
    BEGIN
      Buf := Copy(Buf,2,(Length(Buf) - 1));
      Counter := Pos('`',Buf);
      IF (Counter <> 0) THEN
      BEGIN
        Cmd := AllCaps(Copy(Buf,1,(Counter - 1)));
        Buf := Copy(Buf,(Counter + 1),(Length(Buf) - Counter));
        NL;
        Exit;
      END;
    END;

  SHas0 := '?';
  SHas1 := '';
  Has0 := FALSE;
  Has1 := FALSE;
  Has2 := FALSE;


  FOR CmdToExec := 1 TO NumCmds DO
    IF ((CmdToExec <= (NumCmds - GlobalCmds)) OR NOT (NoGlobalUsed IN MemMenu.MenuFlags)) THEN
      IF (AACS(MemCmd^[CmdToExec].ACS)) THEN
        IF (MemCmd^[CmdToExec].CKeys[0] = #1) THEN
        BEGIN
          Has0 := TRUE;
          SHas0 := SHas0 + MemCmd^[CmdToExec].CKeys;
        END
        ELSE IF ((MemCmd^[CmdToExec].CKeys[1] = '/') AND (MemCmd^[CmdToExec].CKeys[0] = #2)) THEN
        BEGIN
          Has1 := TRUE;
          SHas1 := SHas1 + MemCmd^[CmdToExec].CKeys[2];
        END
        ELSE
          Has2 := TRUE;

  SaveCurrentColor := CurrentColor;

  GotCmd := FALSE;
  SS := '';

  IF (Trapping) THEN
    Flush(TrapFile);

  IF (NOT (HotKey IN ThisUser.Flags)) OR (ForceLine IN MemMenu.MenuFlags) THEN
    InputMain(Cmd,60,[UpperOnly,NoLineFeed])
  ELSE
  BEGIN

    REPEAT

      Key := GetKey;
      IF (Key = F_UP) OR (Key = F_DOWN) OR (Key = F_LEFT) OR (Key = F_RIGHT) THEN
      BEGIN
        CASE Key OF
          F_UP : IF (Pos(#255,MenuKeys) > 0) THEN
                 BEGIN
                   Cmd := 'UP_ARROW';
                   GotCmd := TRUE;
                   Exit;
                 END;
          F_DOWN :
                 IF (Pos(#254,MenuKeys) > 0) THEN
                 BEGIN
                   Cmd := 'DOWN_ARROW';
                   GotCmd := TRUE;
                   Exit;
                 END;
          F_LEFT :
                 IF (Pos(#253,MenuKeys) > 0) THEN
                 BEGIN
                   Cmd := 'LEFT_ARROW';
                   GotCmd := TRUE;
                   Exit;
                 END;
          F_RIGHT :
                 IF (Pos(#252,MenuKeys) > 0) THEN
                 BEGIN
                   Cmd := 'RIGHT_ARROW';
                   GotCmd := TRUE;
                   Exit;
                 END;
        END;
      END;

      C := UpCase(Char(Key));
      SaveSS := SS;
      IF (SS = '') THEN
      BEGIN
        IF (C = #13) THEN
          GotCmd := TRUE;
        IF ((C = '/') AND ((Has1) OR (Has2) OR (SysOp))) THEN
          SS := '/';
        IF (((FQArea) OR (RQArea) OR (MQArea) OR (VQArea)) AND (C IN ['0'..'9'])) THEN
        BEGIN
          SS := C;
          IF (RQArea) AND (HiMsg <= 9) THEN
            GotCmd := TRUE
          ELSE IF (FQArea) AND (NumFileAreas <= 9) THEN
            GotCmd := TRUE
          ELSE IF (MQArea) AND (NumMsgAreas <= 9) THEN
            GotCmd := TRUE
          ELSE IF (VQArea) AND (GetTopics <= 9) THEN
            GotCmd := TRUE;
        END
        ELSE IF (Pos(C,SHas0) <> 0) THEN
        BEGIN
          GotCmd := TRUE;
          SS := C;
        END;
      END
      ELSE IF (SS = '/') THEN
      BEGIN
        IF (C = ^H) THEN
          SS := '';
        IF ((C = '/') AND ((Has2) OR (SysOp))) THEN
          SS := SS + '/';
        IF ((Pos(C,SHas1) <> 0) AND (Has1)) THEN
        BEGIN
          GotCmd := TRUE;
          SS := SS + C;
        END;
      END
      ELSE IF (Copy(SS,1,2) = '//') THEN
      BEGIN
        IF (C = #13) THEN
          GotCmd := TRUE
        ELSE IF (C = ^H) THEN
          Dec(SS[0])
        ELSE IF (C = ^X) THEN
        BEGIN
          FOR Counter := 1 TO (Length(SS) - 2) DO
            BackSpace;
          SS := '//';
          SaveSS := SS;
        END
        ELSE IF ((Length(SS) < 62) AND (C >= #32) AND (C <= #127)) THEN
          SS := SS + C;
      END
      ELSE IF ((Length(SS) >= 1) AND (SS[1] IN ['0'..'9']) AND ((FQArea) OR (RQArea) OR (MQArea) OR (VQArea))) THEN
      BEGIN
        IF (C = ^H) THEN
          Dec(SS[0]);
        IF (C = #13) THEN
          GotCmd := TRUE;
        IF (C IN ['0'..'9']) THEN
        BEGIN
          SS := SS + C;
          IF (VQArea) AND (Length(SS) = Length(IntToStr(GetTopics))) THEN
            GotCmd := TRUE
          ELSE IF (RQArea) AND (Length(SS) = Length(IntToStr(HiMsg))) THEN
            GotCmd := TRUE
          ELSE IF (MQArea) AND (Length(SS) = Length(IntToStr(NumMsgAreas))) THEN
            GotCmd := TRUE
          ELSE IF (FQArea) AND (Length(SS) = Length(IntToStr(NumFileAreas))) THEN
            GotCmd := TRUE;
        END;
      END;

      IF ((Length(SS) = 1) AND (Length(SaveSS) = 2)) THEN
        SetC(SaveCurrentColor);

      IF (SaveSS <> SS) AND (NOT (NoMenuPrompt IN MemMenu.MenuFlags)) THEN
      BEGIN
        IF (Length(SS) > Length(SaveSS)) THEN
          Prompt(SS[Length(SS)]);
        IF (Length(SS) < Length(SaveSS)) THEN
          BackSpace;
      END;

      IF ((NOT (SS[1] IN ['0'..'9'])) AND ((Length(SS) = 2) AND (Length(SaveSS) = 1))) THEN
        UserColor(6);

    UNTIL ((GotCmd) OR (HangUp));

    CursorOn(TRUE);

    UserColor(1);

    IF (Copy(SS,1,2) = '//') THEN
      SS := Copy(SS,3,(Length(SS) - 2));

    Cmd := SS;
  END;

  (* Test *)
  IF (CurMenu <> General.FileListingMenu) THEN
    NL;

  IF (Pos(';',Cmd) <> 0) THEN
    IF (Copy(Cmd,1,2) <> '\\') THEN
    BEGIN
      IF (HotKey IN ThisUser.Flags) THEN
      BEGIN
        S1 := Copy(Cmd,2,(Length(Cmd) - 1));
        IF (Copy(S1,1,1) = '/') THEN
          Cmd := Copy(S1,1,2)
        ELSE
          Cmd := S1[1];
        S1 := Copy(S1,(Length(Cmd) + 1),(Length(S1) - Length(Cmd)));
      END
      ELSE
      BEGIN
        S1 := Copy(Cmd,(Pos(';',Cmd) + 1),(Length(Cmd) - Pos(';',Cmd)));
        Cmd := Copy(Cmd,1,(Pos(';',Cmd) - 1));
      END;
      WHILE (Pos(';',S1) <> 0) DO
        S1[Pos(';',S1)] := ^M;
      Buf := S1;
    END;
END;

PROCEDURE MainMenuHandle(VAR Cmd: AStr);
VAR
  NewArea: Integer;
BEGIN
  TLeft;

  CheckForceLevel;

  IF ((ForcePause IN MemMenu.MenuFlags) AND (CurHelpLevel > 1) AND (LastCommandGood)) THEN
    PauseScr(FALSE);
  LastCommandGood := FALSE;
  MenuAborted := FALSE;
  Abort := FALSE;

  ShowThisMenu;

  AutoExecCmd('EVERYTIME');

  IF (General.MultiNode) THEN
    Check_Status;

  IF ((NOT (NoMenuPrompt IN MemMenu.MenuFlags)) AND (NOT MenuAborted)) AND NOT
     (OKAnsi AND (NoGenericAnsi IN MemMenu.MenuFlags) AND NOT (OkAvatar OR OKRIP)) AND NOT
     (OkAvatar AND (NoGenericAvatar IN MemMenu.MenuFlags) AND NOT OkRIP) AND NOT
     (OkRIP AND (NoGenericRIP IN MemMenu.MenuFlags)) THEN
  BEGIN

    IF (CurMenu <> General.FileListingMenu) THEN
      NL;

    IF (AutoTime IN MemMenu.MenuFlags) THEN
      Print('^3[Time Left:'+CTim(NSL)+']');
    Prompt(MemMenu.MenuPrompt);
  END;

  TempPause := (Pause IN ThisUser.Flags);

  GetCmd(Cmd);

  IF (Cmd = '') AND (Pos(#13,MenuKeys) > 0) THEN
    Cmd := 'ENTER';

  IF (Cmd = '?') THEN
  BEGIN
    Cmd := '';
    Inc(CurHelpLevel);
    IF (CurHelpLevel > 3) THEN
      CurHelpLevel := 3;
  END
  ELSE
    CheckHelpLevel;

  CheckForceLevel;

  IF (FQArea) OR (MQArea) OR (VQArea) OR (RQArea) THEN
  BEGIN
    NewArea := StrToInt(Cmd);
    IF ((NewArea <> 0) OR (Cmd[1] = '0')) THEN
    BEGIN
      IF (FQArea) AND (NewArea >= 1) AND (NewArea <= NumFileAreas) THEN
        ChangeFileArea(CompFileArea(NewArea,1))
      ELSE IF (MQArea) AND (NewArea >= 1) AND (NewArea <= NumMsgAreas) THEN
        ChangeMsgArea(CompMsgArea(NewArea,1))
      ELSE IF (VQArea) AND (NewArea >= 1) AND (NewArea <= NumVotes) THEN
        VoteOne(NewArea)
      ELSE IF (RQArea) AND (NewArea >= 1) AND (NewArea <= HiMsg) THEN
        IF NOT (MAForceRead IN MemMsgArea.MAFlags) OR (NewArea <= Msg_On) THEN
        BEGIN
          Msg_On := (NewArea - 1);
          TReadPrompt := 18;
        END
        ELSE
          Print('You must read all of the messages in this area.');
      Cmd := '';
    END;
  END;
END;

PROCEDURE FCmd(CONST Cmd: AStr; VAR CmdToExec: Byte; VAR CmdExists,CmdNotHid: Boolean);
VAR
  Done: Boolean;
BEGIN
  Done := FALSE;
  REPEAT
    Inc(CmdToExec);
    IF (CmdToExec <= NumCmds) AND (Cmd = MemCmd^[CmdToExec].CKeys) THEN
    BEGIN
      CmdExists := TRUE;
      IF (OkSecurity(CmdToExec,CmdNotHid)) THEN
        Done := TRUE;
    END;
    IF ((CmdToExec > (NumCmds - GlobalCmds)) AND (NoGlobalUsed IN MemMenu.MenuFlags)) THEN
    BEGIN
      CmdToExec := 0;
      CmdExists := FALSE;
      Done := TRUE;
    END;
  UNTIL (CmdToExec > NumCmds) OR (Done) OR (HangUp);
  IF (CmdToExec > NumCmds) THEN
    CmdToExec := 0;
END;

PROCEDURE DoMenuExec(Cmd: AStr; VAR NewMenuCmd: AStr);
VAR
  CmdToExec: Byte;
  CmdACS,
  CmdNotHid,
  CmdExists,
  Done: Boolean;
BEGIN
  IF (NewMenuCmd <> '') THEN
  BEGIN
    Cmd := NewMenuCmd;
    NewMenuCmd := '';
  END;
  CmdACS := FALSE;
  CmdExists := FALSE;
  CmdNotHid := FALSE;
  Done := FALSE;
  CmdToExec := 0;
  REPEAT
    FCmd(Cmd,CmdToExec,CmdExists,CmdNotHid);
    IF (CmdToExec <> 0) THEN
    BEGIN
      CmdACS := TRUE;
      DoMenuCommand(Done,
                    MemCmd^[CmdToExec].CmdKeys,
                    MemCmd^[CmdToExec].Options,
                    NewMenuCmd,
                    MemCmd^[CmdToExec].NodeActivityDesc);
    END;
  UNTIL ((CmdToExec = 0) OR (Done) OR (HangUp));
  IF (NOT Done) AND (Cmd <> '') THEN
    IF ((NOT CmdACS) AND (Cmd <> '')) THEN
    BEGIN
      NL;
      IF ((CmdNotHid) AND (CmdExists)) THEN
        Print('Insufficient clearence for this command.')
      ELSE
        Print('Invalid command.');
    END;
END;

PROCEDURE DoMenuCommand(VAR Done: Boolean;
                        Cmd,
                        MenuOption: AStr;
                        VAR NewMenuCmd: AStr;
                        NodeActivityDesc: AStr);
VAR
  MHeader: MHeaderRec;
  TempStr: AStr;
  SaveMenu: Byte;
  NoCmd: Boolean;
BEGIN
  NewMenuToLoad := FALSE;
  NewMenuCmd := '';
  NoCmd := FALSE;
  Abort := FALSE;
  LastCommandOvr := FALSE;

  IF ((Cmd[1] + Cmd[2]) <> 'NW') THEN
    Update_Node(NodeActivityDesc,TRUE);

  CASE Cmd[1] OF
    '$' : CASE Cmd[2] OF
            'D' : Deposit;
            'W' : Withdraw;
            '+' : Inc(ThisUser.lCredit,StrToInt(MenuOption));
            '-' : Inc(ThisUser.Debit,StrToInt(MenuOption));
          ELSE
            NoCmd := TRUE;
          END;
    '/' : CASE Cmd[2] OF
            'F': BEGIN
                   MCIAllowed := FALSE;
                   PrintF(MCI(MenuOption));
                   MCIAllowed := TRUE;
                 END;
          ELSE
            NoCmd := TRUE;
          END;
    '-' : CASE Cmd[2] OF
            'C' : lStatus_Screen(100,MenuOption,FALSE,MenuOption);
            'F' : PrintF(MCI(MenuOption));
            'L' : Prompt(MenuOption);
            'Q' : ReadQ(General.MiscPath+MenuOption);
            'R' : ReadASW1(MenuOption);
            'S' : SysOpLog(MCI(MenuOption));
            ';' : BEGIN
                    TempStr := MenuOption;
                    WHILE (Pos(';',TempStr) > 0) DO
                      TempStr[Pos(';',TempStr)] := ^M;
                    Buf := TempStr;
                  END;
            '$' : IF (SemiCmd(MenuOption,1) <> '') THEN
                  BEGIN
                    IF (SemiCmd(MenuOption,2) = '') THEN
                      Prt(': ')
                    ELSE
                      Prt(SemiCmd(MenuOption,2));
                    GetPassword(TempStr,20);
                    IF (TempStr <> SemiCmd(MenuOption,1)) THEN
                    BEGIN
                      Done := TRUE;
                      IF (SemiCmd(MenuOption,3) <> '') THEN
                        Print(SemiCmd(MenuOption,3));
                    END;
                  END;
            'Y' : IF (SemiCmd(MenuOption,1) <> '') AND NOT (PYNQ(SemiCmd(MenuOption,1),0,FALSE)) THEN
                  BEGIN
                    Done := TRUE;
                    IF (SemiCmd(MenuOption,2) <> '') THEN
                      Print(SemiCmd(MenuOption,2));
                  END;
            'N' : IF (SemiCmd(MenuOption,1) <> '') AND (PYNQ(SemiCmd(MenuOption,1),0,FALSE)) THEN
                  BEGIN
                    Done := TRUE;
                    IF (SemiCmd(MenuOption,2) <> '') THEN
                      Print(SemiCmd(MenuOption,2));
                  END;
            '^','/','\' :
                  DoChangeMenu(Done,NewMenuCmd,Cmd[2],MenuOption);
          ELSE
            NoCmd := TRUE;
          END;
    'A' : CASE Cmd[2] OF
            'A','C','M','T' :
                  DoArcCommand(Cmd[2]);
            'E' : ExtractToTemp;
            'G' : UserArchive;
            'R' : ReZipStuff;
          ELSE
            NoCmd := TRUE;
          END;
    'B' : CASE Cmd[2] OF
            '?' : BatchDLULInfo;

            'C' : IF (UpCase(MenuOption[1]) = 'U') THEN
                    ClearBatchULQueue
                  ELSE
                    ClearBatchDLQueue;
            'D' : BatchDownload;
            'L' : IF (UpCase(MenuOption[1]) = 'U') THEN
                    ListBatchULFiles
                  ELSE
                    ListBatchDLFiles;
            'R' : IF (UpCase(MenuOption[1]) = 'U') THEN
                    RemoveBatchULFiles
                  ELSE
                    RemoveBatchDLFiles;

            'U' : BatchUpload(FALSE,0);
          ELSE
            NoCmd := TRUE;
          END;
    'D' : CASE Cmd[2] OF
            'P','C','D','G','S','W','-','3' :
                  DoDoorFunc(Cmd[2],MenuOption);
          ELSE
            NoCmd := TRUE;
          END;
    'F' : CASE Cmd[2] OF
            'A' : FileAreaChange(Done,MenuOption);
            'B' : DownloadFile(MenuOption,[lIsAddDLBatch]);
            'C' : CheckFilesBBS;
            'D' : DownloadFile(MenuOption,[]);
            'F' : SearchFileDescriptions;
            'L' : ListFileSpec(MenuOption);
            'N' : NewFilesScanSearchType(MenuOption);
            'P' : SetFileAreaNewScanDate;
            'S' : SearchFileSpec;
            'U' : UploadFile;
            'V' : ViewDirInternalArchive;
            'Z' : ToggleFileAreaScanFlags;
            '@' : CreateTempDir;
            '#' : BEGIN
                    NL;
                    Print('Enter the number of a file area to change to.');
                    IF (Novice IN ThisUser.Flags) THEN
                      PauseScr(FALSE);
                  END;
          ELSE
            NoCmd := TRUE;
          END;
    'H' : CASE Cmd[2] OF
            'C' : IF PYNQ(MenuOption,0,FALSE) THEN
                  BEGIN
                    CLS;
                    PrintF('LOGOFF');
                    HangUp := TRUE;
                    HungUp := FALSE;
                  END;
            'I' : HangUp := TRUE;
            'M' : BEGIN
                    NL;
                    Print(MenuOption);
                    HangUp := TRUE;
                  END;
          ELSE
            NoCmd := TRUE;
          END;
    'L' : CASE Cmd[2] OF
            '1' : TFilePrompt := 1;
            '2' : TFilePrompt := 2;
            '3' : TFilePrompt := 3;
            '4' : TFilePrompt := 4;
            '5' : TFilePrompt := 5;
            '6' : TFilePrompt := 6;
            '7' : TFilePrompt := 7;
            '8' : TFilePrompt := 8;
          ELSE
            NoCmd := TRUE;
          END;
    'M' : CASE Cmd[2] OF
            'A' : MessageAreaChange(Done,MenuOption);
            'E' : SSMail(MenuOption);
            'K' : ShowEMail;
            'L' : SMail(TRUE);
            'M' : ReadMail;
            'N' : StartNewScan(MenuOption);
            'P' : IF (ReadMsgArea = -1) THEN
                  BEGIN
                    NL;
                    Print('^7This option is not available when reading private messages!^1');
                  END
                  ELSE
                  BEGIN
                    IF (MAPrivate IN MemMsgArea.MAFlags) THEN
                    BEGIN
                      NL;
                      Post(-1,MHeader.From,PYNQ('Is this to be a private message? ',0,FALSE))
                    END
                    ELSE
                      Post(-1,MHeader.From,FALSE);
                  END;
            'R' : ReadAllMessages(MenuOption);
            'S' : BEGIN
                    Abort := FALSE;
                    Next := FALSE;
                    ScanMessages(MsgArea,FALSE,MenuOption);
                  END;
            'U' : BEGIN
                    LoadMsgArea(MsgArea);
                    UList(MemMsgArea.ACS);
                  END;
            'Y' : ScanYours;
            'Z' : ToggleMsgAreaScanFlags;
            '#' : BEGIN
                    NL;
                    Print('Enter the number of a message area to change to.');
                    IF (Novice IN ThisUser.Flags) THEN
                      PauseScr(FALSE);
                  END;
          ELSE
            NoCmd := TRUE;
          END;
    'N' : CASE Cmd[2] OF
            'A' : ToggleChatAvailability;
            'D' : Dump_Node;
            'O' : BEGIN
                    LListNodes;
                    IF (Novice IN ThisUser.Flags) THEN
                      PauseScr(FALSE);
                  END;
            'P' : Page_User;
            'G' : MultiLine_Chat;
            'S' : LSend_Message(MenuOption);
            'T' : IF AACS(General.Invisible) THEN
                  BEGIN
                    IsInvisible := NOT IsInvisible;
                    LoadNode(ThisNode);
                    IF (IsInvisible) THEN
                      Include(NodeR.Status,NInvisible)
                    ELSE
                      Exclude(NodeR.Status,NInvisible);
                    SaveNode(ThisNode);
                    NL;
                    Print('Invisible mode is now '+ShowOnOff(IsInvisible));
                  END;
                  (* Consider deleting this cmd *)
            'W' : BEGIN
                    LoadNode(ThisNode);
                    NodeR.ActivityDesc := MenuOption;
                    SaveNode(ThisNode);
                  END;
          ELSE
            NoCmd := TRUE;
          END;
    'O' : CASE Cmd[2] OF
            '1','2' :
                  TShuttleLogon := Ord(Cmd[2]) - 48;
            'A' : AutoValidationCmd(MenuOption);
            'B' : GetUserStats(MenuOption);
            'C' : RequestSysOpChat(MenuOption);
            'F' : ChangeARFlags(MenuOption);
            'G' : ChangeACFlags(MenuOption);
            'L' : BEGIN
                    IF (Pos(';',MenuOption) > 0) THEN
                    BEGIN
                      MenuOption := Copy(MenuOption,Pos(';',MenuOption) + 1,(Length(MenuOption)) - (Pos(';',MenuOption)));
                      TempStr := Copy(MenuOption,1,(Pos(';',MenuOption) - 1));
                    END
                    ELSE
                      TempStr := '0';
                    TodaysCallers(StrToInt(TempStr),MenuOption);
                  END;
            'P' : CStuff(StrToInt(MenuOption),2,ThisUser);
            'R' : ChangeConference(MenuOption);
            'S' : Bulletins(MenuOption);
            'U' : UList(MenuOption);
          ELSE
            NoCmd := TRUE;
          END;
    'Q' : CASE Cmd[2] OF
            'Q' : RGQuote(MenuOption);
          ELSE
            NoCmd := TRUE;
          END;
    'R' : CASE Cmd[2] OF
            '#' : BEGIN
                    NL;
                    Print('Enter the number of a message to read it.');
                  END;
            'A' : TReadPrompt := 1;
            '-' : IF (Msg_On > 1) THEN
                    TReadPrompt := 2
                  ELSE
                  BEGIN
                    NL;
                    Print('You are already at the first message.');
                  END;
            'M' : TReadPrompt := 3;
            'X' : TReadPrompt := 4;
            'E' : TReadPrompt := 5;
            'R' : TReadPrompt := 6;
            'I' : IF (NOT (MAForceRead IN MemMsgArea.MAFlags)) OR (CoSysOp) THEN
                    TReadPrompt := 7
                  ELSE
                    Print('You must read all of the messages in this area.');
            'B' : TReadPrompt := 8;
            'F' : TReadPrompt := 9;
            'C' : TReadPrompt := 10;
            'D' : TReadPrompt := 11;
            'H' : TReadPrompt := 12;
            'G' : IF (NOT (MAForceRead IN MemMsgArea.MAFlags)) OR (CoSysOp) THEN
                    TReadPrompt := 13
                  ELSE
                    Print('^7You must read all of the messages in this area!^1');
            'Q' : IF (NOT (MAForceRead IN MemMsgArea.MAFlags)) OR (CoSysOp) THEN
                    TReadPrompt := 14
                  ELSE
                    Print('^7You must read all of the messages in this area!^1');
            'L' : TReadPrompt := 15;
            'U' : TReadPrompt := 16;
            'T' : TReadPrompt := 17;
            'N' : TReadPrompt := 18;
            'S' : TReadPrompt := 19;
            'V' : TReadPrompt := 20;
            'J' : TReadPrompt := 21;
          ELSE
            NoCmd := TRUE;
          END;
    'U' : CASE Cmd[2] OF
            'A' : ReplyAutoMsg;
            'R' : ReadAutoMsg;
            'W' : WriteAutoMsg;
          ELSE
            NoCmd := TRUE;
          END;
    'V' : CASE Cmd[2] OF
            '#' : BEGIN
                    NL;
                    Print('Enter the number of the topic to vote on.');
                    IF (Novice IN ThisUser.Flags) THEN
                      PauseScr(FALSE);
                  END;
            'A' : AddTopic;
            'L' : ListTopics(TRUE);
            'R' : Results(FALSE);
            'T' : TrackUser;
            'U' : Results(TRUE);
            'V' : VoteAll;
          ELSE
            NoCmd := TRUE;
          END;
    'T' : CASE Cmd[2] OF
            'A' : BBSList_Add;
            'E' : BBSList_Edit;
            'D' : BBSList_Delete;
            'V' : BBSList_View;
            'X' : BBSList_xView;
          ELSE
            NoCmd := TRUE;
          END;
    '!' : CASE Cmd[2] OF
            'P' : SetMessageAreaNewScanDate;
            'D' : DownloadPacket;
            'U' : UploadPacket(FALSE);
          ELSE
            NoCmd := TRUE;
          END;
    '*' : CASE Cmd[2] OF
            '=' : ShowCmds(MenuOption);
            'B' : IF (CheckPW) THEN
                  BEGIN
                    SysOpLog('* Message Area Editor');
                    MessageAreaEditor;
                  END;
            'C' : IF (CheckPW) THEN
                    ChangeUser;
            'D' : IF (CheckPW) THEN
                  BEGIN
                    SysOpLog('* Entered Dos Emulator');
                    MiniDOS;
                  END;
            'E' : IF (CheckPW) THEN
                  BEGIN
                    SysOpLog('* Event Editor');
                    EventEditor;
                  END;
            'F' : IF (CheckPW) THEN
                  BEGIN
                    SysOpLog('* File Area Editor');
                    FileAreaEditor;
                  END;
            'V' : IF (CheckPW) THEN
                  BEGIN
                    SysOpLog('* Vote Editor');
                    VotingEditor;
                  END;
            'L' : IF (CheckPW) THEN
                    ShowLogs;
            'N' : TEdit1;
            'P' : IF (CheckPW) THEN
                  BEGIN
                    SysOpLog('* System Configuration Editor');
                    SystemConfigurationEditor;
                  END;
            'R' : IF (CheckPW) THEN
                  BEGIN
                    SysOpLog('* Conference Editor');
                    ConferenceEditor;
                  END;
            'U' : IF (CheckPW) THEN
                  BEGIN
                    SysOpLog('* User Editor');
                    UserEditor(UserNum);
                  END;
            'X' : IF (CheckPW) THEN
                  BEGIN
                    SysOpLog('* Protocol Editor');
                    ProtocolEditor;
                  END;
            'Z' : BEGIN
                    SysOpLog('* History Editor');
                    HistoryEditor;
                  END;
            '1' : BEGIN
                    SysOpLog('* Edited Files');
                    EditFiles;
                  END;
            '2' : BEGIN
                    SysOpLog('* Sorted Files');
                    Sort;
                  END;
            '3' : IF (CheckPW) THEN
                  BEGIN
                    SysOpLog('* Read Private Messages');
                    ReadAllMessages('');
                  END;
            '4' : IF (MenuOption = '') THEN
                    Do_Unlisted_Download
                  ELSE
                    UnlistedDownload(MenuOption);
            '5' : BEGIN
                    SysOpLog('* Rechecked files');
                    ReCheck;
                  END;
            '6' : IF (CheckPW) THEN
                    UploadAll;
            '7' : ValidateFiles;
            '8' : AddGIFSpecs;
            '9' : PackMessageAreas;
            '#' : IF (CheckPW) THEN
                  BEGIN
                    SysOpLog('* Menu Editor');
                    SaveMenu := CurMenu;
                    MenuEditor;
                    CurMenu := SaveMenu;
                    LoadMenu;
                  END;
            '$' : DirF(TRUE);
            '%' : DirF(FALSE);
          ELSE
            NoCmd := TRUE;
          END;
  ELSE
    NoCmd := TRUE;
  END;
  LastCommandGood := NOT NoCmd;
  IF (LastCommandOvr) THEN
    LastCommandGood := FALSE;
  IF (NoCmd) THEN
    IF (CoSysOp) THEN
    BEGIN
      TempStr := 'Invalid command keys: '+Cmd[1]+Cmd[2]+' '+Cmd;
      NL;
      Print(TempStr);
      SysOpLog(TempStr);
    END;

  IF ((Cmd[1] + Cmd[2]) <> 'NW') THEN
    Update_Node('',FALSE);

  IF (NewMenuToLoad) THEN
  BEGIN
    LoadMenuPW;
    LastCommandGood := FALSE;
    IF (NewMenuCmd = '') THEN
      AutoExecCmd('FIRSTCMD');
  END;
END;

END.
