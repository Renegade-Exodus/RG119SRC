{$IFDEF WIN32}
{$I DEFINES.INC}
{$ENDIF}

{$A+,B-,D-,E-,F+,I-,L-,N-,O+,R-,S+,V-}

UNIT TimeBank;

INTERFACE

PROCEDURE Deposit;
PROCEDURE WithDraw;

IMPLEMENTATION

USES
  Common;

(*
PROCEDURE TimeBank;
VAR
  CmdStr: Str3;
  Cmd: CHAR;
  DepositTime,
  MaxDepositTime: BYTE;

  FUNCTION MinStr(W: WORD): Str160;
  BEGIN
    MinStr := #3'3'+PadRightInt(W,3)+'   minutes';
  END;

BEGIN
  { Display time bank statistics }
  NewLine;
  Print(#3'0                  << Time Bank Information >>');
  NewLine;
  Print('Time left on-line      : '+MinStr(Trunc(TimeLeft / 60)));
  Print('Time in time bank      : '+MinStr(ThisUser.TimeBank));
  Print('Maximum allowed in bank: '+MinStr(Systat.MaxTimeInBank));
  NewLine;
  Print('Time deposited today   : '+MinStr(ThisUser.TbDeposit));
  Print('Maximum daily deposit  : '+MinStr(Systat.TbMaxDeposit));
  Print('Time withdrawn today   : '+MinStr(ThisUser.TbWithDraw));
  Print('Maximum daily withdraw : '+MinStr(Systat.TbMaxWithDraw));
  NewLine;
  Print('Time bank options available:');
  { Determine options user has available }
  CmdStr := 'Q';
  IF (Trunc(TimeLeft / 60) > 0) AND (ThisUser.TbDeposit < Systat.TbMaxDeposit) AND
     (ThisUser.TimeBank < Systat.MaxTimeInBank) THEN
  BEGIN
    Print('  ('#3'3D'#3'1)eposit time into the bank');
    CmdStr := CmdStr + 'D';
  END;
  IF (ThisUser.TimeBank > 0) AND (ThisUser.TbWithDraw < Systat.TbMaxWithDraw) THEN
  BEGIN
    Print('  ('#3'3W'#3'1)ithdraw time from the bank');
    CmdStr := CmdStr + 'W';
  END;
  Print('  ('#3'3Q'#3'1)uit (exit time bank manager)');
  NewLine;
  Prt('Time Bank: ');
  OneKeyInput(Cmd,CmdStr);
  CASE Cmd OF
    'D' : BEGIN
            { Set default deposit to use }
            DepositTime := 0;
            { Make sure user is unable to deposit more then maximum minus what
              was already deposited }
            MaxDepositTime := (Systat.TbMaxDeposit - ThisUser.TbDeposit);
            { Make sure user is unable to deposit more then they have }
            IF (MaxDepositTime > Trunc(TimeLeft / 60)) THEN
              MaxDepositTime := Trunc(TimeLeft / 60);
            InputByteWoc('How many minutes do you wish to deposit',DepositTime,[],0,MaxDepositTime,
                         Length(IntToStr(MaxDepositTime)),TRUE);
            IF (DepositTime >= 1) AND (DepositTime <= MaxDepositTime) THEN
            BEGIN
              { Increase what user deposited today }
              Inc(ThisUser.TbDeposit,DepositTime);
              { Increase what user has in bank }
              Inc(ThisUser.TimeBank,DepositTime);
              { Decrease user's time on-line }
              Dec(ThisUser.AdjTime,DepositTime);
            END;
          END;
    'W' : BEGIN
            { Set default withdraw to use }
            DepositTime := 0;
            { Make sure user is unable to withdraw more then maximum minus what
              was already withdrawn }
            MaxDepositTime := (Systat.TbMaxWithDraw - ThisUser.TbWithDraw);
            { Make sure user is unable to withdraw more then they have }
            IF (MaxDepositTime > ThisUser.TimeBank) THEN
              MaxDepositTime := ThisUser.TimeBank;
            InputByteWoc('How many minutes do you wish to withdraw',DepositTime,[],0,MaxDepositTime,
                         Length(IntToStr(MaxDepositTime)),TRUE);
            IF (DepositTime >= 1) AND (DepositTime <= MaxDepositTime) THEN
            BEGIN
              { Increase what user withdrew today }
              Inc(ThisUSer.TbWithDraw,DepositTime);
              { Decrease what user has in bank }
              Dec(ThisUser.TimeBank,DepositTime);
              { Increase user's time on-line }
              Inc(ThisUSer.AdjTime,DepositTime);
            END;
          END;
  END;
  IF (Cmd <> 'Q') THEN
  BEGIN
    { Display Time Bank Statistics }
    NewLine;
    TStr(255);
  END;
END;
*)

PROCEDURE Deposit;
CONST
  Deposit: LongInt = 0;
BEGIN
  NL;
  IF ((ThisUser.TimeBank >= General.MaxDepositEver) AND (General.MaxDepositEver <> 0)) THEN
  BEGIN
    Print('Your time bank has reached the maximum limit allowed.');
    PauseScr(FALSE);
    Exit;
  END;
  IF ((ThisUser.TimeBankAdd >= General.MaxDepositPerDay) AND (General.MaxDepositPerDay <> 0)) THEN
  BEGIN
    Print('You cannot deposit any more time today.');
    PauseScr(FALSE);
    Exit;
  END;

  Print('^5Time left online : ^3'+FormattedTime(NSL));
  Print('^5Time in time bank: ^3'+FormattedTime(ThisUser.TimeBank * 60));

  IF (General.MaxDepositEver > 0) THEN
    Print('^5Max account limit: ^3'+FormattedTime(General.MaxDepositEver * 60));

  IF (General.MaxDepositPerDay > 0) THEN
    Print('^5Max deposit/day  : ^3'+FormattedTime(General.MaxDepositPerDay * 60));

  IF (ThisUser.TimeBankAdd <> 0) THEN
    Print('^5Deposited today  : ^3'+FormattedTime(ThisUser.TimeBankAdd * 60));

  InputLongIntWOC('%LFDeposit how many minutes',Deposit,[DisplayValue,NumbersOnly],0,32767);

  IF (Deposit > 0) THEN
  BEGIN
    NL;
    IF ((Deposit * 60) > NSL) THEN
      Print('^7You don''t have that much time left to deposit!')
    ELSE IF ((Deposit + ThisUser.TimeBankAdd) > General.MaxDepositPerDay) AND (General.MaxDepositPerDay <> 0) THEN
      Print('^7You can only add '+IntToStr(General.MaxDepositPerDay)+' minutes to your account per day!')
    ELSE IF ((Deposit + ThisUser.TimeBank) > General.MaxDepositEver) AND (General.MaxDepositEver <> 0) THEN
      Print('^7Your account deposit limit is '+IntToStr(General.MaxDepositEver)+' minutes!')
    ELSE
    BEGIN
      Inc(ThisUser.TimeBankAdd,Deposit);
      Inc(ThisUser.TimeBank,Deposit);
      Dec(ThisUser.TLToday,Deposit);
      SysOpLog('Timebank: Deposited '+IntToStr(Deposit)+' minutes.');
    END;
  END;
END;

PROCEDURE WithDraw;
CONST
  Withdrawal: LongInt = 0;
BEGIN
  NL;
  IF (ChopTime <> 0) THEN
  BEGIN
    Print('You cannot withdraw any more time during this call.');
    PauseScr(FALSE);
    Exit;
  END;
  IF (ThisUser.TimeBankWith >= General.MaxWithdrawalPerDay) AND (General.MaxWithDrawalPerDay > 0) THEN
  BEGIN
    Print('You cannot withdraw any more time today.');
    PauseScr(FALSE);
    Exit;
  END;

  Print('^5Time left online  : ^3'+FormattedTime(NSL));
  Print('^5Time in time bank : ^3'+FormattedTime(ThisUser.TimeBank * 60));

  IF (General.MaxWithdrawalPerDay > 0) THEN
    Print('^5Max withdrawal/day: ^3'+FormattedTime(General.MaxWithdrawalPerDay * 60));

  IF (ThisUser.TimeBankWith > 0) THEN
    Print('^5Withdrawn today   : ^3'+FormattedTime(ThisUser.TimeBankWith * 60));

  InputLongIntWOC('%LFWithdraw how many minutes',WithDrawal,[DisplayValue,NumbersOnly],0,32767);
  IF (Withdrawal > 0) THEN
  BEGIN
    NL;
    IF (Withdrawal > ThisUser.TimeBank) THEN
      Print('^7You don''t have that much time left in your account!')
    ELSE IF ((Withdrawal + ThisUser.TimeBankWith) > General.MaxWithdrawalPerDay) AND (General.MaxWithdrawalPerDay > 0) THEN
      Print('^7You cannot withdraw that amount of time.')
    ELSE
    BEGIN
      Inc(ThisUser.TimeBankWith,Withdrawal);
      Dec(ThisUser.TimeBank,Withdrawal);
      Inc(ThisUser.TLToday,Withdrawal);
      IF (TimeWarn) AND (NSL > 180) THEN
        TimeWarn := FALSE;
      SysOpLog('Timebank: Withdrew '+IntToStr(Withdrawal)+' minutes.');
    END;
  END;
END;

END.
