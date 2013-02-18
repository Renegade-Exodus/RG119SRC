{$M 49152,0,65536}
PROGRAM RGUPDT1;

USES
  Crt,
  Dos;

{$I RECORDS.PAS}

CONST
  DYNY: BOOLEAN = FALSE;

TYPE
  OldValidationRecordType =
{$IFDEF WIN32} PACKED {$ENDIF} RECORD
    Description: STRING[25];           { description }
    NewSL,                             { new SL }
    NewDSL,                            { new DSL }
    NewMenu: Byte;                     { User start out menu }
    Expiration: Word;                  { days until expiration }
    NewFP,                             { nothing }
    NewCredit: LongInt;                { new credit }
    ExpireTo: Char;                    { validation level to expire to }
    SoftAR,                            { TRUE=AR added to current, else replaces }
    SoftAC: Boolean;                   { TRUE=AC    "   "   "       "      "  }
    NewAR: ARFlagSet;                  { new AR }
    NewAC: FlagSet;                    { new AC }
  END;

  OldGeneralRecordType =
{$IFDEF WIN32} PACKED {$ENDIF} RECORD
    ForgotPWQuestion: STRING[70];

    QWKWelcome,                        { QWK welcome file name }
    QWKNews,                           { QWK news file name }
    QWKGoodbye,                        { QWK goodbye file name }
    Origin: STRING[50];                { Default Origin line }

    DataPath,                          { DATA path }
    MiscPath,                          { MISC path }
    LogsPath,                          { LOGS path }
    MsgPath,                           { MSGS path }
    NodePath,                          { NODE list path }
    TempPath,                          { TEMP path }
    ProtPath,                          { PROT path }
    ArcsPath,                          { ARCS path }
    MultPath,                          { MULT path }
    FileAttachPath,                    { directory for file attaches }
    QWKLocalPath,                      { QWK path for local usage }
    DefEchoPath,                       { default echomail path }
    NetmailPath,                        { path to netmail }
    BBSName: STRING[40];               { BBS name }

    SysOpName: STRING[30];             { SysOp's name }

    Version: STRING[20];

    BBSPhone: STRING[12];              { BBS phone number }

    LastDate: STRING[10];              { last system date }

    PacketName,                        { QWK packet name }
    BulletPrefix: STRING[8];           { default bulletins filename }

    SysOpPW,                           { SysOp password }
    NewUserPW,                         { newuser password }
    MinBaudOverride,                   { override minimum baud rate }
    QWKNetworkACS,                     { QWK network REP ACS }
    LastOnDatACS,
    SOP,                               { SysOp }
    CSOP,                              { Co-SysOp }
    MSOP,                              { Message SysOp }
    FSOP,                              { File SysOp }
    SPW,                               { SysOp PW at logon }
    AddChoice,                         { Add voting choices acs }
    NormPubPost,                       { make normal public posts }
    NormPrivPost,                      { send normal e-mail }
    AnonPubRead,                       { see who posted public anon }
    AnonPrivRead,                      { see who sent anon e-mail }
    AnonPubPost,                       { make anon posts }
    AnonPrivPost,                      { send anon e-mail }
    SeeUnval,                          { see unvalidated files }
    DLUnval,                           { DL unvalidated files }
    NoDLRatio,                         { no UL/DL ratio }
    NoPostRatio,                       { no post/call ratio }
    NoFileCredits,                     { no file credits checking }
    ULValReq,                          { uploads require validation }
    TeleConfMCI,                       { ACS access for MCI codes while teleconfin' }
    OverrideChat,                      { override chat hours }
    NetMailACS,                        { do they have access to netmail? }
    Invisible,                           { Invisible mode? }
    FileAttachACS,                     { ACS to attach files to messages }
    ChangeVote: ACString;              { ACS to change their vote }

    MaxPrivPost,                     { max email can send per call }
    MaxFBack,                        { max feedback per call }
    MaxPubPost,                      { max posts per call }
    MaxChat,                         { max sysop pages per call }
    MaxWaiting,                       { max mail waiting }
    CSMaxWaiting,                     { max mail waiting for Co-SysOp + }
    MaxMassMailList,
    MaxLogonTries,                   { tries allowed for PW's at logon }
    SysOpColor,                       { SysOp color in chat mode }
    UserColor,                        { user color in chat mode }
    SliceTimer,
    MaxBatchDLFiles,
    MaxBatchULFiles,
    Text_Color,                       { color OF standard text }
    Quote_Color,                      { color OF quoted text }
    Tear_Color,                       { color OF tear line }
    Origin_Color,                      { color OF origin line }
    BackSysOpLogs,                    { days to keep SYSOP##.LOG }
    EventWarningTime,                 { minutes before event to warn user }
    WFCBlankTime,                      { minutes before blanking WFC menu }
    AlertBeep,                         { time between alert beeps - Was Integer }
    FileCreditComp,                   { file credit compensation ratio }
    FileCreditCompBaseSize,           { file credit area compensation size }
    ULRefund,                         { percent OF time to refund on ULs }
    GlobalMenu,
    AllStartMenu,
    ShuttleLogonMenu,
    NewUserInformationMenu,
    FileListingMenu,
    MessageReadMenu,
    CurWindow,                         { type OF SysOp window in use }
    SwapTo: Byte;                      { Swap where?    }

    LowTime,                           { SysOp begin minute (in minutes) }
    HiTime,                            { SysOp END time }
    DLLowTime,                         { normal downloading hours begin.. }
    DLHiTime,                          { ..and END }
    MinBaudLowTime,                    { minimum baud calling hours begin.. }
    MinBaudHiTime,                     { ..and END }
    MinBaudDLLowTime,                  { minimum baud downloading hours begin.. }
    MinBaudDLHiTime,                   { ..and END }
    MinSpaceForPost,                   { minimum drive space left to post }
    MinSpaceForUpload,                 { minimum drive space left to upload }

    NewApp,                            { send new user application to # }
    TimeOutBell,                       { minutes before timeout beep }
    TimeOut,                           { minutes before timeout }
    ToSysOpDir,                        { SysOp file area }
    CreditMinute,                      { Credits per minute }
    CreditPost,                        { Credits per post }
    CreditEmail,                       { Credits per Email sent }
    CreditFreeTime,                    { Amount OF "Free" time given to user at logon }
    NumUsers,                          { number OF users }
    PasswordChange,                    { change password at least every x days }
    RewardRatio,                       { % OF file points to reward back }
    CreditInternetMail,                { cost for Internet mail }
    BirthDateCheck: Integer;           { check user's birthdate every xx logons }

    MaxQWKTotal,                       { max msgs in a packet, period }
    MaxQWKBase,                        { max msgs in a area }
    DaysOnline: Word;                  { days online }

    MinimumBaud,                       { minimum baud rate to logon }
    MinimumDLBaud,                     { minimum baud rate to download }
    MaxDepositEver,
    MaxDepositPerDay,
    MaxWithdrawalPerDay,
    CallerNum,                         { system caller number }
    RegNumber,                         { registration number }
    TotalCalls,                        { incase different from callernum }
    TotalUsage,                        { total usage in minutes }
    TotalPosts,                        { total number OF posts }
    TotalDloads,                       { total number OF dloads }
    TotalUloads,                       { total number OF uloads }
    MinResume,                        { min K to allow resume-later }
    MaxInTemp: LongInt;                { max K allowed in TEMP }

    AllowAlias,                       { allow handles? }
    PhonePW,                          { phone number password in logon? }
    LocalSec,                         { use local security? }
    GlobalTrap,                       { trap everyone's activity? }
    AutoChatOpen,                     { automatically open chat buffer? }
    AutoMInLogon,                     { Auto-Message at logon? }
    BullInLogon,                      { bulletins at logon? }
    YourInfoInLogon,                  { "Your Info" at logon? }
    OffHookLocalLogon,                { phone off-hook for local logons? }
    ForceVoting,                      { manditory voting? }
    CompressBases,                    { "compress" file/msg area numbers? }
    SearchDup,                         { search for dupes files when UL? }
    ForceBatchDL,
    LogonQuote,
    UserAddQuote,
    StripCLog,                         { strip colors from SysOp log? }
    SKludge,                          { show kludge lines? }
    SSeenby,                          { show SEEN-BY lines? }
    SOrigin,                          { show origin line? }
    AddTear,                           { show tear line? }
    ShuttleLog,                        { Use Shuttle Logon? }
    ClosedSystem,                      { Allow new users? }
    SwapShell,                         { Swap on shell? }
    UseEMS,                            { use EMS for overlay }
    UseBios,                            { use BIOS for video output }
    UseIEMSI,                          { use IEMSI }
    ULDLRatio,                        { use UL/DL ratios? }
    FileCreditRatio,                   { use auto file-credit compensation? }
    ValidateAllFiles,                  { validate files automatically? }
    FileDiz,                            { Search/Import file_id.diz }
    SysOpPword,                        { check for sysop password? }
    TrapTeleConf,                      { Trap teleconferencing to ROOMx.TRP? }
    IsTopWindow,                       { is window at top OF screen? }
    ReCompress,                        { recompress like archives? }
    RewardSystem,                       { use file rewarding system? }
    TrapGroup,                         { record group chats? }
    QWKTimeIgnore,                     { ignore time remaining for qwk download? }
    NetworkMode,                       { Network mode ? }
    WindowOn,                          { is the sysop window on? }
    ChatCall,                          { Whether system keeps beeping after chat}
    DailyLimits,                        { Daily file limits on/off }
    MultiNode,                         { enable multinode support }
    PerCall,                           { time limits are per call or per day?}
    TestUploads: Boolean;              { perform integrity tests on uploads? }

    FileArcInfo:
      ARRAY [1..MaxArcs] OF FileArcInfoRecordType;           { archive specs }

    FileArcComment:
      ARRAY [1..3] OF STRING[40];    { BBS comment files for archives }

    Aka: ARRAY [0..20] OF
    {$IFDEF WIN32} PACKED {$ENDIF} RECORD { 20 Addresses }
      Zone,                           { 21st is for UUCP address }
      Net,
      Node,
      Point: Word;
    END;

    NewUserToggles: ARRAY [1..20] OF Byte;

    OldValidation: ARRAY ['A'..'Z'] OF
      OldValidationRecordType;         { Validation records A - Z }

    Macro: ARRAY [0..9] OF STRING[100]; { sysop macros }

    Netattribute: NetAttribs;          { default netmail attribute }

    TimeAllow,                        { time allowance }
    CallAllow,                        { call allowance }
    DLRatio,                          { # ULs/# DLs ratios }
    DLKRatio,                         { DLk/ULk ratios }
    PostRatio,                        { posts per call ratio }
    DLOneday,                         { Max number OF dload files in one day}
    DLKOneDay: SecurityRangeType;     { Max k downloaded in one day}
  END;

function sqoutsp(s:string):string;
begin
  while (pos(' ',s)>0) do delete(s,pos(' ',s),1);
  sqoutsp:=s;
end;

function exist(fn: astr): boolean;
var
  srec: searchrec;
begin
  findfirst(sqoutsp(fn),anyfile,srec);
  exist := (doserror = 0);
end;

FUNCTION SYN(B: BOOLEAN): STRING;
BEGIN
  IF (B) THEN
    SYN := 'Yes'
  ELSE
    SYN := 'No ';
END;

FUNCTION YN: BOOLEAN;
VAR
  C: CHAR;
BEGIN
  Write(SQOutSp(SYN(DYNY)));
  REPEAT
    C := UpCase(Char(ReadKey));
  UNTIL (C IN ['Y','N',^M]);
  IF (DYNY) AND (C <> 'N') THEN
    C := 'Y';
  IF (DYNY) AND (C = 'N') THEN
    Write(#8#8#8'No ')
  ELSE IF (NOT DYNY) AND (C = 'Y') THEN
    Write(#8#8'Yes');
  WriteLn;
  YN := (C = 'Y');
  DYNY := FALSE;
end;

FUNCTION PYNQ(CONST S: AStr): BOOLEAN;
BEGIN
  Write(S);
  PYNQ := YN;
END;

FUNCTION Caps(s: STRING): STRING;
VAR
  Counter: Integer;  { must be Integer }
BEGIN
  IF (s[1] IN ['a'..'z']) THEN
    Dec(s[1],32);
  FOR Counter := 2 TO Length(s) DO
    IF (s[Counter - 1] IN ['a'..'z','A'..'Z']) THEN
      IF (s[Counter] IN ['A'..'Z']) THEN
        Inc(s[Counter],32)
      ELSE
    ELSE
      IF (s[Counter] IN ['a'..'z']) THEN
        Dec(s[Counter],32);
  Caps := s;
END;

FUNCTION IntToStr(L: LongInt): STRING;
VAR
  S: STRING[11];
BEGIN
  Str(L,S);
  IntToStr := S;
END;

FUNCTION ReadUsers(OldGeneral: OldGeneralRecordType): Boolean;
VAR
  TFile: Text;
  UserFile: FILE OF UserRecordType;
  User: UserRecordType;
  RecNum,
  RecNum1,
  RecNum2: Integer;
BEGIN
  Assign(UserFile,OldGeneral.DataPath+'USERS.DAT');
  Reset(UserFile);

  Write('Number of users with invalid expiration setup ... ');

  Assign(TFile,'EXPIRE.TXT');
  ReWrite(TFile);
  WriteLn(TFile,'Users with invalid expiration setup:');
  Writeln(TFile,'');

  RecNum1 := 0;
  RecNum := 0;
  WHILE (RecNum <= (FileSize(UserFile) - 1)) DO
  BEGIN
    Seek(UserFile,RecNum);
    Read(UserFile,User);
    IF (User.Expiration = 0) AND (User.ExpireTo <> ' ') OR
       (User.Expiration <> 0) AND (User.ExpireTo = ' ') THEN
    BEGIN
      WriteLn(TFile,Caps(User.Name)+' #'+IntToStr(RecNum));
      Inc(RecNum1);
    END;
    Inc(RecNum);
  END;
  WriteLn(TFile);
  Close(TFile);
  IF (RecNum1 = 0) THEN
    Erase(TFile);
  WriteLn(IntToStr(RecNum1));

  Write('Number of users with invalid expire to key ... ');

  Assign(TFile,'KEY.TXT');
  ReWrite(TFile);
  WriteLn(TFile,'Users with invalid expire to keys:');
  WriteLn(TFile,'');

  Reset(UserFile);
  RecNum2 := 0;
  RecNum := 0;
  WHILE (RecNum <= (FileSize(UserFile) - 1)) DO
  BEGIN
    Seek(UserFile,RecNum);
    Read(UserFile,User);
    IF (User.ExpireTo <> ' ') THEN
      IF (OldGeneral.OldValidation[User.ExpireTo].Description = '') THEN
      BEGIN
        WriteLn(TFile,Caps(User.Name)+' #'+IntToStr(RecNum));
        Inc(RecNum2);
      END;
    Inc(RecNum);
  END;
  Close(TFile);
  IF (RecNum2 = 0) THEN
    Erase(TFile);
  WriteLn(IntToStr(RecNum2));

  Close(UserFile);
  ReadUsers := (RecNum1 = 0) AND (RecNum2 = 0);
END;

PROCEDURE CreateValidationRec(OldGeneral:  OldGeneralRecordType);
VAR
  ValidationFile: FILE OF ValidationRecordType;
  Validation: ValidationRecordType;
  UserFile: FILE OF UserRecordType;
  User: UserRecordType;
  C: Char;
BEGIN
  Write('Creating "VALIDATE.DAT" file ... ');

  Assign(UserFile,OldGeneral.DataPath+'USERS.DAT');
  Reset(UserFile);
  Seek(UserFile,0);
  Read(UserFile,User);
  Close(UserFile);

  Assign(ValidationFile,OldGeneral.DataPath+'VALIDATE.DAT');
  ReWrite(ValidationFile);
  FOR C := 'A' TO 'Z' DO
    IF (OldGeneral.OldValidation[C].Description <> '') THEN
    BEGIN
      WITH Validation DO
      BEGIN
        IF (C = 'A') THEN
          Key := '!'
        ELSE
          Key := C;
        IF (OldGeneral.OldValidation[C].Expiration = 0) THEN
          ExpireTo := ' '
        ELSE
          ExpireTo := OldGeneral.OldValidation[C].ExpireTo;
        IF (C = 'A') THEN
          Description := 'New User Validation'
        ELSE
          Description := OldGeneral.OldValidation[C].Description;
        UserMsg := 'You have been validated, enjoy the system!';
        IF (OldGeneral.OldValidation[C].NewSL < User.SL) THEN
          NewSL := User.SL
        ELSE
          NewSL := OldGeneral.OldValidation[C].NewSL;
        IF (OldGeneral.OldValidation[C].NewDSL < User.DSL) THEN
          NewDSL := User.DSL
        ELSE
          NewDSL := OldGeneral.OldValidation[C].NewDSL;
        NewMenu := OldGeneral.OldValidation[C].NewMenu;
        IF (OldGeneral.OldValidation[C].ExpireTo = ' ') THEN
          Expiration := 0
        ELSE
          Expiration := OldGeneral.OldValidation[C].Expiration;
        NewFP := OldGeneral.OldValidation[C].NewFP;
        NewCredit := OldGeneral.OldValidation[C].NewCredit;
        SoftAR := OldGeneral.OldValidation[C].SoftAR;
        SoftAC := OldGeneral.OldValidation[C].SoftAR;
        NewAR := OldGeneral.OldValidation[C].NewAR;
        NewAC := OldGeneral.OldValidation[C].NewAC;
      END;
      Write(ValidationFile,Validation);
    END;
  Close(ValidationFile);
  Writeln('Done');
END;

PROCEDURE ConvertGeneralRec(OldGeneral: OldGeneralRecordType);
VAR
  OldGeneralFile: FILE OF OldGeneralRecordType;
  GeneralFile: FILE OF GeneralRecordType;
  General: GeneralRecordType;
  C: Char;
  Counter: Byte;
BEGIN
  Write('Converting "RENEGADE.DAT" file ... ');
  Assign(OldGeneralFile,'RENEGADE.DAT');
  Reset(OldGeneralFile);
  Assign(GeneralFile,'RENEGADE.NEW');
  ReWrite(GeneralFile);
  Seek(OldGeneralFile,0);
  Read(OldGeneralFile,OldGeneral);
  FillChar(General,SizeOf(General),0);
  WITH General DO
  BEGIN
    ForgotPWQuestion := OldGeneral.ForgotPWQuestion;

    QWKWelcome := OldGeneral.QWKWelcome;
    QWKNews := OldGeneral.QWKNews;
    QWKGoodbye := OldGeneral.QWKGoodbye;
    Origin := OldGeneral.Origin;

    DataPath := OldGeneral.DataPath;
    MiscPath := OldGeneral.MiscPath;
    LogsPath := OldGeneral.LogsPath;
    MsgPath := OldGeneral.MsgPath;
    NodePath := OldGeneral.NodePath;
    TempPath := OldGeneral.TempPath;
    ProtPath := OldGeneral.ProtPath;
    ArcsPath := OldGeneral.ArcsPath;
    MultPath := OldGeneral.MultPath;
    FileAttachPath := OldGeneral.FileAttachPath;
    QWKLocalPath := OldGeneral.QWKLocalPath;
    DefEchoPath := OldGeneral.DefEchoPath;
    NetmailPath := OldGeneral.NetMailPath;
    BBSName := OldGeneral.BBSName;

    SysOpName := OldGeneral.SysOpName;

    Version := Ver;

    BBSPhone := OldGeneral.BBSPhone;

    LastDate := OldGeneral.LastDate;

    PacketName := OldGeneral.PacketName;
    BulletPrefix := OldGeneral.BulletPrefix;

    SysOpPW := OldGeneral.SysOpPw;
    NewUserPW := OldGeneral.NewUserPW;
    MinBaudOverride := OldGeneral.MinBaudOverride;
    QWKNetworkACS := OldGeneral.QWKNetworkACS;
    LastOnDatACS := OldGeneral.LastOnDatACS;
    SOP := OldGeneral.SOP;
    CSOP := OldGeneral.CSOP;
    MSOP := OldGeneral.MSOP;
    FSOP := OldGeneral.FSOP;
    SPW := OldGeneral.SPW;
    AddChoice := OldGeneral.AddChoice;
    NormPubPost := OldGeneral.NormPubPost;
    NormPrivPost := OldGeneral.NormPrivPost;
    AnonPubRead := OldGeneral.AnonPubPost;
    AnonPrivRead := OldGeneral.AnonPrivRead;
    AnonPubPost := OldGeneral.AnonPubPost;
    AnonPrivPost := OldGeneral.AnonPrivPost;
    SeeUnval := OldGeneral.SeeUnVal;
    DLUnval := OldGeneral.DLUnval;
    NoDLRatio := OldGeneral.NODLRatio;
    NoPostRatio := OldGeneral.NoPostRatio;
    NoFileCredits := OldGeneral.NoFileCredits;
    ULValReq := OldGeneral.ULValReq;
    TeleConfMCI := OldGeneral.TeleConfMCI;
    OverrideChat := OldGeneral.OverrideChat;
    NetMailACS := OldGeneral.NetMailACS;
    Invisible := OldGeneral.Invisible;
    FileAttachACS := OldGeneral.FileAttachACS;
    ChangeVote := OldGeneral.ChangeVote;

    MaxPrivPost := OldGeneral.MaxPrivPost;
    MaxFBack := OldGeneral.MaxFBack;
    MaxPubPost := OldGeneral.MaxPubPost;
    MaxChat := OldGeneral.MaxChat;
    MaxWaiting := OldGeneral.MaxWaiting;
    CSMaxWaiting := OldGeneral.CSMaxWaiting;
    MaxMassMailList := OldGeneral.MaxMassMailList;
    MaxLogonTries := OldGeneral.MaxLogonTries;
    SysOpColor := OldGeneral.SysOpColor;
    UserColor := OldGeneral.UserColor;
    SliceTimer := OldGeneral.SliceTimer;
    MaxBatchDLFiles := OldGeneral.MaxBatchDLFiles;
    MaxBatchULFiles := OldGeneral.MaxBatchULFiles;
    Text_Color := OldGeneral.Text_Color;
    Quote_Color := OldGeneral.Quote_Color;
    Tear_Color := OldGeneral.Tear_Color;
    Origin_Color := OldGeneral.Origin_Color;
    BackSysOpLogs := OldGeneral.BackSysOpLogs;
    EventWarningTime := OldGeneral.EventWarningTime;
    WFCBlankTime := OldGeneral.WFCBlankTime;
    AlertBeep := OldGeneral.AlertBeep;
    FileCreditComp := OldGeneral.FileCreditComp;
    FileCreditCompBaseSize := OldGeneral.FileCreditCompBaseSize;
    ULRefund := OldGeneral.ULRefund;
    GlobalMenu := OldGeneral.GlobalMenu;
    AllStartMenu := OldGeneral.AllStartMenu;
    ShuttleLogonMenu := OldGeneral.ShuttleLogonMenu;
    NewUserInformationMenu := OldGeneral.NewUserInformationMenu;
    FileListingMenu := OldGeneral.FileListingMenu;
    MessageReadMenu := OldGeneral.MessageReadMenu;
    CurWindow := OldGeneral.CurWindow;
    SwapTo := OldGeneral.SwapTo;

    LowTime := OldGeneral.LowTime;
    HiTime := OldGeneral.HiTime;
    DLLowTime := OldGeneral.DLLowTime;
    DLHiTime := OldGeneral.DLHiTime;
    MinBaudLowTime := OldGeneral.MinBaudLowTime;
    MinBaudHiTime := OldGeneral.MinBaudHiTime;
    MinBaudDLLowTime := OldGeneral.MinBaudDLLowTime;
    MinBaudDLHiTime := OldGeneral.MinBaudDLHiTime;
    MinSpaceForPost := OldGeneral.MinSpaceForPost;
    MinSpaceForUpload := OldGeneral.MinSpaceForUpload;
    NewApp := OldGeneral.NewApp;
    TimeOutBell := OldGeneral.TimeOutBell;
    TimeOut := OldGeneral.TimeOut;
    ToSysOpDir := OldGeneral.ToSysOpDir;
    CreditMinute := OldGeneral.CreditMinute;
    CreditPost := OldGeneral.CreditPost;
    CreditEmail := OldGeneral.CreditEmail;
    CreditFreeTime := OldGeneral.CreditFreeTime;
    NumUsers := OldGeneral.NumUsers;
    PasswordChange := OldGeneral.PasswordChange;
    RewardRatio := OldGeneral.RewardRatio;
    CreditInternetMail := OldGeneral.CreditInternetMail;
    BirthDateCheck := OldGeneral.BirthDateCheck;

    MaxQWKTotal := OldGeneral.MaxQWKTotal;
    MaxQWKBase := OldGeneral.MaxQWKBase;
    DaysOnline := OldGeneral.DaysOnline;

    MinimumBaud := OldGeneral.MinimumBaud;
    MinimumDLBaud := OldGeneral.MinimumDLBaud;
    MaxDepositEver := 300;
    MaxDepositPerDay := 30;
    MaxWithdrawalPerDay := 30;
    CallerNum := OldGeneral.CallerNum;
    RegNumber := OldGeneral.RegNumber;
    TotalCalls := OldGeneral.TotalCalls;
    TotalUsage := OldGeneral.TotalUsage;
    TotalPosts := OldGeneral.TotalPosts;
    TotalDloads := OldGeneral.TotalDloads;
    TotalUloads := OldGeneral.TotalUloads;
    MinResume := OldGeneral.MinResume;
    MaxInTemp := OldGeneral.MaxInTemp;

    AllowAlias := OldGeneral.AllowAlias;
    PhonePW := OldGeneral.PhonePW;
    LocalSec := OldGeneral.LocalSec;
    GlobalTrap := OldGeneral.GlobalTrap;
    AutoChatOpen := OldGeneral.AutoChatOpen;
    AutoMInLogon := OldGeneral.AutoMInLogon;
    BullInLogon := OldGeneral.BullInLogon;
    YourInfoInLogon := OldGeneral.YourInfoInLogon;
    OffHookLocalLogon := OldGeneral.OffHookLocalLogon;
    ForceVoting := OldGeneral.ForceVoting;
    CompressBases := OldGeneral.CompressBases;
    SearchDup := OldGeneral.SearchDup;
    ForceBatchDL := OldGeneral.ForceBatchDL;
    LogonQuote := OldGeneral.LogonQuote;
    UserAddQuote := OldGeneral.UserAddQuote;
    StripCLog := OldGeneral.StripCLog;
    SKludge := OldGeneral.SKludge;
    SSeenby := OldGeneral.SSeenby;
    SOrigin := OldGeneral.SOrigin;
    AddTear := OldGeneral.AddTear;
    ShuttleLog := OldGeneral.ShuttleLog;
    ClosedSystem := OldGeneral.ClosedSystem;
    SwapShell := OldGeneral.SwapShell;
    UseEMS := OldGeneral.UseEMS;
    UseBios := OldGeneral.UseBios;
    UseIEMSI := OldGeneral.UseIEMSI;
    ULDLRatio := OldGeneral.ULDLRatio;
    FileCreditRatio := OldGeneral.FileCreditRatio;
    ValidateAllFiles := OldGeneral.ValidateAllFiles;
    FileDiz := OldGeneral.FileDiz;
    SysOpPword := OldGeneral.SysOpPword;
    TrapTeleConf := OldGeneral.TrapTeleConf;
    IsTopWindow := OldGeneral.IsTopWindow;
    ReCompress := OldGeneral.ReCompress;
    RewardSystem := OldGeneral.RewardSystem;
    TrapGroup := OldGeneral.TrapGroup;
    QWKTimeIgnore := OldGeneral.QWKTimeIgnore;
    NetworkMode := OldGeneral.NetworkMode;
    WindowOn := OldGeneral.WindowOn;
    ChatCall := OldGeneral.ChatCall;
    DailyLimits := OldGeneral.DailyLimits;
    MultiNode := OldGeneral.MultiNode;
    PerCall := OldGeneral.PerCall;
    TestUploads := OldGeneral.TestUploads;

    FOR Counter := 1 TO MaxArcs DO
      WITH FileArcInfo[Counter] DO
      BEGIN
        Active := OldGeneral.FileArcInfo[Counter].Active;
        Ext := OldGeneral.FileArcInfo[Counter].Ext;
        ListLine := OldGeneral.FileArcInfo[Counter].ListLine;
        ArcLine := OldGeneral.FileArcInfo[Counter].ArcLine;
        UnArcLine := OldGeneral.FileArcInfo[Counter].UnArcLine;
        TestLine := OldGeneral.FileArcInfo[Counter].TestLine;
        CmtLine := OldGeneral.FileArcInfo[Counter].CmtLine;
        SuccLevel := OldGeneral.FileArcInfo[Counter].SuccLevel;
      END;

    FOR Counter := 1 TO 3 DO
      FileArcComment[Counter] := OldGeneral.FileArcComment[Counter];

    FOR Counter := 0 TO 20 DO
      WITH AKA[Counter] DO
      BEGIN
        Zone := OldGeneral.AKA[Counter].Zone;
        Net := OldGeneral.AKA[Counter].Net;
        Node := OldGeneral.AKA[Counter].Node;
        Point := OldGeneral.AKA[Counter].Point;
      END;

    FOR Counter := 1 TO 20 DO
     NewUserToggles[Counter] := OldGeneral.NewUserToggles[Counter];;

    FOR Counter := 0 TO 9 DO
      Macro[Counter] := OldGeneral.Macro[Counter];

    Netattribute := OldGeneral.Netattribute;

    FOR Counter := 0 TO 255 DO
      TimeAllow[Counter] := OldGeneral.TimeAllow[Counter];

    FOR Counter := 0 TO 255 DO
      CallAllow[Counter] := OldGeneral.CallAllow[Counter];

    FOR Counter := 0 TO 255 DO
      DLRatio[Counter] := OldGeneral.DLRatio[Counter];

    FOR Counter := 0 TO 255 DO
      DLKRatio[Counter] := OldGeneral.DLKRatio[Counter];

    FOR Counter := 0 TO 255 DO
      PostRatio[Counter] := OldGeneral.PostRatio[Counter];

    FOR Counter := 0 TO 255 DO
      DLOneday[Counter] := OldGeneral.DLOneday[Counter];

    FOR Counter := 0 TO 255 DO
      DLKOneDay[Counter] := OldGeneral.DLKOneDay[Counter];

  END;
  Write(GeneralFile,General);
  Close(OldGeneralFile);
  Close(GeneralFile);
  Assign(OldGeneralFile,'RENEGADE.DAT');
  Erase(OldGeneralFile);
  Assign(GeneralFile,'RENEGADE.NEW');
  ReName(GeneralFile,'RENEGADE.DAT');
  WriteLn('Done');
END;

VAR
  OldGeneralFile: FILE OF OldGeneralRecordType;
  OldGeneral: OldGeneralRecordType;

BEGIN
  ClrScr;
  WriteLn('Renegade Update Utility (12.07/8 to 01.28/8)');
  WriteLn;
  Writeln('This utility will upgrade your Renegade BBS from');
  WriteLn('Version 12.07/8 to Version 01.28/8.');
  WriteLn;
  Writeln('This update will scan your USERS.DAT file to ensure');
  WriteLn('that your expiration information for each guest is');
  WriteLn('configured properly.  Errors will be logged to the');
  WriteLn('files (EXPIRE.TXT or KEY.TXT). Errors will result in');
  Writeln('the termination of this update utility until corrected.');
  Writeln('The following rules apply:');
  Writeln;
  Writeln(' -  Both the expiration date and expire to key must');
  Writeln('    be null or contain valid data.  You can not have');
  WriteLn('    one configured without the other.');
  WriteLn;
  WriteLn(' -  The expire to key must be a valid key configured');
  Writeln('    in the validation editor.');
  WriteLn;
  IF PYNQ('Do you wish to continue? ') THEN
  BEGIN
    WriteLn;
    Write('Reading "RENEGADE.DAT" file ... ');
    Assign(OldGeneralFile,'RENEGADE.DAT');
    Reset(OldGeneralFile);
    Read(OldGeneralFile,OldGeneral);
    Close(OldGeneralFile);
    WriteLn('Done');
    WriteLn;
    (*
    IF (NOT ReadUsers(OldGeneral)) THEN
    BEGIN
      WriteLn;
      WriteLn(^G^G^G'Please see the file EXPIRE.TXT/KEY.TXT for errors.');
    END
    ELSE
    BEGIN
    *)
      WriteLn;
      CreateValidationRec(OldGeneral);
      ConvertGeneralRec(OldGeneral);
      WriteLn;
      WriteLn(^G^G^G'Conversion complete!');
      WriteLn;
      WriteLn('Please replace your old RENEGADE.EXE/RENEGADE.OVR files');
      WriteLn('with the new files provided with this update.');
    (*
    END;
    *)
  END;
END.
