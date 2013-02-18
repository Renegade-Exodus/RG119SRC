{$A+,B-,D-,E-,F+,I-,L-,N-,O+,R-,S+,V-}

UNIT Menus4;

INTERFACE

USES
  Common;

PROCEDURE AutoValidationCmd(CONST PW: AStr; Level: Char);

IMPLEMENTATION

PROCEDURE AutoValidationCmd(CONST PW: AStr; Level: Char);
VAR
  TempStr: AStr;
BEGIN
  NL;
  IF (ThisUser.SL = General.Validation[Level].NewSL) AND (ThisUser.DSL = General.Validation[Level].NewDSL) THEN
  BEGIN
    Print('You''ve been validated!  You do not need to use this command.');
    Exit;
  END;
  Print('Press [Enter] to abort.');
  NL;
  Prt('Password: ');
  Input(TempStr,50);
  NL;
  IF (TempStr = '') THEN
    Print('^7Function aborted.'^G)
  ELSE
  BEGIN
    IF (TempStr <> AllCaps(PW)) THEN
    BEGIN
      Print('^7Wrong!'^G);
      SysOpLog('Wrong password for auto-validation: "'+TempStr+'"');
    END
    ELSE
    BEGIN
      AutoValidate(ThisUser,UserNum,Level);
      lStatus_Screen(100,'This user has auto-validated himself.',FALSE,TempStr);
      PrintF('AUTOVAL');
      IF (NoFile) THEN
        Print('Correct.  You are now validated.');
      SysOpLog('Used auto-validation password.');
    END;
  END;
END;

END.
