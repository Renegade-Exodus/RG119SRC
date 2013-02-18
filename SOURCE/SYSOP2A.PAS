{$IFDEF WIN32}
{$I DEFINES.INC}
{$ENDIF}

{$A+,B-,D+,E-,F+,I-,L+,N-,O+,R-,S+,V-}

UNIT SysOp2A;

INTERFACE

PROCEDURE MainBBSConfiguration;

IMPLEMENTATION

USES
  Crt,
  Common,
  SysOp7,
  TimeFunc;

  {
     RGSysCfgStr(1,FALSE)

     $Main_BBS_Configuration
     %CL^5Main BBS Configuration:^1

     ^1A. BBS name/number  : ^5%BN ^1(^5%BP^1)
     ^1B. Telnet Url       : ^5%TN
     ^1C. SysOp's name     : ^5%SN{15 ^1D. Renegade Version   : ^5%VR
     ^1E. SysOp chat hours : ^5%CS  ^1F. Minimum baud hours : ^5%BL
     ^1G. Regular DL hours : ^5%DH  ^1H. Minimum baud DL hrs: ^5%BM
     ^1I. BBS Passwords    :                 ^1J. Pre-event warning  : ^5%ET seconds
     ^1K. System Menus     :                 ^1L. Bulletin Prefix    : ^5%PB
     ^1M. MultiNode support: ^5%MN             ^1N. Network mode       : ^5%NM

     ^10. Main data files dir.    : ^5%PD
     ^11. Miscellaneous Files dir.: ^5%PM
     ^12. Message file storage dir: ^5%P1
     ^13. Nodelist (Version 7) dir: ^5%P2
     ^14. Log files/trap files dir: ^5%PL
     ^15. Temporary directory     : ^5%PT
     ^16. Protocols directory     : ^5%PP
     ^17. Archivers directory     : ^5%P7
     ^18. File attach directory   : ^5%PF
     ^19. RAM drive/MultiNode path: ^5%P3

     Enter selection [^5A^4-^5N^4,^50^4-^59^4,^5Q^4=^5Quit^4]: @
     $

     RGSysCfgStr(2,TRUE)

     $Main_BBS_Configuration_BBS_Name
     %LFNew BBS name: @
     $

     RGSysCfgStr(3,TRUE)

     $Main_BBS_Configuration_BBS_Phone
     %LFNew BBS phone number: @
     $

     RGSysCfgStr(4,TRUE)

     $Main_BBS_Configuration_Telnet_URL
     %LF^4New Telnet Url:%LF^4: @
     $

     RGSysCfgStr(5,TRUE)

     $Main_BBS_Configuration_SysOp_Name
     %LFNew SysOp name: @
     $

     RGNoteStr(0,FALSE)

     $Internal_Use_Only
     %LF^7This is for internal use only.
     %PA
     $

     RGNoteStr(1,FALSE)

     $Only_Change_Locally
     %LF^7This can only be changed locally.
     %PA
     $

     RGSysCfgStr(6,TRUE)

     $Main_BBS_Configuration_SysOp_Chat_Hours
     %LFDo you want to declare sysop chat hours? @
     $

     RGSysCfgStr(7,TRUE)

     $Main_BBS_Configuration_Minimum_Baud_Hours
     %LFDo you want to declare hours people at the minimum baud can logon? @
     $

     RGSysCfgStr(8,TRUE)

     $Main_BBS_Configuration_Download_Hours
     %LFDo you want to declare download hours? @
     $

     RGSysCfgStr(9,TRUE)

     $Main_BBS_Configuration_Minimum_Baud_Download_Hours
     %LFDo you want to declare hours people at minimum baud can download? @
     $

     RGSysCfgStr(10,FALSE)

     $Main_BBS_Configuration_SysOp_Password_Menu
     %CL^5System Passwords:^1

     ^1A. SysOp password        : ^5%P4
     ^1B. New user password     : ^5%P5
     ^1C. Baud override password: ^5%P6

     Enter selection [^5A^4-^5C^4,^5Q^4=^5Quit^4]: @
     $

     RGSysCfgStr(11,TRUE)

     $Main_BBS_Configuration_SysOp_Password
     %LFNew SysOp password: @
     $

     RGSysCfgStr(12,TRUE)

     $Main_BBS_Configuration_New_User_Password
     %LFNew new-user password: @
     $

     RGSysCfgStr(13,TRUE)

     $Main_BBS_Configuration_Baud_Override_Password
     %LFNew minimum baud rate override password: @
     $

     RGSysCfgStr(14,TRUE)

     $Main_BBS_Configuration_Pre_Event_Time
     %LFNew pre-event warning time@
     $

     RGSysCfgStr(15,FALSE)

     $Main_BBS_Configuration_System_Menus
     %CL^5System Menus:^1

     ^11. Global       : ^5%M1
     ^12. All Start    : ^5%M2
     ^13. Shutle logon : ^5%M3
     ^14. New user info: ^5%M4
     ^15. Message Read : ^5%M5
     ^16. File List    : ^5%M6

     Enter selection [^51^4-^56^4,^5Q^4=^5Quit^4]: @
     $

     RGSysCfgStr(16,TRUE)

     $Main_BBS_Configuration_System_Menus_Global
     %LFMenu for global commands (0=None)@
     $

     RGSysCfgStr(17,TRUE)

     $Main_BBS_Configuration_System_Menus_Start
     %LFMenu to start all users at@
     $

     RGSysCfgStr(18,TRUE)

     $Main_BBS_Configuration_System_Menus_Shuttle
     %LFMenu for shuttle logon (0=None)@
     $

     RGSysCfgStr(19,TRUE)

     $Main_BBS_Configuration_System_Menus_New_User
     %LFMenu for new user information@
     $

     RGSysCfgStr(20,TRUE)

     $Main_BBS_Configuration_System_Menus_Message_Read
     %LFMenu for message read@
     $

     RGSysCfgStr(21,TRUE)

     $Main_BBS_Configuration_System_Menus_File_Listing
     %LFMenu for file listing@
     $

     RGNoteStr(2,FALSE)

     $Invalid_Menu_Number
     %LF^7Invalid menu number.
     %PA
     $

     RGSysCfgStr(22,TRUE)

     $Main_BBS_Configuration_Bulletin_Prefix
     %LFDefault bulletin prefix: @
     $

     RGNoteStr(1,FALSE)

     $Only_Change_Locally
     %LF^7This can only be changed locally.
     %PA
     $

     RGSysCfgStr(23,TRUE)

     $Main_BBS_Configuration_Local_Security
     %LFDo you want local security to remain on? @
     $

     RGSysCfgStr(24,TRUE)

     $Main_BBS_Configuration_Data_Path
     %LF^4New data files path (^5End with a ^4"^5\^4"):%LF^4: @
     $

     RGSysCfgStr(25,TRUE)

     $Main_BBS_Configuration_Misc_Path
     %LF^4New miscellaneous files path (^5End with a ^4"^5\^4"):%LF^4: @
     $

     RGSysCfgStr(26,TRUE)

     $Main_BBS_Configuration_Msg_Path
     %LF^4New message files path (^5End with a ^4"^5\^4"):%LF^4: @
     $

     RGSysCfgStr(27,TRUE)

     $Main_BBS_Configuration_NodeList_Path
     %LF^4New nodelist files path (^5End with a ^4"^5\^4"):%LF^4: @
     $

     RGSysCfgStr(28,TRUE)

     $Main_BBS_Configuration_Log_Path
     %LF^4New sysop log files path (^5End with a ^4"^5\^4"):%LF^4: @
     $

     RGSysCfgStr(29,TRUE)

     $Main_BBS_Configuration_Temp_Path
     %LF^4New temporary files path (^5End with a ^4"^5\^4"):%LF^4: @
     $

     RGSysCfgStr(30,TRUE)

     $Main_BBS_Configuration_Protocol_Path
     %LF^4New protocol files path (^5End with a ^4"^5\^4"):%LF^4: @
     $

     RGSysCfgStr(31,TRUE)

     $Main_BBS_Configuration_Archive_Path
     %LF^4New archive files path (^5End with a ^4"^5\^4"):%LF^4: @
     $

     RGSysCfgStr(32,TRUE)

     $Main_BBS_Configuration_Attach_Path
     %LF^4New file attach files path (^5End with a ^4"^5\^4"):%LF^4: @
     $

     RGSysCfgStr(33,TRUE)

     $Main_BBS_Configuration_MultNode_Path
     %LF^4New multi-node files path (^5End with a ^4"^5\^4"):%LF^4: @
     $

     }

  PROCEDURE GetTimeRange(CONST RGStrNum: LongInt; VAR LoTime,HiTime: SmallInt);
  VAR
    TempStr: Str5;
    LowTime,
    HighTime: Integer;
  BEGIN
    IF (NOT (PYNQ(RGSysCfgStr(RGStrNum,TRUE),0,FALSE))) THEN
    BEGIN
      LowTime := 0;
      HighTime := 0;
    END
    ELSE
    BEGIN
      NL;
      Print('All entries in 24 hour time.  Hour: (0-23), Minute: (0-59)');
      NL;
      Prt('Starting time: ');
      MPL(5);
      InputFormatted('',TempStr,'##:##',TRUE);
      IF (StrToInt(Copy(TempStr,1,2)) IN [0..23]) AND (StrToInt(Copy(TempStr,4,2)) IN [0..59]) THEN
        LowTime := ((StrToInt(Copy(TempStr,1,2)) * 60) + StrToInt(Copy(TempStr,4,2)))
      ELSE
        LowTime := 0;
      NL;
      Prt('Ending time: ');
      MPL(5);
      InputFormatted('',TempStr,'##:##',TRUE);
      IF (StrToInt(Copy(TempStr,1,2)) IN [0..23]) AND (StrToInt(Copy(TempStr,4,2)) IN [0..59]) THEN
        HighTime := ((StrToInt(Copy(TempStr,1,2)) * 60) + StrToInt(Copy(TempStr,4,2)))
      ELSE
        HighTime := 0;
    END;
    NL;
    Print('Hours: '+PHours('Always allowed',LowTime,HighTime));
    NL;
    IF PYNQ('Are you sure this is what you want? ',0,FALSE) THEN
    BEGIN
      LoTime := LowTime;
      HiTime := HighTime;
    END;
  END;

PROCEDURE MainBBSConfiguration;
VAR
  LineFile: FILE OF LineRec;
  Cmd: Char;
  Changed: Boolean;
BEGIN
  Assign(LineFile,General.DataPath+'NODE'+IntToStr(ThisNode)+'.DAT');
  Reset(LineFile);
  Seek(LineFile,0);
  Read(LineFile,Liner);
  REPEAT
    WITH General DO
    BEGIN
      Abort := FALSE;
      Next := FALSE;
      RGSysCfgStr(1,FALSE);
      OneK(Cmd,'QABCDEFGHIJKLMN0123456789'^M,TRUE,TRUE);
      CASE Cmd OF
        'A' : BEGIN
                InputWNWC(RGSysCfgStr(2,TRUE),BBSName,(SizeOf(BBSName) - 1),Changed);
                InputFormatted(RGSysCfgStr(3,TRUE),BBSPhone,'###-###-####',FALSE);
              END;
        'B' : InputWN1(RGSysCfgStr(4,TRUE),Liner.NodeTelnetURL,(SizeOf(Liner.NodeTelnetURL) - 1),[InteractiveEdit],Changed);
        'C' : InputWN1(RGSysCfgStr(5,TRUE),SysOpName,(SizeOf(SysOpName) - 1),[InterActiveEdit],Changed);
        'D' : RGNoteStr(0,FALSE);
        'E' : IF (InCom) THEN
                RGNoteStr(1,FALSE)
              ELSE
                GetTimeRange(6,lLowTime,HiTime);
        'F' : GetTimeRange(7,MinBaudLowTime,MinBaudHiTime);
        'G' : GetTimeRange(8,DLLowTime,DLHiTime);
        'H' : GetTimeRange(9,MinBaudDLLowTime,MinBaudDLHiTime);
        'I' : BEGIN
                REPEAT
                  RGSysCfgStr(10,FALSE);
                  OneK(Cmd,^M'ABC',TRUE,TRUE);
                  CASE Cmd OF
                    'A' : InputWN1(RGSysCfgStr(11,TRUE),SysOpPw,(SizeOf(SysOpPW) - 1),[InterActiveEdit,UpperOnly],Changed);
                    'B' : InputWN1(RGSysCfgStr(12,TRUE),NewUserPW,(SizeOf(SysOpPW) - 1),[InterActiveEdit,UpperOnly],Changed);
                    'C' : InputWN1(RGSysCfgStr(13,TRUE),MinBaudOverride,(SizeOf(SysOpPW) - 1),
                                   [InterActiveEdit,UpperOnly],Changed);
                  END;
                UNTIL (Cmd = ^M) OR (HangUp);
                Cmd := #0;
              END;
        'J' : InputByteWOC(RGSysCfgStr(14,TRUE),EventWarningTime,[DisplayValue,NumbersOnly],0,255);
        'K' : BEGIN
                REPEAT
                  RGSysCfgStr(15,FALSE);
                  OneK(Cmd,^M'123456',TRUE,TRUE);
                  CASE Cmd OF
                    '1' : FindMenu(RGSysCfgStr(16,TRUE),GlobalMenu,0,NumMenus,Changed);
                    '2' : FindMenu(RGSysCfgStr(17,TRUE),AllStartMenu,1,NumMenus,Changed);
                    '3' : FindMenu(RGSysCfgStr(18,TRUE),ShuttleLogonMenu,0,NumMenus,Changed);
                    '4' : FindMenu(RGSysCfgStr(19,TRUE),NewUserInformationMenu,1,NumMenus,Changed);
                    '5' : FindMenu(RGSysCfgStr(20,TRUE),MessageReadMenu,1,NumMenus,Changed);
                    '6' : FindMenu(RGSysCfgStr(21,TRUE),FileListingMenu,1,NumMenus,Changed);
                  END;
                UNTIL (Cmd = ^M) OR (HangUp);
                Cmd := #0;
              END;
        'L' : InputWN1(RGSysCfgStr(22,TRUE),BulletPrefix,(SizeOf(BulletPrefix) - 1),[InterActiveEdit,UpperOnly],Changed);
        'M' : IF (InCom) THEN
                RGNoteStr(1,FALSE)
              ELSE
              BEGIN
                MultiNode := (NOT MultiNode);
                SaveGeneral(FALSE);
                ClrScr;
                Writeln('Please restart Renegade.');
                Halt;
              END;
        'N' : BEGIN
                NetworkMode := (NOT NetworkMode);
                IF (NetworkMode) THEN
                  LocalSec := TRUE
                ELSE
                  LocalSec := PYNQ(RGSysCfgStr(23,TRUE),0,FALSE);
              END;
        '0' : InputPath(RGSysCfgStr(24,TRUE),DataPath,TRUE,FALSE,Changed);
        '1' : InputPath(RGSysCfgStr(25,TRUE),MiscPath,TRUE,FALSE,Changed);
        '2' : InputPath(RGSysCfgStr(26,TRUE),MsgPath,TRUE,FALSE,Changed);
        '3' : InputPath(RGSysCfgStr(27,TRUE),NodePath,TRUE,FALSE,Changed);
        '4' : InputPath(RGSysCfgStr(28,TRUE),LogsPath,TRUE,FALSE,Changed);
        '5' : InputPath(RGSysCfgStr(29,TRUE),TempPath,FALSE,FALSE,Changed);
        '6' : InputPath(RGSysCfgStr(30,TRUE),ProtPath,TRUE,FALSE,Changed);
        '7' : InputPath(RGSysCfgStr(31,TRUE),ArcsPath,TRUE,FALSE,Changed);
        '8' : InputPath(RGSysCfgStr(32,TRUE),FileAttachPath,TRUE,FALSE,Changed);
        '9' : InputPath(RGSysCfgStr(33,TRUE),lMultPath,TRUE,FALSE,Changed);
      END;
    END;
  UNTIL (Cmd = 'Q') OR (HangUp);
  Seek(LineFile,0);
  Write(LineFile,Liner);
  Close(LineFile);
  LastError := IOResult;
END;

END.
