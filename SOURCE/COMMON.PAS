{$IFDEF WIN32}
{$I DEFINES.INC}
{$ENDIF}

{$A+,B-,D-,E-,F+,I-,L-,N+,O-,R-,S-,V-}

UNIT Common;

INTERFACE

USES
  Crt,
  Dos,
  MyIO,
  TimeFunc;

{$I RECORDS.PAS}

CONST
  StrLen = 119;

TYPE
  MCIFunctionType = FUNCTION(CONST s: AStr; Data1, Data2: Pointer): STRING;

  MemMenuRec = RECORD                     { Menu Record }
    LDesc: ARRAY[1..3] OF STRING[100];    { menu name }
    ACS: ACString;                        { access requirements }
    NodeActivityDesc: STRING[50];
    MenuFlags: MenuFlagSet;               { menu status variables }
    LongMenu: STRING[12];                 { displayed IN place OF long menu }
    MenuNum: Byte;                        { menu  number }
    MenuPrompt: STRING[120];              { menu Prompt }
    Password: STRING[20];                 { password required }
    FallBack: Byte;                       { fallback menu }
    Directive: STRING[12];
    ForceHelpLevel: Byte;                 { forced help Level FOR menu }
    GenCols: Byte;                        { generic menus: # OF columns }
    GCol: ARRAY[1..3] OF Byte;            { generic menus: colors }
  END;

  MemCmdRec = RECORD                      { Command records }
    LDesc: STRING[100];                   { long command description }
    ACS: ACString;                        { access requirements }
    NodeActivityDesc: STRING[50];
    CmdFlags: CmdFlagSet;                 { command status variables }
    SDesc: STRING[35];                    { short command description }
    CKeys: STRING[14];                    { command-execution keys }
    CmdKeys: STRING[2];                   { command keys: type OF command }
    Options: STRING[50];                  { MString: command data }
  END;

  LightBarRecordType = RECORD
    XPos,
    YPos: Byte;
    CmdToExec: SmallInt;
    CmdToShow: STRING[40];
  END;

  States =
   (Waiting,
    Bracket,
    Get_Args,
    Get_Param,
    Eat_Semi,
    In_Param,
    GetAvCmd,
    GetAvAttr,
    GetAvRLE1,
    GetAvRLE2,
    GetAvX,
    GetAvY);

  StorageType =
   (Disk,
    CD,
    Copied);

  TransferFlagType =
   (lIsAddDLBatch,
    IsFileAttach,
    IsUnlisted,
    IsTempArc,
    IsQWK,
    IsNoFilePoints,
    IsNoRatio,
    IsCheckRatio,
    IsCDRom,
    IsPaused,
    IsAutoLogOff,
    IsKeyboardAbort,
    IsTransferOk);

  TransferFlagSet = SET OF TransferFlagType;

  BatchDLRecordType = RECORD
    BDLFileName: Str52;
    BDLOwnerName: Str36;
    BDLStorage: StorageType;
    BDLUserNum,
    BDLSection,
    BDLPoints,
    BDLUploader: SmallInt;
    BDLFSize,
    BDLTime: LongInt;
    BDLFlags: TransferFlagSet;
  END;

  BatchULRecordType = RECORD
    BULFileName: Str12;
    BULUserNum,
    BULSection: SmallInt;
    BULDescription: Str50;
    BULVPointer: LongInt;
    BULVTextSize: SmallInt;
  END;

  ExtendedDescriptionArray = ARRAY [1..99] OF Str50;

  IEMSIRecord = RECORD
    UserName,
    Handle: STRING[36];
    CityState: STRING[30];
    Ph: STRING[12];
    PW: STRING[20];
    BDate: STRING[10];
  END;

  StrPointerRec = RECORD
    Pointer,
    TextSize: LongInt;
  END;

  MemCmdPointer = ^MemCmdArray;
  MemCmdArray = ARRAY [1..MaxCmds] OF MemCmdRec;

  MCIBufferType = ARRAY [1..MaxConfigurable] OF Char;
  MCIBufferPtr = ^MCIBufferType;

  Multitasker =
   (None,  (* Dos 5 thu 9 *)
    DV,
    Win,
    OS2,
    Win32,
    DOS5N);

  InputFlagType =
   (UpperOnly,        { Uppercase only }
    ColorsAllowed,    { Colors allowed }
    NoLineFeed,       { Linefeeds OFF - no linefeed after <CR> pressed }
    ReDisplay,        { Display old IF no change }
    CapWords,         { Capitalize characters }
    InterActiveEdit,  { Interactive editing }
    NumbersOnly,
    DisplayValue,
    NegativeAllowed); { Numbers only }

  InputFlagSet = SET OF InputFlagType;

  ValidationKeyType = SET OF '!'..'~'; (* Remove q and Q *)

  ConferenceKeyType = SET OF '@'..'Z';

  CompArrayType = ARRAY[0..1] OF SMALLINT;

CONST
  MCIBuffer: MCIBufferPtr = NIL;
  DieLater: Boolean = FALSE;         { IF TRUE, Renegade locks up }
  F_HOME = 18176;      { 256 * Scan Code }
  F_UP   = 18432;
  F_PGUP = 18688;
  F_LEFT = 19200;
  F_RIGHT = 19712;
  F_END  = 20224;
  F_DOWN = 20480;
  F_PGDN = 20736;
  F_INS  = 20992;
  F_DEL  = 21248;
  F_CTRLLEFT  = 29440;
  F_CTRLRIGHT = 29696;
  NoCallInitTime = (30 * 60);     { thirty minutes between modem inits }
  Tasker: Multitasker = None;
  LastScreenSwap: LongInt = 0;
  ParamArr: ARRAY [1..5] OF Word = (0,0,0,0,0);
  Params: Word = 0;       { number OF parameters }
  NextState: States = Waiting;  { Next state FOR the parser }
  TempSysOp: Boolean = FALSE;  { is temporary sysop? }
  Reverse: Boolean = FALSE;   { TRUE IF Text attributes are reversed }
  TimeLock: Boolean = FALSE;   { IF TRUE, DO NOT HangUp due TO time! }
  SaveX: Byte = 0;        { FOR ANSI driver}
  SaveY: Byte = 0;        { FOR ANSI driver}
  TempPause: Boolean = TRUE;       { is Pause on OR off?  Set at prompts, OneK, used everywhere }
  OfflineMail: Boolean = FALSE;  { are we IN the offline mail system? }
  MultiNodeChat: Boolean = FALSE; { are we IN MultiNode chat?}
  ChatChannel: Integer = 0;    { What chat channel are we IN? }
  DisplayingMenu: Boolean = FALSE; { are we displaying a menu?       }
  InVisEdit: Boolean = FALSE;      { are we IN the visual editor? }
  MenuAborted: Boolean = FALSE;  { was the menu Aborted? }
  AllowAbort: Boolean = TRUE;   { are Aborts allowed?          }
  MCIAllowed: Boolean = TRUE;   { is mci allowed? }
  ColorAllowed: Boolean = TRUE;  { is color allowed? }
  Echo: Boolean = TRUE;      { is Text being echoed? (FALSE=use echo Chr)}
  HangUp: Boolean = TRUE;     { is User offline now?         }
  TimedOut: Boolean = FALSE;    { has he timed out?           }
  NoFile: Boolean = TRUE;          { did last pfl() FILE NOT Exist?        }
  SLogging: Boolean = TRUE;    { are we outputting TO the SysOp log?  }
  SysOpOn: Boolean = TRUE;     { is SysOp logged onto the WFC menu?  }
  WantOut: Boolean = TRUE;     { output Text locally?         }
  WColor: Boolean = TRUE;     { IN chat: was last key pressed by SysOp? }
  BadDLPath: Boolean = FALSE;    { is the current DL path BAD?      }
  BadUlPath: Boolean = FALSE;   { is the current UL path BAD?      }
  BeepEnd: Boolean = FALSE;    { whether TO beep after caller logs off }
  FileAreaNameDisplayed: Boolean = FALSE;      { was FILE area name printed yet?    }
  CFO: Boolean = FALSE;      { is chat FILE open?          }
  InChat: Boolean = FALSE;       { are we IN chat Mode?         }
  ChatCall: Boolean = FALSE;    { is the chat call "noise" on?          }
  ContList: Boolean = FALSE;    { continuous message listing Mode on?  }
  CROff: Boolean = FALSE;     { are CRs turned off?          }
  CtrlJOff: Boolean = FALSE;    { turn color TO #1 after ^Js??     }
  DoneAfterNext: Boolean = FALSE; { offhook AND Exit after Next logoff?  }
  DoneDay: Boolean = FALSE;        { are we done now? ready TO drop TO DOS?}
  DOSANSIOn: Boolean = FALSE;   { output chrs TO DOS FOR ANSI codes?!!? }
  FastLogon: Boolean = FALSE;   { IF a FAST LOGON is requested     }
  HungUp: Boolean = FALSE;     { did User drop carrier?        }
  InCom: Boolean = FALSE;     { accepting input from com?       }
  InWFCMenu: Boolean = FALSE;   { are we IN the WFC menu?        }
  LastCommandGood: Boolean = FALSE;{ was last command a REAL command?   }
  LastCommandOvr: Boolean = FALSE; { override Pause? (NO Pause?)      }
  LocalIOOnly: Boolean = FALSE;  { local I/O ONLY?            }
  MakeQWKFor: Integer = 0;     { make a qwk packet ONLY?        }
  UpQWKFor: Integer = 0;      { upload a qwk packet ONLY?       }
  RoomNumber: Integer = 0;         { Room OF teleconference                }
  PackBasesOnly: Boolean = FALSE; { pack message bases ONLY?       }
  SortFilesOnly: Boolean = FALSE; { sort FILE bases ONLY?         }
  FileBBSOnly: Boolean = FALSE;
  NewMenuToLoad: Boolean = FALSE; { menu command returns TRUE IF new menu TO load }
  OvrUseEMS: Boolean = TRUE;
  OverLayLocation: Byte = 0;       { 0=Normal, 1=EMS, 2=XMS                }
  OutCom: Boolean = FALSE;     { outputting TO com?          }
  DirFileopen1: Boolean = TRUE;  { whether DirFile has been opened before }
  ExtFileOpen1: Boolean = TRUE;
  PrintingFile: Boolean = FALSE;  { are we printing a FILE?        }
  AllowContinue: Boolean = FALSE; { Allow Continue prompts?        }
  QuitAfterDone: Boolean = FALSE; { quit after Next User logs off?    }
  Reading_A_Msg: Boolean = FALSE; { is User reading a message?      }
  ReadingMail: Boolean = FALSE;  { reading private mail?         }
  ShutUpChatCall: Boolean = FALSE; { was chat call "SHUT UP" FOR this call? }
  Trapping: Boolean = FALSE;    { are we Trapping users Text?      }
  UserOn: Boolean = FALSE;     { is there a User on right now?     }
  WasNewUser: Boolean = FALSE;   { did a NEW User log on?        }
  Write_Msg: Boolean = FALSE;   { is User writing a message?      }
  NewEchoMail: Boolean = FALSE;  { has new echomail been entered?    }
  TimeWarn: Boolean = FALSE;    { has User been warned OF time shortage? }
  TellUserEvent: Byte = 0;     { has User been told about the up-coming event? }
  ExitErrors: Byte = 1;      { errorLEVEL FOR Critical error Exit  }
  ExitNormal: Byte = 0;      { errorLEVEL FOR Normal Exit      }
  TodayCallers: Integer = 0;    { new system callers }
  lTodaynumUsers: Integer = 0;   { new number OF users }
  ThisNode: Byte = 0;         { node number }
  AnswerBaud: LongInt = 0;     { baud rate TO answer the phone at   }
  ExtEventTime: Word = 0;     { # minutes before External event    }
  IsInvisible: Boolean = FALSE;  { Run IN invisible Mode? }
  SaveNDescription: STRING[50] = 'Miscellaneous';
  SaveNAvail: Boolean = FALSE;
  LastWFCX: Byte = 1;
  LastWFCY: Byte = 1;
  ANSIDetected: Boolean = FALSE;
VAR
  LightBarArray: ARRAY[1..50] OF LightBarRecordType;
  LightBarCmd,
  LightBarCounter: Byte;
  LightBarFirstCmd: Boolean;

  Telnet: Boolean;
  HangUpTelnet: Boolean;

  DatFilePath: STRING[40];
  Interrupt14: Pointer;     { far ptr TO interrupt 14 }
{$IFDEF MSDOS}
  Ticks: LongInt ABSOLUTE $0040:$006C;
{$ENDIF}
  IEMSIRec: IEMSIRecord;
  FossilPort: Word;
  SockHandle: STRING;      { Telnet Handle }
  CallerIDNumber: STRING[40];  { Caller ID STRING obtained from modem }
  ActualSpeed: LongInt;     { Actual connect rate }
  Reliable: Boolean;       { error correcting connection? }
  ComPortSpeed: LongInt;        { com port rate }
  LastError: Integer;      { Results from last IOResult, when needed }

  General: GeneralRecordType;      { configuration information       }

  DirInfo: SearchRec;

  { Voting Variables }
  VotingFile: FILE OF VotingRecordType;
  Topic: VotingRecordType;
  NumVotes: Byte;

  BBSListFile: FILE OF BBSListRecordType; { bbslist.dat }

  { Conference Variables }
  ConferenceFile: FILE OF ConferenceRecordType;     { CONFRENC.DAT             }
  Conference: ConferenceRecordType;        { Conferences              }
  ConfKeys: ConferenceKeyType;
  NumConfKeys: Integer;
  CurrentConf: Char;       { Current conference tag        }
  ConfSystem: Boolean;     { is the conference system enabled? }

  { Validation Variables }
  ValidationFile: FILE OF ValidationRecordType;
  Validation: ValidationRecordType;
  NumValKeys: Byte;
  ValKeys: ValidationKeyType;

  NumArcs: Byte;

  NodeFile: FILE OF NodeRecordType;    { multi node FILE }
  NodeR: NodeRecordType;
  NodeChatLastRec: LongInt;   { last record IN group chat FILE Read }

  Liner: LineRec;

  SysOpLogFile,            { SYSOP.LOG               }
  SysOpLogFile1,           { SLOGxxxx.LOG             }
  TrapFile,           { TRAP*.MSG               }
  ChatFile: Text;           { CHAT*.MSG               }


  { User Variables }
  UserFile: FILE OF UserRecordType;      { User.LST               }
  UserIDXFile: FILE OF UserIDXRec;    { User.IDX               }
  ThisUser: UserRecordType;       { User's account records                }

  { Color Scheme Variables }
  SchemeFile: FILE OF SchemeRec; { SCHEME.DAT              }
  Scheme: SchemeRec;
  NumSchemes: Integer;

  { Event Variables }
  EventFile: FILE OF EventRecordType;
  MemEventArray: ARRAY [1..MaxEvents] OF ^EventRecordType;
  Event: EventRecordType;
  NumEvents: Integer;              { # OF events    }

  { Protocol Variables }
  ProtocolFile: FILE OF ProtocolRecordType;      { PROTOCOL.DAT             }
  Protocol: ProtocolRecordType;               { protocol IN memory                    }
  NumProtocols: Integer;

  { File Variables }
  FileAreaFile: FILE OF FileAreaRecordType; { FBASES.DAT              }
  MemFileArea,
  TempMemFileArea: FileAreaRecordType;      { File area and temporary file area in memory }
  FileInfoFile: FILE OF FileInfoRecordType; { *.DIR }
  ExtInfoFile: FILE;                        { *.EXT }
  FileInfo: FileInfoRecordType;
  ExtendedArray: ExtendedDescriptionArray;
  NewFilesF: Text;                          { For NEWFILES.DAT in the qwk system }
  FileArea,                                 { File base User is in }
  NumFileAreas,                             { Max number OF FILE bases }
  ReadFileArea,                             { current uboard # IN memory }
  LowFileArea,
  HighFileArea: Integer;
  NewScanFileArea: Boolean;                 { New scan this base? }

  { Batch Download Variables }
  BatchDLFile: FILE OF BatchDLRecordType;
  BatchDL: BatchDLRecordType;
  NumBatchDLFiles: Byte;                     { # files IN DL batch queue       }
  BatchDLSize,
  BatchDLPoints,
  BatchDLTime: LongInt;                      { }

  { Batch Upload Variables }
  BatchULFile: FILE OF BatchULRecordType;
  BatchULF: FILE;
  BatchUL: BatchULRecordType;
  NumBatchULFiles: Byte;                     { # files IN UL batch queue       }

  { Message Variables }
  EmailFile: FILE OF MessageAreaRecordType;
  MsgAreaFile: FILE OF MessageAreaRecordType; { MBASES.DAT              }
  MemMsgArea: MessageAreaRecordType;          { MsgArea IN memory            }
  MsgHdrF: FILE OF MHeaderRec;                { *.HDR                 }
  MsgTxtF: FILE;                              { *.DAT                 }
  LastReadRecord: ScanRec;
  LastAuthor,                                 { Author # OF the last message     }
  NumMsgAreas,                                { Max number OF msg bases        }
  MsgArea,
  ReadMsgArea,
  LowMsgArea,
  HighMsgArea: Integer;
  Msg_On: Word;                               { current message being Read }

  { Menu Variables }
  MenuFile: FILE OF MenuRec;
  MenuR: MenuRec;
  MemMenu: MemMenuRec;                             { menu information           }
  MemCmd: MemCmdPointer;                           { Command information }
  MenuRecNumArray: ARRAY [1..MaxMenus] OF Integer;
  CmdNumArray: ARRAY [1..MaxMenus] OF Byte;
  MenuStack: ARRAY [1..MaxMenus] OF Byte;          { menu stack           }
  MenuKeys: AStr;                                  { keys TO Abort menu display WITH    }
  NumMenus,
  NumCmds,
  GlobalCmds,
  MenuStackPtr,
  FallBackMenu,
  CurMenu,
  CurHelpLevel: Byte;

  Buf: STRING[255];       { macro buffer }
  MLC: STRING[255];       { multiline FOR chat }

  ChatReason,                { last chat reason           }
  LastLineStr,                   { "last-line" STRING FOR Word-wrapping  }
  StartDir: AStr;      { Directory BBS was executed from    }

  TempDir,      { Temporary Directory base name }
  InResponseTo: STRING[40];  { reason FOR reply           }

  LastDIRFileName: Str12;          { last filename FOR recno/nrecno    }

  CurrentColor,            { current ANSI color          }
  ExiterrorLevel,            { errorLEVEL TO Exit WITH        }
  TShuttleLogon,      { type OF special Shuttle Logon command }
  TFilePrompt,       { type OF special FILE Prompt command  }
  TReadPrompt,       { type OF special Read Prompt command  }

  PublicPostsToday,          { posts made by User this call     }
  FeedBackPostsToday,        { feedback sent by User this call    }
  PrivatePostsToday: Byte;   { E-mail sent by User this call     }

  LastDIRRecNum,             { last record # FOR recno/nrecno    }
  ChatAttempts,            { number chat attempts made by User   }
  LIL,             { lines on screen since last PauseScr() }

  PublicReadThisCall,        { # public messages has Read this call }

  UserNum: Integer;       { User's User number                    }

  Rate: Word;          { cps FOR FILE transfers }

  NewFileDate,                      { NewScan Pointer date         }

  DownloadsToday,                       { download sent TO User this call       }
  UploadsToday,                       { uploads sent by User this call        }
  DownloadKBytesToday,                      { download k by User this call          }
  UploadKBytesToday,              { upload k by User this call            }

  CreditsLastUpdated,   { Time Credits last updated }
  TimeOn,      { time User logged on          }
  LastBeep,
  LastKeyHit,
  ChopTime,           { time TO chop off FOR system events  }
  ExtraTime,          { extra time - given by F7/F8, etc   }
  CreditTime,          { credit time adjustment }
  FreeTime: LongInt;       { free time               }

  BlankMenuNow,         { is the wfcmenu blanked out? }
  Abort,
  Next,      { global Abort AND Next }
  RQArea,
  FQArea,
  MQArea,
  VQArea: Boolean;

{$IFDEF WIN32}
procedure Sound(hz: Word; duration: Word);
function Ticks: LongInt;
{$ENDIF}
FUNCTION GetC(c: Byte): STRING;
PROCEDURE ShowColors;
FUNCTION CheckDriveSpace(S,Path: AStr; MinSpace: Integer): Boolean;
FUNCTION StripLeadSpace(S: STRING): STRING;
FUNCTION StripTrailSpace(S: STRING): STRING;
FUNCTION SemiCmd(S: AStr; B: Byte): STRING;
FUNCTION ExistDrive(Drive: Char): Boolean;
PROCEDURE RenameFile(DisplayStr: AStr; OldFileName,NewFileName: AStr; VAR ReNameOk: Boolean);
FUNCTION GetFileSize(FileName: AStr): LongInt;
PROCEDURE GetFileDateTime(CONST FileName: AStr; VAR FileTime: LongInt);
PROCEDURE SetFileDateTime(CONST FileName: AStr; FileTime: LongInt);
FUNCTION PHours(CONST DisplayStr: AStr; LoTime,HiTime: Integer): AStr;
FUNCTION RGSysCfgStr(StrNum: LongInt; PassValue: Boolean): AStr;
FUNCTION RGNoteStr(StrNum: LongInt; PassValue: Boolean): AStr;
FUNCTION RGMainStr(StrNum: LongInt; PassValue: Boolean): AStr;
FUNCTION lRGLNGStr(StrNum: LongInt; PassValue: Boolean): AStr;
PROCEDURE GetPassword(VAR PW: AStr; Len: Byte);
PROCEDURE MakeDir(VAR Path: PathStr; AskMakeDir: Boolean);
PROCEDURE Messages(Msg,MaxRecs: Integer; AreaName: AStr);
PROCEDURE DisplayBuffer(MCIFunction: MCIFunctionType; Data1, Data2:Pointer);
FUNCTION ReadBuffer(FileName: AStr): Boolean;
FUNCTION chinkey: Char;
FUNCTION FormatNumber(L: LongInt): STRING;
FUNCTION ConvertBytes(BytesToConvert: LongInt; OneChar: Boolean): STRING;
FUNCTION ConvertKB(KBToConvert: LongInt; OneChar: Boolean): STRING;
PROCEDURE WriteWFC(c: Char);
FUNCTION AccountBalance: LongInt;
PROCEDURE AdjustBalance(Adjustment: LongInt);
PROCEDURE BackErase(Len: Byte);
FUNCTION UpdateCRC32(CRC: LongInt; VAR Buffer; Len: Word): LongInt;
FUNCTION CRC32(s: AStr): LongInt;
FUNCTION FunctionalMCI(CONST s: AStr; FileName,InternalFileName: AStr): STRING;
FUNCTION MCI(CONST s: STRING): STRING;
FUNCTION Plural(InString: STRING; Number: Byte): STRING;
FUNCTION FormattedTime(TimeUsed: LongInt): STRING;
FUNCTION SearchUser(Uname: Str36; RealNameOK: Boolean): Integer;
PROCEDURE PauseScr(IsCont: Boolean);
PROCEDURE Com_Send_Str(CONST InString: AStr);
PROCEDURE dophoneHangup(ShowIt: Boolean);
PROCEDURE DoTelnetHangUp(ShowIt: Boolean);
PROCEDURE DoPhoneOffHook(ShowIt: Boolean);
PROCEDURE InputPath(CONST DisplayStr: AStr; VAR DirPath: Str40; CreateDir,AllowExit: Boolean; VAR Changed: Boolean);
FUNCTION StripName(InString: STRING): STRING;
PROCEDURE PurgeDir(s: AStr; SubDirs: Boolean);
PROCEDURE DOSANSI(CONST c: Char);
FUNCTION HiMsg: Word;
FUNCTION OnNode(UserNumber: Integer): Byte;
FUNCTION MaxUsers: Integer;
PROCEDURE Kill(CONST FileName: AStr);
PROCEDURE ScreenDump(CONST FileName: AStr);
PROCEDURE ScanInput(VAR s: AStr; CONST Allowed: AStr);
PROCEDURE Com_Flush_Recv;
PROCEDURE Com_Flush_Send;
PROCEDURE Com_Purge_Send;
FUNCTION Com_Carrier: Boolean;
FUNCTION Com_Recv: Char;
FUNCTION Com_IsRecv_Empty: Boolean;
FUNCTION Com_IsSend_Empty: Boolean;
PROCEDURE Com_Send(c: Char);
PROCEDURE Com_Set_Speed(Speed: LongInt);
PROCEDURE Com_DeInstall;
PROCEDURE Com_Install;
PROCEDURE CheckHangup;
PROCEDURE SerialOut(s: STRING);
FUNCTION Empty:Boolean;
PROCEDURE DTR(Status: Boolean);
PROCEDURE BackSpace;
PROCEDURE DoBackSpace(Start,Finish: Byte);
FUNCTION LennMCI(CONST InString: STRING): Integer;
FUNCTION MsgSysOp: Boolean;
FUNCTION FileSysOp: Boolean;
FUNCTION CoSysOp: Boolean;
FUNCTION SysOp: Boolean;
FUNCTION Timer: LongInt;
PROCEDURE TeleConfCheck;
FUNCTION Substitute(Src: STRING; CONST old,New: STRING): STRING;
PROCEDURE NewCompTables;
FUNCTION OkANSI: Boolean;
FUNCTION OkAvatar: Boolean;
FUNCTION OkRIP: Boolean;
FUNCTION OkVT100: Boolean;
FUNCTION NSL: LongInt;
FUNCTION AgeUser(CONST BirthDate: LongInt): Word;
FUNCTION AllCaps(Instring: STRING): STRING;
FUNCTION Caps(Instring: STRING): STRING;
PROCEDURE Update_Screen;
FUNCTION PageLength: Word;
PROCEDURE lStatus_Screen(WhichScreen: Byte; Message: AStr; OneKey: Boolean; VAR Answer: AStr);
FUNCTION CInKey: Char;
FUNCTION CheckPW: Boolean;
FUNCTION StripColor(CONST InString: STRING): STRING;
PROCEDURE sl1(s: AStr);
PROCEDURE SysOpLog(s: AStr);
FUNCTION StrToInt(S: Str11): LongInt;
FUNCTION RealToStr(R: Real; W,D: Byte): STRING;
FUNCTION ValueR(S: AStr): REAL;
PROCEDURE ShellDos(MakeBatch: Boolean; CONST Command: AStr; VAR ResultCode: Integer);
PROCEDURE SysOpShell;
PROCEDURE RedrawForANSI;
PROCEDURE Star(InString: AStr);
FUNCTION GetKey: Word;
PROCEDURE SetC(C: Byte);
PROCEDURE UserColor(Color: Byte);
PROCEDURE Prompt(CONST InString: STRING);
FUNCTION SQOutSp(InString: STRING): STRING;
FUNCTION ExtractDriveNumber(s: AStr): Byte;
FUNCTION PadLeftStr(InString: STRING; MaxLen: Byte): STRING;
FUNCTION PadRightStr(InString: STRING; MaxLen: Byte): STRING;
FUNCTION PadLeftInt(L: LongInt; MaxLen: Byte): STRING;
FUNCTION PadRightInt(L: LongInt; MaxLen: Byte): STRING;
PROCEDURE Print(CONST InString: STRING);
PROCEDURE NL;
PROCEDURE Prt(CONST Instring: STRING);
PROCEDURE MPL(MaxLen: Byte);
FUNCTION CTP(t,b: LongInt): STRING;
PROCEDURE TLeft;
PROCEDURE LoadNode(NodeNumber: Byte);
PROCEDURE Update_Node(NActivityDesc: AStr; SaveVars: Boolean);
FUNCTION MaxNodes: Byte;
FUNCTION MaxChatRec: LongInt;
PROCEDURE SaveNode(NodeNumber: Byte);
PROCEDURE LoadURec(VAR User: UserRecordType; UserNumber: Integer);
PROCEDURE SaveURec(User: UserRecordType; UserNumber:Integer);
FUNCTION MaxIDXRec: Integer;
FUNCTION InKey: Word;
PROCEDURE OutKey(c: Char);
PROCEDURE CLS;
PROCEDURE Wait(b: Boolean);
FUNCTION DisplayARFlags(AR: ARFlagSet; C1,C2: Char): AStr;
PROCEDURE ToggleARFlag(Flag: Char; VAR AR: ARFlagSet; VAR Changed: Boolean);
FUNCTION DisplayACFlags(Flags: FlagSet; C1,C2: Char): AStr;
PROCEDURE ToggleACFlag(Flag: FlagType; VAR Flags: FlagSet);
PROCEDURE ToggleACFlags(Flag: Char; VAR Flags: FlagSet; VAR Changed: Boolean);
PROCEDURE ToggleStatusFlag(Flag: StatusFlagType; VAR SUFlags: StatusFlagSet);
PROCEDURE ToggleStatusFlags(Flag: Char; VAR SUFlags: StatusFlagSet);
FUNCTION TACCH(Flag: Char): FlagType;
PROCEDURE LCmds(Len,c: Byte; c1,c2: AStr);
PROCEDURE LCmds3(Len,c: Byte; c1,c2,c3: AStr);
PROCEDURE InitTrapFile;
FUNCTION AOnOff(b: Boolean; CONST s1,s2: AStr): STRING;
FUNCTION ShowOnOff(b: Boolean): STRING;
FUNCTION ShowYesNo(b: Boolean): STRING;
FUNCTION YN(Len: Byte; DYNY: Boolean): Boolean;
FUNCTION PYNQ(CONST InString: AStr; MaxLen: Byte; DYNY: Boolean): Boolean;
PROCEDURE InputLongIntWC(S: AStr; VAR L: LongInt; InputFlags: InputFlagSet; LowNum,HighNum: LongInt; VAR Changed: Boolean);
PROCEDURE InputLongIntWOC(S: AStr; VAR L: LongInt; InputFlags: InputFlagSet; LowNum,HighNum: LongInt);
PROCEDURE InputWordWC(S: AStr; VAR W: SmallWord; InputFlags: InputFlagSet; LowNum,HighNum: Word; VAR Changed: Boolean);
PROCEDURE InputWordWOC(S: AStr; VAR W: SmallWord; InputFlags: InputFlagSet; LowNum,HighNum: Word);
PROCEDURE InputIntegerWC(S: AStr; VAR I: SmallInt; InputFlags: InputFlagSet; LowNum,HighNum: Integer; VAR Changed: Boolean);
PROCEDURE InputIntegerWOC(S: AStr; VAR I: SmallInt; InputFlags: InputFlagSet; LowNum,HighNum: Integer);
PROCEDURE InputByteWC(S: AStr; VAR B: Byte; InputFlags: InputFlagSet; LowNum,HighNum: Byte; VAR Changed: Boolean);
PROCEDURE InputByteWOC(S: AStr; VAR B: Byte; InputFlags: InputFlagSet; LowNum,HighNum: Byte);
PROCEDURE InputDefault(VAR S: STRING; v: STRING; MaxLen: Byte; InputFlags: InputFlagSet; LineFeed: Boolean);
PROCEDURE InputFormatted(DisplayStr: AStr; VAR InputStr: STRING; v: STRING; Abortable: Boolean);
PROCEDURE InputWN1(DisplayStr: AStr; VAR InputStr: AStr; MaxLen: Byte; InputFlags: InputFlagSet; VAR Changed: Boolean);
PROCEDURE InputWNWC(DisplayStr: AStr; VAR InputStr: AStr; MaxLen: Byte; VAR Changed: Boolean);
PROCEDURE InputMain(VAR s: STRING; MaxLen: Byte; InputFlags: InputFlagSet);
PROCEDURE InputWC(VAR s: STRING; MaxLen: Byte);
PROCEDURE Input(VAR s: STRING; MaxLen: Byte);
PROCEDURE InputL(VAR s: STRING; MaxLen: Byte);
PROCEDURE InputCaps(VAR s: STRING; MaxLen: Byte);
PROCEDURE OneK(VAR C: Char; ValidKeys: AStr; DisplayKey,LineFeed: Boolean);
PROCEDURE OneK1(VAR C: Char; ValidKeys: AStr; DisplayKey,LineFeed: Boolean);
PROCEDURE LOneK(DisplayStr: AStr; VAR C: Char; ValidKeys: AStr; DisplayKey,LineFeed: Boolean);
PROCEDURE Local_Input1(VAR S: STRING; MaxLen: Byte; LowerCase: Boolean);
PROCEDURE Local_Input(VAR S: STRING; MaxLen: Byte);
PROCEDURE Local_InputL(VAR S: STRING; MaxLen: Byte);
PROCEDURE Local_OneK(VAR C: Char; S: STRING);
FUNCTION Centre(InString: AStr): STRING;
PROCEDURE WKey;
PROCEDURE PrintMain(CONST ss: STRING);
PROCEDURE PrintACR(InString: STRING);
PROCEDURE SaveGeneral(X: Boolean);
PROCEDURE pfl(FN: AStr);
PROCEDURE PrintFile(FileName: AStr);
FUNCTION BSlash(InString: AStr; b: Boolean): AStr;
FUNCTION Exist(FileName: AStr): Boolean;
FUNCTION ExistDir(Path: PathStr): Boolean;
PROCEDURE PrintF(FileName: AStr);
PROCEDURE SKey1(VAR c: Char);
FUNCTION VerLine(B: Byte): STRING;
FUNCTION AACS1(User: UserRecordType; UNum: Integer; S: ACString): Boolean;
FUNCTION AACS(s: ACString): Boolean;
FUNCTION DiskKBFree(DrivePath: AStr): LongInt;
FUNCTION IntToStr(L: LongInt): STRING;

IMPLEMENTATION

USES
  Common1,
  Common2,
  Common3,
  Common4,
  Events,
  File0,
  File11,
  Mail0,
  MultNode,
{$IFDEF MSDOS}
  SpawnO,
{$ENDIF}
  SysOp12,
  Vote
{$IFDEF WIN32}
  ,VPSysLow
  ,VPUtils
  ,Windows
{$ENDIF}
  ;

{$IFDEF WIN32}
procedure Sound(hz: Word; duration: Word);
begin
  Windows.Beep(hz, duration);
end;

function Ticks: LongInt;
begin
  Ticks := GetTimeMSec div 55;
end;
{$ENDIF}

{$IFDEF MSDOS}
FUNCTION UpdateCRC32(CRC: LongInt; VAR Buffer; Len: Word): LongInt; EXTERNAL;
{$L CRC32.OBJ }
{$ENDIF}
{$IFDEF WIN32}
CONST
  CRC_32_TAB : array[0..255] of LongInt = (
      $00000000, $77073096, $ee0e612c, $990951ba, $076dc419,
      $706af48f, $e963a535, $9e6495a3, $0edb8832, $79dcb8a4,
      $e0d5e91e, $97d2d988, $09b64c2b, $7eb17cbd, $e7b82d07,
      $90bf1d91, $1db71064, $6ab020f2, $f3b97148, $84be41de,
      $1adad47d, $6ddde4eb, $f4d4b551, $83d385c7, $136c9856,
      $646ba8c0, $fd62f97a, $8a65c9ec, $14015c4f, $63066cd9,
      $fa0f3d63, $8d080df5, $3b6e20c8, $4c69105e, $d56041e4,
      $a2677172, $3c03e4d1, $4b04d447, $d20d85fd, $a50ab56b,
      $35b5a8fa, $42b2986c, $dbbbc9d6, $acbcf940, $32d86ce3,
      $45df5c75, $dcd60dcf, $abd13d59, $26d930ac, $51de003a,
      $c8d75180, $bfd06116, $21b4f4b5, $56b3c423, $cfba9599,
      $b8bda50f, $2802b89e, $5f058808, $c60cd9b2, $b10be924,
      $2f6f7c87, $58684c11, $c1611dab, $b6662d3d, $76dc4190,
      $01db7106, $98d220bc, $efd5102a, $71b18589, $06b6b51f,
      $9fbfe4a5, $e8b8d433, $7807c9a2, $0f00f934, $9609a88e,
      $e10e9818, $7f6a0dbb, $086d3d2d, $91646c97, $e6635c01,
      $6b6b51f4, $1c6c6162, $856530d8, $f262004e, $6c0695ed,
      $1b01a57b, $8208f4c1, $f50fc457, $65b0d9c6, $12b7e950,
      $8bbeb8ea, $fcb9887c, $62dd1ddf, $15da2d49, $8cd37cf3,
      $fbd44c65, $4db26158, $3ab551ce, $a3bc0074, $d4bb30e2,
      $4adfa541, $3dd895d7, $a4d1c46d, $d3d6f4fb, $4369e96a,
      $346ed9fc, $ad678846, $da60b8d0, $44042d73, $33031de5,
      $aa0a4c5f, $dd0d7cc9, $5005713c, $270241aa, $be0b1010,
      $c90c2086, $5768b525, $206f85b3, $b966d409, $ce61e49f,
      $5edef90e, $29d9c998, $b0d09822, $c7d7a8b4, $59b33d17,
      $2eb40d81, $b7bd5c3b, $c0ba6cad, $edb88320, $9abfb3b6,
      $03b6e20c, $74b1d29a, $ead54739, $9dd277af, $04db2615,
      $73dc1683, $e3630b12, $94643b84, $0d6d6a3e, $7a6a5aa8,
      $e40ecf0b, $9309ff9d, $0a00ae27, $7d079eb1, $f00f9344,
      $8708a3d2, $1e01f268, $6906c2fe, $f762575d, $806567cb,
      $196c3671, $6e6b06e7, $fed41b76, $89d32be0, $10da7a5a,
      $67dd4acc, $f9b9df6f, $8ebeeff9, $17b7be43, $60b08ed5,
      $d6d6a3e8, $a1d1937e, $38d8c2c4, $4fdff252, $d1bb67f1,
      $a6bc5767, $3fb506dd, $48b2364b, $d80d2bda, $af0a1b4c,
      $36034af6, $41047a60, $df60efc3, $a867df55, $316e8eef,
      $4669be79, $cb61b38c, $bc66831a, $256fd2a0, $5268e236,
      $cc0c7795, $bb0b4703, $220216b9, $5505262f, $c5ba3bbe,
      $b2bd0b28, $2bb45a92, $5cb36a04, $c2d7ffa7, $b5d0cf31,
      $2cd99e8b, $5bdeae1d, $9b64c2b0, $ec63f226, $756aa39c,
      $026d930a, $9c0906a9, $eb0e363f, $72076785, $05005713,
      $95bf4a82, $e2b87a14, $7bb12bae, $0cb61b38, $92d28e9b,
      $e5d5be0d, $7cdcefb7, $0bdbdf21, $86d3d2d4, $f1d4e242,
      $68ddb3f8, $1fda836e, $81be16cd, $f6b9265b, $6fb077e1,
      $18b74777, $88085ae6, $ff0f6a70, $66063bca, $11010b5c,
      $8f659eff, $f862ae69, $616bffd3, $166ccf45, $a00ae278,
      $d70dd2ee, $4e048354, $3903b3c2, $a7672661, $d06016f7,
      $4969474d, $3e6e77db, $aed16a4a, $d9d65adc, $40df0b66,
      $37d83bf0, $a9bcae53, $debb9ec5, $47b2cf7f, $30b5ffe9,
      $bdbdf21c, $cabac28a, $53b39330, $24b4a3a6, $bad03605,
      $cdd70693, $54de5729, $23d967bf, $b3667a2e, $c4614ab8,
      $5d681b02, $2a6f2b94, $b40bbe37, $c30c8ea1, $5a05df1b,
      $2d02ef8d);
FUNCTION UpdateCRC32(CRC: LongInt; VAR Buffer; Len: Word): LongInt;
VAR
  i: Integer;
  Octet: ^Byte;
BEGIN
  Octet := @buffer;
  for i := 1 to Len do
  begin
    CRC := CRC_32_TAB[Byte(Crc XOR LongInt(Octet^))] XOR ((Crc SHR 8) AND $00FFFFFF);
	Inc(Octet);
  end;
  UpdateCRC32 := CRC;
END;
{$ENDIF}

FUNCTION CheckPW: Boolean;
BEGIN
  CheckPW := Common1.CheckPW;
END;

PROCEDURE NewCompTables;
BEGIN
  Common1.NewCompTables;
END;

PROCEDURE Wait(B: Boolean);
BEGIN
  Common1.Wait(B);
END;

PROCEDURE InitTrapFile;
BEGIN
  Common1.InitTrapFile;
END;

PROCEDURE Local_Input1(VAR S: STRING; MaxLen: Byte; LowerCase: Boolean);
BEGIN
  Common1.Local_Input1(S,MaxLen,LowerCase);
END;

PROCEDURE Local_Input(VAR S: STRING; MaxLen: Byte);
BEGIN
  Common1.Local_Input(S,MaxLen);
END;

PROCEDURE Local_InputL(VAR S: STRING; MaxLen: Byte);
BEGIN
  Common1.Local_InputL(S,MaxLen);
END;

PROCEDURE Local_OneK(VAR C: Char; S: STRING);
BEGIN
  Common1.Local_OneK(C,S);
END;

PROCEDURE SysOpShell;
BEGIN
  Common1.SysOpShell;
END;

PROCEDURE RedrawForANSI;
BEGIN
  Common1.RedrawForANSI;
END;

PROCEDURE SKey1(VAR C: Char);
BEGIN
  Common2.SKey1(C);
END;

PROCEDURE SaveGeneral(X: Boolean);
BEGIN
  Common2.SaveGeneral(X);
END;

PROCEDURE Update_Screen;
BEGIN
  Common2.Update_Screen;
END;

PROCEDURE lStatus_Screen(WhichScreen: Byte; Message: AStr; OneKey: Boolean; VAR Answer:AStr);
BEGIN
  Common2.lStatus_Screen(WhichScreen,Message,OneKey,Answer);
END;

PROCEDURE TLeft;
BEGIN
  Common2.TLeft;
END;

PROCEDURE InputLongIntWC(S: AStr; VAR L: LongInt; InputFlags: InputFlagSet; LowNum,HighNum: LongInt; VAR Changed: Boolean);
BEGIN
  Common3.InputLongIntWC(S,L,InputFlags,LowNum,HighNum,Changed);
END;

PROCEDURE InputLongIntWOC(S: AStr; VAR L: LongInt; InputFlags: InputFlagSet; LowNum,HighNum: LongInt);
BEGIN
  Common3.InputLongIntWOC(S,L,InputFlags,LowNum,HighNum);
END;

PROCEDURE InputWordWC(S: AStr; VAR W: SmallWord; InputFlags: InputFlagSet; LowNum,HighNum: Word; VAR Changed: Boolean);
BEGIN
  Common3.InputWordWC(S,W,InputFlags,LowNum,HighNum,Changed);
END;

PROCEDURE InputWordWOC(S: AStr; VAR W: SmallWord; InputFlags: InputFlagSet; LowNum,HighNum: Word);
BEGIN
  Common3.InputWordWOC(S,W,InputFlags,LowNum,HighNum);
END;

PROCEDURE InputIntegerWC(S: AStr; VAR I: SmallInt; InputFlags: InputFlagSet; LowNum,HighNum: Integer; VAR Changed: Boolean);
BEGIN
  Common3.InputIntegerWC(S,I,InputFlags,LowNum,HighNum,Changed);
END;

PROCEDURE InputIntegerWOC(S: AStr; VAR I: SmallInt; InputFlags: InputFlagSet; LowNum,HighNum: Integer);
BEGIN
  Common3.InputIntegerWOC(S,I,Inputflags,LowNum,HighNum);
END;

PROCEDURE InputByteWC(S: AStr; VAR B: Byte; InputFlags: InputFlagSet; LowNum,HighNum: Byte; VAR Changed: Boolean);
BEGIN
  Common3.InputByteWC(S,B,InputFlags,LowNum,HighNum,Changed);
END;

PROCEDURE InputByteWOC(S: AStr; VAR B: Byte; InputFlags: InputFlagSet; LowNum,HighNum: Byte);
BEGIN
  Common3.InputByteWOC(S,B,InputFlags,LowNum,HighNum)
END;

PROCEDURE InputDefault(VAR S: STRING; v: STRING; MaxLen: Byte; InputFlags: InputFlagSet; LineFeed: Boolean);
BEGIN
  Common3.InputDefault(S,v,MaxLen,InputFlags,LineFeed);
END;

PROCEDURE InputFormatted(DisplayStr: AStr; VAR InputStr: STRING; v: STRING; Abortable: Boolean);
BEGIN
  Common3.InputFormatted(DisplayStr,InputStr,v,Abortable);
END;

PROCEDURE InputWN1(DisplayStr: AStr; VAR InputStr: AStr; MaxLen: Byte; InputFlags: InputFlagSet; VAR Changed: Boolean);
BEGIN
  Common3.InputWN1(DisplayStr,InputStr,MaxLen,InputFlags,Changed);
END;

PROCEDURE InputWNWC(DisplayStr: AStr; VAR InputStr: AStr; MaxLen: Byte; VAR Changed: Boolean);
BEGIN
  Common3.InputWNWC(DisplayStr,InputStr,MaxLen,Changed);
END;

PROCEDURE InputMain(VAR s: STRING; MaxLen: Byte; InputFlags: InputFlagSet);
BEGIN
  Common3.InputMain(s,MaxLen,InputFlags);
END;

PROCEDURE InputWC(VAR s: STRING; MaxLen: Byte);
BEGIN
  Common3.InputWC(s,MaxLen);
END;

PROCEDURE Input(VAR s: STRING; MaxLen: Byte);
BEGIN
  Common3.Input(s,MaxLen);
END;

PROCEDURE InputL(VAR s: STRING; MaxLen: Byte);
BEGIN
  Common3.InputL(s,MaxLen);
END;

PROCEDURE InputCaps(VAR s: STRING; MaxLen: Byte);
BEGIN
  Common3.InputCaps(s,MaxLen);
END;

PROCEDURE Com_Flush_Recv;
BEGIN
  Common4.Com_Flush_Recv;
END;

PROCEDURE Com_Flush_Send;
BEGIN
  Common4.Com_Flush_Send;
END;

PROCEDURE Com_Purge_Send;
BEGIN
  Common4.Com_Purge_Send;
END;

FUNCTION Com_Carrier: Boolean;
BEGIN
  Com_Carrier := Common4.Com_Carrier;
END;

FUNCTION Com_Recv: Char;
BEGIN
  Com_Recv := Common4.Com_Recv;
END;

FUNCTION Com_IsRecv_Empty: Boolean;
BEGIN
  Com_IsRecv_Empty := Common4.Com_IsRecv_Empty;
END;

FUNCTION Com_IsSend_Empty: Boolean;
BEGIN
  Com_IsSend_Empty := Common4.Com_IsSend_Empty;
END;

PROCEDURE Com_Send(c: Char);
BEGIN
  Common4.Com_Send(c);
END;

PROCEDURE Com_Set_Speed(Speed: LongInt);
BEGIN
  Common4.Com_Set_Speed(Speed);
END;

PROCEDURE Com_DeInstall;
BEGIN
  Common4.Com_DeInstall;
END;

PROCEDURE Com_Install;
BEGIN
  Common4.Com_Install;
END;

PROCEDURE CheckHangup;
BEGIN
  Common4.checkhangup;
END;

PROCEDURE SerialOut(s: STRING);
BEGIN
  Common4.SerialOut(s);
END;

FUNCTION Empty: Boolean; BEGIN
  Empty := Common4.Empty;
END;

PROCEDURE DTR(Status: Boolean);
BEGIN
  Common4.DTR(Status);
END;

PROCEDURE ShowColors;
VAR
  Counter: Byte;
BEGIN
  FOR Counter := 1 TO 10 DO
  BEGIN
    SetC(Scheme.Color[Counter]);
    Prompt(IntToStr(Counter - 1));
    SetC(7);
    Prompt(' ');
  END;
  NL;
END;

FUNCTION CheckDriveSpace(S,Path: AStr; MinSpace: Integer): Boolean;
VAR
  Drive: Char;
  MinSpaceOk: Boolean;
BEGIN
  MinSpaceOk := TRUE;
  IF (DiskKBFree(Path) <= MinSpace) THEN
  BEGIN
    NL;
    Star('Insufficient disk space.');
    Drive := Chr(ExtractDriveNumber(Path) + 64);
    IF (Drive = '@') THEN
      SysOpLog('^8--->^3 '+S+' failure: Main BBS drive full.')
    ELSE
      SysOpLog('^8--->^3 '+S+' failure: '+Drive+' Drive full.');
    MinSpaceOk := FALSE;
  END;
  CheckDriveSpace := MinSpaceOk;
END;


FUNCTION StripLeadSpace(S: STRING): STRING;
BEGIN
  WHILE (S[1] = ' ') DO
    Delete(S,1,1);
  StripLeadSpace := S;
END;

FUNCTION StripTrailSpace(S: STRING): STRING;
BEGIN
  WHILE (S[1] = ' ') DO
    Delete(S,1,1);
  StripTrailSpace := S;
END;

FUNCTION SemiCmd(S: AStr; B: Byte): STRING;
VAR
  i,
  p: Byte;
BEGIN
  i := 1;
  WHILE (i < B) AND (s <> '') DO
  BEGIN
    p := Pos(';',s);
    IF (p <> 0) THEN
      s := Copy(s,(p + 1),(Length(s) - p))
    ELSE
      s := '';
    Inc(i);
  END;
  WHILE (Pos(';',s) <> 0) DO
    s := Copy(s,1,(Pos(';',s) - 1));
  SemiCmd := s;
END;

FUNCTION ExistDrive(Drive: Char): Boolean;
VAR
  Found: Boolean;
BEGIN
  ChDir(Drive+':');
  IF (IOResult <> 0) THEN
    Found := FALSE
  ELSE
  BEGIN
    ChDir(StartDir);
    Found := TRUE;
  END;
  ExistDrive := Found;
END;

PROCEDURE RenameFile(DisplayStr: AStr; OldFileName,NewFileName: AStr; VAR RenameOk: Boolean);
VAR
  F: FILE;
BEGIN
  Print(DisplayStr);
  IF (NOT Exist(OldFileName)) THEN
  BEGIN
    NL;
    Print('"'+OldFileName+'" does not exist, can not rename file.');
    ReNameOk := FALSE;
  END
  ELSE IF (Exist(NewFileName)) THEN
  BEGIN
    NL;
    Print('"'+NewFileName+'" exists, file can not be renamed to "'+OldFileName+'".');
    ReNameOk := FALSE;
  END
  ELSE
  BEGIN
    Assign(F,OldFileName);
    ReName(F,NewFileName);
    LastError := IOResult;
    IF (LastError <> 0) THEN
    BEGIN
      NL;
      Print('Error renaming file '+OldFileName+'.');
      ReNameOK := FALSE;
    END;
  END;
END;

FUNCTION GetFileSize(FileName: AStr): LongInt;
VAR
  DirInfo1: SearchRec;
  FSize: LongInt;
BEGIN
  FindFirst(FileName,AnyFile - Directory - VolumeID - DOS.Hidden - SysFile,DirInfo1);
  IF (DosError <> 0) THEN
    FSize := -1
  ELSE
    FSize := DirInfo1.Size;
  GetFileSize := FSize;
END;

PROCEDURE GetFileDateTime(CONST FileName: AStr; VAR FileTime: LongInt);
VAR
  F: FILE;
BEGIN
  FileTime := 0;
  IF Exist(SQOutSp(FileName)) THEN
  BEGIN
    Assign(F,SQOutSp(FileName));
    Reset(F);
    GetFTime(F,FileTime);
    Close(F);
    LastError := IOResult;
  END;
END;

PROCEDURE SetFileDateTime(CONST FileName: AStr; FileTime: LongInt);
VAR
  F: FILE;
BEGIN
  IF Exist(SQOutSp(FileName)) THEN
  BEGIN
    Assign(F,SQOutSp(FileName));
    Reset(F);
    SetFTime(F,FileTime);
    Close(F);
    LastError := IOResult;
  END;
END;

FUNCTION PHours(CONST DisplayStr: AStr; LoTime,HiTime: Integer): AStr;
BEGIN
  IF (LoTime <> HiTime) THEN
    PHours := ZeroPad(IntToStr(LoTime DIV 60))+':'+ZeroPad(IntToStr(LoTime MOD 60))+'....'+
              ZeroPad(IntToStr(HiTime DIV 60))+':'+ZeroPad(IntToStr(HiTime MOD 60))
  ELSE
    PHours := DisplayStr;
END;

FUNCTION RGSysCfgStr(StrNum: LongInt; PassValue: Boolean): AStr;
VAR
  StrPointerFile: FILE OF StrPointerRec;
  StrPointer: StrPointerRec;
  RGStrFile: FILE;
  S: STRING;
  TotLoad: LongInt;
BEGIN
  Assign(StrPointerFile,General.LMultPath+'RGSCFGPR.DAT');
  Reset(StrPointerFile);
  Seek(StrPointerFile,StrNum);
  Read(StrPointerFile,StrPointer);
  Close(StrPointerFile);
  LastError := IOResult;
  TotLoad := 0;
  Assign(RGStrFile,General.LMultPath+'RGSCFGTX.DAT');
  Reset(RGStrFile,1);
  Seek(RGStrFile,(StrPointer.Pointer - 1));
  REPEAT
    BlockRead(RGStrFile,S[0],1);
    BlockRead(RGStrFile,S[1],Ord(S[0]));
    Inc(TotLoad,(Length(S) + 1));
    IF (PassValue) THEN
    BEGIN
      IF (S[Length(s)] = '@') THEN
        Dec(S[0]);
    END
    ELSE
    BEGIN
      IF (S[Length(S)] = '@') THEN
      BEGIN
        Dec(S[0]);
        Prt(S);
      END
      ELSE
        PrintACR(S);
    END;
  UNTIL (TotLoad >= StrPointer.TextSize) OR (Abort) OR (HangUp);
  Close(RGStrFile);
  LastError := IOResult;
  RGSysCfgStr := S;
END;

FUNCTION RGNoteStr(StrNum: LongInt; PassValue: Boolean): AStr;
VAR
  StrPointerFile: FILE OF StrPointerRec;
  StrPointer: StrPointerRec;
  RGStrFile: FILE;
  S: STRING;
  TotLoad: LongInt;
BEGIN
  Assign(StrPointerFile,General.LMultPath+'RGNOTEPR.DAT');
  Reset(StrPointerFile);
  Seek(StrPointerFile,StrNum);
  Read(StrPointerFile,StrPointer);
  Close(StrPointerFile);
  LastError := IOResult;
  TotLoad := 0;
  Assign(RGStrFile,General.LMultPath+'RGNOTETX.DAT');
  Reset(RGStrFile,1);
  Seek(RGStrFile,(StrPointer.Pointer - 1));
  REPEAT
    BlockRead(RGStrFile,S[0],1);
    BlockRead(RGStrFile,S[1],Ord(S[0]));
    Inc(TotLoad,(Length(S) + 1));
    IF (PassValue) THEN
    BEGIN
      IF (S[Length(s)] = '@') THEN
        Dec(S[0]);
    END
    ELSE
    BEGIN
      IF (S[Length(S)] = '@') THEN
      BEGIN
        Dec(S[0]);
        Prt(S);
      END
      ELSE
        PrintACR(S);
    END;
  UNTIL (TotLoad >= StrPointer.TextSize) OR (Abort) OR (HangUp);
  Close(RGStrFile);
  LastError := IOResult;
  RGNoteStr := S;
END;

FUNCTION RGMainStr(StrNum: LongInt; PassValue: Boolean): AStr;
VAR
  StrPointerFile: FILE OF StrPointerRec;
  StrPointer: StrPointerRec;
  RGStrFile: FILE;
  S: STRING;
  TotLoad: LongInt;
BEGIN
  Assign(StrPointerFile,General.LMultPath+'RGMAINPR.DAT');
  Reset(StrPointerFile);
  Seek(StrPointerFile,StrNum);
  Read(StrPointerFile,StrPointer);
  Close(StrPointerFile);
  LastError := IOResult;
  TotLoad := 0;
  Assign(RGStrFile,General.LMultPath+'RGMAINTX.DAT');
  Reset(RGStrFile,1);
  Seek(RGStrFile,(StrPointer.Pointer - 1));
  REPEAT
    BlockRead(RGStrFile,S[0],1);
    BlockRead(RGStrFile,S[1],Ord(S[0]));
    Inc(TotLoad,(Length(S) + 1));
    IF (PassValue) THEN
    BEGIN
      IF (S[Length(s)] = '@') THEN
        Dec(S[0]);
    END
    ELSE
    BEGIN
      IF (S[Length(S)] = '@') THEN
      BEGIN
        Dec(S[0]);
        Prt(S);
      END
      ELSE
        PrintACR(S);
    END;
  UNTIL (TotLoad >= StrPointer.TextSize) OR (Abort) OR (HangUp);
  Close(RGStrFile);
  LastError := IOResult;
  RGMainStr := S;
END;

FUNCTION lRGLngStr(StrNum: LongInt; PassValue: Boolean): AStr;
VAR
  StrPointerFile: FILE OF StrPointerRec;
  StrPointer: StrPointerRec;
  RGStrFile: FILE;
  S: STRING;
  TotLoad: LongInt;
BEGIN
  Assign(StrPointerFile,General.LMultPath+'RGLNGPR.DAT');
  Reset(StrPointerFile);
  Seek(StrPointerFile,StrNum);
  Read(StrPointerFile,StrPointer);
  Close(StrPointerFile);
  LastError := IOResult;
  TotLoad := 0;
  Assign(RGStrFile,General.LMultPath+'RGLNGTX.DAT');
  Reset(RGStrFile,1);
  Seek(RGStrFile,(StrPointer.Pointer - 1));
  REPEAT
    BlockRead(RGStrFile,S[0],1);
    BlockRead(RGStrFile,S[1],Ord(S[0]));
    Inc(TotLoad,(Length(S) + 1));
    IF (PassValue) THEN
    BEGIN
      IF (S[Length(s)] = '@') THEN
        Dec(S[0]);
    END
    ELSE
    BEGIN
      IF (S[Length(S)] = '@') THEN
      BEGIN
        Dec(S[0]);
        Prt(S);
      END
      ELSE
        PrintACR(S);
    END;
  UNTIL (TotLoad >= StrPointer.TextSize) OR (Abort) OR (HangUp);
  Close(RGStrFile);
  LastError := IOResult;
  lRGLNGStr := S;
END;

PROCEDURE GetPassword(VAR PW: AStr; Len: Byte);
BEGIN
  PW := '';
  Echo := FALSE;
  Input(PW,Len);
  Echo := TRUE;
END;

PROCEDURE MakeDir(VAR Path: PathStr; AskMakeDir: Boolean);
VAR
  CurDir: PathStr;
  Counter: Byte;
BEGIN
  IF (Path = '') THEN
  BEGIN
    NL;
    Print('^7A valid path must be specified!^1');
  END
  ELSE IF (NOT (Path[1] IN ['A'..'Z'])) OR (Length(Path) < 3) OR
     (NOT (Path[2] = ':')) OR (NOT (Path[3] = '\')) THEN
  BEGIN
    NL;
    Print('^7Invalid drive specification: "'+Path+'"^1');
  END
  ELSE
  BEGIN
    GetDir(0,CurDir);
    ChDir(Path[1]+':');
    IF (IOResult <> 0) THEN
    BEGIN
      NL;
      Print('^7Drive does not exist: "'+Path[1]+'"^1');
    END
    ELSE
      ChDir(CurDir);
  END;

  Path := BSlash(Path,TRUE);
  IF (Length(Path) > 3) AND (NOT ExistDir(Path)) THEN
  BEGIN
    NL;
    IF (NOT AskMakeDir) OR PYNQ('Directory does not exist, create it? ',0,FALSE) THEN
    BEGIN
      Counter := 2;
      WHILE (Counter <= Length(Path)) DO
      BEGIN
        IF (Path[Counter] = '\') THEN
        BEGIN
          IF (Path[Counter - 1] <> ':') THEN
          BEGIN
            IF (NOT ExistDir(Copy(Path,1,(Counter - 1)))) THEN
            BEGIN
              MkDir(Copy(Path,1,(Counter - 1)));
              LastError := IOResult;
              IF (LastError <> 0) THEN
              BEGIN
                NL;
                Print('^7Error creating directory!^1');
                SysOpLog('^7Error creating directory: '+Copy(Path,1,(Counter - 1)));
                PauseScr(FALSE);
              END;
            END;
          END;
        END;
        Inc(Counter);
      END;
    END;
  END;

END;

PROCEDURE Messages(Msg,MaxRecs: Integer; AreaName: AStr);
VAR
  MsgStr: AStr;
BEGIN
  MsgStr := '';
  NL;
  CASE Msg OF
     1 : MsgStr := '^7Invalid record number!^1';
     2 : MsgStr := '^7You are at the first valid record!^1';
     3 : MsgStr := '^7You are at the last valid record!^1';
     4 : MsgStr := '^7No '+AreaName+' exist!^1';
     5 : MsgStr := '^7No more then '+IntToStr(MaxRecs)+' '+AreaName+' can exist!^1';
     6 : MsgStr := '^7No '+AreaName+' to position!^1';
     7 : MsgStr := '^7Invalid drive!^1';
     8 : MsgStr := '^7Invalid record number order!^1';
  END;
  PrintACR('^1'+MsgStr);
  PauseScr(FALSE);
END;


FUNCTION ReadBuffer(FileName: AStr): Boolean;
VAR
  BufferFile: FILE;
  MCIBufferSize,
  NumRead: Integer;
BEGIN
  IF (MCIBuffer = NIL) THEN
    New(MCIBuffer);

  ReadBuffer := FALSE;

  IF ((Pos('\',FileName) = 0) AND (Pos(':', FileName) = 0)) THEN
    FileName := General.MiscPath+FileName;

  IF (Pos('.',FileName) = 0) THEN
  BEGIN
    IF (OkRIP) AND Exist(FileName+'.RIP') THEN
      FileName := FileName+'.RIP'
    ELSE IF (OkAvatar) AND Exist(FileName+'.AVT') THEN
      FileName := FileName+'.AVT'
    ELSE IF (OkANSI) AND Exist(FileName+'.ANS') THEN
      FileName := FileName+'.ANS'
    ELSE IF (Exist(FileName+'.ASC')) THEN
      FileName := FileName+'.ASC';
  END;

  IF (NOT Exist(FileName)) THEN
    Exit;

  Assign(BufferFile,FileName);
  Reset(BufferFile,1);

  IF (IOResult <> 0) THEN
    Exit;

  IF (FileSize(BufferFile) < MaxConfigurable) THEN
    MCIBufferSize := FileSize(BufferFile)
  ELSE
    MCIBufferSize := MaxConfigurable;

  FillChar(MCIBuffer^,SizeOf(MCIBuffer^),0);

  BlockRead(BufferFile,MCIBuffer^,MCIBufferSize,NumRead);

  IF (NumRead <> MCIBufferSize) THEN
    Exit;

  Close(BufferFile);
  ReadBuffer := TRUE;
END;

PROCEDURE DisplayBuffer(MCIFunction: MCIFunctionType; Data1,Data2: Pointer);
VAR
  TempStr: STRING;
  cs: AStr;
  Justify: Byte;  {0=Right, 1=Left, 2=Center}
  Counter,
  X2: Integer;
BEGIN
  Counter := 1;
  WHILE (Counter <= MaxConfigurable) AND (MCIBuffer^[Counter] <> #0) DO
  BEGIN
    TempStr := '';
    WHILE (Counter <= MaxConfigurable) AND (MCIBuffer^[Counter] <> #13) DO
      IF (MCIBuffer^[Counter] = '~') AND (Counter + 2 <= MaxConfigurable) THEN
      BEGIN
        cs := MCIFunction(MCIBuffer^[Counter + 1] + MCIBuffer^[Counter + 2],Data1,Data2);
        IF (cs = MCIBuffer^[Counter + 1] + MCIBuffer^[Counter + 2]) THEN
        BEGIN
          TempStr := TempStr + '~';
          Inc(Counter);
          Continue;
        END;
        Inc(Counter,3);
        IF ((Counter + 1) <= MaxConfigurable) AND (MCIBuffer^[Counter] IN ['#','{','}']) THEN
        BEGIN
          IF (MCIBuffer^[Counter] = '}') THEN
            Justify := 0
          ELSE IF (MCIBuffer^[Counter] = '{') THEN
            Justify := 1
          ELSE
            Justify := 2;
          IF (MCIBuffer^[Counter + 1] IN ['0'..'9']) THEN
          BEGIN
            X2 := Ord(MCIBuffer^[Counter + 1]) - 48;
            Inc(Counter, 2);
            IF (MCIBuffer^[Counter] IN ['0'..'9']) THEN
            BEGIN
              X2 := X2 * 10 + Ord(MCIBuffer^[Counter]) - 48;
              Inc(Counter,1);
            END;
            IF (X2 > 0) THEN
              CASE Justify OF
                0 : cs := PadRightStr(cs,X2);
                1 : cs := PadLeftStr(cs,X2);
                2 : WHILE (Length(cs) < X2) DO
                    BEGIN
                      cs := ' ' + cs;
                      IF (Length(cs) < X2) THEN
                        cs := cs + ' ';
                    END;
              END;
          END;
        END;
        IF ((Length(cs) + Length(TempStr)) <= 255) THEN
        BEGIN
          Move(cs[1],TempStr[Length(TempStr)+1],Length(cs));
          Inc(TempStr[0],Length(cs));
        END
        ELSE
          IF (Length(TempStr) < 255) THEN
          BEGIN
            Move(cs[1],TempStr[Length(TempStr) + 1],(255 - Length(TempStr)));
            TempStr[0] := #255;
          END;
      END
      ELSE
      BEGIN
        Inc(TempStr[0]);
        TempStr[Length(TempStr)] := MCIBuffer^[Counter];
        Inc(Counter);
      END;

    IF (Counter <= MaxConfigurable) AND (MCIBuffer^[Counter] = #13) THEN
      Inc(Counter,2);
    CROff := TRUE;
    PrintACR(TempStr);
  END;
END;

FUNCTION Chinkey: Char;
VAR
  C: Char;
BEGIN
  C := #0;
  Chinkey := #0;
  IF (KeyPressed) THEN
  BEGIN
    C := ReadKey;
    IF (NOT WColor) THEN
      UserColor(General.SysOpColor);
    WColor := TRUE;
    IF (C = #0) THEN
      IF (KeyPressed) THEN
      BEGIN
        C := ReadKey;
        SKey1(C);
        IF (C = #31) OR (C = #46) THEN
          C := #1
        ELSE IF (Buf <> '') THEN
        BEGIN
          C := Buf[1];
          Buf := Copy(Buf,2,(Length(Buf) - 1));
        END
        ELSE
          C := #0
      END;
    Chinkey := C;
  END
  ELSE IF ((NOT Com_IsRecv_Empty) AND (InCom)) THEN
  BEGIN
    C := CInKey;
    IF (WColor) THEN
      UserColor(General.UserColor);
    WColor := FALSE;
    Chinkey := C;
  END;
END;

FUNCTION FormatNumber(L: LongInt): STRING;
VAR
  S: STRING;
  StrLen,
  Counter: Byte;
BEGIN
  S := '';
  Str(L,S);
  StrLen := Length(S);
  Counter := 0;
  WHILE (StrLen > 1) DO
  BEGIN
    Inc(Counter);
    IF (Counter = 3) THEN
    BEGIN
      Insert(',',S,StrLen);
      Counter := 0;
    END;
    Dec(StrLen);
  END;
  FormatNumber := S;
END;

FUNCTION ConvertBytes(BytesToConvert: LongInt; OneChar: Boolean): STRING;
CONST
  InByte = 1;
  InKilo = 1024;
  InMega = 1048576;
  InGiga = 1073741824;
VAR
  InSize,
  InMod: LongInt;
  InTypes: Str5;
BEGIN
  InMod := 0;
  InTypes := '';
  IF (BytesToConvert < 0) THEN
    Exit;
  IF (BytesToConvert < InKilo) THEN   {Bytes Convertion}
  BEGIN
    InSize := BytesToConvert;
    InTypes := 'Bytes';
  END
  ELSE IF (BytesToConvert < InMega) THEN  {Kilo Convertion}
  BEGIN
    InSize  := (BytesToConvert DIV InKilo);
    InMod := Trunc(((BytesToConvert Mod InKilo) / InKilo) * 10.0);
    InTypes := 'KB';
  END
  ELSE IF (BytesToConvert < InGiga) THEN {Mega Convertion}
  BEGIN
    InSize  := (BytesToConvert DIV InMega);
    InMod := Trunc(((BytesToConvert Mod InMega) / InMega) * 10.0);
    InTypes := 'MB';
  END
  ELSE IF ((BytesToConvert - 1) > InGiga) THEN  {GigaByte Conversion}
  BEGIN
    InSize := (BytesToConvert DIV InGiga);
    InMod := Trunc(((BytesToConvert Mod InGiga) / InGiga) * 10.0);
    InTypes := 'GB';
  END;
  IF (InMod = 0) THEN
    ConvertBytes := AOnOff(OneChar,IntToStr(InSize),FormatNumber(InSize)+' ')
                    +AOnOff(OneChar,Char(Ord(InTypes[1]) + 32),InTypes)
  ELSE
    ConvertBytes := AOnOff(OneChar,IntToStr(InSize),FormatNumber(InSize))+'.'
                    +AOnOff(OneChar,IntToStr(InMod),IntToStr(InMod)+' ')
                    +AOnOff(OneChar,Char(Ord(InTypes[1]) + 32),InTypes);
END;

FUNCTION ConvertKB(KBToConvert: LongInt; OneChar: Boolean): STRING;
CONST
  InKilo = 1;
  InMega = 1024;
  InGiga = 1048576;
  InTera = 1073741824;
VAR
  InSize,
  InMod: LongInt;
  InTypes: Str5;
BEGIN
  InMod := 0;
  InTypes := '';
  IF (KBToConvert < 0) THEN
    Exit;
  IF (KBToConvert < InMega) THEN  {KILO Convertion}
  BEGIN
    InSize := KBToConvert;
    InTypes := 'KB';
  END
  ELSE IF (KBToConvert < InGiga) THEN  {MEGA Convertion}
  BEGIN
    InSize := (KBToConvert DIV InMega);
    InMod := Trunc(((KBToConvert Mod InMega) / InMega) * 10.0);
    InTypes := 'MB';
  END
  ELSE IF (KBToConvert < InTera) THEN  {Giga Convertion}
  BEGIN
    InSize  := (KBToConvert DIV InGiga);
    InMod := Trunc(((KBToConvert Mod InGiga) / InGiga) * 10.0);
    InTypes := 'GB';
  END
  ELSE IF ((KBToConvert - 1) > InTera) THEN  {TeraByte Conversion}
  BEGIN
    InSize := (KBToConvert DIV InTera);
    InMod := Trunc(((KBToConvert Mod InTera) / InTera) * 10.0);
    InTypes := 'TB';
  END;
  IF (InMod = 0) THEN
    ConvertKB := AOnOff(OneChar,IntToStr(InSize),FormatNumber(InSize)+' ')
                 +AOnOff(OneChar,Char(Ord(InTypes[1]) + 32),InTypes)
  ELSE
    ConvertKB := AOnOff(OneChar,IntToStr(InSize),FormatNumber(InSize))+'.'
                 +AOnOff(OneChar,IntToStr(InMod),IntToStr(InMod)+' ')
                 +AOnOff(OneChar,Char(Ord(InTypes[1]) + 32),InTypes);
END;

PROCEDURE WriteWFC(c: Char);
VAR
  LastAttr: Byte;
BEGIN
  IF (BlankMenuNow) THEN
    Exit;
  Window(23,11,78,15);
  GotoXY(LastWFCX,LastWFCY);
  LastAttr := TextAttr;
  TextAttr := 7;
  Write(c);
  TextAttr := LastAttr;
  LastWFCX := WhereX;
  LastWFCY := WhereY;
  Window(1,1,MaxDisplayCols,MaxDisplayRows);
END;

FUNCTION AccountBalance: LongInt;
BEGIN
  AccountBalance := (ThisUser.lCredit - ThisUser.Debit);
END;

PROCEDURE AdjustBalance(Adjustment: LongInt);
BEGIN
  IF (Adjustment > 0) THEN
    Inc(ThisUser.Debit,Adjustment)   { Add TO debits }
  ELSE
    Dec(ThisUser.lCredit,Adjustment);  { Add TO credits }
END;

FUNCTION CRC32(S: AStr): LongInt;
BEGIN
  CRC32 := NOT (UpdateCRC32($FFFFFFFF,S[1],Length(S)));
END;

PROCEDURE Kill(CONST FileName: AStr);
VAR
  F: FILE;
BEGIN
  Assign(F,FileName);
  Erase(F);
  LastError := IOResult;
END;

PROCEDURE BackSpace;
BEGIN
  IF (OutCom) THEN
    SerialOut(^H' '^H);
  IF (WantOut) THEN
    Write(^H' '^H);
END;

PROCEDURE DoBackSpace(Start,Finish: Byte);
VAR
  Counter: Byte;
BEGIN
  FOR Counter := Start TO Finish DO
  BEGIN
    IF (OutCom) THEN
      SerialOut(^H' '^H);
    IF (WantOut) THEN
      Write(^H' '^H);
  END;
END;

FUNCTION Substitute(Src: STRING; CONST old,New: STRING): STRING;
VAR
  p,
  Diff,
  LastP: Integer;
BEGIN
  IF (old <> New) THEN
  BEGIN
    LastP := 0;
    Diff := Length(New) - Length(old);
    REPEAT
      p := Pos(old,Copy(Src,LastP,255));
      IF (p > 0) THEN
      BEGIN
        IF (Diff <> 0) THEN
        BEGIN
          Move(Src[p + Length(old)],Src[p + Length(New)],(Length(Src) - p));
          Inc(Src[0],Diff);
        END;
        Move(New[1],Src[p],Length(New));
        LastP := p + Length(New);
      END;
    UNTIL (p = 0);
  END;
  Substitute := Src;
END;

PROCEDURE DOSANSI(CONST c:Char);
VAR
   i:Word;
label Command;

BEGIN
  IF (c = #27) AND (NextState IN [Waiting..In_Param]) THEN
  BEGIN
    NextState := Bracket;
    Exit;
  END;

  IF (c = ^V) AND (NextState = Waiting) THEN
  BEGIN
    NextState := GetAvCmd;
    Exit;
  END;

  IF (c = ^y) AND (NextState = Waiting) THEN
  BEGIN
    NextState := GetAvRLE1;
    Exit;
  END;

  CASE NextState OF
    Waiting : IF (c = #9) THEN
      GotoXY((WhereX + 8),WhereY)
    ELSE
      Write(c);
    GetAvRLE1:
    BEGIN
      ParamArr[1] := Ord(c);
      NextState := GetAvRLE2;
    END;
    GetAvRLE2:
    BEGIN
      FOR i := 1 TO Ord(c) DO
        Write(Chr(ParamArr[1]));
      NextState := Waiting;
    END;
    GetAvAttr:
    BEGIN
      TextAttr := Ord(c) AND $7f;
      NextState := Waiting;
    END;
    GetAvY:
    BEGIN
      ParamArr[1] := Ord(c);
      NextState := GetAvX;
    END;
    GetAvX:
    BEGIN
      GotoXY(Ord(c),ParamArr[1]);
      NextState := Waiting;
    END;
    GetAvCmd: CASE c OF
      ^A : NextState := GetAvAttr;
      ^B : BEGIN
            TextAttr := TextAttr OR $80;
            NextState := Waiting;
           END;
      ^C : BEGIN
            GotoXY(WhereX,(WhereY - 1));
            NextState := Waiting;
           END;
      ^d : BEGIN
            GotoXY(WhereX,(WhereY + 1));
            NextState := Waiting;
           END;
      ^E : BEGIN
            GotoXY((WhereX - 1),WhereY);
            NextState := Waiting;
           END;
      ^F :
      BEGIN
        GotoXY((WhereX + 1),WhereY);
        NextState := Waiting;
      END;
      ^G :
      BEGIN
        ClrEOL;
        NextState := Waiting;
      END;
      ^H : NextState := GetAvY;
      ELSE
        NextState := Waiting;
    END;
    Bracket :
    BEGIN
      IF c <> '[' THEN
      BEGIN
        NextState := Waiting;
        Write(c);
      END
      ELSE
      BEGIN
        Params := 1;
        FillChar(ParamArr,5,0);
        NextState := Get_Args;
      END;
    END;
    Get_Args,Get_Param,Eat_Semi :
    BEGIN
      IF (NextState = Eat_Semi) AND (c = ';') THEN
      BEGIN
        IF (Params < 5) THEN
          Inc(Params);
        NextState := Get_Param;
        Exit;
      END;
      CASE c OF
        '0'..'9' :
        BEGIN
          ParamArr[Params] := Ord(c) - 48;
          NextState := In_Param;
        END;
        ';' :
        BEGIN
          IF (Params < 5) THEN
            Inc(Params);
          NextState := Get_Param;
        END;
        ELSE
          goto Command;
      END {CASE c} ;
    END;
    In_Param :         { last Char was a digit }
    BEGIN
      { looking FOR more digits, a semicolon, OR a command Char }
      CASE c OF
        '0'..'9' :
        BEGIN
          ParamArr[Params] := ParamArr[Params] * 10 + Ord(c) - 48;
          NextState := In_Param;
          Exit;
        END;
        ';' :
        BEGIN
          IF (Params < 5) THEN
            Inc(Params);
          NextState := Eat_Semi;
          Exit;
        END;
      END {CASE c} ;
      Command:
        NextState := Waiting;
      CASE c OF
        { Note: the order OF commands is optimized FOR execution speed }
        'm' :                 {sgr}
        BEGIN
          FOR i := 1 TO Params DO
          BEGIN
            IF (Reverse) THEN
              TextAttr := TextAttr SHR 4 + TextAttr SHL 4;
            CASE ParamArr[i] OF
              0 :
              BEGIN
                Reverse := FALSE;
                TextAttr := 7;
              END;
              1 : TextAttr := TextAttr AND $FF OR $08;
              2 : TextAttr := TextAttr AND $F7 OR $00;
              4 : TextAttr := TextAttr AND $F8 OR $01;
              5 : TextAttr := TextAttr OR $80;
              7 : IF NOT Reverse THEN
              BEGIN
                {
                TextAttr := TextAttr SHR 4 + TextAttr SHL 4;
                }
                Reverse := TRUE;
              END;
              22 : TextAttr := TextAttr AND $F7 OR $00;
              24 : TextAttr := TextAttr AND $F8 OR $04;
              25 : TextAttr := TextAttr AND $7F OR $00;
              27 : IF Reverse THEN
              BEGIN
                Reverse := FALSE;
                {
                TextAttr := TextAttr SHR 4 + TextAttr SHL 4;
                }
              END;
              30 : TextAttr := TextAttr AND $F8 OR $00;
              31 : TextAttr := TextAttr AND $F8 OR $04;
              32 : TextAttr := TextAttr AND $F8 OR $02;
              33 : TextAttr := TextAttr AND $F8 OR $06;
              34 : TextAttr := TextAttr AND $F8 OR $01;
              35 : TextAttr := TextAttr AND $F8 OR $05;
              36 : TextAttr := TextAttr AND $F8 OR $03;
              37 : TextAttr := TextAttr AND $F8 OR $07;
              40 : TextAttr := TextAttr AND $8F OR $00;
              41 : TextAttr := TextAttr AND $8F OR $40;
              42 : TextAttr := TextAttr AND $8F OR $20;
              43 : TextAttr := TextAttr AND $8F OR $60;
              44 : TextAttr := TextAttr AND $8F OR $10;
              45 : TextAttr := TextAttr AND $8F OR $50;
              46 : TextAttr := TextAttr AND $8F OR $30;
              47 : TextAttr := TextAttr AND $8F OR $70;
            END {CASE} ;
            { fixup FOR reverse }
            IF (Reverse) THEN
              TextAttr := TextAttr SHR 4 + TextAttr SHL 4;
          END;
        END;
        'A' :                 {cuu}
        BEGIN
          IF (ParamArr[1] = 0) THEN
            ParamArr[1] := 1;
          {IF (WhereY - ParamArr[1] >= 1)
          THEN} GotoXY(WhereX,(WhereY - ParamArr[1]))
          {ELSE GotoXY(WhereX, 1);}
        END;
        'B' :                 {cud}
        BEGIN
          IF ParamArr[1] = 0 THEN ParamArr[1] := 1;
          {IF (WhereY + ParamArr[1] <= Hi(WindMax) - Hi(WindMin) + 1)
          THEN }GotoXY(WhereX, WhereY + ParamArr[1])
          {ELSE GotoXY(WhereX, Hi(WindMax) - Hi(WindMin) + 1);}
        END;
        'C' :                 {cuf}
        BEGIN
          IF ParamArr[1] = 0 THEN ParamArr[1] := 1;
          {IF (WhereX + ParamArr[1] <= Lo(WindMax) - Lo(WindMin) + 1)
          THEN} GotoXY(WhereX + ParamArr[1], WhereY)
          {ELSE GotoXY(Lo(WindMax) - Lo(WindMin) + 1, WhereY);}
        END;
        'D' :                 {cub}
        BEGIN
          IF (ParamArr[1] = 0) THEN ParamArr[1] := 1;
          {IF (WhereX - ParamArr[1] >= 1)
          THEN} GotoXY(WhereX - ParamArr[1], WhereY)
          {ELSE GotoXY(1, WhereY);}
        END;
        'H', 'f' :            {cup,hvp}
        BEGIN
          IF (ParamArr[1] = 0) THEN ParamArr[1] := 1;
          IF (ParamArr[2] = 0) THEN ParamArr[2] := 1;

          {IF (ParamArr[2] > Lo(WindMax) + 1)
          THEN ParamArr[2] := Lo(WindMax) - Lo(WindMin) + 1;
          IF (ParamArr[1] > Hi(WindMax) + 1)
          THEN ParamArr[1] := Hi(WindMax) - Hi(WindMin) + 1;}
          GotoXY(ParamArr[2], ParamArr[1]) ;
        END;
        'J' : IF (ParamArr[1] = 2) THEN ClrScr
        ELSE
          FOR i := WhereY TO 25 DO delline; { some terms use others! }
        'K' : ClrEOL;
        'L' : IF (ParamArr[1] = 0) THEN
          insline
        ELSE
          FOR i := 1 TO ParamArr[1] DO insline; { must NOT Move cursor }
        'M' : IF (ParamArr[1] = 0) THEN
          delline
        ELSE
          FOR i := 1 TO ParamArr[1] DO delline; { must NOT Move cursor }
        'P' :                 {dc }
        BEGIN
        END;
        's' :                 {scp}
        BEGIN
          SaveX := WhereX;
          SaveY := WhereY;
        END;
        'u' : {rcp} GotoXY(SaveX,SaveY);
        '@':; { Some unknown code appears TO DO nothing }
        ELSE
          Write(c);
      END {CASE c} ;
    END;
  END {CASE NextState} ;
END {AnsiWrite} ;

PROCEDURE ShellDos(MakeBatch: Boolean; CONST Command: AStr; VAR ResultCode: Integer);
VAR
  BatFile: Text;
  FName,
  s: AStr;
BEGIN
  IF (NOT MakeBatch) THEN
    FName := Command
  ELSE
  BEGIN
    FName := 'TEMP'+IntToStr(ThisNode)+'.BAT';
    Assign(BatFile,FName);
    ReWrite(BatFile);
    WriteLn(BatFile,Command);
    Close(BatFile);
    LastError := IOResult;
  END;

  IF (FName <> '') THEN
    FName := ' /c '+FName;

  Com_Flush_Send;

  Com_DeInstall;

  CursorOn(TRUE);

  SwapVectors;

{$IFDEF MSDOS}
  IF (General.SwapShell) THEN
  BEGIN
    s := GetEnv('TEMP');
    IF (s = '') THEN
      s := StartDir;
    Init_SpawNo(s,General.SwapTo,20,10);
    ResultCode := Spawn(GetEnv('COMSPEC'),FName,0);
  END;
{$ENDIF}
{$IFDEF WIN32}
  ResultCode := -1;
{$ENDIF}

  IF (NOT General.SwapShell) OR (ResultCode = -1) THEN
  BEGIN
    Exec(GetEnv('COMSPEC'),FName);
    ResultCode := Lo(DOSExitCode);
    LastError := IOResult;
  END;

  SwapVectors;

  IF (MakeBatch) THEN
    Kill(FName);

  Com_Install;

  IF (NOT LocalIOOnly) AND NOT (lockedport IN Liner.mflags) THEN
    Com_Set_Speed(ComPortSpeed);

  Update_Screen;

  TextAttr := CurrentColor;

  LastKeyHit := Timer;
END;

FUNCTION LennMCI(CONST InString: STRING): Integer;
VAR
  TempStr: STRING;
  Counter,
  StrLen: Byte;
BEGIN
  StrLen := Length(InString);
  Counter := 0;
  WHILE (Counter < Length(InString)) DO
  BEGIN
    Inc(Counter);
    CASE InString[Counter] OF
      ^S : BEGIN
             Dec(StrLen,2);
             Inc(Counter);
           END;
     '^' : IF (Length(InString) > Counter) AND (InString[Counter + 1] IN ['0'..'9']) THEN
           BEGIN
             Dec(StrLen,2);
             Inc(Counter);
           END;
     '|' : IF (Length(InString) > (Counter + 1)) AND (InString[Counter + 1] IN ['0'..'9']) AND
              (Instring[Counter + 2] IN ['0'..'9']) THEN
           BEGIN
             Dec(StrLen,3);
             Inc(Counter);
           END;
     '%' : IF (MCIAllowed) AND (Length(InString) > (Counter + 1)) THEN
           BEGIN
             TempStr := AllCaps(MCI('%' + InString[Counter + 1] + InString[Counter + 2]));
             IF (Copy(TempStr,1,3) <> '%' + UpCase(InString[Counter + 1]) + UpCase(InString[Counter + 2])) THEN
               Inc(StrLen,Length(TempStr) - 3);
           END;
    END;
  END;
  LennMCI := StrLen;
END;

{$V-}
PROCEDURE LCmds3(Len,c: Byte; c1,c2,c3: AStr);
VAR
  s: AStr;
BEGIN
  s := '';
  s := s+'^1(^'+Chr(c + Ord('0'))+c1[1]+'^1)'+PadLeftStr(Copy(c1,2,LennMCI(c1)-1),Len-1);
  IF (c2 <> '') THEN
    s := s+'^1(^'+Chr(c + Ord('0')) + c2[1]+'^1)'+PadLeftStr(Copy(c2,2,LennMCI(c2)-1),Len-1);
  IF (c3 <> '') THEN
    s := s+'^1(^'+Chr(c + Ord('0')) + c3[1]+'^1)'+Copy(c3,2,LennMCI(c3)-1);
  PrintACR(s);
END;

PROCEDURE LCmds(Len,c: Byte; c1,c2: AStr);
VAR
  s: AStr;
BEGIN
  s := Copy(c1,2,LennMCI(c1) - 1);
  IF (c2 <> '') THEN
    s := PadLeftStr(s,Len - 1);
  Prompt('^1(^' + IntToStr(c) + c1[1] + '^1)' + s);
  IF (c2 <> '') THEN
    Prompt('^1(^' + IntToStr(c) + c2[1] + '^1)' + Copy(c2,2,LennMCI(c2) - 1));
  NL;
END;

FUNCTION MsgSysOp: Boolean;
BEGIN
  MsgSysOp := (CoSysOp) OR (AACS(General.MSOP)) OR (AACS(MemMsgArea.SysOpACS));
END;

FUNCTION FileSysOp: Boolean;
BEGIN
  FileSysOp := ((CoSysOp) OR (AACS(General.FSOP)));
END;

FUNCTION CoSysOp: Boolean;
BEGIN
  CoSysOp := ((SysOp) OR (AACS(General.CSOP)));
END;

FUNCTION SysOp: Boolean;
BEGIN
  SysOp := (AACS(General.SOP));
END;

FUNCTION Timer: LongInt;
BEGIN
  Timer := ((Ticks * 5) DIV 91);   { 2.5 times faster than Ticks DIV 18.2 }
END;

FUNCTION OkVT100: Boolean;
BEGIN
  OkVT100 := (VT100 IN ThisUser.Flags);
END;

FUNCTION OkANSI: Boolean;
BEGIN
  OkANSI := (ANSI IN ThisUser.Flags);
END;

FUNCTION OkRIP: Boolean;
BEGIN
  OkRIP := (RIP IN ThisUser.SFlags);
END;

FUNCTION OkAvatar: Boolean;
BEGIN
  OkAvatar := (Avatar IN ThisUser.Flags);
END;

FUNCTION NSL: LongInt;
VAR
  BeenOn: LongInt;
BEGIN
  IF ((UserOn) OR (NOT InWFCMenu)) THEN
  BEGIN
    BeenOn := (GetPackDateTime - TimeOn);
    NSL := ((LongInt(ThisUser.TLToday) * 60 + ExtraTime + FreeTime) - (BeenOn + ChopTime + CreditTime));
  END
  ELSE
    NSL := 3600;
END;

FUNCTION StripColor(CONST InString: STRING): STRING;
VAR
  TempStr: STRING;
  Counter: Byte;
BEGIN
  TempStr := '';
  Counter := 0;
  WHILE (Counter < Length(InString)) DO
  BEGIN
    Inc(Counter);
    CASE InString[Counter] OF
      ^S : Inc(Counter);
     '^' : IF (InString[Counter + 1] IN ['0'..'9']) THEN
             Inc(Counter)
           ELSE
             TempStr := TempStr + '^';
     '|' : IF (InString[Counter + 1] IN ['0'..'9']) AND (InString[Counter + 2] IN ['0'..'9']) THEN
             Inc(Counter,2)
           ELSE
             TempStr := TempStr + '|';
     ELSE
       TempStr := TempStr + InString[Counter];
     END;
  END;
  StripColor := TempStr;
END;

PROCEDURE sl1(s: AStr);
BEGIN
  IF (SLogging) THEN
  BEGIN
    S := S + '^1';

    IF (General.StripCLog) THEN
      s := StripColor(s);

    Append(SysOpLogFile);
    IF (IOResult = 0) THEN
    BEGIN
      WriteLn(SysOpLogFile,s);
      Close(SysOpLogFile);
      LastError := IOResult;
    END;

    IF (SLogSeparate IN ThisUser.SFlags) THEN
    BEGIN
      Append(SysOpLogFile1);
      IF (IOResult = 0) THEN
      BEGIN
        WriteLn(SysOpLogFile1,s);
        Close(SysOpLogFile1);
        LastError := IOResult;
      END;
    END;

  END;
END;

PROCEDURE SysOpLog(s:AStr);
BEGIN
  sl1('   '+s);
END;

FUNCTION StrToInt(S: Str11): LongInt;
VAR
  I: Integer;
  L: LongInt;
BEGIN
  Val(S,L,I);
  IF (I > 0) THEN
  BEGIN
    S[0] := Chr(I - 1);
    Val(S,L,I)
  END;
  IF (S = '') THEN
    StrToInt := 0
  ELSE
    StrToInt := L;
END;

FUNCTION RealToStr(R: Real; W,D: Byte): STRING;
VAR
  S: STRING[11];
BEGIN
  Str(R:W:D,S);
  RealToStr := S;
END;

FUNCTION ValueR(S: AStr): REAL;
VAR
  Code: Integer;
  R: REAL;
BEGIN
  Val(S,R,Code);
  IF (Code <> 0) THEN
  BEGIN
    S := Copy(S,1,(Code - 1));
    Val(S,R,Code)
  END;
  ValueR := R;
  IF (S = '') THEN
    ValueR := 0;
END;

FUNCTION AgeUser(CONST BirthDate: LongInt): Word;
VAR
  DT1,
  DT2: DateTime;
  Year: Word;
BEGIN
  PackToDate(DT1,BirthDate);
  GetDateTime(DT2);
  Year := (DT2.Year - DT1.Year);
  IF (DT2.Month < DT1.Month) THEN
    Dec(Year);
  IF (DT2.Month = DT1.Month) AND (DT2.Day < DT1.Day) THEN
    Dec(Year);
  AgeUser := Year;
END;

FUNCTION AllCaps(InString: STRING): STRING;
VAR
  Counter: Byte;
BEGIN
  FOR Counter := 1 TO Length(InString) DO
    IF (InString[Counter] IN ['a'..'z']) THEN
      InString[Counter] := Chr(Ord(InString[Counter]) - Ord('a')+Ord('A'));
  AllCaps := InString;
END;

FUNCTION Caps(Instring: STRING): STRING;
VAR
  Counter: Integer;  { must be Integer }
BEGIN
  IF (InString[1] IN ['a'..'z']) THEN
    Dec(InString[1],32);
  FOR Counter := 2 TO Length(Instring) DO
    IF (InString[Counter - 1] IN ['a'..'z','A'..'Z']) THEN
      IF (InString[Counter] IN ['A'..'Z']) THEN
        Inc(InString[Counter],32)
      ELSE
    ELSE
      IF (InString[Counter] IN ['a'..'z']) THEN
        Dec(InString[Counter],32);
  Caps := InString;
END;

FUNCTION GetC(c: Byte): STRING;
CONST
  xclr: ARRAY [0..7] OF Char = ('0','4','2','6','1','5','3','7');
VAR
  s: STRING[10];
  b: Boolean;

  PROCEDURE adto(ss: str8);
  BEGIN
    IF (s[Length(s)] <> ';') AND (s[Length(s)] <> '[') THEN
      s := s + ';';
    s := s + ss;
    b := TRUE;
  END;

BEGIN
  b := FALSE;
  IF ((CurrentColor AND (NOT c)) AND $88) <> 0 THEN
  BEGIN
    s := #27+'[0';
    CurrentColor := $07;
  END
  ELSE
    s := #27+'[';
  IF (c AND 7 <> CurrentColor AND 7) THEN
    adto('3'+xclr[c AND 7]);
  IF (c AND $70 <> CurrentColor AND $70) THEN
    adto('4'+xclr[(c SHR 4) AND 7]);
  IF (c AND 128 <> 0) THEN
    adto('5');
  IF (c AND 8 <> 0) THEN
    adto('1');
  IF (NOT b) THEN
    adto('3'+xclr[c AND 7]);
  s := s + 'm';
  GetC := s;
END;

PROCEDURE SetC(C: Byte);
BEGIN
  IF (NOT (OkANSI OR OkAvatar)) THEN
  BEGIN
    TextAttr := 7;
    Exit;
  END;
  IF (C <> CurrentColor) THEN
  BEGIN
    IF (NOT (Color IN ThisUser.Flags)) THEN
      IF ((C AND 8) = 8) THEN
        C := 15
      ELSE
        C := 7;
    IF (OutCom) THEN
      IF (OkAvatar) THEN
        SerialOut(^V^A+Chr(C AND $7f))
      ELSE
        SerialOut(GetC(C));
    TextAttr := C;
    CurrentColor := C;
  END;
END;

PROCEDURE UserColor(Color: Byte);
BEGIN
  IF (Color IN [0..9]) THEN
    IF (OkANSI OR OkAvatar) THEN
      SetC(Scheme.Color[Color + 1]);
END;

FUNCTION SQOutSp(InString: STRING): STRING;
BEGIN
  WHILE (Pos(' ',InString) > 0) DO
    Delete(InString,Pos(' ',InString),1);
  SQOutSp := InString;
END;

FUNCTION ExtractDriveNumber(s: AStr): Byte;
BEGIN
  s := FExpand(s);
  ExtractDriveNumber := (Ord(s[1]) - 64);
END;

FUNCTION PadLeftStr(InString: STRING; MaxLen: Byte): STRING;
VAR
  StrLen,
  Counter: Byte;
BEGIN
  StrLen := LennMCI(InString);
  IF (StrLen > MaxLen) THEN
    WHILE (StrLen > MaxLen) DO
    BEGIN
      InString[0] := Chr(MaxLen + (Length(InString) - StrLen));
      StrLen := LennMCI(InString);
    END
    ELSE
      FOR Counter := StrLen TO (MaxLen - 1) DO
        InString := InString + ' ';
  PadLeftStr := Instring;
END;

FUNCTION PadRightStr(InString: STRING; MaxLen: Byte): STRING;
VAR
  StrLen,
  Counter: Byte;
BEGIN
  StrLen := LennMCI(InString);
  FOR Counter := StrLen TO (MaxLen - 1) DO
    InString := ' ' + InString;
  IF (StrLen > MaxLen) THEN
    InString[0] := Chr(MaxLen + (Length(InString) - StrLen));
  PadRightStr := Instring;
END;

FUNCTION PadLeftInt(L: LongInt; MaxLen: Byte): STRING;
BEGIN
  PadLeftInt := PadLeftStr(IntToStr(L),MaxLen);
END;

FUNCTION PadRightInt(L: LongInt; MaxLen: Byte): STRING;
BEGIN
  PadRightInt := PadRightStr(IntToStr(L),MaxLen);
END;

PROCEDURE Prompt(CONST InString: STRING);
VAR
  SaveAllowAbort: Boolean;
BEGIN
  SaveAllowAbort := AllowAbort;
  AllowAbort := FALSE;
  PrintMain(InString);
  AllowAbort := SaveAllowAbort;
END;

PROCEDURE Print(CONST Instring: STRING);
BEGIN
  Prompt(InString+^M^J);
END;

PROCEDURE NL;
BEGIN
  Prompt(^M^J);
END;

PROCEDURE Prt(CONST Instring: STRING);
BEGIN
  UserColor(4);
  Prompt(Instring);
  UserColor(3);
END;

PROCEDURE MPL(MaxLen: Byte);
VAR
  Counter,
  SaveWhereX : Byte;
BEGIN
  IF (OkANSI OR OkAvatar) THEN
  BEGIN
    UserColor(6);
    SaveWhereX := WhereX;
    IF (OutCom) THEN
      FOR Counter := 1 TO MaxLen DO
        Com_Send(' ');
    IF (WantOut) THEN
      FOR Counter := 1 TO MaxLen DO
        Write(' ');
    GotoXY(SaveWhereX,WhereY);
    IF (OutCom) THEN
      IF (OkAvatar) THEN
        SerialOut(^y+^H+Chr(MaxLen))
      ELSE
        SerialOut(#27+'['+IntToStr(MaxLen)+'D');
  END;
END;

FUNCTION InKey: Word;
VAR
  c: Char;
  l: LongInt;
BEGIN
  c := #0;
  InKey := 0;
  CheckHangup;
  IF (KeyPressed) THEN
  BEGIN
    c := ReadKey;
    IF (c = #0) AND (KeyPressed) THEN
    BEGIN
       c := ReadKey;
       SKey1(c);
       IF (c = #31) OR (C = #46) THEN
         c := #1
       ELSE
       BEGIN
         InKey := (Ord(c) * 256);        { Return scan code IN MSB }
         Exit;
       END;
    END;
    IF (Buf <> '') THEN
    BEGIN
      c := Buf[1];
      Buf := Copy(Buf,2,255);
    END;
    InKey := Ord(c);
  END
  ELSE IF (InCom) THEN
  BEGIN
    c := CInKey;
    IF (c = #27) THEN
    BEGIN
      IF (Empty) THEN
        Delay(100);
      IF (c = #27) AND (NOT Empty) THEN
      BEGIN
        c := CInKey;
        IF (c = '[') OR (c = 'O') THEN
        BEGIN
          l := (Ticks + 4);
          c := #0;
          WHILE (l > Ticks) AND (c = #0) DO
            c := CInKey;
        END;
        CASE Char(c) OF
          'A' : InKey := F_UP;      {UpArrow}
          'B' : InKey := F_DOWN;    {DownArrow}
          'C' : InKey := F_RIGHT;   {RightArrow}
          'D' : InKey := F_LEFT;    {LeftArrow}
          'H' : InKey := F_HOME;    {Home}
          'K' : InKey := F_END;    {END - PROCOMM+}
          'R' : InKey := F_END;     {END - GT}
          '4' : BEGIN
                  InKey := F_END;
                  c := CInKey;
                END;
          'r' : InKey := F_PGUP;    {PgUp}
          'q' : InKey := F_PGDN;    {PgDn}
          'n' : InKey := F_INS;     {Ins}
        END;
        Exit;
      END;
    END;
    IF (c = #127) THEN
     InKey := F_DEL
    ELSE
     InKey := Ord(c);
  END;
END;

PROCEDURE OutTrap(c: Char);
BEGIN
  IF (c <> ^G) THEN
    Write(TrapFile,c);
  IF (IOResult <> 0) THEN
  BEGIN
    SysOpLog('Error writing to trap file.');
    Trapping := FALSE;
  END;
END;

PROCEDURE OutKey(c: Char);
VAR
  S: Str1;
BEGIN
  IF (NOT Echo) THEN
    IF (General.LocalSec) AND (c IN [#32..#255]) THEN
    BEGIN
      s := lRGLNGStr(1,TRUE); {FString.EchoC;}
      c := s[1];
    END;
  IF (c IN [#27,^V,^y]) THEN
    DOSANSIOn := TRUE;
  IF (WantOut) AND (DOSANSIOn) AND (NextState <> Waiting) THEN
  BEGIN
    DOSANSI(c);
    IF (OutCom) THEN
      Com_Send(c);
    Exit;
  END
  ELSE IF (c <> ^J) AND (c <> ^L) THEN
    IF (WantOut) AND (NOT DOSANSIOn) AND NOT ((c = ^G) AND InCom) THEN
      Write(c)
    ELSE IF (WantOut) AND NOT ((c = ^G) AND InCom) THEN
      DOSANSI(c);

  IF (NOT Echo) AND (c IN [#32..#255]) THEN
  BEGIN
    S := lRGLNGStr(1,TRUE); {FString.EchoC;}
    c := S[1];
  END;

  CASE c OF
    ^J : BEGIN
           IF (NOT InChat) AND (NOT Write_Msg) AND (NOT CtrlJOff) AND (NOT DOSANSIOn) THEN
           BEGIN
             IF (((CurrentColor SHR 4) AND 7) > 0) OR (CurrentColor AND 128 = 128) THEN
               SetC(Scheme.Color[1])
           END
           ELSE
             LIL := 1;
           IF (Trapping) THEN
             OutTrap(c);
           IF (WantOut) THEN
             Write(^J);
           IF (OutCom) THEN
             Com_Send(^J);
           Inc(LIL);
           IF (LIL >= PageLength) THEN
           BEGIN
             LIL := 1;
             IF (TempPause) THEN
               PauseScr(TRUE);
           END;
         END;
    ^L : BEGIN
           IF (WantOut) THEN
             ClrScr;
           IF (OutCom) THEN
             Com_Send(^L);
           LIL := 1;
         END;
  ELSE
  BEGIN
    IF (OutCom) THEN
      Com_Send(c);
    IF (Trapping) THEN
      OutTrap(c);
  END;
  END;
END;

FUNCTION PageLength: Word;
BEGIN
  IF (InCom) THEN
    PageLength := ThisUser.PageLen
  ELSE IF (General.WindowOn) AND NOT (InWFCMenu) THEN
    PageLength := (MaxDisplayRows - 2)
  ELSE
    PageLength := MaxDisplayRows;
END;

PROCEDURE TeleConfCheck;
VAR
  f: FILE;
  s: STRING;
  Counter: Byte;
  SaveMCIAlllowed: Boolean;
  { Only check IF we're bored AND NOT slicing }
BEGIN
  IF (MaxChatRec > NodeChatLastRec) THEN
  BEGIN
    FOR Counter := 1 TO (LennMCI(MLC) + 5) DO
      BackSpace;
    Assign(f,General.TempPath+'MSG'+IntToStr(ThisNode)+'.TMP');
    Reset(f,1);
    Seek(f,NodeChatLastRec);
    WHILE NOT EOF(f) DO
    BEGIN
      BlockRead(f,s[0],1);
      BlockRead(f,s[1],Ord(s[0]));
      MultiNodeChat := FALSE;  {avoid recursive calls during Pause!}
      SaveMCIAlllowed := MCIAllowed;
      MCIAllowed := FALSE;
      Print(s);
      MCIAllowed := SaveMCIAlllowed;
      MultiNodeChat := TRUE;
    END;
    Close(f);
    LastError := IOResult;
    NodeChatLastRec := MaxChatRec;
    Prompt('^3'+MLC);
  END;
END;

FUNCTION GetKey: Word;
CONST
  LastTimeSlice: LongInt = 0;
  LastCheckTimeSlice: LongInt = 0;
VAR
{$IFDEF MSDOS}
  Killme: Pointer ABSOLUTE $0040 :$F000;
{$ENDIF}
  Tf: Boolean;
  I: Integer;
  C: Word;
  TempTimer: LongInt;
BEGIN
  IF (DieLater) THEN
{$IFDEF MSDOS}
    ASM
      Call Killme
    END;
{$ENDIF}
{$IFDEF WIN32}
    Halt;
{$ENDIF}
  LIL := 1;
  IF (Buf <> '') THEN
  BEGIN
    C := Ord(Buf[1]);
    Buf := Copy(Buf,2,255);
  END
  ELSE
  BEGIN
    IF (NOT Empty) THEN
    BEGIN
      IF (InChat) THEN
        C := Ord(Chinkey)
      ELSE
        C := InKey;
    END
    ELSE
    BEGIN
      Tf := FALSE;
      LastKeyHit := Timer;
      C := 0;
      WHILE ((C = 0) AND (NOT HangUp)) DO
      BEGIN
        TempTimer := Timer;
        IF (LastScreenSwap > 0) THEN
        BEGIN
          IF ((TempTimer - LastScreenSwap) < 0) THEN
            LastScreenSwap := ((Timer - LastScreenSwap) + 86400);
          IF ((TempTimer - LastScreenSwap) > 10) THEN
            Update_Screen;
        END;
        IF (Alert IN ThisUser.Flags) OR ((NOT ShutUpChatCall) AND (General.ChatCall) AND (ChatReason <> '')) THEN
        BEGIN
          IF ((TempTimer - LastBeep) < 0) THEN
            LastBeep := ((TempTimer - LastBeep) + 86400);
          IF ((Alert IN ThisUser.Flags) AND ((TempTimer - LastBeep) >= General.Alertbeep)) OR
             ((ChatReason <> '') AND (SysOpAvailable) AND ((TempTimer - LastBeep) >= 5)) THEN
          BEGIN
            FOR I := 1 TO 100 DO
            BEGIN
{$IFDEF MSDOS}
              Sound(500 + (I * 10));
              Delay(2);
              Sound(100 + (I * 10));
              Delay(2);
              NoSound;
{$ENDIF}
{$IFDEF WIN32}
              Sound(500, 200);
              Sound(1500, 200);
{$ENDIF}
            END;
            LastBeep := TempTimer;
          END;
        END;
        IF ((TempTimer - LastKeyHit) < 0) THEN
          LastKeyHit := ((TempTimer - LastKeyHit) + 86400);
        IF (General.TimeOut <> - 1) AND ((TempTimer - LastKeyHit) > (General.TimeOut * 60)) AND (NOT TimedOut)
           AND (ComPortSpeed <> 0) THEN
        BEGIN
          TimedOut := TRUE;
          PrintF('TIMEOUT');
          IF (NoFile) THEN
            Print(^M^J^M^J'Time out - disconnecting.'^M^J^M^J);
          HangUp := TRUE;
          SysOpLog('Inactivity timeout at '+TimeStr);
        END;
        IF (General.TimeOutBell <> - 1) AND ((TempTimer - LastKeyHit) > (General.TimeOutBell * 60)) AND
           (NOT Tf) THEN
        BEGIN
          Tf := TRUE;
          OutKey(^G);
          Delay(100);
          OutKey(^G);
        END;
        IF (Empty) THEN
        BEGIN
          IF (ABS((Ticks - LastTimeSlice)) >= General.Slicetimer) THEN
          BEGIN
{$IFDEF MSDOS}
            CASE Tasker OF
              None : ASM
                       int 28h
                     END;
                DV : ASM
                       Mov ax, 1000h
                       int 15h
                     END;
   Win,Win32,DOS5N : ASM     (* Added Win32 & DOS5N *)
                       Mov ax, 1680h
                       int 2Fh
                     END;
               Os2 : ASM
                       Push dx
                       XOR dx, dx
                       Mov ax, 0
                       Sti
                       Hlt
                       Db 035h, 0Cah
                       Pop dx
                     END;
            END;
{$ENDIF}
{$IFDEF WIN32}
            Sleep(1);
{$ENDIF}
            LastTimeSlice := Ticks;
          END
          ELSE IF (MultiNodeChat) AND (NOT InChat) AND (ABS(Ticks - LastCheckTimeSlice) > 9) THEN
          BEGIN
            LastCheckTimeSlice := Ticks;
            TeleConfCheck;
            LIL := 1;
          END;
        END;
        IF (InChat) THEN
          C := Ord(Chinkey)
        ELSE
          C := InKey;
      END;
      IF (UserOn) AND ((GetPackDateTime - CreditsLastUpdated) > 60) AND NOT (FNoCredits IN ThisUser.Flags) THEN
      BEGIN
        Inc(ThisUser.Debit,General.Creditminute * ((GetPackDateTime - CreditsLastUpdated) DIV 60));
        CreditsLastUpdated := GetPackDateTime;
      END;
    END;
  END;
  GetKey := C;
END;

PROCEDURE CLS;
BEGIN
  IF (OkANSI OR OkVT100) THEN
    SerialOut(^[+'[1;1H'+^[+'[2J')
  ELSE
    OutKey(^L);
  IF (WantOut) THEN
    ClrScr;
  IF (Trapping) THEN
    OutTrap(^L);
  UserColor(1);
  LIL := 1;
END;

FUNCTION DisplayARFlags(AR: ARFlagSet; C1,C2: Char): AStr;
VAR
  Flag: Char;
  TempStr: AStr;
BEGIN
  TempStr := '';
  FOR Flag := 'A' TO 'Z' DO
    IF Flag IN AR THEN
      TempStr := TempStr + '^'+C1+Flag
    ELSE
      TempStr := TempStr + '^'+C2+'-';
  DisplayArFlags := TempStr;
END;

PROCEDURE ToggleARFlag(Flag: Char; VAR AR: ARFlagSet; VAR Changed: Boolean);
VAR
  SaveAR: ARFlagSet;
BEGIN
  SaveAR := AR;
  IF (Flag IN ['A'..'Z']) THEN
    IF (Flag IN AR) THEN
      Exclude(AR,Flag)
    ELSE
      Include(AR,Flag);
  IF (SaveAR <> AR) THEN
    Changed := TRUE;
END;

FUNCTION DisplayACFlags(Flags: FlagSet; C1,C2: Char): AStr;
VAR
  Flag: FlagType;
  TempS: AStr;
BEGIN
  TempS := '';
  FOR Flag := RLogon TO RMsg DO
    IF (Flag IN Flags) THEN
      TempS := TempS + '^'+C1+Copy('LCVUA*PEKM',(Ord(Flag) + 1),1)
    ELSE
      TempS := TempS + '^'+C2+'-';
  TempS := TempS + '^'+C2+'/';
  FOR Flag := FNoDLRatio TO FNoDeletion DO
    IF (Flag IN Flags) THEN
      TempS := TempS + '^'+C1+Copy('1234',(Ord(Flag) - 19),1)
    ELSE
      TempS := TempS + '^'+C2+'-';
  DisplayACFlags := TempS;
END;

PROCEDURE ToggleACFlag(Flag: FlagType; VAR Flags: FlagSet);
BEGIN
  IF (Flag IN Flags) THEN
    Exclude(Flags,Flag)
  ELSE
    Include(Flags,Flag);
END;

PROCEDURE ToggleACFlags(Flag: Char; VAR Flags: FlagSet; VAR Changed: Boolean);
VAR
  SaveFlags: FlagSet;
BEGIN
  SaveFlags := Flags;
  CASE Flag OF
    'L' : ToggleACFlag(RLogon,Flags);
    'C' : ToggleACFlag(RChat,Flags);
    'V' : ToggleACFlag(RValidate,Flags);
    'U' : ToggleACFlag(RUserList,Flags);
    'A' : ToggleACFlag(RAMsg,Flags);
    '*' : ToggleACFlag(RPostAn,Flags);
    'P' : ToggleACFlag(RPost,Flags);
    'E' : ToggleACFlag(REmail,Flags);
    'K' : ToggleACFlag(RVoting,Flags);
    'M' : ToggleACFlag(RMsg,Flags);
    '1' : ToggleACFlag(FNoDLRatio,Flags);
    '2' : ToggleACFlag(FNoPostRatio,Flags);
    '3' : ToggleACFlag(FNoCredits,Flags);
    '4' : ToggleACFlag(FNoDeletion,Flags);
  END;
  IF (SaveFlags <> Flags) THEN
    Changed := TRUE;
END;

PROCEDURE ToggleStatusFlag(Flag: StatusFlagType; VAR SUFlags: StatusFlagSet);
BEGIN
  IF (Flag IN SUFlags) THEN
    Exclude(SUFlags,Flag)
  ELSE
    Include(SUFlags,Flag);
END;

PROCEDURE ToggleStatusFlags(Flag: Char; VAR SUFlags: StatusFlagSet);
BEGIN
  CASE Flag OF
    'A' : ToggleStatusFlag(LockedOut,SUFlags);
    'B' : ToggleStatusFlag(Deleted,SUFlags);
    'C' : ToggleStatusFlag(TrapActivity,SUFlags);
    'D' : ToggleStatusFlag(TrapSeparate,SUFlags);
    'E' : ToggleStatusFlag(ChatAuto,SUFlags);
    'F' : ToggleStatusFlag(ChatSeparate,SUFlags);
    'G' : ToggleStatusFlag(SLogSeparate,SUFlags);
    'H' : ToggleStatusFlag(CLSMsg,SUFlags);
    'I' : ToggleStatusFlag(RIP,SUFlags);
    'J' : ToggleStatusFlag(FSEditor,SUFlags);
    'K' : ToggleStatusFlag(AutoDetect,SUFlags);
  END;
END;

FUNCTION TACCH(Flag: Char): FlagType;
BEGIN
  CASE Flag OF
    'L': TACCH := RLogon;
    'C': TACCH := RChat;
    'V': TACCH := RValidate;
    'U': TACCH := RUserList;
    'A': TACCH := RAMsg;
    '*': TACCH := RPostAN;
    'P': TACCH := RPost;
    'E': TACCH := REmail;
    'K': TACCH := RVoting;
    'M': TACCH := RMsg;
    '1': TACCH := FNoDLRatio;
    '2': TACCH := FNoPostRatio;
    '3': TACCH := FNoCredits;
    '4': TACCH := FNoDeletion;
  END;
END;

{$IFDEF MSDOS}
FUNCTION AOnOff(b: Boolean; CONST s1,s2:AStr): STRING; ASSEMBLER;
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
FUNCTION AOnOff(b: Boolean; CONST s1,s2:AStr): STRING;
BEGIN
  if (b) then
    AOnOff := s1
  else
    AOnOff := s2;
END;
{$ENDIF}

FUNCTION ShowOnOff(b: Boolean): STRING;
BEGIN
  IF (b) THEN
    ShowOnOff := 'On '
  ELSE
    ShowOnOff := 'Off';
END;

FUNCTION ShowYesNo(b: Boolean): STRING;
BEGIN
  IF (b) THEN
    ShowYesNo := 'Yes'
  ELSE
    ShowYesNo := 'No ';
END;

FUNCTION YN(Len: Byte; DYNY: Boolean): Boolean;
VAR
  Cmd: Char;
BEGIN
  IF (NOT HangUp) THEN
  BEGIN
    UserColor(3);
    Prompt(SQOutSp(ShowYesNo(DYNY)));
    REPEAT
      Cmd := UpCase(Char(GetKey));
    UNTIL (Cmd IN ['Y','N',^M]) OR (HangUp);
    IF (DYNY) AND (Cmd <> 'N') THEN
      Cmd := 'Y';
    IF (DYNY) AND (Cmd = 'N') THEN
      Prompt(#8#8#8'^3No ')
    ELSE IF (NOT DYNY) AND (Cmd = 'Y') THEN
      Prompt(#8#8'^3Yes');
    IF (Cmd = 'N') AND (Len <> 0) THEN
      DoBackSpace(1,Len)
    ELSE
      NL;
    UserColor(1);
    YN := (Cmd = 'Y') AND (NOT HangUp);
  END;
END;

FUNCTION PYNQ(CONST InString: AStr; MaxLen: Byte; DYNY: Boolean): Boolean;
BEGIN
  UserColor(7);
  Prompt(InString);
  PYNQ := YN(MaxLen,DYNY);
END;

PROCEDURE OneK(VAR C: Char; ValidKeys: AStr; DisplayKey,LineFeed: Boolean);
BEGIN
  MPL(1);
  TempPause := (Pause IN ThisUser.Flags);
  REPEAT
    C := UpCase(Char(GetKey));
  UNTIL (Pos(C,ValidKeys) > 0) OR (HangUp);
  IF (HangUp) THEN
    C := ValidKeys[1];
  IF (DisplayKey) THEN
    OutKey(C);
  IF (Trapping) THEN
    OutTrap(C);
  UserColor(1);
  IF (LineFeed) THEN
    NL;
END;

PROCEDURE OneK1(VAR C: Char; ValidKeys: AStr; DisplayKey,LineFeed: Boolean);
BEGIN
  MPL(1);
  TempPause := (Pause IN ThisUser.Flags);
  REPEAT
    C := Char(GetKey);
    IF (C = 'q') THEN
      C := UpCase(C);
  UNTIL (Pos(C,ValidKeys) > 0) OR (HangUp);
  IF (HangUp) THEN
    C := ValidKeys[1];
  IF (DisplayKey) THEN
    OutKey(C);
  IF (Trapping) THEN
    OutTrap(C);
  UserColor(1);
  IF (LineFeed) THEN
    NL;
END;

PROCEDURE LOneK(DisplayStr: AStr; VAR C: Char; ValidKeys: AStr; DisplayKey,LineFeed: Boolean);
BEGIN
  Prt(DisplayStr);
  MPL(1);
  TempPause := (Pause IN ThisUser.Flags);
  REPEAT
    C := UpCase(Char(GetKey));
  UNTIL (Pos(C,ValidKeys) > 0) OR (HangUp);
  IF (HangUp) THEN
    C := ValidKeys[1];
  IF (DisplayKey) THEN
    OutKey(C);
  IF (Trapping) THEN
    OutTrap(C);
  UserColor(1);
  IF (LineFeed) THEN
    NL;
END;

FUNCTION Centre(InString: AStr): STRING;
VAR
  StrLen,
  Counter: Integer;
BEGIN
  StrLen := LennMCI(Instring);
  IF (StrLen < ThisUser.LineLen) THEN
  BEGIN
    Counter := ((ThisUser.LineLen - StrLen) DIV 2);
    Move(Instring[1],Instring[Counter + 1],Length(Instring));
    Inc(Instring[0],Counter);
    FillChar(InString[1],Counter,#32);
  END;
  Centre := InString;
END;

PROCEDURE WKey;
VAR
  Cmd: Char;
BEGIN
  IF (NOT AllowAbort) OR (Abort) OR (HangUp) OR (Empty) THEN
    Exit;
  Cmd := Char(GetKey);
  IF (DisplayingMenu) AND (Pos(UpCase(Cmd),MenuKeys) > 0) THEN
  BEGIN
    MenuAborted := TRUE;
    Abort := TRUE;
    Buf := Buf + UpCase(Cmd);
  END
  ELSE
    CASE UpCase(Cmd) OF
      ' ',^C,^X,^K :
            Abort := TRUE;
      'N',^N :
            IF (Reading_A_Msg) THEN
            BEGIN
              Abort := TRUE;
              Next := TRUE;
            END;
      'P',^S :
            Cmd := Char(GetKey);
      ELSE IF (Reading_A_Msg) OR (PrintingFile) THEN
        IF (Cmd <> #0) THEN
          Buf := Buf + Cmd;
    END;
  IF (Abort) THEN
  BEGIN
    Com_Purge_Send;
    NL;
  END;
END;

PROCEDURE PrintMain(CONST ss:STRING);
VAR
  i,
  X: Word;
  X2: Byte;
  c: Char;
  cs: STRING;
  s: STRING;
  Justify: Byte;
BEGIN
  IF (Abort) AND (AllowAbort) THEN
    Exit;
  IF (HangUp) THEN
  BEGIN
    Abort := TRUE;
    Exit;
  END;

  IF (NOT MCIAllowed) THEN
    s := ss
  ELSE
  BEGIN
    s := '';
    FOR i := 1 TO Length(ss) DO
      IF (ss[i] = '%') AND (i + 2 <= Length(ss)) THEN
      BEGIN
        cs := MCI(Copy(ss,i,3));      { faster than adding }
        IF (cs = Copy(ss,i,3)) THEN
        BEGIN
          s := s + '%';
          Continue;
        END;
        Inc(i,2);
        IF (Length(ss) >= i + 2) AND (ss[i + 1] IN ['#','{','}']) THEN
        BEGIN
          IF (ss[i + 1] = '}') THEN
            Justify := 0
          ELSE IF (ss[i + 1] = '{') THEN
            Justify := 1
          ELSE
            Justify := 2;
          IF (ss[i + 2] IN ['0'..'9']) THEN
          BEGIN
            X2 := Ord(ss[i + 2]) - 48;
            Inc(i, 2);
            IF (ss[i + 1] IN ['0'..'9']) THEN
            BEGIN
              X2 := X2 * 10 + Ord(ss[i + 1]) - 48;
              Inc(i, 1);
            END;
            IF (X2 > 0) THEN
              CASE Justify OF
                0 : cs := PadRightStr(cs,X2);
                1 : cs := PadLeftStr(cs,X2);
                2 : WHILE (Length(cs) < X2) DO
                    BEGIN
                      cs := ' ' + cs;
                      IF (Length(cs) < X2) THEN
                        cs := cs + ' ';
                   END;
              END;
          END;
        END;
        { s := s + cs; }
        IF (Length(cs) + Length(s) <= 255) THEN
        BEGIN
          Move(cs[1],s[Length(s)+1],Length(cs));
          Inc(s[0],Length(cs));
        END
        ELSE
          IF (Length(s) < 255) THEN
          BEGIN
            Move(cs[1],s[Length(s)+1],(255 - Length(s)));
            s[0] := #255;
          END;
      END
      ELSE
        IF (Length(s) < 255) THEN   { s := s + ss[i]; }
        BEGIN
          Inc(s[0]);
          s[Length(s)] := ss[i];
        END;
  END;

  IF NOT (OkANSI OR OkAvatar) THEN
    s := StripColor(s);

  i := 1;
  IF ((NOT Abort) OR (NOT AllowAbort)) AND (NOT HangUp) THEN  { can't change IN loop }
    WHILE (i <= Length(s)) DO
    BEGIN
      CASE s[i] OF
        '%' : IF MCIAllowed AND (i + 1 < Length(s)) THEN
              BEGIN
                IF (UpCase(s[i + 1]) = 'P') AND (UpCase(s[i + 2]) = 'A') THEN
                BEGIN
                  Inc(i,2);
                  PauseScr(FALSE)
                END
                ELSE IF (UpCase(s[i + 1]) = 'D') THEN
                  IF (UpCase(s[i + 2]) = 'E') THEN
                  BEGIN
                    Inc(i,2);
                    OutKey(' '); OutKey(#8); { guard against +++ }
                    Delay(800);
                  END
                  ELSE IF ((UpCase(s[i + 2]) = 'F') AND (NOT PrintingFile)) THEN
                  BEGIN
                    cs := ''; Inc(i, 3);
                    WHILE (i < Length(s)) AND (s[i] <> '%') DO
                    BEGIN
                      cs := cs + s[i];
                      Inc(i);
                    END;
                    PrintF(StripName(cs));
                  END
                  ELSE
                ELSE
                  OutKey('%');
        END
        ELSE
          OutKey('%');
        ^S:IF (i < Length(s)) AND (NextState = Waiting) THEN BEGIN
              IF (Ord(s[i + 1]) <= 200) THEN SetC(Scheme.Color[Ord(s[i + 1])]); Inc(i);
           END
           ELSE OutKey('');
           '|':IF (ColorAllowed) AND (i + 1 < Length(s)) AND
               (s[i + 1] IN ['0'..'9']) AND (s[i + 2] IN ['0'..'9'])
        THEN
        BEGIN
          X := StrToInt(Copy(s,i + 1,2));
          CASE X OF
            0..15:SetC(CurrentColor - (CurrentColor MOD 16) + X);
            16..23:SetC(((X - 16) * 16) + (CurrentColor MOD 16));
          END;
          Inc(i,2);
        END
        ELSE
          OutKey('|');
        #9:FOR X := 1 TO 5 DO
          OutKey(' ');
        '^':IF (ColorAllowed) AND (i < Length(s)) AND (s[i+1] IN ['0'..'9']) THEN
        BEGIN
          Inc(i);
          UserColor(Ord(s[i]) - 48);
        END
        ELSE
          OutKey('^');
        ELSE
          OutKey(s[i]);
      END;
      Inc(i);
      X2 := i;
      WHILE (X2 < Length(s)) AND
            NOT (s[X2] IN [^S,'^','|','%',^G,^L,^V,^y,^J,^[])
      DO
        Inc(X2);

      IF (X2 > i) THEN
      BEGIN
        cs[0] := Chr(X2 - i);
        Move(s[i], cs[1], X2 - i);     { twice as fast as Copy(s,i,x2-i); }
        i := X2;

        IF (Trapping) THEN
          Write(TrapFile,cs);

        IF (WantOut) THEN
          IF (NOT DOSANSIOn) THEN
            Write(cs)
          ELSE
            FOR X2 := 1 TO Length(cs) DO
              DOSANSI(cs[X2]);

        SerialOut(cs);
      END;
    END;
  WKey;
END;

PROCEDURE PrintACR(InString: STRING);
VAR
  TurnOff: Boolean;
BEGIN
  IF (AllowAbort) AND (Abort) THEN
    Exit;
  Abort := FALSE;
  TurnOff := (InString[Length(Instring)] = #29);
  IF (TurnOff) THEN
    Dec(InString[0]);
  CheckHangup;
  IF (NOT CROff) AND NOT (TurnOff) THEN
    InString := InString + ^M^J;
  PrintMain(InString);
  IF (Abort) THEN
  BEGIN
    CurrentColor := (255 - CurrentColor);
    UserColor(1);
  END;
  CROff := FALSE;
END;

PROCEDURE pfl(FN: AStr);
VAR
  fil: Text;
  ls: STRING[255];
  ps: Byte;
  c: Char;
  SaveTempPause,
  ToggleBack,
  SaveAllowAbort: Boolean;
BEGIN
  PrintingFile := TRUE;
  SaveAllowAbort := AllowAbort;
  AllowAbort := TRUE;
  Abort := FALSE;
  Next := FALSE;
  ToggleBack := FALSE;
  SaveTempPause := TempPause;
  FN := AllCaps(FN);
  IF (General.WindowOn) AND (Pos('.AN',FN) > 0) OR (Pos('.AV',FN) > 0) THEN
  BEGIN
    TempPause := FALSE;
    ToggleBack := TRUE;
    ToggleWindow(FALSE);
    IF (OkRIP) THEN
      SerialOut('!|*|');
  END;
  IF (Pos('.RI',FN) > 0) THEN
    TempPause := FALSE;
  IF (NOT HangUp) THEN
  BEGIN
    Assign(fil,SQOutSp(FN));
    Reset(fil);
    IF (IOResult <> 0) THEN
      NoFile := TRUE
    ELSE
    BEGIN
      Abort := FALSE;
      Next := FALSE;
      WHILE (NOT EOF(fil)) AND (NOT Abort) AND (NOT HangUp) DO
      BEGIN
        ps := 0;
        REPEAT
          Inc(ps);
          Read(fil,ls[ps]);
          IF EOF(fil) THEN        {check again incase avatar parameter}
          BEGIN
            Inc(ps);
            Read(fil,ls[ps]);
            IF EOF(fil) THEN
              Dec(ps);
          END;
        UNTIL ((ls[ps] = ^J) AND (NextState IN [Waiting..In_Param])) OR (ps = 255) OR EOF(fil);
        ls[0] := Chr(ps);
        CROff := TRUE;
        CtrlJOff := ToggleBack;
        PrintACR(ls);
      END;
      Close(fil);
    END;
    NoFile := FALSE;
  END;
  AllowAbort := SaveAllowAbort;
  PrintingFile := FALSE;
  CtrlJOff := FALSE;
  IF (ToggleBack) THEN
    ToggleWindow(TRUE);
  RedrawForANSI;
  IF (NOT TempPause) THEN
    LIL := 0;
  TempPause := SaveTempPause;
END;

FUNCTION BSlash(InString: AStr; b: Boolean): AStr;
BEGIN
  IF (b) THEN
  BEGIN
    WHILE (Copy(InString,(Length(InString) - 1),2) = '\\') DO
      InString := Copy(Instring,1,(Length(InString) - 2));
    IF (Copy(InString,Length(InString),1) <> '\') THEN
      InString := InString + '\';
  END
  ELSE
    WHILE (InString[Length(InString)] = '\') DO
      Dec(InString[0]);
  BSlash := Instring;
END;

FUNCTION Exist(FileName: AStr): Boolean;
VAR
  DirInfo1: SearchRec;
BEGIN
  FindFirst(SQOutSp(FileName),AnyFile,DirInfo1);
  Exist := (DOSError = 0);
END;

FUNCTION ExistDir(Path: PathStr): Boolean;
VAR
  DirInfo1: SearchRec;
BEGIN
  Path := AllCaps(BSlash(Path,FALSE));
  FindFirst(Path,AnyFile,DirInfo1);
  ExistDir := (DOSError = 0) AND (DirInfo1.Attr AND $10 = $10);
END;

PROCEDURE PrintFile(FileName: AStr);
VAR
  s: AStr;
  dayofweek: Byte;
  i: Integer;
BEGIN
  FileName := AllCaps(FileName);
  s := FileName;
  IF (Copy(FileName,Length(FileName) - 3,4) = '.ANS') THEN
  BEGIN
    IF (Exist(Copy(FileName,1,Length(FileName) - 4)+'.AN1')) THEN
      REPEAT
        i := Random(10);
        IF (i = 0) THEN
          FileName := Copy(FileName,1,Length(FileName) - 4)+'.ANS'
        ELSE
          FileName := Copy(FileName,1,Length(FileName) - 4)+'.AN'+IntToStr(i);
      UNTIL (Exist(FileName));
  END
  ELSE IF (Copy(FileName,Length(FileName) - 3,4) = '.AVT') THEN
  BEGIN
    IF (Exist(Copy(FileName,1,Length(FileName) - 4)+'.AV1')) THEN
      REPEAT
        i := Random(10);
        IF (i = 0) THEN
          FileName := Copy(FileName,1,Length(FileName) - 4)+'.AVT'
        ELSE
          FileName := Copy(FileName,1,Length(FileName) - 4)+'.AV'+IntToStr(i);
      UNTIL (Exist(FileName));
  END
  ELSE IF (Copy(FileName,Length(FileName) - 3,4) = '.RIP') THEN
  BEGIN
    IF (Exist(Copy(FileName,1,Length(FileName) - 4)+'.RI1')) THEN
      REPEAT
        i := Random(10);
        IF (i = 0) THEN
          FileName := Copy(FileName,1,Length(FileName) - 4)+'.RIP'
        ELSE
          FileName := Copy(FileName,1,Length(FileName) - 4)+'.RI'+IntToStr(i);
      UNTIL (Exist(FileName));
    END;
  GetDayOfWeek(DayOfWeek);
  s := FileName;
  s[Length(s) - 1] := Chr(DayOfWeek + 48);
  IF (Exist(s)) THEN
    FileName := s;
  pfl(FileName);
END;

PROCEDURE PrintF(FileName: AStr);
VAR
  FFN,
  Path: PathStr;
  Name: NameStr;
  Ext: ExtStr;

  j: Integer;  (* doesn't seem to do anything *)

BEGIN
  NoFile := TRUE;
  FileName := SQOutSp(FileName);
  IF (FileName = '') THEN
    Exit;

  IF (Pos('\',FileName) <> 0) THEN    (* ??? *)
    j := 1
  ELSE
  BEGIN
    j := 2;
    FSplit(FExpand(FileName),Path,Name,Ext);
    IF (NOT Exist(General.MiscPath+Name+'.*')) THEN
      Exit;
  END;

  FFN := FileName;
  IF ((Pos('\',FileName) = 0) AND (Pos(':',FileName) = 0)) THEN
    FFN := General.MiscPath+FFN;
  FFN := FExpand(FFN);
  IF (Pos('.',FileName) <> 0) THEN
    PrintFile(FFN)
  ELSE
  BEGIN
    IF (OkRIP) AND Exist(FFN+'.RIP') THEN
      PrintFile(FFN+'.RIP');
    IF (NoFile) AND (OkAvatar) AND Exist(FFN+'.AVT') THEN
      PrintFile(FFN+'.AVT');
    IF (NoFile) AND (OkANSI) AND Exist(FFN+'.ANS') THEN
      PrintFile(FFN+'.ANS');
    IF (NoFile) AND (Exist(FFN+'.ASC')) THEN
      PrintFile(FFN+'.ASC');
  END;
END;

FUNCTION VerLine(B: Byte): STRING;
BEGIN
  CASE B OF
    1 : VerLine := '|09The |14Renegade Bulletin Board System|09, Version |15'+General.Version;
    2 : VerLine := '|09Brought to you by |10The Renegade Development Team|09.';
    3 : VerLine := '|09Copyright (c) |151991-2009|09';
  END;
END;

FUNCTION AACS1(User: UserRecordType; UNum: Integer; s: ACString): Boolean;
VAR
  s1,
  s2: AStr;
  c,
  c1,
  c2: Char;
  i,
  p1,
  p2,
  j: Integer;
  b: Boolean;

  PROCEDURE GetRest;
  VAR
    incre: Byte;
  BEGIN
    s1 := c;
    p1 := i;
    incre := 0;
    IF ((i <> 1) AND (s[i - 1] = '!')) THEN
    BEGIN
      s1 := '!' + s1;
      Dec(p1);
    END;
    IF (c IN ['N','C','E','F','G','I','J','M','O','R','V','Z']) THEN
    BEGIN
      s1 := s1 + s[i + 1];
      Inc(i);
      IF c IN ['N'] THEN
        WHILE s[i + 1 + incre] IN ['0'..'9'] DO
        BEGIN
          Inc (incre);
          s1 := s1 + s[i +1 +incre];
        END;
    END
    ELSE
    BEGIN
      j := i + 1;
      WHILE (j <= Length(s)) AND (s[j] IN ['0'..'9']) DO
      BEGIN
        s1 := s1 + s[j];
        Inc(j);
      END;
      i := (j - 1);
    END;
    p2 := i;
  END;

  FUNCTION ArgStat(s: AStr): Boolean;
  VAR
    VS: AStr;
    c: Char;
    DayOfWeek: Byte;
    RecNum1,
    RecNum,
    VSI: Integer;
    Hour,
    Minute,
    Second,
    Sec100: Word;
    BoolState,
    ACS: Boolean;
  BEGIN
    BoolState := (s[1] <> '!');
    IF (NOT BoolState) THEN
      s := Copy(s,2,(Length(s) - 1));
    VS := Copy(s,2,(Length(s) - 1));
    VSI := StrToInt(VS);
    CASE s[1] OF
      'A' : ACS := (AgeUser(User.BirthDate) >= VSI);
      'B' : ACS := ((ActualSpeed >= (VSI * 100)) AND (VSI > 0)) OR (ComPortSpeed = 0);
      'C' : BEGIN
              ACS := (CurrentConf = VS);
              C := VS[1];
              IF (NOT ConfSystem) AND (C IN ConfKeys) THEN
              BEGIN
                IF FindConference(C,Conference) THEN
                  ACS := AACS1(ThisUser,UserNum,Conference.ACS)
                ELSE
                  ACS := FALSE;
              END;
            END;
      'D' : ACS := (User.DSL >= VSI) OR (TempSysOp);
      'E' : CASE UpCase(VS[1]) OF
              'A' : ACS := OkANSI;
              'N' : ACS := NOT (OkANSI OR OkAvatar OR OkVT100);
              'V' : ACS := OkAvatar;
              'R' : ACS := OkRIP;
              '1' : ACS := OkVT100;
            END;
      'F' : ACS := (UpCase(VS[1]) IN User.AR);
      'G' : ACS := (User.Sex = UpCase(VS[1]));
      'H' : BEGIN
              GetTime(Hour,Minute,Second,Sec100);
              ACS := (Hour = VSI);
            END;
      'I' : ACS := IsInvisible;
      'J' : ACS := (Novice IN User.Flags);
      'K' : ACS := (ReadMsgArea = VSI);
      'L' : ACS := (ReadFileArea = VSI);
      'M' : ACS := (UnVotedTopics = 0);
      'N' : ACS := (ThisNode = VSI);
      'O' : ACS := SysOpAvailable;
      'P' : ACS := ((User.lCredit - User.Debit) >= VSI);
      'R' : ACS := (TACCH(UpCase(VS[1])) IN User.Flags);
      'S' : ACS := (User.SL >= VSI) OR (TempSysOp);
      'T' : ACS := (NSL DIV 60 >= VSI);
      'U' : ACS := (UNum = VSI);
      'V' : BEGIN
              Reset(ValidationFile);
              RecNum1 := -1;
              RecNum := 1;
              WHILE (RecNum <= NumValKeys) AND (RecNum1 = -1) DO
              BEGIN
                Seek(ValidationFile,(RecNum - 1));
                Read(ValidationFile,Validation);
                IF (Validation.Key = '!') THEN
                  RecNum1 := RecNum;
                Inc(RecNum);
              END;
              Close(ValidationFile);
              ACS := (RecNum1 <> -1) AND (User.SL > Validation.NewSL);
            END;
      'W' : BEGIN
              GetDayOfWeek(DayOfWeek);
              ACS := (DayOfWeek = Ord(s[2]) - 48);
            END;
      'X' : ACS := (((User.Expiration DIV 86400) - (GetPackDateTime DIV 86400)) <= VSI) AND (User.Expiration > 0);
      'Y' : ACS := (Timer DIV 60 >= VSI);
      'Z' : IF (FNoPostRatio IN User.Flags) THEN
              ACS := TRUE
            ELSE IF (General.PostRatio[User.SL] > 0) AND (User.LoggedOn > 100 / General.PostRatio[User.SL]) THEN
              ACS := ((User.MsgPost / User.LoggedOn * 100) >= General.PostRatio[User.SL])
            ELSE
              ACS := TRUE;
    END;
    IF (NOT BoolState) THEN
      ACS := NOT ACS;
    ArgStat := ACS;
  END;

BEGIN
  i := 0;
  s := AllCaps(s);
  WHILE (i < Length(s)) DO
  BEGIN
    Inc(i);
    c := s[i];
    IF (c IN ['A'..'Z']) AND (i <> Length(s)) THEN
    BEGIN
      GetRest;
      b := ArgStat(s1);
      Delete(s,p1,Length(s1));
      IF (b) THEN
        s2 := '^'
      ELSE
        s2 := '%';
      Insert(s2,s,p1);
      Dec(i,(Length(s1) - 1));
    END;
  END;
  s := '(' + s + ')';
  WHILE (Pos('&', s) <> 0) DO
    Delete(s,Pos('&',s),1);
  WHILE (Pos('^^', s) <> 0) DO
    Delete(s,Pos('^^',s),1);
  WHILE (Pos('(', s) <> 0) DO
  BEGIN
    i := 1;
    WHILE ((s[i] <> ')') AND (i <= Length(s))) DO
    BEGIN
      IF (s[i] = '(') THEN
        p1 := i;
      Inc(i);
    END;
    p2 := i;
    s1 := Copy(s,(p1 + 1),((p2 - p1) - 1));
    WHILE (Pos('|',s1) <> 0) DO
    BEGIN
      i := Pos('|',s1);
      c1 := s1[i - 1];
      c2 := s1[i + 1];
      s2 := '%';
      IF ((c1 IN ['%','^']) AND (c2 IN ['%','^'])) THEN
      BEGIN
        IF ((c1 = '^') OR (c2 = '^')) THEN
          s2 := '^';
        Delete(s1,(i - 1),3);
        Insert(s2,s1,(i - 1));
      END
      ELSE
        Delete(s1,i,1);
    END;
    WHILE (Pos('%%',s1) <> 0) DO
      Delete(s1,Pos('%%',s1),1);   {leave only "%"}
    WHILE (Pos('^^', s1) <> 0) DO
      Delete(s1,Pos('^^',s1),1);   {leave only "^"}
    WHILE (Pos('%^', s1) <> 0) DO
      Delete(s1,Pos('%^',s1)+1,1); {leave only "%"}
    WHILE (Pos('^%', s1) <> 0) DO
      Delete(s1,Pos('^%',s1),1);   {leave only "%"}
    Delete(s,p1,((p2 - p1) + 1));
    Insert(s1,s,p1);
  END;
  AACS1 := (Pos('%',s) = 0);
END;

FUNCTION AACS(s: ACString): Boolean;
BEGIN
  AACS := AACS1(ThisUser,UserNum,s);
END;

PROCEDURE LoadNode(NodeNumber: Byte);
BEGIN
  IF (General.MultiNode) THEN
  BEGIN
    Reset(NodeFile);
    IF (NodeNumber >= 1) AND (NodeNumber <= FileSize(NodeFile)) AND (IOResult = 0) THEN
    BEGIN
      Seek(NodeFile,(NodeNumber - 1));
      Read(NodeFile,NodeR);
    END;
    Close(NodeFile);
    LastError := IOResult;
  END;
END;

PROCEDURE Update_Node(NActivityDesc: AStr; SaveVars: Boolean);
BEGIN
  IF (General.MultiNode) THEN
  BEGIN
    LoadNode(ThisNode);
    IF (SaveVars) THEN
    BEGIN
      SaveNDescription := NodeR.ActivityDesc;
      NodeR.ActivityDesc := NActivityDesc
    END
    ELSE
      NodeR.ActivityDesc := SaveNDescription;
    (*
    IF (UserOn) THEN
    BEGIN
    *)
      NodeR.User := UserNum;
      NodeR.UserName := ThisUser.Name;
      NodeR.Sex := ThisUser.Sex;
      NodeR.Age := AgeUser(ThisUser.BirthDate);
      NodeR.CityState := ThisUser.CityState;
      NodeR.LogonTime := TimeOn;
      NodeR.Channel := ChatChannel;
    (*
    END;
    *)
    SaveNode(ThisNode);
  END;
END;

FUNCTION MaxChatRec: LongInt;
VAR
  DirInfo1: SearchRec;
BEGIN
  FindFirst(General.TempPath+'MSG'+IntToStr(ThisNode)+'.TMP',AnyFile,DirInfo1);
  IF (DOSError = 0) THEN
    MaxChatRec := DirInfo1.Size
  ELSE
    MaxChatRec := 0;
END;

FUNCTION MaxNodes: Byte;
VAR
  DirInfo1: SearchRec;
BEGIN
  FindFirst(General.DataPath+'MULTNODE.DAT',AnyFile,DirInfo1);
  IF (DOSError = 0) THEN
    MaxNodes := (DirInfo1.Size DIV SizeOf(NodeRecordType))
  ELSE
    MaxNodes := 0;
END;

PROCEDURE SaveNode(NodeNumber: Byte);
BEGIN
  IF (General.MultiNode) THEN
  BEGIN
    Reset(NodeFile);
    IF (NodeNumber >= 1) AND (NodeNumber <= FileSize(NodeFile)) AND (IOResult = 0) THEN
    BEGIN
      Seek(NodeFile,(NodeNumber - 1));
      Write(NodeFile,NodeR);
    END;
    Close(NodeFile);
    LastError := IOResult;
  END;
END;

PROCEDURE LoadURec(VAR User: UserRecordType; UserNumber: Integer);
VAR
  FO: Boolean;
BEGIN
  FO := (FileRec(UserFile).Mode <> FMClosed);
  IF (NOT FO) THEN
  BEGIN
    Reset(UserFile);
    IF (IOResult <> 0) THEN
    BEGIN
      SysOpLog('Error opening USERS.DAT.');
      Exit;
    END;
  END;

  IF (UserNumber <> UserNum) OR (NOT UserOn) THEN
  BEGIN
    Seek(UserFile,UserNumber);
    Read(UserFile,User);
  END
  ELSE
    User := ThisUser;

  IF (NOT FO) THEN
    Close(UserFile);

  LastError := IOResult;
END;

PROCEDURE SaveURec(User: UserRecordType; UserNumber: Integer);
VAR
  FO: Boolean;
  NodeNumber: Byte;
BEGIN
  FO := (FileRec(UserFile).Mode <> FMClosed);
  IF (NOT FO) THEN
  BEGIN
    Reset(UserFile);
    IF (IOResult <> 0) THEN
    BEGIN
      SysOpLog('Error opening USERS.DAT.');
      Exit;
    END;
  END;

  Seek(UserFile,UserNumber);
  Write(UserFile,User);

  IF (NOT FO) THEN
    Close(UserFile);

  IF (UserNumber = UserNum) THEN
    ThisUser := User
  ELSE
  BEGIN
    IF (General.MultiNode) THEN
    BEGIN
      NodeNumber := OnNode(UserNumber);
      IF (NodeNumber > 0) THEN
      BEGIN
        LoadNode(NodeNumber);
        Include(NodeR.Status,NUpdate);
        SaveNode(NodeNumber);
      END;
    END;
  END;
  LastError := IOResult;
END;

FUNCTION MaxUsers: Integer;
VAR
  DirInfo1: SearchRec;
BEGIN
  FindFirst(General.DataPath+'USERS.DAT',AnyFile,DirInfo1);
  IF (DOSError = 0) THEN
    MaxUsers := (DirInfo1.Size DIV SizeOf(UserRecordType))
  ELSE
    MaxUsers := 0;
END;

FUNCTION MaxIDXRec: Integer;
VAR
  DirInfo1: SearchRec;
BEGIN
  FindFirst(General.DataPath+'USERS.IDX',AnyFile,DirInfo1);
  IF (DOSError = 0) THEN
    MaxIDXRec := (DirInfo1.Size DIV SizeOf(UserIDXRec))
  ELSE
    MaxIDXRec := 0;
  IF (NOT UserOn) AND (DirInfo1.Size MOD SizeOf(UserIDXRec) <> 0) THEN
    MaxIDXRec := -1;  { UserOn is so it'll only show during boot up }
END;

FUNCTION HiMsg: Word;
VAR
  DirInfo1: SearchRec;
BEGIN
  FindFirst(General.MsgPath+MemMsgArea.FileName+'.HDR',AnyFile,DirInfo1);
  IF (DOSError = 0) THEN
    HiMsg := (DirInfo1.Size DIV SizeOf(MHeaderRec))
  ELSE
    HiMsg := 0;
END;

PROCEDURE ScanInput(VAR S: AStr; CONST Allowed: AStr);
VAR
  SaveS: AStr;
  c: Char;
  Counter: Byte;
  GotCmd: Boolean;
BEGIN
  GotCmd := FALSE;
  s := '';
  REPEAT
    c := UpCase(Char(GetKey));
    SaveS := s;
    IF ((Pos(c,Allowed) <> 0) AND (s = '')) THEN
    BEGIN
      GotCmd := TRUE;
      s := c;
    END
    ELSE IF (Pos(c,'0123456789') > 0) OR (c = '-') THEN
    BEGIN
      IF ((Length(s) < 6) OR ((Pos('-',s) > 0) AND (Length(s) < 11))) THEN
        s := s + c;
    END
    ELSE IF ((s <> '') AND (c = ^H)) THEN
      Dec(s[0])
    ELSE IF (c = ^X) THEN
    BEGIN
      FOR Counter := 1 TO Length(s) DO
        BackSpace;
      s := '';
      SaveS := '';
    END
    ELSE IF (c = #13) THEN
      GotCmd := TRUE;
    IF (Length(s) < Length(SaveS)) THEN
      BackSpace;
    IF (Length(s) > Length(SaveS)) THEN
      Prompt(s[Length(s)]);
  UNTIL (GotCmd) OR (HangUp);
  UserColor(1);
  NL;
END;

PROCEDURE ScreenDump(CONST FileName: AStr);
VAR
  ScreenFile: Text;
  TempStr: AStr;
  c: Char;
  XPos,
  YPos: Byte;
  VidSeg: Word;
BEGIN
  Assign(ScreenFile,FileName);
  Append(ScreenFile);
  IF (IOResult = 2) THEN
    ReWrite(ScreenFile);
  IF (MonitorType = 7) THEN
    VidSeg := $B000
  ELSE
    VidSeg := $B800;
  FOR YPos := 1 TO MaxDisplayRows DO
  BEGIN
    TempStr := '';
    FOR XPos := 1 TO MaxDisplayCols DO
    BEGIN
{$IFDEF MSDOS}
      c := Chr(Mem[VidSeg:(160 * (YPos - 1) + 2 * (XPos - 1))]);
{$ENDIF}
{$IFDEF WIN32}
      c := SysReadCharAt(XPos - 1, YPos - 1);
{$ENDIF}
      IF (c = #0) THEN
        c := #32;
      IF ((XPos = WhereX) AND (YPos = WhereY)) THEN
        c := #178;
      TempStr := TempStr + c;
    END;
    WHILE (TempStr[Length(TempStr)] = ' ') DO
      Dec(TempStr[0]);
    WriteLn(ScreenFile,TempStr);
  END;
  Close(ScreenFile);
  LastError := IOResult;
END;

PROCEDURE InputPath(CONST DisplayStr: AStr; VAR DirPath: Str40; CreateDir,AllowExit: Boolean; VAR Changed: Boolean);
VAR
  TempDirPath: Str40;
  CurDir: PathStr;
  Counter: Byte;
BEGIN
  REPEAT
    TempDirPath := DirPath;
    Changed := FALSE;
    InputWN1(DisplayStr,TempDirPath,39,[UpperOnly,InterActiveEdit],Changed);
    TempDirPath := SQOutSp(TempDirPath);

    IF (Length(TempDirPath) = 1) THEN
      TempDirPath := TempDirPath + ':\'
    ELSE IF (Length(TempDirPath) = 2) AND (TempDirPath[2] = ':') THEN
      TempDirPath := TempDirPath + '\';

    IF (AllowExit) AND (TempDirPath = '') THEN
    BEGIN
      NL;
      Print('Aborted!');
    END
    ELSE IF (TempDirPath = '') THEN
    BEGIN
      NL;
      Print('^7A valid path must be specified!^1');
    END
    ELSE IF (NOT (TempDirPath[1] IN ['A'..'Z'])) OR (Length(TempDirPath) < 3) OR
         (NOT (TempDirPath[2] = ':')) OR (NOT (TempDirPath[3] = '\')) THEN
    BEGIN
      NL;
      Print('^7Invalid drive specification: "'+Copy(TempDirPath,1,3)+'"^1');
      TempDirPath := '';
    END
    ELSE
    BEGIN
      GetDir(0,CurDir);
      ChDir(TempDirPath[1]+':');
      IF (IOResult <> 0) THEN
      BEGIN
        NL;
        Print('^7Drive does not exist: "'+Copy(TempDirPath,1,3)+'"^1');
        TempDirPath := '';
      END
      ELSE
      BEGIN
        ChDir(CurDir);
        IF (CreateDir) THEN
        BEGIN
          TempDirPath := BSlash(TempDirPath,TRUE);
          IF (Length(TempDirPath) > 3) AND (NOT ExistDir(TempDirPath)) THEN
          BEGIN
            NL;
            IF PYNQ('Directory does not exist, create it? ',0,FALSE) THEN
            BEGIN
              Counter := 2;
              WHILE (Counter <= Length(TempDirPath)) DO
              BEGIN
                IF (TempDirPath[Counter] = '\') THEN
                BEGIN
                  IF (TempDirPath[Counter - 1] <> ':') THEN
                  BEGIN
                    IF (NOT ExistDir(Copy(TempDirPath,1,(Counter - 1)))) THEN
                    BEGIN
                      MkDir(Copy(TempDirPath,1,(Counter - 1)));
                      LastError := IOResult;
                      IF (LastError <> 0) THEN
                      BEGIN
                        NL;
                        Print('Error creating directory: '+Copy(TempDirPath,1,(Counter - 1)));
                        SysOpLog('^7Error creating directory: '+Copy(TempDirPath,1,(Counter - 1)));
                        TempDirPath := '';
                      END;
                    END;
                  END;
                END;
                Inc(Counter);
              END;
            END;
          END;
        END;
      END;
    END;
  UNTIL (TempDirPath <> '') OR (AllowExit) OR (HangUp);
  IF (TempDirPath <> '') THEN
    TempDirPath := BSlash(TempDirPath,TRUE);
  IF (TempDirPath <> DirPath) THEN
    Changed := TRUE;
  DirPath := TempDirPath;
END;

FUNCTION OnNode(UserNumber: Integer): Byte;
VAR
  NodeNumber: Byte;
BEGIN
  OnNode := 0;
  IF (General.MultiNode) AND (UserNumber > 0) THEN
    FOR NodeNumber := 1 TO MaxNodes DO
    BEGIN
      LoadNode(NodeNumber);
      IF (NodeR.User = UserNumber) THEN
      BEGIN
        OnNode := NodeNumber;
        Exit;
      END;
    END;
END;

PROCEDURE PurgeDir(s: AStr; SubDirs: Boolean);
VAR
  (*
  DirInfo1: SearchRec;
  *)
  odir: STRING[80];
BEGIN
  s := FExpand(s);
  WHILE (s[Length(s)] = '\') DO
    Dec(s[0]);
  GetDir(ExtractDriveNumber(s),odir);
  ChDir(s);
  IF (IOResult <> 0) THEN
  BEGIN
    ChDir(odir);
    Exit;
  END;
  FindFirst('*.*',AnyFile - Directory - VolumeID,DirInfo);  (* Directory & VolumnID added *)
  WHILE (DOSError = 0) DO
  BEGIN
    Kill(FExpand(DirInfo.Name));
    FindNext(DirInfo);
  END;
  ChDir(odir);
  IF (SubDirs) THEN
    RmDir(s);
  LastError := IOResult;
  ChDir(StartDir);
END;

FUNCTION StripName(InString: STRING): STRING;
VAR
  StrLen: Byte;
BEGIN
  StrLen := Length(InString);
  WHILE (StrLen > 0) AND (Pos(InString[StrLen],':\/') = 0) DO
    Dec(StrLen);
  Delete(InString,1,StrLen);
  StripName := InString;
END;

PROCEDURE Star(InString: AStr);
BEGIN
  IF (OkANSI OR OkAvatar) THEN
    Prompt('^4þ ')
  ELSE
    Prompt('* ');
  IF (InString[Length(InString)] = #29) THEN
    Dec(InString[0])
  ELSE
    InString := InString + ^M^J;
  Prompt('^3'+InString+'^1');
END;

FUNCTION ctp(t,b: LongInt): STRING;
VAR
  s: AStr;
  n: LongInt;
BEGIN
  IF ((t = 0) OR (b = 0)) THEN
    n := 0
  ELSE
    n := (t * 100) DIV b;
  Str(n:6,s);
  ctp := s;
END;

FUNCTION CInKey: Char;
BEGIN
  IF (NOT LocalIOOnly) AND (NOT Com_IsRecv_Empty) THEN
    CInKey := Com_Recv
  ELSE
    CInKey := #0;
END;

PROCEDURE Com_Send_Str(CONST InString: AStr);
VAR
  Counter: Byte;
BEGIN
  FOR Counter := 1 TO Length(InString) DO
    CASE InString[Counter] OF
      '~' : Delay(250);
      '|' : BEGIN
              Com_Send(^M);
              IF (InWFCMenu) THEN
                WriteWFC(^M);
            END;
      '^' : BEGIN
              DTR(FALSE);
              Delay(250);
              DTR(TRUE);
            END;
    ELSE
    BEGIN
      Com_Send(InString[Counter]);
      Delay(2);
      IF (InWFCMenu) THEN
        WriteWFC(InString[Counter]);
    END;
  END;
END;

PROCEDURE DoTelnetHangUp(ShowIt: Boolean);
BEGIN
  IF (NOT LocalIOOnly) THEN
  BEGIN
    IF (ShowIt) AND (NOT BlankMenuNow) THEN
    BEGIN
      TextColor(15);
      TextBackGround(1);
      GotoXY(32,17);
      Prt('Hanging up node..');
    END;
    Com_Flush_Recv;
    DTR(FALSE);
  END;
  IF (ShowIt) AND (SysOpOn) AND (NOT BlankMenuNow) THEN
  BEGIN
    TextColor(15);
    TextBackGround(1);
    GotoXY(1,17);
    ClrEOL;
  END;
END;

PROCEDURE dophoneHangup(ShowIt: Boolean);
VAR
  c: Char;
  Try: Integer;
  SaveTimer: LongInt;
BEGIN
  IF (NOT LocalIOOnly) THEN
  BEGIN
    IF (ShowIt) AND (NOT BlankMenuNow) THEN
    BEGIN
      TextColor(15);
      TextBackGround(1);
      GotoXY(32,17);
      Write('Hanging up phone...');
    END;
    Try := 0;
    WHILE (Try < 3) AND (NOT KeyPressed) DO
    BEGIN
      Com_Flush_Recv;
      Com_Send_Str(Liner.HangUp);
      SaveTimer := Timer;
      WHILE (ABS(Timer - SaveTimer) <= 2) AND (Com_Carrier) DO
      BEGIN
        c := CInKey;
        IF (c > #0) AND (InWFCMenu) THEN
          WriteWFC(c);
      END;
      Inc(Try);
    END;
  END;
  IF (ShowIt) AND (SysOpOn) AND (NOT BlankMenuNow) THEN
  BEGIN
    TextColor(15);
    TextBackGround(1);
    GotoXY(1,17);
    ClrEOL;
  END;
END;

PROCEDURE DoPhoneOffHook(ShowIt: Boolean);
VAR
  TempStr: AStr;
  c: Char;
  Done: Boolean;
  SaveTimer: LongInt;
BEGIN
  IF (ShowIt) AND (NOT BlankMenuNow) AND (SysOpOn) THEN
  BEGIN
    TextColor(15);
    TextBackGround(1);
    GotoXY(33,17);
    Write('Phone off hook');
  END;
  Com_Flush_Recv;
  Com_Send_Str(Liner.OffHook);
  SaveTimer := Timer;
  REPEAT
    c := CInKey;
    IF (c > #0) THEN
    BEGIN
      IF (InWFCMenu) THEN
        WriteWFC(c);
      IF (Length(TempStr) >= 160) THEN
        Delete(TempStr,1,120);
      TempStr := TempStr + c;
      IF (Pos(Liner.OK,TempStr) > 0) THEN
        Done := TRUE;
    END;
  UNTIL (ABS(Timer - SaveTimer) > 2) OR (Done) OR (KeyPressed);
  Com_Flush_Recv;
END;

PROCEDURE PauseScr(IsCont: Boolean);
VAR
  Cmd: Char;
  SaveCurCo,
  Counter: Byte;
  SaveMCIAllowed: Boolean;
BEGIN
  SaveCurCo := CurrentColor;
  SaveMCIAllowed := MCIAllowed;
  MCIAllowed := TRUE;
{$IFDEF MSDOS}
  NoSound;
{$ENDIF}
  IF (NOT AllowContinue) AND NOT (PrintingFile AND AllowAbort) THEN
    IsCont := FALSE;
  IF (IsCont) THEN
    { Prompt(FString.Continue) }
    lRGLngStr(44,FALSE)
  ELSE
    { Prompt({FString.lPause); }
    lRGLngStr(5,FALSE);
  LIL := 1;
  IF (IsCont) THEN
  BEGIN
    REPEAT
      Cmd := UpCase(Char(GetKey));
      CASE Cmd OF
        'C' : IF (IsCont) THEN
                TempPause := FALSE;
        'N' : Abort := TRUE;
      END;
    UNTIL (Cmd IN ['Y','N','Q','C',^M]) OR (HangUp);
  END
  ELSE
    Cmd := Char(GetKey);
  IF (IsCont) THEN
    FOR Counter := 1 TO LennMCI(lRGLngStr(44,TRUE){FString.Continue}) DO
      BackSpace
  ELSE
    FOR Counter := 1 TO LennMCI(lRGLNGStr(5,TRUE){FString.lPause}) DO
      BackSpace;
  IF (Abort) THEN
    NL;
  IF (NOT HangUp) THEN
    SetC(SaveCurCo);
  MCIAllowed := SaveMCIAllowed;
END;

FUNCTION SearchUser(Uname: Str36; RealNameOK: Boolean): Integer;
VAR
  UserIDX: UserIDXRec;
  Current: Integer;
  Done: Boolean;
BEGIN
  SearchUser := 0;
  Reset(UserIDXFile);
  IF (IOResult <> 0) THEN
  BEGIN
    SysOpLog('Error opening USERS.IDX.');
    Exit;
  END;

  WHILE (Uname[Length(Uname)] = ' ') DO
    Dec(Uname[0]);

  Uname := AllCaps(Uname);

  Current := 0;
  Done := FALSE;

  IF (FileSize(UserIDXFile) > 0) THEN
    REPEAT
      Seek(UserIDXFile,Current);
      Read(UserIDXFile,UserIDX);
      IF (Uname < UserIDX.Name) THEN
        Current := UserIDX.Left
      ELSE IF (Uname > UserIDX.Name) THEN
        Current := UserIDX.Right
      ELSE
        Done := TRUE;
    UNTIL (Current = -1) OR (Done);
  Close(UserIDXFile);

  IF (Done) AND (RealNameOK OR NOT UserIDX.RealName) AND (NOT UserIDX.Deleted) THEN
    SearchUser := UserIDX.Number;

  LastError := IOResult;
END;

FUNCTION Plural(InString: STRING; Number: Byte): STRING;
BEGIN
  IF (Number <> 1) THEN
    Plural := InString + 's'
  ELSE
    Plural := InString;
END;

FUNCTION FormattedTime(TimeUsed: LongInt): STRING;
VAR
  s: AStr;
BEGIN
  s := '';
  IF (TimeUsed > 3600) THEN
  BEGIN
    s := IntToStr(TimeUsed DIV 3600)+' '+Plural('Hour',TimeUsed DIV 3600) + ' ';
    TimeUsed := (TimeUsed MOD 3600);
  END;
  IF (TimeUsed > 60) THEN
  BEGIN
    s := s + IntToStr(TimeUsed DIV 60)+' '+Plural('Minute',TimeUsed DIV 60) + ' ';
    TimeUsed := (TimeUsed MOD 60);
  END;
  IF (TimeUsed > 0) THEN
    s := s + IntToStr(TimeUsed)+' '+Plural('Second',TimeUsed);
  IF (s = '') THEN
    s := 'no time';
  WHILE (s[Length(s)] = ' ') DO
    Dec(s[0]);
  FormattedTime := s;
END;

FUNCTION FunctionalMCI(CONST S: AStr; FileName,InternalFileName: AStr): STRING;
VAR
  Temp: STRING;
  Add: AStr;
  Index: Byte;
BEGIN
  Temp := '';
  FOR Index := 1 TO Length(S) DO
    IF (S[Index] = '%') THEN
    BEGIN
      CASE UpCase(S[Index + 1]) OF
        'A' : Add := AOnOff(LocalIOOnly,'0',IntToStr(ActualSpeed));
        'B' : Add := IntToStr(ComPortSpeed);
        'C' : Add := Liner.Address;
        'D' : Add := FunctionalMCI(Protocol.DLFList,'','');
        'E' : Add := Liner.IRQ;
        'F' : Add := SQOutSp(FileName);
        'G' : Add := AOnOff((OkAvatar OR OkANSI),'1','0');
        'H' : Add := SockHandle;
        'I' : BEGIN
                IF (S[Index + 2] = 'P') THEN
                BEGIN
                  Add := ThisUser.CallerID;
                  Inc(Index,1);
                END
                ELSE
                BEGIN
                  Add := InternalFileName;
                END;
              END;
        'K' : BEGIN
                LoadFileArea(FileArea);
                IF (FADirDLPath IN MemFileArea.FAFlags) THEN
                  Add := MemFileArea.DLPath+MemFileArea.FileName+'.DIR'
                ELSE
                  Add := General.DataPath+MemFileArea.FileName+'.DIR';
              END;
        'L' : Add := FunctionalMCI(Protocol.TempLog,'','');
        'M' : Add := StartDir;
        'N' : Add := IntToStr(ThisNode);
        'O' : Add := Liner.DoorPath;
        'P' : Add := IntToStr(Liner.ComPort);
        'R' : Add := ThisUser.RealName;
        'T' : Add := IntToStr(NSL DIV 60);
        'U' : Add := ThisUser.Name;
        '#' : Add := IntToStr(UserNum);
        '1' : Add := Copy(Caps(ThisUser.RealName),1,Pos(' ',ThisUser.RealName) - 1);
        '2' : IF (Pos(' ', ThisUser.RealName) = 0) THEN
                Add := Caps(ThisUser.RealName)
              ELSE
                Add := Copy(Caps(ThisUser.RealName),Pos(' ',ThisUser.RealName) + 1,255);
      ELSE
        Add := '%' + S[Index + 1];
      END;
      Temp := Temp + Add;
      Inc(Index);
    END
    ELSE
      Temp := Temp + S[Index];
  FunctionalMCI := Temp;
END;

FUNCTION MCI(CONST S: STRING): STRING;
VAR
  Temp: STRING;
  Add: AStr;
  Index: Byte;
  I: Integer;
BEGIN
  Temp := '';
  FOR Index := 1 TO Length(S) DO
    IF (S[Index] = '%') AND (Index + 1 < Length(S)) THEN
    BEGIN
      Add := '%' + S[Index + 1] + S[Index + 2];
      WITH ThisUser DO
        CASE UpCase(S[Index + 1]) OF
          'A' : CASE UpCase(S[Index + 2]) OF
                  '1' : Add := IntToStr(LowFileArea);
                  '2' : Add := IntToStr(HighFileArea);
                  '3' : Add := IntToStr(LowMsgArea);
                  '4' : Add := IntToStr(HighMsgArea);
                  'B' : Add := FormatNumber(lCredit - Debit);
                  'D' : Add := Street;
                  'O' : BEGIN
                          IF (PrintingFile) OR (Reading_A_Msg) THEN
                            AllowAbort := FALSE;
                          Add := '';
                        END;
                END;
          'B' : CASE UpCase(S[Index + 2]) OF
                  'D' : Add := IntToStr(ActualSpeed);
                  'L' : Add := PHours('Always allowed',General.MinBaudLowTime,General.MinBaudHiTime);
                  'M' : Add := PHours('Always allowed',General.MinBaudDLLowTime,General.MinBaudDLHiTime);
                  'N' : Add := General.BBSName;
                  'P' : Add := General.BBSPhone;
                END;
          'C' : CASE UpCase(S[Index + 2]) OF
                  'A' : Add := FormatNumber(General.CallAllow[SL]);
                  'D' : Add := AOnOff(General.PerCall,'call','day ');
                  'L' : Add := ^L;
                  'M' : Add := IntToStr(Msg_On);
                  'N' : IF FindConference(CurrentConf,Conference) THEN
                          Add := Conference.Name
                        ELSE
                          Add:= '';
                  'R' : Add := FormatNumber(lCredit);
                  'S' : Add := PHours('Always allowed',General.lLowTime,General.HiTime);
                  'T' : Add := CurrentConf;
                  '+' : BEGIN
                          Add := '';
                          CursorOn(TRUE);
                        END;
                  '-' : BEGIN
                          Add := '';
                          CursorOn(FALSE);
                        END;
                END;
          'D' : CASE UpCase(S[Index + 2]) OF
                  '1'..'3' :
                        Add := UsrDefStr[Ord(S[Index + 2]) - 48];
                  'A' : Add := DateStr;
                  'B' : Add := FormatNumber(Debit);
                  'D' : Add := FormatNumber(General.DlOneDay[SL]);
                  'H' : Add := PHours('Always allowed',General.DLLowTime,General.DLHiTime);
                  'K' : Add := FormatNumber(DK);
                  'L' : Add := FormatNumber(Downloads);
                  'S' : Add := IntToStr(DSL);
                  'T' : BEGIN
                          IF (Timer > 64800) THEN
                            Add := 'evening'
                          ELSE IF (Timer > 43200) THEN
                            Add := 'afternoon'
                          ELSE
                            Add := 'morning'
                        END;
                END;
          'E' : CASE UpCase(S[Index + 2]) OF
                  'D' : Add := AOnOff((Expiration = 0),'Never',ToDate8(PD2Date(Expiration)));
                  'S' : Add := FormatNumber(EmailSent);
                  'T' : Add := IntToStr(General.EventWarningTime);
                  'W' : Add := FormatNumber(Waiting);
                  'X' : IF (Expiration > 0) THEN
                          Add := IntToStr((Expiration DIV 86400) - (GetPackDateTime DIV 86400))
                        ELSE
                          Add := 'Never';
                END;
          'F' : CASE UpCase(S[Index + 2]) OF
                  '#' : Add := IntToStr(CompFileArea(FileArea,0));
                  'B' : BEGIN
                          LoadFileArea(FileArea);
                          Add := MemFileArea.AreaName;
                        END;
                  'D' : Add := ToDate8(PD2Date(FirstOn));
                  'K' : Add := FormatNumber(DiskFree(ExtractDriveNumber(MemFileArea.ULPath)) DIV 1024);
                  'N' : Add := Copy(RealName,1,(Pos(' ', RealName) - 1));
                  'P' : Add := FormatNumber(FilePoints);
                  'S' : Add := AOnOff(NewScanFileArea,'','not ');
                END;
          'G' : CASE UpCase(S[Index + 2]) OF
                  'N' : AOnOff((Sex = 'M'),'Mr.','Ms.');
                END;
          'H' : CASE UpCase(S[Index + 2]) OF
                  '1' : Add := CTim(General.lLowTime);  (* Verify All CTim *)
                  '2' : Add := CTim(General.HiTime);
                  '3' : Add := CTim(General.MinBaudLowTime);
                  '4' : Add := CTim(General.MinBaudHiTime);
                  '5' : Add := CTim(General.DLLowTime);
                  '6' : Add := CTim(General.DLHiTime);
                  '7' : Add := CTim(General.MinBaudDLLowTime);
                  '8' : add := CTim(General.MinBaudDLHiTime);
                  'M' : Add := IntToStr(HiMsg);
                END;
          'I' : CASE UpCase(S[Index + 2]) OF
                  'L' : Add := IntToStr(Illegal);
                  'P' : Add := ThisUser.CallerID;
                END;
          'K' : CASE UpCase(S[Index + 2]) OF
                  'D' : Add := FormatNumber(General.DLKOneday[SL]);
                  'R' : IF (DK > 0) THEN
                          Str((UK / DK):3:3,Add)
                        ELSE
                          Add := '0';
                END;
          'L' : CASE UpCase(S[Index + 2]) OF
                  'C' : Add := ToDate8(PD2Date(LastOn));
                  'F' : Add := ^M^J;
                  'N' : BEGIN
                          I := Length(RealName);
                          WHILE ((RealName[i] <> ' ') AND (i > 1)) DO
                            Dec(i);
                          Add := Copy(Caps(RealName),(i + 1),255);
                        END;
                  'O' : Add := CityState;
                END;
          'M' : CASE UpCase(S[Index + 2]) OF
                  '#' : Add := IntToStr(CompMsgArea(MsgArea,0));
                  '1' : Add := IntToStr(General.GlobalMenu);
                  '2' : Add := IntToStr(General.AllStartMenu);
                  '3' : Add := IntToStr(General.ShuttleLogonMenu);
                  '4' : Add := IntToStr(General.NewUserInformationMenu);
                  '5' : Add := IntToStr(General.MessageReadMenu);
                  '6' : Add := IntToStr(General.FileListingMenu);
                  '7' : Add := IntToStr(General.MinimumBaud);
                  'B' : BEGIN
                          i := ReadMsgArea;
                          IF (i <> MsgArea) THEN
                            LoadMsgArea(MsgArea);
                          Add := MemMsgArea.Name;
                        END;
                  'L' : Add := IntToStr(NSL DIV 60);
                  'N' : Add := ShowOnOff(General.MultiNode);
                  'O' : Add := IntToStr((GetPackDateTime - TimeOn) DIV 60);
                  'R' : Add := IntToStr(HiMsg - Msg_On);
                  'S' : Add := AOnOff(LastReadRecord.NewScan,'','not ');
                END;
          'N' : CASE UpCase(S[Index + 2]) OF
                  'D' : Add := IntToStr(ThisNode);
                  'M' : Add := ShowOnOff(General.NetworkMode);
                  'R' : IF (Downloads > 0) THEN
                          Str((Uploads / Downloads):3:3,Add)
                        ELSE
                          Add := '0';
                END;
          'O' : CASE UpCase(S[Index + 2]) OF
                  '1' : IF (RIP IN SFlags) THEN
                          Add := 'RIP'
                        ELSE IF (Avatar IN Flags) THEN
                          Add := 'Avatar'
                        ELSE IF (ANSI IN Flags) THEN
                          Add := 'ANSI'
                        ELSE IF (VT100 IN Flags) THEN
                          Add := 'VT-100'
                        ELSE
                          Add := 'None';
                  '2' : Add := IntToStr(LineLen)+'x'+IntToStr(PageLen);
                  '3' : Add := ShowOnOff(ClsMsg IN SFlags);
                  '4' : Add := ShowOnOff(FSEditor IN SFlags);
                  '5' : Add := ShowOnOff(Pause IN Flags);
                  '6' : Add := ShowOnOff(HotKey IN Flags);
                  '7' : Add := ShowOnOff(NOT (Novice IN Flags));
                  '8' : IF (ForUsr > 0) THEN
                          Add := 'Forwarded - '+IntToStr(ForUsr)
                        ELSE IF (Nomail IN Flags) THEN
                          Add := 'Closed'
                        ELSE
                          Add := 'Open';
                  '9' : Add := ShowOnOff(Color IN Flags);
                END;
          'P' : CASE UpCase(S[Index + 2]) OF
                  '1' : Add := General.MsgPath;
                  '2' : Add := General.NodePath;
                  '3' : Add := General.LMultPath;
                  '4' : Add := General.SysOpPW;
                  '5' : Add := General.NewUserPW;
                  '6' : Add := General.MinBaudOverride;
                  '7' : Add := General.ArcsPath;
                  'B' : Add := General.BulletPrefix;
                  'C' : IF (LoggedOn > 0) THEN
                          Str((MsgPost / LoggedOn) * 100:3:2,Add)
                        ELSE
                          Add := '0';
                  'D' : Add := General.DataPath;
                  'F' : Add := General.FileAttachPath;
                  'L' : Add := General.LogsPath;
                  'M' : Add := General.MiscPath;
                  'N' : Add := Ph;
                  'O' : BEGIN
                          IF (PrintingFile) OR (Reading_A_Msg) THEN
                            TempPause := FALSE;
                          Add := '';
                        END;
                  'P' : Add := General.ProtPath;
                  'S' : Add := FormatNumber(MsgPost);
                  'T' : Add := General.TempPath;
                END;
          'Q' : CASE UpCase(S[Index + 2]) OF
                  'D' : Add := IntToStr(NumBatchDLFiles);
                  'U' : Add := IntToStr(NumBatchULFiles);
                END;
          'R' : CASE UpCase(S[Index + 2]) OF
                  'N' : Add := Caps(RealName);
                END;
          'S' : CASE UpCase(S[Index + 2]) OF
                  '1' : Add := lRGLngStr(41,TRUE); {FString.UserDefEd[Ord(S[Index + 2]) - 48]; }
                  '2' : Add := lRGLngStr(42,TRUE); {FString.UserDefEd[Ord(S[Index + 2]) - 48]; }
                  '3' : Add := lRGLngStr(43,TRUE); {FString.UserDefEd[Ord(S[Index + 2]) - 48]; }
                  'C' : Add := FormatNumber(General.CallerNum);
                  'L' : Add := IntToStr(SL);
                  'N' : Add := General.SysopName;
                  'X' : Add := AOnOff((Sex = 'M'),'Male','Female');
                END;
          'T' : CASE UpCase(S[Index + 2]) OF
                  '1' : Add := FormatNumber(General.TimeAllow[SL]);
                  'A' : Add := FormatNumber(TimeBankAdd);
                  'B' : Add := FormatNumber(TimeBank);
                  'C' : Add := FormatNumber(LoggedOn);
                  'D' : Add := FormatNumber(DLToday);
                  'I' : Add := TimeStr;
                  'K' : Add := ConvertBytes(DLKToday * 1024,FALSE);
                  'L' : Add := CTim(NSL);
                  'N' : Add := Liner.NodeTelnetURL;
                  'O' : Add := IntToStr(General.TimeAllow[SL] - TLToday);
                  'T' : Add := FormatNumber(TTimeOn);
                  'U' : Add := IntToStr(General.NumUsers);
                END;
          'U' : CASE UpCase(S[Index + 2]) OF
                  'A' : Add := IntToStr(AgeUser(BirthDate));
                  'B' : Add := ToDate8(PD2Date(BirthDate));
                  'C' : Add := IntToStr(OnToday);
                  'F' : Add := FormatNumber(Feedback);
                  'K' : Add := FormatNumber(UK);
                  'L' : Add := FormatNumber(Uploads);
                  'M' : Add := IntToStr(MaxUsers - 1);
                  'N' : Add := Caps(Name);
                  'U' : Add := IntToStr(UserNum);
                END;
          'V' : CASE UpCase(S[Index + 2]) OF
                  'R' : Add := General.Version;
                END;
          'Z' : CASE UpCase(S[Index + 2]) OF
                  'P' : Add := ZipCode;
                END;
        END;
      Temp := Temp + Add;
      Inc(Index,2);
    END
  ELSE
    Temp := Temp + S[Index];
  MCI := Temp;
END;

PROCEDURE BackErase(Len: Byte);
VAR
  Counter: Byte;
BEGIN
  IF (OkANSI) OR (OkVT100) THEN
    SerialOut(^[+'['+IntToStr(Len)+'D'+^[+'[K')
  ELSE IF (OkAvatar) THEN
  BEGIN
    FOR Counter := 1 TO Len DO
      Com_Send(^H);
    SerialOut(^V^G);
  END
  ELSE
    FOR Counter := 1 TO Len DO
    BEGIN
      Com_Send(^H);
      Com_Send(' ');
      Com_Send(^H);
    END;
  GotoXY((WhereX - Len),WhereY);
  ClrEOL;
END;

FUNCTION DiskKBFree(DrivePath: AStr): LongInt;
VAR
  F: TEXT;
{$IFDEF MSDOS}
  Regs: Registers;
{$ENDIF}
  S,
  S1: STRING;
  Counter: Integer;
  C,
  C1,
  C2: Comp;
BEGIN
  C2 := 0.0;                                (* RGCMD *)
  SwapVectors;
  Exec(GetEnv('RGCMD'),' /C DIR '+DrivePath[1]+': > FREE.TXT');
  SwapVectors;
  IF (EXIST('FREE.TXT')) THEN
  BEGIN
    Assign(F,'FREE.TXT');
    Reset(F);
    WHILE NOT EOF(F) DO
    BEGIN
      ReadLn(F,S);
      IF (Pos('bytes free',s) <> 0) THEN
      BEGIN
        WHILE (S[1] = ' ') DO
          Delete(S,1,1);
        Delete(S,1,Pos(')',s));
        WHILE (S[1] = ' ') DO
          Delete(S,1,1);
        S := COPY(S,1,Pos(' ',S) - 1);
        S1 := '';
        FOR Counter := 1 TO Length(S) DO
          IF (S[Counter] <> ',') THEN
            S1 := S1 + S[Counter];
      END;
    END;
    Close(F);
    Erase(F);
    Val(S1,C2,Counter);
  END
  ELSE
  BEGIN
{$IFDEF MSDOS}  
    FillChar(Regs,SizeOf(Regs),#0);
    Regs.Ah := $36;
    Regs.Dl := ExtractDriveNumber(DrivePath);
    Intr($21,Regs);
    C := (1.0 * Regs.Ax);
    C1 := ((1.0 * Regs.Cx) * C);
    C2 := ((1.0 * Regs.Bx) * C1);
{$ENDIF}
{$IFDEF WIN32}
    C2 := DiskFree(ExtractDriveNumber(DrivePath));
{$ENDIF}
  END;
  DiskKBFree := Round(C2 / 1024.0);
END;

FUNCTION IntToStr(L: LongInt): STRING;
VAR
  S: STRING[11];
BEGIN
  Str(L,S);
  IntToStr := S;
END;

PROCEDURE MyDelay(WaitFor: LongInt);
VAR
  CheckMS: LongInt;
BEGIN
  CheckMS := (Ticks + WaitFor);
  REPEAT
  UNTIL (Ticks > CheckMS);
END;

END.
