UNIT RGSTAT;

{$M 65520,0,30000}

{Written By..........: The Renegade Developement Team}
{Date Started........: 01 Sep 2006}
{Last Update.........: ?? ??? ????}

INTERFACE

IMPLEMENTATION

USES
  Crt,
  Dos,
  Common;

TYPE
  (*
  Str3 = STRING[3];
  Str8 = STRING[8];
  Str12 = STRING[12];
  Str30 = STRING[30];
  Str36 = STRING[36];
  *)
  Str43 = STRING[43];
  (*
  Str78 = STRING[78];
  *)
  genrec = RECORD
    name : str43;
    info : real;
  END;

  b_array = ARRAY[1..20] OF boolean;
  d_array = ARRAY[1..20] OF str8;
  e_array = ARRAY[1..10] OF word;
  g_array = ARRAY[1..20] OF longint;
  gsysactivity = ARRAY[1..20] OF real;
  h_array = ARRAY[1..19] OF word;
  m_array = ARRAY[1..3] OF word;
  t_array = ARRAY[1..10] OF genrec;

  configinfo = RECORD
    exuser: e_array;
    graph_fg,
    graph_bg,
    logdays,
    dldsl: byte;
    use_real: boolean;
  END;

VAR
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
  tpubp: t_array;
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

function graph_month(s: str8): str3;
BEGIN
  CASE Value(copy(s,1,2)) OF
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

FUNCTION RmvLeadSpace(S: AStr): AStr;
BEGIN
  WHILE (S[1] = ' ') DO
    Delete(S,1,1);
  RmvLeadSpace := S;
END;

FUNCTION RmvTrailSpace(S: AStr): AStr;
BEGIN
  WHILE (S[Length(S)] = ' ') DO
    Delete(S,Length(S),1);
  RmvTrailSpace := S;
END;

function reverse_str(s: str160): str160;
VAR
  s1: str160;
  counter: byte;
BEGIN
  s1 := '';
  FOR counter := 20 downto 1 DO
    s1 := s1 + s[counter];
  reverse_str := rmvleadspace(rmvtrailspace(s1));
END;

function center(s: str160; i: integer; tf: boolean): str160;
VAR
  counter,strlength: integer;
  which_way: boolean;
BEGIN
  which_way := tf;
  strlength := length(s);
  FOR counter := (strlength + 1) TO i DO
  BEGIN
    IF which_way THEN
    BEGIN
      s := ' ' + s;
      which_way := false;
    END
    ELSE
    BEGIN
      s := s + ' ';
      which_way := TRUE;
    END;
  END;
  center := s;
END;

function return_time(w,w1: word): str160;
BEGIN
  IF (w > 0) and (w1 > 0) THEN
    return_time := inttostr(trunc(w div w1))
  ELSE
    return_time := '0';
END;

function age(s: str160): str160;
BEGIN
  age := inttostr(Value(copy(datestr,7,2)) - Value(copy(s,7,2)));
END;

function return_age(userbday: str160): str160;
VAR
  today,user_years: str160;
BEGIN
  today := datestr;
  user_years := age(userbday);
  IF (Value(copy(userbday,1,2)) > Value(copy(today,1,2))) THEN
    user_years := inttostr(Value(user_years)-1)
  ELSE
    IF (Value(copy(userbday,1,2)) = Value(copy(today,1,2))) THEN
      IF (Value(copy(userbday,4,2)) > Value(copy(today,4,2))) THEN
        user_years := inttostr(Value(user_years)-1);
  return_age := user_years;
END;

PROCEDURE read_config_file(VAR config: configinfo);
VAR
  f: text;
  line,line1: str160;
  counter,counter1: byte;
BEGIN
  assign(f,'TAGSTAT.CFG');
  {$I-} reset(f); {$I+}
  IF (ioresult <> 0) THEN
  BEGIN
    writeln(^G^G^G'Unable to access TAGSTAT.CFG!');
    halt;
  END;
  textcolor(lightgray);
  textbackground(black);
  with config DO
  BEGIN
    FOR counter1 := 1 TO 10 DO
      exuser[counter1] := 0;
    graph_fg := 9;
    graph_bg := 7;
    logdays := 0;
    dldsl := 255;
    use_real := false;
  END;
  counter := 1;
  counter1 := 0;
  WHILE not eof(f) DO
  BEGIN
    {$I-} readln(f,line); {$I+}
    IF (ioresult <> 0) THEN
    BEGIN
      writeln(^G^G^G'Unable to read TAGSTAT.CFG!');
      {$I-} close(f); {$I+}
      IF (ioresult <> 0) THEN
        writeln(^G^G^G'Unable to close TAGSTAT.CFG!');
      halt;
    END;
    line := rmvleadspace(rmvtrailspace(line));
    line1 := allcaps(line);
    IF (line1 <> '') and (line1[1] <> '%') THEN
    BEGIN
      IF (pos('USER_EXCLUDE',line1) = 1) and (counter1 < 10) THEN
      BEGIN
        Delete(line,1,12);
        inc(counter1);
        config.exuser[counter1] := Value(rmvleadspace(line));
      END
      ELSE IF (pos('DOWNLOAD_DSL',line1) = 1) THEN
      BEGIN
        Delete(line,1,12);
        config.dldsl := Value(rmvleadspace(line));
        IF (config.dldsl < 0) OR (config.dldsl > 255) THEN
          config.dldsl := 255;
      END
      ELSE IF (pos('REAL_NAME',line1) = 1) THEN
        config.use_real := TRUE
      ELSE IF (pos('GRAPH_BACKGROUND',line1) = 1) THEN
      BEGIN
        Delete(line,1,16);
        config.graph_bg := Value(rmvleadspace(line));
        IF (config.graph_bg < 0) OR (config.graph_bg > 15) THEN
          config.graph_bg := 7;
      END
      ELSE IF (pos('GRAPH_BARS',line1) = 1) THEN
      BEGIN
        Delete(line,1,10);
        config.graph_fg := Value(rmvleadspace(line));
        IF (config.graph_fg < 0) OR (config.graph_fg > 15) THEN
          config.graph_fg := 9;
      END;
    END;
  END;
  {$I-} close(f); {$I+}
  IF (ioresult <> 0) THEN
  BEGIN
    writeln(^G^G^G'Unable to close TAGSTAT.CFG!');
    halt;
  END;
END;

PROCEDURE init_d_array(VAR gdate: d_array);
VAR
  counter: byte;
BEGIN
  FOR counter := 1 TO 20 DO
    gdate[counter] := '';
END;

PROCEDURE init_g_array(VAR ar: g_array; info_val: longint);
VAR
  counter: byte;
BEGIN
  FOR counter := 1 TO 20 DO
    ar[counter] := info_val;
END;

PROCEDURE init_gsysactivity(VAR gsysact: gsysactivity);
VAR
  counter: byte;
BEGIN
  FOR counter := 1 TO 20 DO
    gsysact[counter] := 0.0;
END;

PROCEDURE init_h_array(VAR ar: h_array; info_val: word);
VAR
  counter: byte;
BEGIN
  FOR counter := 1 TO 19 DO
    ar[counter] := info_val;
END;

PROCEDURE init_m_array(VAR ar: m_array; info_val: word);
VAR
  counter: byte;
BEGIN
  FOR counter := 1 TO 3 DO
    ar[counter] := info_val;
END;

PROCEDURE init_t_array(VAR ar: t_array; info_val: real);
VAR
  counter: byte;
BEGIN
  FOR counter := 1 TO 10 DO
  BEGIN
    ar[counter].name := '';
    ar[counter].info := info_val;
  END;
END;

PROCEDURE sort_ascending(s: str43; r: real; VAR tfreqc: t_array);
VAR
  counter,counter1: byte;
BEGIN
  IF (r > 0.0) THEN
    FOR counter := 1 TO 10 DO
      IF (r <= tfreqc[counter].info) THEN
      BEGIN
        FOR counter1 := 10 downto counter DO
          IF ((counter1 - 1) > 0) THEN
            tfreqc[counter1] := tfreqc[counter1-1];
        tfreqc[counter].name := s;
        tfreqc[counter].info := r;
        counter := 10;
      END;
END;

PROCEDURE sort_descending(s: str43; r: real; VAR ar: t_array);
VAR
  counter,counter1: byte;
BEGIN
  IF (r > 0.0) THEN
    FOR counter := 1 TO 10 DO
      IF (r >= ar[counter].info) THEN
      BEGIN
        FOR counter1 := 10 downto counter DO
          IF ((counter1 - 1) > 0) THEN
            ar[counter1] := ar[counter1 - 1];
        ar[counter].name := s;
        ar[counter].info := r;
        counter := 10;
      END;
END;

PROCEDURE scrn_one;
BEGIN
  CLS;
  Print(#3'5'+center('Renegade BBS Statistics',78,TRUE));
  NL;
  Print(#3'5'+center('Copyright (c) 2006 The Renegade Developement Team',78,TRUE));
  NL;
  Print(#3'5'+center('Version 1.0',78,TRUE));
  NL;
  NL;
  Prompt(#3'2[> '#3'4One Moment Please ... ');
END;

PROCEDURE scrn_two(s: str160);
BEGIN
  window(1,1,80,25);
  CLS;
  Print(#3'1[> Returning to '+s+'... ');
  NL;
  delay(2000);
  clrscr;
END;

function in_array(w: word; exuser: e_array): boolean;
VAR
  counter: byte;
  tf: boolean;
BEGIN
  tf := false;
  FOR counter := 1 TO 10 DO
    IF (w = exuser[counter]) THEN
      tf := TRUE;
  in_array := tf;
END;

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
  counter,userage: byte;
  calltot,realuserblockcount: integer;
  name: str43;
BEGIN
  assign(uf,General.DataPath+'USER.LST');
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
    FOR unum := 1 TO realuserblockcount DO
      with userblock^[unum] DO
      BEGIN
        inc(recnum);
        calltot := 0;
        IF (recnum = usernum) and not in_array(usernum,config.exuser) THEN
        BEGIN
          userage := AgeUser(BirthDate);
          Inc(totuage,userage);
          (*
          uage[2] := min(uage[2],userage);
          uage[3] := max(userage,uage[3]);
          *)
          IF (Sex = 'M') THEN
            inc(usex[1])
          ELSE IF (Sex = 'F') THEN
            inc(usex[2])
          ELSE
            inc(usex[3]);
          (*
          IF (hbaud = 300) THEN
            inc(ubaud[1])
          ELSE IF (hbaud = 600) THEN
            inc(ubaud[2])
          ELSE IF (hbaud = 1200) THEN
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
          ELSE IF (hbaud = 31200) THEN
            inc(ubaud[16])
          ELSE IF (hbaud = 33600) THEN
            inc(ubaud[17])
          ELSE IF (hbaud = 38400) THEN
            inc(ubaud[18])
          ELSE IF (hbaud = 57600) THEN
            inc(ubaud[19])
          ELSE IF (hbaud = 115200) THEN
            inc(ubaud[20]);
          *)
          IF config.use_real THEN
            name := allcaps(realname)+' #'+inttostr(usernum)
          ELSE
            name := name+' #'+inttostr(usernum);
          sort_ascending(name,calltot/15,tfreqc);
          sort_descending(name,ttimeon,tttimeon);
          sort_descending(name,ulk,tulk);
          sort_descending(name,dlk,tdlk);
          sort_descending(name,privpost,tprivp);
          sort_descending(name,pubpost,tpubp);
          sort_descending(name,feedback,tfeedback);
          sort_descending(name,numcalls,tnumc);
          sort_descending(name,numul,tnumul);
          sort_descending(name,numdl,tnumdl);
          sort_descending(name,points,tfilep);
          sort_descending(name,ulk/maxr(1.0,dlk),tupd);
          sort_descending(name,pubpost/maxr(1.0,numcalls),tpostc);
          inc(numusers);
        END;
      END;
  UNTIL (realuserblockcount < maxuserblock);
  dispose(userblock);
  uage[1] := totuage div numusers;
  {$I-} close(uf); {$I+}
  IF (ioresult <> 0) THEN
  BEGIN
    writeln(^G^G^G'Unable to close USER.LST!');
    halt;
  END;
END;

PROCEDURE read_usage_file(General: GeneralRecordType; VAR config: configinfo; VAR
                          gdate: d_array; VAR gsysact: gsysactivity; VAR
                          gmina,gnumc,gnewu,gtimeu,gmsgpub,gmsgpvt,gmsgfb,
                          gnume,gful,gulkb,gfdl,gdlkb: g_array);
VAR
  ul: text;
  line: str160;
  counter: byte;

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
  IF General.multiuser THEN
  BEGIN
    IF fileexist(General.DataPath+'USAGE.LOG') THEN
      assigntxtfile(ul,General.DataPath+'USAGE.LOG')
    ELSE
      assigntxtfile(ul,General.multiuserpath+'USAGE.LOG');
  END
  ELSE
    assigntxtfile(ul,General.DataPath+'USAGE.LOG');
  {$I-} reset(ul); {$I+}
  IF (ioresult <> 0) THEN
  BEGIN
    writeln(^G^G^G'Unable to access USAGE.LOG!');
    halt;
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
  FOR counter := 1 TO 5 DO
  BEGIN
    {$I-} readln(ul); {$I+}
    IF (ioresult <> 0) THEN
    BEGIN
      writeln(^G^G^G'Unable to read USAGE.LOG!');
      {$I-} close(ul); {$I+}
      IF (ioresult <> 0) THEN
        writeln(^G^G^G'Unable to close USAGE.LOG!');
      halt;
    END;
  END;
  FOR counter := 1 TO 20 DO
    IF not eof(ul) THEN
    BEGIN
      {$I-} readln(ul,line); {$I+}
      IF (ioresult <> 0) THEN
      BEGIN
        writeln(^G^G^G'Unable to read USAGE.LOG!');
        {$I-} close(ul); {$I+}
        IF (ioresult <> 0) THEN
          writeln(^G^G^G'Unable to close USAGE.LOG!');
        halt;
      END;
      gdate[counter] := copy(line,1,8);
      Delete(line,1,8);
      gmina[counter] := ajust_int_size(Value(rmvleadspace(copy(line,1,6))),99999);
      Delete(line,1,6);
      gnumc[counter] := ajust_int_size(Value(rmvleadspace(copy(line,1,5))),9999);
      Delete(line,1,5);
      gnewu[counter] := ajust_int_size(Value(rmvleadspace(copy(line,1,5))),9999);
      Delete(line,1,5);
      gsysact[counter] := ajust_real_size(valuer(rmvleadspace(copy(line,1,6))),100.0);
      Delete(line,1,6);
      gtimeu[counter] := ajust_int_size(Value(rmvleadspace(copy(line,1,5))),9999);
      Delete(line,1,5);
      gmsgpub[counter] := ajust_int_size(Value(rmvleadspace(copy(line,1,5))),9999);
      Delete(line,1,5);
      gmsgpvt[counter] := ajust_int_size(Value(rmvleadspace(copy(line,1,5))),9999);
      Delete(line,1,5);
      gmsgfb[counter] := ajust_int_size(Value(rmvleadspace(copy(line,1,5))),9999);
      Delete(line,1,5);
      gnume[counter] := ajust_int_size(Value(rmvleadspace(copy(line,1,5))),9999);
      Delete(line,1,5);
      gful[counter] := ajust_int_size(Value(rmvleadspace(copy(line,1,5))),9999);
      Delete(line,1,5);
      gulkb[counter] := ajust_int_size(Value(rmvleadspace(copy(line,1,7))),999999);
      Delete(line,1,7);
      gfdl[counter] := ajust_int_size(Value(rmvleadspace(copy(line,1,5))),9999);
      Delete(line,1,5);
      gdlkb[counter] := ajust_int_size(Value(rmvleadspace(copy(line,1,7))),999999);
      inc(config.logdays);
    END;
  {$I-} close(ul); {$I+}
  IF (ioresult <> 0) THEN
  BEGIN
    writeln(^G^G^G'Unable to close USAGE.LOG!');
    halt;
  END;
END;

PROCEDURE read_dir_file(dirpath: pathstr; dirname: str8; name: str160;
                        dlpath: str30; group: integer; area: word;
                        sn: byte; flags: ulrecflagset; VAR frec: f_array);
const
  maxfileblock = 30000 div sizeof(ulfrec);  {* Allocate 30K *}
type
  fileblocktype = ARRAY[1..maxfileblock] OF ulfrec;
VAR
  udir: FILE;
  fileblock: ^fileblocktype;
  counter,counter1: byte;
  fnum,realfileblockcount,recnum: word;
BEGIN
  assign(udir,dirpath+dirname+'.DIR');
  setfilemode(readdenynone);
  {$I-} reset(udir,sizeof(ulfrec)); {$I+}
  IF (ioresult = 0) THEN
  BEGIN
    setfilemode(normalmode);
    IF (filesize(udir) > 1) THEN
    BEGIN
      recnum := 0;
      new(fileblock);
      seek(udir,1);
      REPEAT
        blockread(udir,fileblock^,maxfileblock,realfileblockcount);
        FOR fnum := 1 TO realfileblockcount DO
        BEGIN
          inc(recnum);
          FOR counter := 1 TO 20 DO
            IF (fileblock^[fnum].nacc > frec[counter].nacc) THEN
            BEGIN
              IF (counter <= (20 - 1)) THEN
                FOR counter1 := (20 - 1) downto counter DO
                  frec[counter1 + 1] := frec[counter1];
              frec[counter].recnum := recnum;
              frec[counter].filename := fileblock^[fnum].filename;
              frec[counter].description := fileblock^[fnum].description;
              frec[counter].nacc := fileblock^[fnum].nacc;
              frec[counter].unused := fileblock^[fnum].unused;
              frec[counter].blocks := fileblock^[fnum].blocks;
              frec[counter].owner := fileblock^[fnum].owner;
              frec[counter].date := fileblock^[fnum].date;
              frec[counter].daten := fileblock^[fnum].daten;
              frec[counter].flag := fileblock^[fnum].flag;
              frec[counter].points := fileblock^[fnum].points;
              frec[counter].dirpath := dirpath;
              frec[counter].dirname := dirname;
              frec[counter].dlpathname := dlpath;
              frec[counter].flags := flags;
              frec[counter].areaname := name;
              frec[counter].seenames := sn;
              frec[counter].group := group;
              frec[counter].area := area;
              counter := 20;
           END;
        END;
      UNTIL (realfileblockcount < maxfileblock);
      dispose(fileblock);
    END;
    {$I-} close(udir); {$I+}
    IF (ioresult <> 0) THEN
    BEGIN
      writeln(^G^G^G'Unable to close '+dirname+'.DIR!');
      halt;
    END;
  END;
END;

PROCEDURE read_fboard_file(General: GeneralRecordType; VAR frec: f_array);
VAR
  ulf: FILE OF ulrec;
  uboards: ulrec;
  dirpathname: str160;
  counter: byte;
  grp: ARRAY[0..127] OF integer;
  tempgrp: integer;
BEGIN
  IF General.multiuser THEN
  BEGIN
    IF fileexist(General.DataPath+'FBOARDS.DAT') THEN
      assign(ulf,General.DataPath+'FBOARDS.DAT')
    ELSE
      assign(ulf,General.multiuserpath+'FBOARDS.DAT');
  END
  ELSE
    assign(ulf,General.DataPath+'FBOARDS.DAT');
  setfilemode(readdenynone);
  {$I-} reset(ulf); {$I+}
  IF (ioresult <> 0) THEN
  BEGIN
    writeln(^G^G^G'Unable to access FBOARDS.DAT!');
    halt;
  END;
  setfilemode(normalmode);
  FOR counter := 0 TO 127 DO
    grp[counter] := -1;
  tempgrp := -1;
  init_f_array(frec);
  WHILE not eof(ulf) DO
  BEGIN
    {$I-} read(ulf,uboards); {$I+}
    IF (ioresult <> 0) THEN
    BEGIN
      writeln(^G^G^G'Unable to read FBOARDS.DAT!');
      {$I-} close(ulf); {$I+}
      IF (ioresult <> 0) THEN
        writeln(^G^G^G'Unable to close FBOARDS.DAT!');
      halt;
    END;
    IF General.dynamicfile THEN
    BEGIN
      inc(grp[uboards.noratiogroupnum shr 1]);
      tempgrp := grp[uboards.noratiogroupnum shr 1];
    END
    ELSE
      inc(tempgrp);
    dirpathname := uboards.dlpathname;
    IF (uboards.dsl <= thisuser.dsl) and (uboards.arlvl in thisuser.ar) OR
      (uboards.dsl <= thisuser.dsl) and (uboards.arlvl = '@') THEN
    BEGIN
      IF (uboards.filename[1] = '@') THEN
      BEGIN
        dirpathname := General.DataPath;
        uboards.filename := copy(uboards.filename,2,length(uboards.filename));
      END
      ELSE IF (uboards.filename[1] = '`') THEN
      BEGIN
        dirpathname := General.multiuserpath;
        uboards.filename := copy(uboards.filename,2,length(uboards.filename));
      END
      ELSE IF (uboards.filename[1] = '+') THEN
      BEGIN
        dirpathname := General.altpath;
        uboards.filename := copy(uboards.filename,2,length(uboards.filename));
      END;
      read_dir_file(dirpathname,uboards.filename,uboards.name,uboards.dlpathname,
                    uboards.noratiogroupnum shr 1,tempgrp,uboards.seenames,
                    uboards.flags,frec);
    END;
  END;
  {$I-} close(ulf); {$I+}
  IF (ioresult <> 0) THEN
  BEGIN
    writeln(^G^G^G'Unable to close FBOARDS.DAT!');
    halt;
  END;
END;

PROCEDURE menu_line(c,c1: char; s,s1: str160);
BEGIN
  IF (c <> ' ') THEN
  BEGIN
    IF (length(s) > 32) THEN
      s := copy(s,1,32);
    ds_write(#3'1['#3'3'+c+#3'1] : '+addspace(s,33,false));
  END
  ELSE
    ds_write(addspace(s,39,TRUE));
  IF (c1 <> ' ') THEN
  BEGIN
    IF (length(s1) > 32) THEN
      s1 := copy(s1,1,32);
    ds_write(#3'1['#3'3'+c1+#3'1] : '+addspace(s1,33,false));
  END;
  NL;
END;

PROCEDURE menu1_line(c: char; s: str160);
BEGIN
  IF (length(s) > 73) THEN
    s := copy(s,1,73);
  Print(#3'1['#3'3'+c+#3'1] : '+s);
END;

PROCEDURE sys_menu_line(s,s1: str160);
BEGIN
  ds_write(#3'1'+s+#3'0'+s1);
END;

PROCEDURE sys_menu_line1(s,s1: str160);
BEGIN
  Print(#3'1'+s+#3'0'+s1);
END;

PROCEDURE hdr(s: str160);
BEGIN
  CLS;
  Print(#3'5'+center('-=[ '+s+' ]=-',78,TRUE));
  NL;
END;

PROCEDURE ftr(s: str160);
BEGIN
  NL;
  menu1_line('Q','Return to '+s);
  NL;
  ds_write(#3'4['#3'1'+realtostr1(nsl / 60,0,0)+' Mins Left'#3'4] Enter Command > '#3'1');
END;

PROCEDURE display_t_array(decimal,width: byte; t_ar: t_array; title,
                          header: str160);
VAR
  counter,counter1: byte;
BEGIN
  hdr('Top 10 '+title);
  Print(#3'2##   User Name         '+center(header,55,TRUE));
  NL;
  FOR counter := 1 TO 10 DO
  BEGIN
    ds_write(#3'4'+addspace(inttostr(counter),2,TRUE));
    IF (config.use_real) and (t_ar[counter].name = allcaps(thisuser.rname)+' #'+inttostr(thisuser.usernum))
      OR (t_ar[counter].name = thisuser.uname+' #'+inttostr(thisuser.usernum)) THEN
        ds_write('   '#3'8'+t_ar[counter].name+' '#3'9')
    ELSE
      ds_write('   '#3'1'+t_ar[counter].name+' '#3'9');
    FOR counter1 := (length(t_ar[counter].name) + 1) TO 42 DO
      ds_write('.');
    IF (t_ar[counter].info > 0) THEN
      Print(#3'4'+addspace(realtostr1(t_ar[counter].info,0,decimal),width,TRUE))
    ELSE
      NL;
  END;
  ds_pause_cr;
END;

PROCEDURE display_t_freqcall(decimal,width: byte; t_ar: t_array; title,
                             header: str160);
VAR
  counter,counter1: byte;
BEGIN
  hdr('Top 10 '+title);
  Print(#3'2##   User Name         '+center(header,55,TRUE));
  NL;
  FOR counter := 1 TO 10 DO
  BEGIN
    ds_write(#3'4'+addspace(inttostr(counter),2,TRUE));
    IF config.use_real and (t_ar[counter].name = allcaps(thisuser.rname)+' #'+inttostr(thisuser.usernum))
      OR (t_ar[counter].name = thisuser.uname+' #'+inttostr(thisuser.usernum)) THEN
        ds_write('   '#3'8'+t_ar[counter].name+' '#3'9')
    ELSE
      ds_write('   '#3'1'+t_ar[counter].name+' '#3'9');
    FOR counter1 := (length(t_ar[counter].name) + 1) TO 42 DO
      ds_write('.');
    IF (t_ar[counter].info < 255) THEN
      Print(#3'4'+addspace(realtostr1(t_ar[counter].info,0,decimal),width,TRUE))
    ELSE
      NL;
  END;
  ds_pause_cr;
END;

PROCEDURE graph_yes(tf: boolean; VAR first: b_array; i,g_fg,g_bg: byte);
BEGIN
  IF (ANSI in thisuser.Flags) THEN
  BEGIN
    ds_textcolor(g_fg);
    ds_write('лл');
    IF first[i] THEN
    BEGIN
      ds_textcolor(g_bg);
      ds_write('п');
      first[i] := false;
    END
    ELSE
    BEGIN
      ds_textcolor(black);
      ds_write('л');
      IF not tf THEN
        ds_textcolor(g_bg);
    END;
  END
  ELSE
    ds_write('###');
END;

PROCEDURE graph_no;
BEGIN
  IF (ANSI in thisuser.Flags) THEN
    ds_write('ллл')
  ELSE
    ds_write('...');
END;

PROCEDURE display_g_sysactivity(config: configinfo; gdate: d_array; gsysact:
                                gsysactivity; s: str160);
VAR
  first: b_array;
  counter,counter1: byte;
  average: real;
  tf: boolean;
BEGIN
  FOR counter := 1 TO 20 DO
    first[counter] := TRUE;
  average := 0.0;
  CLS;
  Print(#3'5           '+center('-=[ Graph Of System Activity By Percentage ]=-',60,TRUE));
  FOR counter := 20 downto 1 DO
  BEGIN
    average := average + gsysact[counter];
    IF (copy(s,counter,1) <> ' ') THEN
      ds_write(#3'5'+copy(s,counter,1))
    ELSE
      ds_write(' ');
    ds_write(#3'2'+addspace(inttostr(counter * 5),7,TRUE)+'%  ');
    FOR counter1 := 20 downto 1 DO
      IF (gsysact[counter1] >= (counter * 5)) THEN
      BEGIN
        tf := TRUE;
        IF (counter1 > 1) THEN
        BEGIN
          tf := false;
          IF (gsysact[counter1 - 1] >= counter * 5) THEN
            tf := TRUE;
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
  FOR counter := 20 downto 1 DO
    IF (gdate[counter] <> '') and not tf THEN
    BEGIN
      ds_write(addspace(graph_month(gdate[counter])+' ',11,TRUE));
      tf := TRUE;
    END;
  IF not tf THEN
    ds_write('           ');
  FOR counter := 20 downto 1 DO
    IF (gdate[counter] <> '') THEN
      ds_write(copy(gdate[counter],4,2)+' ')
    ELSE
      ds_write('   ');
  IF (gdate[1] <> '') THEN
    Print(graph_month(gdate[1]))
  ELSE
    NL;
  average := average / config.logdays;
  Print(#3'5           '+center('(Average '+reverse_str(s)+': '+realtostr1(average,0,0)+'%)',60,TRUE));
  ds_pause_cr;
END;

PROCEDURE display_g_array(config: configinfo; gdate: d_array; g_ar: g_array;
                          title,side: str160; increment: longint);
VAR
  first: b_array;
  counter,counter1: byte;
  average: longint;
  tf: boolean;
BEGIN
  FOR counter := 1 TO 20 DO
    first[counter] := TRUE;
  average := 0;
  CLS;
  Print(#3'5           '+center('-=[ Graph Of '+title+' ]=-',60,TRUE));
  FOR counter := 20 downto 1 DO
  BEGIN
    Inc(average,g_ar[counter]);
    IF (copy(side,counter,1) <> ' ') THEN
      ds_write(#3'5'+copy(side,counter,1))
    ELSE
      ds_write(' ');
    ds_write(#3'2'+addspace(inttostr(counter * increment),7,TRUE)+'   ');
    FOR counter1 := 20 downto 1 DO
      IF (g_ar[counter1] >= (counter * increment)) THEN
      BEGIN
        tf := TRUE;
        IF (counter1 > 1) THEN
        BEGIN
          tf := false;
          IF (g_ar[counter1 - 1] >= (counter * increment)) THEN
            tf := TRUE;
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
  FOR counter := 20 downto 1 DO
    IF (gdate[counter] <> '') and not tf THEN
    BEGIN
      ds_write(addspace(graph_month(gdate[counter])+' ',11,TRUE));
      tf := TRUE;
    END;
  IF not tf THEN
    ds_write('           ');
  FOR counter := 20 downto 1 DO
    IF (gdate[counter] <> '') THEN
      ds_write(copy(gdate[counter],4,2)+' ')
    ELSE
      ds_write('   ');
  IF (gdate[1] <> '') THEN
    Print(graph_month(gdate[1]))
  ELSE
    NL;
  average := average div config.logdays;
  Print(#3'5           '+center('(Average '+reverse_str(side)+': '+inttostr(average)+')',60,TRUE));
  ds_pause_cr;
END;

function div_g(g: g_array): longint;
VAR
  i: byte;
  counter: longint;
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
      counter := 5;
      REPEAT
        Inc(counter);
      UNTIL (num > 999999) OR (counter > num);
      div_size := counter;
    END;
  END;

BEGIN
  big := 0;
  FOR i := 1 TO 20 DO
    big := max(big,g[i]);
  num := big / 20;
  div_g := div_size(num);
END;

PROCEDURE display_m_array(m_ar: m_array; title,desc1,desc2,desc3: str160; value: byte);
VAR
  len: byte;

  PROCEDURE m_line(s: str160; w: word);
  VAR
    counter: byte;
  BEGIN
    ds_write(#3'1'+s+' '#3'9');
    FOR counter := 1 TO (len - length(s)) DO
      ds_write('.');
    Print(#3'4'+addspace(inttostr(w),value+1,TRUE));
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
  IF (desc3 = 'Total Not Specified') and (m_ar[3] > 0) OR (desc3 = 'The Oldest User Is') THEN
    m_line(desc3,m_ar[3]);
  ds_pause_cr;
END;

PROCEDURE display_h_array(ubaud: h_array);

  PROCEDURE baud_line(s: str160; w: word);
  VAR
    counter: byte;
  BEGIN
    ds_write(#3'1Total '+s+' Baud Callers '#3'9');
    FOR counter := 1 TO (27 - length('Total '+s+' Baud Callers')) DO
      ds_write('.');
    Print(#3'4'+addspace(inttostr(w),6,TRUE));
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
  ds_pause_cr;
END;

PROCEDURE todayusage(General: GeneralRecordType);
BEGIN
  CLS;
  with General DO
  BEGIN
    Print(#3'5'+center('-=[ Todays Usage ]=-',78,TRUE));
    sys_menu_line('                      Date:',datestr);
    sys_menu_line1('         Time:',timestr);
    NL;
    sys_menu_line1('Board Name      :',boardname);
    sys_menu_line1('Node Number     :',inttostr(nodenumber));
    sys_menu_line1('Board Address   :',boardcitystate);
    sys_menu_line1('SysOp Name      :',sysopname);
    sys_menu_line1('Phone Number    :',boardphone);
    sys_menu_line('Mail Address    :',inttostr(address.zone)+':'+inttostr(address.net)+'/'+inttostr(address.node));
    IF (address.point > 0) THEN
      Print('.'+inttostr(address.point))
    ELSE
      NL;
    sys_menu_line1('BBS Software    :','T.A.G. Version '+lasttagversion);
    NL;
    sys_menu_line1('Total Calls     :',realtostr1(callernum,0,0));
    sys_menu_line1('Number Of Users :',realtostr1(users,0,0));
    sys_menu_line1('Last Caller     :',lastcaller);
    NL;
    Print(#3'5'+center('-=[ Summary Of Activity ]=-',78,TRUE));
    sys_menu_line('Minutes Active  :',addspace(inttostr(activetoday),9,false));
    sys_menu_line('Calls Today     :',addspace(inttostr(callstoday),9,false));
    sys_menu_line1('New Users Today :',addspace(inttostr(nuserstoday),9,false));
    sys_menu_line('Percent Active  :',addspace(return_percent(activetoday),9,false));
    sys_menu_line('Time/User       :',addspace(return_time(activetoday,callstoday),9,false));
    sys_menu_line1('Public Posts    :',addspace(inttostr(msgposttoday),9,false));
    sys_menu_line('Private Posts   :',addspace(inttostr(emailtoday),9,false));
    sys_menu_line('Feedback Sent   :',addspace(inttostr(fbacktoday),9,false));
    sys_menu_line1('Errors Today    :',addspace(inttostr(errorstoday),9,false));
    sys_menu_line('Number Uploads  :',addspace(inttostr(ultoday),9,false));
    sys_menu_line('UL K-Bytes      :',addspace(realtostr1(ulktoday,0,0)+'K',9,false));
    sys_menu_line1('Number Downloads:',addspace(inttostr(dltoday),9,false));
    sys_menu_line1('DL K-Bytes      :',addspace(realtostr1(dlktoday,0,0)+'K',9,false));
  END;
  ds_pause_cr;
END;

PROCEDURE chlen(s: str78; i,i1: integer);
VAR
  line1,line2,temp: str160;
  counter: integer;
BEGIN
  s := rmvleadspace(rmvtrailspace(s));
  WHILE (pos('  ',s) > 0) DO
    Delete(s,pos('  ',s),1);
  IF (length(s) > i) THEN
  BEGIN
    line1 := copy(s,1,i);
    WHILE (line1[length(line1)] <> ' ') DO
    BEGIN
      Delete(line1,length(line1),1);
      Dec(i);
    END;
    line1 := rmvtrailspace(line1);
    line2 := copy(s,i + 1,length(s));
    line2 := rmvleadspace(line2);
    temp := '';
    FOR counter := 1 TO i1 DO
      temp := ' ' + temp;
    Print(#3'0'+line1);
    ds_write(temp);
    ds_write(#3'1:');
    Print(#3'0'+line2);
  END
  ELSE
    Print(#3'0'+s);
END;

PROCEDURE mainmenuscr(bbsname: str160);
BEGIN
  hdr('Renegade Statistics Main Menu');
  menu1_line('A','User Statistics');
  menu1_line('B','Usage Statistics');
  ftr(bbsname);
END;

PROCEDURE usermenuscr;
BEGIN
  hdr('Renegade Statistics User Menu');
  menu1_line('A','Top 10 User Menu');
  menu1_line('B','User Age');
  menu1_line('C','User Gender');
  menu1_line('D','User Baud Rate');
  ftr('Renegade Statistics Main Menu');
END;

PROCEDURE usagemenuscr;
BEGIN
  hdr('Renegade Statistics Usage Menu');
  menu1_line('A','Usage Graph Menu');
  menu1_line('B','Todays Usage');
  ftr('Renegade Statistics Main Menu');
END;

PROCEDURE top10menuscr;
BEGIN
  hdr('Renegade Statistics Top 10 User Menu');
  menu_line('A','B','Most Frequent Callers','High Time Users');
  menu_line('C','D','File Kbyte Uploaders','File Kbyte Downloaders');
  menu_line('E','F','Private Message Senders','Public Message Posters');
  menu_line('G','H','SysOp Feedback Senders','All Time Callers');
  menu_line('I','J','File Uploaders','File Downloaders');
  menu_line('K','L','File Points','Upload/Download Ratios');
  menu_line('M',' ','Post/Call Ratios','');
  ftr('Renegade Statistics User Menu');
END;

PROCEDURE graph20menuscr;
BEGIN
  hdr('Renegade Statistics Usage Graph Menu');
  menu_line('A','B','Minutes Active','Number Of Calls');
  menu_line('C','D','New User Logons','System Activity');
  menu_line('E','F','Average Time/User','Public Message Posting');
  menu_line('G','H','Private Message Posting','SysOp Feedback Sent');
  menu_line('I','J','Number Of Errors','File Uploads');
  menu_line('K','L','File Kbytes Uploaded','File Downloads');
  menu_line('M',' ','File Kbytes Downloaded','');
  ftr('Renegade Statistics Usage Menu');
END;

PROCEDURE mainmenu(General: GeneralRecordType; config: configinfo; tfreqc,tttimeon,
                   tulk,tdlk,tprivp,tpubp,tfeedback,tnumc,
                   tnumul,tnumdl,tfilep,tupd,tpostc: t_array; gdate: d_array;
                   gsysact: gsysactivity; gmina,gnumc,gnewu,gtimeu,gmsgpub,
                   gmsgpvt,gmsgfb,gnume,gful,gulkb,gfdl,gdlkb: g_array;
                   uage,usex: m_array; ubaud: h_array; frec: f_array);
VAR
  c: char;
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
                                                    'Number Of KB Uploaded For Each KB Downloaded');
                              'M' : display_t_array(3,12,tpostc,'Post/Call Ratios',
                                                    'Number Of Public Messages Posted Each Call');
                            END;
                          UNTIL (c = 'Q') OR HangUp;
                          c := #0;
                        END;
                  'B' : display_m_array(uage,'User Age Statistics','The Average User Age Is',
                                  'The Youngest User Is','The Oldest User Is',3);
                  'C' : display_m_array(usex,'User Gender Statistics','Total Male Users',
                                       'Total Female Users','Total Not Specified',5);
                  'D' : display_h_array(ubaud);
                END;
              UNTIL (c = 'Q') OR HangUp;
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
                              'C' : display_g_array(config,gdate,gnewu,'New User Logons to System',
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
                          UNTIL (c = 'Q') OR HangUp;
                          c := #0;
                        END;
                  'B' : todayusage(General);
                END;
              UNTIL (c = 'Q') OR HangUp;
              c := #0;
            END;
    END;
  UNTIL (c = 'Q') OR HangUp;
END;

BEGIN
  read_config_file(config,chatconfig);
  TempPause := FALSE;
  read_usage_file(General,config,gdate,gsysact,gmina,gnumc,gnewu,gtimeu,
                  gmsgpub,gmsgpvt,gmsgfb,gnume,gful,gulkb,gfdl,gdlkb);
  scrn_one;
  read_user_file(General,config,uage,usex,ubaud,tfreqc,tttimeon,tulk,tdlk,
                 tprivp,tpubp,tfeedback,tnumc,tnumul,tnumdl,tfilep,tupd,
                 tpostc);
  mainmenu(General,config,tfreqc,tttimeon,tulk,tdlk,tprivp,tpubp,
           tfeedback,tnumc,tnumul,tnumdl,tfilep,tupd,tpostc,gdate,gsysact,
           gmina,gnumc,gnewu,gtimeu,gmsgpub,gmsgpvt,gmsgfb,gnume,gful,gulkb,
           gfdl,gdlkb,uage,usex,ubaud,frec);
  scrn_two(General.boardname);
END.
