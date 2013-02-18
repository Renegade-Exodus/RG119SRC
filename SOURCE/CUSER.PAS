{$IFDEF WIN32}
{$I DEFINES.INC}
{$ENDIF}

{$A+,B-,D+,E-,F+,I-,L+,N-,O+,R-,S+,V-}

UNIT CUser;

INTERFACE

USES
  Common;

PROCEDURE CStuff(Which,How: Byte; VAR User: UserRecordType);

IMPLEMENTATION

USES
  Dos,
  Archive1,
  TimeFunc,
  MiscUser;

VAR
  CallFromArea: Integer;

PROCEDURE CStuff(Which,How: Byte; VAR User: UserRecordType);
VAR
  Try: Byte;
  Done,
  Done1: Boolean;

  PROCEDURE FindArea;
  VAR
    Cmd: Char;
  BEGIN
    Print('Are you calling from:');
    NL;
    Print('(1) United States');
    Print('(2) Canada');
    Print('(3) Other country');
    NL;
    Prt('Select (1-3): ');
    OneK(Cmd,'123',TRUE,TRUE);
    CallFromArea := (Ord(Cmd) - 48);
    Done1 := TRUE;
  END;

  PROCEDURE ConfigureQWK;
  VAR
    ArcExt: Str3;
    AType: Byte;
  BEGIN
    IF (User.DefArcType < 1) OR (User.DefArcType > MaxArcs) THEN
      User.DefArcType := 1;
    Print('Current archive type: ^5'+General.FileArcInfo[User.DefArcType].Ext);
    NL;
    REPEAT
      Prt('Archive type to use? (?=List): ');
      MPL(3);
      Input(ArcExt,3);
      IF (ArcExt = '?') THEN
      BEGIN
        NL;
        ListArcTypes;
        NL;
      END;
    UNTIL (ArcExt <> '?') OR (HangUp);
    IF (StrToInt(ArcExt) <> 0) THEN
      AType := StrToInt(ArcExt)
    ELSE
      AType := ArcType('F.'+ArcExt);
    IF (AType > 0) AND (AType < MaxArcs) THEN
      User.DefArcType := AType;
    Done1 := TRUE;
    NL;
    User.GetOwnQWK := PYNQ('Do you want your own replies in your QWK packet? ',0,FALSE);
    NL;
    User.ScanFilesQWK := PYNQ('Would you like a new files listing in your QWK packet? ',0,FALSE);
    NL;
    User.PrivateQWK := PYNQ('Do you want your private mail in your QWK packet? ',0,FALSE);
    NL;
  END;

  PROCEDURE DoAddress;
  VAR
    TempStreet: Str30;
  BEGIN
    Print('Enter your street address:');
    Prt(': ');
    MPL((SizeOf(User.Street) - 1));
    IF (How = 3) THEN
      InputL(TempStreet,(SizeOf(User.Street) - 1))
    ELSE
      InputCaps(TempStreet,(SizeOf(User.Street) - 1));
    IF (TempStreet <> '') THEN
    BEGIN
      IF (How = 2) THEN
        SysOpLog('Changed address from '+User.Street+' to '+TempStreet);
      User.Street := TempStreet;
      Done1 := TRUE;
    END;
  END;

  PROCEDURE DoAge;
  VAR
    TempDate: Str10;
    TempDay,
    TempMonth,
    TempYear,
    CurYear: Word;
    Redo: Boolean;
  BEGIN
    GetYear(CurYear);
    IF (How = 1) AND (IEMSIRec.BDate <> '') THEN
    BEGIN
      Buf := IEMSIRec.BDate;
      IEMSIRec.BDate := '';
    END;
    REPEAT
      Redo := False;
      Print('Enter your date of birth (mm/dd/yyyy):');
      Prt(': ');
      InputFormatted('',TempDate,'##/##/####',(How = 3));
      IF (TempDate <> '') THEN
      BEGIN
        TempMonth := StrToInt(Copy(TempDate,1,2));
        TempDay := StrToInt(Copy(TempDate,4,2));
        TempYear := StrToInt(Copy(TempDate,7,4));
        IF (TempMonth = 0) OR (TempDay = 0) OR (TempYear = 0) THEN
          ReDo := TRUE;
        IF (TempMonth > 12) THEN
          Redo := TRUE;
        IF (TempMonth IN [1,3,5,7,8,10,12]) AND (TempDay > 31) THEN
          Redo := TRUE;
        IF (TempMonth IN [4,6,9,11]) AND (TempDay > 30) THEN
          Redo := TRUE;
        IF (TempMonth = 2) AND ((TempYear MOD 4) <> 0) AND (TempDay > 28) THEN
          Redo := TRUE;
        IF (TempMonth = 2) AND ((TempYear MOD 4) = 0) AND (TempDay > 29) THEN
          Redo := TRUE;
        IF (TempYear >= CurYear) THEN
          Redo := TRUE;
        IF (TempYear < (CurYear - 100)) THEN
          Redo := TRUE;
        IF (Redo) THEN
        BEGIN
          NL;
          Print('^7You entered an invalid date of birth!^1');
          NL;
        END;
      END;
    UNTIL (NOT Redo) OR (HangUp);
    IF (TempDate <> '') THEN
    BEGIN
      IF (How = 2) THEN
        SysOpLog('Changed birthdate from '+PD2Date(User.BirthDate)+' to '+TempDate);
      User.BirthDate := Date2PD(TempDate);
    END;
    Done1 := TRUE;
  END;

  PROCEDURE DoCityState;
  VAR
    s,
    s1,
    s2: AStr;
  BEGIN
    CASE How OF
      2 : FindArea;
      3 : CallFromArea := 1;
    END;
    IF (CallFromArea <> 3) THEN
    BEGIN
      IF (How = 3) THEN
      BEGIN
        Print('Enter new city & state abbreviation:');
        Prt(': ');
        MPL((SizeOf(User.CityState) - 1));
        InputL(s,(SizeOf(User.CityState) - 1));
        IF (s <> '') THEN
          User.CityState := s;
        Done1 := TRUE;
        Exit;
      END;

      Print('Enter only your city:');
      Prt(': ');
      MPL(((SizeOf(User.CityState) - 1) - 4));
      InputCaps(s,((SizeOf(User.CityState) - 1) - 4));
      IF (Pos(',',s) <> 0) THEN
      BEGIN
        NL;
        Print('^7Enter only your city name.^1');
        Exit;
      END;
      NL;
      IF (Length(s) < 3) THEN
        Exit;
      Prompt('Enter your '+AOnOff((CallFromArea = 1),'state','province')+' abbreviation: ');
      MPL(2);
      Input(s1,2);
      User.CityState := s+', '+s1;
      Done1 := TRUE;
    END
    ELSE
    BEGIN
      Print('First enter your city name only:');
      Prt(': ');
      MPL(26);
      InputCaps(s1,26);
      IF (Length(s1) < 2) THEN
        Exit;
       NL;
      Print('Now enter your country name:');
      Prt(': ');
      MPL(26);
      InputCaps(s2,26);
      IF (Length(s2) < 2) THEN
        Exit;
       s := s1+', '+s2;
       IF (Length(s) > 30) THEN
      BEGIN
        Print('^7Max total Length is 30 characters!^1');
        Exit;
      END;
       IF (How = 2) AND (User.CityState <> s) THEN
        SysOpLog('Changed city/state from '+User.CityState+' to '+s);
       User.CityState := s;
      Done1 := TRUE;
    END;
  END;

  PROCEDURE DoUserDef(QuestionNum: Byte);
  VAR
    UserDefQues: STRING[80];
    s: Str35;
  BEGIN
    CASE QuestionNum OF
      1 : UserDefQues := lRGLngStr(38,TRUE); {'Is ALL of your information REAL & CORRECT? (Yes/No)'}
      2 : UserDefQues := lRGLngStr(39,TRUE); {'Do you run a Telnet BBS? (If so, type in address below)'}
      3 : UserDefQues := lRGLngStr(40,TRUE); {'What BBS or Web Site did you hear about this BBS? (Specific Please)'}
    END;
    IF (UserDefQues = '') THEN
    BEGIN
      User.UsrDefStr[QuestionNum] := '';
      Done1 := TRUE;
      Exit;
    END;
    Print(UserDefQues);
    Prt(': ');
    MPL((SizeOf(User.UsrDefStr[QuestionNum]) - 1));
    InputL(s,(SizeOf(User.UsrDefStr[QuestionNum]) - 1));
    IF (s <> '') THEN
    BEGIN
      User.UsrDefStr[QuestionNum] := s;
      Done1 := TRUE;
    END;
  END;

  PROCEDURE DoName;
  VAR
    TextFile: Text;
    s,
    s1,
    s2: AStr;
    UNum: Integer;
  BEGIN
    IF (How = 1) THEN
      IF (General.AllowAlias) AND (IEMSIRec.Handle <> '') THEN
      BEGIN
        Buf := IEMSIRec.Handle;
        IEMSIRec.Handle := '';
      END
      ELSE IF (IEMSIRec.UserName <> '') THEN
      BEGIN
        Buf := IEMSIRec.UserName;
        IEMSIRec.UserName := '';
      END;
    IF (General.AllowAlias) THEN
    BEGIN
      Print('Enter your handle, or your real first & last');
      Print('names if you don''t want to use one.')
    END
    ELSE
    BEGIN
      Print('Enter your first & last Name.');
      Print('Handles are not allowed.');
    END;
    Prt(': ');
    MPL((SizeOf(User.Name) - 1));
    Input(s,(SizeOf(User.Name) -1));
    Done1 := FALSE;
    WHILE (s[1] IN [' ','0'..'9']) AND (Length(s) > 0) do
      Delete(s,1,1);
    WHILE (s[Length(s)] = ' ') do
      Dec(s[0]);
    IF ((Pos(' ',s) = 0) AND (How <> 3) AND NOT (General.AllowAlias)) THEN
    BEGIN
      NL;
      Print('Enter your first and last Name!');
      s := '';
    END;
    IF (s <> '') THEN
    BEGIN
      Done1 := TRUE;
      UNum := SearchUser(s,TRUE);
      IF (UNum > 0) AND (UNum <> UserNum) THEN
      BEGIN
        Done1 := FALSE;
        NL;
        Print('^7That name is in use.^1');
      END;
    END;
    Assign(TextFile,General.MiscPath+'TRASHCAN.TXT');
    Reset(TextFile);
    IF (IOResult = 0) THEN
    BEGIN
      s2 := ' '+s+' ';
      WHILE NOT EOF(TextFile) do
      BEGIN
        ReadLn(TextFile,s1);
        IF (s1[Length(s1)] = #1) THEN
          s1[Length(s1)] := ' '
        ELSE
          s1 := s1 + ' ';
        s1 := ' ' + s1;
        S1 := AllCaps(S1);
        IF (Pos(s1,s2) <> 0) THEN
          Done1 := FALSE;
      END;
      Close(TextFile);
      LastError := IOResult;
    END;
    IF (NOT Done1) AND (NOT HangUp) THEN
    BEGIN
      NL;
      Print(^G'^7Sorry, can''t use that name.^1');
      Inc(Try);
      sl1('Unacceptable Name : '+s);
    END;
    IF (Try >= 3) AND (How = 1) THEN
      HangUp := TRUE;

    IF ((Done) AND (How = 1) AND (NOT General.AllowAlias)) THEN
      User.RealName := Caps(s);

    IF (Done1) THEN
    BEGIN
      IF (How = 2) AND (UserNum > -1) THEN  { Don't do index on unregged users! }
      BEGIN
        SysOpLog('Changed name from '+User.Name+' to '+s);
        InsertIndex(User.Name,UserNum,FALSE,TRUE);
        User.Name := s;
        InsertIndex(User.Name,UserNum,FALSE,FALSE);
      END
      ELSE
        User.Name := s;
    END;
  END;

  PROCEDURE DoPhone;
  VAR
    TempPhone: AStr;
  BEGIN
    CASE How OF
      1 : BEGIN
            IF (IEMSIRec.Ph <> '') THEN
            BEGIN
              Buf := IEMSIRec.Ph;
              IEMSIRec.Ph := '';
            END;
          END;
      2 : FindArea;
      3 : CallFromArea := 1;
    END;
    Print('Enter your phone number:');
    Prt(': ');
    IF (((How = 1) AND (CallFromArea = 3)) OR (How = 3)) THEN
    BEGIN
      MPL(12);
      Input(TempPhone,12);
      IF (Length(TempPhone) > 5) THEN
      BEGIN
        User.Ph := TempPhone;
        Done1 := TRUE;
      END;
    END
    ELSE
    BEGIN
      InputFormatted('',TempPhone,'(###)###-####',FALSE);
      TempPhone[5] := '-';
      TempPhone := Copy(TempPhone,2,(Length(TempPhone) - 1));
      IF (How = 2) AND (User.Ph <> TempPhone) THEN
        SysOpLog('Changed phone from '+User.Ph+' to '+TempPhone);
      User.Ph := TempPhone;
      Done1 := TRUE;
    END;
  END;

  PROCEDURE DoPW;
  VAR
    s,
    s2: STRING[20];
    SavePW: LongInt;
  BEGIN
    IF (How = 1) AND (IEMSIRec.PW <> '') THEN
    BEGIN
      Buf := IEMSIRec.PW;
      IEMSIRec.PW := '';
    END;
    SavePW := User.PW;
    IF (How = 2) THEN
    BEGIN
      Print('^5Enter your current password:');
      NL;
      Prompt('Password: ^5');
      GetPassword(s,20);
      IF (CRC32(s) <> User.PW) THEN
      BEGIN
        NL;
        Print('Wrong!');
        NL;
        Exit;
      END;
    END;
    REPEAT
      REPEAT
        Print('Enter your desired password for future access.');
        Print('It should be 4 to 20 characters in length.');
        NL;
        Prompt('Password: ');
        MPL(20);
        GetPassword(s,20);
        NL;
        IF (Length(s) < 4) THEN
        BEGIN
          Print('^7Must be at least 4 characters long!^1');
          NL;
        END
        ELSE IF (Length(s) > 20) THEN
        BEGIN
          Print('^7Must be no more than 20 characters long.^1');
          NL;
        END
        ELSE IF (How = 3) AND (CRC32(s) = SavePW) THEN
        BEGIN
          Print('^7Must be different from your old password!^1');
          NL;
          s := '';
        END
        ELSE IF (s = ThisUser.Name) OR (s = ThisUser.RealName) THEN
        BEGIN
          Print('^7You cannot use that password!^1');
          NL;
          s := '';
        END;
      UNTIL (((Length(s) > 3) AND (Length(s) < 21)) OR (HangUp));
      Print('Enter your password again for verification:');
      NL;
      Prompt('Password: ');
      MPL(20);
      GetPassword(s2,20);
      IF (s2 <> s) THEN
      BEGIN
        NL;
        Print('^7Passwords do not match!^1');
        NL;
      END;
    UNTIL ((s2 = s) OR (HangUp));
    IF (HangUp) AND (How = 3) THEN
      User.PW := SavePW
    ELSE
      User.PW := CRC32(s);
    User.PasswordChanged := DayNum(DateStr);
    IF (How = 2) THEN
    BEGIN
      NL;
      Print('Password changed.');
      SysOpLog('Changed password.');
    END;
    Done1 := TRUE;
  END;

  PROCEDURE DoForgotPW;
  VAR
    s: AStr;
  BEGIN
    IF (How IN [1..2]) THEN
    BEGIN
      REPEAT
        s := '';
        Print('This question will be asked should you ever forget your password.');
        NL;
        Print(General.forgotpwquestion);
        Prt(': ');
        MPL(40);
        Input(s,40);
      UNTIL (s <> '') OR (HangUp);
      User.ForgotPWAnswer := s;
      Done1 := TRUE;
    END;
  END;

  PROCEDURE DoRealName;
  VAR
    TempRealName: AStr;
    UNum: Integer;
  BEGIN
    IF (How = 1) THEN
      IF (NOT General.AllowAlias) THEN
      BEGIN
        User.RealName := Caps(User.Name);
        Done1 := TRUE;
        Exit;
      END
      ELSE IF (IEMSIRec.UserName <> '') THEN
      BEGIN
        Buf := IEMSIRec.UserName;
        IEMSIRec.UserName := '';
      END;
    Print('Enter your real first & last name:');
    Prt(': ');
    MPL((SizeOf(User.RealName) - 1));
    IF (How = 3) THEN
      InputL(TempRealName,(SizeOf(User.RealName) - 1))
    ELSE
      InputCaps(TempRealName,(SizeOf(User.RealName) - 1));
    WHILE (TempRealName[1] IN [' ','0'..'9']) AND (Length(TempRealName) > 0) do
      Delete(TempRealName,1,1);
    WHILE (TempRealName[Length(TempRealName)] = ' ') do
      Dec(TempRealName[0]);
    IF (Pos(' ',TempRealName) = 0) AND (How <> 3) THEN
    BEGIN
      NL;
      Print('Enter your first and last name!');
      TempRealName := '';
    END;
    IF (TempRealName <> '') THEN
    BEGIN
      Done1 := TRUE;
      UNum := SearchUser(TempRealName,TRUE);
      IF (UNum > 0) AND (UNum <> UserNum) THEN
      BEGIN
        Done1 := FALSE;
        NL;
        Print('^7That name is in use.^1');
      END;
    END;
    IF (Done1) THEN
    BEGIN
      IF (How = 2) AND (UserNum > -1) THEN { don't do index on unregged users! }
      BEGIN
        SysOpLog('Changed real name from '+User.RealName+' to '+TempRealName);
        InsertIndex(User.RealName,UserNum,TRUE,TRUE);
        User.RealName := TempRealName;
        InsertIndex(User.RealName,UserNum,TRUE,FALSE);
      END
      ELSE
        User.RealName := TempRealName;
      Done1 := TRUE;
    END;
  END;

  PROCEDURE DoScreen;
  BEGIN
    InputByteWOC('How wide is your screen',User.LineLen,[DisplayValue,NumbersOnly],32,132);
    InputByteWOC('%LFHow many lines per page',User.PageLen,[DisplayValue,NumbersOnly],4,50);
    Done1 := TRUE;
  END;

  PROCEDURE DoSex;
  VAR
    Cmd: Char;
  BEGIN
    IF (How = 3) THEN
    BEGIN
      Prt('New gender (M,F): ');
      OneK(Cmd,'MF '^M,TRUE,TRUE);
      IF (Cmd IN ['M','F']) THEN
        User.Sex := Cmd;
    END
    ELSE
    BEGIN
      User.Sex := #0;
      Prt('Your gender (M,F)? ');
      OneK(User.Sex,'MF',TRUE,TRUE);
    END;
    Done1 := TRUE;
  END;

  PROCEDURE DoZIPCode;
  VAR
    TempZipCode: Str10;
  BEGIN
    IF (How = 3) THEN
    BEGIN
      FindArea;
      NL;
    END;
    CASE CallFromArea OF
      1 : BEGIN
            Print('Enter your zipcode (#####-####):');
            Prt(': ');
            InputFormatted('',TempZipCode,'#####-####',(How = 3));
            IF (TempZipCode <> '') THEN
              User.ZipCode := TempZipCode;
            Done1 := TRUE;
          END;
      2 : BEGIN
            Print('Enter your postal code (LNLNLN format)');
            Prt(': ');
            InputFormatted('',TempZipCode,'@#@#@#',(How = 3));
            IF (TempZipCode <> '') THEN
              User.ZipCode := TempZipCode;
            Done1 := TRUE
          END;
      3 : BEGIN
            Print('Enter your postal code:');
            Prt(': ');
            MPL((SizeOf(User.ZipCode) - 1));
            Input(TempZipCode,(SizeOf(User.ZipCode) - 1));
            IF (Length(TempZipCode) > 2) THEN
            BEGIN
              User.ZipCode := TempZipCode;
              Done1 := TRUE;
            END;
          END;
    END;
  END;

  PROCEDURE ForwardMail;
  VAR
    User1: UserRecordType;
    Unum: Integer;
  BEGIN
    NL;
    Print('^5If you forward your mail, all email sent to your account^1');
    Print('^5will be redirected to that person.^1');
    NL;
    Print('Enter User Number, Name, or Partial Search String.');
    Prt(': ');
    lFindUserWS(UNum);
    IF (UNum < 1) OR (UNum > (MaxUsers - 1)) THEN
      User.ForUsr := 0
    ELSE
    BEGIN
      LoadURec(User1,UNum);
      IF (User.Name = User1.Name) OR (LockedOut IN User1.SFlags) OR
         (Deleted IN User1.SFlags) OR (NoMail IN User1.Flags) THEN
      BEGIN
        NL;
        Print('^7You can not forward mail to that user!^1');
      END
      ELSE
      BEGIN
        User.ForUsr := UNum;
        NL;
        Print('Forwarding mail to: ^5'+Caps(User1.Name)+' #'+IntToStr(UNum)+'^1');
        SysOpLog('Forwarding mail to: ^5'+Caps(User1.Name)+' #'+IntToStr(UNum));
      END;
    END;
    IF (How = 3) THEN
      PauseSCr(FALSE);
  END;

  PROCEDURE MailBox;
  BEGIN
    IF (NoMail IN User.Flags) THEN
    BEGIN
      Exclude(User.Flags,NoMail);
      Print('Mail box is now open.');
      IF (How = 3) THEN
        PauseScr(FALSE);
      SysOpLog('Mail box is now open.');
    END
    ELSE IF (User.ForUsr <> 0) THEN
    BEGIN
      User.ForUsr := 0;
      Print('Mail is no longer being forwarded.');
      IF (How = 3) THEN
        PauseSCr(FALSE);
      SysOpLog('Mail forwarding ended.');
    END
    ELSE
    BEGIN
      IF PYNQ('Do you want to close your mail box? ',0,FALSE) THEN
      BEGIN
        Include(User.Flags,NoMail);
        NL;
        Print('Mail box is now closed.');
        IF (How = 3) THEN
          PauseSCr(FALSE);
        SysOpLog('Mail box is now closed.');
      END
      ELSE
      BEGIN
        NL;
        IF PYNQ('Do you want to forward your mail? ',0,FALSE) THEN
          ForwardMail;
      END;
    END;
    Done1 := TRUE;
  END;

  PROCEDURE Toggle_ANSI;
  VAR
    Cmd: Char;
  BEGIN
    PrintF('TERMINAL');
    Print('Which terminal emulation do you support?');
    NL;
    Print('(1) None');
    Print('(2) ANSI');
    Print('(3) Avatar');
    Print('(4) VT-100');
    Print('(5) RIP Graphics');
    NL;
    Prt('Select (1-5): ');
    OneK(Cmd,'12345',TRUE,TRUE);
    Exclude(User.Flags,ANSI);
    Exclude(User.Flags,Avatar);
    Exclude(User.Flags,VT100);
    Exclude(User.SFlags,RIP);
    CASE Cmd OF
      '2' : Include(User.Flags,ANSI);
      '3' : BEGIN
              Include(User.Flags,Avatar);
              NL;
              IF PYNQ('Does your terminal program support ANSI fallback? ',0,TRUE) THEN
                Include(User.Flags,ANSI);
            END;
      '4' : Include(User.Flags,VT100);
      '5' : BEGIN
              Include(User.Flags,ANSI);
              Include(User.SFlags,RIP);
            END;
    END;
    IF (ANSI IN User.Flags) OR (Avatar IN User.Flags) OR (VT100 IN User.Flags) THEN
      Include(User.SFlags,FSEditor)
    ELSE
      Exclude(User.SFlags,FSEditor);
    NL;
    IF (PYNQ('Would you like this to be auto-detected in the future? ',0,TRUE)) THEN
      Include(User.SFlags,AutoDetect)
    ELSE
      Exclude(User.SFlags,AutoDetect);
    Done1 := TRUE;
  END;

  PROCEDURE Toggle_Color;
  BEGIN
    IF (Color IN User.Flags) THEN
    BEGIN
      Exclude(User.Flags,Color);
      Print('ANSI Color disabled.');
    END
    ELSE
    BEGIN
      Include(User.Flags,Color);
      Print('ANSI Color enabled.');
    END;
    Done1 := TRUE;
  END;

  PROCEDURE Toggle_Pause;
  BEGIN
    IF (Pause IN User.Flags) THEN
    BEGIN
      Exclude(User.Flags,Pause);
      Print('Pause on screen disabled');
    END
    ELSE
    BEGIN
      Include(User.Flags,Pause);
      Print('Pause on screen enabled');
    END;
    Done1 := TRUE;
  END;

  PROCEDURE Toggle_Editor;
  BEGIN
    Done1 := TRUE;
    IF (NOT (ANSI IN User.Flags)) AND (NOT (Avatar IN User.Flags)) THEN
    BEGIN
      Print('You must use ANSI to use the full screen editor.');
      Exclude(User.SFlags,FSEditor);
      Exit;
    END;
    IF (FSEditor IN User.SFlags) THEN
    BEGIN
      Exclude(User.SFlags,FSEditor);
      Print('Full screen editor disabled.');
    END
    ELSE
    BEGIN
      Include(User.SFlags,FSEditor);
      Print('Full screen editor enabled.');
    END;
  END;

  PROCEDURE Toggle_Input;
  BEGIN
    IF (HotKey IN User.Flags) THEN
    BEGIN
      Exclude(User.Flags,HotKey);
      Print('Full line input.');
    END
    ELSE
    BEGIN
      Include(User.Flags,HotKey);
      Print('Hot key input.');
    END;
    Done1 := TRUE;
  END;

  PROCEDURE Toggle_CLSMsg;
  BEGIN
    IF (CLSMsg IN User.SFlags) THEN
    BEGIN
      Exclude(User.SFlags,CLSMsg);
      Print('Screen clearing off.');
    END
    ELSE
    BEGIN
      Include(User.SFlags,CLSMsg);
      Print('Screen clearing on.');
    END;
    Done1 := TRUE;
  END;

  PROCEDURE Toggle_Expert;
  BEGIN
    IF (Novice IN User.Flags) THEN
    BEGIN
      Exclude(User.Flags,Novice);
      CurHelpLevel := 1;
      Print('Expert mode on.');
    END
    ELSE
    BEGIN
      Include(User.Flags,Novice);
      CurHelpLevel := 2;
      Print('Expert mode off.');
    END;
    Done1 := TRUE;
  END;

  PROCEDURE Toggle_File_Area_LightBar;
  BEGIN
    IF (NOT General.UseFileAreaLightBar) THEN
    BEGIN
      NL;
      Print('File area lightbar support is not available.');
    END
    ELSE
    BEGIN
      IF (FileAreaLightBar IN ThisUser.SFlags) THEN
      BEGIN
        Exclude(ThisUser.SFlags,FileAreaLightBar);
        Print('File area lightbar support is now off.');
      END
      ELSE
      BEGIN
        Include(ThisUser.SFlags,FileAreaLightBar);
        Print('File area lightbar support is now on.');
      END;
    END;
    Done1 := TRUE;
  END;

  PROCEDURE Toggle_Message_Area_LightBar;
  BEGIN
    IF (NOT General.UseMsgAreaLightBar) THEN
    BEGIN
      NL;
      Print('Message area lightbar support is not available.');
    END
    ELSE
    BEGIN
      IF (MsgAreaLightBar IN ThisUser.SFlags) THEN
      BEGIN
        Exclude(ThisUser.SFlags,MsgAreaLightBar);
        Print('Message area lightbar support is now off.');
      END
      ELSE
      BEGIN
        Include(ThisUser.SFlags,MsgAreaLightBar);
        Print('Message area lightbar support is now on.');
      END;
    END;
    Done1 := TRUE;
  END;

  PROCEDURE CHColors;
  VAR
    AScheme: SchemeRec;
    i,
    Onlin: SmallInt;
  BEGIN
    Reset(SchemeFile);
    CLS;
    Abort := FALSE;
    Next := FALSE;
    PrintACR('Available Color schemes:');
    NL;
    i := 1;
    Onlin := 0;
    Seek(SchemeFile,0);
    WHILE (FilePos(SchemeFile) < FileSize(SchemeFile)) AND (NOT Abort) AND (NOT HangUp) do
    BEGIN
      Read(SchemeFile,AScheme);
      Inc(Onlin);
      Prompt(PadLeftInt(i,2)+'. ^3'+PadLeftStr(AScheme.Description,35));
      IF (OnLin = 2) THEN
      BEGIN
        NL;
        Onlin := 0;
      END;
      WKey;
      Inc(i);
    END;
    Abort := FALSE;
    Next := FALSE;
    NL;
    InputIntegerWOC('%LFSelect a color scheme',i,[NumbersOnly],1,FileSize(SchemeFile));
    IF (i >= 1) AND (i <= FileSize(SchemeFile)) THEN
    BEGIN
      ThisUser.ColorScheme := i;
      Seek(SchemeFile,(i - 1));
      Read(SchemeFile,Scheme);
      Done1 := TRUE;
    END;
    Close(SchemeFile);
    LastError := IOResult;
  END;

  PROCEDURE CheckWantPause;
  BEGIN
    IF PYNQ('Pause after each screen? ',0,TRUE) THEN
      Include(User.Flags,Pause)
    ELSE
      Exclude(User.Flags,Pause);
    Done1 := TRUE;
  END;

  PROCEDURE CheckWantInput;
  BEGIN
    IF PYNQ('Do you want to use Hot Keys? ',0,TRUE) THEN
      Include(User.Flags,HotKey)
    ELSE
      Exclude(User.Flags,HotKey);
    Done1 := TRUE;
  END;

  PROCEDURE CheckWantExpert;
  BEGIN
    IF PYNQ('Do you want to be in expert mode? ',0,FALSE) THEN
      Exclude(User.Flags,Novice)
    ELSE
      Include(User.Flags,Novice);
    Done1 := TRUE;
  END;

  PROCEDURE CheckWantCLSMsg;
  BEGIN
    IF PYNQ('Clear screen before each message read? ',0,TRUE) THEN
      Include(User.SFlags,CLSMsg)
    ELSE
      Exclude(User.SFlags,CLSMsg);
    Done1 := TRUE;
  END;

  PROCEDURE WW(www: Byte);
  BEGIN
    NL;
    CASE www OF
      1 : DoAddress;
      2 : DoAge;
      3 : Toggle_ANSI;
      4 : DoCityState;
      5 : DoUserDef(1);
      6 : DoUserDef(2);
      7 : DoName;
      8 : DoPhone;
      9 : DoPW;
     10 : DoRealName;
     11 : DoScreen;
     12 : DoSex;
     13 : DoUserDef(3);
     14 : DoZIPCode;
     15 : MailBox;
     16 : Toggle_ANSI;
     17 : Toggle_Color;
     18 : Toggle_Pause;
     19 : Toggle_Input;
     20 : Toggle_CLSMsg;
     21 : CHColors;
     22 : Toggle_Expert;
     23 : FindArea;
     24 : CheckWantPause;
     25 : CheckWantInput;
     26 : Toggle_Editor;
     27 : ConfigureQWK;
     28 : CheckWantExpert;
     29 : CheckWantCLSMsg;
     30 : DoForgotPW;
     31 : Toggle_File_Area_LightBar;
     32 : Toggle_Message_Area_LightBar;
    END;
  END;

BEGIN
  Try := 0;
  Done1 := FALSE;
  CASE How OF
    1 : REPEAT
          WW(Which)
        UNTIL (Done1) OR (HangUp);
    2,3 :
        BEGIN
          WW(Which);
          IF (NOT Done1) THEN
            Print('Function aborted!');
        END;
  END;
END;

END.
