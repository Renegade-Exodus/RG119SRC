{$A+,B-,D-,E-,F+,I-,L-,N-,O+,R-,S+,V-}

{ User related functions }

unit User;

interface

uses
   common;

procedure changeconf(var v:str8);
procedure finduserws(var x:integer);
procedure changearflags(const cms:astr);
procedure changeacflags(const cms:astr);
procedure finduser(var usernum:integer);
procedure InsertIndex(uname:astr;usernum:integer;IsReal,IsDeleted:boolean);

implementation

uses
  dos;

procedure changeconf(var v:str8);
var
  c:char;
  done:boolean;

  procedure listconfs;
  var i,onlin:byte;
      s:string[100];

  begin
     printf('conflist');
     if not nofile then exit;
     cls;
     abort:=FALSE; next:=FALSE;
     s:='^0N'+seperator+'Title';
     if (thisuser.linelen>=80) then s:=mln(s,38)+seperator+s;
     print(s);
     s:='^4=:====================================';
     if (thisuser.linelen>=80) then s:=s+':'+s;
     print(s);
     i:=1;
     onlin:=0;
     while (i<=27) and (not abort) and (not hangup) do begin
         c:=chr(i+63);
         if (aacs(confr.conference[c].acs)) and (confr.conference[c].name<>'') then begin
            s:='^0'+c+' ^3'+confr.conference[c].name;
            inc(onlin);
            s:=mln(s,39);
            if (onlin=1) then prompt(s)
               else begin
                 if (thisuser.linelen<80) then nl;
                 print(s);
                 onlin:=0;
               end;
         end;
         wkey;
         inc(i);
     end;
     if (onlin=1) and (thisuser.linelen>=80) then nl;
  end;

begin
  nl;
  done:=false;
  if v<>'' then c:=v[1] else c:=#0;
  if (c>='@') and (c<='Z') and aacs(confr.conference[c].acs) then begin
        currentconf:=c;
        thisuser.lastconf:=c;
        printf('conf'+c);
  end else if c='?' then listconfs
      else begin
  print(^M^J'^4Current conference: ^5%CT - %CN');
  repeat
    prompt(^M^J'^4Join which conference (^3?^4=^3List^4): ');
    c:=upcase(char(getkey));
    print(c + ^M^J);
    if (c>='@') and (c<='Z') then begin
       if (aacs(confr.conference[c].acs)) and (confr.conference[c].name<>'') then begin
          printf('conf'+c);
          if nofile then print('Conference joined.');
          currentconf:=c;
          thisuser.lastconf:=c;
          done:=true;
          nl
       end else print('No such conference.');
    end else if c='?' then listconfs;
  until (c=#13) or (done) or (hangup);
  end;
  newcomptables;
end;

procedure finduserws(var x:integer);
var user:UserRecordType;
    IndexR:useridxrec;
    nn:astr;
    gg,j:integer;
    c:char;
    done,asked:boolean;
begin
  linput(nn,36);
  if (nn='SYSOP') then nn:='1';
  x:=value(nn);
  if (x>0) then begin
    if (x > (maxusers - 1)) then
    begin
      print(^M^J'Unknown User.');
      x:=0;
    end else loadurec(user,x);
  end else
    if (nn<>'') then begin
      done:=FALSE; asked:=FALSE;
      x := searchuser(nn, CoSysOp);
      if (x > 0) then
        exit;
      reset(sf);
      gg:=0; j:=filesize(sf);
      while (gg<j) and (not done) do begin
        read(sf, IndexR);
        inc(gg);
        if not (IndexR.Deleted) and (pos(nn, IndexR.name) <> 0) and
           ((not IndexR.RealName) or (CoSysOp)) then
          if ((IndexR.Name = nn) or (CoSysOp and (IndexR.Name = nn))) and
            (Indexr.number <= (maxusers - 1)) then
              x := Indexr.Number
          else begin
            if (not asked) then begin nl; asked:=TRUE; end;
            prompt('^1Did you mean ^3' + caps(IndexR.Name) + '^1? ');
            onek(c,'QYN'^M);
            done:=TRUE;
            case c of
              'Q':x:=-1;
              'Y':x:= IndexR.Number;
            else
                  done:=FALSE;
            end;
          end;
      end;
      close(sf);
      if (x=0) then print(^M^J'User not found.');
      if x=-1 then x:=0;
    end;
  Lasterror := IOResult;
end;

procedure changearflags(const cms:astr);
var
  c,cc:char;
  i:byte;

begin
  for i:=1 to (length(cms)-1) do
    begin
      c := upcase(cms[i]);
      cc := upcase(cms[i+1]);
      case c of
         '+':Include(thisuser.ar,cc);
         '-':Exclude(thisuser.ar,cc);
         '!':if (upcase(cms[i + 1]) in thisuser.ar) then
               Exclude(thisuser.ar,cc)
             else
               Include(thisuser.ar,cc);
      end;
    end;

  newcomptables;
  update_screen;
end;

procedure changeacflags(const cms:astr);
var
  c,cc:char;
  i:byte;
begin
  for i:=1 to length(cms)-1 do
    begin
      c:=upcase(cms[i]);
      cc := upcase(cms[i+1]);
      case c of
         '+':Include(thisuser.flags,tacch(cc));
         '-':Exclude(thisuser.flags,tacch(cc));
         '!':acch(upcase(cms[i+1]),thisuser);
      end;
    end;
  newcomptables;
  update_screen;
end;

procedure finduser(var usernum:integer);
var user:UserRecordType;
    nn:astr;
    ii:integer;
begin
  usernum:=0;
  linput(nn,36);

  if (nn='NEW') then
    begin
      usernum := -1;
      exit;
    end;

  if (nn='?') then exit;

  while (pos('  ',nn)<>0) do
    delete(nn,pos('  ',nn),1);

  while (nn[1] = ' ') and (length(nn) > 0) do
    delete(nn,1,1);

  if ((hangup) or (nn='')) then exit;
  usernum:=value(nn);
  if (usernum<>0) then begin
    if (usernum<0) then
      usernum:=0
    else begin
      if (usernum > (maxusers - 1)) then
        usernum := 0
      else
        begin
          loadurec(user,usernum);
          if (deleted in user.sflags) then
            usernum:=0;
        end;
    end;
  end else begin
    if (nn <> '') then begin
      ii := searchuser(nn, TRUE);
      if (ii <> 0) then
        begin
          loadurec(user,ii);
          if not (deleted in user.sflags) then
            usernum:=ii
          else
            usernum:=0;
        end;
    end;
  end;
end;

procedure InsertIndex(Uname:astr; usernum:integer; IsReal, IsDeleted:boolean);
var
  IndexR:useridxrec;
  Current:integer;
  InsertAt:integer;
  SFO,Done:boolean;

  procedure WriteIndex;
  begin
    with IndexR do
      begin
        fillchar(IndexR, sizeof(IndexR), 0);
        Name    := Uname;
        Number  := UserNum;
        RealName:= IsReal;
        Deleted := IsDeleted;
        Left    := -1;
        Right   := -1;
        write(sf, IndexR);
      end
  end;

begin
  Done := FALSE;
  Uname := Allcaps(Uname);
  Current := 0;

  SFO := (filerec(sf).mode<>fmclosed);

  if (not SFO) then
    reset(sf);

  if (filesize(sf) = 0) then
    WriteIndex
  else
    repeat
      seek(sf, Current);
      InsertAt := Current;
      read(sf, IndexR);
      if (Uname < IndexR.Name) then
        Current := IndexR.Left
      else
        if (Uname > IndexR.Name) then
          Current := IndexR.Right
        else
          if (IndexR.Deleted <> IsDeleted) then
            begin
              Done := TRUE;
              IndexR.Deleted := IsDeleted;
              IndexR.RealName := IsReal;
              IndexR.Number := Usernum;
              seek(sf, Current);
              write(sf,IndexR);
            end
          else
            begin
              if (Usernum <> IndexR.Number) then
                sysoplog('Note: Duplicate user ' + UName + ' #' + cstr(IndexR.Number) +
                         ' and ' + UName + ' #' + cstr(Usernum))
              else
                begin
                  IndexR.RealName := FALSE;
                  seek(sf, Current);         { Make it be his handle if it's BOTH }
                  write(sf, IndexR);
                end;
              Done := TRUE;
            end;
    until (Current = -1) or (Done);

    if (Current = -1) then
      begin
        if (Uname < IndexR.Name) then
          IndexR.Left := filesize(sf)
        else
          IndexR.Right := filesize(sf);
        seek(sf, InsertAt);
        write(sf, IndexR);
        seek(sf, filesize(sf));
        WriteIndex;
      end;
  if (not SFO) then
    close(sf);
  Lasterror := IOResult;
end;

end.
