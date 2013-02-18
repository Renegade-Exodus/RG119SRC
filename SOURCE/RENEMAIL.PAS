{$IFDEF WIN32}
{$I DEFINES.INC}
{$ENDIF}

{$IFDEF MSDOS}
{$M 49152,0,65536}
{$ENDIF}
{$A+,I-,E-,F+}

PROGRAM ReneMail;

USES
  Crt,
  Dos,
  TimeFunc;

{$I RECORDS.PAS}

CONST
  Activity_Log: Boolean = FALSE;
  NetMailOnly: Boolean = FALSE;
  IsNetMail: Boolean = FALSE;
{$IFDEF MSDOS}
  FastPurge: Boolean = TRUE;
{$ENDIF}
{$IFDEF WIN32}
  FastPurge: Boolean = FALSE;
{$ENDIF}
  Process_NetMail: Boolean = TRUE;
  Purge_NetMail: Boolean = TRUE;
  Absolute_Scan: Boolean = FALSE;
  Ignore_1Msg: Boolean = TRUE;
  Toss_Mail: Boolean = FALSE;
  Scan_Mail: Boolean = FALSE;
  Purge_Dir: Boolean = FALSE;

TYPE
  FidoRecordType = RECORD
    FromUserName: STRING[35];
    ToUserName: STRING[35];
    Subject: STRING[71];
    DateTime: STRING[19];
    TimesRead: SmallWord;
    DestNode: SmallWord;
    OrigNode: SmallWord;
    Cost: SmallWord;
    OrigNet: SmallWord;
    DestNet: SmallWord;
    Filler: ARRAY[1..8] OF Char;
    ReplyTo: SmallWord;
    Attribute: SmallWord;
    NextReply: SmallWord;
  END;

  BufferArrayType = ARRAY[1..32767] OF Char;

VAR
  FCB: ARRAY[1..37] OF Char;

  BufferArray: BufferArrayType;

  GeneralFile: FILE OF GeneralRecordType;

  UserFile: FILE OF UserRecordType;

  MessageAreaFile: FILE OF MessageAreaRecordType;

  IndexFile: FILE OF UserIDXRec;

  RGMsgHdrFile: FILE OF MHeaderRec;

  RGMsgTxtFile: FILE;

  FidoFile: FILE;

  HiWaterF: FILE OF SmallWord;

  General: GeneralRecordType;

  User: UserRecordType;

  MemMsgArea: MessageAreaRecordType;

  IndexR: UserIDXRec;

  RGMsgHdr: MHeaderRec;

  FidoMsgHdr: FidoRecordType;

{$IFDEF MSDOS}
  Regs: Registers;
{$ENDIF}

  DirInfo: SearchRec;

  TempParamStr,
  StartDir: STRING;

  LastError,
  ParamCounter,
  MsgArea: Integer;

  ParamFound: Boolean;

{$IFDEF WIN32}
(* REENOTE 
   In BP/TP you can do this:

   var
     MySet: NetAttribs;
     MyWord: Word;
   begin
     MySet := [Private, Crash];
     MyWord := Word(MySet);
     { MyWord now contains the value 3 in BP/TP }
	 { but VP refuses to compile the code due to Word(MySet) }
   end;

   In VP this typecast isn't allowed (maybe there's a compiler setting to allow it, didn't look actually)
   so this function converts from a set to a word type.
   
   While this function should work for both BP/TP and for VP, I'm only using it for VP and using the
   original cast for BP/TP, since there's no need to change what isn't broken
*)
function NetAttribsToWord(inSet: NetAttribs): Word;
var
  Result: Word;
begin
  Result := 0;
  if (Private in inSet) then result := result + 1;
  if (Crash in inSet) then result := result + 2;
  if (Recd in inSet) then result := result + 4;
  if (NSent in inSet) then result := result + 8;
  if (FileAttach in inSet) then result := result + 16;
  if (Intransit in inSet) then result := result + 32;
  if (Orphan in inSet) then result := result + 64;
  if (KillSent in inSet) then result := result + 128;
  if (Local in inSet) then result := result + 256;
  if (Hold in inSet) then result := result + 512;
  if (Unused in inSet) then result := result + 1024;
  if (FileRequest in inSet) then result := result + 2048;
  if (ReturnReceiptRequest in inSet) then result := result + 4096;
  if (IsReturnReceipt in inSet) then result := result + 8192;
  if (AuditRequest in inSet) then result := result + 16384;
  if (FileUpdateRequest in inSet) then result := result + 32768;
  NetAttribsToWord := Result;
end;
{$ENDIF}

FUNCTION CenterStr(S: STRING): STRING;
VAR
  Counter1: Byte;
BEGIN
  Counter1 := ((80 - Length(S)) DIV 2);
  Move(S[1],S[Counter1 + 1],Length(S));
  Inc(S[0],Counter1);
  FillChar(S[1],Counter1,#32);
  CenterStr := S;
END;

PROCEDURE WriteCharXY(C: Char; X,Y,FColor,BColor: Byte);
BEGIN
  TextColor(FColor);
  TextBackGround(BColor);
  GotoXY(X,Y);
  Write(C);
END;

PROCEDURE WriteStrXY(S: STRING; X,Y,FColor,BColor: Byte);
BEGIN
  TextColor(FColor);
  TextBackGround(BColor);
  GotoXY(X,Y);
  Write(S);
END;

PROCEDURE DisplayMain(FColor,BColor: Byte);
VAR
  X,
  Y: Byte;
BEGIN
  ClrScr;
  Window(1,1,80,24);
  TextColor(FColor);
  TextBackGround(BColor);
  ClrScr;
  Window(1,1,80,25);
  WriteCharXY(#201,1,1,FColor,BColor);
  FOR X := 2 TO 79 DO
    WriteCharXY(#205,X,1,FColor,BColor);
  WriteCharXY(#187,80,1,FColor,BColor);
  FOR Y := 2 TO 3 DO
  BEGIN
    WriteCharXY(#186,1,Y,FColor,BColor);
    WriteCharXY(#186,80,Y,FColor,BColor);
  END;
  WriteCharXY(#204,1,4,FColor,BColor);
  FOR X := 2 TO 79 DO
    WriteCharXY(#205,X,4,FColor,BColor);
  WriteCharXY(#185,80,4,FColor,BColor);
  WriteStrXY(CenterStr('Renegade Echomail Interface v'+Ver),2,2,FColor,BColor);
  WriteStrXY(CenterStr('Copyright 2004-2011 - The Renegade Developement Team'),2,3,FColor,BColor);
  FOR Y := 5 TO 21 DO
  BEGIN
    WriteCharXY(#186,1,Y,FColor,BColor);
    WriteCharXY(#186,80,Y,FColor,BColor);
  END;
  WriteCharXY(#204,1,22,FColor,BColor);
  FOR X := 2 TO 79 DO
    WriteCharXY(#205,X,22,FColor,BColor);
  WriteCharXY(#185,80,22,FColor,BColor);
  WriteCharXY(#186,1,23,FColor,BColor);
  WriteStrXY('Message: None',3,23,FColor,BColor);
  WriteCharXY(#186,80,23,FColor,BColor);
  WriteCharXY(#200,1,24,FColor,BColor);
  FOR X := 2 TO 79 DO
    WriteCharXY(#205,X,24,FColor,BColor);
  WriteCharXY(#188,80,24,FColor,BColor);
  Window(2,5,78,21);
  GoToXY(1,1);
END;

PROCEDURE DisplayHelp(FColor,BColor: Byte);
BEGIN
  WriteStrXY('Commands:  -T  Toss incoming messages',22,2,FColor,BColor);
  WriteStrXY('-P  Purge echomail dirs',33,3,FColor,BColor);
  WriteStrXY('-S  Scan outbound messages',33,4,FColor,BColor);
  WriteStrXY('Options:       -A  Absolute Scan',22,6,FColor,BColor);
  WriteStrXY('-D  Do not delete netmail',37,7,FColor,BColor);
  WriteStrXY('-F  No fast purge',37,8,FColor,BColor);
  WriteStrXY('-I  Import 1.MSG',37,9,FColor,BColor);
  WriteStrXY('-L  Activity logging',37,10,FColor,BColor);
  WriteStrXY('-N  No netmail',37,11,FColor,BColor);
  WriteStrXY('-O  Only netmail',37,12,FColor,BColor);
END;

PROCEDURE ErrorStrXY(S: STRING; X,Y,FColor,BColor: Byte);
VAR
  SaveX,
  SaveY: Byte;
BEGIN
  SaveX := WhereX;
  SaveY := WhereY;
  Window(1,1,80,25);
  GoToXY(X,Y);
  TextColor(FColor);
  TextBackGround(BColor);
  Write(S);
  Window(2,5,78,21);
  GoToXY(SaveX,SaveY);
END;

PROCEDURE HaltErrorStrXY(S: STRING; X,Y,FColor,BColor,HaltNum: Byte);
BEGIN
  DisplayHelp(White,Blue);
  Window(1,1,80,25);
  GoToXY(X,Y);
  TextColor(FColor);
  TextBackGround(BColor);
  Write(S);
  GotoXY(1,25);
  Halt(HaltNum);
END;

PROCEDURE LogActivity(ActivityMsg: STRING);
VAR
  ActivityFile: Text;
BEGIN
  IF (Activity_Log) THEN
  BEGIN
    Assign(ActivityFile,General.LogsPath+'RENEMAIL.LOG');
    {$I-} Append(ActivityFile); {$I+}
    LastError := IOResult;
    IF (LastError <> 0) THEN
    BEGIN
      {$I-} ReWrite(ActivityFile); {$I+}
      LastError := IOResult;
      IF (LastError <> 0) THEN
        ErrorStrXY('Unable to create RENEMAIL.LOG.',12,23,Red + 128,Blue);
    END;
    {$I-} Write(ActivityFile,ActivityMsg); {$I+}
    LastError := IOResult;
    IF (LastError <> 0) THEN
      ErrorStrXY('Unable to write to RENEMAIL.LOG.',12,23,Red + 128,Blue);
    {$I-} Close(ActivityFile); {$I+}
    LastError := IOResult;
    IF (LastError <> 0) THEN
      ErrorStrXY('Unable to close RENEMAIL.LOG.',12,23,Red + 128,Blue);
  END;
END;

PROCEDURE LogError(ErrMsg: STRING);
VAR
  ErrorFile: Text;
BEGIN
  Assign(ErrorFile,General.LogsPath+'RENEMAIL.ERR');
  {$I-} Append(ErrorFile); {$I+}
  LastError := IOResult;
  IF (LastError <> 0) THEN
  BEGIN
    {$I-} ReWrite(ErrorFile); {$I+}
    LastError := IOResult;
    IF (LastError <> 0) THEN
      ErrorStrXY('Unable to create RENEMAIL.ERR.',12,23,Red + 128,Blue);
  END;
  {$I-} WriteLn(ErrorFile,ToDate8(DateStr)+' '+TimeStr+': '+ErrMsg); {$I+}
  LastError := IOResult;
  IF (LastError <> 0) THEN
    ErrorStrXY('Unable to write to RENEMAIL.ERR.',12,23,Red + 128,Blue);
  {$I-} Close(ErrorFile); {$I+}
  LastError := IOResult;
  IF (LastError <> 0) THEN
    ErrorStrXY('Unable to close RENEMAIL.ERR.',12,23,Red + 128,Blue);
END;

FUNCTION SC(S: STRING; I: Integer): Char;
BEGIN
  SC := UpCase(S[I]);
END;

FUNCTION Hex(L: LongInt; B: Byte): STRING;
CONST
  HC: ARRAY[0..15] OF Char = '0123456789ABCDEF';
VAR
  One,
  Two,
  Three,
  Four: Byte;
BEGIN
  One := (L AND $000000FF);
  Two := ((L AND $0000FF00) SHR 8);
  Three := ((L AND $00FF0000) SHR 16);
  Four := ((L AND $FF000000) SHR 24);
  Hex[0] := Chr(B);
  IF (B = 4) THEN
  BEGIN
    Hex[1] := HC[Two SHR 4];
    Hex[2] := HC[Two AND $F];
    Hex[3] := HC[One SHR 4];
    Hex[4] := HC[One AND $F];
  END
  ELSE
  BEGIN
    Hex[8] := HC[One AND $F];
    Hex[7] := HC[One SHR 4];
    Hex[6] := HC[Two AND $F];
    Hex[5] := HC[Two SHR 4];
    Hex[4] := HC[Three AND $F];
    Hex[3] := HC[Three SHR 4];
    Hex[2] := HC[Four AND $F];
    Hex[1] := HC[Four SHR 4];
  END;
END;

FUNCTION SQOutSp(S: STRING): STRING;
BEGIN
  WHILE (Pos(' ',S) > 0) DO
    Delete(S,Pos(' ',S),1);
  SQOutSp := S;
END;

FUNCTION BSlash(S: STRING; B: Boolean): STRING;
BEGIN
  IF (B) THEN
  BEGIN
    WHILE (Copy(S,(Length(S) - 1),2) = '\\') DO
      S := Copy(S,1,(Length(S) - 2));
    IF (Copy(S,Length(S),1) <> '\') THEN
      S := S + '\';
  END
  ELSE
    WHILE (S[Length(S)] = '\') DO
      Dec(S[0]);
  BSlash := S;
END;

FUNCTION ExistDir(Dir: STRING): Boolean;
BEGIN
  WHILE (Dir[Length(Dir)] = '\') DO
    Dec(Dir[0]);
  FindFirst(Dir,AnyFile,DirInfo);
  ExistDir := (DOSError = 0) AND (DirInfo.Attr AND $10 = $10);
END;

FUNCTION ExistFile(FileName: STRING): Boolean;
BEGIN
  FindFirst(SQOutSp(FileNAme),AnyFile,DirInfo);
  ExistFile := (DOSError = 0);
END;

(*
PROCEDURE MakeDir(Dir: STRING);
VAR
  Counter: Integer;
BEGIN
  Dir := BSlash(Dir,TRUE);
  IF (Length(Dir) > 3) AND (NOT ExistDir(Dir)) THEN
  BEGIN
    Counter := 2;
    WHILE (Counter <= Length(Dir)) DO
    BEGIN
      IF (Dir[Counter] = '\') THEN
        IF (Dir[Counter - 1] <> ':') THEN
          IF (NOT ExistDir(Copy(Dir,1,(Counter - 1)))) THEN
          BEGIN
            MkDir(Copy(Dir,1,(Counter - 1)));
            LastError := IOResult;
            IF (LastError <> 0) THEN
            BEGIN
              WriteLn('Error creating message path: '+Copy(Dir,1,(Counter - 1)));
              LogError(Copy(Dir,1,(Counter - 1))+'/ ');
              Halt(1);
            END;
          END;
      Inc(Counter);
    END;
  END;
END;
*)

{$IFDEF MSDOS}
FUNCTION AOnOff(B: Boolean; S1,S2: STRING): STRING; ASSEMBLER;
ASM
  PUSH ds
  Test b, 1
  JZ   @@1
  LDS  si, s1
  JMP  @@2
  @@1:   LDS  si, s2
  @@2:   LES  di, @Result
  XOR  Ch, Ch
  MOV  cl, Byte ptr ds:[si]
  MOV  Byte ptr es:[di], cl
  Inc  di
  Inc  si
  CLD
  REP  MOVSB
  POP  ds
END;
{$ENDIF}
{$IFDEF WIN32}
FUNCTION AOnOff(B: Boolean; S1,S2: STRING): STRING;
BEGIN
  if (B) then
    AOnOff := S1
  else
    AOnOff := S2;
END;
{$ENDIF}

FUNCTION StripName(S: STRING): STRING;
VAR
  Counter: Integer;
BEGIN
  Counter := Length(S);
  WHILE (Counter > 0) AND (Pos(S[Counter],':\/') = 0) DO
    Dec(Counter);
  Delete(S,1,Counter);
  StripName := S;
END;

FUNCTION AllCaps(S: STRING): STRING;
VAR
  Counter: Integer;
BEGIN
  AllCaps[0] := s[0];
  FOR Counter := 1 TO Length(S) DO
    AllCaps[Counter] := UpCase(S[Counter]);
END;

FUNCTION Caps(S: STRING): STRING;
VAR
  Counter: Integer;
BEGIN
  FOR Counter := 1 TO Length(s) DO
    IF (S[Counter] IN ['A'..'Z']) THEN
       S[Counter] := Chr(Ord(S[Counter]) + 32);
  FOR Counter := 1 TO Length(S) DO
    IF (NOT (S[Counter] IN ['A'..'Z','a'..'z',Chr(39)])) THEN
      IF (S[Counter + 1] IN ['a'..'z']) THEN
         S[Counter + 1] := UpCase(S[Counter + 1]);
  S[1] := UpCase(S[1]);
  Caps := S;
END;

FUNCTION StrToInt(S: STRING): LongInt;
VAR
  I: Integer;
  L: LongInt;
BEGIN
 Val(S,L,I);
 IF (I <> 0) THEN
 BEGIN
   S[0] := Chr(I - 1);
   Val(S,L,I)
  END;
  StrToInt := L;
  IF (S = '') THEN
    StrToInt := 0;
END;

FUNCTION IntToStr(L: LongInt): STRING;
VAR
  S: STRING;
BEGIN
  Str(L,S);
  IntToStr := S;
END;

FUNCTION PadRightStr(S: STRING; Len: Byte): STRING;
VAR
  X,
  Counter: Byte;
BEGIN
  X := Length(S);
  FOR Counter := X TO (Len - 1) DO
    S := ' ' + S;
  PadRightStr := S;
END;

FUNCTION StripColor(MAFlags: MAFlagSet; InStr: STRING): STRING;
VAR
  OutStr: STRING;
  Counter,
  Counter1: Byte;
BEGIN
  Counter := 0;
  OutStr := '';
  WHILE (Counter < Length(InStr)) DO
  BEGIN
    Inc(Counter);
    CASE InStr[Counter] OF
      #128..#255 :
            IF (MAFilter IN MAFlags) THEN
              OutStr := OutStr + Chr(Ord(InStr[Counter]) AND 128)
            ELSE
              OutStr := OutStr + InStr[Counter];
      '^' : IF InStr[Counter + 1] IN [#0..#9,'0'..'9'] THEN
              Inc(Counter)
            ELSE
              OutStr := OutStr + '^';
      '|' : IF (MAFilter IN MAFlags) AND (InStr[Counter + 1] IN ['0'..'9']) THEN
            BEGIN
              Counter1 := 0;
              WHILE (InStr[Counter + 1] IN ['0'..'9']) AND (Counter <= Length(InStr)) AND (Counter1 <= 2) DO
              BEGIN
                Inc(Counter);
                Inc(Counter1)
              END
            END
            ELSE
              OutStr := OutStr + '|'
      ELSE
        OutStr := OutStr + InStr[Counter];
    END;
  END;
  StripColor := OutStr;
END;

FUNCTION UseName(B: Byte; S: STRING): STRING;
BEGIN
  CASE b OF
    1,2
      : S := 'Anonymous';
    3 : S := 'Abby';
    4 : S := 'Problemed Person';
  END;
  UseName := S;
END;

FUNCTION SearchUser(GenDataPath: STRING; Uname: STRING): Integer;
VAR
  Current: Integer;
  Done: Boolean;
BEGIN
  Assign(IndexFile,GenDataPath+'USERS.IDX');
  {$I-} Reset(IndexFile); {$I+}
  LastError := IOResult;
  IF (LastError <> 0) THEN
  BEGIN
    TextColor(Red);
    WriteLn('Unable to open USERS.IDX.');
    TextColor(LightGray);
    LogError(GenDataPath+'USERS.IDX/Open File Error - '+IntToStr(LastError)+' (Proc: SearchUser)');
    Exit;
  END;
  Uname := AllCaps(UName);
  Current := 0;
  Done := FALSE;
  IF (FileSize(IndexFile) > 0) THEN
    REPEAT
      {$I-} Seek(IndexFile,Current); {$I+}
      LastError := IOResult;
      IF (LastError <> 0) THEN
      BEGIN
        TextColor(Red);
        WriteLn('Unable to seek record in USERS.IDX.');
        TextColor(LightGray);
        LogError(GenDataPath+'USERS.IDX/Seek Record '+IntTostr(Current)+' Error - '+IntToStr(LastError)+' (Proc: SearchUser)');
        Exit;
      END;
      {$I-} Read(IndexFile,IndexR); {$I+}
      LastError := IOResult;
      IF (LastError <> 0) THEN
      BEGIN
        TextColor(Red);
        WriteLn('Unable to read record from USERS.IDX.');
        TextColor(LightGray);
        LogError(GenDataPath+'USERS.IDX/Read Record '+IntTostr(Current)+' Error - '+IntToStr(LastError)+' (Proc: SearchUser)');
        Exit;
      END;
      IF (Uname < IndexR.Name) THEN
        Current := IndexR.Left
      ELSE IF (Uname > IndexR.Name) THEN
        Current := IndexR.Right
      ELSE
        Done := TRUE;
    UNTIL (Current = -1) OR (Done);
  {$I-} Close(IndexFile); {$I+}
  LastError := IOResult;
  IF (LastError <> 0) THEN
  BEGIN
    TextColor(Red);
    WriteLn('Unable to close USERS.IDX.');
    TextColor(LightGray);
    LogError(GenDataPath+'USERS.IDX/Close File Error - '+IntToStr(LastError)+' (Proc: SearchUser)');
    Exit;
  END;
  IF (Done) AND (NOT IndexR.Deleted) THEN
    SearchUser := IndexR.Number
  ELSE
    SearchUser := 0;
END;

PROCEDURE GetGeneral(VAR General1: GeneralRecordType);
BEGIN
  Assign(GeneralFile,'RENEGADE.DAT');
  {$I-} Reset(GeneralFile); {$I+}
  LastError := IOResult;
  IF (LastError <> 0) THEN
  BEGIN
    LogError('RENEGADE.DAT/Open File Error - '+IntToStr(LastError)+' (Proc: GetGeneral)');
    HaltErrorStrXY('Unable to open RENEGADE.DAT!',12,23,Red + 128,Blue,1);
  END;
  {$I-} Seek(GeneralFile,0); {$I+}
  LastError := IOResult;
  IF (LastError <> 0) THEN
  BEGIN
    LogError('RENEGADE.DAT/Seek Record 0 Error - '+IntToStr(LastError)+' (Proc: GetGeneral)');
    HaltErrorStrXY('Unable to seek record in RENEGADE.DAT!',12,23,Red + 128,Blue,1);
  END;
  {$I-} Read(GeneralFile,General1); {$I+}
  LastError := IOResult;
  IF (LastError <> 0) THEN
  BEGIN
    LogError('RENEGADE.DAT/Read Record 0 Error - '+IntToStr(LastError)+' (Proc: GetGeneral)');
    HaltErrorStrXY('Unable to read record from RENEGADE.DAT!',12,23,Red + 128,Blue,1);
  END;
  {$I-} Close(GeneralFile); {$I+}
  LastError := IOResult;
  IF (LastError <> 0) THEN
  BEGIN
    LogError('RENEGADE.DAT/Close File Error - '+IntToStr(LastError)+' (Proc: GetGeneral)');
    HaltErrorStrXY('Unable to close RENEGADE.DAT!',12,23,Red + 128,Blue,1);
  END;
END;

PROCEDURE GeneralPaths(General1: GeneralRecordType);
BEGIN
  IF (NOT ExistDir(General1.DataPath)) THEN
  BEGIN
    LogError(General1.DataPath+'/Data Path - "Invalid" (Proc: GeneralPaths)');
    HaltErrorStrXY('The system configuration data path is invalid!',12,23,Red + 128,Blue,1);
  END;
  IF (NOT ExistDir(General1.NetMailPath)) THEN
  BEGIN
    LogError(General1.NetMailPath+'/NetMail Path - "Invalid" (Proc: GeneralPaths)');
    HaltErrorStrXY('The system configuration netmail path is invalid!',12,23,Red + 128,Blue,1);
  END;
  IF (NOT ExistDir(General1.MsgPath)) THEN
  BEGIN
    LogError(General1.MsgPath+'/Message Path - "Invalid" (Proc: GeneralPaths)');
    HaltErrorStrXY('The system configuration message path is invalid!',12,23,Red + 128,Blue,1);
  END;
  IF (NOT ExistDir(General1.LogsPath)) THEN
  BEGIN
    LogError(General1.LogsPath+'/Log Path - "Invalid" (Proc: GeneralPaths)');
    HaltErrorStrXY('The system configuration log path is invalid!',12,23,Red + 128,Blue,1);
  END;
END;

PROCEDURE GeneralFiles(General1: GeneralRecordType);
BEGIN
  IF (NOT ExistFile(General1.DataPath+'USERS.DAT')) THEN
  BEGIN
    LogError(General1.DataPath+'USERS.DAT/File - "Missing" (Proc: GeneralFiles)');
    HaltErrorStrXY('Unable to locate USERS.DAT!',12,23,Red + 128,Blue,1);
  END;
  IF (NOT ExistFile(General1.DataPath+'USERS.IDX')) THEN
  BEGIN
    LogError(General1.DataPath+'USERS.IDX/File - "Missing" (Proc: GeneralFiles)');
    HaltErrorStrXY('Unable to locate USERS.IDX!',12,23,Red + 128,Blue,1);
  END;
  IF (NOT ExistFile(General1.DataPath+'MBASES.DAT')) THEN
  BEGIN
    LogError(General1.DataPath+'MBASES.DAT/File - "Missing" (Proc: GeneralFiles)');
    HaltErrorStrXY('Unable to locate MBASES.DAT!',12,23,Red + 128,Blue,1);
  END;
END;

(*
PROCEDURE MessageFile(General1: GeneralRecordType);
VAR
  MArea: Integer;
BEGIN
  Assign(MessageAreaFile,General1.DataPath+'MBASES.DAT');
  {$I-} Reset(MessageAreaFile); {$I+}
  LastError := IOResult;
  IF (LastError <> 0) THEN
  BEGIN
    TextColor(Red);
    WriteLn('Unable to open MBASES.DAT.');
    TextColor(LightGray);
    LogError(General1.DataPath+'MBASES.DAT/Open File Error - '+IntToStr(LastError)+' (Proc: MessageFile)');
    Halt(1);
  END;
  MArea := 1;
  WHILE (MArea <= (FileSize(MessageAreaFile))) DO
  BEGIN
    {$I-} Seek(MessageAreaFile,(MArea - 1)); {$I+}
    LastError := IOResult;
    IF (LastError <> 0) THEN
    BEGIN
      TextColor(Red);
      WriteLn('Unable to seek record in MBASES.DAT.');
      TextColor(LightGray);
      LogError(General1.DataPath+'MBASES.DAT/Seek Record '+IntToStr(MArea - 1)+' Error - '+IntToStr(LastError)+
               ' (Proc: MessageFile)');
      Halt(1);
    END;
    {$I-} Read(MessageAreaFile,MemMsgArea); {$I+}
    LastError := IOResult;
    IF (LastError <> 0) THEN
    BEGIN
      TextColor(Red);
      WriteLn('Unable to read record from MBASES.DAT.');
      TextColor(LightGray);
      LogError(General1.DataPath+'MBASES.DAT/Read Record '+IntToStr(MArea - 1)+' Error - '+IntToStr(LastError)+
               ' (Proc: MessageFile)');
      Halt(1);
    END;
    IF (MemMsgArea.MAType = 1) THEN
    BEGIN
      IF (NOT ExistDir(MemMsgArea.MsgPath)) THEN

    END;
    Inc(MArea);
  END;
  {$I-} Close(MessageAreaFile); {$I+}
  LastError := IOResult;
  IF (LastError <> 0) THEN
  BEGIN
    TextColor(Red);
    WriteLn('Unable to close MBASES.DAT.');
    TextColor(LightGray);
    LogError(General1.DataPath+'MBASES.DAT/Close File Error - '+IntToStr(LastError)+' (Proc: MessageFile)');
    Halt(1);
  END;
END;
*)

PROCEDURE GetMsgLst(MemMsgPath: STRING; VAR LowMsg,HighMsg: Word);
VAR
  FidoMsgNum,
  HiWater: SmallWord;
BEGIN
  HiWater := 1;
  IF (NOT IsNetMail) THEN
  BEGIN
    Assign(HiWaterF,MemMsgPath+'HI_WATER.MRK');
    {$I- } Reset(HiWaterF); {$I+}
    LastError := IOResult;
    IF (LastError <> 0) THEN
    BEGIN
      {$I-} ReWrite(HiWaterF); {$I+}
      LastError := IOResult;
      IF (LastError <> 0) THEN
      BEGIN
        TextColor(Red);
        WriteLn('Unable to create '+MemMsgPath+'HI_WATER.MRK.');
        TextColor(LightGray);
        LogError(MemMsgPath+'HI_WATER.MRK/ReWrite File Error - '+IntToStr(LastError)+' (Proc: GetMsgList)');
        Exit;
      END;
      {$I-} Write(HiWaterF,HiWater); {$I+}
      LastError := IOResult;
      IF (LastError <> 0) THEN
      BEGIN
        TextColor(Red);
        WriteLn('Unable to write record to '+MemMsgPath+'HI_WATER.MRK.');
        TextColor(LightGray);
        LogError(MemMsgPath+'HI_WATER.MRK/Write Record 0 Error - '+IntToStr(LastError)+' (Proc: GetMsgList)');
        Exit;
      END;
    END
    ELSE
    BEGIN
      {$I-} Read(HiWaterF,HiWater); {$I+}
      LastError := IOResult;
      IF (LastError <> 0) THEN
      BEGIN
        TextColor(Red);
        WriteLn('Unable to read record from '+MemMsgPath+'HI_WATER.MRK.');
        TextColor(LightGray);
        LogError(MemMsgPath+'HI_WATER.MRK/Read Record 0 Error - '+IntToStr(LastError)+' (Proc: GetMsgList)');
        Exit;
      END;
      FindFirst(MemMsgPath+IntToStr(HiWater)+'.MSG',AnyFile,DirInfo);
      IF (DOSError <> 0) THEN
        HiWater := 1;
    END;
    {$I-} Close(HiWaterF); {$I+}
    LastError := IOResult;
    IF (LastError <> 0) THEN
    BEGIN
      TextColor(Red);
      WriteLn('Unable to close '+MemMsgPath+'HI_WATER.MRK.');
      TextColor(LightGray);
      LogError(MemMsgPath+'HI_WATER.MRK/Close File Error - '+IntToStr(LastError)+' (Proc: GetMsgList)');
      Exit;
    END;
  END;
  HighMsg := 1;
  LowMsg := 65535;
  FindFirst(MemMsgPath+'*.MSG',AnyFile,DirInfo);
  WHILE (DOSError = 0) DO
  BEGIN
    FidoMsgNum := StrToInt(DirInfo.Name);
    IF (FidoMsgNum < LowMsg) THEN
      LowMsg := FidoMsgNum;
    IF (FidoMsgNum > HighMsg) THEN
      HighMsg := FidoMsgNum;
    FindNext(DirInfo);
  END;
  IF (HiWater <= HighMsg) THEN
    IF (HiWater > 1) THEN
      LowMsg := (HiWater + 1);
  IF (Ignore_1Msg) THEN
    IF (LowMsg = 1) AND (HighMsg > 1) THEN
      LowMsg := 2;
END;

PROCEDURE UpdateHiWater(MemMsgPath: STRING; HighWater: SmallWord);
BEGIN
  Assign(HiWaterF,MemMsgPath+'HI_WATER.MRK');
  {$I-} ReWrite(HiWaterF); {$I+}
  LastError := IOResult;
  IF (LastError <> 0) THEN
  BEGIN
    TextColor(Red);
    WriteLn('Unable to create '+MemMsgPath+'HI_WATER.MRK.');
    TextColor(LightGray);
    LogError(MemMsgPath+'HI_WATER.MRK/ReWrite File Error - '+IntToStr(LastError)+' (Proc: UpdateHiWater)');
    Exit;
  END;
  {$I-} Write(HiWaterF,HighWater); {$I+}
  LastError := IOResult;
  IF (LastError <> 0) THEN
  BEGIN
    TextColor(Red);
    WriteLn('Unable to write record to '+MemMsgPath+'HI_WATER.MRK.');
    TextColor(LightGray);
    LogError(MemMsgPath+'HI_WATER.MRK/Write Record 0 Error - '+IntToStr(LastError)+' (Proc: UpdateHiWater)');
    Exit;
  END;
  {$I-} Close(HiWaterF); {$I+}
  LastError := IOResult;
  IF (LastError <> 0) THEN
  BEGIN
    TextColor(Red);
    WriteLn('Unable to close '+MemMsgPath+'HI_WATER.MRK.');
    TextColor(LightGray);
    LogError(MemMsgPath+'HI_WATER.MRK/Close File Error - '+IntToStr(LastError)+' (Proc: UpdateHiWater)');
    Exit;
  END;
END;

PROCEDURE PurgeDir(MemMsgPath: STRING);
VAR
  TotalMsgsProcessed: Word;
  Purged: Boolean;
BEGIN
  TotalMsgsProcessed := 0;
  IF (FastPurge) THEN
  BEGIN
    Randomize;
    FillChar(FCB,SizeOf(FCB),' ');
    FCB[1] := Chr(Ord(StartDir[1]) - 64);
    FCB[2] := '*';
    FCB[10] := 'M';
    FCB[11] := 'S';
    FCB[12] := 'G';
    ChDir(Copy(MemMsgPath,1,Length(MemMsgPath) - 1));
    IF (IOResult <> 0) THEN
      Exit;
    IF (MemMsgPath[2] = ':') THEN
      FCB[1] := Chr(Ord(MemMsgPath[1]) - 64)
    ELSE
      FCB[1] := Chr(Ord(StartDir[1]) - 64);
{$IFDEF MSDOS}
    Regs.DS := Seg(FCB);
    Regs.DX := Ofs(FCB);
    Regs.AX := $1300;
    MSDOS(Regs);
    Purged := (Lo(Regs.AX) = 0);
{$ENDIF}
{$IFDEF WIN32}
  // We ensure FastPurge is false in Win32, so this is never called
{$ENDIF}
  END
  ELSE
  BEGIN
    Purged := TRUE;
    FindFirst(MemMsgPath+'*.MSG',AnyFile,DirInfo);
    IF (DOSError <> 0) THEN
      Purged := FALSE
    ELSE
    BEGIN
      WHILE (DOSError = 0) DO
      BEGIN
        Assign(FidoFile,MemMsgPath+DirInfo.Name);
        {$I-} Erase(FidoFile); {$I+}
        LastError := IOResult;
        IF (LastError <> 0) THEN
        BEGIN
          TextColor(Red);
          WriteLn('Unable to erase '+MemMsgPath+DirInfo.Name);
          TextColor(LightGray);
          LogError(MemMsgPath+DirInfo.Name+'/Erase File Error - '+IntToStr(LastError)+
                   ' (Proc: PurgeDir)');
        END;
        FindNext(DirInfo);
        Inc(TotalMsgsProcessed);
      END;
    END;
  END;
  IF (NOT Purged) THEN
  BEGIN
    LogActivity('No Messages!'^M^J);
    Write('No messages!')
  END
  ELSE
  BEGIN
    IF (FastPurge) THEN
    BEGIN
      LogActivity('Fast purged!'^M^J);
      Write('Fast purged!');
    END
    ELSE
    BEGIN
      LogActivity(IntToStr(TotalMsgsProcessed)+' purged!'^M^J);
      Write(IntToStr(TotalMsgsProcessed)+' purged!');
    END;
  END;
  UpdateHiWater(MemMsgPath,1);
END;

PROCEDURE UpdateMailWaiting(GenDataPath: STRING; UserNum: Integer);
BEGIN
  Assign(UserFile,GenDataPath+'USERS.DAT');
  {$I-} Reset(UserFile); {$I+}
  LastError := IOResult;
  IF (LastError <> 0) THEN
  BEGIN
    TextColor(Red);
    WriteLn('Unable to open '+GenDataPath+'USERS.DAT.');
    TextColor(LightGray);
    LogError(GenDataPath+'USERS.DAT/Open File Error - '+IntToStr(LastError)+' (Proc: UpdateMailWaiting)');
    Exit;
  END;
  {$I-} Seek(UserFile,UserNum); {$I+}
  LastError := IOResult;
  IF (LastError <> 0) THEN
  BEGIN
    TextColor(Red);
    WriteLn('Unable to seek record in '+GenDataPath+'USERS.DAT.');
    TextColor(LightGray);
    LogError(GenDataPath+'USERS.DAT/Seek Record '+IntToStr(UserNum)+' Error - '+IntToStr(LastError)+
             ' (Proc: UpdateMailWaiting)');
    Exit;
  END;
  {$I-} Read(UserFile,User); {$I+}
  LastError := IOResult;
  IF (LastError <> 0) THEN
  BEGIN
    TextColor(Red);
    WriteLn('Unable to read record from '+GenDataPath+'USERS.DAT.');
    TextColor(LightGray);
    LogError(GenDataPath+'USERS.DAT/Read Record '+IntToStr(UserNum)+' Error - '+IntToStr(LastError)+
             ' (Proc: UpdateMailWaiting)');
    Exit;
  END;
  Inc(User.Waiting);
  {$I-} Seek(UserFile,UserNum); {$I+}
  LastError := IOResult;
  IF (LastError <> 0) THEN
  BEGIN
    TextColor(Red);
    WriteLn('Unable to seek record in '+GenDataPath+'USERS.DAT.');
    TextColor(LightGray);
    LogError(GenDataPath+'USERS.DAT/Seek Record '+IntToStr(UserNum)+' Error - '+IntToStr(LastError)+
             ' (Proc: UpdateMailWaiting)');
    Exit;
  END;
  {$I-} Write(UserFile,User); {$I+}
  LastError := IOResult;
  IF (LastError <> 0) THEN
  BEGIN
    TextColor(Red);
    WriteLn('Unable to write record to '+GenDataPath+'USERS.DAT.');
    TextColor(LightGray);
    LogError(GenDataPath+'USERS.DAT/Write Record '+IntToStr(UserNum)+' Error - '+IntToStr(LastError)+
             ' (Proc: UpdateMailWaiting)');
    Exit;
  END;
  {$I-} Close(UserFile); {$I+}
  LastError := IOResult;
  IF (LastError <> 0) THEN
  BEGIN
    TextColor(Red);
    WriteLn('Unable to close '+GenDataPath+'USERS.DAT.');
    TextColor(LightGray);
    LogError(GenDataPath+'USERS.DAT/Close File Error - '+IntToStr(LastError)+' (Proc: UpdateMailWaiting)');
    Exit;
  END;
END;

PROCEDURE InitRGMsgHdrVars(VAR RGMsgHdr: MHeaderRec);
VAR
  Counter: Integer;
BEGIN
  WITH RGMsgHdr DO
  BEGIN
    WITH From DO
    BEGIN
      Anon := 0;
      UserNum := 0;
      A1S := '';
      Real := '';
      Name := '';
      Zone := 0;
      Net := 0;
      Node := 0;
      Point := 0;
    END;
    WITH MTO DO
    BEGIN
      Anon := 0;
      UserNum := 0;
      A1S := '';
      Real := '';
      Name := '';
      Zone := 0;
      Net := 0;
      Node := 0;
      Point := 0;
    END;
    Pointer := -1;
    TextSize := 0;
    ReplyTo := 0;
    Date := GetPackDateTime;
    GetDayOfWeek(DayOfWeek);
    Status := [];
    Replies := 0;
    Subject := '';
    OriginDate := '';
    FileAttached := 0;
    NetAttribute := [];
    FOR Counter := 1 TO 2 DO
      Res[Counter] := 0;
  END;
END;

FUNCTION ReadFidoMsg(General1: GeneralRecordType;
                 VAR RGMsgHdr: MHeaderRec;
                 FidoMsgNum: Word;
                 MemMsgPath: STRING;
                 VAR MsgLength: Integer): Boolean;
VAR
  FidoTxt: STRING[81];
  BufSize,
  Counter: Integer;
  MsgRead: Boolean;
BEGIN
  MsgRead := FALSE;

  IF (NOT ExistFile(MemMsgPath+IntToStr(FidoMsgNum)+'.MSG')) THEN
  BEGIN
    ReadFidoMsg := MsgRead;
    Exit;
  END;

  Assign(FidoFile,MemMsgPath+IntToStr(FidoMsgNum)+'.MSG');
  {$I-} Reset(FidoFile,1); {$I+}
  IF (IOResult <> 0) THEN
  BEGIN
    LogError(MemMsgPath+IntToStr(FidoMsgNum)+'.MSG/Open File Error (Proc: ReadFidoMsg)');
    ErrorStrXY('Unable to open '+MemMsgPath+IntToStr(FidoMsgNum)+'.MSG',12,23,Red + 128,Blue);
  END
  ELSE
  BEGIN

    IF (FileSize(FidoFile) < SizeOf(FidoMsgHdr)) THEN
    BEGIN
      LogError(MemMsgPath+IntToStr(FidoMsgNum)+'.MSG/Truncated File Error (Proc: ReadFidoMsg)');
      ErrorStrXY('Truncated file '+MemMsgPath+IntToStr(FidoMsgNum)+'.MSG',12,23,Red + 128,Blue);
    END
    ELSE
    BEGIN
      {$I-} BlockRead(FidoFile,FidoMsgHdr,SizeOf(FidoMsgHdr)); {$I+}
      LastError := IOResult;
      IF (LastError <> 0) THEN
      BEGIN
        LogError(MemMsgPath+IntToStr(FidoMsgNum)+'.MSG/Block Read Header Error - '+IntToStr(LastError)+
                 ' (Proc: ReadFidoMsg)');
        ErrorStrXY('Unable to block read header from '+MemMsgPath+IntToStr(FidoMsgNum)+'.MSG',12,23,Red + 128,Blue);
      END;

      InitRGMsgHdrVars(RGMsgHdr);

      IF ((FidoMsgHdr.Attribute AND 16) = 16) THEN
        RGMsgHdr.FileAttached := 1;

      FidoTxt := FidoMsgHdr.FromUserName[0];

      FidoTxt := FidoTxt + Copy(FidoMsgHdr.FromUserName,1,((Pos(#0,FidoMsgHdr.FromUserName) - 1)));

      FidoTxt := Caps(FidoTxt);

      RGMsgHdr.From.A1S := FidoTxt;
      RGMsgHdr.From.Real := FidoTxt;
      RGMsgHdr.From.Name := FidoTxt;

      FidoTxt := FidoMsgHdr.ToUserName[0];

      FidoTxt := FidoTxt + Copy(FidoMsgHdr.ToUserName,1,((Pos(#0,FidoMsgHdr.ToUserName) - 1)));

      FidoTxt := Caps(FidoTxt);

      RGMsgHdr.MTO.A1S := FidoTxt;
      RGMsgHdr.MTO.Real := FidoTxt;
      RGMsgHdr.MTO.Name := FidoTxt;

      FidoTxt := FidoMsgHdr.Subject[0];

      FidoTxt := FidoTxt + Copy(FidoMsgHdr.Subject,1,((Pos(#0,FidoMsgHdr.Subject) - 1)));

      RGMsgHdr.Subject := FidoTxt;

      FidoTxt := FidoMsgHdr.DateTIme[0];

      FidoTxt := FidoTxt + Copy(FidoMsgHdr.DateTime,1,((Pos(#0,FidoMsgHdr.DateTime) - 1)));

      RGMsgHdr.OriginDate := FidoTxt;

      RGMsgHdr.Status := [Sent];

      IF (FidoMsgHdr.Attribute AND 1 = 1) THEN
        Include(RGMsgHdr.Status,Prvt);

      MsgRead := TRUE;

      IF (IsNetMail) THEN
      BEGIN
        MsgRead := FALSE;
        RGMsgHdr.From.Node := FidoMsgHdr.OrigNode;
        RGMsgHdr.From.Net := FidoMsgHdr.OrigNet;
        RGMsgHdr.MTO.Node := FidoMsgHdr.DestNode;
        RGMsgHdr.MTO.Net := FidoMsgHdr.DestNet;
        RGMsgHdr.From.Point := 0;
        RGMsgHdr.MTO.Point := 0;
        RGMsgHdr.From.Zone := 0;
        RGMsgHdr.MTO.Zone := 0;
        IF (FidoMsgHdr.Attribute AND 256 = 0) AND (FidoMsgHdr.Attribute AND 4 = 0) THEN
          FOR Counter := 0 TO 19 DO
            IF (RGMsgHdr.MTO.Node = General1.AKA[Counter].Node) AND (RGMsgHdr.MTO.Net = General1.AKA[Counter].Net) THEN
            BEGIN
              RGMsgHdr.MTO.Zone := General1.AKA[Counter].Zone;
              RGMsgHdr.From.Zone := General1.AKA[Counter].Zone;
              MsgRead := TRUE;
            END;
        IF (NOT MsgRead) THEN
        BEGIN
{          LogError(MemMsgPath+IntToStr(FidoMsgNum)+'.MSG/Unknown Zone Error (Proc: ReadFidoMsg)');
          ErrorStrXY('Unknown zone '+MemMsgPath+IntToStr(FidoMsgNum)+'.MSG',12,23,Red + 128,Blue);
}        END;
      END;

      IF (MsgRead) THEN
      BEGIN

        IF (FileSize(FidoFile) - 190) <= SizeOf(BufferArray) THEN
          BufSize := (FileSize(FidoFile) - 190)
        ELSE
          BufSize := SizeOf(BufferArray);

        {$I-} BlockRead(FidoFile,BufferArray,BufSize,MsgLength); {$I+}
        LastError := IOResult;
        IF (LastError <> 0) THEN
        BEGIN
          LogError(MemMsgPath+IntToStr(FidoMsgNum)+'.MSG/Block Read Text Error - '+IntToStr(LastError)+
                   ' (Proc: ReadFidoMsg)');
          ErrorStrXY('Unable to block read text from '+MemMsgPath+IntToStr(FidoMsgNum)+'.MSG',12,23,Red + 128,Blue);
          MsgRead := FALSE;
        END;
      END;
    END;
    IF (IsNetMail) THEN
      IF (MsgRead) AND (Purge_NetMail) THEN
      BEGIN
        {$I-} Close(FidoFile); {$I+}
        LastError := IOResult;
        IF (LastError <> 0) THEN
        BEGIN
          LogError(MemMsgPath+IntToStr(FidoMsgNum)+'.MSG/Close File Error - '+IntToStr(LastError)+
                   ' (Proc: ReadFidoMsg)');
          ErrorStrXY('Unable to close '+MemMsgPath+IntToStr(FidoMsgNum)+'.MSG',12,23,Red + 128,Blue);
        END;
        {$I-} Erase(FidoFile); {$I+}
        LastError := IOResult;
        IF (LastError <> 0) THEN
        BEGIN
          LogError(MemMsgPath+IntToStr(FidoMsgNum)+'.MSG/Erase File Error - '+IntToStr(LastError)+
                   ' (Proc: ReadFidoMsg)');
          ErrorStrXY('Unable to erase '+MemMsgPath+IntToStr(FidoMsgNum)+'.MSG',12,23,Red + 128,Blue);
        END;
      END
      ELSE IF (MsgRead) THEN
      BEGIN
        FidoMsgHdr.Attribute := 260;
        {$I-} Seek(FidoFile,0); {$I+}
        LastError := IOResult;
        IF (LastError <> 0) THEN
        BEGIN
          LogError(MemMsgPath+IntToStr(FidoMsgNum)+'.MSG/Seek Record 0 Error - '+IntToStr(LastError)+
                   ' (Proc: ReadFidoMsg)');
          ErrorStrXY('Unable to seek record in '+MemMsgPath+IntToStr(FidoMsgNum)+'.MSG',12,23,Red + 128,Blue);
        END;
        {$I-} BlockWrite(FidoFile,FidoMsgHdr,SizeOf(FidoMsgHdr)); {$I+}
        LastError := IOResult;
        IF (LastError <> 0) THEN
        BEGIN
          LogError(MemMsgPath+IntToStr(FidoMsgNum)+'.MSG/Block Write Header Error - '+IntToStr(LastError)+
                   ' (Proc: ReadFidoMsg)');
          ErrorStrXY('Unable to block write header to '+MemMsgPath+IntToStr(FidoMsgNum)+'.MSG',12,23,Red + 128,Blue);
        END;
      END;
    IF (NOT (IsNetMail AND MsgRead AND Purge_NetMail)) THEN
    BEGIN
      {$I-} Close(FidoFile); {$I+}
      LastError := IOResult;
      IF (LastError <> 0) THEN
      BEGIN
        LogError(MemMsgPath+IntToStr(FidoMsgNum)+'.MSG/Close File Error - '+IntToStr(LastError)+
                 ' (Proc: ReadFidoMsg)');
        ErrorStrXY('Unable to close '+MemMsgPath+IntToStr(FidoMsgNum)+'.MSG',12,23,Red + 128,Blue);
      END;
    END;
  END;
  ReadFidoMsg := MsgRead;
END;

PROCEDURE Toss(General1: GeneralRecordType; MemMsgArea1: MessageAreaRecordType);
VAR
  MsgTxt: STRING[255];
  FidoTxt: STRING[81];
  AddressStr: STRING[20];
  C: Char;
  Counter,
  Counter1,
  MsgPointer,
  MsgLength: Integer;
  LowMsg,
  HighMsg,
  FidoMsgNum,
  TotalMsgsProcessed: Word;
  FirstTime: Boolean;
BEGIN

  FirstTime := TRUE;

  TotalMsgsProcessed := 0;

  GetMsgLst(MemMsgArea1.MsgPath,LowMsg,HighMsg);

  IF (IsNetMail) AND (HighMsg > 1) THEN
    LowMsg := 1;

  IF (LowMsg <= HighMsg) AND ((HighMsg > 1) OR (IsNetMail)) THEN
  BEGIN

    Assign(RGMsgHdrFile,General1.MsgPath+MemMsgArea1.FileName+'.HDR');
    {$I-} Reset(RGMsgHdrFile); {$I+}
    LastError := IOResult;
    IF (LastError <> 0) THEN
    BEGIN
      {$I-} ReWrite(RGMsgHdrFile); {$I+}
      LastError := IOResult;
      IF (IOResult <> 0) THEN
      BEGIN
        TextColor(Red);
        WriteLn('Unable to create '+General1.MsgPath+MemMsgArea1.FileName+'.HDR.');
        TextColor(LightGray);
        LogError(General1.MsgPath+MemMsgArea1.FileName+'.HDR/ReWrite File Error - '+IntToStr(LastError)+' (Proc: Toss)');
        Exit;
      END;
    END;

    Assign(RGMsgTxtFile,General1.MsgPath+MemMsgArea1.FileName+'.DAT');
    {$I-} Reset(RGMsgTxtFile,1); {$I+}
    LastError := IOResult;
    IF (IOResult <> 0) THEN
    BEGIN
      {$I-} ReWrite(RGMsgTxtFile); {$I+}
      LastError := IOResult;
      IF (IOResult <> 0) THEN
      BEGIN
        TextColor(Red);
        WriteLn('Unable to create '+General1.MsgPath+MemMsgArea1.FileName+'.DAT.');
        TextColor(LightGray);
        LogError(General1.MsgPath+MemMsgArea1.FileName+'.DAT/ReWrite File Error - '+IntToStr(LastError)+' (Proc: Toss)');
        Exit;
      END;
    END;

    {$I-} Seek(RGMsgHdrFile,FileSize(RGMsgHdrFile)); {$I+}
    LastError := IOResult;
    IF (IOResult <> 0) THEN
    BEGIN
      TextColor(Red);
      WriteLn('Unable to seek record in '+General1.MsgPath+MemMsgArea1.FileName+'.HDR.');
      TextColor(LightGray);
      LogError(General1.MsgPath+MemMsgArea1.FileName+'.HDR/Seek End Of File Error - '+IntToStr(LastError)+' (Proc: Toss)');
      Exit;
    END;

    {$I-} Seek(RGMsgTxtFile,FileSize(RGMsgTxtFile)); {$I+}
    LastError := IOResult;
    IF (IOResult <> 0) THEN
    BEGIN
      TextColor(Red);
      WriteLn('Unable to seek record in '+General1.MsgPath+MemMsgArea1.FileName+'.DAT.');
      TextColor(LightGray);
      LogError(General1.MsgPath+MemMsgArea1.FileName+'.DAT/Seek End Of File Error - '+IntToStr(LastError)+' (Proc: Toss)');
      Exit;
    END;

    FOR FidoMsgNum := LowMsg TO HighMsg DO
    BEGIN

      TextColor(LightCyan);
      TextBackGround(Blue);
      Write(PadRightStr(IntToStr(FidoMsgNum),5));

      IF ReadFidoMsg(General1,RGMsgHdr,FidoMsgNum,MemMsgArea1.MsgPath,MsgLength) THEN
      BEGIN

        IF (FirstTime) THEN
        BEGIN
          LogActivity(^M^J);
          FirstTime := FALSE;
        END;
        LogActivity(^M^J);
        LogActivity('Processing: '+IntToStr(FidoMsgNum)+'.MSG'^M^J);
        LogActivity(^M^J);
        LogActivity('From   : '+RGMsgHdr.From.Name+^M^J);
        LogActivity('To     : '+RGMsgHdr.MTO.Name+^M^J);
        LogActivity('Subject: '+RGMsgHdr.Subject+^M^J);
        LogActivity('Date   : '+RGMsgHdr.OriginDate+^M^J);

        Inc(RGMsgHdr.Date);

        RGMsgHdr.Pointer := (FileSize(RGMsgTxtFile) + 1);

        RGMsgHdr.TextSize := 0;

        FidoTxt := '';

        MsgPointer := 0;
        WHILE (MsgPointer < MsgLength) DO
        BEGIN

          MsgTxt := FidoTxt;
          REPEAT
            Inc(MsgPointer);
            C := BufferArray[MsgPointer];
            IF (NOT (C IN [#0,#10,#13,#141])) THEN
              IF (Length(MsgTxt) < 255) THEN
              BEGIN
                Inc(MsgTxt[0]);
                MsgTxt[Length(MsgTxt)] := C;
              END;
          UNTIL ((FidoTxt = #13) OR (C IN [#13,#141]) OR ((Length(MsgTxt) > 79) AND (Pos(#27,MsgTxt) = 0))
                OR (Length(MsgTxt) = 254) OR (MsgPointer >= MsgLength));

          IF (Length(MsgTxt) = 254) THEN
            MsgTxt := MsgTxt + #29;

          Counter := Pos(#1'INTL ',MsgTxt);
          IF (Counter > 0) THEN
          BEGIN
            Inc(Counter,6);
            FOR Counter1 := 1 TO 8 DO
            BEGIN
              AddressStr := '';
              WHILE (MsgTxt[Counter] IN ['0'..'9']) AND (Counter <= Length(MsgTxt)) DO
              BEGIN
                AddressStr := AddressStr + MsgTxt[Counter];
                Inc(Counter);
              END;
              CASE Counter1 OF
                1 : RGMsgHdr.MTO.Zone := StrToInt(AddressStr);
                2 : RGMsgHdr.MTO.Net := StrToInt(AddressStr);
                3 : RGMsgHdr.MTO.Node := StrToInt(AddressStr);
                4 : RGMsgHdr.MTO.Point := StrToInt(AddressStr);
                5 : RGMsgHdr.From.Zone := StrToInt(AddressStr);
                6 : RGMsgHdr.From.Net := StrToInt(AddressStr);
                7 : RGMsgHdr.From.Node := StrToInt(AddressStr);
                8 : RGMsgHdr.From.Point := StrToInt(AddressStr);
              END;
              IF (Counter1 = 3) AND (MsgTxt[Counter] <> '.') THEN
                Inc(Counter1);
              IF (Counter1 = 7) AND (MsgTxt[Counter] <> '.') THEN
                Break;
              Inc(Counter);
            END;
            LogActivity('INTL   : '+IntToStr(RGMsgHdr.MTO.Zone)+
                                ':'+IntToStr(RGMsgHdr.MTO.Net)+
                                '/'+IntToStr(RGMsgHdr.MTO.Node)+
                                ' '+
                                ' '+IntToStr(RGMsgHdr.From.Zone)+
                                ':'+IntToStr(RGMsgHdr.From.Net)+
                                '/'+IntToStr(RGMsgHdr.From.Node)+^M^J);
          END;

          IF (Length(MsgTxt) > 79) THEN
          BEGIN
            Counter := Length(MsgTxt);
            WHILE (MsgTxt[Counter] = ' ') AND (Counter > 1) DO
              Dec(Counter);
            WHILE (Counter > 65) AND (MsgTxt[Counter] <> ' ') DO
              Dec(Counter);
            FidoTxt[0] := Chr(Length(MsgTxt) - Counter);
            Move(MsgTxt[Counter + 1],FidoTxt[1],(Length(MsgTxt) - Counter));
            MsgTxt[0] := Chr(Counter - 1);
          END
          ELSE
            FidoTxt := '';

          IF ((MsgTxt[1] = #1) AND (MASkludge IN MemMsgArea1.MAFlags)) OR
             ((Pos('SEEN-BY',MsgTxt) > 0) AND (MASSeenby IN MemMsgArea1.MAFlags)) OR
             ((Pos('* Origin:',MsgTxt) > 0) AND (MASOrigin IN MemMsgArea1.MAFlags)) THEN
            MsgTxt := ''
          ELSE
          BEGIN
            Inc(RGMsgHdr.TextSize,(Length(MsgTxt) + 1));

            {$I-} BlockWrite(RGMsgTxtFile,MsgTxt,(Length(MsgTxt) + 1)); {$I+}
            LastError := IOResult;
            IF (LastError <> 0) THEN
            BEGIN
              TextColor(Red);
              WriteLn('Unable to block write text to '+General1.MsgPath+MemMsgArea1.FileName+'.DAT.');
              TextColor(LightGray);
              LogError(General1.MsgPath+MemMsgArea1.FileName+'.DAT/Block Write Text Error - '+IntToStr(LastError)+
                       ' (Proc: Toss)');
              Exit;
            END;
          END;

        END;

        IF (IsNetMail) THEN
        BEGIN
          Include(RGMsgHdr.Status,NetMail);
          RGMsgHdr.MTO.UserNum := SearchUser(General1.DataPath,RGMsgHdr.MTO.A1S);
          IF (RGMsgHdr.MTO.UserNum = 0) THEN
            RGMsgHdr.MTO.UserNum := 1;
          UpdateMailWaiting(General1.DataPath,RGMsgHdr.MTO.UserNum);
        END;

        {$I-} Write(RGMsgHdrFile,RGMsgHdr); {$I+}
        LastError := IOResult;
        IF (LastError <> 0) THEN
        BEGIN
          TextColor(Red);
          WriteLn('Unable to write record to '+General1.MsgPath+MemMsgArea1.FileName+'.HDR.');
          TextColor(LightGray);
          LogError(General1.MsgPath+MemMsgArea1.FileName+'.HDR/Write End Of File Error - '+IntToStr(LastError)+
                   ' (Proc: Toss)');
          Exit;
        END;

        Inc(TotalMsgsProcessed);

      END;

      IF (FidoMsgNum < HighMsg) THEN
        Write(#8#8#8#8#8);

    END;

    {$I-} Close(RGMsgHdrFile); {$I+}
    LastError := IOResult;
    IF (IOResult <> 0) THEN
    BEGIN
      TextColor(Red);
      WriteLn('Unable to close '+General1.MsgPath+MemMsgArea1.FileName+'.HDR.');
      TextColor(LightGray);
      LogError(General1.MsgPath+MemMsgArea1.FileName+'.HDR/Close File Error - '+IntToStr(LastError)+' (Proc: Toss)');
      Exit;
    END;

    {$I-} Close(RGMsgTxtFile); {$I+}
    LastError := IOResult;
    IF (IOResult <> 0) THEN
    BEGIN
      TextColor(Red);
      WriteLn('Unable to close '+General1.MsgPath+MemMsgArea1.FileName+'.DAT.');
      TextColor(LightGray);
      LogError(General1.MsgPath+MemMsgArea1.FileName+'.DAT/Close File Error - '+IntToStr(LastError)+' (Proc: Toss)');
      Exit;
    END;

    IF (NOT IsNetMail) THEN
      UpdateHiWater(MemMsgArea1.MsgPath,HighMsg);

  END
  ELSE
    Write('No messages!');

  IF (TotalMsgsProcessed = 0) THEN
    LogActivity('No Messages!'^M^J)
  ELSE
  BEGIN
    LogActivity(^M^J);
    LogActivity('Total processed: '+IntToStr(TotalMsgsProcessed)+^M^J);
    LogActivity(^M^J);
  END;
END;

PROCEDURE Scan(General1: GeneralRecordType; MemMsgArea1: MessageAreaRecordType);
VAR
  DT: DateTime;
  FidoTxt: STRING[81];
  MsgLength: Integer;
  LowMsg,
  HighMsg,
  RGMsgNum,
  FidoMsgNum,
  HighestWritten,
  TotalMsgsProcessed: Word;
  Scanned,
  FirstTime: Boolean;
BEGIN

  Scanned := FALSE;

  TotalMsgsProcessed := 0;

  FirstTime := TRUE;

  GetMsgLst(MemMsgArea1.MsgPath,LowMsg,HighMsg);

  FidoMsgNum := HighMsg;

  Assign(RGMsgHdrFile,General1.MsgPath+MemMsgArea1.FileName+'.HDR');
  {$I-} Reset(RGMsgHdrFile); {$I+}
  LastError := IOResult;
  IF (LastError <> 0) THEN
  BEGIN
    TextColor(Red);
    WriteLn('Unable to open '+General1.MsgPath+MemMsgArea1.FileName+'.HDR.');
    TextColor(LightGray);
    LogError(General1.MsgPath+MemMsgArea1.FileName+'.HDR/Open File Error - '+IntToStr(LastError)+' (Proc: Scan)');
    Exit;
  END;

  Assign(RGMsgTxtFile,General1.MsgPath+MemMsgArea1.FileName+'.DAT');
  {$I-} Reset(RGMsgTxtFile,1); {$I+}
  LastError := IOResult;
  IF (LastError <> 0) THEN
  BEGIN
    TextColor(Red);
    WriteLn('Unable to open '+General1.MsgPath+MemMsgArea1.FileName+'.DAT.');
    TextColor(LightGray);
    LogError(General1.MsgPath+MemMsgArea1.FileName+'.DAT/Open File Error - '+IntToStr(LastError)+' (Proc: Scan)');
    Exit;
  END;

  FOR RGMsgNum := 1 TO FileSize(RGMsgHdrFile) DO
  BEGIN

    {$I-} Seek(RGMsgHdrFile,(RGMsgNum - 1)); {$I+}
    LastError := IOResult;
    IF (LastError <> 0) THEN
    BEGIN
      TextColor(Red);
      WriteLn('Unable to seek record in '+General1.MsgPath+MemMsgArea1.FileName+'.HDR.');
      TextColor(LightGray);
      LogError(General1.MsgPath+MemMsgArea1.FileName+'.HDR/Seek Record '+IntToStr(RGMsgNum - 1)+' Error - '
               +IntToStr(LastError)+' (Proc: Scan)');
      Exit;
    END;

    {$I-} Read(RGMsgHdrFile,RGMsgHdr); {$I+}
    LastError := IOResult;
    IF (LastError <> 0) THEN
    BEGIN
      TextColor(Red);
      WriteLn('Unable to read record from '+General1.MsgPath+MemMsgArea1.FileName+'.HDR.');
      TextColor(LightGray);
      LogError(General1.MsgPath+MemMsgArea1.FileName+'.HDR/Read Record '+IntToStr(RGMsgNum - 1)+' Error - '
               +IntToStr(LastError)+' (Proc: Scan)');
      Exit;
    END;

    IF (NOT (Sent IN RGMsgHdr.Status)) AND
       (NOT (MDeleted IN RGMsgHdr.Status)) AND
       (NOT (UnValidated IN RGMsgHdr.Status)) AND
       (NOT (IsNetMail AND (NOT (NetMail IN RGMsgHdr.Status)))) THEN
    BEGIN

      Inc(FidoMsgNum);

      Assign(FidoFile,MemMsgArea1.MsgPath+IntToStr(FidoMsgNum)+'.MSG');
      {$I-} ReWrite(FidoFile,1); {$I+}
      LastError := IOResult;
      IF (LastError <> 0) THEN
      BEGIN
        TextColor(Red);
        WriteLn('Unable to create '+MemMsgArea1.MsgPath+IntToStr(FidoMsgNum)+'.MSG.');
        TextColor(LightGray);
        LogError(MemMsgArea1.MsgPath+IntToStr(FidoMsgNum)+'.MSG/Rewrite File Error - '+IntToStr(LastError)+' (Proc: Scan)');
        Exit;
      END;

      TextColor(LightCyan);
      TextBackGround(Blue);
      Write(PadRightStr(IntToStr(RGMsgNum),5));

      Include(RGMsgHdr.Status,Sent);

      IF (IsNetMail) THEN
        Include(RGMsgHdr.Status,MDeleted);

      {$I-} Seek(RGMsgHdrFile,(RGMsgNum - 1)); {$I+}
      LastError := IOResult;
      IF (LastError <> 0) THEN
      BEGIN
        TextColor(Red);
        WriteLn('Unable to seek record in '+General1.MsgPath+MemMsgArea1.FileName+'.HDR.');
        TextColor(LightGray);
        LogError(General1.MsgPath+MemMsgArea1.FileName+'.HDR/Seek Record '+IntToStr(RGMsgNum - 1)+
                 ' Error - '+IntToStr(LastError)+' (Proc: Scan)');
        Exit;
      END;

      {$I-} Write(RGMsgHdrFile,RGMsgHdr); {$I+}
      LastError := IOResult;
      IF (LastError <> 0) THEN
      BEGIN
        TextColor(Red);
        WriteLn('Unable to write record to '+General1.MsgPath+MemMsgArea1.FileName+'.HDR.');
        TextColor(LightGray);
        LogError(General1.MsgPath+MemMsgArea1.FileName+'.HDR/Write Record '+IntToStr(RGMsgNum - 1)+
                 ' Error - '+IntToStr(LastError)+' (Proc: Scan)');
        Exit;
      END;

      FillChar(FidoMsgHdr,SizeOf(FidoMsgHdr),#0);

      IF (FirstTime) THEN
      BEGIN
        LogActivity(^M^J);
        FirstTime := FALSE;
      END;
      LogActivity(^M^J);
      LogActivity('Processing: '+IntToStr(FidoMsgNum)+'.MSG'^M^J);
      LogActivity(^M^J);

      FidoTxt := UseName(RGMsgHdr.From.Anon,
                 AOnOff((MARealName IN MemMsgArea1.MAFlags),
                 Caps(RGMsgHdr.From.Real),
                 Caps(RGMsgHdr.From.A1S)));
      Move(FidoTxt[1],FidoMsgHdr.FromUserName[0],Length(FidoTxt));

      LogActivity('From   : '+FidoTxt+^M^J);

      FidoTxt := UseName(RGMsgHdr.MTO.Anon,
                 AOnOff((MARealName IN MemMsgArea1.MAFlags),
                 Caps(RGMsgHdr.MTO.Real),
                 Caps(RGMsgHdr.MTO.A1S)));
      Move(FidoTxt[1],FidoMsgHdr.ToUserName[0],Length(FidoTxt));

      LogActivity('To     : '+FidoTxt+^M^J);

      FidoTxt := StripColor(MemMsgArea1.MAFlags,RGMsgHdr.Subject);
      IF (NOT IsNetMail) AND (RGMsgHdr.FileAttached > 0) THEN
        FidoTxt := StripName(FidoTxt);
      Move(FidoTxt[1],FidoMsgHdr.Subject[0],Length(FidoTxt));

     LogActivity('Subject: '+FidoTxt+^M^J);

      PackToDate(DT,RGMsgHdr.Date);
      FidoTxt := ZeroPad(IntToStr(DT.Day))+
                ' '+Copy(MonthString[DT.Month],1,3)+
                ' '+Copy(IntToStr(DT.Year),3,2)+
                '  '+ZeroPad(IntToStr(DT.Hour))+
                ':'+ZeroPad(IntToStr(DT.Min))+
                ':'+ZeroPad(IntToStr(DT.Sec));
      Move(FidoTxt[1],FidoMsgHdr.DateTime[0],Length(FidoTxt));

      LogActivity('Date   : '+FidoTxt+^M^J);

      IF (IsNetMail) THEN
      BEGIN
        FidoMsgHdr.OrigNet := RGMsgHdr.From.Net;
        FidoMsgHdr.OrigNode := RGMsgHdr.From.Node;
        FidoMsgHdr.DestNet := RGMsgHdr.MTO.Net;
        FidoMsgHdr.DestNode := RGMsgHdr.MTO.Node;

        LogActivity('Origin : '+IntToStr(FidoMsgHdr.OrigNet)+
                            '/'+IntToStr(FidoMsgHdr.OrigNode)+^M^J);

        LogActivity('Destin : '+IntToStr(FidoMsgHdr.DestNet)+
                            '/'+IntToStr(FidoMsgHdr.DestNode)+^M^J);
      END
      ELSE
      BEGIN
        FidoMsgHdr.OrigNet := General1.AKA[MemMsgArea1.AKA].Net;
        FidoMsgHdr.OrigNode := General1.AKA[MemMsgArea1.AKA].Node;
        FidoMsgHdr.DestNet := 0;
        FidoMsgHdr.DestNode := 0;

        LogActivity('Origin : '+IntToStr(General1.AKA[MemMsgArea1.AKA].Net)+
                            '/'+IntToStr(General1.AKA[MemMsgArea1.AKA].Node)+^M^J);

      END;

      IF (IsNetMail) THEN
{$IFDEF MSDOS}
        FidoMsgHdr.Attribute := Word(RGMsgHdr.NetAttribute)
{$ENDIF}
{$IFDEF WIN32}
        FidoMsgHdr.Attribute := NetAttribsToWord(RGMsgHdr.NetAttribute)
{$ENDIF}
      ELSE IF (Prvt IN RGMsgHdr.Status) THEN
        FidoMsgHdr.Attribute := 257
      ELSE
        FidoMsgHdr.Attribute := 256;

      IF (RGMsgHdr.FileAttached > 0) THEN
        FidoMsgHdr.Attribute := (FidoMsgHdr.Attribute + 16);

      {$I-} BlockWrite(FidoFile,FidoMsgHdr,SizeOf(FidoMsgHdr)); {$I+}
      LastError := IOResult;
      IF (LastError <> 0) THEN
      BEGIN
        TextColor(Red);
        WriteLn('Unable to block write header '+MemMsgArea1.MsgPath+IntToStr(FidoMsgNum)+'.MSG');
        TextColor(LightGray);
        LogError(MemMsgArea1.MsgPath+IntToStr(FidoMsgNum)+'.MSG/Block Write Header Error - '+IntToStr(LastError)+
                 ' (Proc: Scan)');
        Exit;
      END;

      {$I-} Seek(RGMsgTxtFile,(RGMsgHdr.Pointer - 1)); {$I+}
      LastError := IOResult;
      IF (LastError <> 0) THEN
      BEGIN
        TextColor(Red);
        WriteLn('Unable to seek text in '+MemMsgArea1.MsgPath+IntToStr(FidoMsgNum)+'.MSG');
        TextColor(LightGray);
        LogError(MemMsgArea1.MsgPath+IntToStr(FidoMsgNum)+'.MSG/Seek Text Error - '+IntToStr(LastError)+
                 ' (Proc: Scan)');
        Exit;
      END;

      IF (IsNetMail) THEN
      BEGIN

        LogActivity('INTL   : '+IntToStr(RGMsgHdr.MTO.Zone)+
                            ':'+IntToStr(RGMsgHdr.MTO.Net)+
                            '/'+IntToStr(RGMsgHdr.MTO.Node)+
                            ' '+
                            ' '+IntToStr(RGMsgHdr.From.Zone)+
                            ':'+IntToStr(RGMsgHdr.From.Net)+
                            '/'+IntToStr(RGMsgHdr.From.Node)+^M^J);

        FidoTxt := #1'INTL '+IntToStr(RGMsgHdr.MTO.Zone)+
                        ':'+IntToStr(RGMsgHdr.MTO.Net)+
                        '/'+IntToStr(RGMsgHdr.MTO.Node)+
                        ' '+IntToStr(RGMsgHdr.From.Zone)+
                        ':'+IntToStr(RGMsgHdr.From.Net)+
                        '/'+IntToStr(RGMsgHdr.From.Node)+#13;

        {$I-} BlockWrite(FidoFile,FidoTxt[1],Length(FidoTxt)); {$I+}
        LastError := IOResult;
        IF (LastError <> 0) THEN
        BEGIN
          TextColor(Red);
          WriteLn('Unable to block write text to '+MemMsgArea1.MsgPath+IntToStr(FidoMsgNum)+'.MSG');
          TextColor(LightGray);
          LogError(MemMsgArea1.MsgPath+IntToStr(FidoMsgNum)+'.MSG/Block Write Text Error - '+IntToStr(LastError)+
                   ' (Proc: Scan)');
          Exit;
        END;

        IF (RGMsgHdr.MTO.Point > 0) THEN
        BEGIN
          LogActivity('TOPT   : '+IntToStr(RGMsgHdr.MTO.Point)+^M^J);

          FidoTxt := #1'TOPT '+IntToStr(RGMsgHdr.MTO.Point)+#13;

          {$I-} BlockWrite(FidoFile,FidoTxt[1],Length(FidoTxt)); {$I+}
          LastError := IOResult;
          IF (LastError <> 0) THEN
          BEGIN
            TextColor(Red);
            WriteLn('Unable to block write text to '+MemMsgArea1.MsgPath+IntToStr(FidoMsgNum)+'.MSG');
            TextColor(LightGray);
            LogError(MemMsgArea1.MsgPath+IntToStr(FidoMsgNum)+'.MSG/Block Write Text Error - '+IntToStr(LastError)+
                     ' (Proc: Scan)');
            Exit;
          END;

        END;

        IF (RGMsgHdr.From.Point > 0) THEN
        BEGIN
          LogActivity('FMPT   : '+IntToStr(RGMsgHdr.From.Point)+^M^J);

          FidoTxt := #1'FMPT '+IntToStr(RGMsgHdr.From.Point)+#13;

          {$I-} BlockWrite(FidoFile,FidoTxt[1],Length(FidoTxt)); {$I+}
          LastError := IOResult;
          IF (LastError <> 0) THEN
          BEGIN
            TextColor(Red);
            WriteLn('Unable to block write text to '+MemMsgArea1.MsgPath+IntToStr(FidoMsgNum)+'.MSG');
            TextColor(LightGray);
            LogError(MemMsgArea1.MsgPath+IntToStr(FidoMsgNum)+'.MSG/Block Write Text Error - '+IntToStr(LastError)+
                     ' (Proc: Scan)');
            Exit;
          END;

        END;

        FidoTxt := #1'MSGID: '+IntToStr(RGMsgHdr.From.Zone)+
                           ':'+IntToStr(RGMsgHdr.From.Net)+
                           '/'+IntToStr(RGMsgHdr.From.Node)+
                           ' '+Hex(Random($FFFF),4)+Hex(Random($FFFF),4);
        IF (RGMsgHdr.From.Point > 0) THEN
          FidoTxt := FidoTxt +'.'+IntToStr(RGMsgHdr.From.Point);

        FidoTxt := FidoTxt + #13;

        {$I-} BlockWrite(FidoFile,FidoTxt[1],Length(FidoTxt)); {$I+}
        LastError := IOResult;
        IF (LastError <> 0) THEN
        BEGIN
          TextColor(Red);
          WriteLn('Unable to block write text to '+MemMsgArea1.MsgPath+IntToStr(FidoMsgNum)+'.MSG');
          TextColor(LightGray);
          LogError(MemMsgArea1.MsgPath+IntToStr(FidoMsgNum)+'.MSG/Block Write Text Error - '+IntToStr(LastError)+
                   ' (Proc: Scan)');
          Exit;
        END;

      END;

      MsgLength := 0;

      IF (RGMsgHdr.TextSize > 0) THEN
        REPEAT

          {$I-} BlockRead(RGMsgTxtFile,FidoTxt[0],1); {$I+}
          LastError := IOResult;
          IF (LastError <> 0) THEN
          BEGIN
            TextColor(Red);
            WriteLn('Unable to block read text from '+MemMsgArea1.MsgPath+IntToStr(FidoMsgNum)+'.MSG');
            TextColor(LightGray);
            LogError(MemMsgArea1.MsgPath+IntToStr(FidoMsgNum)+'.MSG/Block Read Text Error - '+IntToStr(LastError)+
                     ' (Proc: Scan)');
            Exit;
          END;

          {$I-} BlockRead(RGMsgTxtFile,FidoTxt[1],Ord(FidoTxt[0])); {$I+}
          LastError := IOResult;
          IF (LastError <> 0) THEN
          BEGIN
            TextColor(Red);
            WriteLn('Unable to block read text from '+MemMsgArea1.MsgPath+IntToStr(FidoMsgNum)+'.MSG');
            TextColor(LightGray);
            LogError(MemMsgArea1.MsgPath+IntToStr(FidoMsgNum)+'.MSG/Block Read Text Error - '+IntToStr(LastError)+
                     ' (Proc: Scan)');
            Exit;
          END;

          Inc(MsgLength,(Length(FidoTxt) + 1));

          WHILE (Pos(#0,FidoTxt) > 0) DO
            Delete(FidoTxt,Pos(#0,FidoTxt),1);

          IF (FidoTxt[Length(FidoTxt)] = #29) THEN
            Dec(FidoTxt[0])

          (* NOTE: Should this be (Pos(#27,FidoTxt) <> 0) *)

          ELSE IF (Pos(#27,FidoTxt) = 0) THEN
            FidoTxt := StripColor(MemMsgArea1.MAFlags,FidoTxt);

          FidoTxt := FidoTxt + #13;

          {$I-} BlockWrite(FidoFile,FidoTxt[1],Length(FidoTxt)); {$I+}
          LastError := IOResult;
          IF (LastError <> 0) THEN
          BEGIN
            TextColor(Red);
            WriteLn('Unable to block write text to '+MemMsgArea1.MsgPath+IntToStr(FidoMsgNum)+'.MSG');
            TextColor(LightGray);
            LogError(MemMsgArea1.MsgPath+IntToStr(FidoMsgNum)+'.MSG/Block Write Text Error - '+IntToStr(LastError)+
                     ' (Proc: Scan)');
            Exit;
          END;

        UNTIL (MsgLength >= RGMsgHdr.TextSize);

      {$I-} Close(FidoFile); {$I+}
      LastError := IOResult;
      IF (LastError <> 0) THEN
      BEGIN
        TextColor(Red);
        WriteLn('Unable to close '+MemMsgArea1.MsgPath+IntToStr(FidoMsgNum)+'.MSG.');
        TextColor(LightGray);
        LogError(MemMsgArea1.MsgPath+IntToStr(FidoMsgNum)+'.MSG/Close File Error - '+IntToStr(LastError)+' (Proc: Scan)');
        Exit;
      END;

      Write(#8#8#8#8#8);

      Scanned := TRUE;

      Inc(TotalMsgsProcessed);
    END;

    HighestWritten := FidoMsgNum;

  END;

  IF (NOT IsNetMail) THEN
    UpdateHiWater(MemMsgArea1.MsgPath,HighestWritten);

  {$I-} Close(RGMsgHdrFile); {$I+}
  LastError := IOResult;
  IF (LastError <> 0) THEN
  BEGIN
    TextColor(Red);
    WriteLn('Unable to close '+General1.MsgPath+MemMsgArea1.FileName+'.HDR.');
    TextColor(LightGray);
    LogError(General1.MsgPath+MemMsgArea1.FileName+'.HDR/Close File Error - '+IntToStr(LastError)+' (Proc: Scan)');
    Exit;
  END;

  {$I-} Close(RGMsgTxtFile); {$I+}
  LastError := IOResult;
  IF (LastError <> 0) THEN
  BEGIN
    TextColor(Red);
    WriteLn('Unable to close '+General1.MsgPath+MemMsgArea1.FileName+'.DAT.');
    TextColor(LightGray);
    LogError(General1.MsgPath+MemMsgArea1.FileName+'.DAT/Close File Error - '+IntToStr(LastError)+' (Proc: Scan)');
    Exit;
  END;

  IF (NOT Scanned) THEN
  BEGIN
    LogActivity('No Messages!'^M^J);
    Write('No messages!');
  END
  ELSE
  BEGIN
    LogActivity(^M^J);
    LogActivity('Total processed: '+IntToStr(TotalMsgsProcessed)+^M^J);
    LogActivity(^M^J);
  END;

END;

BEGIN
  DisplayMain(White,Blue);

  IF (ParamCount = 0) THEN
    HaltErrorStrXY('No command line parameters specified!',12,23,Red + 128,Blue,1);

  TempParamStr := '';
  ParamFound := FALSE;
  ParamCounter := 1;
  WHILE (ParamCounter <= ParamCount) DO
  BEGIN
    IF (SC(ParamStr(ParamCounter),1) = '-') THEN
    BEGIN
      CASE SC(ParamStr(ParamCounter),2) OF
        'A' : Absolute_Scan := TRUE;
        'D' : Purge_NetMail := FALSE;
        'F' : FastPurge := FALSE;
        'I' : Ignore_1Msg := FALSE;
        'L' : Activity_Log := TRUE;
        'N' : Process_NetMail := FALSE;
        'O' : NetMailOnly := TRUE;
        'P' : BEGIN
                Purge_Dir := TRUE;
                ParamFound := TRUE;
              END;
        'S' : BEGIN
                Scan_Mail := TRUE;
                ParamFound := TRUE;
              END;
        'T' : BEGIN
                Toss_Mail := TRUE;
                ParamFound := TRUE;
              END;
      END;
      TempParamStr := TempParamStr + AllCaps(ParamStr(ParamCounter))+' ';
    END;
    Inc(ParamCounter);
  END;

  Dec(TempParamStr[0]);

  IF (NOT ParamFound) THEN
    HaltErrorStrXY('Valid commands are -T, -P, -S, (With or without options)',12,23,Red + 128,Blue,1);

  GetDir(0,StartDir);

  FileMode := 66;
{$IFDEF WIN32}
  FileModeReadWrite := FileMode;
{$ENDIF}

  GetGeneral(General);

  GeneralPaths(General);

  GeneralFiles(General);

  LogActivity(^M^J);
  LogActivity(ToDate8(DateStr)+' '+TimeStr+': Renemail initiated with '+TempParamStr+' parameter(s).'^M^J);
  LogActivity(^M^J);

  IF (Process_NetMail) AND (Toss_Mail) OR (Scan_Mail) THEN
  BEGIN
    IsNetMail := TRUE;
    MemMsgArea.MsgPath := General.NetMailPath;
    MemMsgArea.FileName := 'EMAIL';
    MemMsgArea.MAFlags := [MASkludge];
    IF (Toss_Mail) THEN
    BEGIN
      LogActivity(' Tossing:  NETMAIL - ');
      TextColor(3);
      Write(' Tossing: ');
      TextColor(14);
      Write(' NETMAIL - ');
      Toss(General,MemMsgArea);
      WriteLn;
    END;
    IF (Scan_Mail) THEN
    BEGIN
      LogActivity('Scanning:  NETMAIL - ');
      TextColor(3);
      Write('Scanning: ');
      TextColor(14);
      Write(' NETMAIL - ');
      TextColor(11);
      Scan(General,MemMsgArea);
      WriteLn;
    END;
    IsNetMail := FALSE;
  END;

  IF (NOT NetMailOnly) THEN
  BEGIN
    IF (Toss_Mail) OR (Purge_Dir) OR (Scan_Mail) THEN
    BEGIN
      Assign(MessageAreaFile,General.DataPath+'MBASES.DAT');
      {$I-} Reset(MessageAreaFile); {$I+}
      LastError := IOResult;
      IF (LastError <> 0) THEN
      BEGIN
        LogError(General.DataPath+'MBASES.DAT/Open File Error - '+IntToStr(LastError)+' (Proc: Main)');
        HaltErrorStrXY('Unable to open '+General.DataPath+'MBASES.DAT!',12,23,Red + 128,Blue,1);
      END;
      MsgArea := 1;
      WHILE (MsgArea <= FileSize(MessageAreaFile)) DO
      BEGIN
        {$I-} Seek(MessageAreaFile,(MsgArea - 1)); {$I+}
        LastError := IOResult;
        IF (LastError <> 0) THEN
        BEGIN
          TextColor(Red);
          WriteLn('Unable to seek record in '+General.DataPath+'MBASES.DAT');
          TextColor(LightGray);
          LogError(General.DataPath+'MBASES.DAT/Seek Record '+IntToStr(MsgArea - 1)+' Error - '+IntToStr(LastError)+
                   ' (Proc: Main)');
          Exit;
        END;
        {$I-} Read(MessageAreaFile,MemMsgArea); {$I+}
        LastError := IOResult;
        IF (LastError <> 0) THEN
        BEGIN
          TextColor(Red);
          WriteLn('Unable to read record from '+General.DataPath+'MBASES.DAT');
          TextColor(LightGray);
          LogError(General.DataPath+'MBASES.DAT/Read Record '+IntToStr(MsgArea - 1)+' Error - '+IntToStr(LastError)+
                   ' (Proc: Main)');
          Exit;
        END;
        IF (MemMsgArea.MAType = 1) AND (NOT Scan_Mail OR (Absolute_Scan OR (MAScanOut IN MemMsgArea.MAFlags))) THEN
        BEGIN
          IF (Toss_Mail) THEN
          BEGIN
            LogActivity(' Tossing: '+PadRightStr(MemMsgArea.FileName,8)+' - ');
            TextColor(3);
            Write(' Tossing: ');
            TextColor(14);
            Write(PadRightStr(MemMsgArea.FileName,8)+' - ');
            TextColor(11);
            Toss(General,MemMsgArea);
            WriteLn;
          END;
          IF (Purge_Dir) THEN
          BEGIN
            LogActivity(' Purging: '+PadRightStr(MemMsgArea.FileName,8)+' - ');
            TextColor(3);
            Write(' Purging: ');
            TextColor(14);
            Write(PadRightStr(MemMsgArea.FileName,8)+' - ');
            TextColor(11);
            PurgeDir(MemMsgArea.MsgPath);
            WriteLn;
          END;
          IF (Scan_Mail) THEN
          BEGIN
            LogActivity('Scanning: '+PadRightStr(MemMsgArea.FileName,8)+' - ');
            TextColor(3);
            Write('Scanning: ');
            TextColor(14);
            Write(PadRightStr(MemMsgArea.FileName,8)+' - ');
            TextColor(11);
            Scan(General,MemMsgArea);
            WriteLn;
          END;
          IF (Scan_Mail) AND (MAScanOut IN MemMsgArea.MAFlags) THEN
          BEGIN
            {$I-} Seek(MessageAreaFile,(MsgArea - 1)); {$I+}
            LastError := IOResult;
            IF (LastError <> 0) THEN
            BEGIN
              TextColor(Red);
              WriteLn('Unable to seek record in '+General.DataPath+'MBASES.DAT');
              TextColor(LightGray);
              LogError(General.DataPath+'MBASES.DAT/Seek Record '+IntToStr(MsgArea - 1)+' Error - '+IntToStr(LastError)+
                       ' (Proc: Main)');
              Exit;
            END;
            Exclude(MemMsgArea.MAFlags,MAScanOut);
            {$I-} Write(MessageAreaFile,MemMsgArea); {$I+}
            LastError := IOResult;
            IF (LastError <> 0) THEN
            BEGIN
              TextColor(Red);
              WriteLn('Unable to write record to '+General.DataPath+'MBASES.DAT');
              TextColor(LightGray);
              LogError(General.DataPath+'MBASES.DAT/Write Record '+IntToStr(MsgArea - 1)+' Error - '+IntToStr(LastError)+
                       ' (Proc: Main)');
              Exit;
            END;
          END;
        END;
        Inc(MsgArea);
      END;
      {$I-} Close(MessageAreaFile); {$I+}
      LastError := IOResult;
      IF (LastError <> 0) THEN
      BEGIN
        TextColor(Red);
        WriteLn('Unable to close '+General.DataPath+'MBASES.DAT');
        TextColor(LightGray);
        LogError(General.DataPath+'MBASES.DAT/Close File Error - '+IntToStr(LastError)+' (Proc: Main)');
        Exit;
      END;
    END;
  END;

  LogActivity(^M^J);
  LogActivity(ToDate8(DateStr)+' '+TimeStr+': Renemail completed with '+TempParamStr+' parameter(s).'^M^J);

  ChDir(StartDir);

  Window(1,1,80,25);

  GoToXY(1,25);

END.


