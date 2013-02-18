{$IFDEF WIN32}
{$I DEFINES.INC}
{$ENDIF}

{$A+,B-,D-,E-,F+,I-,L-,N-,O+,R-,S+,V-}

UNIT SysOp2L;

INTERFACE

PROCEDURE CreditConfiguration;

IMPLEMENTATION

USES
  Common;

PROCEDURE CreditConfiguration;
VAR
  Cmd: Char;
BEGIN
  REPEAT
    WITH General DO
    BEGIN
      Abort := FALSE;
      Next := FALSE;
      CLS;
      Print('^5Credit System Configuration:');
      NL;
      PrintACR('^1A. Charge/minute       : ^5'+IntToStr(CreditMinute));
      PrintACR('^1B. Message post        : ^5'+IntToStr(CreditPost));
      PrintACR('^1C. Email sent          : ^5'+IntToStr(CreditEmail));
      PrintACR('^1D. Free time at logon  : ^5'+IntToStr(CreditFreeTime));
      PrintACR('^1E. Internet mail cost  : ^5'+IntToStr(CreditInternetMail));
      Prt('%LFEnter selection [^5A^4-^5E^4,^5Q^4=^5Quit^4]: ');
      OneK(Cmd,'QABCDE'^M,TRUE,TRUE);
      CASE Cmd OF
        'A' : InputIntegerWOC('%LFCredits charged per minute online',CreditMinute,[NumbersOnly],0,32767);
        'B' : InputIntegerWOC('%LFCredits charged per message post',CreditPost,[NumbersOnly],0,32767);
        'C' : InputIntegerWOC('%LFCredits charged per email sent',CreditEmail,[Numbersonly],0,32767);
        'D' : InputIntegerWOC('%LFMinutes to give users w/o credits at logon',CreditFreeTime,[NumbersOnly],0,32767);
        'E' : InputIntegerWOC('%LFCost for Internet mail messages',CreditInternetMail,[NumbersOnly],0,32767);
      END;
    END;
  UNTIL (Cmd = 'Q') OR (HangUp);
END;

END.
