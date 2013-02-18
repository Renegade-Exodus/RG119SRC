{$IFDEF WIN32}
{$I DEFINES.INC}
{$ENDIF}

{$A+,B-,D-,E-,F+,I-,L-,N-,O+,R-,S+,V-}

UNIT Nodelist;

INTERFACE

USES
  Common;

PROCEDURE ToggleNetAttr(NetAttrT: NetAttr; VAR NetAttrS: NetAttribs);
PROCEDURE ToggleNetAttrs(C: CHAR; VAR NetAttrS: NetAttribs);
FUNCTION GetNewAddr(DisplayStr: AStr; MaxLen: Byte; VAR Zone,Net,Node,Point: SmallWord): Boolean;
PROCEDURE GetNetAddress(VAR SysOpName: AStr; VAR Zone,Net,Node,Point: SmallWord; var Fee: Word; GetFee: Boolean);
PROCEDURE ChangeFlags(VAR MsgHeader: MHeaderRec);
FUNCTION NetMail_Attr(NetAttribute: NetAttribs): AStr;

IMPLEMENTATION

USES
  Mail0;

TYPE
  CompProc = FUNCTION(VAR ALine,Desire; L: Char): Integer;

  DATRec = RECORD
    Zone, 											{ Zone of board 							}
    Net,												{ Net Address of board				}
    Node, 											{ Node Address of board 			}
    Point: SmallInt;				{ Either Point number OR 0		}
    CallCost, 									{ Cost to sysop to send 			}
    MsgFee, 										{ Cost to user to send				}
    NodeFlags: SmallWord; 				{ Node flags									}
    ModemType,									{ Modem TYPE									}
    PassWord: STRING[9];
    Phone,
    BName,
    CName,
    SName: STRING[39];
    BaudRate,    				{ Highest Baud Rate 					}
    RecSize: Byte; 				{ Size of the Node on FILE		}
  END;

  IndxRefBlk = RECORD
    IndxOfs,  		{ Offset of STRING into block }
    IndxLen: SmallWord; 	{ Length of STRING						}
    IndxData,         	{ RECORD number of STRING 		}
    IndxPtr: LongInt;	{ Block number of lower index }
  END;  { IndxRef }

  LeafRefBlk = RECORD
    KeyOfs,  		{ Offset of STRING into block }
    KeyLen: SmallWord;	{ Length of STRING						}
    KeyVal: LongInt;	{ Pointer to Data block 			}
  END; 	{ LeafRef }

  CtlBlk = RECORD
    CtlBlkSize: SmallWord; 	{ blocksize of Index blocks 	}
    CtlRoot,										{ Block number of Root				}
    CtlHiBlk, 									{ Block number of last block	}
    CtlLoLeaf,		{ Block number of first leaf	}
    CtlHiLeaf,		{ Block number of last leaf 	}
    CtlFree: LongInt;	{ Head of freelist						}
    CtlLvls, 		{ Number of index levels			}
    CtlParity: SmallWord; 	{ XOR of above fields 				}
  END;

  INodeBlk = RECORD
    IndxFirst,			{ Pointer to next lower level }
    IndxBLink,			{ Pointer to previous link		}
    IndxFLink: LongInt;			{ Pointer to next link				}
    IndxCnt: SmallInt;			{ Count of Items IN block 		}
    IndxStr: SmallWord; 				{ Offset IN block of 1st str	}
								{ IF IndxFirst is NOT -1, this is INode:	}
    IndxRef: ARRAY [0..49] OF IndxRefBlk;
  END;

  LNodeBlk = RECORD
    IndxFirst,			{ Pointer to next lower level }
    IndxBLink,			{ Pointer to previous link		}
    IndxFLink: LongInt;			{ Pointer to next link				}
    IndxCnt: SmallInt;			{ Count of Items IN block 		}
    IndxStr: SmallWord; 				{ Offset IN block of 1st str	}
    LeafRef: ARRAY [0..49] OF LeafRefBlk;
  END;

PROCEDURE ToggleNetAttr(NetAttrT: NetAttr; VAR NetAttrS: NetAttribs);
BEGIN
  IF (NetAttrT IN NetAttrS) THEN
    Exclude(NetAttrS,NetAttrT)
  ELSE
    Include(NetAttrS,NetAttrT);
END;

PROCEDURE ToggleNetAttrs(C: CHAR; VAR NetAttrS: NetAttribs);
BEGIN
  CASE C OF
    'C' : ToggleNetAttr(Crash,NetAttrS);
    'H' : ToggleNetAttr(Hold,NetAttrS);
    'I' : ToggleNetAttr(InTransit,NetAttrS);
    'K' : ToggleNetAttr(KillSent,NetAttrS);
    'L' : ToggleNetAttr(Local,NetAttrS);
    'P' : ToggleNetAttr(Private,NetAttrS);
  END;
END;

FUNCTION GetNewAddr(DisplayStr: AStr; MaxLen: Byte; VAR Zone,Net,Node,Point: SmallWord): Boolean;
BEGIN
  GetNewAddr := FALSE;
  Prt(DisplayStr);
  MPL(MaxLen);
  Input(DisplayStr,MaxLen);
  IF (DisplayStr = '') OR (Pos('/',DisplayStr) = 0) THEN
    Exit;
  IF (Pos(':',DisplayStr) > 0) THEN
  BEGIN
    Zone := StrToInt(Copy(DisplayStr,1,Pos(':',DisplayStr)));
    DisplayStr := Copy(DisplayStr,Pos(':',DisplayStr)+1,Length(DisplayStr));
  END
  ELSE
    Zone := 1;
  IF (Pos('.',DisplayStr) > 0) THEN
  BEGIN
    Point := StrToInt(Copy(DisplayStr,Pos('.',DisplayStr)+1,Length(DisplayStr)));
    DisplayStr := Copy(DisplayStr,1,Pos('.',DisplayStr)-1);
  END
  ELSE
    Point := 0;
  Net := StrToInt(Copy(DisplayStr,1,Pos('/',DisplayStr)));
  Node := StrToInt(Copy(DisplayStr,Pos('/',DisplayStr)+1,Length(DisplayStr)));
  GetNewAddr := TRUE;
END;

FUNCTION NetMail_Attr(NetAttribute: NetAttribs): Astr;
VAR
  s: AStr;
BEGIN
  s := '';
  IF (Local IN NetAttribute) THEN
    s := 'Local ';
  IF (Private IN NetAttribute) THEN
    s := s + 'Private ';
  IF (Crash IN NetAttribute) THEN
    s := s + 'Crash ';
  IF (FileAttach IN NetAttribute) THEN
    s := s + 'FileAttach ';
  IF (InTransit IN NetAttribute) THEN
    s := s + 'InTransit ';
  IF (KillSent IN NetAttribute) THEN
    s := s + 'KillSent ';
  IF (Hold IN NetAttribute) THEN
    s := s + 'Hold ';
  IF (FileRequest IN NetAttribute) THEN
    s := s + 'File Request ';
  IF (FileUpdateRequest IN NetAttribute) THEN
    s := s + 'Update Request ';
  NetMail_Attr := s;
END;

FUNCTION CompName(VAR ALine,Desire; L: Char): Integer;
VAR
  Key,
  Desired: STRING[36];
  Len: Byte ABSOLUTE L;
BEGIN
  Key[0] := L;
  Desired[0] := L;
  Move(ALine,Key[1],Len);
  Move(Desire,Desired[1],Len);
  IF (Key > Desired) THEN
    CompName := 1
  ELSE IF (Key < Desired) THEN
    CompName := -1
  ELSE
    CompName := 0;
END;

FUNCTION CompAddress(VAR ALine,Desire; L: Char): Integer;
TYPE
  NodeType = RECORD
    Zone,
    Net,
    Node,
    Point: SmallWord;
  END;
VAR
  Key: NodeType ABSOLUTE ALine;
  Desired: NodeType ABSOLUTE Desire;
  Count: Byte;
  K: Integer;
BEGIN
  Count := 0;
  REPEAT
    Inc(Count);
    CASE Count OF
      1 : Word(K) := Key.Zone - Desired.Zone;
      2 : Word(K) := Key.Net  - Desired.Net;
      3 : Word(K) := Key.Node - Desired.Node;
      4 : BEGIN
            IF (L = #6) THEN
              Key.Point := 0;
            Word(K) := Key.Point - Desired.Point;
          END;
    END;
  UNTIL (Count = 4) OR (K <> 0);
  Compaddress := K;
END;

PROCEDURE GetNetAddress(VAR SysOpName: AStr; VAR Zone,Net,Node,Point: SmallWord; var Fee: Word; GetFee: Boolean);
VAR
  DataFile,
  NDXFile: FILE;
  s: STRING[36];
  Location: LongInt;
  Dat: DatRec;
  Internet: Boolean;

  FUNCTION FullNodeStr(NodeStr: AStr): STRING;
  { These constants are the defaults IF the user does NOT specify them }
  CONST
    DefZone = '1';          { Default Zone  }
    DefNet = '1';         { Default Net   }
    DefNode = '1';          { Default Node  }
    DefPoint = '0';         { Default Point }
  BEGIN
    IF (NodeStr[1] = '.') THEN
      NodeStr := DefNode + NodeStr;
    IF (Pos('/',NodeStr) = 0) THEN
      IF (Pos(':',NodeStr) = 0) THEN
        NodeStr := DefZone+':'+DefNet+'/'+NodeStr
      ELSE
    ELSE
    BEGIN
      IF (NodeStr [1] = '/') THEN
        NodeStr := DefNet + NodeStr;
      IF (Pos(':',NodeStr) = 0) THEN
        NodeStr := DefZone + ':' + NodeStr;
      IF (NodeStr[Length(NodeStr)] = '/') THEN
        NodeStr := NodeStr + DefNode;
    END;
    IF (Pos('.',NodeStr) = 0) THEN
      NodeStr := NodeStr+'.'+DefPoint;
    FullNodeStr := NodeStr;
  END;

  FUNCTION MakeAddress(Z,Nt,N,P: Word): STRING;
  TYPE
    NodeType = RECORD 			{ A Node address TYPE }
      Len: Byte;
      Zone,
      Net,
      Node,
      Point: SmallWord;
    END;
  VAR
    Address: NodeType;
    S2: STRING ABSOLUTE Address;
  BEGIN
    WITH Address DO
    BEGIN
      Zone := Z;
      Net := Nt;
      Node := N;
      Point := P;
      Len := 8;
    END;
    MakeAddress := S2;
  END;

  FUNCTION MakeName(Name: AStr): STRING;
  VAR
    Temp: STRING[36];
    Comma: STRING[2];
  BEGIN
    Temp := Caps(Name);
    IF (Pos(' ', Name) > 0) THEN
      Comma := ', '
    ELSE
      Comma := '';
    MakeName := Copy(Temp, Pos(' ',Temp) + 1, Length(Temp) - Pos(' ',Temp))
                     + Comma + Copy(Temp,1,Pos(' ',Temp) - 1) + #0;
  END;

  PROCEDURE UnPk(S1: STRING; VAR S2: STRING; Count: Byte);
  CONST
    UnWrk: ARRAY [0..38] OF Char = ' EANROSTILCHBDMUGPKYWFVJXZQ-''0123456789';
  TYPE
    CharType = RECORD
      C1,
      C2: Byte;
    END;
  VAR
    U: CharType;
    W1: Word ABSOLUTE U;
    I,
    J: Integer;
    OBuf: ARRAY [0..2] OF Char;
    Loc1,
    Loc2: Byte;
  BEGIN
    S2 := '';
    Loc1 := 1;
    Loc2 := 1;
    WHILE (Count > 0) DO
    BEGIN
      U.C1 := Ord(S1[Loc1]);
      Inc(Loc1);
      U.C2 := Ord(S1[Loc1]);
      Inc(Loc1);
      Count := Count - 2;
      for J := 2 downto 0 DO
      BEGIN
        I := W1 MOD 40;
        W1 := W1 DIV 40;
        OBuf[J] := UnWrk[I];
      END;
      Move(OBuf,S2[Loc2],3);
      Inc(Loc2,3);
    END;
    S2[0] := Chr(Loc2);
  END;

  FUNCTION GetData(VAR F1: FILE; SL: LongInt; VAR Dat: DATRec): Boolean;
  TYPE
    RealDATRec = RECORD
      Zone, 											{ Zone of board 							}
      Net,												{ Net Address of board				}
      Node, 											{ Node Address of board 			}
      Point: SmallInt;				{ Either Point number OR 0		}
      CallCost, 									{ Cost to sysop to send 			}
      MsgFee, 										{ Cost to user to send				}
      NodeFlags: SmallWord; 				{ Node flags									}
      ModemType,									{ Modem TYPE									}
      PhoneLen, 									{ Length of Phone Number			}
      PassWordLen,								{ Length of Password					}
      BNameLen, 									{ Length of Board Name				}
      SNameLen, 									{ Length of Sysop Name				}
      CNameLen, 									{ Length of City/State Name 	}
      PackLen,										{ Length of Packed STRING 		}
      Baud: Byte; 				{ Highest Baud Rate 					}
      Pack: ARRAY [1..160] of Char;		{ The Packed STRING 					}
    END;
  VAR
    Data: RealDATRec;
    Error: Boolean;
    UnPack: STRING[160];
  BEGIN
    Seek(F1,SL);
    { Read everything at once to keep disk access to a minimum }
    BlockRead(F1,Data,SizeOf(Data));
    Error := (IOResult <> 0);
    IF (NOT Error) THEN
      WITH Dat,Data DO
      BEGIN
        Move(Data,Dat,15);
        Phone := Copy(Pack,1,PhoneLen);
        PassWord := Copy(Pack,(PhoneLen + 1),PasswordLen);
        Move(Pack[PhoneLen + PasswordLen + 1],Pack[1],PackLen);
        UnPk(Pack,UnPack,PackLen);
        BName := Caps(Copy(UnPack,1,BNameLen));
        SName := Caps(Copy(Unpack,(BNameLen + 1),SNameLen));
        CName := Caps(Copy(UnPack,BNameLen + SNameLen + 1,CNameLen));
        BaudRate := Baud;
        RecSize := (PhoneLen + PassWordLen + PackLen) + 22;
      END;
  END;

  PROCEDURE Get7Node(VAR F: FILE; SL: LongInt; VAR Buf);
  BEGIN
    Seek(F,SL);
    BlockRead(F,Buf,512);
    IF (IOResult <> 0) THEN
      Halt(1);
  END;

  FUNCTION BTree(VAR F1: FILE; Desired: AStr; Compare: CompProc): LongInt;
  LABEL
    Return;
  VAR
    Buf: ARRAY [0..511] OF Char; 	{ These four variables all occupy 	}
    CTL: CTLBlk ABSOLUTE Buf;			{ the same memory location.  Total	}
    INode: INodeBlk ABSOLUTE Buf;		{ of 512 bytes. 										}
    LNode: LNodeBlk ABSOLUTE Buf;		{ --------------------------------- }
    NodeCTL: CTLBlk; 									{ Store the CTL block seperately		}
    ALine: STRING[160];							{ Address from NDX FILE 						}
    J,
    K,
    L,Count: Integer;									{ Temp integers 										}
    TP: Word; 										{ Pointer to location IN BUF				}
    Rec,									{ A temp RECORD IN the FILE 				}
    FRec: LongInt;									{ The RECORD when found OR NOT			}
  BEGIN
    FRec := -1;
    Get7Node(F1,0,Buf);
    IF (CTL.CTLBlkSize = 0) THEN GOTO
      Return;
    Move(Buf,NodeCTL,SizeOf(CTL));
    Get7Node(F1,NodeCTL.CtlRoot * NodeCTL.CtlBlkSize,Buf);
    WHILE (INode.IndxFirst <> -1) AND (FRec = -1) DO
    BEGIN
      Count := INode.IndxCnt;
      IF (Count = 0) THEN GOTO
        Return;
      J := 0;
      K := -1;
      WHILE (J < Count) AND (K < 0) DO
      BEGIN
        TP := INode.IndxRef[J].IndxOfs;
        L := INode.IndxRef[J].IndxLen;
        { ALine [0] := Chr (L); }
        Move(Buf[TP],ALine[1],L);
        K := Compare(ALine[1],Desired[1],Chr(L));
        IF (K = 0) THEN
          FRec := INode.IndxRef[J].IndxData
        ELSE IF (K < 0) THEN
          Inc(J);
      END;
      IF (FRec = -1) THEN
      BEGIN
        IF (J = 0) THEN
          Rec := INode.IndxFirst
        ELSE
          Rec := INode.IndxRef[J - 1].IndxPtr;
        Get7Node(F1,Rec * NodeCTL.CtlBlkSize,Buf);
      END;
    END;
    IF (FRec = -1) THEN
    BEGIN
      Count := LNode.IndxCnt;
      IF (Count <> 0) THEN
      BEGIN
        J := 0;
        WHILE (J < Count) AND (FRec = -1) DO
        BEGIN
          TP := LNode.LeafRef[J].KeyOfs;
          L := LNode.LeafRef[J].KeyLen;
          { ALine [0] := Chr (L); }
          Move(Buf[TP],ALine[1],L);
          K := Compare(ALine[1],Desired[1],Chr(L));
          IF (K = 0) THEN
            FRec := LNode.LeafRef[J].KeyVal;
          Inc(J);
        END;
      END;
    END;
    Return :
    BTree := FRec;
  END;

  FUNCTION Pull(VAR S: STRING; C: Char): STRING;
  VAR
    I: Byte;
  BEGIN
    I := Pos(C,S);
    Pull := Copy(S,1,(I - 1));
    Delete(S,1,I);
  END;

BEGIN
  NL;
  Internet := FALSE;
  IF NOT Exist(General.NodePath+'NODEX.DAT') OR
     NOT Exist(General.NodePath+'SYSOP.NDX') OR
     NOT Exist(General.NodePath+'NODEX.NDX') THEN
  BEGIN
    IF (GetFee) THEN
    BEGIN
      Fee := 0;
      Exit;
    END;
    Print('Enter name of intended receiver.');
    Prt(':');
    InputDefault(SysOpName,SysOpName,36,[CapWords],TRUE);
    IF (SysOpName = '') THEN
      Exit;
    IF (Pos('@',SysOpName) > 0) THEN
      IF (PYNQ('Is this an Internet message? ',0,FALSE)) THEN
      BEGIN
        Internet := TRUE;
        Zone := General.Aka[20].Zone;
        Net := General.Aka[20].Net;
        Node := General.Aka[20].Node;
        Point := General.Aka[20].Point;
        Fee := 0;
        Exit;
      END
      ELSE
        NL;
    IF NOT GetNewAddr('Enter network address (^5Z^4:^5N^4/^5N^4.^5P^4 format): ',30,Zone,Net,Node,Point) THEN
      Exit;
    Exit;
  END;
  Assign(DataFile,General.NodePath+'NODEX.DAT');
  IF (GetFee) THEN
  BEGIN
    s := IntToStr(Net)+'/'+IntToStr(Node);
    IF (Zone > 0) THEN
      s := IntToStr(Zone)+':'+s;
    IF (Point > 0) THEN
      s := s+'.'+IntToStr(Point);
    s := FullNodeStr(s);
    Assign(NDXFile,General.NodePath+'NODEX.NDX');
    Reset(NDXFile,1);
    Location := BTree(NDXFile,MakeAddress(StrToInt(Pull(S,':')),
                      StrToInt(Pull(S,'/')),StrToInt(Pull(S,'.')),
                      StrToInt(S)),Compaddress);
    Close(NDXFile);
    IF (Location <> -1) THEN
    BEGIN
      Reset(DataFile,1);
      GetData(DataFile,Location,Dat);
      Close(DataFile);
      Fee := Dat.MsgFee;
    END
    ELSE
      Fee := 0;
    Exit;
  END;
  s := SysOpName;
  SysOpName := '';
  Fee := 0;
  REPEAT
    Print('Enter a name, a Fidonet address, or an Internet address.');
    Prt(':');
    InputDefault(s,s,36,[],TRUE);
    IF (s = '') THEN
      Break;
    IF (Pos('/',s) > 0) THEN
    BEGIN
      s := FullNodeStr(s);
      Assign(NDXFile,General.NodePath+'NODEX.NDX');
      Reset(NDXFile,1);
      Location := BTree(NDXFile,MakeAddress(StrToInt(Pull(S,':')),StrToInt(Pull(S,'/')),StrToInt(Pull(S,'.')),StrToInt(S)),
                        Compaddress);
      Close(NDXFile);
    END
    ELSE
    BEGIN
      Assign(NDXFile,General.NodePath+'SYSOP.NDX');
      Reset(NDXFile,1);
      Location := BTree(NDXFile,MakeName(S),CompName);
      Close(NDXFile);
    END;
    IF (Location <> -1) THEN
    BEGIN
      Reset(DataFile,1);
      GetData(DataFile,Location,Dat);
      Close(DataFile);
      WITH Dat DO
      BEGIN
        Print('^1System: '+BName+' ('+IntToStr(Zone)+':'+IntToStr(Net)+'/'+IntToStr(Node)+')');
        Print('SysOp : '+SName);
        Print('Phone : '+Phone);
        Print('Where : '+CName);
        Print('Cost  : '+IntToStr(MsgFee)+' credits');
      END;
      NL;
      IF (Dat.MsgFee > (ThisUser.lCredit - ThisUser.Debit)) THEN
      BEGIN
        Print('You do not have enough credit to netmail this Node!');
        s := '';
      END
      ELSE IF PYNQ('Is this correct? ',0,FALSE) THEN
      BEGIN
        SysOpName := Dat.Sname;
        Zone := Dat.Zone;
        Net := Dat.Net;
	Node := Dat.Node;
        Point := 0;
        Fee := Dat.MsgFee;
      END
      ELSE
        s := '';
    END
    ELSE IF (Pos('@',s) > 0) THEN
      IF (NOT PYNQ('Is this an Internet message? ',0,FALSE)) THEN
      BEGIN
        Print('That name is not in the nodelist!'^M^J);
        S := '';
      END
      ELSE
      BEGIN
        Internet := TRUE;
        SysOpName := s;
        Zone := General.Aka[20].Zone;
        Net := General.Aka[20].Net;
        Node := General.Aka[20].Node;
        Point := General.Aka[20].Point;
        Fee := 0;
      END
      ELSE
      BEGIN
        Print('That name is not in the nodelist!'^M^J);
        S := '';
      END
  UNTIL (SysOpName <> '') OR (HangUp);
  IF (NOT Internet) AND (Pos('/',s) = 0) AND (s <> '') THEN
  BEGIN
    NL;
    Print('Enter name of intended receiver.');
    Prt(':');
    InputDefault(SysOpName,SysOpName,36,[CapWords],FALSE);
    IF (SysOpName = '') THEN
      Exit;
  END;
  LastError := IOResult;
END;

PROCEDURE ChangeFlags(VAR MsgHeader: MHeaderRec);
VAR
  Cmd: Char;
BEGIN
  IF (CoSysOp) AND (PYNQ('Change default netmail flags? ',0,FALSE)) THEN
  BEGIN
    Cmd := #0;
    NL;
    REPEAT
      IF (Cmd <> '?') THEN
      BEGIN
        Print('^4Current flags: ^5'+NetMail_Attr(MsgHeader.NetAttribute));
        NL
      END;
      Prt('Flag to change: ');
      OneK(Cmd,'QPCAIKHRLU?'^M,TRUE,TRUE);
      IF (Cmd IN ['?']) THEN
        NL;
      WITH MsgHeader DO
        CASE Cmd OF
          'L' : ToggleNetAttr(Local,NetAttribute);
          'U' : ToggleNetAttr(FileUpdateRequest,NetAttribute);
          'R' : ToggleNetAttr(FileRequest,NetAttribute);
          'H' : ToggleNetAttr(Hold,NetAttribute);
          'K' : ToggleNetAttr(KillSent,NetAttribute);
          'I' : ToggleNetAttr(InTransit,NetAttribute);
          'A' : ToggleNetAttr(FileAttach,NetAttribute);
          'C' : ToggleNetAttr(Crash,NetAttribute);
          'P' : ToggleNetAttr(Private,NetAttribute);
          '?' : BEGIN
                  LCmds3(15,3,'Private','Crash','Attached File');
                  LCmds3(15,3,'InTransit','KillSent','Hold');
                  LCmds3(15,3,'Req file','Update Req','Local');
                END;
        END;
    UNTIL (Cmd IN ['Q',^M]) OR (HangUp);
  END;
  NL;
END;

END.
