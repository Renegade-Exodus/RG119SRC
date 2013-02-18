{$IFDEF WIN32}
{$I DEFINES.INC}
{$ENDIF}

{$A+,B-,D-,E-,F+,I-,L-,N-,O+,R-,S+,V-}

{ System Configuration - System Flagged Functions }

(*  1.  Add checking for deleted users or forwarded mail to option 1 *)

UNIT SysOp2E;

INTERFACE

PROCEDURE SystemFlaggedFunctions;

IMPLEMENTATION

USES
  Crt,
  Common;

PROCEDURE SystemFlaggedFunctions;
VAR
  Cmd,
  Cmd1: Char;
  LowNum,
  HiNum,
  TempInt: SmallInt;
BEGIN
  REPEAT
    WITH General DO
    BEGIN
      Abort := FALSE;
      Next := FALSE;
      Print('%CL^5System Flagged Functions:');
      NL;
      PrintACR('^1A. Handles allowed on system: ^5'+ShowOnOff(AllowAlias)+
             '^1  B. Phone number in logon     : ^5'+ShowOnOff(PhonePW));
      PrintACR('^1C. Local security protection: ^5'+ShowOnOff(LocalSec)+
             '^1  D. Use EMS for overlay file  : ^5'+ShowOnOff(UseEMS));
      PrintACR('^1E. Global activity trapping : ^5'+ShowOnOff(GlobalTrap)+
             '^1  F. Auto chat buffer open     : ^5'+ShowOnOff(AutoChatOpen));
      PrintACR('^1G. AutoMessage in logon     : ^5'+ShowOnOff(AutoMInLogon)+
             '^1  H. Bulletins in logon        : ^5'+ShowOnOff(BullInLogon));
      PrintACR('^1I. User info in logon       : ^5'+ShowOnOff(YourInfoInLogon)+
             '^1  J. Strip color off SysOp Log : ^5'+ShowOnOff(StripCLog));
      PrintACR('^1K. Offhook in local logon   : ^5'+ShowOnOff(OffHookLocalLogon)+
             '^1  L. Trap Teleconferencing     : ^5'+ShowOnOff(TrapTeleConf));
      PrintACR('^1M. Compress file/msg numbers: ^5'+ShowOnOff(CompressBases)+
             ' ^1 N. Use BIOS for video output : ^5'+ShowOnOff(UseBIOS));
      PrintACR('^1O. Use IEMSI handshakes     : ^5'+ShowOnOff(UseIEMSI)+
             '^1  P. Refuse new users          : ^5'+ShowOnOff(ClosedSystem));
      PrintACR('^1R. Swap shell function      : ^5'+ShowOnOff(SwapShell)+
             '^1  S. Use shuttle logon         : ^5'+ShowOnOff(ShuttleLog));
      PrintACR('^1T. Chat call paging         : ^5'+ShowOnOff(ChatCall)+
             '^1  U. Time limits are per call  : ^5'+ShowOnOff(PerCall));
      PrintACR('^1V. SysOp Password checking  : ^5'+ShowOnOff(SysOpPWord)+
             '^1  W. Random quote in logon     : ^5'+ShowOnOff(LogonQuote));
      PrintACR('^1X. User add quote in logon  : ^5'+ShowOnOff(UserAddQuote)+
             '^1  Y. Use message area lightbar : ^5'+ShowOnOff(UseMsgAreaLightBar));
      PrintACR('^1Z. Use file area lightbar   : ^5'+ShowOnOff(UseFileAreaLightBar));
      PrintACR('');
      PrintACR('^11. New user message sent to : ^5'+AOnOff((NewApp = -1),'Off',PadLeftInt(NewApp,5)));
      PrintACR('^12. Mins before TimeOut bell : ^5'+AOnOff((TimeOutBell = -1),'Off',PadLeftInt(TimeOutBell,3)));
      PrintACR('^13. Mins before TimeOut      : ^5'+AOnOff((TimeOut = -1),'Off',PadLeftInt(TimeOut,3)));
      Prt('%LFEnter selection [^5A^4-^5P^4,^5R^4-^5Z^4,^51^4-^53^4,^5Q^4=^5Quit^4]: ');
      OneK(Cmd,'QABCDEFGHIJKLMNOPRSTUVWXYZ123'^M,TRUE,TRUE);
      CASE Cmd OF
        'A' : AllowAlias := NOT AllowAlias;
        'B' : BEGIN
                PhonePW := NOT PhonePW;
                IF (PhonePW) THEN
                  NewUserToggles[7] := 8
                ELSE
                  NewUserToggles[7] := 0;
              END;
        'C' : LocalSec := NOT LocalSec;
        'D' : BEGIN
                UseEMS := NOT UseEMS;
                IF (UseEMS) THEN
                  OvrUseEMS := TRUE
                ELSE
                  OvrUseEMS := FALSE;
              END;
        'E' : GlobalTrap := NOT GlobalTrap;
        'F' : AutoChatOpen := NOT AutoChatOpen;
        'G' : AutoMInLogon := NOT AutoMInLogon;
        'H' : BullInLogon := NOT BullInLogon;
        'I' : YourInfoInLogon := NOT YourInfoInLogon;
        'J' : StripCLog := NOT StripCLog;
        'K' : OffHookLocalLogon := NOT OffHookLocalLogon;
        'L' : TrapTeleConf := NOT TrapTeleConf;
        'M' : BEGIN
                CompressBases := NOT CompressBases;
                IF (CompressBases) THEN
                  Print('%LFCompressing file/message areas ...')
                ELSE
                  Print('%LFDe-compressing file/message areas ...');
                NewCompTables;
              END;
        'N' : BEGIN
                UseBIOS := NOT UseBIOS;
                DirectVideo := NOT UseBIOS;
              END;
        'O' : UseIEMSI := NOT UseIEMSI;
        'P' : ClosedSystem := NOT ClosedSystem;
        'R' : SwapShell := NOT SwapShell;
        'S' : ShuttleLog := NOT ShuttleLog;
        'T' : ChatCall := NOT ChatCall;
        'U' : PerCall := NOT PerCall;
        'V' : SysOpPWord := NOT SysOpPWord;
        'W' : LogonQuote := NOT LogonQuote;
        'X' : UserAddQuote := NOT UserAddQuote;
        'Y' : UseMsgAreaLightBar := NOT UseMsgAreaLightBar;
        'Z' : UseFileAreaLightBar := NOT UseFileAreaLightBar;
        '1'..'3' :
              BEGIN
                Prt('%LFSelect option [^5E^4=^5Enable^4,^5D^4=^5Disable^4,^5<CR>^4=^5Quit^4]: ');
                OneK(Cmd1,^M'ED',TRUE,TRUE);
                IF (Cmd1 IN ['E','D']) THEN
                BEGIN
                  CASE Cmd1 OF
                    'E' : BEGIN
                            CASE Cmd OF
                              '1' : BEGIN
                                      LowNum := 1;
                                      HiNum := (MaxUsers - 1);
                                      TempInt := NewApp;
                                    END;
                              '2' : BEGIN
                                      LowNum := 1;
                                      HiNum := 20;
                                      TempInt := TimeOutBell;
                                    END;
                              '3' : BEGIN
                                      LowNum := 1;
                                      HiNum := 20;
                                      TempInt := TimeOut;
                                    END;
                            END;
                            InputIntegerWOC('%LFEnter value for this function',TempInt,[NumbersOnly],LowNum,HiNum);
                          END;
                    'D' : TempInt := -1;
                  END;
                  CASE Cmd OF
                    '1' : NewApp := TempInt;
                    '2' : TimeOutBell := TempInt;
                    '3' : TimeOut := TempInt;
                  END;
                  Cmd := #0;
                END;
          END;
      END;
    END;
  UNTIL (Cmd = 'Q') OR (HangUp);
END;

END.
