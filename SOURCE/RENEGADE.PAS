{$IFDEF WIN32}
{$I DEFINES.INC}
{$ENDIF}

{$IFDEF MSDOS}
{$M 35500,0,131072}
{$ENDIF}

{                             R E N E G A D E                                }
{                             ===============                                }

{$A+} { Align Data for faster execution }
{$B-} { Shortcut Boolean eval }
{$D+} { No Debug Info }
{$E-} { No Math-Co library }
{$F+} { Force Far Calls }
{$I-} { Disable I/O check }
{$L+} { Local Symbols, Ignored IF D-, don't need cause of D- }
{$N-} { No Math-Co use }
{$P+} { Allow OpenString }
{$O+} { Use Overlays? }
{$Q-} { No overflow check }
{$R-} { No range check }
{$S-} { Don't Check stack usage }
{$V-} { Variable string Length allowed }
{$X+} { Allow extended syntax }

PROGRAM Renegade;

USES
  OverLay,
{ OvrUMB,}
  Crt,
  Dos,
  Boot,
  Common,
  Common1,
  Events,
  File0,
  File7,
  File13,
  Logon,
  Mail0,
  Maint,
  Menus,
  Menus2,
  MsgPack,
  MyIO,
  NewUsers,
  OffLine,
  TimeFunc,
  WfCMenu;

{$O MsgPack   } {$O Common1   } {$O Common2   } {$O Common3   } {$O Boot      }
{$O WfcMenu   } {$O Timefunc  } {$O Sysop1    } {$O Sysop2    } {$O Offline   }
{$O Sysop2j   } {$O Sysop2a   } {$O Sysop2b   } {$O Sysop2c   } {$O Sysop2d   }
{$O Sysop2e   } {$O Sysop2f   } {$O Sysop2l   } {$O Sysop2g   } {$O Sysop2i   }
{$O Sysop2h   } {$O File4     } {$O Sysop2k   } {$O Sysop3    } {$O Sysop4    }
{$O Sysop6    } {$O Sysop7    } {$O Sysop7m   } {$O Sysop8    } {$O Sysop2m   }
{$O Sysop9    } {$O Sysop10   } {$O Sysop11   } {$O Mail0     } {$O Mail1     }
{$O Email     } {$O Mail2     } {$O Mail3     } {$O Vote      } {$O Nodelist  }
{$O Mail4     } {$O Arcview   } {$O File0     } {$O File1     } {$O File2     }
{$O File5     } {$O File6     } {$O File8     } {$O MultNode  } {$O Script    }
{$O File9     } {$O File10    } {$O File11    } {$O File12    } {$O File13    }
{$O File14    } {$O Archive1  } {$O Archive2  } {$O Archive3  } {$O Logon     }
{$O Maint     } {$O NewUsers  } {$O TimeBank  } {$O Bulletin  } {$O MiscUser  }
{$O ShortMsg  } {$O CUser     } {$O Doors     } {$O ExecBat   } {$O Automsg   }
{$O MyIO      } {$O Menus2    } {$O Menus3    } {$O LineChat  } {$O Stats      }
{$O Events    } {$O BBSList   } {$O Common4   } {$O File7     } {$O SplitCha  }
{$O Sysop2o   } {$O Sysop5   }  {$O SysOp12   }

CONST
  NeedToHangUp: Boolean = FALSE;

VAR
  ExitSave: Pointer;
  GeneralF: FILE OF GeneralRecordType;
  ByteFile: FILE OF Byte;
  TextFile: Text;
  S: Astr;
  Counter: Byte;
  Counter1: Integer;

PROCEDURE ErrorHandle;
VAR
  TextFile: Text;
  S: STRING[50];
BEGIN
  ExitProc := ExitSave;
  IF (ErrorAddr <> NIL) THEN
  BEGIN

    CHDir(StartDir);

    IF (General.Multinode) AND (ThisNode > 0) THEN
      Assign(SysOpLogFile,TempDir+'TEMPLOG.'+IntToStr(ThisNode) )
    ELSE
      Assign(SysOpLogFile,General.LogsPath+'SYSOP.LOG');

    Append(SysOpLogFile);
    S := '^8*>>^7 Runtime error '+IntToStr(ExitCode)+' at '+DateStr+' '+TimeStr+ '^8 <<*^5'+' (Check ERROR.LOG)';
    WriteLn(SysOpLogFile,S);
    Flush(SysOpLogFile);
    Close(SysOpLogFile);

    IF (TextRec(Trapfile).Mode = FMOutPut) THEN
    BEGIN
      WriteLn(Trapfile,S);
      Flush(Trapfile);
      Close(Trapfile);
    END;

    Assign(TextFile,'ERROR.LOG');
    Append(TextFile);
    IF (IOResult <> 0) THEN
      ReWrite(TextFile);

    WriteLn(TextFile,'อออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ');
    WriteLn(TextFile,'Critical error Log file - Contains screen images at instant of error.');
    WriteLn(TextFile,'The "ฒ" character shows the cursor position at time of error.');
    WriteLn(TextFile,'อออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ');
    WriteLn(TextFile);
    WriteLn(TextFile);
    WriteLn(TextFile,'ฏ>ฏ error #'+IntToStr(ExitCode)+' at '+DateStr+' '+TimeStr+' version: '+General.Version);

    IF (UserOn) THEN
    BEGIN
      Write(TextFile,'ฏ>ฏ User "'+AllCaps(ThisUser.name)+' #'+IntToStr(UserNum)+'" was on ');
      IF (ComPortSpeed > 0) THEN
        WriteLn(TextFile,'at '+IntToStr(ActualSpeed)+ 'baud')
      ELSE
        WriteLn(TextFile,'Locally');
    END;
    Close(TextFile);

    ScreenDump('ERROR.LOG');

    Assign(TextFile,'CRITICAL.ERR');
    ReWrite(TextFile);
    Close(TextFile);
    SetFAttr(TextFile,Dos.Hidden);

    Print('^8System malfunction.');

    LoadNode(ThisNode);
    Noder.Status := [];
    Noder.User := 0;
    SaveNode(ThisNode);

    Com_Flush_Send;
    Dtr(FALSE);
    Com_DeInstall;

    Halt(ExitErrors);

  END;
END;

PROCEDURE ReadP;
VAR
  d: astr;
  Counter: Integer;

  FUNCTION SC(s: astr; i: Integer): Char;
  BEGIN
    SC := UpCase(s[i]);
  END;

BEGIN
  Reliable := FALSE;
  Telnet := FALSE;
  CallerIDNumber := '';
  Counter := 0;
  WHILE (Counter < ParamCount) DO
  BEGIN
    Inc(Counter);
    IF ((SC(ParamStr(Counter),1) = '-') OR (SC(ParamStr(Counter),1) = '/')) THEN
      CASE SC(ParamStr(Counter),2) OF
        '5' : TextMode(259);
        'B' : AnswerBaud := StrToInt(Copy(ParamStr(Counter),3,255));
        'C' : Reliable := (Pos(AllCaps(Liner.Reliable),AllCaps(ParamStr(Counter))) > 0);
        'D' : OvrUseEms := FALSE;
        'E' : IF (Length(ParamStr(Counter)) >= 4) THEN
              BEGIN
                d := AllCaps(ParamStr(Counter));
                CASE d[3] OF
                  'E' : ExitErrors := StrToInt(Copy(d,4,(Length(d) - 3)));
                  'N' : ExitNormal := StrToInt(Copy(d,4,(Length(d) - 3)));
                END;
              END;
        'H' : SockHandle := Copy(ParamStr(Counter),3,255);
        'I' : BEGIN
                CASE SC(ParamStr(Counter),3) OF
                 'D' : CallerIDNumber := Copy(ParamStr(Counter),4,255);
                 'P' : CallerIDNumber := Copy(ParamStr(Counter),4,255);
               END;
              END;
        'L' : LocalIOOnly := TRUE;
        'M' : BEGIN
                MakeQWKFor := StrToInt(Copy(ParamStr(Counter),3,255));
                LocalIOOnly := TRUE;
              END;
        'N' : ThisNode := StrToInt(Copy(ParamStr(Counter),3,255));
        'P' : BEGIN
                PackBasesOnly := TRUE;
                LocalIOOnly := TRUE;
              END;
        'Q' : QuitAfterDone := TRUE;
        'S' : BEGIN
                SortFilesOnly := TRUE;
                LocalIOOnly := TRUE;
              END;
        'F' : BEGIN
                FileBBSOnly := TRUE;
                LocalIOOnly := TRUE;
              END;
        'T' : BEGIN
                IF (SC(ParamStr(Counter),3) <> 'C') THEN
                  HangUpTelnet := TRUE;
                Telnet := TRUE;
              END;
        'U' : BEGIN
                UpQWKFor := StrToInt(Copy(ParamStr(Counter),3,255));
                LocalIOOnly := TRUE;
              END;
        'X' : ExtEventTime := StrToInt(Copy(ParamStr(Counter),3,255));
      END;
  END;
  AllowAbort := TRUE;
END;

BEGIN
  ClrScr;
  TextColor(Yellow);
{$IFDEF MSDOS}
  GetIntVec($14,Interrupt14);
{$ENDIF}
  FileMode := 66;
{$IFDEF WIN32}
  FileModeReadWrite := FileMode;
{$ENDIF}
  ExitSave := ExitProc;
  ExitProc := @ErrorHandle;

  DirectVideo := FALSE;
  CheckSnow := FALSE;

  UserOn := FALSE;
  UserNum := 0;

  GetDir(0,StartDir);

  DatFilePath := GetEnv('RENEGADE');
  IF (DatFilePath <> '') THEN
    DatFilePath := BSlash(DatFilePath,TRUE);
  Assign(ByteFile,DatFilePath+'RENEGADE.DAT');
  Reset(ByteFile);
  IF (IOResult <> 0) THEN
  BEGIN
    WriteLn('Error opening RENEGADE.DAT.');
    Halt;
  END;
  Counter := 0;
  Seek(ByteFile,FileSize(ByteFile));
  WHILE FileSize(ByteFile) < SizeOf(General) DO
    Write(ByteFile,Counter);
  Close(ByteFile);

  Assign(GeneralF,DatFilePath+'RENEGADE.DAT');
  Reset(GeneralF);
  Read(GeneralF,General);
  Close(GeneralF);

  ReadP;

{$IFDEF MSDOS}
  OvrFileMode := 0;
  Write('Initializing RENEGADE.OVR ... ');
  OvrInit('RENEGADE.OVR');
  IF (OvrResult <> OvrOK) THEN
    OvrInit(General.DataPath+'RENEGADE.OVR');
  IF (OvrResult <> OvrOK) THEN
  BEGIN
    CASE OvrResult OF
      OvrError    : WriteLn('Program has no overlays.');
      OvrNotFound : WriteLn('Overlay file not found.');
    END;
    Halt;
  END
  ELSE
    WriteLn('Done.');

  IF (General.UseEMS) AND (OvrUseEms) THEN
  BEGIN

    Write('Attempting to load overlays into XMS memory ... ');

    {vrMovBufToUMB;}

    IF (OvrResult <> OvrOK) THEN
    BEGIN
      WriteLn('Failed.');
      Write('Attempting to load overlays into EMS memory ... ');
      OvrInitEMS;
      IF (OvrResult = OvrOK) THEN
      BEGIN
        WriteLn('Done.');
        OverLayLocation := 1
      END
      ELSE
      BEGIN
        CASE OvrResult OF
          OvrIOError     : WriteLn('Overlay file I/O error.');
          OvrNoEMSDriver : WriteLn('EMS driver not installed.');
          OvrNoEMSMemory : WriteLn('Not enough EMS memory.');
        END;
        Halt;
      END;
    END
    ELSE
    BEGIN
      WriteLn('Done.');
      OverLayLocation := 2;
    END;
  END;
  WriteLn('Initial size of the overlay buffer is '+FormatNumber(OvrGetBuf)+' bytes.');
{$ENDIF}

  Init;

  MaxDisplayRows := (Hi(WindMax) + 1);
  MaxDisplayCols := (Lo(WindMax) + 1);
  ScreenSize := 2 * MaxDisplayRows * MaxDisplayCols;
  IF (ScreenSize > 8000) THEN
    ScreenSize := 8000;

  IF (FileBBSOnly) OR (PackBasesOnly) OR (SortFilesOnly) OR (MakeQWKFor > 0) OR (UpQWKFor > 0) THEN
  BEGIN
    WFCMDefine;
    TempPause := FALSE;
    IF (MakeQWKFor > 0) THEN
    BEGIN
      UserNum := MakeQWKFor;
      LoadURec(ThisUser,MakeQWKFor);
      NewFileDate := ThisUser.LastOn;
      Downloadpacket;
      SaveURec(ThisUser,MakeQWKFor);
    END;

    IF (UpQWKFor > 0) THEN
    BEGIN
      UserNum := UpQWKFor;
      LoadURec(ThisUser,UpQWKFor);
      Uploadpacket(TRUE);
      SaveURec(ThisUser,UpQWKFor);
    END;

    IF (PackBasesOnly) THEN
    BEGIN
      DoShowPackMessageAreas;
      NL;
      Print('^5Message areas packed.');
    END;

    IF (SortFilesOnly) THEN
      Sort;

    IF (FileBBSOnly) THEN
      CheckFilesBBS;

    Halt(0);
  END;

  GetMem(MemCmd,MaxCmds * SizeOf(MemCmdRec));

  REPEAT

   IF (NeedToHangUp) THEN
    BEGIN
      NeedToHangUp := FALSE;
      DoPhoneHangUp(FALSE);
    END;

    WFCMenus;

    UserOn := FALSE;
    UserNum := 0;

    IF (NOT DoneDay) THEN
    BEGIN

      lStatus_Screen(100,'User logging in.',FALSE,S);

      LastScreenSwap := 0;

      IF (GetUser) THEN
        NewUser;

      IF (NOT HangUp) THEN
      BEGIN

        NumBatchDLFiles := 0;
        NumBatchULFiles := 0;
        BatchDLPoints := 0;
        BatchDLSize := 0;
        BatchDLTime := 0;

        LogonMaint;

        IF (NOT HangUp) THEN
        BEGIN

          NewFileDate := ThisUser.LastOn;

          IF (MsgAreaAC(ThisUser.LastMsgArea)) THEN
            MsgArea := ThisUser.LastMsgArea
          ELSE
          BEGIN
            FOR Counter := 1 TO NumMsgAreas DO
              IF (MsgAreaAC(Counter)) THEN
              BEGIN
                MsgArea := Counter;
                Counter := NumMsgAreas;
              END;
          END;

          IF (FileAreaAC(ThisUser.LastFileArea)) THEN
            FileArea := ThisUser.LastFileArea
          ELSE
          BEGIN
            FOR Counter := 1 TO NumFileAreas DO
              IF (FileAreaAC(Counter)) THEN
              BEGIN
                FileArea := Counter;
                Counter := NumFileAreas;
              END;
          END;

          NewCompTables;

          MenuStackPtr := 0;

          FOR Counter := 1 TO MaxMenus DO
            MenuStack[Counter] := 0;

          IF (Novice in ThisUser.Flags) THEN
            CurHelpLevel := 2
          ELSE
            CurHelpLevel := 1;

          GlobalCmds := 0;
          NumCmds := 0;
          CurMenu := 0;
          FallBackMenu := 0;

          IF (General.GlobalMenu <> 0) THEN
          BEGIN
            CurMenu := General.GlobalMenu;
            LoadMenu;
            GlobalCmds := NumCmds;
          END;

          IF (ThisUser.UserStartMenu = 0) THEN
            CurMenu := General.AllStartMenu
          ELSE
            CurMenu := ThisUser.UserStartMenu;

          LoadMenu;

          AutoExecCmd('FIRSTCMD');

        END;

        WHILE (NOT HangUp) DO
          MenuExec;

      END;

      IF (QuitAfterDone) THEN
      BEGIN
        IF (ExitErrorLevel = 0) THEN
          ExitErrorLevel := ExitNormal;
        HangUp := TRUE;
        DoneDay := TRUE;
        NeedToHangUp := TRUE;
      END;

      LogOffMaint;

      IF (General.Multinode) THEN
      BEGIN
        Assign(TextFile,General.LogsPath+'SYSOP.LOG');
        IF Exist(General.LogsPath+'SYSOP.LOG') THEN
          Append(TextFile)
        ELSE
          ReWrite(TextFile);
        Reset(SysOpLogFile);
        WHILE NOT EOF(SysOpLogFile) DO
        BEGIN
          ReadLn(SysOpLogFile,S);
          WriteLn(TextFile,S);
        END;
        Close(SysOpLogFile);
        Close(TextFile);
        ReWrite(SysOpLogFile);
        Close(SysOpLogFile);
        LastError := IOResult;
      END;

      IF (Com_Carrier) AND (NOT DoneDay) THEN
        IF (InCom) THEN
          NeedToHangUp := TRUE;

    END;

  UNTIL (DoneDay);

  FreeMem(MemCmd,MaxCmds * SizeOf(MemCmdRec));

  IF (MCIBuffer <> NIL) THEN
    Dispose(MCIBuffer);

  IF (MemEventArray[NumEvents] <> NIL) THEN
    FOR Counter1 := 1 TO NumEvents DO
      IF (MemEventArray[Counter1] <> NIL) THEN
        Dispose(MemEventArray[Counter1]);

  IF (NeedToHangUp) THEN
  BEGIN
    IF (HangUpTelnet) THEN
      DoTelnetHangUp(TRUE);
    IF (NOT HangUpTelnet) THEN
      DoPhoneHangUp(FALSE);
  END;

  IF (General.Multinode) THEN
  BEGIN
    Assign(TextFile,General.LogsPath+'SYSOP.LOG');
    IF Exist(General.LogsPath+'SYSOP.LOG') THEN
      Append(TextFile)
    ELSE
      ReWrite(TextFile);
    Reset(SysOpLogFile);
    WHILE NOT EOF(SysOpLogFile) DO
    BEGIN
      ReadLn(SysOpLogFile,S);
      WriteLn(TextFile,S);
    END;
    Close(SysOpLogFile);
    Close(TextFile);
    ReWrite(SysOpLogFile);
    Close(SysOpLogFile);
    LastError := IOResult;
  END;

  IF (General.Multinode) THEN
    Kill(TempDir+'TEMPLOG.'+IntToStr(ThisNode));

  Window(1,1,MaxDisplayCols,MaxDisplayRows);
  TextBackGround(0);
  TextColor(7);
  ClrScr;
  TextColor(14);

  IF (NewEchoMail) AND (ExitErrorLevel = 0) THEN
    ExitErrorLevel := 2;

  LoadNode(ThisNode);
  Noder.Status := [];
  SaveNode(ThisNode);

  PurgeDir(TempDir,FALSE);

  Com_DeInstall;

  WriteLn('Exiting with errorlevel ',ExitErrorLevel);
  Halt(ExitErrorLevel);
END.
