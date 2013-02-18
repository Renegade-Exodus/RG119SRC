Program ChangeMultiNode;
Uses CRT, DOS, RgAPI;
Var
  RGIn            : GeneralRec;
  WhichErr        : Byte;
  MultNodeDatPath : String;
  Noder           : noderec;
  Node            : String;

procedure OpenReadCloseRenegadeDat;
 begin
  OpenRenegadeDat('d:\bbs\',WhichErr);
    If WhichErr <> 0 then HandleError('Can''t find Renegade.dat',True,1);
  ReadFromRenegadeDat(RGIn,WhichErr);
    If WhichErr <> 0 then HandleError('Can''t read from Renegade.dat',True,2);
  CloseRenegadeDat;
 end;

Procedure GetMultNodeDatPath;
 begin
   if paramstr(2) = '' then MultNodeDatPath := rgin.datapath
   else MultNodeDatPath := ParamStr(2);
 end;

procedure SetWhichNode;
 begin
   if paramstr(1) = '' then HandleError('Which node do you want me to apply this to..',True,3)
   else Node := paramstr(1);
 end;

procedure initnoder;
 begin
   FillChar(Noder,SizeOf(Noder),' ');
   OpenMultNodeDat(MultNodeDatPath,WhichErr);
    If WhichErr <> 0 then HandleError('Can''t find multnode.dat',True,4);
   ReadFromMultNodeDat(Noder,StrToInt(Node));
 end;

Procedure MainProgram;
 begin
    with noder do begin
       User      := 1;
       UserName  := 'The Titantic BBS';
       Status    := [];
       Status    := [NActive];
       CityState := 'Internet';
       LogonTime := TodayinUnix;
{                      12345678901234567890}
       Description := 'Waiting for Call';
       Activity := 255;
    end;
 end;

Procedure WriteToCloseNoder;
 begin
    WriteToMultNodeDat(Noder,StrToInt(Node));
    CloseMultNodeDat;
 end;

procedure DoProgram;
 begin
   OpenReadCloseRenegadeDat;
   GetMultNodeDatPath;
   SetWhichNode;
   InitNoder;
   MainProgram;
   WriteToCloseNoder;
 end;


Begin
  DoProgram;
End.
