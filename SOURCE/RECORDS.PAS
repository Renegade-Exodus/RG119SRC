CONST
  Build = '1.20';

{$IFDEF MSDOS}
  OS = '/Alpha';
{$ENDIF}

{$IFDEF WIN32}
  OS = 'WIN32';
{$ENDIF}

{$IFDEF OS/2}
  OS = 'OS/2';
{$ENDIF}

  Ver = Build + OS;
  MaxProtocols = 120;
  MaxEvents = 10;
  MaxArcs = 8;
  MaxCmds = 200;
  MaxMenus = 100;
  MaxResultCodes = 20;
  MaxExtDesc = 99;
  MaxFileAreas = 32767;
  MaxMsgAreas = 32767;
  MaxConfigurable = 1024;
  MaxVotes = 25;
  MaxChoices = 25;
  MaxSchemes = 255;
  MaxValKeys = 92;
  MaxConfKeys = 27;

  User_String_Ask  = ' ';         {Ask for user string fields}
  User_String_None = '';          {None for user string fields}

  User_Date_Ask  = -2145916799;   {Ask for user date fields - 01/01/1902}
  User_Date_None = -2146003199;   {None for user date fields - 12/31/1901}

  User_Word_Ask  = 65535;         {Ask for user word fields}
  User_Word_None = 65534;         {None for user word fields}

  User_Char_Ask  = '~';           {Ask for user character fields}
  User_Char_None = ' ';           {None for user character fields}

  User_Phone_Ask  = ' ';          {Ask for user phone fields}
  User_Phone_None = '';           {None for user phone fields}

TYPE
{$IFDEF MSDOS}
  SmallInt = Integer;
  SmallWord = Word;
{$ENDIF}
  AStr = STRING[160];
  Str1 = STRING[1];
  Str2 = STRING[2];
  Str3 = STRING[3];
  Str4 = STRING[4];
  Str5 = STRING[5];
  Str7 = STRING[7];
  Str8 = STRING[8];
  Str9 = STRING[9];
  Str11 = STRING[11];
  Str10 = STRING[10];
  Str12 = STRING[12];
  Str15 = STRING[15];
  Str20 = STRING[20];
  Str26 = STRING[26];
  Str30 = STRING[30];
  Str35 = STRING[35];
  Str36 = STRING[36];
  Str40 = STRING[40];
  Str50 = STRING[50];
  Str52 = STRING[52];
  Str65 = STRING[65];
  Str74 = STRING[74];
  Str78 = STRING[78];
  Str160 = STRING[160];

  UnixTime = LongInt;             { Seconds since 1-1-70 }

  ACString = STRING[20];          { Access Condition STRING }

  ARFlagType = '@'..'Z';          {AR flags}

  ARFlagSet = SET OF ARFlagType;  {SET OF AR flags}

  FlagType =
   (RLogon,                       { L - Limited to one call a day }
    RChat,                        { C - No SysOp paging }
    RValidate,                    { V - Posts are unvalidated }
    RUserList,                    { U - Can't list users }
    RAMsg,                        { A - Can't leave automsg }
    RPostAn,                      { * - Can't post anonymously }
    RPost,                        { P - Can't post }
    REmail,                       { E - Can't send email }
    RVoting,                      { K - Can't use voting booth }
    RMsg,                         { M - Force email deletion }

    VT100,                        { Supports VT00 }
    HotKey,                       { hotkey input mode }
    Avatar,                       { Supports Avatar }
    Pause,                        { screen pausing }
    Novice,                       { user requires novice help }
    ANSI,                         { Supports ANSI }
    Color,                        { Supports color }
    Alert,                        { Alert SysOp upon login }
    SMW,                          { Short message(s) waiting }
    NoMail,                       { Mailbox is closed }

    FNoDLRatio,                   { 1 - No UL/DL ratio }
    FNoPostRatio,                 { 2 - No post/call ratio }
    FNoCredits,                   { 3 - No credits checking }
    FNoDeletion);                 { 4 - Protected from deletion }

  FlagSet = SET OF FlagType;

  StatusFlagType =
    (LockedOut,                   { if locked out }
    Deleted,                      { if deleted }
    TrapActivity,                 { if trapping users activity }
    TrapSeparate,                 { if trap to seperate TRAP file }
    ChatAuto,                     { if auto chat trapping }
    ChatSeparate,                 { if separate chat file to trap to }
    SLogSeparate,                 { if separate SysOp log }
    CLSMsg,                       { if clear-screens }
    RIP,                          { if RIP graphics can be used }
    FSEditor,                     { if Full Screen Editor }
    AutoDetect,                   { Use auto-detected emulation }
    FileAreaLightBar,
    MsgAreaLightBar,
    UnUsedStatusFlag1,
    UnUsedStatusFlag2,
    UnUsedStatusFlag3
  );

  StatusFlagSet = SET OF StatusFlagType;

  ANonTyp =
   (ATNo,                         { Anonymous posts not allowed }
    ATYes,                        { Anonymous posts are allowed }
    ATForced,                     { Force anonymous }
    ATDearAbby,                   { "Dear Abby"  }
    ATAnyName);                   { Post under any name }

  NetAttr =
    (Private,
     Crash,
     Recd,
     NSent,
     FileAttach,
     Intransit,
     Orphan,
     KillSent,
     Local,
     Hold,
     Unused,
     FileRequest,
     ReturnReceiptRequest,
     IsReturnReceipt,
     AuditRequest,
     FileUpdateRequest);

  NetAttribs = SET OF NetAttr;

  SecurityRangeType = ARRAY [0..255] OF LongInt;        { Access tables }

  UserIDXRec =                         { USERS.IDX : Sorted names listing }
{$IFDEF WIN32} PACKED {$ENDIF} RECORD
    Name: STRING[36];                 { the user's name }
    Number,                           { user number          }
    Left,                             { Left node }
    Right: SmallInt;                   { Right node }
    RealName,                         { User's real name?    }
    Deleted: Boolean;                 { deleted or not       }
  END;

  UserRecordType =                     { USERS.DAT : User records }
  {$IFDEF WIN32} PACKED {$ENDIF} RECORD
    Name,                              { system name        }
    RealName: STRING[36];              { real name          }

    Street,                            { street address     }
    CityState: STRING[30];             { city, state        }

    CallerID: STRING[20];              { caller ID STRING   }

    ZipCode: STRING[10];               { zipcode            }

    PH: STRING[12];                    { phone #            }

    ForgotPWAnswer: STRING[40];

    UsrDefStr: ARRAY [1..3] OF STRING[35]; { definable strings  }

    Note: STRING[35];                  { SysOp note         }

    LockedFile: STRING[8];             { print lockout msg  }

    Vote: ARRAY [1..25] OF Byte;       { voting data        }

    Sex,                               { gender             }
    Subscription,                      { their subscription }
    ExpireTo,                          { level to expire to }
    LastConf,                          { last conference in }
    UnUsedChar1,
    UnUsedChar2: Char;

    SL,                                { SL                 }
    DSL,                               { DSL                }
    Waiting,                           { mail waiting       }
    LineLen,                           { line length        }
    PageLen,                           { page length        }
    OnToday,                           { # times on today   }
    Illegal,                           { # illegal logons   }
    DefArcType,                        { QWK archive type   }
    ColorScheme,                       { Color scheme #     }
    UserStartMenu,                     { menu to start at   }
    UnUsedByte1,
    UnUsedByte2: Byte;

    BirthDate,                         { Birth date         }
    FirstOn,                           { First On Date      }
    LastOn,                            { Last On Date       }
    TTimeOn,                           { total time on      }
    LastQWK,                           { last qwk packet    }
    Expiration,                        { Expiration date    }
    UnUsedUnixTime1,
    UnUsedUnixTime2: UnixTime;

    UserID,                            { Permanent userid   }
    TLToday,                           { # min left today   }
    ForUsr,                            { forward mail to    }
    LastMsgArea,                       { # last msg area    }
    LastFileArea,                      { # last file area   }
    UnUsedInteger1,
    UnUsedInteger2: SmallInt;

    PasswordChanged,                   { Numeric date pw changed - was UnixTime }
    UnUsedWord1,
    UnUsedWord2: SmallWord;

    lCredit,                            { Amount OF credit   }
    Debit,                             { Amount OF debit    }
    PW,                                { password           }
    Uploads,                           { # OF DLs           }
    Downloads,                         { # OF DLs           }
    UK,                                { UL k               }
    DK,                                { DL k               }
    LoggedOn,                          { # times on         }
    MsgPost,                           { # message posts    }
    EmailSent,                         { # email sent       }
    FeedBack,                          { # feedback sent    }
    TimeBank,                          { # mins in bank     }
    TimeBankAdd,                       { # added today      }
    DLKToday,                          { # kbytes dl today  }
    DLToday,                           { # files dl today   }
    FilePoints,
    TimeBankWith,                      { Time withdrawn     }
    UnUsedLongInt1,
    UnUsedLongInt2: LongInt;

    TeleConfEcho,                      { Teleconf echo?     }
    TeleConfInt,                       { Teleconf interrupt }
    GetOwnQWK,                         { Get own messages   }
    ScanFilesQWK,                      { new files in qwk   }
    PrivateQWK,                        { private mail qwk   }
    UnUsedBoolean1,
    UnUsedBoolean2: Boolean;

    AR: ARFlagSet;                     { AR flags           }

    Flags: FlagSet;                    { flags              }

    SFlags: StatusFlagSet;             { status flags       }
  END;

  MsgStatusR =
    (MDeleted,
     Sent,
     Unvalidated,
     Permanent,
     AllowMCI,
     NetMail,
     Prvt,
     Junked);

  FromToInfo =                  { from/to information for mheaderrec }
{$IFDEF WIN32} PACKED {$ENDIF} RECORD
    Anon: Byte;
    UserNum: SmallWord;              { user number   }
    A1S: STRING[36];            { posted as     }
    Real: STRING[36];           { real name     }
    Name: STRING[36];           { system name   }
    Zone,
    Net,
    Node,
    Point: SmallWord;
  END;

  MHeaderRec =
{$IFDEF WIN32} PACKED {$ENDIF} RECORD
    From,
    MTO: FromToInfo;                 { message from/to info    }
    Pointer: LongInt;                { starting record OF text }
    TextSize: SmallWord;                  { size OF text            }
    ReplyTo: SmallWord;                   { ORIGINAL + REPLYTO = CURRENT }
    Date: UnixTime;                  { date/time PACKED STRING }
    DayOfWeek: Byte;                 { message day OF week     }
    Status: SET OF MsgStatusR;       { message status flags    }
    Replies: SmallWord;                   { times replied to        }
    Subject: STRING[40];             { subject OF message      }
    OriginDate: STRING[19];          { date OF echo/group msgs }
    FileAttached: Byte;              { 0=No, 1=Yes&Del, 2=Yes&Save }
    NetAttribute: NetAttribs;        { Netmail attributes }
    Res: ARRAY [1..2] OF Byte;        { reserved }
  END;

  HistoryRecordType =                { HISTORY.DAT : Summary logs }
{$IFDEF WIN32} PACKED {$ENDIF} RECORD
    Date: UniXTime;
    Active,
    Callers,
    NewUsers,
    Posts,
    Email,
    FeedBack,
    Errors,
    Uploads,
    Downloads,
    UK,
    DK: LongInt;
    UserBaud: ARRAY [0..20] OF LongInt;
  END;

  FileArcInfoRecordType =                 { Archive configuration records }
{$IFDEF WIN32} PACKED {$ENDIF} RECORD
    Active: Boolean;               { active or not  }
    Ext: STRING[3];                { file extension }
    ListLine,                      { /x for internal; x: 1=ZIP, 2=ARC/PAK, 3=ZOO, 4=LZH }
    ArcLine,                       { compression cmdline    }
    UnArcLine,                     { de-compression cmdline }
    TestLine,                      { integrity test cmdline }
    CmtLine: STRING[25];           { comment cmdline        }
    SuccLevel: SmallInt;            { success errorlevel, -1=ignore results }
  END;

  ModemFlagType =         { MODEM.DAT status flags }
   (Lockedport,           { COM port locked at constant rate }
    XOnXOff,              { XON/XOFF (software) flow control }
    CTSRTS);              { CTS/RTS (hardware) flow control }

  MFlagSet = SET OF ModemFlagType;

  LineRec =
{$IFDEF WIN32} PACKED {$ENDIF} RECORD
    InitBaud: LongInt;                 { initialization baud }
    ComPort: Byte;                     { COM port number }
    MFlags: MFlagSet;                  { status flags }
    Init,                              { init STRING }
    Answer,                            { answer STRING or blank }
    Hangup,                            { hangup STRING }
    Offhook: STRING[30];               { phone off-hook STRING }
    DoorPath,                          { door drop files written to }
    TeleConfNormal,
    TeleConfAnon,                      { Teleconferencing strings }
    TeleConfGlobal,
    TeleConfPrivate: STRING[40];
    Ok,
    Ring,
    Reliable,
    CallerID,
    NoCarrier: STRING[20];
    Connect: ARRAY [1..22] OF STRING[20];
    { 300, 600, 1200, 2400, 4800, 7200, 9600, 12000, 14400, 16800, 19200,
      21600, 24000, 26400, 28800, 31200, 33600, 38400, 57600, 115200 + 2 extra }
    UseCallerID: Boolean;              { Insert Caller ID into sysop note? }
    LogonACS: ACString;                { ACS STRING to logon this node }
    IRQ,
    Address: STRING[10];               { used only for functional MCI codes
                                        %C = Comport address
                                        %E = IRQ
                                       }
    AnswerOnRing: Byte;                { Answer after how many rings? }
    MultiRing: Boolean;                { Answer Ringmaster or some other type
                                        OF multiple-ring system ONLY }
    NodeTelnetUrl: STRING[65];
  END;

  ValidationRecordType =
{$IFDEF WIN32} PACKED {$ENDIF} RECORD
    Key,                               { Key '!' to '~' }
    ExpireTo: Char;                    { validation level to expire to }
    Description: STRING[30];           { description }
    UserMsg: STRING[78];               { Message sent to user upon validation }
    NewSL,                             { new SL }
    NewDSL,                            { new DSL }
    NewMenu: Byte;                     { User start out menu }
    Expiration: SmallWord;                  { days until expiration }
    NewFP,                             { nothing }
    NewCredit: LongInt;                { new credit }
    SoftAR,                            { TRUE=AR added to current, else replaces }
    SoftAC: Boolean;                   { TRUE=AC    "   "   "       "      "  }
    NewAR: ARFlagSet;                  { new AR }
    NewAC: FlagSet;                    { new AC }
  END;

  GeneralRecordType =
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
    lMultPath,                          { MULT path }
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
    ChangeVote,                      { ACS to change their vote }
    UnUsedACS1,
    UnUsedACS2: ACString;

    MaxPrivPost,                     { max email can send per call }
    MaxFBack,                        { max feedback per call }
    MaxPubPost,                      { max posts per call }
    MaxChat,                         { max sysop pages per call }
    MaxWaiting,                      { max mail waiting }
    CSMaxWaiting,                    { max mail waiting for Co-SysOp + }
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
    SwapTo,                            { Swap where?    }
    UnUsedByte1,
    UnUsedByte2: Byte;

    lLowTime,                           { SysOp begin minute (in minutes) }
    HiTime,                            { SysOp END time }
    DLLowTime,                         { normal downloading hours begin.. }
    DLHiTime,                          { ..and END }
    MinBaudLowTime,                    { minimum baud calling hours begin.. }
    MinBaudHiTime,                     { ..and END }
    MinBaudDLLowTime,                  { minimum baud downloading hours begin.. }
    MinBaudDLHiTime,                   { ..and END }
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
    BirthDateCheck,                    { check user's birthdate every xx logons }
    UnUsedInteger1,
    UnUsedInteger2: SmallInt;

    MaxQWKTotal,                       { max msgs in a packet, period }
    MaxQWKBase,                        { max msgs in a area }
    DaysOnline,                        { days online }
    UnUsedWord1,
    UnUsedWord2: SmallWord;

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
    MinResume,                         { min K to allow resume-later }
    MaxInTemp,                         { max K allowed in TEMP }
    MinSpaceForPost,                   { minimum drive space left to post }
    MinSpaceForUpload,                 { minimum drive space left to upload }
    UnUsedLongInt1,
    UnUsedLongInt2: LongInt;

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
    ForceBatchUL,
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
    TestUploads,                       { perform integrity tests on uploads? }
    UseFileAreaLightBar,
    UseMsgAreaLightBar,
    UnUsedBoolean1,
    UnUsedBoolean2: Boolean;

    FileArcInfo:
      ARRAY [1..MaxArcs] OF FileArcInfoRecordType;           { archive specs }

    FileArcComment:
      ARRAY [1..3] OF STRING[40];    { BBS comment files for archives }

    Aka: ARRAY [0..20] OF
    {$IFDEF WIN32} PACKED {$ENDIF} RECORD { 20 Addresses }
      Zone,                           { 21st is for UUCP address }
      Net,
      Node,
      Point: SmallWord;
    END;

    NewUserToggles: ARRAY [1..20] OF Byte;

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

  ShortMessageRecordType =        { SHORTMSG.DAT : One-line messages }
{$IFDEF WIN32} PACKED {$ENDIF} RECORD
    Msg: AStr;
    Destin: SmallInt;
  END;

  VotingRecordType =               { VOTING.DAT : Voting records }
{$IFDEF WIN32} PACKED {$ENDIF} RECORD
    Question1,                     { Voting Question 1 }
    Question2: STRING[60];         { Voting Question 2 }
    ACS: ACString;                 { ACS required to vote on this }
    ChoiceNumber: Byte;            { number OF choices }
    NumVotedQuestion: SmallInt;     { number OF votes on it }
    CreatedBy: STRING[36];         { who created it }
    AddAnswersACS: ACString;       { ACS required to add choices }
    Answers: ARRAY [1..25] OF
  {$IFDEF WIN32} PACKED {$ENDIF} RECORD
      Answer1,                     { answer description }
      Answer2: STRING[65];         { answer description #2 }
      NumVotedAnswer: SmallInt;     { # user's who picked this answer }
    END;
  END;

  MessageAreaFlagType =
   (MARealName,                   { whether real names are forced }
    MAUnHidden,                   { whether *VISIBLE* to users w/o access }
    MAFilter,                     { whether to filter ANSI/8-bit ASCII }
    MAPrivate,                    { allow private messages }
    MAForceRead,                  { force the reading of this area }
    MAQuote,                      { Allow Quote/Tagline to messages posted in this area }
    MASKludge,                    { strip IFNA kludge lines }
    MASSeenBy,                    { strip SEEN-BY lines }
    MASOrigin,                    { strip origin lines }
    MAAddTear,                    { add tear/origin lines }
    MAInternet,                   { if internet message area }
    MAScanOut);                   { Needs to be scanned out by renemail }

  MAFlagSet = SET OF MessageAreaFlagType;

  MessageAreaRecordType =         { MBASES.DAT : Message area records }
{$IFDEF WIN32} PACKED {$ENDIF} RECORD
    Name: STRING[40];             { message area description }
    FileName: STRING[8];          { HDR/DAT data filename }
    MsgPath: STRING[40]; {Not Used}         { messages pathname   }
    ACS,                          { access requirement }
    PostACS,                      { post access requirement }
    MCIACS,                       { MCI usage requirement }
    SysOpACS: ACString;           { Message area sysop requirement }
    MaxMsgs: SmallWord;                { max message count }
    Anonymous: AnonTyp;           { anonymous type }
    Password: STRING[20];         { area password }
    MAFlags: MAFlagSet;           { message area status vars }
    MAType: SmallInt;             { Area type (0=Local,1=Echo, 3=Qwk) }
    Origin: STRING[50];           { origin line }
    Text_Color,                   { color OF standard text }
    Quote_Color,                  { color OF quoted text }
    Tear_Color,                   { color OF tear line }
    Origin_Color,                 { color OF origin line }
    MessageReadMenu: Byte;
    QuoteStart,
    QuoteEnd: STRING[70];
    PrePostFile: STRING[8];
    AKA: Byte;                    { alternate address }
    QWKIndex: SmallWord;               { QWK indexing number }
  END;

  FileAreaFlagType =
   (FANoRatio,                    { if <No Ratio> active }
    FAUnHidden,                   { whether *VISIBLE* to users w/o access }
    FADirDLPath,                  { if *.DIR file stored in DLPATH }
    FAShowName,                   { show uploaders in listings }
    FAUseGIFSpecs,                { whether to use GifSpecs }
    FACDROM,                      { Area is read only, no sorting or ul scanning }
    FAShowDate,                   { show date uploaded in listings }
    FANoDupeCheck);               { No dupe check on this area }

  FAFlagSet = SET OF FileAreaFlagType;

  FileAreaRecordType =            { FBASES.DAT  : File area records }
{$IFDEF WIN32} PACKED {$ENDIF} RECORD
    AreaName: STRING[40];         { area description  }
    FileName: STRING[8];          { filename + ".DIR" }
    DLPath,                       { download path     }
    ULPath: STRING[40];           { upload path       }
    MaxFiles: SmallInt;            { max files allowed - VerbRec Limit would allow up to LongInt Value or Maximum 433835}
    Password: STRING[20];         { password required }
    ArcType,                      { wanted archive type (1..max,0=inactive) }
    CmtType: Byte;                { wanted comment type (1..3,0=inactive) }
    ACS,                          { access requirements }
    ULACS,                        { upload requirements }
    DLACS: ACString;              { download requirements }
    FAFlags: FAFlagSet;           { file area status vars }
  END;

  FileInfoFlagType =
   (FINotVal,                      { If file is not validated }
    FIIsRequest,                   { If file is REQUEST }
    FIResumeLater,                 { If file is RESUME-LATER }
    FIHatched,                     { Has file been hatched? }
    FIOwnerCredited,
    FIUnusedFlag1,
    FIUnusedFlag2,
    FIUnusedFlag3);

  FIFlagSet = SET OF FileInfoFlagType;

  FileInfoRecordType =             { *.DIR : File records }
  {$IFDEF WIN32} PACKED {$ENDIF} RECORD
    FileName: STRING[12];          { Filename }
    Description: STRING[50];       { File description }
    FilePoints: SmallInt;           { File points }
    Downloaded: LongInt;           { Number DLs }
    FileSize: LongInt;             { File size in Bytes }
    OwnerNum: SmallInt;             { ULer OF file }
    OwnerName: STRING[36];         { ULer's name }
    FileDate: UnixTime;            { Date ULed }
    VPointer: LongInt;             { Pointer to verbose descr, -1 if none }
    VTextSize: SmallInt;            { Verbose descr textsize - 50 Bytes x 99 Lines = 4950 max }
    FIFlags: FIFlagSet;            { File status }
  END;

  LastCallerRec =                  { LASTON.DAT : Last few callers records }
{$IFDEF WIN32} PACKED {$ENDIF} RECORD
    Node: Byte;                     { Node number }
    UserName: STRING[36];           { User name OF caller }
    Location: STRING[30];           { Location OF caller }
    Caller,                        { system caller number }
    UserID,                        { User ID # }
    Speed: LongInt;                 { Speed OF caller 0=Local }
    LogonTime,                     { time user logged on }
    LogoffTime: UnixTime;           { time user logged off }
    NewUser,                       { was it a new user? }
    Invisible: Boolean;             { Invisible user? }
    Uploads,                       { Uploads/Downloads during call }
    Downloads,
    MsgRead,                       { Messages Read }
    MsgPost,                       { Messages Posted }
    EmailSent,                     { Email sent }
    FeedbackSent: SmallWord;             { Feedback sent }
    UK,                            { Upload/Download kbytes during call }
    DK: LongInt;
    Reserved: ARRAY [1..17] OF Byte; { Reserved }
  END;

  EventFlagType =
   (EventIsExternal,
    EventIsActive,
    EventIsErrorLevel,
    EventIsShell,
    EventIsPackMsgAreas,
    EventIsSortFiles,
    EventIsFilesBBS,
    EventIsLogon,
    EventIsChat,
    EventIsOffHook,
    EventIsMonthly,
    EventIsPermission,
    EventIsSoft,
    EventIsMissed,
    BaudIsActive,
    ACSIsActive,
    TimeIsActive,
    ARisActive,
    SetARisActive,
    ClearARisActive,
    InRatioIsActive);

  EFlagSet = SET OF EventFlagType;

  EventDaysType  = SET OF 0..6;     {Set of event days}

  EventRecordType =                 {Events - EVENTS.DAT}
{$IFDEF WIN32} PACKED {$ENDIF} RECORD
    EventDescription: STRING[30]; {Description of the Event}
    EventDayOfMonth: BYTE;        {If monthly, the Day of Month}
    EventDays: EventDaysType;     {If Daily, the Days Active}
    EventStartTime,               {Start Time in Min from Mid.}
    EventFinishTime: SmallWord;        {Finish Time}
    EventQualMsg,                 {Msg/Path if he qualifies}
    EventNotQualMsg: STRING[64];  {Msg/Path if he doesn't}
    EventPreTime: BYTE;           {Min. B4 event to rest. Call}
    EventNode: Byte;
    EventLastDate: UnixTime;      {Last Date Executed}
    EventErrorLevel: BYTE;        {For Ext Event ErrorLevel}
    EventShellPath: STRING[8];    {File for Ext Event Shell}
    LoBaud,                       {Low baud rate limit}
    HiBaud: LongInt;              {High baud rate limit}
    EventACS: ACString;           {Event ACS}
    MaxTimeAllowed: SmallWord;         {Max Time per user this event}
    SetARflag,                    {AR Flag to Set}
    ClearARflag: CHAR;            {AR Flag to Clear}
    EFlags: EFlagSet;             {Kinds of Events Supported}   { Changed }
  END;

  ProtocolFlagType =
   (ProtActive,
    ProtIsBatch,
    ProtIsResume,
    ProtXferOkCode,
    ProtBiDirectional,
    ProtReliable);

  PRFlagSet = SET OF ProtocolFlagType;

  ProtocolCodeType = ARRAY [1..6] OF STRING[6];

  ProtocolRecordType =                            { PROTOCOL.DAT records }
{$IFDEF WIN32} PACKED {$ENDIF} RECORD
    PRFlags: PRFlagSet;                           { Protocol Flags }
    CKeys: STRING[14];                            { Command Keys }
    Description: STRING[40];                      { Description }
    ACS: ACString;                                { User Access STRING }
    TempLog,                                      { Utilized for Batch DL's - Temporary Log File }
    DLoadLog,                                     { Utilized for Batch DL's - Permanent Log Files }
    ULoadLog,                                     { Not Utilized }
    DLFList: STRING[25];                          { Utilized for Batch DL's - DL File Lists }
    DLCmd,                                        { DL Command Line }
    ULCmd: STRING[76];                            { UL Command Line }
    DLCode,                                       { DL Status/Return codes }
    ULCode: ProtocolCodeType;                     { UL StAtus/Return codes }
    EnvCmd: STRING[60];                           { Environment Setup Cmd }
    MaxChrs,                                      { Utilized for Batch DL's - Max chrs in cmdline }
    TempLogPF,                                    { Utilized for Batch DL's - Position in log for DL Status }
    TempLogPS: Byte;                              { Utilized for Batch DL's - Position in log for file data }
  END;

  ConferenceRecordType =  { CONFRENC.DAT : Conference data }
{$IFDEF WIN32} PACKED {$ENDIF} RECORD
    Key: Char;            { key '@' to 'Z' }
    Name: STRING[30];     { name of conference }
    ACS: ACString;        { access requirement }
  END;

  NodeFlagType =
   (NActive,                 { Is this node active?               }
    NAvail,                  { Is this node's user available?     }
    NUpdate,                 { This node should re-read it's user }
    NHangup,                 { Hangup on this node                }
    NRecycle,                { Recycle this node to the OS        }
    NInvisible);             { This node is Invisible             }

  NodeFlagSet = SET OF NodeFlagType;

  NodeRecordType =                         { MULTNODE.DAT }
{$IFDEF WIN32} PACKED {$ENDIF} RECORD
    User: SmallWord;                                 { What user number }
    UserName: STRING[36];                       { User's name }
    CityState: STRING[30];                      { User's location }
    Sex: Char;                                  { User's sex }
    Age: Byte;                                  { User's age }
    LogonTime: UnixTime;                        { What time they logged on }
    GroupChat: Boolean;                         { Are we in MultiNode Chat }
    ActivityDesc: STRING[50];                   { Activity STRING }
    Status: NodeFlagSet;
    Room: Byte;                                 { What room are they in? }
    Channel: SmallWord;                              { What channel are they in? }
    Invited,                                    { Have they been invited ? }
    Booted,                                     { Have they been kicked off ? }
    Forget: ARRAY [0..31] OF SET OF 0..7;       { Who are they forgetting? }
  END;

  RoomRec =                         { ROOM.DAT }
{$IFDEF WIN32} PACKED {$ENDIF} RECORD
    Topic: STRING[40];             { Topic OF this room          }
    Anonymous: Boolean;            { Is Room anonymous ?         }
    Private: Boolean;              { Is Room private ?           }
    Occupied: Boolean;             { Is anyone in here?          }
    Moderator: SmallWord;               { Who's the moderator?        }
  END;

  ScanRec =                         { *.SCN files / MESSAGES }
  {$IFDEF WIN32} PACKED {$ENDIF} RECORD
    NewScan: Boolean;               { Scan this area? }
    LastRead: UnixTime;             { Last date read  }
  END;

  SchemeRec =                       { Scheme.dat }
{$IFDEF WIN32} PACKED {$ENDIF} RECORD
    Description: STRING[30];        { Description OF the color scheme }
    Color: ARRAY [1..200] OF Byte;  { Colors in scheme }
  END;

  { 1 - 10 system colors
    11 -   file list colors
    28 -   msg list colors
    45 -   file area list colors
    55 -   msg area list colors
    65 -   user list colors
    80 -   who's online colors
    100-   last on colors
    115-   qwk colors
    135-   email colors
   }

  BBSListRecordType =          { *.BBS file records }
{$IFDEF WIN32} PACKED {$ENDIF} RECORD
    RecordNum: LongInt;        { Number OF the Record For Edit }
    UserID: LongInt;           { User ID OF person adding this }
    BBSName: STRING[30];       { Name OF BBS                   }
    SysOpName: STRING[30];     { SysOp OF BBS                  }
    TelnetUrl: STRING[60];     { Telnet Urls                   }
    WebSiteUrl: STRING[60];    { Web Site Url                  }
    PhoneNumber: STRING[20];   { Phone number OF BBS           }
    Software: STRING[8];       { Software used by BBS          }
    Speed: STRING[8];          { Highest connect speed OF BBS  }
    Description: STRING[60];   { Description OF BBS            }
    Description2: STRING[60];  { Second line OF descrition     }
    DateAdded: UnixTime;       { Date entry was added          }
    DateEdited: UnixTime;      { Date entry was last edited    }
    XA: STRING[8];             { sysop definable A             }
    XB: STRING[30];            { sysop definable B             }
    XC: STRING[30];            { sysop definable C             }
    XD: STRING[40];            { sysop definable D             }
    XE: STRING[60];            { sysop definable E             }
    XF: STRING[60];            { sysop definable F             }
  END;

  MenuFlagType =
    (ClrScrBefore,                 { C: clear screen before menu display }
     DontCenter,                   { D: don't center the menu titles! }
     NoMenuTitle,                  { T: no menu title displayed }
     NoMenuPrompt,                 { N: no menu prompt whatsoever? }
     ForcePause,                   { P: force a pause before menu display? }
     AutoTime,                     { A: is time displayed automatically? }
     ForceLine,                    { F: Force full line input }
     NoGenericAnsi,                { 1: DO NOT generate generic prompt if ANSI }
     NoGenericAvatar,              { 2: DO NOT generate generic prompt if AVT  }
     NoGenericRIP,                 { 3: DO NOT generate generic prompt if RIP  }
     NoGlobalDisplayed,            { 4: DO NOT display the global commands!    }
     NoGlobalUsed);                { 5: DO NOT use global commands!            }

  MenuFlagSet = SET OF MenuFlagType;

  CmdFlagType =
     (Hidden,                       { H: is command ALWAYS hidden? }
      UnHidden);                    { U: is command ALWAYS visible? }

  CmdFlagSet = SET OF CmdFlagType;

  MenuRec =
{$IFDEF WIN32} PACKED {$ENDIF} RECORD
    LDesc: ARRAY [1..3] OF STRING[100];    { Menu Or Command Long Description ARRAY }
    ACS: ACString;                        { Access Requirements }
    NodeActivityDesc: STRING[50];
    CASE Menu: Boolean OF                { Menu Or Command - Variant section}
      TRUE:
        (MenuFlags: MenuFlagSet;          { Menu Flag SET }
         LongMenu: STRING[12];            { Displayed In Place OF Long Description }
         MenuNum: Byte;                   { Menu Number }
         MenuPrompt: STRING[120];         { Menu Prompt }
         Password: STRING[20];            { Menu Password }
         FallBack: Byte;                  { Menu Fallback Number }
         Directive: STRING[12];
         ForceHelpLevel: Byte;            { Menu Forced Help Level }
         GenCols: Byte;                   { Generic Menus: # OF Columns }
         GCol: ARRAY [1..3] OF Byte);      { Generic Menus: Colors }
      FALSE:
        (CmdFlags: CmdFlagSet;            { Command Flag SET }
         SDesc: STRING[35];               { Command Short Description }
         CKeys: STRING[14];               { Command Execution Keys }
         CmdKeys: STRING[2];              { Command Keys: Type OF Command }
         Options: STRING[50]);            { MString: Command Data }
    END;