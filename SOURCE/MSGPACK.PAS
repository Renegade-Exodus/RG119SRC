{$IFDEF WIN32}
{$I DEFINES.INC}
{$ENDIF}

{$A+,B-,D-,E-,F+,I-,L-,N-,O+,R-,S+,V-}

UNIT MsgPack;

INTERFACE

USES
  Common;

PROCEDURE DoShowPackMessageAreas;
PROCEDURE PackMessageAreas;

IMPLEMENTATION

USES
  Mail0;

PROCEDURE PackMessageArea(FN: Astr; MaxM: LongInt);

VAR
  Buffer: ARRAY [1..4096] OF Char;
  MsgHdrF1,
  MsgHdrF2: FILE OF MheaderRec;
  BrdF1,
  BrdF2: FILE;
  MHeader: MheaderRec;
  Numm,
  i,
  IDX,
  TotLoad,
  Buffered: Word;
  NeedPack: Boolean;

  PROCEDURE OhShit;
  BEGIN
    SysOpLog('Error renaming temp files while packing.');
  END;

BEGIN
  NeedPack := FALSE;
  FN := AllCaps(FN);
  FN := General.MsgPath + FN;

  Assign(BrdF1,FN+'.DAT');
  Reset(BrdF1,1);
  IF (IOResult <> 0) THEN
    Exit;

  Assign(MsgHdrF1,FN+'.HDR');
  Reset(MsgHdrF1);

  IF (IOResult <> 0) THEN
  BEGIN
    Close(BrdF1);
    Exit
  END;

  IF (MaxM <> 0) AND (FileSize(MsgHdrF1) > MaxM) THEN
  BEGIN
    Numm := 0;
    IDX := FileSize(MsgHdrF1);
    WHILE (IDX > 0) DO
    BEGIN
      Seek(MsgHdrF1,(IDX - 1));
      Read(MsgHdrF1,MHeader);
      IF NOT (MDeleted IN MHeader.Status) THEN
        Inc(Numm);
      IF (Numm > MaxM) AND NOT (Permanent IN MHeader.Status) THEN
      BEGIN
        MHeader.Status := [MDeleted];
        Seek(MsgHdrF1,(IDX - 1));
        Write(MsgHdrF1,MHeader);
      END;
      Dec(IDX);
    END;
  END
  ELSE
  BEGIN

    WHILE (FilePos(MsgHdrF1) < FileSize(MsgHdrF1)) AND (NOT NeedPack) DO
    BEGIN
      Read(MsgHdrF1,MHeader);
      IF (MDeleted IN MHeader.Status) THEN
        NeedPack := TRUE;
    END;

    IF (NOT NeedPack) THEN
    BEGIN
      Close(MsgHdrF1);
      Close(BrdF1);
      Exit;
    END;
  END;

  LastError := IOResult;

  Assign(BrdF2,FN+'.DA1');
  ReWrite(BrdF2,1);

  Assign(MsgHdrF2,FN+'.HD2');
  ReWrite(MsgHdrF2);

  Kill(FN+'.HD3');
  Kill(FN+'.DA3');

  LastError := IOResult;

  IDX := 1;
  i := 0;

  WHILE (i <= FileSize(MsgHdrF1) - 1) DO
  BEGIN
    Seek(MsgHdrF1,i);
    Read(MsgHdrF1,MHeader);

    IF (MHeader.Pointer - 1 + MHeader.TextSize > FileSize(BrdF1)) OR
       (MHeader.Pointer < 1) THEN
      MHeader.Status := [MDeleted];

    IF NOT (MDeleted IN MHeader.Status) THEN
    BEGIN
      Inc(IDX);
      Seek(BrdF1,MHeader.Pointer - 1);
      MHeader.Pointer := (FileSize(BrdF2) + 1);
      Write(MsgHdrF2,MHeader);

      TotLoad := 0;
      IF (MHeader.TextSize > 0) THEN
        WHILE (MHeader.TextSize > 0) DO
        BEGIN
          Buffered := MHeader.TextSize;
          IF (Buffered > 4096) THEN
            Buffered := 4096;
          Dec(MHeader.TextSize,Buffered);
          BlockRead(BrdF1,Buffer[1],Buffered);
          BlockWrite(BrdF2,Buffer[1],Buffered);
          LastError := IOResult;
        END;
    END;
    Inc(i);
  END;

  LastError := IOResult;
  Close(BrdF1);
  Close(BrdF2);
  Close(MsgHdrF1);
  Close(MsgHdrF2);

  ReName(BrdF1,FN+'.DA3');                     { ReName .DAT to .DA3 }

  IF (IOResult <> 0) THEN                      { Didn't work, abort  }
  BEGIN
    OhShit;
    Exit;
  END;

  ReName(BrdF2,FN+'.DAT');                     { ReName .DA2 to .DAT }

  IF (IOResult <> 0) THEN                      { Didn't work, abort  }
  BEGIN
    OhShit;
    ReName(BrdF1,FN+'.DAT');                 { ReName .DA3 to .DAT }
    Exit;
  END;

  ReName(MsgHdrF1,FN+'.HD3');                  { ReName .HDR to .HD3 }

  IF (IOResult <> 0) THEN                      { Didn't work, abort  }
  BEGIN
    OhShit;
    Erase(BrdF2);                            { Erase .DA2          }
    ReName(BrdF1,FN+'.DAT');                 { ReName .DA3 to .DAT }
    Exit;
  END;

  ReName(MsgHdrF2,FN+'.HDR');                  { ReName .HD2 to .HDR }

  IF (IOResult <> 0) THEN                      { Didn't work, abort  }
  BEGIN
    OhShit;
    Erase(BrdF2);                            { Erase .DAT (new)    }
    Erase(MsgHdrF2);                         { Erase .HD2 (new)    }
    ReName(BrdF1,FN+'.DAT');                 { ReName .DA3 to .DAT }
    ReName(MsgHdrF1,FN+'.HDR');              { ReName .HD3 to .HDR }
    Exit;
  END;

  Erase(MsgHdrF1);
  Erase(BrdF1);
  LastError := IOResult;
END;

PROCEDURE DoShowPackMessageAreas;
VAR
  TempBoard: MessageAreaRecordType;
  MArea: Integer;
BEGIN
  TempPause := FALSE;
  SysOpLog('Packed all message areas');
  NL;
  Star('Packing all message areas');
  NL;
  Print('^1Packing ^5Private Mail');
  PackMessageArea('EMAIL',0);
  Reset(MsgAreaFile);
  IF (IOResult <> 0) THEN
    Exit;
  Abort := FALSE;
  FOR MArea := 0 TO (FileSize(MsgAreaFile) - 1) DO
  BEGIN
    Seek(MsgAreaFile,MArea);
    Read(MsgAreaFile,TempBoard);
    Print('^1Packing ^5'+TempBoard.Name+'^5 #'+IntToStr(MArea + 1));
    PackMessageArea(TempBoard.FIleName,TempBoard.MaxMsgs);
    WKey;
    IF (Abort) THEN
      Break;
  END;
  Close(MsgAreaFile);
  lil := 0;
END;

PROCEDURE PackMessageAreas;
BEGIN
  NL;
  IF PYNQ('Pack all message areas? ',0,FALSE) THEN
    DoShowPackMessageAreas
  ELSE
  BEGIN
    InitMsgArea(MsgArea);
    SysOpLog('Packed message area ^5'+MemMsgArea.Name);
    NL;
    Print('^1Packing ^5'+MemMsgArea.Name+'^5 #'+IntToStr(CompMsgArea(MsgArea,0)));
    PackMessageArea(MemMsgArea.FIleName,MemMsgArea.MaxMsgs);
  END;
END;

END.
