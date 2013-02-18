{$IFDEF WIN32}
{$I DEFINES.INC}
{$ENDIF}

{$A+,B-,D+,E-,L+,I-,L+,N-,O+,R-,S+,V-}

UNIT SysOp2B;

INTERFACE

PROCEDURE ModemConfiguration;

IMPLEMENTATION

USES
  Common;

PROCEDURE ModemConfiguration;
VAR
  LineFile: FILE OF LineRec;
  Cmd: Char;
  TempB: Byte;
  Changed: Boolean;

  PROCEDURE ToggleMFlag(MFlagT: ModemFlagType; VAR MFlags: MFlagSet);
  BEGIN
    IF (MFlagT IN MFlags) THEN
      Exclude(MFlags,MFlagT)
    ELSE
      Include(MFlags,MFlagT);
  END;

  PROCEDURE ToggleMFlags(C: Char; VAR MFlags: MFlagSet; VAR Changed: Boolean);
  VAR
    SaveMFlags: MFlagSet;
  BEGIN
    SaveMFlags := MFlags;
    CASE C OF
      '7' : ToggleMFlag(LockedPort,MFlags);
      '8' : ToggleMFlag(XONXOFF,MFlags);
      '9' : ToggleMFlag(CTSRTS,MFlags);
    END;
    IF (MFlags <> SaveMFlags) THEN
      Changed := TRUE;
  END;

  PROCEDURE NewModemString(CONST DisplayStr: AStr; VAR InputStr: AStr; Len: Byte);
  VAR
    Changed: Boolean;
  BEGIN
    Print('%LF^1Current modem '+DisplayStr+' string: "^5'+InputStr+'^1"');
    Print('%LFUse: "|" for a carriage return');
    Print('     "~" for a half-second delay');
    Print('     "^" to toggle DTR off for 1/4 second');
    InputWN1('%LF^1Enter new modem '+DisplayStr+' string:%LF^4: ',InputStr,Len,[InterActiveEdit],Changed);
  END;

  FUNCTION WhichBaud(B: Byte): AStr;
  BEGIN
    CASE B OF
      1 : WhichBaud := 'CONNECT 300';
      2 : WhichBaud := 'CONNECT 600';
      3 : WhichBaud := 'CONNECT 1200';
      4 : WhichBaud := 'CONNECT 2400';
      5 : WhichBaud := 'CONNECT 4800';
      6 : WhichBaud := 'CONNECT 7200';
      7 : WhichBaud := 'CONNECT 9600';
      8 : WhichBaud := 'CONNECT 12000';
      9 : WhichBaud := 'CONNECT 14400';
     10 : WhichBaud := 'CONNECT 16800';
     11 : WhichBaud := 'CONNECT 19200';
     12 : WhichBaud := 'CONNECT 21600';
     13 : WhichBaud := 'CONNECT 24000';
     14 : WhichBaud := 'CONNECT 26400';
     15 : WhichBaud := 'CONNECT 28800';
     16 : WhichBaud := 'CONNECT 31200';
     17 : WhichBaud := 'CONNECT 33600';
     18 : WhichBaud := 'CONNECT 38400';
     19 : WhichBaud := 'CONNECT 57600';
     20 : WhichBaud := 'CONNECT 115200';
    END;
 END;

BEGIN
  Assign(LineFile,General.DataPath+'NODE'+IntToStr(ThisNode)+'.DAT');
  Reset(LineFile);
  Read(LineFile,Liner);
  REPEAT
    WITH Liner DO
    BEGIN
      Abort := FALSE;
      Next := FALSE;
      Print('%CL^5Modem/Node Configuration:');
      NL;
      PrintACR('^11. Maximum baud rate: ^5'+PadLeftInt(InitBaud,20)+
               '^12. Port number      : ^5'+IntToStr(ComPort));
      PrintACR('^13. Modem init       : ^5'+PadLeftStr(Init,20)+
               '^14. Modem answer     : ^5'+Answer);
      PrintACR('^15. Modem HangUp     : ^5'+PadLeftStr(HangUp,20)+
               '^16. Modem offhook    : ^5'+Offhook);
      PrintACR('^17. COM port locking : ^5'+PadLeftStr(ShowOnOff(LockedPort IN MFlags),20)+
               '^18. XON/XOFF flow    : ^5'+ShowOnOff(XONXOFF IN MFlags));
      PrintACR('^19. CTS/RTS flow     : ^5'+PadLeftStr(ShowOnOff(CTSRTS IN MFlags),20)+
               '^1A. ACS for this node: ^5'+LogonACS);
      PrintACR('^1B. Drop file path   : ^5'+PadLeftStr(DoorPath,20)+
               '^1C. Answer on ring   : ^5'+IntToStr(AnswerOnRing));
      PrintACR('^1D. TeleConf Normal  : ^5'+PadLeftStr(TeleConfNormal,20)+
               '^1E. MultiRing only   : ^5'+ShowOnOff(MultiRing));
      PrintACR('^1F. TeleConf Anon    : ^5'+PadLeftStr(TeleConfAnon,20));
      PrintACR('^1G. TeleConf Global  : ^5'+TeleConfGlobal);
      PrintACR('^1H. TeleConf Private : ^5'+TeleConfPrivate);
      PrintACR('^1I. IRQ string       : ^5'+IRQ);
      PrintACR('^1J. Address string   : ^5'+Address);
      PrintACR('^1R. Modem result codes');
      Prt('%LFEnter selection [^51^4-^59^4,^5A^4-^5J^4,^5R^4,^5Q^4=^5Quit^4]: ');
      OneK(Cmd,'Q123456789ABCDEFGHIJR'^M,TRUE,TRUE);
      CASE Cmd OF
        '1' : IF (InCom) THEN
              BEGIN
                Print('%LF^7This can only be changed locally.');
                PauseScr(FALSE);
              END
              ELSE
              BEGIN
                Print('%LF^5Modem maximum baud rates:^1');
                Print('%LF^1(^3A^1). 2400');
                Print('^1(^3B^1). 9600');
                Print('^1(^3C^1). 19200');
                Print('^1(^3D^1). 38400');
                Print('^1(^3E^1). 57600');
                Print('^1(^3F^1). 115200');
                LOneK('%LFModem speed? [^5A^4-^5F^4,^5<CR>^4=^5Quit^4]: ',Cmd,^M'ABCDEF',TRUE,TRUE);
                CASE Cmd OF
                  'A' : InitBaud := 2400;
                  'B' : InitBaud := 9600;
                  'C' : InitBaud := 19200;
                  'D' : InitBaud := 38400;
                  'E' : InitBaud := 57600;
                  'F' : InitBaud := 115200;
                END;
                Cmd := #0;
              END;
        '2' : IF (InCom) THEN
              BEGIN
                Print('%LF^7This can only be changed locally.');
                PauseScr(FALSE);
              END
              ELSE
              BEGIN
                TempB := ComPort;
                InputByteWC('%LFCom port',TempB,[DisplayValue,NumbersOnly],0,64,Changed);
                IF (Changed) THEN
                  IF PYNQ('%LFAre you sure this is what you want? ',0,FALSE) THEN
                  BEGIN
                    Com_DeInstall;
                    ComPort := TempB;
                    Com_Install;
                  END;
                IF (NOT LocalIOOnly) AND (ComPort = 0) THEN
                  LocalIOOnly := TRUE;
              END;
        '3' : NewModemString('init',Init,(SizeOf(Init) - 1));
        '4' : NewModemString('answer',Answer,(SizeOf(Answer) - 1));
        '5' : NewModemString('hangup',HangUp,(SizeOf(HangUp) - 1));
        '6' : NewModemString('offhook',Offhook,(SizeOf(Offhook) - 1));
        '7' : ToggleMFlags('7',MFlags,Changed);
        '8' : ToggleMFlags('8',MFlags,Changed);
        '9' : ToggleMFlags('9',MFlags,Changed);
        'A' : InputWN1('%LFNew ACS: ',LogonACS,(SizeOf(LogonACS) - 1),[InterActiveEdit],Changed);
        'B' : InputPath('%LF^1Enter path to write door interface files to (^5End with a ^1"^5\^1"):%LF^4: ',
                        DoorPath,TRUE,FALSE,Changed);
        'C' : InputByteWOC('%LFAnswer after ring number',AnswerOnRing,[DisplayValue,NumbersOnly],0,255);
        'E' : MultiRing := NOT MultiRing;
        'D' : InputWN1('%LF^1Enter new teleconference string:%LF^4: ',TeleConfNormal,(SizeOf(TeleConfNormal) - 1),
                       [ColorsAllowed,InterActiveEdit],Changed);
        'F' : InputWN1('%LF^1Enter new teleconference string:%LF^4: ',TeleConfAnon,(SizeOf(TeleConfAnon) - 1),
                       [ColorsAllowed,InterActiveEdit],Changed);
        'G' : InputWN1('%LF^1Enter new teleconference string:%LF^4: ',TeleConfGlobal,(SizeOf(TeleConfGlobal) - 1),
                       [ColorsAllowed,InterActiveEdit],Changed);
        'H' : InputWN1('%LF^1Enter new teleconference string:%LF^4: ',TeleConfPrivate,(SizeOf(TeleConfPrivate) - 1),
                                [ColorsAllowed,InterActiveEdit],Changed);
        'I' : InputWN1('%LFIRQ for %E MCI code: ',IRQ,(SizeOf(IRQ) - 1),[InterActiveEdit],Changed);
        'J' : InputWN1('%LFAddress for %C MCI code: ',Address,(SizeOf(Address) - 1),[InterActiveEdit],Changed);
        'R' : BEGIN
                REPEAT
                  Abort := FALSE;
                  Next := FALSE;
                  Print('%CL^5Modem configuration - Result Codes');
                  NL;
                  PrintACR('^1A. NO CARRIER    : ^5'+PadLeftStr(NOCARRIER,21)+'^1B. RELIABLE      : ^5'+RELIABLE);
                  PrintACR('^1C. OK            : ^5'+PadLeftStr(OK,21)+'^1D. RING          : ^5'+RING);
                  PrintACR('^1E. CALLER ID     : ^5'+PadLeftStr(CALLERID,21)+
                           '^1F. ID/User note  : ^5'+ShowOnOff(UseCallerID));
                  FOR TempB := 1 TO MaxResultCodes DO
                    IF (NOT Odd(TempB)) THEN
                      Print('^1'+Chr(TempB + 70)+'. '+PadLeftStr(WhichBaud(TempB),14)+': ^5'+Connect[TempB])
                    ELSE
                      Prompt(PadLeftStr('^1'+Chr(TempB + 70)+'. '+PadLeftStr(WhichBaud(TempB),14)+': ^5'+Connect[TempB],40));
                  LOneK('%LFEnter selection [^5A^4-^5Z^4,^5<CR>^4=^5Quit^4]: ',Cmd,^M'ABCDEFGHIJKLMNOPQRSTUVWXYZ',TRUE,TRUE);
                  CASE Cmd OF
                    'A' : InputWN1('%LFEnter NO CARRIER string: ',NOCARRIER,(SizeOf(NOCARRIER) - 1),
                                   [InterActiveEdit,UpperOnly],Changed);
                    'B' : InputWN1('%LFEnter RELIABLE string: ',RELIABLE,(SizeOf(RELIABLE) - 1),
                                   [InterActiveEdit,UpperOnly],Changed);
                    'C' : InputWN1('%LFEnter OK string: ',OK,(SizeOf(OK) - 1),[InterActiveEdit,UpperOnly],Changed);
                    'D' : InputWN1('%LFEnter RING string: ',RING,(SizeOf(RING) - 1),[InterActiveEdit,UpperOnly],Changed);
                    'E' : InputWN1('%LFEnter Caller ID string: ',CALLERID,(SizeOf(CALLERID) - 1),
                                   [InterActiveEdit,UpperOnly],Changed);
                    'F' : UseCallerID := NOT UseCallerID;
                    'G'..'Z' :
                          BEGIN
                            TempB := (Ord(Cmd) - 70);
                            IF (TempB IN [1..MaxResultCodes]) THEN
                              InputWN1('%LFEnter '+WhichBaud(TempB)+' string: ',Connect[TempB],(SizeOf(Connect[1]) - 1),
                                       [InterActiveEdit,UpperOnly],Changed);
                          END;
                  END;
                UNTIL (Cmd = ^M);
                Cmd := #0;
              END;
      END;
    END;
  UNTIL (Cmd = 'Q') OR (HangUp);
  Seek(LineFile,0);
  Write(LineFile,Liner);
  Close(LineFile);
  LastError := IOResult;
END;

END.
