{$IFDEF WIN32}
{$I DEFINES.INC}
{$ENDIF}

{$A+,B-,D+,E-,F+,I-,L+,N-,O+,R-,S+,V-}

UNIT SysOp2H;

INTERFACE

PROCEDURE NetworkConfiguration;

IMPLEMENTATION

USES
  Common,
  NodeList;

PROCEDURE NetworkConfiguration;
VAR
  Cmd: Char;
  Counter: Byte;
  Changed: Boolean;
BEGIN
  REPEAT
    WITH General DO
    BEGIN
      Abort := FALSE;
      Next := FALSE;
      Print('%CL^5Network Configuration:');
      NL;
      PrintACR('^1A. Net addresses');
      PrintACR('^1B. Origin line     : ^5'+Origin);
      NL;
      PrintACR('^1C. Strip IFNA kludge lines : ^5'+ShowYesNo(SKludge)+
               '^1     1. Color of standard text : ^'+IntToStr(Text_Color)+IntToStr(Text_Color));
      PrintACR('^1D. Strip SEEN-BY lines     : ^5'+ShowYesNo(SSeenBy)+
               '^1     2. Color of quoted text   : ^'+IntToStr(Quote_Color)+IntToStr(Quote_Color));
      PrintACR('^1E. Strip origin lines      : ^5'+ShowYesNo(SOrigin)+
               '^1     3. Color of tear line     : ^'+IntToStr(Tear_Color)+IntToStr(Tear_Color));
      PrintACR('^1F. Add tear/origin line    : ^5'+ShowYesNo(AddTear)+
               '^1     4. Color of origin line   : ^'+IntToStr(Origin_Color)+IntToStr(Origin_Color));
      NL;
      PrintACR('^1G. Default Echomail path   : ^5'+DefEchoPath);
      PrintACR('^1H. Netmail path            : ^5'+NetMailPath);
      PrintACR('^1I. Netmail attributes      : ^5'+NetMail_Attr(NetAttribute));
      PrintACR('^1J. UUCP gate address       : ^5'+PadLeftStr('^5'+IntToStr(AKA[20].Zone)+':'+IntToStr(AKA[20].Net)+
                                                       '/'+IntToStr(AKA[20].Node)+'.'+IntToStr(AKA[20].Point),20));
      Prt('%LFEnter selection [^5A^4-^5J^4,^51^4-^54^4,^5Q^4=^5Quit^4]: ');
      OneK(Cmd,'QABCDEFGHIJ1234'^M,TRUE,TRUE);
      CASE Cmd OF
        'A' : BEGIN
                REPEAT
                  Abort := FALSE;
                  Next := FALSE;
                  Print('%CL^5Network Addresses:^1');
                  NL;
                  FOR Counter := 0 TO 19 DO
                  BEGIN
                    Prompt('^1'+Chr(Counter + 65)+'. Address #'+PadLeftInt(Counter,2)+' : '+
                    PadLeftStr('^5'+IntToStr(AKA[Counter].Zone)+
                        ':'+IntToStr(AKA[Counter].Net)+
                        '/'+IntToStr(AKA[Counter].Node)+
                        '.'+IntToStr(AKA[Counter].Point),20));
                    IF (Odd(Counter)) THEN
                      NL;
                  END;
                  LOneK('%LFEnter selection [^5A^4-^5T^4,^5<CR>^4=^5Quit^4]: ',Cmd,^M'ABCDEFGHIJKLMNOPQRST',TRUE,TRUE);
                  IF (Cmd IN ['A'..'T']) THEN
                    GetNewAddr('%LFEnter new network address (^5Z^4:^5N^4/^5N^4.^5P^4 format): ',30,
                                AKA[(Ord(Cmd) - 65)].Zone,
                                AKA[(Ord(Cmd) - 65)].Net,
                                AKA[(Ord(Cmd) - 65)].Node,
                                AKA[(Ord(Cmd) - 65)].Point);
                UNTIL (Cmd = ^M) OR (HangUp);
                Cmd := #0;
              END;
        'B' : InputWN1('%LF^1Enter new origin line:%LF^4: ',Origin,50,[],Changed);
        'C' : SKludge := NOT SKludge;
        'D' : SSeenBy := NOT SSeenBy;
        'E' : SOrigin := NOT SOrigin;
        'F' : AddTear := NOT AddTear;
        'G' : InputPath('%LF^1Enter new default echomail path (^5End with a ^1"^5\^1"):%LF^4:',DefEchoPath,TRUE,FALSE,Changed);
        'H' : InputPath('%LF^1Enter new netmail path (^5End with a ^1"^5\^1"):%LF^4:',NetMailPath,TRUE,FALSE,Changed);
        'I' : BEGIN

                REPEAT
                  Print('%LF^1Netmail attributes: ^5'+NetMail_Attr(NetAttribute)+'^1');
                  LOneK('%LFToggle attributes (CHIKLP) [?]Help [Q]uit: ',Cmd,'QPCKHIL?',TRUE,TRUE);
                  CASE Cmd OF
                    'C','H','I','K','L','P' :
                           ToggleNetAttrS(Cmd,NetAttribute);
                    '?' : BEGIN
                            NL;
                            LCmds(22,3,'Crash mail','Hold');
                            LCmds(22,3,'In-Transit','Kill-Sent');
                            LCmds(22,3,'Local','Private');
                          END;
                  END;

                UNTIL (Cmd = 'Q') OR (HangUp);

                Cmd := #0;
              END;
        'J' : GetNewAddr('%LFEnter new UUCP Gate Address (^5Z^4:^5N^4/^5N^4.^5P^4 format): ',30,
                         AKA[20].Zone,
                         AKA[20].Net,
                         AKA[20].Node,
                         AKA[20].Point);
        '1' : BEGIN
                Prompt('%LF^5Colors: ');
                ShowColors;
                InputByteWC('%LFNew standard text color',Text_Color,[DisplayValue,NumbersOnly],0,9,Changed);
              END;
        '2' : BEGIN
                Prompt('%LF^5Colors: ');
                ShowColors;
                InputByteWC('%LFNew quoted text color',Quote_Color,[DisplayValue,NumbersOnly],0,9,Changed);
              END;
        '3' : BEGIN
                Prompt('%LF^5Colors: ');
                ShowColors;
                InputByteWC('%LFNew tear line color',Tear_Color,[DisplayValue,NumbersOnly],0,9,Changed);
              END;
        '4' : BEGIN
                Prompt('%LF^5Colors: ');
                ShowColors;
                InputByteWC('%LFNew origin line color',Origin_Color,[DisplayValue,NumbersOnly],0,9,Changed);
              END;
      END;
    END;
  UNTIL (Cmd = 'Q') OR (HangUp);
END;

END.
