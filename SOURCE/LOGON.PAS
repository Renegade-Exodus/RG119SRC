{$IFDEF WIN32}
{$I DEFINES.INC}
{$ENDIF}

{$A+,B-,D+,E-,F+,I-,L+,N-,O+,R-,S+,V-}

UNIT Logon;

INTERFACE

FUNCTION GetUser: Boolean;

IMPLEMENTATION

USES
  Crt,
  Common,
  Archive1,
  CUser,
  Doors,
  Email,
  Events,
  Mail0,
  Mail1,
  Maint,
  Menus,
  Menus2,
  NewUsers,
  ShortMsg,
  SysOp2G,
  TimeFunc,
  MiscUser;

VAR
  GotName: Boolean;
  OldUser: UserRecordType;

FUNCTION Hex(i: LongInt; j: Byte): STRING;
CONST
  hc : ARRAY [0..15] OF Char = '0123456789ABCDEF';
VAR
  One,
  Two,
  Three,
  Four: Byte;
BEGIN
  One := (i AND $000000FF);
  Two := (i AND $0000FF00) SHR 8;
  Three := (i AND $00FF0000) SHR 16;
  Four := (i AND $FF000000) SHR 24;
  Hex[0] := chr(j);          { Length of STRING = 4 or 8}
  IF (j = 4) THEN
  BEGIN
    Hex[1] := hc[Two SHR 4];
    Hex[2] := hc[Two AND $F];
    Hex[3] := hc[One SHR 4];
    Hex[4] := hc[One AND $F];
  END
  ELSE
  BEGIN
    Hex[8] := hc[One AND $F];
    Hex[7] := hc[One SHR 4];
    Hex[6] := hc[Two AND $F];
    Hex[5] := hc[Two SHR 4];
    Hex[4] := hc[Three AND $F];
    Hex[3] := hc[Three SHR 4];
    Hex[2] := hc[Four AND $F];
    Hex[1] := hc[Four SHR 4];
  END;
END;

PROCEDURE IEMSI;
VAR
  Tries: Byte;
  T1,T2: LongInt;
  Emsi_Irq: STRING[20];
  Done,Success: Boolean;
  S,Isi: STRING;
  C: Char;
  I: Integer;
  Buffer: ARRAY [1..2048] OF Char;
  Buffptr: Integer;
  User: UserRecordType;
  NextItemPointer: Integer;

  FUNCTION NextItem: STRING;
  VAR
    S: AStr;
  BEGIN
    S := '';
    WHILE (NextItemPointer < 2048) AND (Buffer[NextItemPointer] <> #0) AND (Buffer [NextItemPointer] <> '{') DO
      Inc(NextItemPointer);
    IF (Buffer[NextItemPointer] = '{') THEN
      Inc(NextItemPointer);
    WHILE (NextItemPointer < 2048) AND (Buffer[NextItemPointer] <> #0) AND (Buffer [NextItemPointer] <> '}') DO
    BEGIN
      S := S + Buffer[NextItemPointer];
      Inc(NextItemPointer);
    END;
    IF (Buffer[NextItemPointer] = '}') THEN
      Inc(NextItemPointer);
    NextItem := S;
  END;

BEGIN
  FillChar(IEMSIRec,SizeOf(IEMSIRec),0);
  IF (ComPortSpeed = 0) OR (NOT General.UseIEMSI) THEN
    Exit;
  (* Should this be Prompt ???
  Write('Attempting IEMSI negotiation ... ');
  *)
  Write(RGNoteStr(21,TRUE));
  FillChar(Buffer,SizeOf(Buffer),0);
  T1 := Timer;
  T2 := Timer;
  Tries := 0;
  Done := FALSE;
  Success := FALSE;
  Emsi_Irq := '**EMSI_IRQ8E08'^M^L;
  Com_Flush_Recv;
  SerialOut(Emsi_Irq);
  S := '';
  REPEAT
    HangUp := NOT Com_Carrier;
    IF (ABS(T1 - Timer) > 2) THEN
    BEGIN
      T1 := Timer;
      Inc(Tries);
      IF (Tries >= 2) THEN
        Done := TRUE
      ELSE
      BEGIN
        Com_Flush_Recv;
        SerialOut(Emsi_Irq);
      END;
    END;
    IF (ABS(T2 - Timer) >= 8) THEN
      Done := TRUE;
    C := Cinkey;
    IF (C > #0) THEN
    BEGIN
      IF (Length(S) >= 160) THEN
        Delete(S, 1, 120);
      S := S + C;
      IF (Pos('**EMSI_ICI', S) > 0) THEN
      BEGIN
        Delete(S,1,Pos('EMSI_ICI',S) - 1);
        Move(S[1],Buffer[1],Length(S));
        Buffptr := Length(S);
        T1 := Timer;
        REPEAT
          C := Cinkey;
          IF NOT (C IN [#0, #13]) THEN
          BEGIN
            Inc(Buffptr);
            Buffer[Buffptr] := C;
          END;
        UNTIL (HangUp) OR (ABS(Timer - T1) > 4) OR (C = ^M) OR (Buffptr = 2048);
        S [0] := #8;
        Move(Buffer[Buffptr - 7],S[1],8);
        Dec(Buffptr,8);
        IF (S = Hex(UpdateCRC32($Ffffffff,Buffer[1],Buffptr),8)) THEN
        BEGIN
          LoadURec(User,1);
          Isi := '{Renegade,'+General.Version+'}{'+General.BBSName+'}{'+User.CityState+
                 '}{'+General.SysOpName+'}{'+Hex(GetPackDateTime,8)+
                 '}{Live free or die!}{}{Everything!}';
          Isi := 'EMSI_ISI'+ Hex(Length(Isi),4) + Isi;
          Isi := Isi + Hex(UpdateCRC32($Ffffffff,Isi[1],Length(Isi)),8);
          Isi := '**' + Isi + ^M;
          Com_Flush_Recv;
          SerialOut(Isi);
          Tries := 0;
          T1 := Timer;
          S := '';
          REPEAT
            IF (ABS(Timer - T1) >= 3) THEN
            BEGIN
              T1 := Timer;
              Inc(Tries);
              Com_Flush_Recv;
              SerialOut(Isi);
            END;
            C := Cinkey;
            IF (C > #0) THEN
            BEGIN
              IF (Length(S) >= 160) THEN
                Delete(S,1,120);
              S := S + C;
              IF (Pos('**EMSI_ACK', S) > 0) THEN
              BEGIN
                Com_Flush_Recv;
                Com_Purge_Send;
                Done := TRUE;
                Success := TRUE;
              END
              ELSE IF (Pos('**EMSI_NAKEEC3',S) > 0) THEN
              BEGIN
                Com_Flush_Recv;
                SerialOut(Isi);
                Inc(Tries);
              END;
            END;
          UNTIL (Tries >= 3) OR (Done);
        END
        ELSE
        BEGIN
          SerialOut('**EMSI_NAKEEC3');
          T1 := Timer;
        END;
      END;
    END;
  UNTIL (Done) OR (HangUp);
  IF (Success) THEN
  BEGIN
    (* Should this be print ???
    WriteLn('success.');
    *)
    Writeln(RGNOteStr(22,TRUE));
    SL1('IEMSI negotiation Suceeded.');
  END
  ELSE
  BEGIN
    (* Should this be print ???
    WriteLn('failure.');
    *)
    WriteLn(RGNoteStr(23,TRUE));
    SL1('IEMSI negotiation failed.');
  END;
  NextItemPointer := 1;
  WITH IEMSIRec DO
  BEGIN
    UserName := NextItem;
    Handle := NextItem;
    CityState := NextItem;
    Ph := NextItem;
    S := NextItem;
    Pw := AllCaps(NextItem);
    I := StrToInt('$'+NextItem);
    IF (I > 0) THEN
      Bdate := Pd2Date(I);
  END;
    Com_Flush_Recv;
END;

PROCEDURE Check_Ansi;
VAR
  L: LongInt;
  C: Char;
  Ox,x,y: Byte;
  S: AStr;

  PROCEDURE ANSIResponse(VAR x,y: Byte);
  VAR
    Xs,
    Ys: STRING[4];
  BEGIN
    L := (Timer + 2);
    C := #0;
    Xs := '';
    Ys := '';
    x := 0;
    y := 0;
    WHILE (L > Timer) AND (C <> ^[) AND (NOT HangUp) DO
      IF (NOT Empty) THEN
        C := Com_Recv;        { must be low level to avoid ansi-eater }
      IF (C = ^[) THEN
      BEGIN
        L := (Timer + 1);
        WHILE (L > Timer) AND (C <> ';') AND (NOT HangUp) DO
          IF (NOT Empty) THEN
          BEGIN
            C := Com_Recv;
            IF (C IN ['0'..'9']) AND (Length(Ys) < 4) THEN
              Ys := Ys + C;
          END;
        L := (Timer + 1);
        WHILE (L > Timer) AND (C <> 'R') AND (NOT HangUp) DO
          IF (NOT Empty) THEN
          BEGIN
            C := Com_Recv;
            IF (C IN ['0'..'9']) AND (Length(Xs) < 4) THEN
              Xs := Xs + C;
          END;
        x := StrToInt(Xs);
        y := StrToInt(Ys);
      END;
  END;

BEGIN
  TextAttr := 10;
  (* Should this be Prompt ???
  Write('Attempting to detect emulation ... ');
  *)
  Write(RGNoteStr(24,TRUE));
  Exclude(ThisUser.Flags,Avatar);
  Exclude(ThisUser.Flags,Ansi);
  Exclude(ThisUser.Flags,Vt100);
  Exclude(ThisUser.SFlags,Rip);
  IF (ComPortSpeed = 0) THEN
  BEGIN
    Include(ThisUser.Flags,Ansi);
    Exit;
  END;
  Com_Flush_Recv;
  SerialOut(^M^M^['[!'#8#8#8);
  L := (Timer + 2);
  C := #0;
  S := '';
  WHILE (L > Timer) AND (C <> 'R') AND (NOT HangUp) DO IF (NOT Empty) THEN
    C := Com_Recv;
  IF (C = 'R') THEN
  BEGIN
    L := (Ticks + 3);
    WHILE (NOT Empty) AND (Ticks < L) DO;
      C := Com_Recv;
    IF (C = 'I') THEN
    BEGIN
      L := (Ticks + 3);
      WHILE (NOT Empty) AND (Ticks < L) DO;
      C := Com_Recv;
      IF (C = 'P') THEN
      BEGIN
        Include(ThisUser.SFlags,Rip);
        S := RGNoteStr(25,TRUE); {'RIP'}
      END;
    END;
    Com_Flush_Recv;
  END;
  SerialOut(^M^M^['[6n'#8#8#8#8);
  ANSIResponse(x,y);
  IF (x + y > 0) THEN
  BEGIN
    Include(ThisUser.Flags,Ansi);
  ANSIDetected := TRUE;
    IF (S <> '') THEN
      S := S + RGNoteStr(26,TRUE) {'/Ansi'}
    ELSE
      S := RGNoteStr(27,TRUE); {'Ansi'}
    SerialOut(^V^F);
    SerialOut(^['[6n'#8#8);
    Ox := x;
    ANSIResponse(x,y);
    IF (x = Ox + 1) THEN
    BEGIN
      Include(ThisUser.Flags,Avatar);
      IF (S <> '') THEN
        S := S + RGNoteStr(28,TRUE)  {'/Avatar'}
      ELSE
        S := RGNoteStr(29,TRUE); {'Avatar'}
    END
    ELSE
      SerialOut(#8#8);
  END;
  IF (S <> '') THEN
    Print('|10'+S+RGNoteStr(30,TRUE)) {' detected.'}
  ELSE
  BEGIN
    TextAttr := 7;
    { Should this be Print ??? }
    WriteLn;
  END;
END;

PROCEDURE GetPWS(VAR Ok: Boolean; VAR Tries: Integer);  (* Tries should be Byte *)
VAR
  MHeader: MHeaderRec;
  S: AStr;
  PhonePW: STR4;
  Birthday: Str10;
  UserPW,
  SysOpPW: Str20;
  ForgotPW: Str40;
BEGIN
  Ok := TRUE;
  IF (NOT (FastLogon AND (NOT General.LocalSec))) THEN
  BEGIN
    IF (IEMSIRec.Pw = '') THEN
    BEGIN
      (*
      Prompt(FString.Yourpassword);
      *)
      RGMainStr(3,FALSE);
      GetPassword(UserPw,20);
    END
    ELSE
    BEGIN
      UserPW := IEMSIRec.Pw;
      IEMSIRec.Pw := '';
    END;
    IF (General.Phonepw) THEN
      IF (IEMSIRec.Ph = '') THEN
      BEGIN
        (*
        Prompt(FString.YourPhoneNumber);
        *)
        RGMainStr(4,FALSE);
        GetPassword(PhonePW,4);
      END
      ELSE
      BEGIN
        PhonePW := Copy(IEMSIRec.Ph,Length(IEMSIRec.Ph) - 3,4);
        IEMSIRec.Ph := '';
      END
      ELSE
        PhonePW := Copy(ThisUser.Ph,Length(ThisUser.Ph) - 3,4);
  END;
  IF (NOT (FastLogon AND (NOT General.LocalSec))) AND ((ThisUser.Pw <> Crc32(UserPW)) OR
     (Copy(ThisUser.Ph,Length(ThisUser.Ph) - 3,4) <> PhonePW)) THEN
  BEGIN
    ok := FALSE;
    (*
    Prompt(FString.ILogon);
    *)
    RGNoteStr(9,FALSE);
    IF (NOT HangUp) AND (UserNum <> 0) THEN
    BEGIN
      S := '* Illegal logon attempt! Tried: '+Caps(ThisUser.Name)+' #'+IntToStr(UserNum)+' PW='+UserPw;
      IF (General.Phonepw) THEN
        S := S + ', PH#='+PhonePW;
      SendShortMessage(1,S);
      SL1(S);
    END;
    Inc(ThisUser.Illegal);
    IF (UserNum <> - 1) THEN
      SaveURec(ThisUser,UserNum);
    Inc(Tries);
    IF (Tries >= General.MaxLogonTries) THEN
    BEGIN
      IF (General.NewUserToggles[20] = 0) OR (General.ForgotPWQuestion = '') OR (ThisUser.ForgotPWAnswer = '') THEN
        HangUp := TRUE
      ELSE
      BEGIN
        (*
        Print('|03Please answer the following question to logon to the BBS.');
        Print('|03'+General.ForgotPWQuestion);
        Prt(': ');
        *)
        RGMainStr(6,FALSE);
        MPL(40);
        Input(ForgotPW,40);
        IF (ForgotPW <> ThisUser.ForgotPWAnswer) THEN
        BEGIN
          S := '* Invalid forgot password response: '+ForgotPW;
          SL1(S);
          SendShortMessage(1,S);
          HangUp := TRUE
        END
        ELSE
        BEGIN
          S := '* Entered correct forgot password response.';
          SL1(S);
          SendShortMessage(1,S);
          CStuff(9,1,ThisUser);
          ok := TRUE;
          Tries := 0;
        END;
      END;
    END;
  END;
  IF (Ok) THEN
    lStatus_Screen(General.Curwindow,'',FALSE,S);
  IF ((AACS(General.Spw)) AND (Ok) AND (InCom) AND (NOT HangUp)) THEN
  BEGIN
    (*
    Prompt(FString.SysOpPrompt);
    *)
    RGMainStr(5,FALSE);
    GetPassword(SysOpPW,20);
    IF (SysOpPW <> General.SysOpPW) THEN
    BEGIN
      (*
      Prompt(FString.ILogon);
      *)
      RGNoteStr(9,FALSE);
      SL1('* Illegal System password: '+SysOpPw);
      Inc(Tries);
      IF (Tries >= General.MaxLogonTries) THEN
        HangUp := TRUE;
      Ok := FALSE;
    END;
  END;
  IF (Ok) AND NOT (AACS(Liner.LogonACS)) THEN
  BEGIN
    PrintF('NONODE');
    IF (NoFile) THEN
      (*
      Print('You don''t have the required ACS to logon to this node!');
      *)
      RGNoteStr(10,FALSE);
    SysOpLog(ThisUser.Name+': Attempt to logon node '+IntToStr(ThisNode)+' without access.');
    HangUp := TRUE;
  END;
  IF ((Ok) AND (General.ShuttleLog) AND (LockedOut IN ThisUser.SFlags)) THEN
  BEGIN
    PrintF(ThisUser.LockedFile);
    IF (NoFile) THEN
      (*
      Print('You have been locked out of the BBS by the SysOp.');
      *)
      RGNoteStr(11,FALSE);
    SysOpLog(ThisUser.Name+': Attempt to access system when locked out^7 <--');
    HangUp := TRUE;
  END;
  IF (UserNum > 0) AND (Onnode(UserNum) > 0) AND NOT (Cosysop) THEN
  BEGIN
     PrintF('MULTILOG');
     IF (NoFile) THEN
       (*
       Print('You are already logged in on another node!');
       *)
       RGNoteStr(12,FALSE);
     HangUp := TRUE;
  END;
  IF (NOT FastLogon) AND (Ok) AND (NOT HangUp) AND (General.Birthdatecheck > 0) AND
    (ThisUser.LoggedOn MOD General.Birthdatecheck = 0) THEN
  BEGIN
    (*
    Prt('Please verify your date of birth (mm/dd/yyyy): ');
    *)
    RGMainStr(7,FALSE);
    Inputformatted('',Birthday,'##/##/####',FALSE);
    IF (Date2Pd(Birthday) <> ThisUser.Birthdate) THEN
    BEGIN
      Dec(ThisUser.LoggedOn);
      PrintF('WRNGBDAY');
      IF (NoFile) THEN
        (*
        Print('You entered an incorrect birthdate.');
        *)
        RGNoteStr(13,FALSE);
      SL1('*'+ThisUser.Name+' Failed birthday verification. Tried = '+Birthday+' Actual = '+Pd2Date(ThisUser.Birthdate));
      SendShortMessage(1,ThisUser.Name+' failed birthday verification on '+DateStr);
      InResponseTo := '\'#1'Failed birthdate check';
      MHeader.Status := [];
      SeMail(1,MHeader);
      HangUp := TRUE;
    END;
  END;
  UserOn := Ok;
END;

PROCEDURE TryIEMSILogon;
VAR
  I, Zz: Integer;
  Ok: Boolean;
BEGIN
  IF (IEMSIRec.UserName <> '') THEN
  BEGIN
    I := SearchUser(IEMSIRec.UserName,TRUE);
    IF (I = 0) AND (IEMSIRec.Handle <> '') THEN
      I := SearchUser(IEMSIRec.Handle,TRUE);
    IF (I > 0) THEN
    BEGIN
      Zz := UserNum;
      UserNum := 0;
      OldUser := ThisUser;
      LoadURec(ThisUser,I);
      UserNum := Zz;
      GetPWS(Ok,Zz);
      GotName := Ok;
      IF (NOT GotName) THEN
      BEGIN
        ThisUser := OldUser;
        Update_Screen;
      END
      ELSE
      BEGIN
        UserNum := I;
        IF (Pd2Date(ThisUser.LastOn) <> DateStr) THEN
          WITH ThisUser DO
          BEGIN
            OnToday := 0;
            TLToday := General.TimeAllow[SL];
            TimeBankAdd := 0;
            DLToday := 0;
            DLKToday := 0;
            TimeBankWith := 0;
          END;
        UserOn := TRUE;
        Update_Screen;
        SysOpLog('Logged in IEMSI as '+Caps(ThisUser.Name));
      END;
    END
    ELSE
      (*
      Print(FString.NameNotFound);
      *)
      RGNoteStr(8,FALSE);

  END;
END;

PROCEDURE Doshuttle;
VAR
  Cmd,NewMenuCmd: AStr;
  SaveMenu,
  CmdToExec: Byte;
  Tries,
  RecNum,
  RecNum1,
  I: Integer;
  Done,Loggedon,Ok,CmdNotHid,CmdExists: Boolean;
BEGIN
  PrintF('PRESHUTL');
  GotName := FALSE;
  Loggedon := FALSE;
  TryIEMSILogon;
  SaveMenu := CurMenu;
  CurMenu := General.ShuttleLogonMenu;
  LoadMenu;
  AutoExecCmd('FIRSTCMD');
  Tries := 0;
  Curhelplevel := 2;
  REPEAT
    TSHuttleLogon := 0;
    MainMenuHandle(Cmd);
    NewMenuCmd:= '';
    CmdToExec := 0;
    Done := FALSE;
    REPEAT
      FCmd(Cmd,CmdToExec,CmdExists,CmdNotHid);
      IF (CmdToExec <> 0) THEN
        IF (MemCmd^[CmdToExec].Cmdkeys <> 'OP') AND (MemCmd^[CmdToExec].Cmdkeys <> 'O2') AND
           (MemCmd^[CmdToExec].Cmdkeys[1] <> 'H') AND (MemCmd^[CmdToExec].Cmdkeys[1] <> '-') AND
           (NOT GotName) THEN
        BEGIN
          (*
          Prompt(FString.Shuttleprompt);
          *)
          RGMainStr(9,FALSE);
          FindUser(UserNum);
          IF (UserNum >= 1) THEN
          BEGIN
            I := UserNum;
            UserNum := 0;
            OldUser := ThisUser;
            LoadURec(ThisUser,I);
            UserNum := I;
            GetPWS(Ok,Tries);
            GotName := Ok;
            IF (NOT GotName) THEN
            BEGIN
              ThisUser := OldUser;
              Update_Screen;
            END
            ELSE
            BEGIN
              IF (Pd2Date(ThisUser.LastOn) <> DateStr) THEN
                WITH ThisUser DO
                BEGIN
                  OnToday := 0;
                  TLToday := General.TimeAllow[SL];
                  TimeBankAdd := 0;
                  DLToday := 0;
                  DLKToday := 0;
                  TimeBankWith := 0;
                END;
              UserOn := TRUE;
              Update_Screen;
              SysOpLog('Logged on to Shuttle Menu as '+Caps(ThisUser.Name));
              DoMenuCommand(Done,
                            MemCmd^[CmdToExec].Cmdkeys,
                            MemCmd^[CmdToExec].Options,
                            NewMenuCmd,
                            MemCmd^[CmdToExec].NodeActivityDesc);
            END;
          END
          ELSE
          BEGIN
            (*
            Print(FString.ILogon);
            *)
            RGNoteStr(9,FALSE);
            Inc(Tries);
          END;
      END
      ELSE
        DoMenuCommand(Done,
                      MemCmd^[CmdToExec].Cmdkeys,
                      MemCmd^[CmdToExec].Options,
                      NewMenuCmd,
                      MemCmd^[CmdToExec].NodeActivityDesc);
    UNTIL (CmdToExec = 0) OR (Done);
    CASE TSHuttleLogon OF
      1 : BEGIN

            Reset(ValidationFile);
            RecNum1 := -1;
            RecNum := 1;
            WHILE (RecNum <= NumValKeys) AND (RecNum1 = -1) DO
            BEGIN
              Seek(ValidationFile,(RecNum - 1));
              Read(ValidationFile,Validation);
              IF (Validation.Key = '!') THEN
                RecNum1 := RecNum;
              Inc(RecNum);
            END;
            Close(ValidationFile);

            IF (RecNum1 <> -1) AND (ThisUser.SL > Validation.NewSL) THEN
              Loggedon := TRUE
            ELSE
            BEGIN
              PrintF('NOSHUTT');
              IF (NoFile) THEN
                (*
                Print('You have not been validated yet.');
                *)
                RGNoteStr(31,FALSE);
              SL1('* Illegal Shuttle Logon attempt');
              Inc(Tries);
            END;

          END;
      2 : BEGIN
            IF (NOT General.ClosedSystem) AND PYNQ(RGMainStr(2,TRUE){FString.LogonAsNew},0,FALSE) THEN
            BEGIN
              NewUserInit;
              NewUser;
              IF (UserNum > 0) AND (NOT HangUp) THEN
              BEGIN
                GotName := TRUE;
                UserOn := TRUE;
                DailyMaint;
              END;
              CurMenu := General.ShuttleLogonMenu;
              LoadMenu;
            END;
          END;
    END;
    IF (Tries >= General.MaxLogonTries) THEN
      HangUp := TRUE;
  UNTIL (Loggedon) OR (HangUp);
  CurMenu := SaveMenu;
  NewMenuToLoad := TRUE;
END;

FUNCTION GetUser: Boolean;
VAR
  User: UserRecordType;
  MHeader: MHeaderRec;
  Pw,
  S,
  ACSReq: AStr;
  OverridePW: Str20;
  Lng: SmallInt;
  Tries,
  I,
  TTimes,
  Zz,
  EventNum: Integer;    (* Tries/TTimes should be Byte, may NOT need TTimes *)
  Done,
  Nu,
  Ok,
  TooMuch,
  ACSUser: Boolean;
BEGIN
  WasNewUser := FALSE;
  UserNum := -1;
  LoadURec(ThisUser,0);
  TimeOn := GetPackDateTime;
  ChatChannel := 0;
  Update_Node(RGNoteStr(35,TRUE){ Logging on },TRUE);  (* New *)

  LoadNode(ThisNode);     (* New *)
  NodeR.GroupChat := FALSE;
  SaveNode(ThisNode);

  CreditsLastUpdated := GetPackDateTime;

  PublicReadThisCall := 0;

  ExtraTime := 0;
  FreeTime := 0;
  ChopTime := 0;
  CreditTime := 0;

  SL1('');

  S := '^3Logon node '+IntToStr(ThisNode)+'^5 ['+Dat+']^4 (';
  IF (ComPortSpeed > 0) THEN
  BEGIN
    S := S + IntToStr(ActualSpeed)+' baud';
    IF (Reliable) THEN
      S := S + '/Reliable)'
    ELSE
      S := S + ')';
    IF (CallerIDNumber > '') THEN
    BEGIN
      IF (NOT Telnet) THEN
        S := S + ' Number: '+CallerIDNumber
      ELSE
        S := S + ' IP Number: '+CallerIDNumber;
    END;
  END
  ELSE
    S := S + 'Keyboard)';
  SL1(S);

  Nu := FALSE;
  Pw := '';

  IF (ActualSpeed < General.MinimumBaud) AND (ComPortSpeed > 0) THEN
  BEGIN
    IF ((General.MinBaudHiTime - General.MinBaudLowTime) > 1430) THEN
    BEGIN
      IF (General.MinBaudOverride <> '') THEN
      BEGIN
        (*
        Prt('Baud rate override password: ');
        *)
        RGMainStr(0,FALSE);
        GetPassword(OverridePW,20);
      END;
      IF (General.MinBaudOverride = '') OR (OverRidePW <> General.MinBaudOverride) THEN
      BEGIN
        PrintF('NOBAUD.ASC');
        IF (NoFile) THEN
          RGNoteStr(3,FALSE);
          (*
          Print('You must be using at least '+IntToStr(General.MinimumBaud)+' baud to call this BBS.');
          *)
        HangUp := TRUE;
        Exit;
      END;
    END
    ELSE IF (NOT InTime(Timer,General.MinBaudLowTime,General.MinBaudHiTime)) THEN
    BEGIN
      IF (General.MinBaudOverride <> '') THEN
      BEGIN
        (*
        Prt('Baud rate override password: ');
        *)
        RGMainStr(0,FALSE);
        GetPassword(OverridePW,20);
      END;
      IF (General.MinBaudOverride = '') OR (OverridePW <> General.MinBaudOverride) THEN
      BEGIN
        PrintF('NOBAUDH.ASC');
        IF (NoFile) THEN
          (*
          Print('Hours for those using less than '+IntToStr(General.MinimumBaud)+' baud are from '+
               Ctim(General.MinBaudLowTime)+' to '+Ctim(General.MinBaudHiTime));
          *)
          RGNoteStr(4,FALSE);
        HangUp := TRUE;
        Exit;
      END;
    END
    ELSE
    BEGIN
      IF (NOT HangUp) THEN
        IF ((General.MinBaudLowTime <> 0) OR (General.MinBaudHiTime <> 0)) THEN
        BEGIN
          PrintF('YESBAUDH.ASC');
          IF (NoFile) THEN
            (*
            Print('NOTE: Callers at less than '+IntToStr(General.MinimumBaud)+' baud are');
            Print('restricted to the following hours ONLY:');
            Print('  '+Ctim(General.MinBaudLowTime)+' to '+Ctim(General.MinBaudHiTime));
            *)
            RGNoteStr(5,FALSE);
        END;
    END;
  END;

  ACSUser := FALSE;
  FOR I := 1 TO NumEvents DO
    WITH MemEventArray[I]^ DO
      IF ((EventIsActive IN EFlags) AND (EventIsLogon IN EFlags) AND (CheckEventTime(I,0))) THEN
      BEGIN
        ACSUser := TRUE;
        ACSReq := MemEventArray[I]^.EventACS;
        EventNum := I;
      END;

  Check_Ansi;
  IEMSI;
  GotName := FALSE;
  IF ((General.ShuttleLog) AND (NOT FastLogon) AND (NOT HangUp)) THEN
    Doshuttle;
  Setc(7);
  CLS;
  Print(Centre(VerLine(1)));
  Print(Centre(VerLine(2)));
  Print(Centre(VerLine(3)));
  PrintF('PRELOGON');
  IF (ACSUser) THEN
  BEGIN
    PrintF('ACSEA'+IntToStr(EventNum));
    IF (NoFile) THEN
      (*
      Print('Restricted: Only certain users allowed online at this time.');
      *)
      RGNoteStr(6,FALSE);
  END;
  IF (NOT GotName) THEN
    TryIEMSILogon;
  TTimes := 0;
  Tries := 0;
  REPEAT
    REPEAT
      IF (UserNum <> - 1) AND (TTimes >= General.MaxLogonTries) THEN
        HangUp := TRUE;
      OldUser := ThisUser;
      IF (NOT GotName) THEN
      BEGIN
        (*
        IF (FString.Note[1] <> '') THEN
          Print(FString.Note[1]);
        IF (FString.Note[2] <> '') THEN
          Print(FString.Note[2]);
        IF (FString.Lprompt <> '') THEN
          Prompt(FString.Lprompt);
        *)
        RGMainStr(1,FALSE);
        FindUser(UserNum);
        Inc(TTimes);
        IF (ACSUser) AND (UserNum = -1) THEN
        BEGIN
          PrintF('ACSEB'+IntToStr(EventNum));
          IF (NoFile) THEN
            (*
            Print('This time window allows certain other users to get online.');
            Print('Please call back later, after it has ended.');
            *)
            RGNoteStr(7,FALSE);
          HangUp := TRUE;
        END;
        IF (NOT HangUp) AND (UserNum = 0) THEN
        BEGIN
          PrintF('LOGERR');
          IF (NoFile) THEN
            (*
            Print('Name not found in user list.');
            *)
            RGNoteStr(8,FALSE);
          IF NOT (General.ShuttleLog) AND (NOT General.ClosedSystem) THEN
            IF PYNQ(RGMainStr(2,TRUE){FString.LogonAsNew},0,FALSE) THEN
              UserNum := -1;
        END;
      END;
    UNTIL (UserNum <> 0) OR (HangUp);
    IF (ACSUser) AND (UserNum = -1) THEN
    BEGIN
      PrintF('ACSEB'+IntToStr(EventNum));
      IF (NoFile) THEN
        (*
        Print('This time window allows certain other users to get online.');
        Print('Please call back later, after it has ended.');
        *)
        RGNoteStr(7,FALSE);
      HangUp := TRUE;
    END;
    Ok := TRUE;
    Done := FALSE;
    IF (NOT HangUp) THEN
    BEGIN
      IF (UserNum = -1) THEN
      BEGIN
        NewUserInit;
        Nu := TRUE;
        Done := TRUE;
        Ok := FALSE;
      END
      ELSE
      BEGIN
        I := UserNum;
        UserNum := 0;
        LoadURec(ThisUser,I);
        UserNum := I;
        TempPause := (Pause IN ThisUser.Flags);
        NewFileDate := ThisUser.LastOn;
        MsgArea := ThisUser.LastMsgArea;
        FileArea := ThisUser.LastFileArea;
        IF (AutoDetect IN ThisUser.SFlags) THEN
        BEGIN
          IF (Rip IN OldUser.SFlags) THEN
            Include(ThisUser.SFlags,Rip)
          ELSE
            Exclude(ThisUser.SFlags,Rip);
          IF (Ansi IN OldUser.Flags) THEN
            Include(ThisUser.Flags,Ansi)
          ELSE
            Exclude(ThisUser.Flags,Ansi);
          IF (Avatar IN OldUser.Flags) THEN
            Include(ThisUser.Flags,Avatar)
          ELSE
            Exclude(ThisUser.Flags,Avatar);
        END;
        IF (Pd2Date(ThisUser.LastOn) <> DateStr) THEN
          WITH ThisUser DO
          BEGIN
            OnToday := 0;
            TLToday := General.TimeAllow[SL];
            TimeBankAdd := 0;
            DLToday := 0;
            DLKToday := 0;
            TimeBankWith := 0;
          END
          ELSE IF (General.PerCall) THEN
            ThisUser.TLToday := General.TimeAllow[ThisUser.SL];

        IF (ThisUser.Expiration > 0) AND
           (ThisUser.Expiration <= GetPackDateTime) AND
           (ThisUser.ExpireTo IN ['!'..'~']) THEN
        BEGIN
          SysOpLog('Subscription expired to level: "'+ThisUser.ExpireTo+'".');
          AutoValidate(ThisUser,UserNum,ThisUser.ExpireTo);
        END;

        IF (CallerIDNumber <> '') THEN
          ThisUser.CallerID := CallerIDNumber;
        SaveURec(ThisUser,UserNum);
        IF (NOT GotName) THEN
          GetPWS(Ok,Tries);
        IF (Ok) THEN
          Done := TRUE;
        IF (NOT Done) THEN
        BEGIN
          ThisUser := OldUser;
          UserNum := 0;
          Update_Screen;
        END;
      END;
    END;
  UNTIL ((Done) OR (HangUp));
  Reset(SchemeFile);
  IF (ThisUser.ColorScheme > 0) AND (ThisUser.ColorScheme <= FileSize(SchemeFile) ) THEN
    Seek(SchemeFile,ThisUser.ColorScheme - 1)
  ELSE
    ThisUser.ColorScheme := 1;
  Read(SchemeFile,Scheme);
  Close(SchemeFile);
  IF (ACSUser) AND NOT (AACS(ACSReq)) THEN
  BEGIN
    PrintF('ACSEB'+IntToStr(EventNum));
    IF (NoFile) THEN
      (*
      Print('This time window allows certain other users to get online.');
      Print('Please call back later, after it has ended.');
      *)
      RGNoteStr(7,FALSE);
    HangUp := TRUE;
  END;
  IF NOT (AACS(Liner.LogonACS)) AND (NOT HangUp) THEN
  BEGIN
    PrintF('NONODE');
    IF (NoFile) THEN
      (*
      Print('You don''t have the required ACS to logon to this node!');
      *)
      RGNoteStr(10,FALSE);
    SysOpLog(ThisUser.Name+': Attempt to logon node '+IntToStr(ThisNode)+' without access.');
    HangUp := TRUE;
  END;
  IF ((LockedOut IN ThisUser.SFlags) AND (NOT HangUp)) THEN
  BEGIN
    PrintF(ThisUser.LockedFile);
    IF (NoFile) THEN
      (*
      Print('You have been locked out of the BBS by the SysOp.');
      *)
      RGNoteStr(11,FALSE);
    SysOpLog(ThisUser.Name+': Attempt to access system when locked out^7 <--');
    HangUp := TRUE;
  END;
  IF ((NOT Nu) AND (NOT HangUp)) THEN
  BEGIN
    TooMuch := FALSE;
    IF (Accountbalance < General.Creditminute) AND (General.Creditminute > 0) AND
       NOT (FNoCredits IN ThisUser.Flags) THEN
    BEGIN
      PrintF('NOCREDTS');
      IF (NoFile) THEN
        (*
        Print('You have insufficient credits for online time.');
        *)
        RGNoteStr(14,FALSE);
      SysOpLog(ThisUser.Name+': insufficient credits for logon.');
      IF (General.CreditFreeTime < 1) THEN
        HangUp := TRUE
      ELSE
      BEGIN
        ThisUser.TLToday := General.CreditFreeTime DIV General.Creditminute;
        Inc(ThisUser.lCredit,General.CreditFreeTime);
      END;
    END
    ELSE IF (((Rlogon IN ThisUser.Flags) OR (General.CallAllow[ThisUser.SL] = 1)) AND
            (ThisUser.OnToday >= 1) AND (Pd2Date(ThisUser.LastOn) = DateStr)) THEN
    BEGIN
      PrintF('2MANYCAL');
      IF (NoFile) THEN
        (*
        Print('You can only log on once per day.');
        *)
        RGNoteStr(15,FALSE);
      TooMuch := TRUE;
    END
    ELSE IF ((ThisUser.OnToday >= General.CallAllow[ThisUser.SL])  AND
            (Pd2Date(ThisUser.LastOn) = DateStr)) THEN
    BEGIN
      PrintF('2MANYCAL');
      IF (NoFile) THEN
        (*
        Print('You can only log on '+IntToStr(General.CallAllow[ThisUser.SL])+' times per day.');
        *)
        RGNoteStr(16,FALSE);
      TooMuch := TRUE;
    END
    ELSE IF (ThisUser.TLToday <= 0) AND NOT (General.PerCall) THEN
    BEGIN
      PrintF('NOTLEFTA');
      IF (NoFile) THEN
        (*
        Prompt('You can only log on for '+IntToStr(General.TimeAllow[ThisUser.SL])+' minutes per day.');
        *)
        RGNoteStr(17,FALSE);
      TooMuch := TRUE;
      IF (ThisUser.TimeBank > 0) THEN
      BEGIN
        (*
        Print('^5However, you have '+IntToStr(ThisUser.TimeBank)+' minutes left in your Time Bank.');
        *)
        RGNoteStr(18,FALSE);
        IF PYNQ(RGMainStr(8,TRUE){'Withdraw from Time Bank? '},0,TRUE) THEN
        BEGIN
          InputIntegerWOC('Withdraw how many minutes',Lng,[NumbersOnly],1,32767);
          BEGIN
            IF (Lng > ThisUser.TimeBank) THEN
              Lng := ThisUser.TimeBank;
            Dec(ThisUser.TimeBankAdd,Lng);
            IF (ThisUser.TimeBankAdd < 0) THEN
              ThisUser.TimeBankAdd := 0;
            Dec(ThisUser.TimeBank,Lng);
            Inc(ThisUser.TLToday,Lng);
            (*
            Print('^5In your account: ^3'+IntToStr(ThisUser.TimeBank)+'^5   Time left online: ^3'+Formattedtime(NSL));
            *)
            RGNoteStr(19,FALSE);
            SysOpLog('TimeBank: Withdrew '+ IntToStr(Lng)+' minutes at logon.');
          END;
        END;
        IF (NSL >= 0) THEN
          TooMuch := FALSE
        ELSE
          (*
          Print('Hanging up.');
          *)
          RGNoteStr(20,FALSE);
      END;
    END;
    IF (TooMuch) THEN
    BEGIN
      SL1(ThisUser.Name+' attempt to exceed time/call limits.');
      HangUp := TRUE;
    END;
    IF (Tries >= General.MaxLogonTries) THEN
      HangUp := TRUE;
    IF (NOT HangUp) THEN
      Inc(ThisUser.OnToday);
  END;
  IF (UserNum > 0) AND (NOT HangUp) THEN
  BEGIN
    GetUser := Nu;
    IF (NOT FastLogon) THEN
    BEGIN
      PrintF('WELCOME');
      IF (NOT NoFile) THEN
        PauseScr(FALSE);
      I := 0;
      REPEAT
        Inc(I);
        PrintF('WELCOME'+IntToStr(I));
        IF (NOT NoFile) THEN
          PauseScr(FALSE);
      UNTIL (I = 9) OR (NoFile) OR (HangUp);
    END;
    UserOn := TRUE;
    Update_Screen;
    (*
    Update_Node('Logged on',TRUE);
    *)
    InitTrapFile;
    UserOn := FALSE;
    CLS;
  END;
  IF (HangUp) THEN
    GetUser := FALSE;
END;

END.
