{$IFDEF WIN32}
{$I DEFINES.INC}
{$ENDIF}

{$A+,B-,D-,E-,F+,I-,L-,N-,O+,R-,S+,V-}

UNIT SysOp2C;

INTERFACE

PROCEDURE SystemACSSettings;

IMPLEMENTATION

USES
  Common;

PROCEDURE SystemACSSettings;
VAR
  TempACS: ACString;
  Cmd: Char;
  Changed: Boolean;
BEGIN
  REPEAT
    WITH General DO
    BEGIN
      Abort := FALSE;
      Next := FALSE;
      MCIAllowed := FALSE;
      CLS;
      Print('^5System ACS Settings:');
      NL;
      PrintACR('^1A. Full SysOp       : ^5'+PadLeftStr(SOp,18)+
               '^1B. Full Co-SysOp    : ^5'+CSOp);
      PrintACR('^1C. Msg Area SysOp   : ^5'+PadLeftStr(MSOp,18)+
               '^1D. File Area SysOp  : ^5'+FSOp);
      PrintACR('^1E. Change a vote    : ^5'+PadLeftStr(ChangeVote,18)+
               '^1F. Add voting choice: ^5'+AddChoice);
      PrintACR('^1G. Post public      : ^5'+PadLeftStr(NormPubPost,18)+
               '^1H. Send e-mail      : ^5'+NormPrivPost);
      PrintACR('^1I. See anon pub post: ^5'+PadLeftStr(AnonPubRead,18)+
               '^1J. See anon E-mail  : ^5'+AnonPrivRead);
      PrintACR('^1K. Global Anon post : ^5'+PadLeftStr(AnonPubPost,18)+
               '^1L. E-mail anon      : ^5'+AnonPrivPost);
      PrintACR('^1M. See unval. files : ^5'+PadLeftStr(SeeUnVal,18)+
               '^1N. DL unval. files  : ^5'+DLUnVal);
      PrintACR('^1O. No UL/DL ratio   : ^5'+PadLeftStr(NoDLRatio,18)+
               '^1P. No PostCall ratio: ^5'+NoPostRatio);
      PrintACR('^1R. No DL credits chk: ^5'+PadLeftStr(NoFileCredits,18)+
               '^1S. ULs auto-credited: ^5'+ULValReq);
      PrintACR('^1T. MCI in TeleConf  : ^5'+PadLeftStr(TeleConfMCI,18)+
               '^1U. Chat at any hour : ^5'+OverRideChat);
      PrintACR('^1V. Send Netmail     : ^5'+PadLeftStr(NetMailACS,18)+
               '^1W. "Invisible" Mode : ^5'+Invisible);
      PrintACR('^1X. Mail file attach : ^5'+PadLeftStr(FileAttachACS,18)+
               '^1Y. SysOp PW at logon: ^5'+SPW);
      PrintACR('^1Z. Last On Add      : ^5'+PadLeftStr(LastOnDatACS,18));
      MCIAllowed := TRUE;
      NL;
      Prt('Enter selection [^5A^4-^5P^4,^5R^4-^5Z^4,^5Q^4=^5Quit^4]: ');
      OneK(Cmd,'QABCDEFGHIJKLMNOPRSTUVWXYZ'^M,TRUE,TRUE);
      IF (Cmd IN ['A'..'P','R'..'Z']) THEN
      BEGIN
        CASE Cmd OF
          'A' : TempACS := SOp;
          'B' : TempACS := CSOp;
          'C' : TempACS := MSOp;
          'D' : TempACS := FSOp;
          'E' : TempACS := ChangeVote;
          'F' : TempACS := AddChoice;
          'G' : TempACS := NormPubPost;
          'H' : TempACS := NormPrivPost;
          'I' : TempACS := AnonPubRead;
          'J' : TempACS := AnonPrivRead;
          'K' : TempACS := AnonPubPost;
          'L' : TempACS := AnonPrivPost;
          'M' : TempACS := SeeUnVal;
          'N' : TempACS := DLUnVal;
          'O' : TempACS := NoDLRatio;
          'P' : TempACS := NoPostRatio;
          'R' : TempACS := NoFileCredits;
          'S' : TempACS := ULValReq;
          'T' : TempACS := TeleConfMCI;
          'U' : TempACS := OverRideChat;
          'V' : TempACS := NetMailACS;
          'W' : TempACS := Invisible;
          'X' : TempACS := FileAttachACS;
          'Y' : TempACS := SPW;
          'Z' : TempACS := LastOnDatACS;
        END;
        InputWN1('%LFNew ACS: ',TempACS,(SizeOf(ACString) - 1),[InterActiveEdit],Changed);
        CASE Cmd OF
          'A' : SOp := TempACS;
          'B' : CSOp := TempACS;
          'C' : MSOp := TempACS;
          'D' : FSOp := TempACS;
          'E' : ChangeVote := TempACS;
          'F' : AddChoice := TempACS;
          'G' : NormPubPost := TempACS;
          'H' : NormPrivPost := TempACS;
          'I' : AnonPubRead := TempACS;
          'J' : AnonPrivRead := TempACS;
          'K' : AnonPubPost := TempACS;
          'L' : AnonPrivPost := TempACS;
          'M' : SeeUnVal := TempACS;
          'N' : DLUnVal := TempACS;
          'O' : NoDLRatio := TempACS;
          'P' : NoPostRatio := TempACS;
          'R' : NoFileCredits := TempACS;
          'S' : ULValReq := TempACS;
          'T' : TeleConfMCI := TempACS;
          'U' : OverRideChat := TempACS;
          'V' : NetMailACS := TempACS;
          'W' : Invisible := TempACS;
          'X' : FileAttachACS := TempACS;
          'Y' : SPW := TempACS;
          'Z' : LastOnDatACS := TempACS;
        END;
      END;
    END;
  UNTIL (Cmd = 'Q') OR (HangUp);
END;

END.
