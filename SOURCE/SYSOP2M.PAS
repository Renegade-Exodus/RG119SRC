{$IFDEF WIN32}
{$I DEFINES.INC}
{$ENDIF}

{$A+,B-,D-,E-,F+,I-,L-,N-,O+,R-,S+,V-}

UNIT SysOp2M;

INTERFACE

PROCEDURE NewUserTogglesConfiguration;

IMPLEMENTATION

USES
  Common;

PROCEDURE NewUserTogglesConfiguration;
VAR
  TempStr: STRING[70];
  Cmd: CHAR;
  TempB: BYTE;
  Changed: Boolean;

  FUNCTION Toggle(NUToggle,CUSerNum: BYTE): BYTE;
  BEGIN
    IF (NUToggle = 0) THEN
      Toggle := CUserNum
    ELSE
      Toggle := 0;
  END;

BEGIN
  REPEAT
    CLS;
    Abort := FALSE;
    Next := FALSE;
    MCIAllowed := FALSE;
    WITH General DO
    BEGIN
      Print('^5New User Question Toggles Configuration:');
      NL;
      NewUserToggles[1] := 7;
      PrintACR('^1A. Ask what the REAL NAME is           : ^5'+ShowYesNo(NewUserToggles[2] <> 0));
      PrintACR('^1B. Ask which COUNTRY from              : ^5'+ShowYesNo(NewUserToggles[3] <> 0));
      PrintACR('^1C. Ask what the ADDRESS is             : ^5'+ShowYesNo(NewUserToggles[4] <> 0));
      PrintACR('^1D. Ask what the CITY, STATE is         : ^5'+ShowYesNo(NewUserToggles[5] <> 0));
      PrintACR('^1E. Ask what the ZIP CODE is            : ^5'+ShowYesNo(NewUserToggles[6] <> 0));
      PrintACR('^1F. Ask what the PHONE NUMBER is        : ^5'+ShowYesNo(NewUserToggles[7] <> 0));
      PrintACR('^1G. Ask which Gender (Male/Female)      : ^5'+ShowYesNo(NewUserToggles[8] <> 0));
      PrintACR('^1H. Ask what the BIRTHDAY is            : ^5'+ShowYesNo(NewUserToggles[9] <> 0));
      PrintACR('^1I. Ask SysOp Question #1               : ^5'+ShowYesNo(NewUserToggles[10] <> 0));
      PrintACR('^1J. Ask SysOp Question #2               : ^5'+ShowYesNo(NewUserToggles[11] <> 0));
      PrintACR('^1K. Ask SysOp Question #3               : ^5'+ShowYesNo(NewUserToggles[12] <> 0));
      PrintACR('^1L. Ask EMULATION that is required      : ^5'+ShowYesNo(NewUserToggles[13] <> 0));
      PrintACR('^1M. Ask SCREEN SIZE that is required    : ^5'+ShowYesNo(NewUserToggles[14] <> 0));
      PrintACR('^1N. Ask if Msg SCREEN CLEARING is needed: ^5'+ShowYesNo(NewUserToggles[15] <> 0));
      PrintACR('^1O. Ask if SCREEN PAUSES are needed     : ^5'+ShowYesNo(NewUserToggles[16] <> 0));
      PrintACR('^1P. Ask if HOTKEYS are needed           : ^5'+ShowYesNo(NewUserToggles[17] <> 0));
      PrintACR('^1R. Ask if EXPERT MODE is needed        : ^5'+ShowYesNo(NewUserToggles[18] <> 0));
      NewUserToggles[19] := 9;
      PrintACR('^1S. Ask FORGOT PW question              : ^5'+ShowYesNo(NewUserToggles[20] <> 0));
      IF (ForgotPWQuestion <> '') THEN
        PrintACR('^1   ('+ForgotPWQuestion+')');
    END;
    MCIAllowed := TRUE;
    Prt('%LFEnter selection [^5A^4-^5P^4,^5R^4-^5S^4,^5Q^4=^5Quit^4]: ');
    OneK(Cmd,'QABCDEFGHIJKLMNOPRS'^M,TRUE,TRUE);
    WITH General DO
      CASE Cmd OF
        'A' : NewUserToggles[2] := Toggle(NewUserToggles[2],10);
        'B' : NewUserToggles[3] := Toggle(NewUserToggles[3],23);
        'C' : NewUserToggles[4] := Toggle(NewUserToggles[4],1);
        'D' : NewUserToggles[5] := Toggle(NewUserToggles[5],4);
        'E' : NewUserToggles[6] := Toggle(NewUserToggles[6],14);
        'F' : BEGIN
                NewUserToggles[7] := Toggle(NewUserToggles[7],8);
                IF (NewUserToggles[7] <> 0) THEN
                  General.PhonePW := TRUE
                ELSE
                  General.PhonePW := FALSE;
             END;
       'G' : NewUserToggles[8] := Toggle(NewUserToggles[8],12);
       'H' : BEGIN
               NewUserToggles[9] := Toggle(NewUserToggles[9],2);
               (*
               IF (NewUserToggles[9] = 0) THEN
                 General.BirthDateCheck := 0
               ELSE
               BEGIN
                 REPEAT
                   NL;
                   Prt('Logins before birthday check (0-255): ');
                   Ini(TempB);
                   IF (TempB < 0) OR (TempB > 255) THEN
                   BEGIN
                     NL;
                     Print('Invalid Range!');
                     PauseScr(FALSE);
                   END;
                 UNTIL (TempB >= 0) AND (TempB <= 255) OR (HangUp);
                 General.BirthDateCheck := TempB;
               END;
               *)
             END;
       'I' : NewUserToggles[10] := Toggle(NewUserToggles[10],5);
       'J' : NewUserToggles[11] := Toggle(NewUserToggles[11],6);
       'K' : NewUserToggles[12] := Toggle(NewUserToggles[12],13);
       'L' : NewUserToggles[13] := Toggle(NewUserToggles[13],3);
       'M' : NewUserToggles[14] := Toggle(NewUserToggles[14],11);
       'N' : NewUserToggles[15] := Toggle(NewUserToggles[15],29);
       'O' : NewUserToggles[16] := Toggle(NewUserToggles[16],24);
       'P' : NewUserToggles[17] := Toggle(NewUserToggles[17],25);
       'R' : NewUserToggles[18] := Toggle(NewUserToggles[18],28);
       'S' : BEGIN
               NewUserToggles[20] := Toggle(NewUserToggles[20],30);
               IF (NewUserToggles[20] = 0) THEN
                 ForgotPWQuestion := ''
               ELSE
               BEGIN
                 TempStr := General.ForgotPWQuestion;
                 REPEAT
                   InputWN1('%LFEnter question to ask user if they forget thier password:%LF: ',TempStr,70,
                            [InterActiveEdit],Changed);
                 UNTIL (TempStr <> '') OR (HangUp);
                 IF (Changed) THEN
                   ForgotPWQuestion := TempStr;
               END;
             END;
      END;
  UNTIL (Cmd = 'Q') OR (HangUp);
END;

END.
