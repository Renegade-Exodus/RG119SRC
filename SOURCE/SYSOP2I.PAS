{$IFDEF WIN32}
{$I DEFINES.INC}
{$ENDIF}

{$A+,B-,D-,E-,F+,I-,L-,N-,O+,R-,S+,V-}

UNIT SysOp2I;

INTERFACE

PROCEDURE OfflineMailConfiguration;

IMPLEMENTATION

USES
  Common;

PROCEDURE OfflineMailConfiguration;
VAR
  Cmd: CHAR;
  Changed: Boolean;
BEGIN
  REPEAT
    WITH General DO
    BEGIN
      Abort := FALSE;
      Next := FALSE;
      Print('%CL^5Offline Mail Configuration:');
      NL;
      PrintACR('^1A. QWK/REP Packet name : ^5'+PacketName);
      PrintACR('^1B. Welcome screen name : ^5'+QWKWelcome);
      PrintACR('^1C. News file name      : ^5'+QWKNews);
      PrintACR('^1D. Goodbye file name   : ^5'+QWKGoodbye);
      PrintACR('^1E. Local QWK/REP path  : ^5'+QWKLocalPath);
      PrintACR('^1F. Ignore time for DL  : ^5'+ShowOnOff(QWKTimeIgnore));
      PrintACR('^1G. Max total messages  : ^5'+IntToStr(MaxQWKTotal));
      PrintACR('^1H. Max msgs per base   : ^5'+IntToStr(MaxQWKBase));
      PrintACR('^1I. ACS for Network .REP: ^5'+QWKNetworkACS);
      Prt('%LFEnter selection [^5A^4-^5I^4,^5Q^4=^5Quit^4]: ');
      OneK(Cmd,'QABCDEFGHI'^M,TRUE,TRUE);
      CASE Cmd OF
        'A' : InputWN1('%LFQWK Packet name: ',PacketName,(SizeOf(PacketName) - 1),[InterActiveEdit],Changed);
        'B' : InputWN1('%LF^1Welcome screen file d:\path\name (^5Do not enter ^1"^5.EXT^1"):%LF^4: ',
                       QWKWelcome,(SizeOf(QWKWelcome) - 1),
                       [UpperOnly,InterActiveEdit],Changed);
        'C' : InputWN1('%LF^1News file d:\path\name (^5Do not enter ^1"^5.EXT^1"):%LF^4: ',QWKNews,(SizeOf(QWKNews) - 1),
                       [UpperOnly,InterActiveEdit],Changed);
        'D' : InputWN1('%LF^1Goodbye file d:\path\name (^5Do not enter ^1"^5.EXT^1"):%LF^4: ',
                       QWKGoodbye,(SizeOf(QWKGoodBye) - 1),
                       [UpperOnly,InterActiveEdit],Changed);
        'E' : InputPath('%LF^1Enter local QWK reader path (^5End with a ^1"^5\^1"):%LF^4:',QWKLocalPath,TRUE,FALSE,Changed);
        'F' : QWKTimeIgnore := NOT QWKTimeIgnore;
        'G' : InputWordWOC('%LFMaximum total messages in a QWK packet',MaxQWKTotal,[DisplayValue,NumbersOnly],0,65535);
        'H' : InputWordWOC('%LFMaximum messages per base in a packet',MaxQWKBase,[DisplayValue,NumbersOnly],0,65535);
        'I' : InputWN1('%LFNew ACS: ',QWKNetworkACS,(SizeOf(QWKNetworkACS) - 1),[InterActiveEdit],Changed);
      END;
    END;
  UNTIL (Cmd = 'Q') OR (HangUp);
END;

END.
