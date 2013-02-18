{$IFDEF WIN32}
{$I DEFINES.INC}
{$ENDIF}

{$A+,B-,D+,E-,F+,I-,L+,N-,O+,R-,S+,V-}

UNIT Mail0;

INTERFACE

USES
  Common;

FUNCTION CompMsgArea(MArea: Integer; ArrayNum: Byte): Integer;
FUNCTION UseName(AnonNum: Byte; NameToUse: Str36): Str36;
PROCEDURE UpdateBoard;
PROCEDURE ExtractMsgToFile(MsgNum: Word; MHeader: MheaderRec);
PROCEDURE DumpQuote(MHeader: MHeaderRec);
PROCEDURE LoadHeader(MsgNum: Word; VAR MHeader: MHeaderRec);
PROCEDURE SaveHeader(MsgNum: Word; MHeader: MHeaderRec);
FUNCTION MsgAreaAC(MArea: Integer): Boolean;
PROCEDURE ChangeMsgArea(MArea: Integer);
PROCEDURE LoadMsgArea(MArea: Integer);
PROCEDURE LoadLastReadRecord(VAR LastReadRec: ScanRec);
PROCEDURE SaveLastReadRecord(LastReadRec: ScanRec);
PROCEDURE InitMsgArea(MArea: Integer);
PROCEDURE ReadMsg(Anum,MNum,TNum: Word);
FUNCTION HeaderLine(MHeader: MHeaderRec; MNum,TNum: Word; Line: byte; VAR FileOwner: Str36): STRING;
FUNCTION ToYou(MessageHeader: MHeaderRec): Boolean;
FUNCTION FromYou(MessageHeader: MHeaderRec): Boolean;
FUNCTION GetTagLine: Str74;

IMPLEMENTATION

USES
  Dos,
  File0,
  File1,
  Shortmsg,
  TimeFunc;

TYPE
  MHeaderRecPtrType = ^MHeaderRec;

FUNCTION CompMsgArea(MArea: Integer; ArrayNum: Byte): Integer;
VAR
  MsgCompArrayFile: FILE OF CompArrayType;
  CompMsgArray: CompArrayType;
BEGIN
  Assign(MsgCompArrayFile,TempDir+'MACT'+IntToStr(ThisNode)+'.DAT');
  Reset(MsgCompArrayFile);
  Seek(MsgCompArrayFile,(MArea - 1));
  Read(MsgCompArrayFile,CompMsgArray);
  Close(MsgCompArrayFile);
  CompMsgArea := CompMsgArray[ArrayNum];
END;

FUNCTION UseName(AnonNum: Byte; NameToUse: Str36): Str36;
BEGIN
  CASE AnonNum OF
    1,2 :
        NameToUse := lRGLNGStr(0,TRUE); {FString.Anonymous;}
    3 : NameToUse := 'Abby';
    4 : NameToUse := 'Problemed Person';
    ELSE
      NameToUse := Caps(NameToUse);
  END;
  UseName := NameToUse;
END;

FUNCTION FromYou(MessageHeader: MHeaderRec): Boolean;
BEGIN
  FromYou := FALSE;
  IF (MessageHeader.From.UserNum = UserNum) OR
     (AllCaps(MessageHeader.From.A1S) = ThisUser.Name) OR
     (AllCaps(MessageHeader.From.Name) = ThisUser.Name) OR
     (AllCaps(MessageHeader.From.A1S) = AllCaps(ThisUser.RealName)) THEN
    FromYou := TRUE;
END;

FUNCTION ToYou(MessageHeader: MHeaderRec): Boolean;
BEGIN
  ToYou := FALSE;
  IF (MessageHeader.MTO.UserNum = UserNum) OR
     (AllCaps(MessageHeader.MTO.A1S) = ThisUser.Name) OR
     (AllCaps(MessageHeader.MTO.Name) = ThisUser.Name) OR
     (AllCaps(MessageHeader.MTO.A1S) = AllCaps(ThisUser.RealName)) THEN
    ToYou := TRUE;
END;

PROCEDURE UpdateBoard;
VAR
  FO: Boolean;
BEGIN
  IF (ReadMsgArea < 1) OR (ReadMsgArea > NumMsgAreas) THEN
    Exit;
  FO := (FileRec(MsgAreaFile).Mode <> FMClosed);
  IF (NOT FO) THEN
  BEGIN
    Reset(MsgAreaFile);
    LastError := IOResult;
    IF (LastError > 0) THEN
    BEGIN
      SysOpLog('MBASES.DAT/Open Error - '+IntToStr(LastError)+' (Procedure: UpDateBoard - '+IntToStr(ReadMsgArea)+')');
      Exit;
    END;
  END;
  Seek(MsgAreaFile,(ReadMsgArea - 1));
  LastError := IOResult;
  IF (LastError > 0) THEN
  BEGIN
    SysOpLog('MBASES.DAT/Seek Error - '+IntToStr(LastError)+' (Procedure: UpDateBoard - '+IntToStr(ReadMsgArea)+')');
    Exit;
  END;
  Read(MsgAreaFile,MemMsgArea);
  LastError := IOResult;
  IF (LastError > 0) THEN
  BEGIN
    SysOpLog('MBASES.DAT/Read Error - '+IntToStr(LastError)+' (Procedure: UpDateBoard - '+IntToStr(ReadMsgArea)+')');
    Exit;
  END;
  Include(MemMsgArea.MAFlags,MAScanOut);
  Seek(MsgAreaFile,(ReadMsgArea - 1));
  LastError := IOResult;
  IF (LastError > 0) THEN
  BEGIN
    SysOpLog('MBASES.DAT/Seek Error - '+IntToStr(LastError)+' (Procedure: UpDateBoard - '+IntToStr(ReadMsgArea)+')');
    Exit;
  END;
  Write(MsgAreaFile,MemMsgArea);
  LastError := IOResult;
  IF (LastError > 0) THEN
  BEGIN
    SysOpLog('MBASES.DAT/Write Error - '+IntToStr(LastError)+' (Procedure: UpDateBoard - '+IntToStr(ReadMsgArea)+')');
    Exit;
  END;
  IF (NOT FO) THEN
  BEGIN
    Close(MsgAreaFile);
    LastError := IOResult;
    IF (LastError > 0) THEN
    BEGIN
      SysOpLog('MBASES.DAT/Close Error - '+IntToStr(LastError)+' (Procedure: UpDateBoard - '+IntToStr(ReadMsgArea)+')');
      Exit;
    END;
  END;
END;

PROCEDURE LoadHeader(MsgNum: Word; VAR MHeader: MHeaderRec);
VAR
  FO: Boolean;
BEGIN
  FO := FileRec(MsgHdrF).Mode <> FMClosed;
  IF (NOT FO) THEN
  BEGIN
    Reset(MsgHdrF);
    IF (IOResult = 2) THEN
    BEGIN
      ReWrite(MsgHdrF);
      LastError := IOResult;
      IF (LastError > 0) THEN
      BEGIN
       SysOpLog(MemMsgArea.FileName+'/ReWrite Error - '+IntToStr(LastError)+' (Procedure: LoadHeader - '+IntToStr(MsgNum)+')');
        Exit;
      END;
    END;
  END;
  Seek(MsgHdrF,(MsgNum - 1));
  LastError := IOResult;
  IF (LastError > 0) THEN
  BEGIN
    SysOpLog(MemMsgArea.FileName+'/Seek Error - '+IntToStr(LastError)+' (Procedure: LoadHeader - '+IntToStr(MsgNum)+')');
    Exit;
  END;
  Read(MsgHdrF,MHeader);
  LastError := IOResult;
  IF (LastError > 0) THEN
  BEGIN
    SysOpLog(MemMsgArea.FileName+'/Read Error - '+IntToStr(LastError)+' (Procedure: LoadHeader - '+IntToStr(MsgNum)+')');
    Exit;
  END;
  IF (NOT FO) THEN
  BEGIN
    Close(MsgHdrF);
    LastError := IOResult;
    IF (LastError > 0) THEN
    BEGIN
      SysOpLog(MemMsgArea.FileName+'/Close Error - '+IntToStr(LastError)+' (Procedure: LoadHeader - '+IntToStr(MsgNum)+')');
      Exit;
    END;
  END;
  LastError := IOResult;
END;

PROCEDURE SaveHeader(MsgNum: Word; MHeader: MHeaderRec);
VAR
  FO: Boolean;
BEGIN
  FO := FileRec(MsgHdrF).Mode <> FMClosed;
  IF (NOT FO) THEN
  BEGIN
    Reset(MsgHdrF);
    IF (IOResult = 2) THEN
    BEGIN
      ReWrite(MsgHdrF);
      LastError := IOResult;
      IF (LastError > 0) THEN
      BEGIN
        SysOpLog(MemMsgArea.FileName+'/ReWrite Error - '+IntToStr(LastError)+
                 '(Procedure: SaveHeader - '+IntToStr(MsgNum)+')');
        Exit;
      END;
    END;
  END;
  Seek(MsgHdrF,(MsgNum - 1));
  LastError := IOResult;
  IF (LastError > 0) THEN
  BEGIN
    SysOpLog(MemMsgArea.FileName+'/Seek Error - '+IntToStr(LastError)+' (Procedure: SaveHeader - '+IntToStr(MsgNum)+')');
    Exit;
  END;
  Write(MsgHdrF,MHeader);
  LastError := IOResult;
  IF (LastError > 0) THEN
  BEGIN
    SysOpLog(MemMsgArea.FileName+'/Write Error - '+IntToStr(LastError)+' (Procedure: SaveHeader - '+IntToStr(MsgNum)+')');
    Exit;
  END;
  IF (NOT FO) THEN
  BEGIN
    Close(MsgHdrF);
    LastError := IOResult;
    IF (LastError > 0) THEN
    BEGIN
      SysOpLog(MemMsgArea.FileName+'/Close Error - '+IntToStr(LastError)+' (Procedure: SaveHeader - '+IntToStr(MsgNum)+')');
      Exit;
    END;
  END;
  LastError := IOResult;
END;

FUNCTION MsgAreaAC(MArea: Integer): Boolean;
BEGIN
  MsgAreaAC := FALSE;
  IF (MArea <> -1) THEN
    IF (MArea < 1) OR (MArea > NumMsgAreas) THEN
      Exit;
  LoadMsgArea(MArea);
  MsgAreaAC := AACS(MemMsgArea.ACS);
END;

PROCEDURE ChangeMsgArea(MArea: Integer);
VAR
  TempPassword: Str20;
BEGIN
  IF (MArea < 1) OR (MArea > NumMsgAreas) OR (NOT MsgAreaAC(MArea)) THEN
    Exit;
  IF (MemMsgArea.Password <> '') THEN
  BEGIN
    NL;
    Print('Message area: ^5'+MemMsgArea.Name+' #'+IntToStr(CompMsgArea(MArea,0))+'^1');
    NL;
    Prt('Password: ');
    GetPassword(TempPassword,20);
    IF (TempPassword <> MemMsgArea.Password) THEN
    BEGIN
      NL;
      Print('^7Incorrect password!^1');
      Exit;
    END;
  END;
  MsgArea := MArea;
  ThisUser.LastMsgArea := MsgArea;
END;

PROCEDURE LoadMsgArea(MArea: Integer);
VAR
  FO: Boolean;
BEGIN
  IF (MArea = -1) THEN
  BEGIN
    Assign(EmailFile,General.DataPath+'MEMAIL.DAT');
    Reset(EmailFile);
    Read(EmailFile,MemMsgArea);
    Close(EmailFile);
    ReadMsgArea := -1;
    WITH LastReadRecord DO
    BEGIN
      LastRead := 0;
      NewScan := TRUE;
    END;
  END;
  IF (MArea < 1) OR (MArea > NumMsgAreas) OR (ReadMsgArea = MArea) THEN
    Exit;
  FO := (FileRec(MsgAreaFile).Mode <> FMClosed);
  IF (NOT FO) THEN
  BEGIN
    Reset(MsgAreaFile);
    LastError := IOResult;
    IF (LastError > 0) THEN
    BEGIN
      SysOpLog('MBASES.DAT/Open Error - '+IntToStr(LastError)+' (Procedure: LoadMsgArea - '+IntToStr(MArea)+')');
      Exit;
    END;
  END;
  Seek(MsgAreaFile,(MArea - 1));
  LastError := IOResult;
  IF (LastError > 0) THEN
  BEGIN
    SysOpLog('MBASES.DAT/Seek Error - '+IntToStr(LastError)+' (Procedure: LoadMsgArea - '+IntToStr(MArea)+')');
    Exit;
  END;
  Read(MsgAreaFile,MemMsgArea);
  LastError := IOResult;
  IF (LastError > 0) THEN
  BEGIN
    SysOpLog('MBASES.DAT/Read Error - '+IntToStr(LastError)+' (Procedure: LoadMsgArea - '+IntToStr(MArea)+')');
    Exit;
  END
  ELSE
    ReadMsgArea := MArea;
  IF (NOT FO) THEN
  BEGIN
    Close(MsgAreaFile);
    LastError := IOResult;
    IF (LastError > 0) THEN
    BEGIN
      SysOpLog('MBASES.DAT/Close Error - '+IntToStr(LastError)+' (Procedure: LoadMsgArea - '+IntToStr(MArea)+')');
      Exit;
    END;
  END;
  LastError := IOResult;
END;

PROCEDURE LoadLastReadRecord(VAR LastReadRec: ScanRec);
VAR
  MsgAreaScanFile: FILE OF ScanRec;
  Counter: Integer;
BEGIN
  Assign(MsgAreaScanFile,General.MsgPath+MemMsgArea.FileName+'.SCN');
  Reset(MsgAreaScanFile);
  IF (IOResult = 2) THEN
    ReWrite(MsgAreaScanFile);
  IF (IOResult <> 0) THEN
  BEGIN
    SysOpLog('Error opening file: '+General.MsgPath+MemMsgArea.FileName+'.SCN');
    Exit;
  END;
  IF (UserNum > FileSize(MsgAreaScanFile)) THEN
  BEGIN
    WITH LastReadRec DO
    BEGIN
      LastRead := 0;
      NewScan := TRUE;
    END;
    Seek(MsgAreaScanFile,FileSize(MsgAreaScanFile));
    FOR Counter := FileSize(MsgAreaScanFile) TO (UserNum - 1) DO
      Write(MsgAreaScanFile,LastReadRec);
  END
  ELSE
  BEGIN
    Seek(MsgAreaScanFile,(UserNum - 1));
    Read(MsgAreaScanFile,LastReadRec);
  END;
  Close(MsgAreaScanFile);
  LastError := IOResult;
END;

PROCEDURE SaveLastReadRecord(LastReadRec: ScanRec);
VAR
  MsgAreaScanFile: FILE OF ScanRec;
BEGIN
  Assign(MsgAreaScanFile,General.MsgPath+MemMsgArea.FileName+'.SCN');
  Reset(MsgAreaScanFile);
  Seek(MsgAreaScanFile,(UserNum - 1));
  Write(MsgAreaScanFile,LastReadRec);
  Close(MsgAreaScanFile);
  LastError := IOResult;
END;

PROCEDURE InitMsgArea(MArea: Integer);
BEGIN
  LoadMsgArea(MArea);
  Assign(MsgHdrF,General.MsgPath+MemMsgArea.FileName+'.HDR');
  Reset(MsgHdrF);
  IF (IOResult = 2) THEN
    ReWrite(MsgHdrF);
  Close(MsgHdrF);
  Assign(MsgTxtF,General.MsgPath+MemMsgArea.FileName+'.DAT');
  Reset(MsgTxtF,1);
  IF (IOResult = 2) THEN
    ReWrite(MsgTxtF,1);
  Close(MsgTxtF);
  IF (MArea = -1) THEN
    Exit;
  LoadLastReadRecord(LastReadRecord);
END;

PROCEDURE DumpQuote(MHeader: MHeaderRec);
VAR
  QuoteFile: Text;
  DT: DateTime;
  S: STRING;
  S1: STRING[80];
  Counter: Byte;
  TempTextSize: Word;
BEGIN
  IF (MHeader.TextSize < 1) THEN
    Exit;

  Assign(QuoteFile,'TEMPQ'+IntToStr(ThisNode));
  ReWrite(QuoteFile);
  IF (IOResult <> 0) THEN
  BEGIN
    SysOpLog('^7Error creating file: ^5TEMPQ'+IntToStr(ThisNode)+'^1!');
    Exit;
  END;

  S := AOnOff(MARealName IN MemMsgArea.MAFlags,MHeader.From.Real,MHeader.From.A1S);

  FOR Counter := 1 TO 2 DO
  BEGIN

    IF (Counter = 1) THEN
      S1 := MemMsgArea.QuoteStart
    ELSE
      S1 := MemMsgArea.QuoteEnd;

    S1 := Substitute(S1,'@F',UseName(MHeader.From.Anon,S));

    S1 := Substitute(S1,'@T',UseName(MHeader.MTO.Anon,
                                     AOnOff(MARealName IN MemMsgArea.MAFlags,
                                     Caps(MHeader.MTO.Real),
                                     Caps(MHeader.MTO.A1S))));


    IF (MHeader.Origindate <> '') THEN
      S1 := Substitute(S1,'@D',MHeader.Origindate)
    ELSE
    BEGIN
      Packtodate(DT,MHeader.Date);
      S1 := Substitute(S1,'@D',IntToStr(DT.Day)+
                               ' '+Copy(MonthString[DT.Month],1,3)+
                               ' '+Copy(IntToStr(DT.Year),3,2)+
                               '  '+Zeropad(IntToStr(DT.Hour))+
                               ':'+Zeropad(IntToStr(DT.Min)));
    END;

    S1 := Substitute(S1,'@S',AOnOff(MHeader.FileAttached = 0,
                 Substitute(S1,'@S',MHeader.Subject),
                 Substitute(S1,'@S',StripName(MHeader.Subject))));

    S1 := Substitute(S1,'@B',MemMsgArea.Name);

    IF (S1 <> '') THEN
      WriteLn(QuoteFile,S1);
  END;

  WriteLn(QuoteFile);

  S1 := S[1];
  IF (Pos(' ',S) > 0) AND (Length(S) > Pos(' ',S)) THEN
    S1 := S1 + S[Pos(' ',S) + 1]
  ELSE IF (Length(S1) > 1) THEN
    S1 := S1 + S[2];
  IF (MHeader.From.Anon <> 0) THEN
    S1 := '';
  S1 := Copy(S1,1,2);

  Reset(MsgTxtF,1);
  Seek(MsgTxtF,(MHeader.Pointer - 1));
  TempTextSize := 0;
  REPEAT
    BlockRead(MsgTxtF,S[0],1);
    BlockRead(MsgTxtF,S[1],Ord(S[0]));
    LastError := IOResult;
    Inc(TempTextSize,Length(S) + 1);
    IF (Pos('> ',Copy(S,1,4)) > 0) THEN
      S := Copy(StripColor(S),1,78)
    ELSE
      S := Copy(S1+'> '+StripColor(S),1,78);
    WriteLn(QuoteFile,S);
  UNTIL (TempTextSize >= MHeader.TextSize);
  Close(QuoteFile);
  Close(MsgTxtF);
  LastError := IOResult;
END;

PROCEDURE ExtractMsgToFile(MsgNum: Word; MHeader: MHeaderRec);
VAR
  ExtTxtFile: Text;
  FileOwner: Str36;
  FileName: Str52;
  MsgTxtStr: STRING;
  Counter: Byte;
  TempTextSize: Word;
  StripColors: Boolean;
BEGIN
  NL;
  Print('Extract message to file:');
  Prt(': ');
  InputDefault(FileName,'MSG'+IntToStr(ThisNode)+'.TXT',52,[UpperOnly,NoLineFeed],TRUE);
  IF (FileName = '') THEN
  BEGIN
    NL;
    Print('Aborted!');
    Exit;
  END;
  NL;
  IF PYNQ('Are you sure? ',0,FALSE) THEN
  BEGIN
    NL;
    StripColors := PYNQ('Strip color codes from output? ',0,FALSE);

    Assign(ExtTxtFile,FileName);
    Append(ExtTxtFile);
    IF (IOResult = 2) THEN
    BEGIN
      ReWrite(ExtTxtFile);
      IF (IOResult <> 0) THEN
      BEGIN
        Print('^7Unable to create file: ^5'+FileName+'!^1');
        Exit;
      END;
    END;

    LoadHeader(MsgNum,MHeader);

    FOR Counter := 1 TO 6 DO
    BEGIN
      MsgTxtStr := HeaderLine(MHeader,MsgNum,HiMsg,Counter,FileOwner);
      IF (MsgTxtStr <> '') THEN
        IF (StripColors) THEN
          WriteLn(ExtTxtFile,StripColor(MsgTxtStr))
        ELSE
          WriteLn(ExtTxtFile,MsgTxtStr);
    END;

    WriteLn(ExtTxtFile);

    Reset(MsgTxtF,1);
    Seek(MsgTxtF,(MHeader.Pointer - 1));
    TempTextSize := 0;
    REPEAT
      BlockRead(MsgTxtF,MsgTxtStr[0],1);
      BlockRead(MsgTxtF,MsgTxtStr[1],Ord(MsgTxtStr[0]));
      LastError := IOResult;
      Inc(TempTextSize,(Length(MsgTxtStr) + 1));
      IF (StripColors) THEN
        MsgTxtStr := StripColor(MsgTxtStr);
      IF (MsgTxtStr[Length(MsgTxtStr)] = #29) THEN
      BEGIN
        Dec(MsgTxtStr[0]);
        Write(ExtTxtFile,MsgTxtStr);
      END
      ELSE
        WriteLn(ExtTxtFile,MsgTxtStr);
    UNTIL (TempTextSize >= MHeader.TextSize);
    WriteLn(ExtTxtFile);
    Close(ExtTxtFile);
    Close(MsgTxtF);
    NL;
    Print('Message extracted.');
  END;
  LastError := IOResult;
END;

FUNCTION MHeaderRecMCI(CONST S: ASTR; Data1,Data2: Pointer): STRING;
VAR
  MHeaderPtr: MHeaderRecPtrType;
  S1: STRING;
BEGIN
  MheaderPtr := Data1;
  MHeaderRecMCI := S;
  CASE S[1] OF
    'C' : CASE S[2] OF
            'A' : ;{TodaysCallerMCI := FormatNumber(LastCallerPtr^.Caller);}
          END;
  END;
END;

FUNCTION HeaderLine(MHeader: MHeaderRec; MNum,TNum: Word; Line: byte; VAR FileOwner: Str36): STRING;
VAR
  S,
  S1: STRING;
  Pub,
  SeeAnon: Boolean;
BEGIN
  Pub := (ReadMsgArea <> -1);

  IF (Pub) THEN
    SeeAnon := (AACS(General.AnonPubRead) OR MsgSysOp)
  ELSE
    SeeAnon := AACS(General.AnonPrivRead);

  IF (MHeader.From.Anon = 2) THEN
    SeeAnon := CoSysOp;

  S := '';

  CASE Line OF
    1 : BEGIN

          IF (MHeader.FileAttached > 0) THEN
            InResponseTo := StripName(MHeader.Subject)
          ELSE
            InResponseTo := Mheader.Subject;

          IF ((MHeader.From.Anon = 0) OR (SeeAnon)) THEN
            LastAuthor := MHeader.From.UserNum
          ELSE
            LastAuthor := 0;

          IF ((MHeader.From.Anon = 0) OR (SeeAnon)) THEN
            S := PDT2Dat(MHeader.Date,MHeader.DayOfWeek)
          ELSE
            S := '[Unknown]';

          S := '^1Date: ^9'+S;

          S := PadLeftStr(S,39)+'^1Number : ^9'+IntToStr(MNum)+'^1 of ^9'+IntToStr(TNum);
        END;
    2 : BEGIN
          IF (Pub) AND (MARealName IN MemMsgArea.MAFlags) THEN
            S1 := MHeader.From.Real
          ELSE
            S1 := MHeader.From.A1S;
          S := '^1From: ^5'+Caps(UseName(MHeader.From.Anon,S1));

          FileOwner := Caps(UseName(MHeader.From.Anon,S1));

          IF (NOT Pub) AND (Netmail IN MHeader.Status) THEN
          BEGIN
            S := S + '^2 ('+IntToStr(MHeader.From.Zone)+':'+IntToStr(MHeader.From.Net)+'/'+IntToStr(MHeader.From.Node);
            IF (MHeader.From.Point > 0) THEN
               S := S + '.'+IntToStr(MHeader.From.Point);
            S := S + ')';
          END;
          S := PadLeftStr(S,38)+'^1 Area   : ^5';

          IF (LennMCI(MemMsgArea.Name) > 30) THEN
            S := S + PadLeftStr(MemMsgArea.Name,30)
          ELSE
            S := S + MemMsgArea.Name;
        END;
    3 : BEGIN
          IF (Pub) AND (MARealName IN MemMsgArea.MAFlags) THEN
            S1 := Caps(MHeader.MTO.Real)
          ELSE
            S1 := Caps(MHeader.MTO.A1S);
          S := '^1To  : ^5'+UseName(MHeader.MTO.Anon,S1);
          IF (NOT Pub) AND (Netmail IN MHeader.Status) THEN
          BEGIN
            S := S + '^2 ('+IntToStr(MHeader.MTO.Zone)+':'+IntToStr(MHeader.MTO.Net)+'/'+IntToStr(MHeader.MTO.Node);
            IF (MHeader.MTO.Point > 0) THEN
              S := S + '.'+IntToStr(MHeader.MTO.Point);
            S := S + ')';
          END;
          S := PadLeftStr(S,38)+'^1 Refer #: ^5';
          IF (MHeader.Replyto > 0) AND (MHeader.Replyto < MNum) THEN
            S := S + IntToStr(MNum - MHeader.Replyto)
          ELSE
            S := S + 'None';
       END;
   4 : BEGIN
         S := '^1Subj: ';
         IF (MHeader.FileAttached = 0) THEN
           S := S + '^5'+MHeader.Subject
         ELSE
           S := S + '^8'+StripName(MHeader.Subject);
         S := PadLeftStr(S,38)+'^1 Replies: ^5';
         IF (MHeader.Replies <> 0) THEN
           S := S + IntToStr(MHeader.Replies)
         ELSE
           S := S + 'None';
       END;
   5 : BEGIN
         S := '^1Stat: ^';
         IF (MDeleted IN MHeader.Status) THEN
           S := S + '8Deleted'
         ELSE IF (Prvt IN MHeader.Status) THEN
           S := S + '8Private'
         ELSE IF (Pub) AND (UnValidated IN MHeader.Status) THEN
           S := S + '8Unvalidated'
         ELSE IF (Pub) AND (Permanent IN MHeader.Status) THEN
           S := S + '5Permanent'
         ELSE IF (MemMsgArea.MAType <> 0) THEN
           IF (Sent IN MHeader.Status) THEN
             S := S + '5Sent'
           ELSE
             S := S + '5Unsent'
           ELSE
             S := S + '5Normal';
         IF (NOT Pub) AND (Netmail IN MHeader.Status) THEN
           S := S + ' Netmail';
         S := PadLeftStr(S,39) + '^1Origin : ^5';
         IF (MHeader.Origindate <> '') THEN
           S := S + MHeader.Origindate
         ELSE
           S := S + 'Local';
       END;
   6 : IF ((SeeAnon) AND ((MHeader.MTO.Anon + MHeader.From.Anon) > 0) AND (MemMsgArea.MAType = 0)) THEN
       BEGIN
         S := '^1Real: ^5';
         IF (MARealName IN MemMsgArea.MAFlags) THEN
           S := S + Caps(Mheader.From.Real)
         ELSE
           S := S + Caps(MHeader.From.Name);
         S := S + '^1 to ^5';
         IF (MARealName IN MemMsgArea.MAFlags) THEN
           S := S + Caps(MHeader.MTO.Real)
         ELSE
           S := S + Caps(MHeader.MTO.Name);
       END;
  END;
  HeaderLine := S;
END;

{ anum=actual, MNum=M#/t# <-displayed, TNum=m#/T# <- max? }

PROCEDURE ReadMsg(Anum,MNum,TNum: Word);
VAR
  MHeader: MHeaderRec;
  FileInfo: FileInfoRecordType;
  TransferFlags: TransferFlagSet;
  MsgTxtStr: AStr;
  FileOwner: Str36;
  DS: DirStr;
  NS: NameStr;
  ES: ExtStr;
  SaveFileArea: Integer;
  TempTextSize: Word;
BEGIN
  AllowAbort := (CoSysOp) OR (NOT (MAForceRead IN MemMsgArea.MAFlags));
  AllowContinue := TRUE;
  LoadHeader(Anum,MHeader);
  IF ((MDeleted IN Mheader.Status) OR (UnValidated IN MHeader.Status)) AND
     NOT (CoSysOp OR FromYou(MHeader) OR ToYou(MHeader)) THEN
    Exit;
  Abort := FALSE;
  Next := FALSE;

  FOR TempTextSize := 1 TO 6 DO
  BEGIN
    MsgTxtStr := HeaderLine(MHeader,MNum,TNum,TempTextSize,FileOwner);
    IF (TempTextSize <> 2) THEN
      MCIAllowed := (AllowMCI IN MHeader.Status);
    IF (MsgTxtStr <> '') THEN
      PrintACR(MsgTxtStr);
    MCIAllowed := TRUE;
  END;

  NL;

  Reset(MsgTxtF,1);
  IF (IOResult <> 0) THEN
  BEGIN
    SysOpLog('Error accessing message text.');
    AllowAbort := TRUE;
    Exit;
  END;
  IF (NOT Abort) THEN
  BEGIN
    Reading_A_Msg := TRUE;
    MCIAllowed := (AllowMCI IN Mheader.Status);
    TempTextSize := 0;
    Abort := FALSE;
    Next := FALSE;
    UserColor(MemMsgArea.Text_Color);
    IF (MHeader.TextSize > 0) THEN
      IF (((MHeader.Pointer - 1) + MHeader.TextSize) <= FileSize(MsgTxtF)) AND (MHeader.Pointer > 0) THEN
      BEGIN
        Seek(MsgTxtF,(MHeader.Pointer - 1));
        REPEAT
          BlockRead(MsgTxtF,MsgTxtStr[0],1);
          BlockRead(MsgTxtF,MsgTxtStr[1],Ord(MsgTxtStr[0]));
          LastError := IOResult;
          IF (LastError <> 0) THEN
          BEGIN
            SysOpLog('Error loading message text.');
            TempTextSize := MHeader.TextSize;
          END;
          Inc(TempTextSize,(Length(MsgTxtStr) + 1));
          IF (' * Origin: ' = Copy(MsgTxtStr,1,11)) THEN
            MsgTxtStr := '^'+IntToStr(MemMsgArea.Origin_Color) + MsgTxtStr
          ELSE IF ('---'= Copy(MsgTxtStr,1,3)) AND ((Length(MsgTxtStr) = 3) OR (MsgTxtStr[4] <> '-')) THEN
            MsgTxtStr := '^'+IntToStr(MemMsgArea.Tear_Color) + MsgTxtStr
          ELSE IF (Pos('> ',Copy(MsgTxtStr,1,5)) > 0) THEN
            MsgTxtStr := '^'+IntToStr(MemMsgArea.Quote_Color)+ MsgTxtStr +'^'+IntToStr(MemMsgArea.Text_Color)
          ELSE IF (Pos(#254,Copy(MsgTxtStr,1,5)) > 0) THEN
            MsgTxtStr := '^'+IntToStr(MemMsgArea.Tear_Color) + MsgTxtStr;
          PrintACR('^1'+MsgTxtStr);
        UNTIL (TempTextSize >= MHeader.TextSize) OR (Abort) OR (HangUp);
      END;
    MCIAllowed := TRUE;
    Reading_A_Msg := FALSE;
    IF (DOSANSIOn) THEN
      ReDrawForANSI;
  END;
  Close(MsgTxtF);
  LastError := IOResult;
  IF (MHeader.FileAttached > 0) THEN
    IF (NOT Exist(MHeader.Subject)) THEN
    BEGIN
      NL;
      Print('^7The attached file does not actually exist!^1');
    END
    ELSE
    BEGIN
      SaveFileArea := FileArea;
      FileArea := -1;
      FSplit(MHeader.Subject,DS,NS,ES);
      WITH MemFileArea DO
      BEGIN
        AreaName := 'File Attach';
        DLPath := DS;
        ULPath := DS;
        FAFlags := [FANoRatio];
      END;
      WITH FileInfo DO
      BEGIN
        FileName := Align(NS+ES);
        Description := 'File Attach';
        FilePoints := 0;
        Downloaded := 0;
        FileSize := GetFileSize(MHeader.Subject);
        OwnerNum := SearchUser(StripColor(FileOwner),FALSE);
        OwnerName := StripColor(FileOwner);
        FileDate := MHeader.Date;
        VPointer := -1;
        VTextSize := 0;
        FIFlags := [];
      END;
      TransferFlags := [IsFileAttach];
      DLX(FileInfo,-1,TransferFlags);
      IF (IsTransferOk IN TransferFLags) AND (NOT (IsKeyboardAbort IN TransferFlags)) THEN
        SendShortMessage(MHeader.From.UserNum,Caps(ThisUser.Name)+' downloaded "^5'+StripName(MHeader.Subject)+
                         '^1" from ^5File Attach');
      FileArea := SaveFileArea;
      LoadFileArea(FileArea);
    END;
  AllowAbort := TRUE;
  TempPause := (Pause IN ThisUser.Flags);
END;

(* Done:  Lee Palmer 10/23/09 *)
FUNCTION GetTagLine: Str74;
VAR
  StrPointerFile: FILE OF StrPointerRec;
  RGStrFile: FILE;
  StrPointer: StrPointerRec;
  TagLine: Str74;
  TempTextSize: Word;
  StrNum: Word;
  FSize: LongInt;
BEGIN
  TagLine := '';
  IF (NOT Exist(General.lMultPath+'TAGLINE.PTR')) OR (NOT Exist(General.LMultPath+'TAGLINE.DAT')) THEN
    SL1('* TAGLINE.PTR or TAGLINE.DAT file(s) do not exist!')
  ELSE
  BEGIN
    Assign(StrPointerFile,General.LMultPath+'TAGLINE.PTR');
    Reset(StrPointerFile);
    FSize := FileSize(StrPointerFile);
    IF (FSize < 1) THEN
    BEGIN
      SL1('* TAGLINE.PTR does not contain any TagLines!');
      Exit;
    END;
    IF (FSize > 65535) THEN
      FSize := 65535
    ELSE
      Dec(FSize);
    Randomize;
    StrNum := Random(FSize);
    Seek(StrPointerFile,StrNum);
    Read(StrPointerFile,StrPointer);
    Close(StrPointerFile);
    LastError := IOResult;
    Assign(RGStrFile,General.LMultPath+'TAGLINE.DAT');
    Reset(RGStrFile,1);
    Seek(RGStrFile,(StrPointer.Pointer - 1));
    TempTextSize := 0;
    REPEAT
      BlockRead(RGStrFile,TagLine[0],1);
      BlockRead(RGStrFile,TagLine[1],Ord(TagLine[0]));
      Inc(TempTextSize,(Length(TagLine) + 1));
    UNTIL (TempTextSize >= StrPointer.TextSize);
    Close(RGStrFile);
    LastError := IOResult;
  END;
  GetTagLine := TagLine;
END;

END.
