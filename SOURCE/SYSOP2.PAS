{$IFDEF WIN32}
{$I DEFINES.INC}
{$ENDIF}

{$A+,B-,D-,E-,F+,I-,L-,N-,O+,R-,S+,V-}

UNIT SysOp2;

INTERFACE

PROCEDURE SystemConfigurationEditor;

IMPLEMENTATION

USES
  Common,
  SysOp2A,
  SysOp2B,
  SysOp2C,
  SysOp2D,
  SysOp2E,
  SysOp2F,
  SysOp2G,
  SysOp2H,
  SysOp2I,
  SysOp2J,
  SysOp2K,
  SysOp2L,
  SysOp2M,
  SysOp2O,
  Maint;

   {
   1. RGSysCfgStr(0,FALSE)

      %CL^5System Configuration:^1

      ^1A. Main BBS Configuration                 B. Modem/Node Configuration
      ^1C. System ACS Settings                    D. System Variables
      ^1E. System Toggles                         F. File System Configuration
      ^1G. Subscription/Validation System         H. Network Configuration
      ^1I. Offline Mail Configuration             J. Color Configuration
      ^1K. Archive Configuration                  L. Credit System Configuration
      ^1M. New User Log-In Toggles

      ^11. Time allowed per %CD                  2. Max calls per day
      ^13. UL/DL # files ratio                    4. UL/DL K-bytes ratio
      ^15. Post/Call ratio                        6. Max downloads per day
      ^17. Max download kbytes per day            8. Update System Averages

      Enter selection [^5A^4-^5M^4,^51^4-^58^4,^5Q^4=^5Quit^4]: @

   }

PROCEDURE SystemConfigurationEditor;
VAR
  Cmd: Char;
BEGIN
  REPEAT
    SaveGeneral(TRUE);
    WITH General DO
    BEGIN
      Abort := FALSE;
      Next := FALSE;
      RGSysCfgStr(0,FALSE);
      OneK(Cmd,'QABCDEFGHIJKLM12345678'^M,TRUE,TRUE);
      CASE Cmd OF
        'A' : MainBBSConfiguration;
        'B' : ModemConfiguration;
        'C' : SystemACSSettings;
        'D' : SystemGeneralVariables;
        'E' : SystemFlaggedFunctions;
        'F' : FileAreaConfiguration;
        'G' : ValidationEditor;
        'H' : NetworkConfiguration;
        'I' : OffLineMailConfiguration;
        'J' : ColorConfiguration;
        'K' : ArchiveConfiguration;
        'L' : CreditConfiguration;
        'M' : NewUserTogglesConfiguration;
        '1' : GetSecRange(1,TimeAllow);
        '2' : GetSecRange(2,CallAllow);
        '3' : GetSecRange(3,DLRatio);
        '4' : GetSecRange(4,DLKratio);
        '5' : GetSecRange(5,PostRatio);
        '6' : GetSecRange(6,DLOneDay);
        '7' : GetSecRange(7,DLKOneDay);
        '8' : UpdateGeneral;
      END;
    END;
    SaveGeneral(FALSE);
  UNTIL (Cmd = 'Q') OR (HangUp);
END;

END.
