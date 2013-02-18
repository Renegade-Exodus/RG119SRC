{$M 35500,0,131072}
program tagstat;

uses
  crt,
  dos,
  Common;

type
  Str39 = STRING[39];
  Str43 = STRING[43];
  Str78 = STRING[78];

  genrec = record
    name : str43;
    info : real;
  END;

  (*
  fileinfo = record
    recnum: word;
    filename: str12;
    description: str78;
    Downloaded: word;
    unused: byte;
    blocks: word;
    owner: str36;
    date: LongInt;
    daten: word;
    FIFlags: FIFlagSet;
    points: byte;
    dirpath: pathstr;
    dirname: str8;
    DLPath: str30;
    FAflags: FAFlagSet;
    areaname: str39;
    area: word;
  END;

  b_array = ARRAY[1..20] OF boolean;
  d_array = ARRAY[1..20] OF str8;
  e_array = ARRAY[1..10] OF word;
  f_array = ARRAY[1..20] OF fileinfo;
  g_array = ARRAY[1..20] OF longint;
  gsysactivity = ARRAY[1..20] OF real;
  h_array = ARRAY[1..19] OF word;
  m_array = ARRAY[1..3] OF word;
  *)
  t_array = ARRAY[1..10] OF genrec;

  (*
  configinfo = record
    exuser: e_array;
    graph_fg,
    graph_bg,
    logdays,
    dldsl: byte;
    use_real: boolean;
  END;
  *)

VAR
  (*
  config: configinfo;
  uage: m_array;
  usex: m_array;
  gdate: d_array;
  ubaud: h_array;
  tttimeon: t_array;
  tfreqc: t_array;
  tulk: t_array;
  tdlk: t_array;
  tprivp: t_array;
  *)
  tpubp: t_array;
  (*
  tfeedback: t_array;
  tnumc: t_array;
  tnumul: t_array;
  tnumdl: t_array;
  tfilep: t_array;
  tupd: t_array;
  tpostc: t_array;
  gsysact: gsysactivity;
  gmina: g_array;
  gnumc: g_array;
  gnewu: g_array;
  gtimeu: g_array;
  gmsgpub: g_array;
  gmsgpvt: g_array;
  gmsgfb: g_array;
  gnume: g_array;
  gful: g_array;
  gulkb: g_array;
  gfdl: g_array;
  gdlkb: g_array;
  frec: f_array;
  *)

FUNCTION RealToStr(L: Real; W,D: Integer): STRING;
VAR
  S: STRING[11];
BEGIN
  Str(L:W:D,S);
  RealToStr := s;
END;

FUNCTION RmvLeadSpace(S: STRING): STRING;
BEGIN
END;

FUNCTION RmvTrailSpace(S: STRING): STRING;
BEGIN
END;

FUNCTION Min(X,Y: Integer): Integer;
BEGIN
END;

FUNCTION Max(X,Y: Integer): Integer;
BEGIN
END;

function graph_month(s: str8): str3;
BEGIN
  CASE StrToInt(copy(s,1,2)) OF
     1 : graph_month := 'Jan';
     2 : graph_month := 'Feb';
     3 : graph_month := 'Mar';
     4 : graph_month := 'Apr';
     5 : graph_month := 'May';
     6 : graph_month := 'Jun';
     7 : graph_month := 'Jul';
     8 : graph_month := 'Aug';
     9 : graph_month := 'Sep';
    10 : graph_month := 'Oct';
    11 : graph_month := 'Nov';
    12 : graph_month := 'Dec';
  END;
END;

function reverse_str(s: str160): str160;
VAR
  s1: str160;
  Counter: byte;
BEGIN
  s1 := '';
  FOR Counter := 20 downto 1 DO
    s1 := s1 + s[Counter];
  reverse_str := rmvleadspace(rmvtrailspace(s1));
END;

function center(s: str160; i: integer; tf: boolean): str160;
VAR
  Counter,strlength: integer;
  which_way: boolean;
BEGIN
  which_way := tf;
  strlength := length(s);
  FOR Counter := (strlength + 1) to i DO
  BEGIN
    IF which_way THEN
    BEGIN
      s := ' ' + s;
      which_way := false;
    END
    ELSE
    BEGIN
      s := s + ' ';
      which_way := true;
    END;
  END;
  center := s;
END;

function return_time(w,w1: word): str160;
BEGIN
  IF (w > 0) AND (w1 > 0) THEN
    return_time := IntToStr(trunc(w div w1))
  ELSE
    return_time := '0';
END;

function age(s: str160): str160;
BEGIN
  age := IntToStr(StrToInt(copy(datestr,7,2)) - StrToInt(copy(s,7,2)));
END;

function return_age(userbday: str160): str160;
VAR
  today,user_years: str160;
BEGIN
  today := datestr;
  user_years := age(userbday);
  IF (StrToInt(copy(userbday,1,2)) > StrToInt(copy(today,1,2))) THEN
    user_years := IntToStr(StrToInt(user_years)-1)
  ELSE
    IF (StrToInt(copy(userbday,1,2)) = StrToInt(copy(today,1,2))) THEN
      IF (StrToInt(copy(userbday,4,2)) > StrToInt(copy(today,4,2))) THEN
        user_years := IntToStr(StrToInt(user_years)-1);
  return_age := user_years;
END;

(*
PROCEDURE read_config_file(VAR config: configinfo);
VAR
  f: text;
  line,line1: str160;
  Counter,counter1: byte;
BEGIN
  Assign(f,'TAGSTAT.CFG');
  {$I-} Reset(f); {$I+}
  IF (IOResult <> 0) THEN
  BEGIN
    WriteLn(^G^G^G'Unable to access TAGSTAT.CFG!');
    Halt;
  END;
  textcolor(lightgray);
  textbackground(black);
  WITH config DO
  BEGIN
    FOR counter1 := 1 to 10 DO
      exuser[counter1] := 0;
    graph_fg := 9;
    graph_bg := 7;
    logdays := 0;
    dldsl := 255;
    use_real := false;
  END;
  Counter := 1;
  counter1 := 0;
  while not eof(f) DO
  BEGIN
    {$I-} readln(f,line); {$I+}
    IF (IOResult <> 0) THEN
    BEGIN
      WriteLn(^G^G^G'Unable to read TAGSTAT.CFG!');
      {$I-} Close(f); {$I+}
      IF (IOResult <> 0) THEN
        WriteLn(^G^G^G'Unable to close TAGSTAT.CFG!');
      Halt;
    END;
    line := rmvleadspace(rmvtrailspace(line));
    line1 := allcaps(line);
    IF (line1 <> '') AND (line1[1] <> '%') THEN
    BEGIN
      IF (pos('USER_EXCLUDE',line1) = 1) AND (counter1 < 10) THEN
      BEGIN
        delete(line,1,12);
        inc(counter1);
        config.exuser[counter1] := StrToInt(rmvleadspace(line));
      END
      ELSE IF (pos('DOWNLOAD_DSL',line1) = 1) THEN
      BEGIN
        delete(line,1,12);
        config.dldsl := StrToInt(rmvleadspace(line));
        IF (config.dldsl < 0) OR (config.dldsl > 255) THEN
          config.dldsl := 255;
      END
      ELSE IF (pos('REAL_NAME',line1) = 1) THEN
        config.use_real := true
      ELSE IF (pos('GRAPH_BACKGROUND',line1) = 1) THEN
      BEGIN
        delete(line,1,16);
        config.graph_bg := StrToInt(rmvleadspace(line));
        IF (config.graph_bg < 0) OR (config.graph_bg > 15) THEN
          config.graph_bg := 7;
      END
      ELSE IF (pos('GRAPH_BARS',line1) = 1) THEN
      BEGIN
        delete(line,1,10);
        config.graph_fg := StrToInt(rmvleadspace(line));
        IF (config.graph_fg < 0) OR (config.graph_fg > 15) THEN
          config.graph_fg := 9;
      END;
    END;
  END;
  {$I-} Close(f); {$I+}
  IF (IOResult <> 0) THEN
  BEGIN
    WriteLn(^G^G^G'Unable to close TAGSTAT.CFG!');
    Halt;
  END;
END;
*)

(*
PROCEDURE init_d_array(VAR gdate: d_array);
VAR
  Counter: byte;
BEGIN
  FOR Counter := 1 to 20 DO
    gdate[Counter] := '';
END;

PROCEDURE init_f_array(VAR ar: f_array);
VAR
  Counter: byte;
BEGIN
  FOR Counter := 1 to 20 DO
    WITH ar[Counter] DO
    BEGIN
      recnum := 0;
      filename := '';
      description := '';
      Downloaded := 0;
      unused := 0;
      blocks := 0;
      owner := '';
      date := 0;
      daten := 0;
      FIflags := [];
      points := 0;
      dirpath := '';
      dirname := '';
      DLPath := '';
      FAflags := [];
      areaname := '';
      area := 0;
    END;
END;

PROCEDURE init_g_array(VAR ar: g_array; info_val: longint);
VAR
  Counter: byte;
BEGIN
  FOR Counter := 1 to 20 DO
    ar[Counter] := info_val;
END;

PROCEDURE init_gsysactivity(VAR gsysact: gsysactivity);
VAR
  Counter: byte;
BEGIN
  FOR Counter := 1 to 20 DO
    gsysact[Counter] := 0.0;
END;

PROCEDURE init_h_array(VAR ar: h_array; info_val: word);
VAR
  Counter: byte;
BEGIN
  FOR Counter := 1 to 19 DO
    ar[Counter] := info_val;
END;

PROCEDURE init_m_array(VAR ar: m_array; info_val: word);
VAR
  Counter: byte;
BEGIN
  FOR Counter := 1 to 3 DO
    ar[Counter] := info_val;
END;

*)
PROCEDURE init_t_array(VAR ar: t_array; info_val: real);
VAR
  Counter: byte;
BEGIN
  FOR Counter := 1 to 10 DO
  BEGIN
    ar[Counter].name := '';
    ar[Counter].info := info_val;
  END;
END;

PROCEDURE sort_ascending(s: str43; r: real; VAR tfreqc: t_array);
VAR
  Counter,counter1: byte;
BEGIN
  IF (r > 0.0) THEN
    FOR Counter := 1 to 10 DO
      IF (r <= tfreqc[Counter].info) THEN
      BEGIN
        FOR counter1 := 10 downto (Counter + 1) DO
          tfreqc[counter1] := tfreqc[counter1-1];
        tfreqc[Counter].name := s;
        tfreqc[Counter].info := r;
        Counter := 10;
      END;
END;

PROCEDURE sort_descending(s: str43; r: real; VAR ar: t_array);
VAR
  Counter,counter1: byte;
BEGIN
  IF (r > 0.0) THEN
    FOR Counter := 1 to 10 DO
      IF (r >= ar[Counter].info) THEN
      BEGIN
        FOR counter1 := 10 downto (Counter + 1) DO
          ar[counter1] := ar[counter1 - 1];
        ar[Counter].name := s;
        ar[Counter].info := r;
        Counter := 10;
      END;
END;

(*
function in_array(w: word; exuser: e_array): boolean;
VAR
  Counter: byte;
  tf: boolean;
BEGIN
  tf := false;
  FOR Counter := 1 to 10 DO
    IF (w = exuser[Counter]) THEN
      tf := true;
  in_array := tf;
END;
*)

PROCEDURE read_user_file(General: GeneralRecordType; VAR config: configinfo; VAR uage,
                         usex: m_array; VAR ubaud: h_array; VAR tfreqc,tttimeon,
                         tulk,tdlk,tprivp,tpubp,tfeedback,tnumc,tnumul,tnumdl,
                         tfilep,tupd,tpostc: t_array);
const
  maxuserblock = 30000 div sizeof(UserRecordType);  {* Allocate 30K *}
type
  userblocktype = ARRAY[1..maxuserblock] OF UserRecordType;
VAR
  uf: FILE;
  userblock: ^userblocktype;
  recnum,numusers,unum: word;
  totuage: longint;
  Counter,userage: byte;
  calltot,realuserblockcount: integer;
  name: str43;
BEGIN
  Assign(uf,General.DataPath+'USER.LST');
  {$I-} Reset(uf,sizeof(UserRecordType)); {$I+}
  IF (IOResult <> 0) THEN
  BEGIN
    WriteLn(^G^G^G'Unable to access USER.LST!');
    Halt;
  END;
  new(userblock);
  init_m_array(uage,0);
  init_m_array(usex,0);
  init_h_array(ubaud,0);
  init_t_array(tfreqc,255.000);
  init_t_array(tttimeon,0.000);
  init_t_array(tulk,0.000);
  init_t_array(tdlk,0.000);
  init_t_array(tprivp,0.000);
  init_t_array(tpubp,0.000);
  init_t_array(tfeedback,0.000);
  init_t_array(tnumc,0.000);
  init_t_array(tnumul,0.000);
  init_t_array(tnumdl,0.000);;
  init_t_array(tfilep,0.000);
  init_t_array(tupd,0.000);
  init_t_array(tpostc,0.000);
  recnum := 0;
  numusers := 0;
  totuage := 0;
  uage[2] := 255;
  seek(uf,1);
  REPEAT
    blockread(uf,userblock^,maxuserblock,realuserblockcount);
    FOR unum := 1 to realuserblockcount DO
      WITH userblock^[unum] DO
      BEGIN
        inc(recnum);
        calltot := 0;
        IF (recnum = usernum) AND not in_array(usernum,config.exuser) THEN
        BEGIN
          userage := AgeUser(BirthDate);
          Inc(totuage,userage);
          uage[2] := min(uage[2],userage);
          uage[3] := max(userage,uage[3]);
          IF (Sex = 'M') THEN
            inc(usex[1])
          ELSE IF (Sex = 'F') THEN
            inc(usex[2])
          ELSE
            inc(usex[3]);
          (*
          IF (hbaud = 300) THEN
            inc(ubaud[1])
          ELSE IF (hbaud = 1200) THEN
            inc(ubaud[2])
          ELSE IF (hbaud = 1275) THEN
            inc(ubaud[3])
          ELSE IF (hbaud = 2400) THEN
            inc(ubaud[4])
          ELSE IF (hbaud = 4800) THEN
            inc(ubaud[5])
          ELSE IF (hbaud = 7200) THEN
            inc(ubaud[6])
          ELSE IF (hbaud = 9600) THEN
            inc(ubaud[7])
          ELSE IF (hbaud = 12000) THEN
            inc(ubaud[8])
          ELSE IF (hbaud = 14400) THEN
            inc(ubaud[9])
          ELSE IF (hbaud = 16800) THEN
            inc(ubaud[10])
          ELSE IF (hbaud = 19200) THEN
            inc(ubaud[11])
          ELSE IF (hbaud = 21600) THEN
            inc(ubaud[12])
          ELSE IF (hbaud = 24000) THEN
            inc(ubaud[13])
          ELSE IF (hbaud = 26400) THEN
            inc(ubaud[14])
          ELSE IF (hbaud = 28800) THEN
            inc(ubaud[15])
          ELSE IF (hbaud = 38400) THEN
            inc(ubaud[16])
          ELSE IF (hbaud = 57600) THEN
            inc(ubaud[17])
          ELSE IF (hbaud = 64000) THEN
            inc(ubaud[18])
          ELSE IF (hbaud = 115200) THEN
            inc(ubaud[19]);
          *)
          IF config.use_real THEN
            name := allcaps(RealName)+' #'+IntToStr(usernum)
          ELSE
            name := Name+' #'+IntToStr(usernum);
          sort_ascending(name,calltot/15,tfreqc);
          sort_descending(name,ttimeon,tttimeon);
          sort_descending(name,uk,tulk);
          sort_descending(name,dk,tdlk);
          sort_descending(name,emailsent,tprivp);
          sort_descending(name,msgpost,tpubp);
          sort_descending(name,feedback,tfeedback);
          sort_descending(name,loggedon,tnumc);
          sort_descending(name,uploads,tnumul);
          sort_descending(name,downloads,tnumdl);
          sort_descending(name,credit,tfilep);
          (*
          sort_descending(name,uk/maxr(1.0,dlk),tupd);
          sort_descending(name,msgpost/maxr(1.0,numcalls),tpostc);
          inc(numusers);
          *)
        END;
      END;
  UNTIL (realuserblockcount < maxuserblock);
  dispose(userblock);
  uage[1] := totuage div numusers;
  {$I-} Close(uf); {$I+}
  IF (IOResult <> 0) THEN
  BEGIN
    WriteLn(^G^G^G'Unable to close USER.LST!');
    Halt;
  END;
END;

PROCEDURE read_usage_file(General: GeneralRecordType; VAR config: configinfo; VAR
                          gdate: d_array; VAR gsysact: gsysactivity; VAR
                          gmina,gnumc,gnewu,gtimeu,gmsgpub,gmsgpvt,gmsgfb,
                          gnume,gful,gulkb,gfdl,gdlkb: g_array);
VAR
  ul: text;
  line: str160;
  Counter: byte;

  function ajust_int_size(l,size: longint): longint;
  BEGIN
    IF (l < 0) THEN
      ajust_int_size := 0
    ELSE IF (l > size) THEN
      ajust_int_size := size
    ELSE
      ajust_int_size := l;
  END;

  function ajust_real_size(r,size: real): real;
  BEGIN
    IF (r < 0.0) THEN
      ajust_real_size := 0.0
    ELSE IF (r > size) THEN
      ajust_real_size := size
    ELSE
      ajust_real_size := r;
  END;

BEGIN
  Assign(ul,General.DataPath+'USAGE.LOG');
  {$I-} Reset(ul); {$I+}
  IF (IOResult <> 0) THEN
  BEGIN
    WriteLn(^G^G^G'Unable to access USAGE.LOG!');
    Halt;
  END;
  init_d_array(gdate);
  init_g_array(gmina,0);
  init_g_array(gnumc,0);
  init_g_array(gnewu,0);
  init_gsysactivity(gsysact);
  init_g_array(gtimeu,0);
  init_g_array(gmsgpub,0);
  init_g_array(gmsgpvt,0);
  init_g_array(gmsgfb,0);
  init_g_array(gnume,0);
  init_g_array(gful,0);
  init_g_array(gulkb,0);
  init_g_array(gfdl,0);
  init_g_array(gdlkb,0);
  FOR Counter := 1 to 5 DO
  BEGIN
    {$I-} readln(ul); {$I+}
    IF (IOResult <> 0) THEN
    BEGIN
      WriteLn(^G^G^G'Unable to read USAGE.LOG!');
      {$I-} Close(ul); {$I+}
      IF (IOResult <> 0) THEN
        WriteLn(^G^G^G'Unable to close USAGE.LOG!');
      Halt;
    END;
  END;
  FOR Counter := 1 to 20 DO
    IF not eof(ul) THEN
    BEGIN
      {$I-} readln(ul,line); {$I+}
      IF (IOResult <> 0) THEN
      BEGIN
        WriteLn(^G^G^G'Unable to read USAGE.LOG!');
        {$I-} Close(ul); {$I+}
        IF (IOResult <> 0) THEN
          WriteLn(^G^G^G'Unable to close USAGE.LOG!');
        Halt;
      END;
      gdate[Counter] := copy(line,1,8);
      delete(line,1,8);
      gmina[Counter] := ajust_int_size(StrToInt(rmvleadspace(copy(line,1,6))),99999);
      delete(line,1,6);
      gnumc[Counter] := ajust_int_size(StrToInt(rmvleadspace(copy(line,1,5))),9999);
      delete(line,1,5);
      gnewu[Counter] := ajust_int_size(StrToInt(rmvleadspace(copy(line,1,5))),9999);
      delete(line,1,5);
      gsysact[Counter] := ajust_real_size(valuer(rmvleadspace(copy(line,1,6))),100.0);
      delete(line,1,6);
      gtimeu[Counter] := ajust_int_size(StrToInt(rmvleadspace(copy(line,1,5))),9999);
      delete(line,1,5);
      gmsgpub[Counter] := ajust_int_size(StrToInt(rmvleadspace(copy(line,1,5))),9999);
      delete(line,1,5);
      gmsgpvt[Counter] := ajust_int_size(StrToInt(rmvleadspace(copy(line,1,5))),9999);
      delete(line,1,5);
      gmsgfb[Counter] := ajust_int_size(StrToInt(rmvleadspace(copy(line,1,5))),9999);
      delete(line,1,5);
      gnume[Counter] := ajust_int_size(StrToInt(rmvleadspace(copy(line,1,5))),9999);
      delete(line,1,5);
      gful[Counter] := ajust_int_size(StrToInt(rmvleadspace(copy(line,1,5))),9999);
      delete(line,1,5);
      gulkb[Counter] := ajust_int_size(StrToInt(rmvleadspace(copy(line,1,7))),999999);
      delete(line,1,7);
      gfdl[Counter] := ajust_int_size(StrToInt(rmvleadspace(copy(line,1,5))),9999);
      delete(line,1,5);
      gdlkb[Counter] := ajust_int_size(StrToInt(rmvleadspace(copy(line,1,7))),999999);
      inc(config.logdays);
    END;
  {$I-} Close(ul); {$I+}
  IF (IOResult <> 0) THEN
  BEGIN
    WriteLn(^G^G^G'Unable to close USAGE.LOG!');
    Halt;
  END;
END;

(*
read_dir_file(dirpathname,uboards.filename,uboards.name,uboards.dlpathname,
              uboards.noratiogroupnum shr 1,tempgrp,uboards.seenames,
               uboards.flags,frec);
*)

PROCEDURE read_dir_file(dirpath: pathstr; dirname: str8; name: str160;
                        dlpath: str30; area: word;
                        FAflags: FAFlagSet; VAR frec: f_array);
const
  maxfileblock = 30000 div sizeof(FileInfoRecordType);  {* Allocate 30K *}
type
  fileblocktype = ARRAY[1..maxfileblock] OF FileInfoRecordType;
VAR
  udir: FILE;
  fileblock: ^fileblocktype;
  Counter,counter1: byte;
  fnum,realfileblockcount,recnum: word;
BEGIN
  Assign(udir,dirpath+dirname+'.DIR');
  {$I-} Reset(udir,sizeof(FileInfoRecordType)); {$I+}
  IF (IOResult = 0) THEN
  BEGIN
    IF (filesize(udir) > 1) THEN
    BEGIN
      recnum := 0;
      new(fileblock);
      seek(udir,1);
      REPEAT
        blockread(udir,fileblock^,maxfileblock,realfileblockcount);
        FOR fnum := 1 to realfileblockcount DO
        BEGIN
          inc(recnum);
          FOR Counter := 1 to 20 DO
            IF (fileblock^[fnum].Downloaded > frec[Counter].Downloaded) THEN
            BEGIN
              IF (Counter <= (20 - 1)) THEN
                FOR counter1 := (20 - 1) downto Counter DO
                  frec[counter1 + 1] := frec[counter1];
              frec[Counter].recnum := recnum;
              frec[Counter].filename := fileblock^[fnum].filename;
              frec[Counter].description := fileblock^[fnum].description;
              frec[Counter].Downloaded := fileblock^[fnum].Downloaded;
              frec[Counter].blocks := fileblock^[fnum].blocks;
              frec[Counter].owner := fileblock^[fnum].ownername;
              frec[Counter].date := fileblock^[fnum].date;
              frec[Counter].daten := fileblock^[fnum].daten;
              frec[Counter].FIflags := fileblock^[fnum].fIFlags;
              frec[Counter].points := fileblock^[fnum].credits;
              frec[Counter].dirpath := dirpath;
              frec[Counter].dirname := dirname;
              frec[Counter].DLPath := dlpath;
              frec[Counter].FAflags := FAflags;
              frec[Counter].areaname := name;
              frec[Counter].area := area;
              Counter := 20;
           END;
        END;
      UNTIL (realfileblockcount < maxfileblock);
      dispose(fileblock);
    END;
    {$I-} Close(udir); {$I+}
    IF (IOResult <> 0) THEN
    BEGIN
      WriteLn(^G^G^G'Unable to close '+dirname+'.DIR!');
      Halt;
    END;
  END;
END;

PROCEDURE read_fboard_file(General: GeneralRecordType; VAR frec: f_array);
VAR
  FileAreaFile: FILE OF FileAreaRecordType;
  Filearea: FileAreaRecordType;
  dirpathname: str160;
  Counter: byte;
  grp: ARRAY[0..127] OF integer;
  tempgrp: integer;
BEGIN
  Assign(FileAreaFile,General.DataPath+'FBOARDS.DAT');
  {$I-} Reset(FileAreaFile); {$I+}
  IF (IOResult <> 0) THEN
  BEGIN
    WriteLn(^G^G^G'Unable to access FBOARDS.DAT!');
    Halt;
  END;
  FOR Counter := 0 to 127 DO
    grp[Counter] := -1;
  tempgrp := -1;
  init_f_array(frec);
  while not eof(FileAreaFile) DO
  BEGIN
    {$I-} read(FileAreaFile,Filearea); {$I+}
    IF (IOResult <> 0) THEN
    BEGIN
      WriteLn(^G^G^G'Unable to read FBOARDS.DAT!');
      {$I-} Close(FileAreaFile); {$I+}
      IF (IOResult <> 0) THEN
        WriteLn(^G^G^G'Unable to close FBOARDS.DAT!');
      Halt;
    END;
    (*
    IF General.dynamicfile THEN
    BEGIN
      inc(grp[Filearea.noratiogroupnum shr 1]);
      tempgrp := grp[Filearea.noratiogroupnum shr 1];
    END
    ELSE
      inc(tempgrp);
    *)
    dirpathname := Filearea.DLPath;
    (*
    IF (Filearea.dsl <= thisuser.dsl) AND (Filearea.arlvl IN thisuser.ar) OR
      (Filearea.dsl <= thisuser.dsl) AND (Filearea.arlvl = '@') THEN
    BEGIN
    *)

      read_dir_file(dirpathname,Filearea.filename,Filearea.name,Filearea.DLPath,Counter,
                    Filearea.FAflags,frec);
    (*
    END;
    *)
  END;
  {$I-} Close(FileAreaFile); {$I+}
  IF (IOResult <> 0) THEN
  BEGIN
    WriteLn(^G^G^G'Unable to close FBOARDS.DAT!');
    Halt;
  END;
END;

(*
PROCEDURE menu_line(c,c1: Char; s,s1: str160);
BEGIN
  IF (c <> ' ') THEN
  BEGIN
    IF (length(s) > 32) THEN
      s := copy(s,1,32);
    Prompt(#3'1['#3'3'+c+#3'1] : '+addspace(s,33,false));
  END
  ELSE
    Prompt(addspace(s,39,true));
  IF (c1 <> ' ') THEN
  BEGIN
    IF (length(s1) > 32) THEN
      s1 := copy(s1,1,32);
    Prompt(#3'1['#3'3'+c1+#3'1] : '+addspace(s1,33,false));
  END;
  NL;
END;

PROCEDURE menu1_line(c: Char; s: str160);
BEGIN
  IF (length(s) > 73) THEN
    s := copy(s,1,73);
  PrintACR(#3'1['#3'3'+c+#3'1] : '+s);
END;
*)

PROCEDURE sys_menu_line(s,s1: str160);
BEGIN
  Prompt(#3'1'+s+#3'0'+s1);
END;

PROCEDURE sys_menu_line1(s,s1: str160);
BEGIN
  PrintACR(#3'1'+s+#3'0'+s1);
END;

PROCEDURE hdr(s: str160);
BEGIN
  CLS;
  PrintACR(#3'5'+center('-=[ '+s+' ]=-',78,true));
  NL;
END;

(*
PROCEDURE ftr(s: str160);
BEGIN
  NL;
  menu1_line('Q','Return To '+s);
  NL;
  Prompt(#3'4['#3'1'+realtostr1(nsl / 60,0,0)+' Mins Left'#3'4] Enter Command > '#3'1');
END;
*)

PROCEDURE display_t_array(decimal,width: byte; t_ar: t_array; title,
                          header: str160);
VAR
  Counter,counter1: byte;
BEGIN
  hdr('Top 10 '+title);
  PrintACR(#3'2##   User Name         '+center(header,55,true));
  NL;
  FOR Counter := 1 to 10 DO
  BEGIN
    Prompt(#3'4'+PadRightStr(IntToStr(Counter),2));
    IF (config.use_real) AND (t_ar[Counter].name = allcaps(thisuser.RealName)+' #'+IntToStr(usernum))
      OR (t_ar[Counter].name = thisuser.Name+' #'+IntToStr(usernum)) THEN
        Prompt('   '#3'8'+t_ar[Counter].name+' '#3'9')
    ELSE
      Prompt('   '#3'1'+t_ar[Counter].name+' '#3'9');
    FOR counter1 := (length(t_ar[Counter].name) + 1) to 42 DO
      Prompt('.');
    IF (t_ar[Counter].info > 0) THEN
      PrintACR(#3'4'+PadRightStr(realtostr(t_ar[counter].info,0,decimal),width))
    ELSE
      NL;
  END;
  PauseScr(FALSE);
END;

(*
PROCEDURE display_t_freqcall(decimal,width: byte; t_ar: t_array; title,
                             header: str160);
VAR
  Counter,counter1: byte;
BEGIN
  hdr('Top 10 '+title);
  PrintACR(#3'2##   User Name         '+center(header,55,true));
  NL;
  FOR Counter := 1 to 10 DO
  BEGIN
    Prompt(#3'4'+addspace(IntToStr(Counter),2,true));
    IF config.use_real AND (t_ar[Counter].name = allcaps(thisuser.RealName)+' #'+IntToStr(thisuser.usernum))
      OR (t_ar[Counter].name = thisuser.Name+' #'+IntToStr(thisuser.usernum)) THEN
        Prompt('   '#3'8'+t_ar[Counter].name+' '#3'9')
    ELSE
      Prompt('   '#3'1'+t_ar[Counter].name+' '#3'9');
    FOR counter1 := (length(t_ar[Counter].name) + 1) to 42 DO
      Prompt('.');
    IF (t_ar[Counter].info < 255) THEN
      PrintACR(#3'4'+addspace(realtostr1(t_ar[Counter].info,0,decimal),width,true))
    ELSE
      NL;
  END;
  PauseScr(FALSE);
END;
*)

(*
PROCEDURE graph_yes(tf: boolean; VAR first: b_array; i,g_fg,g_bg: byte);
BEGIN
  IF (ANSI IN thisuser.Flags) THEN
  BEGIN
    ds_textcolor(g_fg);
    Prompt('лл');
    IF first[i] THEN
    BEGIN
      ds_textcolor(g_bg);
      Prompt('п');
      first[i] := false;
    END
    ELSE
    BEGIN
      ds_textcolor(black);
      Prompt('л');
      IF not tf THEN
        ds_textcolor(g_bg);
    END;
  END
  ELSE
    Prompt('###');
END;

PROCEDURE graph_no;
BEGIN
  IF (ANSI IN thisuser.Flags) THEN
    Prompt('ллл')
  ELSE
    Prompt('...');
END;

PROCEDURE display_g_sysactivity(config: configinfo; gdate: d_array; gsysact:
                                gsysactivity; s: str160);
VAR
  first: b_array;
  Counter,counter1: byte;
  average: real;
  tf: boolean;
BEGIN
  FOR Counter := 1 to 20 DO
    first[Counter] := true;
  average := 0.0;
  CLS;
  PrintACR(#3'5           '+center('-=[ Graph Of System Activity By Percentage ]=-',60,true));
  FOR Counter := 20 downto 1 DO
  BEGIN
    average := average + gsysact[Counter];
    IF (copy(s,Counter,1) <> ' ') THEN
      Prompt(#3'5'+copy(s,Counter,1))
    ELSE
      Prompt(' ');
    Prompt(#3'2'+addspace(IntToStr(Counter * 5),7,true)+'%  ');
    FOR counter1 := 20 downto 1 DO
      IF (gsysact[counter1] >= (Counter * 5)) THEN
      BEGIN
        tf := true;
        IF (counter1 > 1) THEN
        BEGIN
          tf := false;
          IF (gsysact[counter1 - 1] >= Counter * 5) THEN
            tf := true;
        END;
        graph_yes(tf,first,counter1,config.graph_fg,config.graph_bg)
      END
      ELSE
      BEGIN
        IF (counter1 = 20) THEN
          ds_textcolor(config.graph_bg);
        graph_no;
      END;
    NL;
  END;
  ds_ansi_color(2);
  tf := false;
  FOR Counter := 20 downto 1 DO
    IF (gdate[Counter] <> '') AND not tf THEN
    BEGIN
      Prompt(addspace(graph_month(gdate[Counter])+' ',11,true));
      tf := true;
    END;
  IF not tf THEN
    Prompt('           ');
  FOR Counter := 20 downto 1 DO
    IF (gdate[Counter] <> '') THEN
      Prompt(copy(gdate[Counter],4,2)+' ')
    ELSE
      Prompt('   ');
  IF (gdate[1] <> '') THEN
    PrintACR(graph_month(gdate[1]))
  ELSE
    NL;
  average := average / config.logdays;
  PrintACR(#3'5           '+center('(Average '+reverse_str(s)+': '+realtostr1(average,0,0)+'%)',60,true));
  PauseScr(FALSE);
END;

PROCEDURE display_g_array(config: configinfo; gdate: d_array; g_ar: g_array;
                          title,side: str160; increment: longint);
VAR
  first: b_array;
  Counter,counter1: byte;
  average: longint;
  tf: boolean;
BEGIN
  FOR Counter := 1 to 20 DO
    first[Counter] := true;
  average := 0;
  CLS;
  PrintACR(#3'5           '+center('-=[ Graph Of '+title+' ]=-',60,true));
  FOR Counter := 20 downto 1 DO
  BEGIN
    Inc(average,g_ar[Counter]);
    IF (copy(side,Counter,1) <> ' ') THEN
      Prompt(#3'5'+copy(side,Counter,1))
    ELSE
      Prompt(' ');
    Prompt(#3'2'+addspace(IntToStr(Counter * increment),7,true)+'   ');
    FOR counter1 := 20 downto 1 DO
      IF (g_ar[counter1] >= (Counter * increment)) THEN
      BEGIN
        tf := true;
        IF (counter1 > 1) THEN
        BEGIN
          tf := false;
          IF (g_ar[counter1 - 1] >= (Counter * increment)) THEN
            tf := true;
        END;
        graph_yes(tf,first,counter1,config.graph_fg,config.graph_bg)
      END
      ELSE
      BEGIN
        IF (counter1 = 20) THEN
          ds_textcolor(config.graph_bg);
        graph_no;
      END;
    NL;
  END;
  ds_ansi_color(2);
  tf := false;
  FOR Counter := 20 downto 1 DO
    IF (gdate[Counter] <> '') AND not tf THEN
    BEGIN
      Prompt(addspace(graph_month(gdate[Counter])+' ',11,true));
      tf := true;
    END;
  IF not tf THEN
    Prompt('           ');
  FOR Counter := 20 downto 1 DO
    IF (gdate[Counter] <> '') THEN
      Prompt(copy(gdate[Counter],4,2)+' ')
    ELSE
      Prompt('   ');
  IF (gdate[1] <> '') THEN
    PrintACR(graph_month(gdate[1]))
  ELSE
    NL;
  average := average div config.logdays;
  PrintACR(#3'5           '+center('(Average '+reverse_str(side)+': '+IntToStr(average)+')',60,true));
  PauseScr(FALSE);
END;

function div_g(g: g_array): longint;
VAR
  i: byte;
  Counter: longint;
  big: longint;
  num: real;

  function div_size(num: real): longint;
  BEGIN
    IF (num <= 1) THEN
      div_size := 1
    ELSE IF (num < 2) THEN
      div_size := 2
    ELSE IF (num < 3) THEN
      div_size := 3
    ELSE IF (num < 4) THEN
      div_size := 4
    ELSE IF (num < 5) THEN
      div_size := 5
    ELSE
    BEGIN
      Counter := 5;
      REPEAT
        Inc(Counter);
      UNTIL (num > 999999) OR (Counter > num);
      div_size := Counter;
    END;
  END;

BEGIN
  big := 0;
  FOR i := 1 to 20 DO
    big := max(big,g[i]);
  num := big / 20;
  div_g := div_size(num);
END;

PROCEDURE display_m_array(m_ar: m_array; title,desc1,desc2,desc3: str160; StrToInt: byte);
VAR
  len: byte;

  PROCEDURE m_line(s: str160; w: word);
  VAR
    Counter: byte;
  BEGIN
    Prompt(#3'1'+s+' '#3'9');
    FOR Counter := 1 to (len - length(s)) DO
      Prompt('.');
    PrintACR(#3'4'+addspace(IntToStr(w),StrToInt+1,true));
  END;

BEGIN
  len := 0;
  len := max(len,length(desc1));
  len := max(len,length(desc2));
  len := max(len,length(desc3));
  Inc(len,3);
  hdr(title);
  m_line(desc1,m_ar[1]);
  m_line(desc2,m_ar[2]);
  IF (desc3 = 'Total Not Specified') AND (m_ar[3] > 0) OR (desc3 = 'The Oldest User Is') THEN
    m_line(desc3,m_ar[3]);
  PauseScr(FALSE);
END;

PROCEDURE display_h_array(ubaud: h_array);

  PROCEDURE baud_line(s: str160; w: word);
  VAR
    Counter: byte;
  BEGIN
    Prompt(#3'1Total '+s+' Baud Callers '#3'9');
    FOR Counter := 1 to (27 - length('Total '+s+' Baud Callers')) DO
      Prompt('.');
    PrintACR(#3'4'+addspace(IntToStr(w),6,true));
  END;

BEGIN
  hdr('User Baud Rate Statistics');
  IF (ubaud[1] > 0) THEN
    baud_line('300',ubaud[1]);
  IF (ubaud[2] > 0) THEN
    baud_line('1200',ubaud[2]);
  IF (ubaud[3] > 0) THEN
    baud_line('1275',ubaud[3]);
  IF (ubaud[4] > 0) THEN
    baud_line('2400',ubaud[4]);
  IF (ubaud[5] > 0) THEN
    baud_line('4800',ubaud[5]);
  IF (ubaud[6] > 0) THEN
    baud_line('7200',ubaud[6]);
  IF (ubaud[7] > 0) THEN
    baud_line('9600',ubaud[7]);
  IF (ubaud[8] > 0) THEN
    baud_line('12000',ubaud[8]);
  IF (ubaud[9] > 0) THEN
    baud_line('14400',ubaud[9]);
  IF (ubaud[10] > 0) THEN
    baud_line('16800',ubaud[10]);
  IF (ubaud[11] > 0) THEN
    baud_line('19200',ubaud[11]);
  IF (ubaud[12] > 0) THEN
    baud_line('21600',ubaud[12]);
  IF (ubaud[13] > 0) THEN
    baud_line('24000',ubaud[13]);
  IF (ubaud[14] > 0) THEN
    baud_line('26400',ubaud[14]);
  IF (ubaud[15] > 0) THEN
    baud_line('28800',ubaud[15]);
  IF (ubaud[16] > 0) THEN
    baud_line('38400',ubaud[16]);
  IF (ubaud[17] > 0) THEN
    baud_line('57600',ubaud[17]);
  IF (ubaud[18] > 0) THEN
    baud_line('64000',ubaud[18]);
  IF (ubaud[19] > 0) THEN
    baud_line('115200',ubaud[19]);
  PauseScr(FALSE);
END;

PROCEDURE todayusage(General: GeneralRecordType);
BEGIN
  CLS;
  WITH General DO
  BEGIN
    PrintACR(#3'5'+center('-=[ Todays Usage ]=-',78,true));
    sys_menu_line('                      Date:',datestr);
    sys_menu_line1('         Time:',timestr);
    NL;
    sys_menu_line1('Board Name      :',boardname);
    sys_menu_line1('Node Number     :',IntToStr(nodenumber));
    sys_menu_line1('Board Address   :',boardcitystate);
    sys_menu_line1('SysOp Name      :',sysopname);
    sys_menu_line1('Phone Number    :',boardphone);
    sys_menu_line('Mail Address    :',IntToStr(address.zone)+':'+IntToStr(address.net)+'/'+IntToStr(address.node));
    IF (address.point > 0) THEN
      PrintACR('.'+IntToStr(address.point))
    ELSE
      NL;
    sys_menu_line1('BBS Software    :','T.A.G. Version '+lasttagversion);
    NL;
    sys_menu_line1('Total Calls     :',realtostr1(callernum,0,0));
    sys_menu_line1('Number Of Users :',realtostr1(users,0,0));
    sys_menu_line1('Last Caller     :',lastcaller);
    NL;
    PrintACR(#3'5'+center('-=[ Summary Of Activity ]=-',78,true));
    sys_menu_line('Minutes Active  :',addspace(IntToStr(activetoday),9,false));
    sys_menu_line('Calls Today     :',addspace(IntToStr(callstoday),9,false));
    sys_menu_line1('New Users Today :',addspace(IntToStr(nuserstoday),9,false));
    sys_menu_line('Percent Active  :',addspace(return_percent(activetoday),9,false));
    sys_menu_line('Time/User       :',addspace(return_time(activetoday,callstoday),9,false));
    sys_menu_line1('Public Posts    :',addspace(IntToStr(msgposttoday),9,false));
    sys_menu_line('Private Posts   :',addspace(IntToStr(emailtoday),9,false));
    sys_menu_line('Feedback Sent   :',addspace(IntToStr(fbacktoday),9,false));
    sys_menu_line1('Errors Today    :',addspace(IntToStr(errorstoday),9,false));
    sys_menu_line('Number Uploads  :',addspace(IntToStr(ultoday),9,false));
    sys_menu_line('UL K-Bytes      :',addspace(realtostr1(ulktoday,0,0)+'K',9,false));
    sys_menu_line1('Number Downloads:',addspace(IntToStr(dltoday),9,false));
    sys_menu_line1('DL K-Bytes      :',addspace(realtostr1(dlktoday,0,0)+'K',9,false));
  END;
  PauseScr(FALSE);
END;

PROCEDURE chlen(s: str78; i,i1: integer);
VAR
  line1,line2,temp: str160;
  Counter: integer;
BEGIN
  s := rmvleadspace(rmvtrailspace(s));
  while (pos('  ',s) > 0) DO
    delete(s,pos('  ',s),1);
  IF (length(s) > i) THEN
  BEGIN
    line1 := copy(s,1,i);
    while (line1[length(line1)] <> ' ') DO
    BEGIN
      delete(line1,length(line1),1);
      dec(i);
    END;
    line1 := rmvtrailspace(line1);
    line2 := copy(s,i + 1,length(s));
    line2 := rmvleadspace(line2);
    temp := '';
    FOR Counter := 1 to i1 DO
      temp := ' ' + temp;
    PrintACR(#3'0'+line1);
    Prompt(temp);
    Prompt(#3'1:');
    PrintACR(#3'0'+line2);
  END
  ELSE
    PrintACR(#3'0'+s);
END;

PROCEDURE write_status_file(General: GeneralRecordType);
VAR
  systatf: FILE OF GeneralRecordType;
BEGIN
  Assign(systatf,paramstr(1)+'\RENEGADE.DAT');
  {$I-} Reset(systatf); {$I+}
  IF (IOResult <> 0) THEN
  BEGIN
    WriteLn(^G^G^G'Unable to access STATUS.DAT!');
    Halt;
  END;
  {$I-} Write(systatf,General); {$I+}
  IF (IOResult <> 0) THEN
  BEGIN
    WriteLn(^G^G^G'Unable to close STATUS.DAT!');
    {$I-} Close(systatf); {$I+}
    IF (IOResult <> 0) THEN
      WriteLn(^G^G^G'Unable to close STATUS.DAT!');
    Halt;
  END;
  {$I-} Close(systatf); {$I+}
  IF (IOResult <> 0) THEN
  BEGIN
    WriteLn(^G^G^G'Unable to close STATUS.DAT!');
    Halt;
  END;
END;

PROCEDURE write_user_file(user: UserRecordType);
VAR
  uf: FILE OF UserRecordType;
  fvar: dos.filerec;
BEGIN
  Assign(uf,General.DataPath+'USER.LST');
  {$I-} Reset(uf); {$I+}
  IF (IOResult <> 0) THEN
  BEGIN
    WriteLn(^G^G^G'Unable to access USER.LST!');
    Halt;
  END;
  seek(uf,user.usernum);
  WITH fvar DO
    lockfile(handle,lock,user.usernum*recsize,recsize);
  {$I-} Write(uf,user); {$I+}
  WITH fvar DO
    lockfile(handle,unlock,user.usernum*recsize,recsize);
  IF (IOResult <> 0) THEN
  BEGIN
    WriteLn(^G^G^G'Unable to close USER.LST!');
    {$I-} Close(uf); {$I+}
    IF (IOResult <> 0) THEN
      WriteLn(^G^G^G'Unable to close USER.LST!');
    Halt;
  END;
  {$I-} Close(uf); {$I+}
  IF (IOResult <> 0) THEN
  BEGIN
    WriteLn(^G^G^G'Unable to close USER.LST!');
    Halt;
  END;
END;

PROCEDURE write_dir_file(b: byte; frec: f_array);
VAR
  udir: FILE OF FileInfoRecordType;
  udirfile: FileInfoRecordType;
  fvar: dos.filerec;
BEGIN
  Assign(udir,frec[b].dirpath+frec[b].dirname+'.DIR');
  {$I-} Reset(udir); {$I+}
  IF (IOResult <> 0) THEN
  BEGIN
    WriteLn(^G^G^G'Unable to access '+frec[b].dirname+'.DIR!');
    Halt;
  END;
  WITH udirfile DO
  BEGIN
    filename := frec[b].filename;
    description := frec[b].description;
    Downloaded := frec[b].Downloaded + 1;
    unused := frec[b].unused;
    blocks := frec[b].blocks;
    owner := frec[b].owner;
    date := frec[b].date;
    daten := frec[b].daten;
    flag := frec[b].flag;
    points := frec[b].points;
  END;
  seek(udir,frec[b].recnum);
  WITH fvar DO
    lockfile(handle,lock,frec[b].recnum*recsize,recsize);
  {$I-} Write(udir,udirfile); {$I+}
  WITH fvar DO
    lockfile(handle,unlock,frec[b].recnum*recsize,recsize);
  IF (IOResult <> 0) THEN
  BEGIN
    WriteLn(^G^G^G'Unable to close '+frec[b].dirname+'.DIR!');
    {$I-} Close(udir); {$I+}
    IF (IOResult <> 0) THEN
      WriteLn(^G^G^G'Unable to close '+frec[b].dirname+'.DIR!');
    Halt;
  END;
  {$I-} Close(udir); {$I+}
  IF (IOResult <> 0) THEN
  BEGIN
    WriteLn(^G^G^G'Unable to close '+frec[b].dirname+'.DIR!');
    Halt;
  END;
END;

PROCEDURE top20file(frec: f_array);
VAR
  c: Char;
  s,s1: str160;
  Counter,counter1: byte;
  tempsize: longint;
  tf: boolean;
BEGIN
  REPEAT
    REPEAT
      counter1 := 0;
      c := #0;
      s := '';
      hdr('Top 20 Files Downloaded');
      PrintACR(#3'2##   Filename.Ext  Number Downloads         ##   Filename.Ext  Number Downloads');
      NL;
      FOR Counter := 1 to 10 DO
      BEGIN
        Prompt(#3'4'+addspace(IntToStr(Counter),2,true));
        Prompt(#3'1'+addspace(frec[Counter].filename,15,true));
        IF (frec[Counter].Downloaded > 0) THEN
        BEGIN
          Prompt(#3'4'+addspace(IntToStr(frec[Counter].Downloaded),12,true));
          inc(counter1);
        END
        ELSE
          Prompt('            ');
        Prompt('               ');
        Prompt(#3'4'+addspace(IntToStr(Counter+10),2,true));
        Prompt(#3'1'+addspace(frec[Counter+10].filename,15,true));
        IF (frec[Counter+10].Downloaded > 0) THEN
        BEGIN
          PrintACR(#3'4'+addspace(IntToStr(frec[Counter+10].Downloaded),12,true));
          inc(counter1);
        END
        ELSE
          PrintACR('      ');
      END;
      NL;
      menu1_line('#','Number for Extended File Information');
      menu1_line('Q','Return To T.A.G. Statistics File Menu');
      NL;
      Prompt(#3'4['#3'1'+realtostr1(nsl / 60,0,0)+' Mins Left'#3'4] Enter Command > '#3'1');
      IF (length(IntToStr(counter1)) = 1) THEN
      BEGIN
        FOR Counter := 1 to counter1 DO
          s := s + IntToStr(Counter);
        OneK(c,'Q'+s);
        s := c;
      END
      ELSE
      BEGIN
        ds_input(s,2,false,false,true,false);
        s := rmvleadspace(s);
      END;
    UNTIL (s <> #1) OR ds_hangup;
    IF (StrToInt(s) >= 1) AND (StrToInt(s) <= counter1) THEN
    BEGIN
      hdr('Extended File Information');
      WITH frec[StrToInt(s)] DO
      BEGIN
        PrintACR(#3'1Group #      :'#3'5'+IntToStr(group));
        PrintACR(#3'1Area #       :'#3'5'+IntToStr(area));
        PrintACR(#3'1Area Name    :'#3'5'+striptagcodes(areaname));
        Prompt(#3'1File Name    :'#3'0'+rmvspace(filename));
        IF (notvalidated IN flag) THEN
          Prompt(#3'8 <NOT-VALIDATED>');
        NL;
        Prompt(#3'1Description  :');
        chlen(description,65,13);
        PrintACR(#3'1File Points  :'#3'5'+IntToStr(points));
        Prompt(#3'1File Size    :');
        tempsize := blocks;
        Prompt(#3'5'+IntToStr(tempsize * 128)+' Bytes / ');
        Prompt(IntToStr(tempsize)+' XModem Blks / ');
        PrintACR(realtostr1(((tempsize * 128) + 1023) / 1024,0,0)+' YModem Blks');
        PrintACR(#3'1Date U/L''ed  :'#3'5'+date);
        PrintACR(#3'1Times D/L''ed :'#3'3'+IntToStr(Downloaded));
        IF (thisuser.dsl >= seenames) THEN
          PrintACR(#3'1Uploaded By  :'#3'3'+owner);
        NL;
        IF (thisuser.dsl >= config.dldsl) THEN
        BEGIN
          Prompt(#3'7Download file (y/[N]? ');
          IF ds_yesnoresp THEN
          BEGIN
            NL;
            tf := true;
            IF (ISCDROM IN flags) THEN
            BEGIN
              Prompt('Copying file ... ');
              swapvectors;
              exec(getenv('COMSPEC'),'/C copy '+DLPath+rmvspace(filename)+
                   ' '+copy(General.tempdlpath,1,length(General.tempdlpath)-1));
              swapvectors;
              IF (doserror = 0) THEN
              BEGIN
                PrintACR('Successful');
                DLPath := General.tempdlpath;
                tf := true;
              END
              ELSE
              BEGIN
                PrintACR('Failed');
                tf := false;
              END;
              NL;
            END;
            IF tf THEN
            BEGIN
              Prompt('['#3'3X'#3'1]Modem, ['#3'3Y'#3'1]Modem, ['#3'3Z'#3'1]Modem, ['#3'3Q'#3'1]uit: ');
              OneK(c,'QXYZ');
              CASE c OF
                'X' : s1 := 'protocol dsz port '+IntToStr(General.comport)+' sx -s '+DLPath+rmvspace(filename);
                'Y' : s1 := 'protocol dsz port '+IntToStr(General.comport)+' sb -s '+DLPath+rmvspace(filename);
                'Z' : s1 := 'protocol dsz port '+IntToStr(General.comport)+' sz -m -s '+DLPath+rmvspace(filename);
              END;
              IF (c <> 'Q') THEN
              BEGIN
                NL;
                Prompt('Ready to send file, ^X to abort...');
                swapvectors;
                exec(getenv('COMSPEC'),'/C '+s1);
                swapvectors;
                delay(2000);
                General.dlktoday := General.dlktoday + (((tempsize * 128) + 1023) / 1024);
                Inc(General.dltoday);
                write_status_file(General);
                thisuser.dlk := thisuser.dlk + (((tempsize * 128) + 1023) / 1024);
                Inc(thisuser.numdl);
                write_user_file(thisuser);
                write_dir_file(StrToInt(s),frec);
                ds_sysop_window;
              END;
            END;
          END;
        END
        ELSE
          PauseScr(FALSE);
      END;
    END;
  UNTIL (s[1] = 'Q') OR DS_hangup;
END;


PROCEDURE mainmenuscr(bbsname: str160);
BEGIN
  hdr('T.A.G. Statistics Main Menu');
  menu1_line('A','User Statistics');
  menu1_line('B','Usage Statistics');
  menu1_line('C','File Statistics');
  ftr(bbsname);
END;

PROCEDURE usermenuscr;
BEGIN
  hdr('T.A.G. Statistics User Menu');
  menu1_line('A','Top 10 User Menu');
  menu1_line('B','User Age');
  menu1_line('C','User Gender');
  menu1_line('D','User Baud Rate');
  ftr('T.A.G. Statistics Main Menu');
END;

PROCEDURE usagemenuscr;
BEGIN
  hdr('T.A.G. Statistics Usage Menu');
  menu1_line('A','Usage Graph Menu');
  menu1_line('B','Todays Usage');
  ftr('T.A.G. Statistics Main Menu');
END;

PROCEDURE fboardmenuscr;
BEGIN
  hdr('T.A.G. Statistics File Menu');
  menu1_line('A','Top 20 Files Downloaded');
  ftr('T.A.G. Statistics Main Menu');
END;

PROCEDURE top10menuscr;
BEGIN
  hdr('T.A.G. Statistics Top 10 User Menu');
  menu_line('A','B','Most Frequent Callers','High Time Users');
  menu_line('C','D','File Kbyte Uploaders','File Kbyte Downloaders');
  menu_line('E','F','Private Message Senders','Public Message Posters');
  menu_line('G','H','SysOp Feedback Senders','All Time Callers');
  menu_line('I','J','File Uploaders','File Downloaders');
  menu_line('K','L','File Points','Upload/Download Ratios');
  menu_line('M',' ','Post/Call Ratios','');
  ftr('T.A.G. Statistics User Menu');
END;

PROCEDURE graph20menuscr;
BEGIN
  hdr('T.A.G. Statistics Usage Graph Menu');
  menu_line('A','B','Minutes Active','Number Of Calls');
  menu_line('C','D','New User Logons','System Activity');
  menu_line('E','F','Average Time/User','Public Message Posting');
  menu_line('G','H','Private Message Posting','SysOp Feedback Sent');
  menu_line('I','J','Number Of Errors','File Uploads');
  menu_line('K','L','File Kbytes Uploaded','File Downloads');
  menu_line('M',' ','File Kbytes Downloaded','');
  ftr('T.A.G. Statistics Usage Menu');
END;

PROCEDURE mainmenu(General: GeneralRecordType; config: configinfo; tfreqc,tttimeon,
                   tulk,tdlk,tprivp,tpubp,tfeedback,tnumc,
                   tnumul,tnumdl,tfilep,tupd,tpostc: t_array; gdate: d_array;
                   gsysact: gsysactivity; gmina,gnumc,gnewu,gtimeu,gmsgpub,
                   gmsgpvt,gmsgfb,gnume,gful,gulkb,gfdl,gdlkb: g_array;
                   uage,usex: m_array; ubaud: h_array; frec: f_array);
VAR
  c: Char;
BEGIN
  REPEAT
    mainmenuscr(General.boardname);
    OneK(c,'QABC');
    CASE c OF
      'A' : BEGIN
              REPEAT
                usermenuscr;
                OneK(c,'QABCD');
                CASE c OF
                  'A' : BEGIN
                          REPEAT
                            top10menuscr;
                            OneK(c,'QABCDEFGHIJKLM');
                            CASE c OF
                              'A' : display_t_freqcall(3,12,tfreqc,'Most Frequent Callers',
                                                       'Average Number Of Days Between Calls');
                              'B' : display_t_array(0,8,tttimeon,'High Time Users',
                                                    'Total Number Of Minutes Online');
                              'C' : display_t_array(0,8,tulk,'File Kbyte Uploaders',
                                                    'Number Of Kbytes Uploaded');
                              'D' : display_t_array(0,8,tdlk,'File Kbyte Downloaders',
                                                    'Number Of Kbytes Downloaded');
                              'E' : display_t_array(0,6,tprivp,'Private Message Senders',
                                                    'Number Of Private Messages Sent');
                              'F' : display_t_array(0,6,tpubp,'Public Message Posters',
                                                    'Number Of Public Messages Posted');
                              'G' : display_t_array(0,6,tfeedback,'SysOp Feedback Senders',
                                                    'Number Of SysOp Feedback Sent');
                              'H' : display_t_array(0,6,tnumc,'All Time Callers',
                                                    'Number Of Calls To The System');
                              'I' : display_t_array(0,6,tnumul,'File Uploaders',
                                                    'Number Of Files Uploaded');
                              'J' : display_t_array(0,6,tnumdl,'File Downloaders',
                                                    'Number Of Files Downloaded');
                              'K' : display_t_array(0,6,tfilep,'File Points',
                                                    'Amount Of File Points On Hand');
                              'L' : display_t_array(3,12,tupd,'Upload/Download Ratios',
                                                    'Number Of KB Uploaded for Each KB Downloaded');
                              'M' : display_t_array(3,12,tpostc,'Post/Call Ratios',
                                                    'Number Of Public Messages Posted Each Call');
                            END;
                          UNTIL (c = 'Q') OR ds_hangup;
                          c := #0;
                        END;
                  'B' : display_m_array(uage,'User Age Statistics','The Average User Age Is',
                                  'The Youngest User Is','The Oldest User Is',3);
                  'C' : display_m_array(usex,'User Gender Statistics','Total Male Users',
                                       'Total Female Users','Total Not Specified',5);
                  'D' : display_h_array(ubaud);
                END;
              UNTIL (c = 'Q') OR ds_hangup;
              c := #0;
            END;
      'B' : BEGIN
              REPEAT
                usagemenuscr;
                OneK(c,'QAB');
                CASE c OF
                  'A' : BEGIN
                          REPEAT
                            graph20menuscr;
                            OneK(c,'QABCDEFGHIJKLM');
                            CASE c OF
                              'A' : display_g_array(config,gdate,gmina,'Total Minutes Active',
                                                    '         setuniM    ',div_g(gmina));
                              'B' : display_g_array(config,gdate,gnumc,'Total Calls',
                                                    '           sllaC    ',div_g(gnumc));
                              'C' : display_g_array(config,gdate,gnewu,'New User Logons To System',
                                                    '       sresU weN    ',div_g(gnewu));
                              'D' : display_g_sysactivity(config,gdate,gsysact,'         tnecreP    ');
                              'E' : display_g_array(config,gdate,gtimeu,'Average Time/User',
                                                    '         setuniM    ',div_g(gtimeu));
                              'F' : display_g_array(config,gdate,gmsgpub,'Public Messages Posted',
                                                    '        segasseM    ',div_g(gmsgpub));
                              'G' : display_g_array(config,gdate,gmsgpvt,'Private Messages Sent',
                                                    '        segasseM    ',div_g(gmsgpvt));
                              'H' : display_g_array(config,gdate,gmsgfb,'SysOp Feedback Sent',
                                                    '        segasseM    ',div_g(gmsgfb));
                              'I' : display_g_array(config,gdate,gnume,'Logon Errors',
                                                    '          srorrE    ',div_g(gnume));
                              'J' : display_g_array(config,gdate,gful,'File Uploads',
                                                    '           seliF    ',div_g(gful));
                              'K' : display_g_array(config,gdate,gulkb,'Total Upload Kbytes',
                                                    '          setybK    ',div_g(gulkb));
                              'L' : display_g_array(config,gdate,gfdl,'File Downloads',
                                                    '           seliF    ',div_g(gfdl));
                              'M' : display_g_array(config,gdate,gdlkb,'Total Download Kbytes',
                                                    '          setybK    ',div_g(gdlkb));
                            END;
                          UNTIL (c = 'Q') OR ds_hangup;
                          c := #0;
                        END;
                  'B' : todayusage(General);
                END;
              UNTIL (c = 'Q') OR ds_hangup;
              c := #0;
            END;
      'C' : BEGIN
              REPEAT
                fboardmenuscr;
                OneK(c,'QA');
                CASE c OF
                  'A' : top20file(frec);
                END;
              UNTIL (c = 'Q') OR DS_hangup;
              c := #0;
            END;
    END;
  UNTIL (c = 'Q') OR DS_hangup;
END;
*)

VAR
  GeneralFile: FILE OF GeneralRecordType;
  General: GeneralRecordType;

BEGIN
  (*
  read_config_file(config,chatconfig);
  read_usage_file(General,config,gdate,gsysact,gmina,gnumc,gnewu,gtimeu,
                  gmsgpub,gmsgpvt,gmsgfb,gnume,gful,gulkb,gfdl,gdlkb);
  *)
  Assign(GeneralFile,'C:\RG\RENEGADE.DAT');
  Reset(GeneralFile);
  Read(GeneralFile,General);
  Close(GeneralFile);

  read_user_file(General,config,uage,usex,ubaud,tfreqc,tttimeon,tulk,tdlk,
                 tprivp,tpubp,tfeedback,tnumc,tnumul,tnumdl,tfilep,tupd,
                 tpostc);
  display_t_array(0,6,tpubp,'Public Message Posters','Number Of Public Messages Posted');
  (*
  read_fboard_file(General,frec);
  mainmenu(General,config,tfreqc,tttimeon,tulk,tdlk,tprivp,tpubp,
           tfeedback,tnumc,tnumul,tnumdl,tfilep,tupd,tpostc,gdate,gsysact,
           gmina,gnumc,gnewu,gtimeu,gmsgpub,gmsgpvt,gmsgfb,gnume,gful,gulkb,
           gfdl,gdlkb,uage,usex,ubaud,frec);
  *)
END.
