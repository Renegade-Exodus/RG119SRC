PROGRAM Renemail;       {eatus echomailius}

{$A+,I-,E-,F+}

(* {A+,B-,D-,E-,F+,G+,N-,R-,S-,V-,I-} *)

uses crt, dos, timefunc;

{$I RECORDS.PAS}

type
  fidorecord = record
    FromUserName : string[35];
    ToUserName   : string[35];
    Subject      : string[71];
    DateTime     : string[19];
    TimesRead    : word;
    DestNode     : word;
    OrigNode     : word;
    Cost         : word;
    OrigNet      : word;
    DestNet      : word;
    Filler       : array[1..8] of char;
    Replyto      : word;
    Attribute    : word;
    NextReply    : word;
  END;

VAR
    LastError :integer;
    header : fidorecord;
    dt : datetime;
    MsgTFile : file;
    hiwaterf : file of integer;
    statusf : file of generalrecordtype;
    statusr : generalrecordtype;
    boardf : file of MessageAreaRecordType;
    BoardR : MessageAreaRecordType;
    MsgHdrF : file of mheaderrec;
    MsgHdr : mheaderrec;
    MsgTxtF : file;
    uf : file of userrecordtype;
    user : userrecordtype;
    sf : file of useridxrec;
    toi, fromi, subjecti, datetime : string;
    i, j, lines, MsgNumber, highest, lowest, Board, TextSize,
    msglength, msgpointer : integer;
    c : char;
    attribute : word;
    ispm : boolean;
    dirinfo : searchrec;
    s, StartDir, nos, datapath, MsgPath, netmailpath : string [81];
    MsgTxt : string [255];
    buffer : array [1..32767] of char;
    fcb : array [1..37] of char;
{$IFDEF MSDOS}
    Regs : registers;
{$ENDIF}
    x : byte;

const
  netmailonly : boolean = FALSE;
  IsNetMail : boolean = FALSE;
  fastpurge : boolean = TRUE;
  process_netmail : boolean = TRUE;
  purge_netmail : boolean = TRUE;
  absolute_scan : boolean = FALSE;
  ignore_1msg : boolean = TRUE;

FUNCTION Hex(i : longint; j:byte) : String;
const
  hc : array[0..15] of Char = '0123456789ABCDEF';
VAR
  one,two,three,four: Byte;
BEGIN
  one   := (i AND $000000FF);
  two   := (i AND $0000FF00) SHR 8;
  three := (i AND $00FF0000) SHR 16;
  four  := (i AND $FF000000) SHR 24;

  Hex[0] := chr(j);          { Length of String = 4 or 8}
  IF (j = 4) THEN
    BEGIN
      Hex[1] := hc[two SHR 4];
      Hex[2] := hc[two AND $F];
      Hex[3] := hc[one SHR 4];
      Hex[4] := hc[one AND $F];
    END
  ELSE
    BEGIN
      Hex[8] := hc[one AND $F];
      Hex[7] := hc[one SHR 4];
      Hex[6] := hc[two AND $F];
      Hex[5] := hc[two SHR 4];
      hex[4] := hc[three AND $F];
      hex[3] := hc[three SHR 4];
      hex[2] := hc[four AND $F];
      hex[1] := hc[four SHR 4];
    END;
END {Hex} ;

FUNCTION Usename(b:byte; s:astr):string;
BEGIN
  case b of
    1,
    2:s:='Anonymous';
    3:s:='Abby';
    4:s:='Problemed Person';
  END;
  Usename:=s;
END;

FUNCTION ExistDir(fn:string):boolean;
VAR dirinfo:searchrec;
BEGIN
  WHILE (fn[Length(fn)] = '\') DO
    Dec(fn[0]);
  findfirst(fn,anyfile,dirinfo);
  ExistDir:=(doserror=0) AND (dirinfo.attr AND $10=$10);
END;

FUNCTION StrPas(Str: String): String; assembler;
asm
        PUSH    DS
        CLD
        LES     DI,Str
        MOV     CX,0FFFFH
        XOR     AL,AL
        REPNE   SCASB
        NOT     CX
        Dec     CX
        LDS     SI,Str
        LES     DI,@Result
        MOV     AL,CL
        STOSB
        REP     MOVSB
        POP     DS
END;


FUNCTION StripName(s:astr):astr;
VAR
  n:integer;
BEGIN
  n := Length(s);
  WHILE (n > 0) AND (POS(s[n],':\/') = 0) DO
    Dec(n);
  Delete(s,1,n);
  StripName := s;
END;

FUNCTION AllCaps (const s : string) : string;
VAR
  q : integer;
BEGIN
  AllCaps [0] := s [0];
  FOR q := 1 TO Length (s) DO
    AllCaps [q] := upcase (s [q]);
END;

FUNCTION Caps (s : string) : string;
VAR
  i : integer;
BEGIN
  FOR i := 1 TO Length (s) DO
    IF (s [i] in ['A'..'Z']) THEN
       s [i] := chr (ord (s [i]) + 32);

  FOR i := 1 TO Length (s) DO
    IF (NOT (s [i] in ['A'..'Z', 'a'..'z', chr (39) ]) ) THEN
      IF (s [i + 1] in ['a'..'z']) THEN
         s [i + 1] := upcase (s [i + 1]);
  s [1] := upcase (s [1]);
  Caps := s;
END;

FUNCTION searchuser(Uname:string): word;
VAR
  Current:integer;
  Done:boolean;
  IndexR:useridxrec;
BEGIN

  Reset(sf);
  IF (IOResult > 0) THEN Exit;

  Uname := AllCaps(UName);

  Current := 0;
  Done := FALSE;

  IF (FileSize(sf) > 0) THEN BEGIN
    REPEAT
      Seek(sf, Current);
      Read(sf, IndexR);
      IF (Uname < IndexR.Name) THEN BEGIN Current := IndexR.Left END
      ELSE BEGIN
        IF (Uname > IndexR.Name) THEN Current := IndexR.Right
        ELSE Done := TRUE;
      END;
    UNTIL (Current = -1) or (Done);
  END;

  Close(sf);

  IF (Done) AND NOT (IndexR.Deleted) THEN SearchUser := IndexR.Number
  ELSE SearchUser := 0;

  LastError := IOResult;
END;

FUNCTION StripColor (o : string) : string;
VAR i,j : byte;
    s : string;
BEGIN
  i := 0;
  s := '';
  WHILE (i < Length (o) ) DO BEGIN
    Inc (i);
    case o [i] of
     #128..#255:IF (mafilter in BoardR.maflags) THEN
                  s := s + chr(ord(o[i]) AND 128)
                ELSE
                  s := s + o[i];
     '^' : IF o [i + 1] in [#0..#9, '0'..'9'] THEN
              Inc (i) ELSE s := s + '^';
     '|' : IF (mafilter in BoardR.maflags) AND (o[i + 1] in ['0'..'9']) THEN
              BEGIN
                j:=0;
                WHILE (o [i + 1] in ['0'..'9']) AND (i <= Length (o) )
                  AND (j<=2) DO BEGIN
                    Inc (i);
                    Inc (j)
                  END
              END
           ELSE
              s := s + '|'
      ELSE s := s + o [i];
    END;
  END;
  StripColor := s;
END;

procedure aborterror(const s:string);
BEGIN
  WriteLn(s);
  halt(255);
END;

  FUNCTION Value (s : string) : longint;
  VAR i : longint;
      j : integer;
  BEGIN
   val (s, i, j);
   IF (j <> 0) THEN BEGIN
      s[0]:=chr(j-1);
      val (s, i, j)
    END;
    Value := i;
    IF (s = '') THEN Value := 0;
  END;

  FUNCTION CStr (i : longint) : string;
  VAR c : string [16];
  BEGIN
    str (i, c);
    CStr := c;
  END;

  procedure getmsglst (const dir : string);
  VAR hiwater : integer;
  BEGIN
      hiwater := 1;
      IF NOT IsNetMail THEN BEGIN
         Assign (hiwaterf, dir + 'HI_WATER.MRK');
         Reset (hiwaterf);
         IF IOResult <> 0 THEN BEGIN
            ReWrite (hiwaterf);
            Write (hiwaterf, hiwater);
            IF IOResult <> 0 THEN aborterror('error creating ' + dir + '\HI_WATER.MRK');
         END
         ELSE BEGIN
            Read (hiwaterf, hiwater);
            i := IOResult;
            findfirst (dir + CStr (hiwater) + '.MSG', 0, dirinfo);
            IF doserror <> 0 THEN hiwater := 1;
         END;
         Close (hiwaterf);
      END;
      findfirst (dir + '*.MSG', 0, dirinfo);
      highest := 1;
      lowest := 32767;
      WHILE doserror = 0 DO BEGIN
            i := Value (dirinfo.name);
            IF i < lowest THEN lowest := i;
            IF i > highest THEN highest := i;
            findnext (dirinfo);
      END;

      IF hiwater <= highest THEN BEGIN
         IF hiwater > 1 THEN lowest := hiwater + 1;
      END;

      IF (ignore_1msg) THEN BEGIN
        IF (lowest = 1) AND (highest > 1) THEN lowest := 2;
      END;
      LastError := IOResult;
  END;

  procedure getpaths;

     procedure badpath(const s:string);
     BEGIN
       WriteLn('The ',s,' path is bad.  Please correct it.');
       halt;
     END;

  BEGIN
    s := fsearch ('RENEGADE.DAT', getenv ('PATH') );
    Assign (statusf, s);
    Reset (statusf);
    IF (IOResult <> 0) or (s = '') THEN BEGIN
       WriteLn ('RENEGADE.DAT must be in the current directory or the path.');
       halt (1);
    END;
    Read (statusf, statusr);
    datapath := statusr.datapath;
    IF NOT (ExistDir(datapath)) THEN badpath('DATA');
    netmailpath := statusr.netmailpath;
    IF NOT (ExistDir(netmailpath)) THEN badpath('NETMAIL');
    MsgPath := statusr.MsgPath;
    IF NOT (ExistDir(MsgPath)) THEN badpath('MSGS');
    Close (statusf);
    IF IOResult <> 0 THEN
      aborterror('error reading From RENEGADE.DAT');
  END;

  procedure updatehiwater (const dir:string; x:integer);
  BEGIN
     Assign (hiwaterf, dir + 'HI_WATER.MRK');
     ReWrite (hiwaterf);
     Write (hiwaterf, x);
     Close (hiwaterf);
     i := IOResult;
  END;

  procedure PurgeDir (const dir : string);
  VAR purged : boolean;
  BEGIN
{$IFDEF MSDOS}
    IF fastpurge THEN BEGIN
        ChDir (Copy (dir, 1, Length (dir) - 1) );
        IF (IOResult <> 0) THEN Exit;
        IF (dir[2] = ':') THEN fcb [1] := chr(ord(dir[1]) - 64)
        ELSE fcb [1] := chr(ord(StartDir[1]) - 64);
        Regs.ds := seg (fcb);
        Regs.dx := ofs (fcb);
        Regs.ax := $1300;
        msdos (Regs);
        purged := (lo (Regs.ax) = 0);
    END;
{$ENDIF}
    IF NOT fastpurge THEN BEGIN
       purged := TRUE;
       findfirst (dir + '*.MSG', 0, dirinfo);
       IF doserror <> 0 THEN BEGIN purged := FALSE END
       ELSE BEGIN
          WHILE doserror = 0 DO BEGIN
                Assign (hiwaterf, dir + dirinfo.name);
                erase (hiwaterf);
                i := IOResult;
                findnext (dirinfo);
          END;
       END;
    END;

    IF NOT purged THEN Write ('No messages')
    ELSE Write ('Purged');
    updatehiwater (dir, 1);
  END;

  FUNCTION readmsg (x:integer ; const dir:string) : boolean;
  VAR
    q : boolean;
  BEGIN
    Assign (MsgTFile, dir + CStr (x) + '.MSG');
    Reset (MsgTFile, 1);
    q := FALSE;
    IF IOResult = 0 THEN BEGIN

       IF FileSize (MsgTFile) >= sizeof(header) THEN BEGIN

          BlockRead (MsgTFile, header, sizeof(header));
          s := StrPas(Header.FromUserName);

          IF ((header.attribute AND 16) = 16) THEN MsgHdr.fileattached := 1;

          MsgHdr.From.a1s := s;
          MsgHdr.From.real := s;
          MsgHdr.From.name := s;

          s := StrPas(Header.ToUserName);

          MsgHdr.MTO.a1s := s;
          MsgHdr.MTO.real := s;
          MsgHdr.MTO.name := s;

          MsgHdr.Subject := StrPas(Header.Subject);

          MsgHdr.OriginDate := StrPas(Header.DateTime);

          q := TRUE;

          IF (Header.Attribute AND 1 = 1) THEN MsgHdr.status := [Sent, Prvt]
          ELSE MsgHdr.status := [Sent];

          IF IsNetMail THEN BEGIN
             q:=FALSE;
             MsgHdr.From.node := Header.OrigNode;
             MsgHdr.From.net := Header.OrigNet;
             MsgHdr.MTO.node := Header.DestNode;
             MsgHdr.MTO.net := Header.DestNet;
             MsgHdr.From.Point := 0;
             MsgHdr.MTO.Point := 0;
             MsgHdr.From.Zone := 0;
             MsgHdr.MTO.Zone := 0;
             IF (Header.Attribute AND 256 = 0) AND
                (Header.Attribute AND 4 = 0) THEN BEGIN
                {look here FOR the netmail bug}
                FOR i := 0 TO 19 DO BEGIN {21 is the uucp}
                    IF (MsgHdr.MTO.node = statusr.aka[i].node) AND
                       (MsgHdr.MTO.net  = statusr.aka[i].net) THEN BEGIN
                          MsgHdr.MTO.Zone := statusr.aka[i].Zone;
                          MsgHdr.From.Zone := statusr.aka[i].Zone;
                          q := TRUE;
                    END;
                END;
             END;
          END;

          IF q THEN BEGIN
             IF (FileSize(MsgTFile) - 190) <= sizeof(buffer) THEN x := FileSize(MsgTFile) - 190
             ELSE x := sizeof(buffer);
             BlockRead (MsgTFile, buffer, x, msglength);
          END;
       END;

       IF IsNetMail THEN
         IF q AND purge_netmail THEN
            BEGIN
              Close (MsgTFile);
              erase (MsgTFile)
            END
         ELSE IF q THEN
           BEGIN
             Header.Attribute := 260;
             Seek (MsgTFile, 0);
             BlockWrite (MsgTFile, header, sizeof(Header));
           END;
       IF NOT (IsNetMail AND q AND purge_netmail) THEN Close(MsgTFile);
    END;
    readmsg := q;
    i := IOResult;
  END;

  procedure nextboard(Scanning:boolean);
  VAR
    GoodBoard:boolean;
  BEGIN
    IF Board = 0 THEN
      BEGIN
        i := IOResult;
        Assign (boardf, datapath + 'MBASES.DAT');
        Reset (boardf);
        i := IOResult;
        IF i <> 0 THEN
          BEGIN
            WriteLn (i,':Problem accessing ' + datapath + 'MBASES.DAT. Please fix.');
            halt (1);
          END;
      END;

    IF Board = FileSize (boardf) THEN
      BEGIN
        Board := 32767;
        Exit;
      END;

    BoardR.matype := 0;  BoardR.maflags := []; GoodBoard := FALSE;
    WHILE NOT GoodBoard AND (Board < FileSize(boardf)) DO
      BEGIN
        Read (boardf, BoardR);
        GoodBoard := (BoardR.matype = 1) AND
                     (NOT scanning or (absolute_scan or (mascanout in BoardR.maflags)));
        Inc(Board);
      END;

    IF (NOT GoodBoard) THEN
      Board := 32767
    ELSE
      IF scanning AND (mascanout in BoardR.maflags) THEN
        BEGIN
          Seek(boardf, Board - 1);
          BoardR.maflags := BoardR.maflags - [mascanout];
          Write(boardf, BoardR);
        END;
  END;


  procedure toss;
  VAR i,j:word;
      z:string [20];
      left, right, gap, oldgap : integer;
  BEGIN
       MsgHdr.From.anon := 0;
       MsgHdr.From.usernum := 0;
       MsgHdr.MTO.anon := 0;
       MsgHdr.MTO.usernum := 0;
       MsgHdr.replyto := 0;
       MsgHdr.replies := 0;
       MsgHdr.fileattached := 0;

       getdayofweek (MsgHdr.dayofweek);
       MsgHdr.date := getpackdatetime;
       getmsglst (BoardR.MsgPath);
       IF IsNetMail AND (highest > 1) THEN lowest := 1;

       IF (lowest <= highest) AND ((highest > 1) or IsNetMail) THEN BEGIN

          Assign (MsgHdrF, MsgPath + BoardR.FileName + '.HDR');
          Reset (MsgHdrF);
          IF (IOResult = 2) THEN ReWrite (MsgHdrF);

          Assign (MsgTxtF, MsgPath + BoardR.FileName + '.DAT');
          Reset (MsgTxtF, 1);
          IF (IOResult = 2) THEN ReWrite (MsgTxtF, 1);

          Seek (MsgHdrF, FileSize (MsgHdrF) );
          Seek (MsgTxtF, FileSize (MsgTxtF) );

          IF IOResult <> 0 THEN
            aborterror('error accessing ' + MsgPath + BoardR.FileName + '.*');

          FOR MsgNumber := lowest TO highest DO BEGIN
              Write (MsgNumber : 4);
              IF readmsg (MsgNumber, BoardR.MsgPath) THEN
                with MsgHdr DO BEGIN
                  Inc (date);
                  pointer := FileSize (MsgTxtF) + 1;
                  TextSize := 0;
                  msgpointer := 0;
                  nos := '';
                  WHILE (msgpointer < msglength) DO BEGIN
                    MsgTxt := nos;
                    REPEAT
                      Inc (msgpointer);
                      c := buffer [msgpointer];
                      IF NOT (c in [#0, #10, #13, #141]) THEN
                        IF (Length(MsgTxt) < 255) THEN  {MsgTxt := MsgTxt + c;}
                          BEGIN
                            Inc(MsgTxt[0]);
                            MsgTxt[Length(MsgTxt)] := c;
                          END;
                    UNTIL (
                          (nos = #13) or (c in [#13,#141])
                          or
                          ((Length(MsgTxt) > 79) AND (POS(#27, MsgTxt) = 0))
                          or
                          (Length(MsgTxt) = 254)
                          or
                          (msgpointer >= msglength)
                          );

                    IF Length (MsgTxt) = 254 THEN
                       MsgTxt := MsgTxt + #29;

                    i := POS('INTL ', MsgTxt);
                    IF (i > 0) THEN
                      BEGIN
                        Inc(i, 6);
                        FOR j := 1 TO 8 DO
                          BEGIN
                            z := '';
                            WHILE (MsgTxt[i] in ['0'..'9']) AND (i <= Length(MsgTxt)) DO
                              BEGIN
                                z := z + MsgTxt[i];
                                Inc(i);
                              END;
                            case j of
                              1:MsgHdr.MTO.Zone := Value(z);
                              2:MsgHdr.MTO.net := Value(z);
                              3:MsgHdr.MTO.node := Value(z);
                              4:MsgHdr.MTO.Point := Value(z);
                              5:MsgHdr.From.Zone := Value(z);
                              6:MsgHdr.From.net := Value(z);
                              7:MsgHdr.From.node := Value(z);
                              8:MsgHdr.From.Point := Value(z);
                            END;
                            IF (j = 3) AND (MsgTxt[i] <> '.') THEN
                              Inc(j);
                            IF (j = 7) AND (MsgTxt[i] <> '.') THEN
                              break;
                            Inc(i);
                          END;
                      END;

                    IF (Length (MsgTxt) > 79) THEN
                      BEGIN
                        i := Length (MsgTxt);
                        WHILE (MsgTxt [i] = ' ') AND (i > 1) DO
                          Dec (i);
                        WHILE (i > 65) AND (MsgTxt [i] <> ' ') DO
                          Dec (i);

                        nos[0] := chr(Length(MsgTxt) - i);
                        Move(MsgTxt[i + 1], nos[1], Length(MsgTxt) - i);
                        MsgTxt[0] := chr(i - 1);

                      END
                    ELSE
                      nos := '';

                    IF ( (MsgTxt [1] = #1) AND (maskludge in BoardR.maflags) ) or
                       ( (POS ('SEEN-BY', MsgTxt) > 0) AND (masseenby in BoardR.maflags) ) or
                       ( (POS ('* Origin:', MsgTxt) > 0) AND (masorigin in BoardR.maflags) ) THEN
                       MsgTxt := ''
                    ELSE BEGIN
                       Inc (MsgHdr.TextSize, Length (MsgTxt) + 1);
                       BlockWrite (MsgTxtF, MsgTxt, Length (MsgTxt) + 1);
                    END;
                  END;
                  IF IsNetMail THEN BEGIN
                     MsgHdr.status := MsgHdr.status + [netmail];
                     MsgHdr.MTO.usernum := SearchUser(MsgHdr.MTO.a1s);
                     IF MsgHdr.MTO.usernum = 0 THEN
                       MsgHdr.MTO.usernum := 1;
                     Seek (uf, MsgHdr.MTO.usernum);
                     Read (uf, user);
                     Inc (user.waiting);
                     Seek (uf, MsgHdr.MTO.usernum);
                     Write (uf, user);
                  END;
                  Write (MsgHdrF, MsgHdr);
                END;
              IF MsgNumber < highest THEN Write (#8#8#8#8);
              i := IOResult;
          END;
          Close (MsgHdrF);
          Close (MsgTxtF);
          IF NOT IsNetMail THEN updatehiwater (BoardR.MsgPath, highest);
       END ELSE Write ('No messages');
    LastError := IOResult;
  END;

  procedure scan;
  VAR rgmsgnumber : integer;
      highestwritten : integer;
      AnsiOn,
      scanned : boolean;
  BEGIN
       AnsiOn := FALSE;
       scanned := FALSE;
       getmsglst (BoardR.MsgPath);
       MsgNumber := highest;
       IF (NOT ExistDir(BoardR.MsgPath)) THEN
         BEGIN
           WriteLn('WARNING: Cannot access ', BoardR.MsgPath);
           Exit;
         END;

       Assign (MsgHdrF, MsgPath + BoardR.FileName + '.HDR');
       Reset (MsgHdrF);
       IF IOResult <> 0 THEN Exit;

       Assign (MsgTxtF, MsgPath + BoardR.FileName + '.DAT');
       Reset (MsgTxtF, 1);
       IF IOResult <> 0 THEN BEGIN Close (MsgHdrF); Exit; END;

       FOR rgmsgnumber := 1 TO FileSize (MsgHdrF) DO BEGIN
           Seek (MsgHdrF, rgmsgnumber - 1);
           Read (MsgHdrF, MsgHdr);
           IF NOT (Sent in MsgHdr.status) AND (IOResult = 0) AND
              NOT (MDeleted in MsgHdr.status) AND
              NOT (IsNetMail AND NOT (netmail in MsgHdr.status)) AND
              NOT (unvalidated in MsgHdr.status) THEN BEGIN
              scanned := TRUE;
              Inc (MsgNumber);
              Assign (MsgTFile, BoardR.MsgPath + CStr (MsgNumber) + '.MSG');
              ReWrite (MsgTFile, 1);
              Write (rgmsgnumber : 5);

              MsgHdr.status := MsgHdr.status + [Sent];

              IF IsNetMail THEN
                MsgHdr.status := MsgHdr.status + [MDeleted];

              Seek (MsgHdrF, rgmsgnumber - 1);
              Write (MsgHdrF, MsgHdr);

              IF (marealname in BoardR.maflags) THEN
                s := Caps (MsgHdr.From.real)
              ELSE
                s := Caps (MsgHdr.From.a1s);

              s := usename(MsgHdr.From.anon, s);

              FillChar(Header,sizeof(Header),#0);

              Move(s[1],Header.FromUserName[0],Length(s));

              IF (marealname in BoardR.maflags) THEN
                s := Caps (MsgHdr.MTO.real)
              ELSE
                s := Caps (MsgHdr.MTO.a1s);

              s := usename(MsgHdr.MTO.anon, s);

              Move(s[1],Header.ToUserName[0],Length(s));

              MsgHdr.Subject := StripColor(MsgHdr.Subject);

              IF (NOT IsNetMail) AND (MsgHdr.fileattached > 0) THEN
                MsgHdr.Subject := StripName(MsgHdr.Subject);

              Move(MsgHdr.Subject[1],Header.Subject[0],Length(MsgHdr.Subject));

              packtodate (dt, MsgHdr.date);
              with dt DO BEGIN
               s := CStr (day);
                IF Length (s) < 2 THEN s := '0' + s;
               s := s + ' ' + Copy ('JanFebMarAprMayJunJulAugSepOctNovDec', (month - 1) * 3 + 1, 3) + ' ';
               s := s + Copy (CStr (year), 3, 2) + '  ';
               nos := CStr (hour);
               IF Length (nos) < 2 THEN nos := '0' + nos;
               s := s + nos + ':';
               nos := CStr (min);
               IF Length (nos) < 2 THEN nos := '0' + nos;
               s := s + nos + ':';
               nos := CStr (sec);
              END;
              IF Length (nos) < 2 THEN nos := '0' + nos;
              s := s + nos;

              Move(s[1],Header.DateTime[0],Length(s));

              IF IsNetMail THEN BEGIN
                 Header.OrigNet := MsgHdr.From.net;
                 Header.OrigNode := MsgHdr.From.node;
                 Header.DestNet := MsgHdr.MTO.net;
                 Header.DestNode := MsgHdr.MTO.node;
              END ELSE BEGIN
                 Header.OrigNet := statusr.aka [BoardR.aka].net;
                 Header.OrigNode := statusr.aka [BoardR.aka].node;
                 Header.DestNet := 0;
                 Header.DestNode := 0;
              END;

              IF IsNetMail THEN
                Header.Attribute := word(MsgHdr.netattribute)
                {word(statusr.netattribute)}
              ELSE
                IF (prvt in MsgHdr.status) THEN
                  Header.Attribute := 257
                ELSE
                  Header.Attribute := 256;

              IF (MsgHdr.fileattached > 0) THEN
                Header.Attribute := Header.Attribute + 16;

              BlockWrite (MsgTFile, header, sizeof(Header));
              Seek (MsgTxtF, MsgHdr.pointer - 1);

              IF IsNetMail THEN BEGIN
                s := 'INTL ' + CStr (MsgHdr.MTO.Zone) + ':' + CStr (MsgHdr.MTO.net) + '/' + CStr (MsgHdr.MTO.node);
                s := s + ' ' + CStr (MsgHdr.From.Zone) + ':' + CStr (MsgHdr.From.net) + '/' + CStr (MsgHdr.From.node);
                s := s + #13;
                BlockWrite (MsgTFile, s [1], Length (s) );
                IF MsgHdr.MTO.Point > 0 THEN
                  BEGIN
                    s := #1'TOPT ' + CStr(MsgHdr.MTO.Point);
                    BlockWrite (MsgTFile, s [1], Length (s) );
                  END;
                IF MsgHdr.From.Point > 0 THEN
                  BEGIN
                    s := #1'FMPT ' + CStr(MsgHdr.From.Point);
                    BlockWrite (MsgTFile, s [1], Length (s) );
                  END;

                s := ^A'MSGID: ' + CStr (MsgHdr.From.Zone) + ':' + CStr (MsgHdr.From.net) +
                   '/' + CStr (MsgHdr.From.node) + ' ' + Hex(Random($FFFF), 4) + Hex(Random($FFFF),4);

                IF MsgHdr.From.Point > 0 THEN s := s + '.' + CStr (MsgHdr.From.Point);
                s := s + {' '} #13;  { *** }
                BlockWrite (MsgTFile, s [1], Length (s) );
{$IFDEF MSDOS}
                s := #1'PID: Renemail ' + ver + #13;
{$ELSE}
                s := #1'PID: Renemail/2 ' + ver + #13;
{$ENDIF}
                BlockWrite (MsgTFile, s [1], Length (s) );
              END;

              j := 0;
              IF MsgHdr.TextSize > 0 THEN
              REPEAT
                BlockRead (MsgTxtF, s [0], 1);
                BlockRead (MsgTxtF, s [1], ord (s [0]) );
                Inc (j, Length (s) + 1);
                WHILE POS(#0,s) > 0 DO
                  Delete(s,POS(#0,s),1);
                IF s [Length (s) ] = #29 THEN
                  Dec(s[0])
                ELSE
                  IF POS (#27, s) = 0 THEN
                    s := StripColor(s)
                  ELSE
                    AnsiOn := TRUE;
                s := s + #13;
                BlockWrite (MsgTFile, s [1], Length (s) );
              UNTIL (j >= MsgHdr.TextSize);
              Close (MsgTFile);
              Write (#8#8#8#8#8);
           END;
           highestwritten := MsgNumber;
       END;
       i := IOResult;
       IF NOT IsNetMail THEN updatehiwater (BoardR.MsgPath, highestwritten);
       Close (MsgHdrF);
       Close (MsgTxtF);
       IF NOT scanned THEN Write ('No messages');
    LastError := IOResult;
  END;

BEGIN
  Randomize;
  GetDir (0, StartDir);
  FOR x := 1 TO 37 DO
     fcb [x] := ' ';
  fcb [1] := chr (ord (StartDir [1]) - 64);
  fcb [2] := '*';
  fcb [10] := 'M';
  fcb [11] := 'S';
  fcb [12] := 'G';
  FileMode := 66;
  MsgHdr.From.Zone := 0;
  MsgHdr.From.Point := 0;
  ClrScr;
  TextColor (3);
{$IFDEF MSDOS}
  WriteLn ('Renegade Echomail Interface DOS v' + ver);
{$ELSE}
  WriteLn ('Renegade Echomail Interface OS/2 v' + ver);
{$ENDIF}
  WriteLn ('Copyright 2004-2006');
  WriteLn;
  TextColor (10);

  IF ParamStr (1) = '' THEN
    BEGIN
      WriteLn (' Commands:  -T  Toss incoming messages');
      WriteLn ('            -S  Scan outbound messages');
      WriteLn ('            -P  Purge echomail dirs');
      WriteLn (' Options:       -A  Absolute scan');
{$IFDEF MSDOS}
      WriteLn ('                -F  No fast purge');
{$ENDIF}
      WriteLn ('                -N  No Netmail');
      WriteLn ('                -D  Do not delete Netmail');
{$IFDEF MSDOS}
      WriteLn ('                -B  Bios video output');
{$ENDIF}
      WriteLn ('                -O  Only Netmail');
      WriteLn ('                -I  Import 1.MSG');
      WriteLn;
      halt;
    END;
  FOR i := 1 TO paramcount DO
      IF POS ('-N', AllCaps (ParamStr (i) ) ) > 0 THEN
         process_netmail := FALSE
      ELSE
         IF POS ('-F', AllCaps (ParamStr (i) ) ) > 0 THEN
            fastpurge := FALSE
         ELSE
            IF POS ('-D', AllCaps (ParamStr (i) ) ) > 0 THEN
               purge_netmail := FALSE
            ELSE
{$IFDEF MSDOS}
              IF POS ('-B', AllCaps (ParamStr (i) ) ) > 0 THEN
                 directvideo := FALSE
              ELSE
{$ENDIF}
                IF POS ('-O', AllCaps (ParamStr (i) ) ) > 0 THEN
                   netmailonly := TRUE
                ELSE
                  IF POS ('-A', AllCaps (ParamStr (i) ) ) > 0 THEN
                     absolute_scan := TRUE
                  ELSE
                    IF POS ('-I', AllCaps (ParamStr (i) ) ) > 0 THEN
                       ignore_1msg := FALSE;
                       (* 09-16-96 Changed to allow processing of 1.msg
                       *)
  Board := 0;
  getpaths;

  IF process_netmail THEN
    BEGIN
       BoardR.MsgPath := netmailpath;
       BoardR.FileName := 'EMAIL';
       BoardR.maflags := [maskludge];
       Assign (uf, datapath + 'users.dat');
       Reset (uf);
       IF IOResult <> 0 THEN
         aborterror('Cannot find users.dat in your DATA directory');
       Assign (sf, datapath + 'users.idx');
       Reset (sf);
       IF IOResult <> 0 THEN
         aborterror('Cannot find users.idx in your DATA directory');

       IsNetMail := TRUE;
       TextColor (3);
       Write ('Processing: ');
       TextColor (14);
       Write (' NETMAIL - ');
       TextColor (11);
       IF POS ('-T', AllCaps (ParamStr (1) ) ) > 0 THEN
          toss;
       IF POS ('-S', AllCaps (ParamStr (1) ) ) > 0 THEN
          scan;
       Close (uf);
       Close (sf);
       LastError := IOResult;
       WriteLn;
       IsNetMail := FALSE;
    END;

  IF netmailonly THEN halt;

  WHILE Board <> 32767 DO BEGIN
       nextboard(POS('-S', AllCaps(ParamStr(1))) > 0);
       IF Board <> 32767 THEN BEGIN
       TextColor (3);
       Write ('Processing: ');
       TextColor (14);
       Write (BoardR.FileName : 8, ' - ');
       TextColor (11);
       IF POS ('-P', AllCaps (ParamStr (1) ) ) > 0 THEN PurgeDir (BoardR.MsgPath)
          ELSE IF POS ('-T', AllCaps (ParamStr (1) ) ) > 0 THEN toss
               ELSE IF POS ('-S', AllCaps (ParamStr (1) ) ) > 0 THEN scan;
        WriteLn;
    END ELSE Close (boardf)
  END;
  ChDir (StartDir);
END.
