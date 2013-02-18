uses crt;

var verline:array [0..3] of string;
    s3:string;
    f:text;
    i:byte;
    loop:integer;

function encrypt(s:string):string;
var b:byte;
   s2:string;
    t:byte;
begin
  s2:='';
  s2[0] := s[0]; t := 0;
  for b:=1 to length(s) do
    begin
      s2[b] := chr(ord(s[b]) + ord(s2[b-1]));
      inc(t, ord(s2[b]));
    end;
  writeln('Total: ',t);
  encrypt:=s2;
end;

function decrypt(s:string):string;
var b:byte;
   s2:string;
begin
  s2:='';
  for b:=1 to length(s) do
    s2:=s2+chr(ord(s[b]) - ord(s[b-1]));
  decrypt:=s2;
end;

begin
  clrscr;
   {verline[0]:='|03The |11Renegade Bulletin Board System|03 Version ';}
   verline[1]:= ('|03Copyright (C) 2003-2005 |03.');
   verline[2]:= ('|03Copyright (C) 2003-2005 |03.');
   verline[3]:= ('|03Copyright (C) 2003-2005 |03.');
  {verline:='--- Renegade v';}
  assign(f,'ec.txt');
  s3:='';
  rewrite(f);
{   for loop := 0 to 3 do
     begin}
       writeln(verline[3]);
       writeln(f,verline[3]);
       s3:=encrypt(verline[3]);
       writeln(s3);
       writeln(f,s3);
{     end;}
  close(f);
end.

