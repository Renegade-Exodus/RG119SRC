{$IFDEF WIN32}
{$I DEFINES.INC}
{$ENDIF}

{$A+,B-,D-,E-,F+,I-,L-,N-,O+,R-,S+,V-}

UNIT SysOp2F;

INTERFACE

PROCEDURE FileAreaConfiguration;

IMPLEMENTATION

USES
  Common;

PROCEDURE FileAreaConfiguration;
VAR
  Cmd: Char;
BEGIN
  REPEAT
    WITH General DO
    BEGIN
      Abort := FALSE;
      Next := FALSE;
      Print('%CL^5File Area Configuration:');
      NL;
      PrintACR('^1A. Upload/download ratio system    : ^5'+ShowOnOff(ULDLRatio));
      PrintACR('^1B. File point system               : ^5'+ShowOnOff(FileCreditRatio));
      PrintACR('^1C. Daily download limits           : ^5'+ShowOnOff(DailyLimits));
      PrintACR('^1D. Test and convert uploads        : ^5'+ShowOnOff(TestUploads));
      PrintACR('^1E. File point rewarding system     : ^5'+ShowOnOff(RewardSystem));
      PrintACR('^1F. Search for/Use FILE_ID.DIZ      : ^5'+ShowOnOff(FileDiz));
      PrintACR('^1G. Recompress like archives        : ^5'+ShowOnOff(Recompress));
      PrintACR('^1H. Credit reward compensation ratio: ^5'+IntToStr(RewardRatio)+'%');
      PrintACR('^1I. File point compensation ratio   : ^5'+IntToStr(FileCreditComp)+' to 1');
      PrintACR('^1J. Area file size per 1 file point : ^5'+IntToStr(FileCreditCompBaseSize)+'k');
      PrintACR('^1K. Upload time refund percent      : ^5'+IntToStr(ULRefund)+'%');
      PrintACR('^1L. "To-SysOp" file area            : ^5'+AOnOff(ToSysOpDir = 0,'*None*',IntToStr(ToSysOpDir)));
      PrintACR('^1M. Auto-validate ALL files ULed?   : ^5'+ShowYesNo(ValidateAllFiles));
      PrintACR('^1N. Max k-bytes allowed in temp dir : ^5'+IntToStr(MaxInTemp));
      PrintACR('^1O. Min k-bytes to save for resume  : ^5'+IntToStr(MinResume));
      PrintACR('^1P. Max batch download files        : ^5'+IntToStr(MaxBatchDLFiles));
      PrintACR('^1R. Max batch upload files          : ^5'+IntToStr(MaxBatchUlFiles));
      PrintACR('^1S. UL duplicate file search        : ^5'+ShowOnOff(SearchDup));
      PrintACR('^1T. Force batch download at login   : ^5'+ShowOnOff(ForceBatchDL));
      PrintACR('^1U. Force batch upload at login     : ^5'+ShowOnOff(ForceBatchUL));
      NL;
      Prt('Enter selection [^5A^4-^5P^4,^5R^4-^5U^4,^5Q^4=^5Quit^4]: ');
      OneK(Cmd,'QABCDEFGHIJKLMNOPRSTU'^M,TRUE,TRUE);
      CASE Cmd OF
        'A' : ULDLRatio := NOT ULDLRatio;
        'B' : FileCreditRatio := NOT FileCreditRatio;
        'C' : DailyLimits := NOT DailyLimits;
        'D' : TestUploads := NOT TestUploads;
        'E' : RewardSystem := NOT RewardSystem;
        'F' : FileDiz := NOT FileDiz;
        'G' : Recompress := NOT Recompress;
        'H' : InputIntegerWOC('%LFNew percentage of file credits to reward',RewardRatio,[DisplayValue,NumbersOnly],0,100);
        'I' : InputByteWOC('%LFNew file point compensation ratio',FileCreditComp,[DisplayValue,Numbersonly],0,100);
        'J' : InputByteWOC('%LFNew area file size per 1 file Point',FileCreditCompBaseSize,[DisplayValue,NumbersOnly],0,255);
        'K' : InputByteWOC('%LFNew upload time refund percent',ULRefund,[DisplayValue,NumbersOnly],0,100);
        'L' : InputIntegerWOC('%LFNew "To-SysOp" file area (0=None)',ToSysOpDir,[DisplayValue,NumbersOnly],0,NumFileAreas);
        'M' : ValidateAllFiles := NOT ValidateAllFiles;
        'N' : InputLongIntWOC('%LFNew max k-bytes',MaxInTemp,[DisplayValue,NumbersOnly],0,2097151);
        'O' : InputLongIntWOC('%LFNew min resume k-bytes',MinResume,[DisplayValue,NumbersOnly],0,2097151);
        'P' : InputByteWOC('%LFNew max batch download files',MaxBatchDLFiles,[DisplayValue,NumbersOnly],1,255);
        'R' : InputByteWOC('%LFNew max batch upload files',MaxBatchULFiles,[DisplayValue,NumbersOnly],1,255);
        'S' : SearchDup := NOT SearchDup;
        'T' : ForceBatchDL := NOT ForceBatchDL;
        'U' : ForceBatchUL := NOT ForceBatchUL;
      END;
    END;
  UNTIL (Cmd = 'Q') OR (HangUp);
END;

END.
