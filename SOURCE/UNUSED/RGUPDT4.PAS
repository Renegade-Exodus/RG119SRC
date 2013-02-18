{$M 49152,0,65536}
PROGRAM RGUPDATE;

USES
  Crt,
  Dos,
  TimeFunc;

{$I records.pas}

TYPE
  oldnoderec=                         { MULTNODE.DAT }
  {$IFDEF WIN32} packed {$ENDIF} record
      User:word;                                 { What user number     }
      UserName:string[36];                       { User's name }
      CityState:string[30];                      { User's location }
      Sex:char;                                  { User's sex }
      Age:byte;                                  { User's age }
      LogonTime:unixtime;                        { What time they logged on }
      activity:byte;                             { What are they doing? }
      Description:string[50];                    { Optional string }
      Status:NodeFlagSet;
      Room:byte;                                 { What room are they in?      }
      Channel:word;                              { What channel are they in?   }
      Invited:array[0..31] of set of 0..7;       { Have they been invited ?    }
      Booted:array[0..31] of set of 0..7;        { Have they been kicked off ? }
      Forget:array[0..31] of set of 0..7;        { Who are they forgetting?    }
    end;

function IntToStr(i: longint): string;
var
  s: string;
begin
  s := '';
  str(I,S);
  IntToStr := s;
end;

function sqoutsp(s:string):string;
begin
  while (pos(' ',s)>0) do delete(s,pos(' ',s),1);
  sqoutsp:=s;
end;

function exist(fn: astr): boolean;
var
  srec: searchrec;
begin
  findfirst(sqoutsp(fn),anyfile,srec);
  exist := (doserror = 0);
end;

PROCEDURE CvtNodeFile(General: GeneralRecordType);
VAR
  OldNodeFile: FILE OF OldNodeRec;
  NodeFile: FILE OF NodeRecordType;
  OldNode: OldNodeRec;
  Node: NodeRecordType;
  Counter: Byte;
BEGIN
  FOR Counter := 1 To 255 Do
    IF Exist(General.DataPath+'NODE'+Inttostr(Counter)+'.DAT') THEN
    BEGIN
      Write('Converting "NODE'+inttostr(Counter)+'.DAT" file ... ');
      Assign(Oldnodefile,General.DataPath+'NODE'+inttostr(Counter)+'.DAT');
      Reset(Oldnodefile);
      Read(Oldnodefile,Oldnode);
      Assign(nodefile,General.DataPath+'NODE'+inttostr(Counter)+'.NEW');
      ReWrite(nodefile);
      WITH Node DO
      BEGIN
        User := Oldnode.User;
        UserName := Oldnode.UserName;
        CityState := Oldnode.CityState;
        Sex := Oldnode.Sex;
        Age := Oldnode.Age;
        LogonTime := Oldnode.LogonTime;

        (* Start - Delete *)
        {activity := Oldnode.Activity}
        (* End - Delete *)

        (* Start - Add *)
        IF (OldNode.Activity = 2) THEN
          GroupChat := TRUE
        ELSE
          GroupChat := FALSE;
        (* End - Add *)

        (* Start - Change *)
        ActivityDesc := Oldnode.Description;
        (* End - Change *)

        Status := Oldnode.Status;
        Room := Oldnode.Room;
        Channel := Oldnode.Channel;
        FillChar(Node.Invited,SizeOf(Node.Invited),0);
        FillChar(Node.Booted,SizeOf(Node.Booted),0);
        FillChar(Node.Forget,SizeOf(Node.Forget),0);
      END;
      Write(NodeFile,Node);
      Close(OldNodeFile);
      Close(NodeFile);
      Assign(OldNodeFile,General.DataPath+'NODE'+inttostr(Counter)+'.DAT');
      Erase(OldNodeFile);
      Assign(NodeFile,General.DataPath+'NODE'+inttostr(Counter)+'.NEW');
      ReName(Nodefile,General.DataPath+'NODE'+inttostr(Counter)+'.DAT');
      WriteLn('Done');
    END;
END;

VAR
  GR: FILE OF GeneralRecordType;
  General: GeneralRecordType;

BEGIN
  Write('Reading "RENEGADE.DAT" file ... ');
  Assign(GR,'RENEGADE.DAT');
  Reset(GR);
  Read(GR,General);
  Close(GR);
  WriteLn('Done');

  CvtNodeFile(General);

END.