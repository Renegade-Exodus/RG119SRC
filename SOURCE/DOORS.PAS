{$IFDEF WIN32}
{$I DEFINES.INC}
{$ENDIF}

{$A+,B-,D+,E-,F+,I-,L+,N-,O+,R-,S+,V-}
UNIT Doors;

INTERFACE

USES
  Common;

PROCEDURE DoDoorFunc(DropFileType: Char; MenuOption: Str50);

IMPLEMENTATION

USES
  ExecBat,
  Events,
  File0,
  Mail0,
  SysOp12,
  TimeFunc;

PROCEDURE ShowUserName(RName: Boolean; VAR First,Last: AStr);
BEGIN
  First := '';
  Last := '';
  IF (RName) THEN
  BEGIN
    IF (Pos(' ',ThisUser.RealName) = 0) THEN
    BEGIN
      First := ThisUser.RealName;
      Last := '';
    END
    ELSE
    BEGIN
      First := Copy(ThisUser.RealName,1,(Pos(' ',ThisUser.RealName) - 1));
      Last := Copy(ThisUser.RealName,(Length(First) + 2),Length(ThisUser.RealName));
    END;
  END
  ELSE
  BEGIN
    IF (Pos(' ',ThisUser.Name) = 0) THEN
    BEGIN
      First := ThisUser.Name;
      Last := '';
    END
    ELSE
    BEGIN
      First := Copy(ThisUser.Name,1,(Pos(' ',ThisUser.Name) - 1));
      Last := Copy(ThisUser.Name,(Length(First) + 2),Length(ThisUser.Name));
    END;
  END;
END;

(*
START POS   SAVED
& LENGTH     AS       DESCRIPTION OF DATA
---------  ------    --------------------------------------------
1, 2       ASCII     "-1" always used by FeatherNet PRO!
3, 2       ASCII     " 0" always used By FeatherNet PRO!
5, 2       ASCII     "-1" if page allowed or 0 if not.
7, 2       ASCII     User Number in Users file
9, 1       ASCII     "Y" if Expert or "N"if Not
10, 2      ASCII     "-1"  if  Error Correcting modem, "0" if not
12, 1      ASCII     "Y" if Graphics Mode or "N" if Not
13, 1      ASCII     "A" is always placed here by FeatherNet PRO!
14, 5      ASCII     The DTE speed or PC  to Modem baud rate
19, 5      ASCII     The connect baud rate:"300-38400" or "Local"
24, 2      MKI$      User's Record # in "USERS" file
26, 15     ASCII     User's FIRST Name padded with spaces
41, 12     ASCII     User's Password
53, 2      MKI$      Time user logged on in Mins: (60 x Hr)+Mins
55, 2      MKI$      User's Time on today in minutes
57, 5      ASCII     Time user logged on in HH:MM format. Ex: "12:30"
62, 2      MKI$      Time user allowed today in minutes
64, 2      ASCII     Daily D/L Limit from pwrd file
66, 1      Chr$      Conference the user has last joined
67, 5      Bitmap    Areas user has been in
72, 5      Bitmap    Areas user has scanned
77, 2      MKI$i     An mki$(0) used by FeatherNet PRO!
79, 2      MKI$      Currently a value of 0 is here (MKI$(0))
81, 4      ASCII     4 Spaces are placed here
85, 25     ASCII     User's Full name placed here.
110, 2     MKI$      Number of minutes user has left today
112, 1     chr$      Node user is on (actual character)
113, 5     ASCII     Scheduled EVENT time
118, 2     ASCII     A "-1" if EVENT is active or a " 0"
120, 2     ASCII     " 0" is Placed here by FeatherNet PRO!
122, 4     MKS$      Time of day in secs format when user is on
126, 1     ASCII     The Com port this node uses (0 - 8)
127, 2     ASCII     Flag to let FNET PRO! know type of file xfer
129, 1     CHAR      Ansi Detected Flag - Char[0] or Char[1]
130, 13    ASCII     Unused by FeatherNet PRO! - SPACE filled
143, 2     MKI$      Last Area User was in (0 - 32766 possible)
145        BITMAP    Not Currently Used by FeatherNet PRO!

--------------------------------------------------------------------------------
Some BASIC functions:
CHR$
Writes a character (8 bit value). One byte.
MKI$
Writes a short integer (16 bit value). Low byte then high byte.
MKS$
I didn't want to research this, and am writing four zeroes. Anyone know?
--------------------------------------------------------------------------------
*)

PROCEDURE Write_PCBoard_Sys(RName: Boolean);
VAR
  DoorFile: FILE;
  S,
  UN: STRING[50];
  i: Integer;

  PROCEDURE Dump(x: STRING);
  BEGIN
    BlockWrite(DoorFile,x[1],Length(x));
  END;

BEGIN
  UN := AOnOff(RName,ThisUser.RealName,ThisUser.Name);

  Assign(DoorFile,Liner.DoorPath+'PCBOARD.SYS');
  ReWrite(DoorFile,1);
  Dump(AOnOff(WantOut,'-1',' 0'));
  Dump(AOnOff(FALSE,'-1',' 0'));
  Dump(AOnOff(SysOpAvailable,'-1',' 0'));
  Dump(' 0 ');
  Dump(AOnOff(Reliable,'-1',' 0'));
  Dump(Copy(ShowYesNo(OkANSI OR OKAvatar),1,1));
  Dump('A');
  Dump(PadLeftInt(ComPortSpeed,5));
  Dump(AOnOff((ComPortSpeed = 0),'Local',PadLeftInt(ComPortSpeed,5)));
  BlockWrite(DoorFile,UserNum,2);
  Dump(PadLeftStr(Copy(UN,1,Pos(' ',UN) - 1),15));
  Dump(PadLeftStr('PASSWORD',12));
  i := 0;
  BlockWrite(DoorFile,i,2);
  BlockWrite(DoorFile,i,2);
  Dump('00:00');
  i := General.TimeAllow[ThisUser.SL];
  BlockWrite(DoorFile,i,2);
  i := General.DLKOneDay[ThisUser.SL];
  BlockWrite(DoorFile,i,2);
  Dump(#0#0#0#0#0#0);
  Dump(Copy(S,1,5));
  i := 0;
  BlockWrite(DoorFile,i,2);
  BlockWrite(DoorFile,i,2);
  Dump('    ');
  Dump(PadLeftStr(UN,25));
  i := (NSL DIV 60);
  BlockWrite(DoorFile,i,2);
  Dump(Chr(ThisNode)+'00:00');
  Dump(AOnOff(FALSE,'-1',' 0'));
  Dump(AOnOff(FALSE,'-1',' 0'));
  Dump(#0#0#0#0);
  S := AOnOff((ComPortSpeed = 0),'0',IntToStr(Liner.Comport));
  S := S[1]+#0#0;
  IF (OkANSI OR OKAvatar) THEN
    S := S + #1
  ELSE
    S := S + #0;
  Dump(S);
  Dump(DateStr);
  i := 0;
  BlockWrite(DoorFile,i,2);
  Dump(#0#0#0#0#0#0#0#0#0#0);
  Close(DoorFile);
  LastError := IOResult;
END;

(*
Node name          The name of the system.
Sysop f.name       The sysop's name up to the first space.
Sysop l.name       The sysop's name following the first space.
Com port           The serial port the modem is connected to, or 0 if logged in on console.
Baud rate          The current port (DTE) rate.
Networked          The number "0"
User's first name  The current user's name, up to the first space.
User's last name   The current user's name, following the first space.
City               Where the user lives, or a blank line if unknown.
Terminal type      The number "0" if TTY, or "1" if ANSI.
Security level     The number 5 for problem users, 30 for regular users, 80 for Aides, and 100 for Sysops.
Minutes remaining  The number of minutes left in the current user's account, limited to 546 to keep from
                   overflowing other software.
FOSSIL             The number "-1" if using an external serial driver or "0" if using internal serial routines.
*)

PROCEDURE Write_DorInfo1_Def(RName: Boolean);
VAR
  DoorFile: Text;
  First,
  Last: AStr;
BEGIN
  Assign(DoorFile,Liner.DoorPath+'DORINFO1.DEF');
  ReWrite(DoorFile);
  WriteLn(DoorFile,StripColor(General.BBSName));

  First := Copy(General.SysOpName,1,(Pos(' ',General.SysOpName) - 1));
  Last := SQOutSp(Copy(General.SysOpName,(Length(First) + 1),Length(General.SysOpName)));
  WriteLn(DoorFile,First);
  WriteLn(DoorFile,Last);

  WriteLn(DoorFile,'COM'+AOnOff((ComPortSpeed = 0),'0',IntToStr(Liner.Comport)));
  WriteLn(DoorFile,IntToStr(ComPortSpeed)+' BAUD,N,8,1');
  WriteLn(DoorFile,'0');

  ShowUserName(RName,First,Last);

  WriteLn(DoorFile,AllCaps(First));
  WriteLn(DoorFile,AllCaps(Last));

  WriteLn(DoorFile,ThisUser.CityState);
  WriteLn(DoorFile,AOnOff((OkANSI OR OKAvatar),'1','0'));
  WriteLn(DoorFile,ThisUser.SL);
  WriteLn(DoorFile,(NSL DIV 60));

  WriteLn(DoorFile,'0');

  Close(DoorFile);
  LastError := IOResult;
END;

(*
0                            Line 1 : Comm type (0=local, 1=serial, 2=telnet)
0                            Line 2 : Comm or socket handle
38400                        Line 3 : Baud rate
Mystic 1.07                  Line 4 : BBSID (software name and version)
1                            Line 5 : User record position (1-based)
James Coyle                  Line 6 : User's real name
g00r00                       Line 7 : User's handle/alias
255                          Line 8 : User's security level
58                           Line 9 : User's time left (in minutes)
1                            Line 10: Emulation *See Below
1                            Line 11: Current node number

 * The following are values we've predefined for the emulation:

 0 = Ascii
 1 = Ansi
 2 = Avatar
 3 = RIP
 4 = Max Graphics     { Not Used by RG }
*)

PROCEDURE Write_Door32_Sys(RName: Boolean);
VAR
  DoorFile: Text;

  FUNCTION ShowSpeed: AStr;
  BEGIN
    IF (TelNet) THEN
      ShowSpeed := '2'
    ELSE IF (ComportSpeed <> 0) THEN
      ShowSpeed := '1'
    ELSE
      ShowSpeed := '0'
  END;

  FUNCTION ShowEmulation: AStr;
  BEGIN
    IF (OkRIP) THEN
      ShowEmulation := '3'
    ELSE IF (OKAvatar) THEN
      ShowEmulation := '2'
    ELSE IF (OkANSI) THEN
      ShowEmulation := '1'
    ELSE
      ShowEmulation := '0';
  END;

BEGIN
  Assign(DoorFile,Liner.DoorPath+'DOOR32.SYS');
  ReWrite(DoorFile);
  WriteLn(DoorFile,ShowSpeed);
  WriteLn(DoorFile,SockHandle);
  WriteLn(DoorFile,ComPortSpeed);
  WriteLn(DoorFile,'Renegade BBS '+General.Version);   (* Was General.BBSName *)
  WriteLn(DoorFile,UserNum);
  WriteLn(DoorFile,ThisUser.RealName);
  WriteLn(DoorFile,AOnOff(RName,ThisUser.RealName,Caps(ThisUser.Name)));  (* Was AllCaps Name and force real name missing *)
  WriteLn(DoorFile,ThisUser.SL);
  WriteLn(DoorFile,(NSL DIV 60));
  WriteLn(DoorFile,ShowEmulation);  (* Was "1" *)
  WriteLn(DoorFile,ThisNode);
  Close(DoorFile);
END;

(*
COM1:             <-- Comm Port - COM0: = LOCAL MODE
2400              <-- Baud Rate - 300 to 38400
8                 <-- Parity - 7 or 8
1                 <-- Node Number - 1 to 99                    (Default to 1)
19200             <-- DTE Rate. Actual BPS rate to use. (kg)
Y                 <-- Screen Display - Y=On  N=Off             (Default to Y)
Y                 <-- Printer Toggle - Y=On  N=Off             (Default to Y)
Y                 <-- Page Bell      - Y=On  N=Off             (Default to Y)
Y                 <-- Caller Alarm   - Y=On  N=Off             (Default to Y)
Rick Greer        <-- User Full Name
Lewisville, Tx.   <-- Calling From
214 221-7814      <-- Home Phone
214 221-7814      <-- Work/Data Phone
PASSWORD          <-- Password
110              *<-- Security Level
1456              <-- Total Times On
03/14/88          <-- Last Date Called
7560              <-- Seconds Remaining THIS call (for those that particular)
126               <-- Minutes Remaining THIS call
GR                <-- Graphics Mode - GR=Graph, NG=Non-Graph, 7E=7,E Caller
23                <-- Page Length
Y                 <-- User Mode - Y = Expert, N = Novice
1,2,3,4,5,6,7     <-- Conferences/Forums Registered In  (ABCDEFG)
7                 <-- Conference Exited To \cf1\f1 DOOR\cf0  From    (G)
01/01/99          <-- User Expiration Date              (mm/dd/yy)
1                 <-- User File's Record Number
Y                 <-- Default Protocol - X, C, Y, G, I, N, Etc.
0                *<-- Total Uploads
0                *<-- Total Downloads
0                *<-- Daily Download "K" Total
999999            <-- Daily Download Max. "K" Limit
10/22/88          <-- Caller's Birthdate                              (kg)
G:\\GAP\\MAIN       <-- Path to the MAIN directory (where User File is) (kg)
G:\\GAP\\GEN        <-- Path to the GEN directory                       (kg)
Michael           <-- Sysop's Name (name \cf1 BBS\cf0  refers to Sysop as)      (kg)
Stud              <-- Alias name                                      (rc)
00:05             <-- Event time                        (hh:mm)       (rc)
Y                 <-- If its an error correcting connection (Y/N)     (rc)
N                 <-- ANSI supported & caller using NG mode (Y/N)     (rc)
Y                 <-- Use Record Locking                    (Y/N)     (rc)
14                <-- \cf1 BBS\cf0  Default Color (Standard IBM color code, ie, 1-15) (rc)
10               *<-- Time Credits In Minutes (positive/negative)     (rc)
07/07/90          <-- Last New \cf1 Files\cf0  Scan Date          (mm/dd/yy)    (rc)
14:32             <-- Time of This Call                 (hh:mm)       (rc)
07:30             <-- Time of Last Call                 (hh:mm)       (rc)
6                 <-- Maximum daily \cf1 files\cf0  available                   (rc)
3                *<-- \cf1 Files\cf0  d/led so far today                        (rc)
23456            *<-- Total "K" Bytes Uploaded                        (rc)
76329            *<-- Total "K" Bytes Downloaded                      (rc)
A File Sucker     <-- User Comment                                    (rc)
10                <-- Total Doors Opened                              (rc)
10283             <-- Total Messages Left                             (rc)
*)

PROCEDURE Write_Door_Sys(RName: Boolean);
VAR
  DoorFile: Text;

  FUNCTION ShowEmulation: AStr;
  BEGIN
    IF (OkRIP) THEN
      ShowEmulation := 'RIP'
    ELSE IF (OkANSI OR OKAvatar) THEN
      ShowEmulation := 'GR'
    ELSE
      ShowEmulation := 'NG';
  END;

BEGIN
  Assign(DoorFile,Liner.DoorPath+'DOOR.SYS');
  ReWrite(DoorFile);
  WriteLn(DoorFile,'COM'+AOnOff((ComPortSpeed = 0),'0',IntToStr(Liner.Comport))+':');
  WriteLn(DoorFile,ActualSpeed);
  WriteLn(DoorFile,'8');
  WriteLn(DoorFile,ThisNode);
  WriteLn(DoorFile,ComPortSpeed);
  WriteLn(DoorFile,Copy(ShowYesNo(WantOut),1,1));
  WriteLn(DoorFile,'N');
  WriteLn(DoorFile,Copy(ShowYesNo(SysOpAvailable),1,1));
  WriteLn(DoorFile,Copy(ShowYesNo(Alert IN ThisUser.Flags),1,1));
  WriteLn(DoorFile,AOnOff(RName,ThisUser.RealName,Caps(ThisUser.Name)));  (* ThisUser.Name Was All Caps *)
  WriteLn(DoorFile,ThisUser.CityState);
  WriteLn(DoorFile,Copy(ThisUser.Ph,1,3)+' '+Copy(ThisUser.Ph,5,8));
  WriteLn(DoorFile,Copy(ThisUser.Ph,1,3)+' '+Copy(ThisUser.Ph,5,8));
  WriteLn(DoorFile,'PASSWORD');
  WriteLn(DoorFile,ThisUser.SL);
  WriteLn(DoorFile,ThisUser.LoggedOn);
  WriteLn(DoorFile,DoorToDate8(PD2Date(ThisUser.LastOn)));  (* Used - vice / for separator *)
  WriteLn(DoorFile,NSL);
  WriteLn(DoorFile,(NSL DIV 60));
  WriteLn(DoorFile,ShowEmulation);
  WriteLn(DoorFile,ThisUser.PageLen);
  WriteLn(DoorFile,Copy(ShowYesNo(Novice IN ThisUser.Flags),1,1));
  WriteLn(DoorFile,ShowConferences); (* Was AR Flags *)
  WriteLn(DoorFile,ThisUser.LastConf);  (* Was 7 *)
  WriteLn(DoorFile,DoorToDate8(PD2Date(ThisUser.Expiration)));  (* Was 12/31/99 *)
  WriteLn(DoorFile,UserNum);
  WriteLn(DoorFile,'Z');
  WriteLn(DoorFile,ThisUser.Uploads);
  WriteLn(DoorFile,ThisUser.Downloads);
  WriteLn(DoorFile,ThisUser.DLKToday);
  WriteLn(DoorFile,General.DLKOneDay[ThisUser.SL]);  (* Was 999999 *)
  WriteLn(DoorFile,DoorToDate8(PD2Date(ThisUser.BirthDate))); (* Used - vice / for separator *)
  WriteLn(DoorFile,General.DataPath);  (* Was "\" *)
  WriteLn(DoorFile,General.DataPath);  (* Was "\" *)
  WriteLn(DoorFile,General.SysOpName);
  WriteLn(DoorFile,Caps(ThisUser.Name));

  (* Fix - Event Time *)
  WriteLn(DoorFile,'00:00');

  WriteLn(DoorFile,Copy(ShowYesNo(Reliable),1,1));
  WriteLn(DoorFile,Copy(ShowYesNo(ANSIDetected AND (ShowEmulation = 'NG')),1,1));  (* Was 'N'*)
  WriteLn(DoorFile,Copy(ShowYesNo(General.MultiNode),1,1));

  (* Fix - Default User Color *)
  WriteLn(DoorFile,'3');

  (* Fix - Time Credits In Minutes (Positive/Negative *)
  WriteLn(DoorFile,'0');

  WriteLn(DoorFile,DoorToDate8(PD2Date(NewFileDate))); (* Used - vice / for separator *)
  WriteLn(DoorFile,PD2Time24(TimeOn));  (* Was TimeStr *)
  WriteLn(DoorFile,PD2Time24(ThisUser.LastOn));  (* Was 00:00 *)
  WriteLn(DoorFile,General.DLOneDay[ThisUser.SL]);
  WriteLn(DoorFile,ThisUser.DLToday);
  WriteLn(DoorFile,ThisUser.UK);
  WriteLn(DoorFile,ThisUser.DK);
  WriteLn(DoorFile,ThisUser.Note);

  (* Fix - Total Doors Opened *)
  WriteLn(DoorFile,'0');

  (* Fix - Total Messages Left *)
  WriteLn(DoorFile,'0');  (* Was 10 *)

  Close(DoorFile);
  LastError := IOResult;
END;

(*
1                                 User number
MRBILL                            User alias
Bill                              User real name
                                  User callsign (HAM radio)
21                                User age
M                                 User sex
  16097.00                        User gold
05/19/89                          User last logon date
80                                User colums
25                                User width
255                               User security level (0-255)
1                                 1 if Co-SysOp, 0 if not
1                                 1 if SysOp, 0 if not
1                                 1 if ANSI, 0 if not
0                                 1 if at remote, 0 if local console
   2225.78                        User number of seconds left till logoff
F:\WWIV\GFILES\                   System GFILES directory (gen. txt files)
F:\WWIV\DATA\                     System DATA directory
890519.LOG                        System log of the day
2400                              User baud rate
2                                 System com port
MrBill's Abode (the original)     System name
The incredible inedible MrBill    System SysOp
83680                             Time user logged on/# of secs. from midn.
554                               User number of seconds on system so far
5050                              User number of uploaded k
22                                User number of uploads
42                                User amount of downloaded k
1                                 User number of downloads
8N1                               User parity
2400                              Com port baud rate
7400                              WWIVnet node number
*)

PROCEDURE Write_Chain_Txt(RName: Boolean);
VAR
  DoorFile: Text;
  TUsed: LongInt;
BEGIN
  Assign(DoorFile,Liner.DoorPath+'CHAIN.TXT');
  ReWrite(DoorFile);
  WriteLn(DoorFile,UserNum);
  WriteLn(DoorFile,AOnOff(RName,ThisUser.RealName,Caps(ThisUser.Name)));  (* Was AllCaps Name and force real name missing *)
  WriteLn(DoorFile,ThisUser.RealName);
  WriteLn(DoorFile,'');
  WriteLn(DoorFile,AgeUser(ThisUser.BirthDate));
  WriteLn(DoorFile,ThisUser.Sex);

  (* What is gold ??? *)
  WriteLn(DoorFile,'00.00');

  WriteLn(DoorFile,DoorToDate8(PD2Date(ThisUser.LastOn)));   (* Used "-" vice "/" *)
  WriteLn(DoorFile,ThisUser.LineLen);
  WriteLn(DoorFile,ThisUser.PageLen);
  WriteLn(DoorFile,ThisUser.SL);
  WriteLn(DoorFile,AOnOff(CoSysOp,'1','0'));  (* Was Sysop *)
  WriteLn(DoorFile,AOnOff(SysOp,'1','0'));  (* Was CoSysOp *)
  WriteLn(DoorFile,AOnOff((OkANSI OR OKAvatar),'1','0'));
  WriteLn(DoorFile,AOnOff(InCom,'1','0'));
  WriteLn(DoorFile,NSL);
  WriteLn(DoorFile,General.DataPath);
  WriteLn(DoorFile,General.DataPath);
  WriteLn(DoorFile,General.LogsPath+'SYSOP.LOG');  (* Was missing path to the LOG *)
  WriteLn(DoorFile,ComPortSpeed);
  WriteLn(DoorFile,AOnOff((ComportSpeed = 0),'0',IntToStr(Liner.ComPort))); (* Was Liner.ComPort *)
  WriteLn(DoorFile,StripColor(General.BBSName));
  WriteLn(DoorFile,General.SysOpName);

  (* Fix - Time user logged on/# of secs. from midnight *)
  WriteLn(DoorFile,(GetPackDateTime - TimeOn));

  (* Fix - User number of seconds on system so far *)
  WriteLn(DoorFile,TUsed);

  WriteLn(DoorFile,ThisUser.UK);
  WriteLn(DoorFile,ThisUser.Uploads);
  WriteLn(DoorFile,ThisUser.DK);
  WriteLn(DoorFile,ThisUser.Downloads);
  WriteLn(DoorFile,'8N1');

  (* Fix - Com port baud rate *)
  WriteLn(DoorFile,'');    (* Line was missing *)

  WriteLn(DoorFile,'0');   (* Line was missing *)
  Close(DoorFile);
  LastError := IOResult;
END;

(*

User's Name               The name of the currently logged in user, with all color codes removed.
Speed                     The number 0 for 2400 baud, 1 for 300 baud, 2 for 1200 baud, 3 for 9600 baud, or 5 for console or
                            other speed.
City                      The last line of the user's mailing address that has data in it, or blank if no lines have data.
Security Level            The number 5 for problem users, 30 for normal users, 80 for Aides, and 100 for Sysops.
Time left                 The time left in the user's accounts, in minutes. In an attempt to keep from overflowing other
                            software's limits, no value larger than 546 minutes is written.
ANSI Color                The word "COLOR" if the current user has ANSI color enabled or "MONO" if he does not.
Password                  The current user's password (but not initials).
Userlog Number            The current user's slot in LOG.DAT. (Not that this means anything to Citadel.)
Time used                 The number of minutes this call has lasted. If there is no user logged in, the number 0.
Unknown                   Citadel writes nothing out. Our information lists this field as being "01:23".
Unknown                   Citadel writes nothing out. Our information lists this field as being "01:23 01/02/90".
Unknown                   Citadel writes nothing out. Our information lists this field as being "ABCDEFGH".
Unknown                   Citadel writes nothing out. Our information lists this field as being "0".
Unknown                   Citadel writes nothing out. Our information lists this field as being "99".
Unknown                   Citadel writes nothing out. Our information lists this field as being "0".
Unknown                   Citadel writes nothing out. Our information lists this field as being "9999".
Phone number              The current user's phone number.
Unknown                   Citadel writes nothing out. Our information lists this field as being "01/01/90 02:34".
Expert                    The word "EXPERT" if helpful hints are turned off or "NOVICE" if they are on.
File transfer protocol    The name of the user's default file transfer protocol, or a blank line if none is specified.
Unknown                   Citadel writes nothing out. Our information lists this field as being "01/01/90".
Times on                  The number of times the current user has logged onto the system.
Lines per screen          The number of lines per screen, or 0 if the current user has screen pause turned off.
Last message read         The new message pointer for the current room.
Total uploads             The total number of files the user has uploaded.
Total downloads           The total number of files the user has downloaded.
Excessively Stupid!!!     The text "8  { Databits }". (There are two spaces between the "8" and the "{".)
User's location           The text "LOCAL if logged in on console, or "REMOTE" if logged in over the modem.
Port                      The text "COM" followed by the serial port number of the modem. (For example, "COM1" if the modem is
                            on the first serial port.)
Speed                     The number 0 for 2400 baud, 1 for 300 baud, 2 for 1200 baud, 3 for 9600 baud, or 5 for other speed.
                            No attention is paid to whether the user is on console or not.
Unknown                   Citadel writes nothing out. Our information lists this field as being "FALSE".
Another stupid thing      The text "Normal Connection".
Unknown                   Citadel writes nothing out. Our information lists this field as being "01/02/94 01:20".
Task number               Citadel writes the number 0.
Door number               Citadel writes the number 1.
*)

PROCEDURE Write_CallInfo_BBS(RName: Boolean);
VAR
  DoorFile: Text;

  FUNCTION ShowSpeed: AStr;
  BEGIN
    IF (ComPortSpeed = 300) THEN
      ShowSpeed := '1'
    ELSE IF (ComPortSpeed = 1200) THEN
      ShowSpeed := '2'
    ELSE IF (ComPortSpeed = 2400) THEN
      ShowSpeed := '0'
    ELSE IF (ComPortSpeed = 9600) THEN
      ShowSpeed := '3'
    ELSE IF (ComPortSpeed = 0) THEN
      ShowSpeed := '5'
    ELSE
      ShowSpeed := '4';
  END;

BEGIN
  Assign(DoorFile,Liner.DoorPath+'CALLINFO.BBS');
  ReWrite(DoorFile);
  WITH ThisUser DO
  BEGIN
    WriteLn(DoorFile,AOnOff(RName,AllCaps(ThisUser.RealName),AllCaps(ThisUser.Name)));
    WriteLn(DoorFile,ShowSpeed);
    WriteLn(DoorFile,AllCaps(ThisUser.CityState));
    WriteLn(DoorFile,ThisUser.SL);
    WriteLn(DoorFile,NSL DIV 60);
    WriteLn(DoorFile,AOnOff((OkANSI OR OKAvatar),'COLOR','MONO'));
    WriteLn(DoorFile,'PASSWORD');
    WriteLn(DoorFile,UserNum);
    WriteLn(DoorFile,'0');
    WriteLn(DoorFile,Copy(TimeStr,1,5));
    WriteLn(DoorFile,Copy(TimeStr,1,5)+' '+DateStr);
    WriteLn(DoorFile,'A');
    WriteLn(DoorFile,'0');
    WriteLn(DoorFile,'999999');
    WriteLn(DoorFile,'0');
    WriteLn(DoorFile,'999999');
    WriteLn(DoorFile,ThisUser.Ph);
    WriteLn(DoorFile,ToDate8(PD2Date(ThisUser.LastOn))+' 00:00');
    WriteLn(DoorFile,AOnOff((Novice IN ThisUser.Flags),'NOVICE','EXPERT'));
    WriteLn(DoorFile,'All');
    WriteLn(DoorFile,'01/01/80');
    WriteLn(DoorFile,ThisUser.LoggedOn);
    WriteLn(DoorFile,ThisUser.PageLen);
    WriteLn(DoorFile,'0');
    WriteLn(DoorFile,ThisUser.Uploads);
    WriteLn(DoorFile,ThisUser.Downloads);
    WriteLn(DoorFile,'8  { Databits }');
    WriteLn(DoorFile,AOnOff((InCom OR OutCom),'REMOTE','LOCAL'));
    WriteLn(DoorFile,'COM'+AOnOff((InCom OR OutCom),IntToStr(Liner.Comport),'0'));
    WriteLn(DoorFile,PD2Date(ThisUser.BirthDate));
    WriteLn(DoorFile,ComPortSpeed);
    WriteLn(DoorFile,AOnOff((InCom OR OutCom),'TRUE','FALSE'));
    WriteLn(DoorFile,AOnOff(Reliable,'MNP/ARQ','Normal')+' Connection');
    WriteLn(DoorFile,'12/31/99 23:59');
    WriteLn(DoorFile,ThisNode);
    WriteLn(DoorFile,'1');
  END;
  Close(DoorFile);
  LastError := IOResult;
END;

PROCEDURE Write_SFDoors_Dat(RName: Boolean);
VAR
  DoorFile: Text;
  S: AStr;
BEGIN
  Assign(DoorFile,Liner.DoorPath+'SFDOORS.DAT');
  ReWrite(DoorFile);
  WriteLn(DoorFile,UserNum);
  WriteLn(DoorFile,AOnOff(RName,AllCaps(ThisUser.RealName),AllCaps(ThisUser.Name)));
  WriteLn(DoorFile,'PASSWORD');
  IF (RName) THEN
  BEGIN
    IF (Pos(' ',ThisUser.RealName) = 0) THEN
      S := ThisUser.RealName
    ELSE
      S := Copy(ThisUser.RealName,1,(Pos(' ',ThisUser.RealName) - 1));
  END
  ELSE
  BEGIN
    IF (Pos(' ',ThisUser.Name) = 0) THEN
      S := ThisUser.Name
    ELSE
      S := Copy(ThisUser.Name,1,(Pos(' ',ThisUser.Name) - 1));
  END;
  WriteLn(DoorFile,S);
  WriteLn(DoorFile,ComPortSpeed);
  WriteLn(DoorFile,AOnOff((ComPortSpeed = 0),'0',IntToStr(Liner.Comport)));
  WriteLn(DoorFile,NSL DIV 60);
  WriteLn(DoorFile,Timer);   { seconds since midnight }
  WriteLn(DoorFile,StartDir);
  WriteLn(DoorFile,AOnOff((OkANSI OR OKAvatar),'TRUE','FALSE'));
  WriteLn(DoorFile,ThisUser.SL);
  WriteLn(DoorFile,ThisUser.Uploads);
  WriteLn(DoorFile,ThisUser.Downloads);
  WriteLn(DoorFile,General.TimeAllow[ThisUser.SL]);
  WriteLn(DoorFile,'0');   { time on (seconds) }
  WriteLn(DoorFile,'0');   { extra time (seconds) }
  WriteLn(DoorFile,'FALSE');
  WriteLn(DoorFile,'FALSE');
  WriteLn(DoorFile,'FALSE');
  WriteLn(DoorFile,Liner.InitBaud);
  WriteLn(DoorFile,AOnOff(Reliable,'TRUE','FALSE'));
  WriteLn(DoorFile,'A');
  WriteLn(DoorFile,'A');
  WriteLn(DoorFile,ThisNode);
  WriteLn(DoorFile,General.DLOneDay[ThisUser.SL]);
  WriteLn(DoorFile,ThisUser.DLToday);
  WriteLn(DoorFile,General.DLKOneDay[ThisUser.SL]);
  WriteLn(DoorFile,ThisUser.DLKToday);
  WriteLn(DoorFile,ThisUser.UK);
  WriteLn(DoorFile,ThisUser.DK);
  WriteLn(DoorFile,ThisUser.Ph);
  WriteLn(DoorFile,ThisUser.CityState);
  WriteLn(DoorFile,General.TimeAllow[ThisUser.SL]);
  Close(DoorFile);
  LastError := IOResult;
END;

PROCEDURE DoDoorFunc(DropFileType: Char; MenuOption: Str50);
VAR
  Answer: AStr;
  ReturnCode: Integer;
  DoorTime: LongInt;
  UseRealName: Boolean;
BEGIN
  IF (MenuOption = '') AND (InCom) THEN
    Exit;
  SaveURec(ThisUser,UserNum);
  UseRealName := FALSE;
  IF (Copy(AllCaps(MenuOption),1,2) = 'R;') THEN
  BEGIN
    UseRealName := TRUE;
    MenuOption := Copy(MenuOption,3,(Length(MenuOption) - 2));
  END;
  Answer := FunctionalMCI(MenuOption,'','');
  CASE DropFileType OF
    '3' : BEGIN
            lStatus_Screen(100,'Outputting DOOR32.SYS ...',FALSE,Answer);
            Write_Door32_Sys(UseRealName);
          END;
    'P' : BEGIN
            lStatus_Screen(100,'Outputting PCBOARD.SYS ...',FALSE,Answer);
            Write_PCBoard_Sys(UseRealName);
          END;
    'C' : BEGIN
            lStatus_Screen(100,'Outputting CHAIN.TXT ...',FALSE,Answer);
            Write_Chain_Txt(UseRealName);
          END;
    'D' : BEGIN
            lStatus_Screen(100,'Outputting DORINFO1.DEF ...',FALSE,Answer);
            Write_DorInfo1_Def(UseRealName);
          END;
    'G' : BEGIN
            lStatus_Screen(100,'Outputting DOOR.SYS ...',FALSE,Answer);
            Write_Door_Sys(UseRealName);
          END;
    'S' : BEGIN
            lStatus_Screen(100,'Outputting SFDOORS.DAT ...',FALSE,Answer);
            Write_SFDoors_Dat(UseRealName);
          END;
    'W' : BEGIN
            lStatus_Screen(100,'Outputting CALLINFO.BBS ...',FALSE,Answer);
            Write_CallInfo_BBS(UseRealName);
          END;
  END;
  IF (Answer = '') THEN
    Exit;
  Shel('Running "'+Answer+'"');
  SysOpLog('Opened door '+Answer+' on '+DateStr+' at '+TimeStr);

  IF (General.MultiNode) THEN
  BEGIN
    LoadNode(ThisNode);
    SaveNAvail := (NAvail IN NodeR.Status);
    Exclude(NodeR.Status,NAvail);
    SaveNode(ThisNode);
  END;

  DoorTime := GetPackDateTime;
  ShellDos(FALSE,Answer,ReturnCode);
  DoorTime := (GetPackDateTime - DoorTime);
  Shel2(FALSE);

  IF (General.MultiNode) THEN
  BEGIN
    LoadNode(ThisNode);
    IF (SaveNAvail) THEN
      Include(NodeR.Status,NAvail);
    SaveNode(ThisNode);
  END;

  NewCompTables;
  SaveGeneral(TRUE);
  LoadURec(ThisUser,UserNum);
  LoadFileArea(FileArea);
  LoadMsgArea(MsgArea);
  ChDir(StartDir);
  Com_Flush_Recv;
  SysOpLog('Returned on '+DateStr+' at '+TimeStr+'. Spent '+FormattedTime(DoorTime));
END;

END.
