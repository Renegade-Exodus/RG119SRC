{***************************************************************************}
{* Dragon Bulletin Board System                                            *}
{* Copyright (c) 1998 By Dragon Software                                   *}
{* All rights reserved.                                                    *}
{*                                                                         *}
{*                    -----------------------------------                  *}
{*                    Dragon Version .010 Data Structures                  *}
{*                    -----------------------------------                  *}
{*                                                                         *}
{***************************************************************************}

CONST
  {**************************************************************************}
  {* The following values are used by the system for user fields            *}
  {*   "ask"  values will be asked of the user the next time they logon if  *}
  {*          the question is part of the new user logon                    *}
  {*   "none" values are normally for optional fields where the user simply *}
  {*          pressed <enter>                                               *}
  {**************************************************************************}
  User_String_Ask  = ' ';         {Ask for user string fields}
  User_String_None = '';          {None for user string fields}

  User_Date_Ask  = $fe21;         {Ask for user date fields - 1/1/2027}
  User_Date_None = $0021;         {None for user date fields - 1/1/0}

  User_Word_Ask  = 65535;         {Ask for user word fields}
  User_Word_None = 65534;         {None for user word fields}

  User_Char_Ask  = '~';           {Ask for user character fields}
  User_Char_None = ' ';           {None for user character fields}

  User_Phone_Ask  = ' ';          {Ask for user phone fields}
  User_Phone_None = '';           {None for user phone fields}


TYPE
  DefaultYesNoType = (            {Default/yes/no type}
    dyn_default,                  {Default}
    dyn_yes,                      {Yes}
    dyn_no                        {No}
    );                            {1 byte}

  ArFlagType = '@'..'Z';          {AR flags}

  ArFlagset = SET OF ArFlagType;  {Set of AR flags}

  FlagRec = (                     {User special flags}
    AutoPrivDel,                  {A = Force user to delete private mail}
    NoPostCall,                   {B = No post call ratio}
    ForceULScan,                  {C = Force this user to automatically scan when uploading}
    Ranon,                        {D = Restrict from posting anonymous}
    RbbsList,                     {E = Restrict from adding to other BBS list}
    Rchat,                        {F = Restrict from chatting}
    NoDLlimit,                    {G = No download ratio limit}
    RpubMsg,                      {H = Restrict from posting public mail}
    RprivMsg,                     {I = Restrict from sending private mail}
    Rvoting,                      {J = Restrict from voting}
    OneCall,                      {K = One call per day allowed}
    PubNotVal,                    {L = Public posts are not validated}
    ProtDel,                      {M = Protect from deletion}
    NoFilePts,                    {N = No file point checks}
    RfileVal,                     {O = Credit from upload on validation}
    Pause,                        {P = [PAUSE] active}
    Ansi,                         {Q = ANSI graphics active}
    Color,                        {R = Color active if ANSI present}
    OneKey,                       {S = Onekey input used instead of line input}
    Alert,                        {T = Alert active from user's next call}
    FlagRecUnused,                {U = Unused}
    MboxClosed,                   {V = Mail box closed to all but SysOp's}
    Tabs,                         {W = VT100 tabs are used to optimize display}
    ClsChar                       {X = Clear screen characters used}
    );                            {3 bytes used for 24 flags in set}

  FlagSet = SET OF FlagRec;       {Set of special flags}

  UlRecFlagType = (               {File section flags}
    IsCdRom,                      {Section is on a CD-ROM (read only device)}
    uuUlRecFlag1,                 {Reserved}
    uuUlRecFlag2,                 {Reserved}
    uuUlRecFlag3,                 {Reserved}
    uuUlRecFlag4,                 {Reserved}
    uuUlRecFlag5,                 {Reserved}
    uuUlRecFlag6,                 {Reserved}
    uuUlRecFlag7                  {Reserved}
    );                            {1 byte}

  UlRecFlagSet =                  {Set of file section flags}
    SET OF UlRecFlagType;

  ConfigFlagRec = (               {User configuration flags}
    UseCustomMenus,               {A = Allow custom ANSI menus}
    ClsMsgRead,                   {B = Clear screen between reading messages}
    DoNotDisturbUser,             {C = Do not disturb user (multi-user only)}
    LogonScanAllMsgSections,      {D = Scan all msg sections at logon for mail}
    QWKNewBulletins,              {E = Put new bulletins in QWK packet}
    QWKNewFiles,                  {F = Put new files list in QWK packet}
    uuCFFlag18,                   {G = Reserved}
    uuCFFlag17,                   {H = Reserved}
    uuCFFlag16,                   {I = Reserved}
    uuCFFlag15,                   {J = Reserved}
    uuCFFlag14,                   {K = Reserved}
    uuCFFlag13,                   {L = Reserved}
    uuCFFlag12,                   {M = Reserved}
    uuCFFlag11,                   {N = Reserved}
    uuCFFlag10,                   {O = Reserved}
    uuCFFlag9,                    {P = Reserved}
    uuCFFlag8,                    {Q = Reserved}
    uuCFFlag7,                    {R = Reserved}
    uuCFFlag6,                    {S = Reserved}
    uuCFFlag5,                    {T = Reserved}
    uuCFFlag4,                    {U = Reserved}
    uuCFFlag3,                    {V = Reserved}
    uuCFFlag2,                    {W = Reserved}
    uuCFFlag1                     {X = Reserved}
    );                            {3 bytes used for 24 flags in set}

  ConfigFlagSet =                 {Set of configuration flags}
    SET OF ConfigFlagRec; 

  {**********************************************************************}
  {* ColorRec = Array of B&W / Color  Color Bytes                       *}
  {**********************************************************************}
  ColorRec = ARRAY[FALSE..TRUE,   {False = B&W, True = Color}
                   0..9]          {0..9 = Color number}
             OF BYTE;

  SmalRec = RECORD                {User name index - NAMES.LST}
    Name : STRING[36];            {User name}

    Number : INTEGER;             {User number}
  END;

  UserRec = RECORD                {User log - USER.LST}
    Uname,                        {User name}
    Rname : STRING[36];           {Real name}

    ADDR,                         {Address}
    ComType,                      {Computer type}
    CityState,                    {City/State}
    Snote : STRING[30];           {SysOp note}

    LastDate,                     {Last date on - Semi-MS-DOS 1900 based format}
    LastTime : WORD;              {Last time on - MS-DOS format}

    PW : STRING[16];              {Password}

    Phone : STRING[12];           {Phone number 1}

    Zcode : STRING[10];           {Zip code}

    Phone2 : STRING[12];          {Phone number 2}

    ExtraStr1,                    {Extra string 1}
    ExtraStr2,                    {Extra string 2}
    ExtraStr3 : STRING[40];       {Extra string 3}

    ExtraDate1,                   {Extra date 1 - Semi-MS-DOS 1900 based format}
    ExtraDate2 : WORD;            {Extra date 2 - Semi-MS-DOS 1900 based format}

    ExtraWord1,                   {Extra word 1}
    ExtraWord2,                   {Extra word 2}
    ExtraWord3,                   {Extra word 3}
    ExtraWord4 : WORD;            {Extra word 4}

    ExtraChar1,                   {Extra character 1}
    ExtraChar2,                   {Extra character 2}
    ExtraChar3,                   {Extra character 3}
    ExtraChar4 : CHAR;            {Extra character 4}

    ExtraPhone : STRING[12];      {Extra phone}

    uureserved                    {Reserved}
      : ARRAY[1..3] OF BYTE;

    {**********************************************************************}
    {* Vote  = An array of Voting Answers, One for each question          *}
    {**********************************************************************}
    Vote : ARRAY[1..20] OF BYTE;  {Voting}

    {**********************************************************************}
    {* Call spread for last 15 calls - Number  of days between each call: *}
    {* 0      = Called the same day                                       *}
    {* 1..253 = X number of days between                                  *}
    {* 254    = 254 or more days between                                  *}
    {* 255    = Element not used yet                                      *}
    {**********************************************************************}
    CallSpr                       {Call spread}
       : ARRAY[1..15] OF BYTE;

    Ttimeon,                      {Total time on system in minutes}
    UlK,                          {UL K-Bytes}
    Dlk : REAL;                   {DL K-Bytes}

    {**********************************************************************}
    {* UserNum = The User number                                          *}
    {*           0  -----------------------------> Deleted                *}
    {*           Same as Record Number ----------> Normal                 *}
    {*           Different from Record Number ---> Locked Out             *}
    {**********************************************************************}
    UserNum : INTEGER;            {User number}

    PrivPost,                     {Private posts}
    PubPost,                      {Public posts}
    FeedBack,                     {Feedback sent to SysOp}
    NumCalls,                     {Total number of calls to system}
    NumUL,                        {Number of uploads}
    NumDL : WORD;                 {Number of downloads}

    {**********************************************************************}
    {* Fmail = Status of Mail Forwarding                                  *}
    {*           0  --------> Forwarding inactive                         *}
    {*           Other  ----> User Number to forward mail to              *}
    {**********************************************************************}
    Fmail : INTEGER;              {Forward mail to which user number}

    Hbaud,                        {Highest baud rate user supports}
    TimeToday,                    {Minutes on system date of last call}
    Credit,                       {Credit for mail in cents}
    Debit,                        {Debit for mail in cents}
    Points,                       {File points}
    TimeBank,                     {Minutes in time bank}
    Bday,                         {Birthdate of user - Semi-MS-DOS format}
    LastChange : WORD;            {Reserved}

    StrtMenu,                     {Reserved}
    SL,                           {Security level - SL}
    DSL,                          {Download security level - DSL}
    Hlvl,                         {Help level}
    Colms,                        {Number of screen columns}
    Lines,                        {Number of screen lines}
    Callstoday,                   {Number of calls to system today}
    Illegal : BYTE;               {Illegal logon attempts}

    Gender : CHAR;                {User gender M/F/' '=not specified}

    uulMsgBase,                   {Reserved}
    uuLdlBase,                    {Reserved}
    Cls : BYTE;                   {Reserved}

    FullEdit : defaultyesnotype;  {Full screen editor status}

    Ar : ArFlagset;               {AR flag set}

    Flags : FlagSet;              {Special flag set}

    FirstOn,                      {Date first on - Semi-MS-DOS format}
    Expires : WORD;               {Date expires - Semi-MS-DOS format}

    UserRecUnused :               {Reserved}
      ARRAY[1..29] OF BYTE;

    Colors : ColorRec;            {User colors}

    TBdeposit,                    {Time deposited in bank today}
    TBwithdraw : BYTE;            {Time withdraw from bank today}

    AdjTime : INTEGER;            {Adjusted time date of last call}

    ConfigFlags : ConfigFlagSet;  {Configuration Flags}

    lMbase,                       {Last message section}
    lFbase : WORD;                {Last file section}

    LastQWKCRC : LongInt;         {CRC of last QWK .REP packet uploaded}

    Unused : Byte;                {Reserved}
  END;

  SmallMessageRec = RECORD        {Short messages - SHORTMSG.DAT}
    Msg : STRING[160];            {Message text}

    Destin : INTEGER;             {User number of who message is to}
  END;

  Vdatar = RECORD                 {Voting questions - VOTING.DAT}
    Question : STRING[74];        {Question}

    NumA : WORD;                  {Number of answers in below array}

    Answ : ARRAY[0..9] OF RECORD  {Array of answer data}
      Ans : STRING[40];           {Answer}

      NumRes : WORD;              {Number of users who choose this response}
    END;
  END;


  UlRec = RECORD                  {File section - FBOARDS.DAT}
    Name : STRING[39];            {Section name 26 Real Len, Rest Colors}

    Filename : STRING[8];         {Listing filename (does not include ".DIR")}
                                  {If UL and DL paths are different,}
                                  {filename for upload section is "FILES"}
                                  {If first character is "@" then *.DIR file}
                                  {is found in main data files directory}

    DlPathname,                   {Download pathname}
    UlPathName : STRING[30];      {Upload pathname}

    Password : STRING[15];        {Password required}

    Flags : UlRecFlagSet;         {File section flags}

    DSL,                          {DSL required}
    SeeNames : BYTE;              {DSL required to see uploader names}

    ArLvl : ArFlagType;           {AR flag required}

    NoRatioGroupNum : BYTE;       {bit  0   : Ratio disabled}
                                  {bits 1-7 : Group number  }
  END;

  Filerec = (                     {File flags}
    NotValidated,                 {File is not validated}
    OwnerRestricted,              {Uploader did not receive credit on upload}
    LocalUpload,                  {File existed locally}    { Added }
    uuF5,                         {Reserved}
    uuF4,                         {Reserved}
    uuF3,                         {Reserved}
    uuF2,                         {Reserved}
    uuF1                          {Reserved}
    );                            {1 byte used for 8 flags in set}

  FlagRecSet = SET OF Filerec;    {Set of file flags}

  UlfRec = RECORD                 {File listing - *.DIR}
    Filename : STRING[12];        {File name}

    Description : STRING[78];     {Description}

    Nacc : WORD;                  {Number of times file downloaded}

    Unused : BYTE;                {Reserved}

    Blocks : WORD;                {Number of 128 byte blocks in file}

    Owner : STRING[36];           {Uploader of file}

    Date : STRING[8];             {Date file uploaded}

    DateN : WORD;                 {Date uploaded in days since Jan 1, 1985}

    Flag : FlagRecSet;            {File status}

    Points : BYTE;                {File points}
  END;

  Range = ARRAY[0..255] OF WORD;  {Range of values for all security levels}


CONST
  numshellfiles = 13;            {Number of defined internal shell files}
  maxshelldesclength = 29;        {Maximum shell file description length}


  shellfiledesc :                 {Array of shell file descriptions}
    ARRAY[1..numshellfiles] OF
    STRING[maxshelldesclength] = (
    'Front end mailer',              {mailer.bat / binkley.bat}
    'External editor',               {extedit.bat}
    'External SysOp function key',   {extern#.bat}
    'Archive file testing',          {filetest.bat}
    'Logon',                         {logon.bat}
    'New logon',                     {newlogon.bat}
    'Post download',                 {postdl.bat}
    'Post upload',                   {postul.bat}
    'Wait screen special function',  {special.bat}
    'TAGMail external reader',       {tagmail.bat}
    'Wait screen terminal function', {term.bat}
    'Welcome',                       {welcome.bat}
    'Logoff'                         {logoff.bat}
    );


TYPE
  shellfileflagtype = (           {Shell file flags}
    shellshowcall,                {Display shell message on screen}
    shelllogcall                  {Log shell message}
  );                              

  shellfileflagset =              {Shell file flag set}
    SET OF shellfileflagtype;     

  shellfilerec = RECORD
    UseSwap : defaultyesnotype;   {Swap shell setting}

    Flags : shellfileflagset;     {Shell file flags}
  END;

  shellfilelist =                 {Array of shell files}
    ARRAY[1..numshellfiles] OF
    shellfilerec;


CONST
  numnewuserquests = 29;          {Number of current new user questions}

  maxnewuserdesclength = 15;      {Maximum new user description length}

  newuserquestdesc :              {Array of new user question descriptions}
    ARRAY[0..numnewuserquests] OF
    STRING[maxnewuserdesclength] = (
    'Inactive',
    'Real Name',
    'Address',
    'City State',
    'Zip Code',
    'Phone Number 1',
    'Phone Number 2',
    'Computer Type',
    'Gender',
    'Birthday',
    'Maximum Baud',
    'Extra String 1',
    'Extra String 2',
    'Extra String 3',
    'Extra Date 1',
    'Extra Date 2',
    'Extra Number 1',
    'Extra Number 2',
    'Extra Number 3',
    'Extra Number 4',
    'Extra Char 1',
    'Extra Char 2',
    'Extra Char 3',
    'Extra Char 4',
    'Extra Phone',
    'Columns/Lines*',
    'Pause*',
    'ANSI/Color*',
    'Tabs*',
    'Password*'
    );


TYPE
  newuserquestrec = RECORD
    itemnum : BYTE;               {Item number to ask or 0=inactive}

    required : BOOLEAN;           {Required/optional}
  END;

  newuserquestlist =              {Array of new user questions}
    ARRAY[1..numnewuserquests] OF
    newuserquestrec;

  {*************************************************************************}
  {* Provide for full 4D awareness (And point support)                     *}
  {*************************************************************************}
  AddressType = RECORD            {Fidonet Style Address (24 Bytes)}
    Zone,                         {Zone, 1   = N. America}
    Net,                          {Net,  120 = SE Michigan}
    Node,                         {Node, 116 = CRIMP BBS}
    Point : WORD;                 {Point, 99% of the time = 0}

    Domain : STRING[15];          {As in FIDONET.ORG}
  END;

  SystatRec = RECORD              {System status - STATUS.DAT}
    AltPath,                      {Alternate file path}
    DictPath : STRING[40];        {Dictionary path}

    DefReadMsgMenu : BYTE;        {Wait screen read message menu}

    dynamicmsg,                   {Dynamic message numbering active}
    dynamicfile,                  {Dynamic file numbering active}
    waitscreendisable,            {Wait screen activity disable}
    requiredvoting : BOOLEAN;     {Require voting when user logs on}

    automsglines,                 {Auto message number of lines}
    uunewuserexpdays,             {Reserved}
    addwordsl : BYTE;             {Add word to dictionary SL}

    expvalkey : CHAR;             {User expired validation key (#13=None)}

    expwarning,                   {Number of days to give warning before expires}
    modifymailflags,              {SL when allowed to modify mail flags}
    netmailfilerequest,           {SL for net mail file requests}
    netmailfileattach : BYTE;     {SL for net mail file attach}

    ModemDebug,                   {Modem debug information written to log}
    UseXMS,                       {Use XMS memory for swap shell}
    ShowFilesOpen,                {Show Files Open on Top Screen}
    LocalSysopWindow,             {SysOp window when on locally}
    AllowSuperFast,               {Allow SHIFT password override}
    WaitSend,                     {FOSSIL buffer inactive}
    OverlayEMS,                   {Attempt EMS of overlays}
    EMSOverXMS,                   {Use EMS over XMS memory for swap}
    DirectScreen,                 {Direct screen writes}
    UseEMS,                       {Use EMS memory for swap shell}
    useswap,                      {Use swap shell}
    UseFossil,                    {Use FOSSIL driver}
    SnowCheck : BOOLEAN;          {Snow checking active}

    BrowseDSL : BYTE;             {DSL to have U/D commands on File Browse Menu}

    BbsID : String[8];            {!2.6f - ID used for Qwk Packets}

    TempDlPath : STRING[40];      {Temp File Download Path}

    MinKpost,                     {Minimum K-Bytes to post}
    MinKul : WORD;                {Minimum K-Bytes to upload}

    AutoChatBufOpen : BOOLEAN;    {Auto chat buffer open}

    nettype : STRING[20];         {Multi-user network type}

    uusystatrec2 :                {Reserved}
      ARRAY[1..15] OF BYTE;       

    LogonPassword,                {SL when SysOp PW #1 needed to logon}
    ReadTextMsg : BYTE;           {SL when allowed to use /READ command}

    AlertChatOnly,                {Alert active only when chat on}
    genericinfo,                  {Generic mode active}
    LogonPhone : BOOLEAN;         {Logon requires phone number}

    DefMsgGroup : STRING[20];     {Default msg section group mask}
    DefFileGroup : STRING[20];    {Default file section group mask}

    MaxQWKMsgsSection:Word;       {Maximum QWK messages allowed per section}
    MaxQWKMsgsTotal  :Word;       {Maximum QWK messages allowed total}

    uusystatrec3 :
      ARRAY[1..9] OF BYTE;        {Reserved}

    LastCaller : STRING[42];      {Name and number of last caller}

    MenuFastKeys : STRING[20];    {Menu fast keys (e.g. "/")}

    BoardPW : STRING[16];         {New user password (Null=None)}

    BoardPhone : STRING[12];      {Board phone number}

    SysopColor,                   {Chat SysOp color}
    UserColor : BYTE;             {Chat user color}

    PostCallFlag : ArFlagType;    {Post call ratio AR flag}

    NoPostCallChk,                {SL when post call ratio ignored}
    ReinitTime,                   {Minutes to re-init modem when no calls}
    StartMenu : BYTE;             {Unused}

    UseAutoMsg,                   {Display auto-message during logon}
    LogonOffHook : BOOLEAN;       {Take phone off-hook on local logon}

    NoPointChk : BYTE;            {DSL when file points ignored}

    LastDate : STRING[8];         {Date last user logged on}

    Address : AddressType;        {Zone/Net/Node/Point/Domain}

    UserOn11x : Boolean;          {Use USERON.BBS version 1.1x}

    shellfile : shellfilelist;    {Shell file information}

    uushellfile :                 {Reserved for shell files}
      ARRAY[1..10] OF BYTE;       

    newuserquest :                {New user question information}
      newuserquestlist;           

    uunewuserquest :              {Reserved}
      ARRAY[1..270] OF BYTE;      

    ActiveModemRecNum : BYTE;     {Active Modem Record Number}

    MultiUserPath : STRING[40];   {Multi-user path}

    defusereditlist : BYTE;       {Default user editor list mode}
                                  {0=short, 1=normal, 2=extended, 3=info}

    uusystatrec5 :                {Reserved}
       ARRAY[1..10] OF BYTE;      

    GfilesPath : STRING[40];      {Main data files path}

    StoreBadLogon : BOOLEAN;      {Store bad logon info in SysOp log}

    MaxBdNum,                     {Maximum number of batch DL files}
    MaxBuNum : BYTE;              {Maximum number of batch UL files}

    BoardName : STRING[48];       {Board name}

    SysopMenuSL : BYTE;           {SL required for SysOp Control-Q menu}

    SysopMenuAR : ArFlagType;     {AR flag required from Control-Q menu}

    SysopName : STRING[36];       {SysOp name}

    SwapPath : STRING[40];        {Swap shell path}

    ChatPW : STRING[16];          {Chat password}

    LastDragonVersion : STRING[20];  {Last version of Dragon to run}   { Changed }

    nodelistpath : STRING[40];    {Nodelist directory}

    BoardCityState : String[32];  {Board City, State for QWK Pkt}

    QWKPath : String[40];         {QWK Path}
    RIPPath : String[40];         {RIP Path}

    uusystatrec6 :                {Reserved}
      ARRAY[1..2193] OF BYTE;

    SysopPW :                     {Array of SysOp passwords}
      ARRAY[1..3] OF STRING[16];  

    uusystatrec7 :                {Reserved}
      ARRAY[1..120] OF BYTE;      

    CallerNum,                    {Total number of calls to system}
    UlKtoday,                     {K-Bytes uploaded today}
    DlkToday,                     {K-Bytes downloaded today}
    uur1,                         {Reserved}
    uur2,                         {Reserved}
    uur3 : REAL;                  {Reserved}

    Users,                        {Number of active users}
    ActiveToday,                  {Minutes active today}
    Callstoday,                   {Calls today}
    MsgPostToday,                 {Public messages posted today}
    EmailToday,                   {Private messages posted today}
    FbackToday,                   {Feedback sent to SysOp today}
    UlToday,                      {Number of uploads today}
    uuw1,                         {Reserved}
    uuw2,                         {Reserved}
    uuw3,                         {Reserved}
    MaxUsers,                     {Maximum users allowed to be active}
    ErrorsToday,                  {Number of errors today}
    NusersToday,                  {Number of new users today}
    DlToday : WORD;               {Number of downloads today}

    NewUserMsgTo,                 {User number new user message sent to}
    uui1,                         {Reserved}
    SysopMailTo,                  {User number mail to "SYSOP" is sent to}
    GuestUser,                    {Guest user number (0=None)}
    FailedLogonMsgTo : INTEGER;   {Failed logon message sent to}

    uuw5,                         {Reserved}
    UsageLogDays,                 {Number of days to keep USAGE.LOG}
    WaitMailUser : INTEGER;       {Mail waiting on wait screen (0=none)}

    UEditJumpSL : BYTE;           {SL required for SysOp Control-U menu}
    UEditJumpAR : ArFlagType;     {AR flag required from Control-U menu}

    NoviceDisplay : BYTE;         {Number of calls to display novice msg}

    NodeNumber : BYTE;            {Multi-user node number}

    UEditJumpPassword,            {Use System pswd for Quick User Edit}
    ScanOnUploads : BOOLEAN;      {System permits forced scan on uploads}

    MaxTimeInBank : WORD;         {Maximum minutes in time bank}

    ShowGifRes,                   {Show GIF resolution}
    CheckUploadSpace,             {Show upload drive space}
    SystemSecur : BOOLEAN;        {Full keyboard security active}

    MultiUser : BOOLEAN;          {Board in multi-user mode}

    TBmaxDeposit,                 {Maximum daily time bank deposit}
    TBmaxWithdraw,                {Maximum daily time bank withdraw}
    SysopLvl,                     {SL for SysOp}
    CoSysopLvl,                   {SL for CoSysOp}
    uub1,                         {Reserved}
    AddBbsLvl,                    {SL for adding boards to bbs listing}
    EmailLvl,                     {SL for sending normal private mail}
    uub2,                         {Reserved}
    uub3,                         {Reserved}
    SeeUnvalLvl,                  {DSL for seeing unvalidated files}
    DlCoSysopLvl,                 {DSL for Download CoSysOp}
    NoRatioChk,                   {DSL for no ratio}
    ReadAnon,                     {SL to know see anonymous real name     }
    ReplyAnon,                    {SL to reply to anonymous private mail  }
    PublicAnonAny,                {SL to post anonymous on any public base}
    PrivateAnonAny,               {SL to send private anonymous mail      }
    MaxPublicCall,                {Maximum public posts per call}
    MaxPrivCall,                  {Maximum private messages per call}
    MaxFbackCall,                 {Maximum feedback to SysOp per call}
    uub4,                         {Reserved}
    SeePasswords,                 {SL to see user passwords remotely}
    uub5,                         {Reserved}
    uub6,                         {Reserved}
    ComPort,                      {Communications port}
    TimeOut,                      {Minutes for inactivity time-out}
    TimeOutBell,                  {Minutes for inactivity bell}
    Backlogdays,                  {Number of days to keep SYSOP.LOG's}
    PrivilegeSL,                  {Privilege SL}
    PrivilegeDSL,                 {Privilege DSL}
    CDmask,                       {Carrier detect mask}
    MaxLogonTries,                {Maximum logon attempts per call}
    uub7,                         {Reserved}
    uub8,                         {Reserved}
    UlTimePercent,                {UL time percent refund}
    MaxChats,                     {Maximum chat pages per call}
    uub9,                         {Reserved}
    TagLineSL : BYTE;             {Reserved}

    ClosedSystem,                 {System closed}
    TitlePause,                   {Allow [PAUSE] on welcome screen}
    LogonBulletin,                {Logon to the bulletin section}
    BlankWait,                    {Blank the wait screen if no activity}
    Handles,                      {Allow handles}
    AutoANSIDetect,               {Logon auto-detect ANSI}
    SecureSystem,                 {Keyboard security active}
    TimePerDay,                   {Time limits represent time per day}
    Mailer,                       {External mailer active}
    SysopFemale,                  {SysOp is female}
    scantosysoplog : BOOLEAN;     {File scans are saved in SysOp log}

    TimeAllowed,                  {SL array of time per call/per day}
    UlDlNumRatio,                 {DSL array of number of file UL ratios}
    UlDlKratio,                   {DSL array of K-Byte UL ratios}
    CallsAllowed,                 {SL array of calls allowed per day}
    PostCall : Range;             {SL array of posts per 1/10 call}

    AutoRIPDetect  : BOOLEAN;     {Logon auto-detect RIP}

    uusystatrec8 :
      ARRAY[1..7] OF BYTE;        {Reserved}
  END;


  MenuFlagType = (                {Menu flag type}
    MenuOrCheck,                  {SL/DSL or AR - When off SL/DSL and AR}
    MenuTimeHelpDisplay,          {Time/Help display}
    MenuBoardDisplayOverride,     {Board display override}
    MenuNamePrompt,               {Menu name prompt}
    AscIIClearBeforeMenu,         {ASCII Clear screen before printing menu}
    AnsiClearBeforeMenu,          {ANSI Clear screen before printing menu}
    RipClearBeforeMenu,           {RIP Clear screen before printing menu}
    UUMF9,                        {Reserved}
    UUMF8,                        {Reserved}
    UUMF7,                        {Reserved}
    UUMF6,                        {Reserved}
    UUMF5,                        {Reserved}
    UUMF4,                        {Reserved}
    UUMF3,                        {Reserved}
    UUMF2,                        {Reserved}
    UUMF1                         {Reserved}
    ); {1 byte}

  MenuFlagSet =                   {Set of menu flags}
    SET OF MenuFlagType;

  CmdFlagType = (
    CmdOrCheck,                   {SL or AR - When off SL and AR}
    CmdHidden,                    {Hidden status}
    CmdLinkToNext,                {Link to next}
    AscIIClearBeforeCmd,          {ASCII clear screen before command}
    AscIIPauseAfterCmd,           {ASCII pause after command completed}
    AnsiClearBeforeCmd,           {ANSI clear screen before command}
    AnsiPauseAfterCmd,            {ANSI pause after command completed}
    RipClearBeforeCmd,            {RIP clear screen before command}
    RipPauseAfterCmd,             {RIP pause after command completed}
    AnsiOnly,                     {Command requires ANSI or RIP}
    RipOnly,                      {Command requires RIP}
    UUCF5,                        {Reserved}
    UUCF4,                        {Reserved}
    UUCF3,                        {Reserved}
    UUCF2,                        {Reserved}
    UUCF1                         {Reserved}
    ); {2 bytes}

  CmdFlagSet =                    {Set of command flags}
    SET OF CmdFlagType;

  MenuRec = RECORD                {Menus - MENUS.LST}
    LongD : STRING[80];           {Menu desc (menu) or Long command desc (cmd)}

    SL,                           {Security level (SL)}
    DSL : Byte;                   {Download security level (DSL)}

    ArFlags : ArFlagSet;          {AR flag set}

    UUMenu:Array[1..10] of byte;  {Reserved}

    CASE Menu : BOOLEAN OF        {Menu or command - Variant section}
{80}  TRUE :
        (MenuFlags : MenuFlagSet; {Menu flag set}

         MenuNum : BYTE;          {Menu number}

         mPrompt : STRING[48];    {Menu prompt unless MenuNamePrompt active}

         Password : STRING[16];   {Menu password}

         FallBack : BYTE;         {Fallback menu number}

         HelpFile : STRING[7];    {Help file ID name}

         StartHelp : BYTE;        {Starting help level 0=default}

         Location : BYTE);        {Menu location (0=Main, 1=File, 2=ReadMessage)}
{80}  FALSE :
        (CmdFlags : CmdFlagSet;   {Command flag set}

         Pkey : BYTE;             {Command PKey}

         Pdata : STRING[30];      {Command PData}

         Shortd : STRING[32];     {Command short description}

         CmdKey : STRING[12]);    {Command execution key}
  END; {case/record}


  MacroRec = RECORD               {Macro list - MACROS.LST}
    UserN : INTEGER;              {User number of macro owner}

    Key :                         {Txt for each of the macros}
      ARRAY[1..4] OF STRING[160];
  END;


  SprotocolRec = RECORD           {Single protocols - SPROT.DAT}
    Key : STRING[12];             {Execution key}

    Desc : STRING[60];            {Description}

    MinBaud,                      {Minimum baud rate to use}
    MaxBaud : WORD;               {Maximum baud rate to use}

    DSL : BYTE;                   {DSL required}

    TempLog,                      {Temp log path and name}
    UlLog,                        {UL log path and name}
    DlLog : STRING[52];           {DL log path and name}

    UlString,                     {UL string for DOS call}
    DlString : STRING[70];        {DL string for DOS call}

    GoodCode : BOOLEAN;           {Result codes mean good transfer}

    DlCode,                       {DL error level result codes}
    ULcode : ARRAY[1..6] OF BYTE; {DL error level result codes}
  END;

  BprotocolRec = RECORD           {Batch protocols - BPROT.DAT}
    Key : STRING[12];             {Execution key}

    Desc : STRING[60];            {Description}

    MinBaud,                      {Minimum baud rate to use}
    MaxBaud : WORD;               {Maximum baud rate to use}

    DSL : BYTE;                   {DSL required}

    UlString,                     {UL string for DOS call}
    DlString : STRING[70];        {DL string for DOS call}

    UlList,                       {UL file list file path and name}
    DlList,                       {DL file list file path and name}
    TempLog,                      {Temp log path and name}
    UlLog,                        {UL log path and name}
    DlLog : STRING[52];           {DL log path and name}

    MaxCmdLen,                    {Maximum command line length}
    PosFn,                        {Position of filename in log}
    PosStatus : BYTE;             {Position of status in log}

    GoodCode : BOOLEAN;           {Result codes mean good transfer}

    DlCode,                       {DL status result codes}
    ULcode :                      {UL status result codes}
      ARRAY[1..6] OF STRING[10];  
  END;

  ValidationRec = RECORD          {Validation information - VALIDATE.DAT}
    Key : CHAR;                   {Execution key}

    Desc : STRING[160];           {Descrip sent to user after validation}
                                  {76 max real length - Rest for color}

    SL,                           {SL to set on validation}
    DSL : BYTE;                   {DSL to set on validation}

    Credit,                       {Credit in cents to set on validation}
    Points,                       {File points to set on validation}
    TimeBank : WORD;              {Time bank minutes to set on validation}

    Ar : ArFlagset;               {AR flags to set on validation}

    Flags : FlagSet;              {Special flags to set on validation}

    UnusedWord : WORD;            {Reserved}
  END;

  EventType      = (              {Event flags}
    UnknownEvent,                 {1  Unknown}
    EventIsExternal,              {2  External/Internal}
    EventIsActive,                {3  Active/InActive}
    EventIsShell,                 {4  Shell/Error}
    EventIsMonthly,               {5  Monthly/Daily}
    EventIsPermission,            {6  Permission/Restriction}
    EventIsChat,                  {7  Chat Event}
    EventIsSoft,                  {8  Soft/Hard}

    BaudIsActive,                 {9  Baud Rate Flag}
    SLisActive,                   {10 SL Flag}
    DSLisActive,                  {11 DSL Flag}
    ARisActive,                   {12 ARflag required}
    InRatioIsActive,              {13 InRatioFlag}
    TimeIsActive,                 {14 Time Flag}
    SetARisActive,                {15 Set AR flag}
    ClearARisActive,              {16 Clear AR Flag}

    uuEvent24,                    {17 Reserved}
    uuEvent23,                    {18 Reserved}
    uuEvent22,                    {19 Reserved}
    uuEvent21,                    {20 Reserved}
    uuEvent20,                    {21 Reserved}
    uuEvent19,                    {22 Reserved}
    uuEvent18,                    {23 Reserved}
    uuEvent17,                    {24 Reserved}

    uuEvent16,                    {25 Reserved}
    uuEvent15,                    {26 Reserved}
    uuEvent14,                    {27 Reserved}
    uuEvent13,                    {28 Reserved}
    uuEvent12,                    {29 Reserved}
    uuEvent11,                    {30 Reserved}
    uuEvent10,                    {31 Reserved}
    uuEvent9,                     {32 Reserved}

    uuEvent8,                     {33 Reserved}
    uuEvent7,                     {34 Reserved}
    uuEvent6,                     {35 Reserved}
    uuEvent5,                     {36 Reserved}
    uuEvent4,                     {37 Reserved}
    uuEvent3,                     {38 Reserved}
    uuEvent2,                     {39 Reserved}
    uuEvent1                      {40 Reserved}
    );

  EventFlagSet = SET OF EventType;   { Added }

  EventDaysType  = SET OF 0..6;   {Set of event days}

  {*************************************************************************}
  {* The Record Structure of the EventFile                                 *}
  {*************************************************************************}
  EventRecordType = RECORD        {Events - EVENTS.DAT}
    EventFlags : EventFlagSet;    {Kinds of Events Supported}   { Changed }

    EventDayOfMonth : BYTE;       {If monthly, the Day of Month}

    EventDays : EventDaysType;    {If Daily, the Days Active}

    EventStartTime,               {Start Time in Min from Mid.}
    EventFinishTime : WORD;       {Finish Time}

    EventDesc : STRING[32];       {Description of the Event}

    EventQualMsg,                 {Msg/Path if he qualifies}
    EventNotQualMsg : STRING[64]; {Msg/Path if he doesn't}

    EventPreTime : BYTE;          {Min. B4 event to rest. Call}

    EventOffHook : BOOLEAN;       {Take phone Offhook ?}

    EventLastDate : STRING[8];    {Last Date Executed}

    EventErrorLevel : BYTE;       {For Ext Event ErrorLevel}

    EventShellPath : STRING[8];   {File for Ext Event Shell}

    LoBaud,                       {Low baud rate limit}
    HiBaud : WORD;                {High baud rate limit}

    LoSL,                         {Low SL limit}
    HiSL,                         {High SL limit}
    LoDSL,                        {Low DSL limit}
    HiDSL : BYTE;                 {High DSL limit}

    ARflagRequired : CHAR;        {AR flag required}

    MaxTimeAllowed : WORD;        {Max Time per user this event}

    SetARflag,                    {AR Flag to Set}
    ClearARflag : CHAR;           {AR Flag to Clear}

    EventUnused :                 {Reserved}
      ARRAY[1..128] OF BYTE;      
  END;

CONST
  maxmodemresultcodes = 45;       {Maximum number of modem result codes}

TYPE
  modemresulttype = (             {Modem result types}
    resulterror,                  {Command error}
    resultok,                     {Command accepted}
    resultring,                   {Phone ringing}
    resultnocarrier,              {Connect attempt failed}
    resultconnect,                {Connect succcessful}
    resultwaitscreen,             {Go to wait screen}
    resultlocallogon,             {Logcal logon}
    resultshellbatch,             {Shell to batch file}
    resultexiterrorlevel,         {Exit system with error level}
    resultexitsystem,             {Exit system with error level 255}

                                  {The following are not supported}
    resultnodialtone,             {Reserved}
    resultringing,                {Reserved}
    resultbusy,                   {Reserved}
    resultnoanswer,               {Reserved}
    resultvoice                   {Reserved}
    );

  modemresultset =                {Set to modem results - Used intenally}
    SET OF modemresulttype;
                                  

  resultrec = RECORD
    typeofresult :                {Type of result}
      modemresulttype;            

    result : STRING[50];          {Test of result}

    connectrate,                  {Connect rate modem to modem}
    realrate,                     {Real rate computer to modem}
    controlcode : LONGINT;        {Error level or startup code}

    fullduplex,                   {Full duplex operation?}
    errorcorrecting : BOOLEAN;    {Error correcting modem?}

    Unused : ARRAY[1..8] OF CHAR; {Reserved}
  END;

{
Modem string mapping codes:

Char.  Name             Action
-----  ---------------  ------------------------------
 ^     Carat            Control code of next character
 |     Pipe, Split Bar  Carriage return sent
 `     Accent Mark      1/20th second delay
 ~     Tilde            1/2 second delay
 ^-    Carat & Minus    Lower DTR line
 ^+    Carat & Plus     Raise DTR line
}

  modemrec = RECORD               {Modem record - MODEM.DAT}
    uuunused : BOOLEAN;           {Unused}

    modemdescription :            {Description on modem}
      STRING[64];                 

    characterdelay : BYTE;        {Miliseconds}

    ctsrts,                       {Hardware flow control active}
    samering,                     {Reserved}
    nocollide : BOOLEAN;          {Reserved}

    numberresults : BYTE;         {Number of modem result codes defined}

    result :                      {Array of results}
      ARRAY[1..maxmodemresultcodes] OF
      resultrec;                  

    preinitialization,            {Pre-initialization string}
    initialization,               {Initialization string}
    answer,                       {Answer string}
    busy,                         {Busy string}
    hangupprimary,                {Hangup primary string}
    hangupsecondary,              {Hangup secondard string}
    afterhangup,                  {After hangup string}
    exitsystem,                   {Exit system string}
    predial,                      {Reserved}
    dialprefix,                   {Reserved}
    dialsuffix : STRING[64];      {Reserved}

    waitbaud : LONGINT;           {Init modem speed}

    lockedbaud : BOOLEAN;         {Is baud rate locked - Not used by Dragon}

    ecefficiency,                 {Error correcting efficiency}
    ncefficiency : BYTE;          {Normal connect efficiency}

    Unused :
      ARRAY[1..249] OF CHAR;      {Reserved}
  END;

CONST
  MaxSubOps = 10;                 {Maximum number of message section SubOps}

TYPE
  NoYesForcedType = (             {Message section type}
    No,                           {Anonymous messages not allowed}
    Yes,                          {Anonymous messages allowed}
    Forced,                       {Messages forced anonymous}
    AtUnused                      {Reserved}
    );

  {*************************************************************************}
  {* Standard Attributes for Messages                                      *}
  {*************************************************************************}
  MessageAttrFlagType = (
    Msg_Private,                  {1  fPrivate,RaPrivate,JamPrivate}
    Msg_Crash,                    {2  fCrash,Crash,JamCrash}
    Msg_Received,                 {3  fReceived,Received,JamRead}
    Msg_Sent,                     {4  fSent,Sent,JamSent}
    Msg_FileAttached,             {5  fFileAttached,FileAttach,
                                      JamFileAttach}
    Msg_KillSent,                 {6  fKillSent,KillSent,JamKillSent}
    Msg_Local,                    {7  fLocal,LocalMessage,JamLocal}
    Msg_ReturnReceiptRequest,     {8  fReportReceiptRequest,RequestReceipt,
                                      JamReceiptReq}
    Msg_IsReturnReceipt,          {9  fIsReturnReceipt,ReturnReceipt}
    Msg_AuditRequest,             {10 fAuditRequest,AuditRequest}

    Msg_InTransit,                {11 fInTransit,JamIntransit}
    Msg_Orphan,                   {12 fOrphan,JamOrphan}
    Msg_HoldForPickup,            {13 fHoldForPickup,JamHold}
    Msg_Fido_UnusedBit10,         {14 fUnusedBit10}
    Msg_FileRequest,              {15 fFileRequest,JamFileRequest}
    Msg_Fido_FileUpdateRequest,   {16 fFileUpdateRequest}

    Msg_Deleted,                  {17 Deleted,JamDeleted}
    Msg_Ra_NetmailPendingExport,  {18 NetmailPendingExport}
    Msg_NetMailMessage,           {19 NetMailMessage,JamTypeNet}
    Msg_Ra_EchomailPendingExport, {20 EchomailPendingExport}
    Msg_Ra_UnusedMsgBit7,         {21 UnusedMsgBit7}
    Msg_Ra_UnusedNetBit7,         {22 UnusedNetBit7}

    Msg_Jam_ArchiveSent,          {23 JamArchiveSent}
    Msg_Jam_Immediate,            {24 JamImmediate}
    Msg_Jam_Direct,               {25 JamDirect}
    Msg_Jam_Gate,                 {26 JamGate}
    Msg_Jam_ConfirmRequest,       {27 JamConfirmReq}
    Msg_Jam_ForcePickUp,          {28 JamFpu}
    Msg_Jam_TypeLocal,            {29 JamTypeLocal}
    Msg_Jam_TypeEcho,             {30 JamTypeEcho}
    Msg_Jam_NoDisplay,            {31 JamNoDisp}
    Msg_Jam_Locked                {32 JamLocked}
  ); {4 Bytes Total}

  MessageAttrFlagSet =            {Set of message attributes}
    Set of MessageAttrFlagType;

  MBstyle = (                     {Message section style flags}
    uumbbstyle,                   {Was For Private Mail Board}
    LocalStyle,                   {Local}
    EchoStyle,                    {Echomail}
    NetmailStyle,                 {Netmail}
    GroupStyle                    {Groupmail}
    );

  MBtype = (                      {Message section type flags}
    uumbtype,                     {Was For Netmail Board}
    FidoFormat,                   {Fido 1.Msg Format}
    RaFormat,                     {Remote Access Format}
    JamFormat);                   {Jam Format}

  MboardType = RECORD             {Message boards - MBOARDS.DAT}
    Name : STRING[64];            {Name of the Board}

    Mstyle : MBstyle;             {Local/Echo/Netmail}

    Mtype : MBtype;               {Message Board Type}

    RaBoard : BYTE;               {Board Number if RA/QBBS type}

    Path : STRING[64];            {Directory PathName}

    OriginLine : STRING[65];      {Origin Line}

    AccessAR,                     {AR flag Required to Access}
    PostAR : ArFlagType;          {AR flag required to Post}

    AccessSL,                     {Security Level Required to Access}
    PostSL : BYTE;                {Security Level Required to Post}

    MsgCount,                     {Count of Msgs on the Board}
    MaxMsgs,                      {Max Number of Messages}
    uuMaxOld : WORD;              {Max Days for Messages}

    Password : STRING[16];        {Password Required}

    Anon : NoYesForcedType;       {Anonymous Type}

    AllowAnsi : BOOLEAN;          {Should we allow ANSI}

    AllowHandle :                 {Should we allow handles}
      NoYesForcedType;            

    {*********************************************************}
    {* Message Board SubOpts List  - Up to 10 - User Numbers *}
    {*********************************************************}
    SubOps :                      {SubOps - Item 0 = How many}
      ARRAY[0..MaxSubOps] OF
      INTEGER;                    

    EchoTag : STRING[32];         {Echo Tag for Writing ECHOMAIL.BBS}

    UseOtherAddress: BOOLEAN;     {Use something other than system}

    JamBoard : STRING[8];         {JAM 8 character file name}

    AskPrivate : Boolean;         {Ask if in area private message (echos)}

    Reserved:                     {Unused}
      ARRAY[1..13] of byte;

    MenuNumber : BYTE;            {Default read message number (if 0, use system default}

    PrePostFile : STRING[8];      {Prepost file name}

    MinMsgs : BYTE;               {Minimum number of messages}

    QuoteStart,                   {Override starting quote}
    QuoteEnd : STRING[70];        {Override ending quote}

    QwkConf : WORD;               {QWK Conference Number}

    GroupNumber : BYTE;           {What group the board belongs}

    OtherAddress : AddressType;   {The Address to use!}

    RestrictPrivate:              {Private mail status}
      NoYesForcedType;

    DefaultAttr :                 {Default message flags}
      MessageAttrFlagSet;

    QwkName : String[10];         {QWK Conference Name}

    Filter7Bit : Boolean;         {Only allow 7 bit characters}
  END;

TYPE
  LastOnType =                    {Last Few Callers - LASTON.DAT}
    Array[1..8] of String[160];   

Const
  MaxBits = 1024;                 {Means a 128 Byte BitSet Bits 0 to 1023}

Type
  BitSetType =                    {Board Flags - ?ZSCAN.DAT}
    Array[0..(MaxBits Div 8)-1] of
    Byte;                         


  WhoRecType = RECORD             {Who's online - $WHO.DAT}
    Active : Boolean;

    Node : Byte;                  {Node number for this record}

    Available : Boolean;          {Is he available for anything}

    Uname : String[36];           {Users Name}

    CityState : String[30];       {City and State}

    Baud : LongInt;               {Baud Rate}

    Paging : Byte;                {Paging Node Number}

    InPrivateChat : Byte;         {Node in private chat with}

    InGroupChat : Boolean;        {Is he in Group Chat}

    Desc : String[64];            {Long Description}
  END;

  UserOnType100 = RECORD          {USERON.BBS file version 1.00}
    Name : String[35];            {User name}

    Line : Byte;                  {Node number}

    Baud : Word;                  {Connect rate}

    City : String[25];            {City/State}

    DoNotDisturb : Boolean;       {Do not disturb}

    Status : Byte;                {Status}
  END;

  UserOnType11x = RECORD          {USERON.BBS file version 1.1x}
    Name : String[35];            {Real name}

    Handle : String[35];          {User name}

    Line : Byte;                  {Node number}

    Baud : Word;                  {Connect rate}

    City : String[25];            {City/State}

    DoNotDisturb : Boolean;       {Do not disturb}

    Status : Byte;                {Status}

    Attribute : Byte;             {Attribute}
  END;

  Type200Attr = (RA_Hidden,       {Bit 0}
                 RA_WantsChat,    {Bit 1}
                 RA_Netmgr,       {Bit 2}
                 RA_DoNotDisturb, {Bit 3}
                 RA_Bit4,         {Bit 4}
                 RA_Bit5,         {Bit 5}
                 RA_Ready,        {Bit 6}
                 RA_Bit7);        {Bit 7}

  UserOnType200 = RECORD          {USERON.BBS file version 2.00 Gamma}
    Name      : String[35];           {Real name}
    Handle    : String[35];           {User name}
    Line      : Byte;                 {Node number}
    Baud      : Word;                 {Connect rate}
    City      : String[25];           {City/State}
    Status    : Byte;                 {Status}

  { Status byte - 0 : Browsing (in a menu)
                  1 : Uploading/downloading
                  2 : Reading/posting messages
                  3 : In a door/external utility
                  4 : Chatting with sysop
                  5 : Answering questionnaire
                  6 : RTC
                  7 : New user logon
                255 : User-defined - display StatDesc
  }
    Attribute : Type200Attr;          {Attribute}
    StatDesc  : String[10];           {Status Description}
    FreeSpace : Array[1..98] of Byte; {For Expansion}
    NoCalls   : Word;
  END;

