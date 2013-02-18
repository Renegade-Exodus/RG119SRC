{$IFDEF WIN32}
{$I DEFINES.INC}
{$ENDIF}

{$A+,B-,D+,E-,F+,I-,L+,N-,O+,R-,S-,V-}

UNIT OffLine;

INTERFACE

PROCEDURE SetMessageAreaNewScanDate;
PROCEDURE DownloadPacket;
PROCEDURE uploadpacket(Already: Boolean);

IMPLEMENTATION

USES
  Crt,
  Dos,
  Common,
  Archive1,
  ExecBat,
  File0,
  File1,
  File2,
  File8,
  File11,
  Mail0,
  Mail1,
  Mail2,
  Mail4,
  NodeList,
  TimeFunc;

TYPE
  BSingle = ARRAY [0..3] OF Byte;

  NDXRec = RECORD
    Pointer: BSingle;
    Conf: Byte;
  END;

  QWKHeadeRec = RECORD
    Flag: Char;
    Num: ARRAY [1..7] OF Char;
    MsgDate: ARRAY [1..8] OF Char;
    MsgTime: ARRAY [1..5] OF Char;
    MsgTo: ARRAY [1..25] OF Char;
    MsgFrom: ARRAY [1..25] OF Char;
    MsgSubj: ARRAY [1..25] OF Char;
    MsgPWord: STRING[11];
    RNum: STRING[7];
    NumBlocks: ARRAY [1..6] OF Char;
    Status: Byte;
    MBase: SmallWord;
    Crap: STRING[3];
  END;

(*
PROCEDURE SetFileAreaNewScanDate;
VAR
  TempDate: Str10;
  Key: CHAR;
BEGIN
  {
  NL;
  Prt(FString.FileNewScan);
  }
  lRGLngStr(54,FALSE);
  MPL(10);
  Prompt(PD2Date(NewDate));
  Key := Char(GetKey);
  IF (Key = #13) THEN
  BEGIN
    NL;
    TempDate := PD2Date(NewDate);
  END
  ELSE
  BEGIN
    Buf := Key;
    DOBackSpace(1,10);
    InputFormatted('',TempDate,'##/##/####',TRUE);
    IF (TempDate = '') THEN
      TempDate := PD2Date(NewDate);
  END;
  IF (DayNum(TempDate) = 0) OR (DayNum(TempDate) > DayNum(DateStr)) THEN
  BEGIN
    NL;
    Print('Invalid date entered.');
  END
  ELSE
  BEGIN
    NL;
    Print('New file scan date set to: ^5'+TempDate+'^1');
    NewDate := Date2PD(TempDate);
    SL1('Reset file new scan date to: ^5'+TempDate+'.');
  END;
END;
*)

PROCEDURE SetMessageAreaNewScanDate;
VAR
  S: AStr;
  DT: DateTime;
  MArea,
  SaveMsgArea: Integer;
  l: LongInt;
BEGIN
  NL;
  Prt('Enter oldest date for new messages (mm/dd/yyyy): ');

  InputFormatted('',S,'##/##/####',TRUE);
  IF (DayNum(S) = 0) THEN
  BEGIN
    NL;
    Print('^7Invalid date entered!^1')
  END
  ELSE IF (S <> '') THEN
  BEGIN
    NL;
    Print('Current newscan date is now: ^5'+S);
    SaveMsgArea := MsgArea;
    FillChar(DT,SizeOf(DT),0);
    WITH DT DO
    BEGIN
      Month := StrToInt(Copy(S,1,2));
      Day := StrToInt(Copy(S,4,2));
      Year := StrToInt(Copy(S,7,4));
    END;
    l := DateToPack(DT);
    FOR MArea := 1 TO NumMsgAreas DO
    BEGIN
      InitMsgArea(MArea);
      LastReadRecord.LastRead := L;
      SaveLastReadRecord(LastReadRecord);
    END;
    MsgArea := SaveMsgArea;
    LoadMsgArea(MsgArea);
    SL1('Reset message last read pointers.');
  END;
END;

PROCEDURE DownloadPacket;
VAR
  IndexR:
  NDXRec;
  NDXFile,
  PNDXFile: FILE OF NDXRec;
  MsgFile: FILE;
  ControlTxt: Text;
  MHeader: MHeaderRec;
  QWKHeader: QWKHeadeRec;
  DT: DateTime;
  TransferFlags: TransferFlagSet;
  S,
  Texts: STRING;

  C: Char;

  FArrayRecNum: Byte;

  MArea,
  UseMsgArea,
  AvailableMsgAreas,
  SaveMsgArea,
  SaveFileArea: Integer;


  TotalNewMsgsInArea,
  TotalYourMsgsInArea,
  MsgNum,
  TempTextSize: Word;

  X,
  LastK,
  Marker,
  TotalMsgsAllAreas,
  TotalNewMsgsAllAreas,
  TotalYourMsgsAllAreas,
  LastUpdate: LongInt;

  SaveConfSystem,
  Ok: Boolean;

  PROCEDURE Real_To_Msb(PReal: Real; VAR B: BSingle);
  VAR
    R: ARRAY [0 .. 5] OF Byte ABSOLUTE PReal;
  BEGIN
    B[3] := R[0];
    Move(R[3],B[0],3);
  END;

  PROCEDURE KillEmail;
  VAR
    MsgNum1: Word;
  BEGIN
    InitMsgArea(-1);
    Reset(MsgHdrF);
    IF (IOResult = 0) THEN
    BEGIN
      FOR MsgNum1 := 1 TO FileSize(MsgHdrF) DO
      BEGIN
        Seek(MsgHdrF,(MsgNum1 - 1));
        Read(MsgHdrF,MHeader);
        IF ToYou(MHeader) THEN
        BEGIN
          Include(MHeader.Status,MDeleted);
          Seek(MsgHdrF,(MsgNum1 - 1));
          Write(MsgHdrF,MHeader);
        END
      END;
      Close(MsgHdrF);
    END;
    ThisUser.Waiting := 0;
  END;

  PROCEDURE Upload_Display;
  BEGIN
    LastUpdate := Timer;
    IF (NOT Abort) THEN
      Prompt(' ‚'+PadRightInt(TotalNewMsgsInArea,7)+
             'ƒ'+PadRightInt(TotalYourMsgsInArea,6)+
             '„'+PadRightStr(IntToStr((FileSize(MsgFile) - LastK) DIV 1024)+'k',8));
  END;

  PROCEDURE UpdatePointers;
  VAR
    MArea1: Integer;
    MsgNum1: Word;
  BEGIN
    TotalNewMsgsAllAreas := 0;
    FOR MArea1 := 1 TO NumMsgAreas DO
      IF (CompMsgArea(MArea1,0) <> 0) THEN
      BEGIN
        InitMsgArea(MArea1);
        IF AACS(MemMsgArea.ACS) AND ((LastReadRecord.NewScan) OR (MAForceRead IN MemMsgArea.MAFlags)) THEN
        BEGIN
          LastError := IOResult;
          Reset(MsgHdrF);
          IF (IOResult = 2) THEN
            ReWrite(MsgHdrF);
          MsgNum1 := FirstNew;
          IF (MsgNum1 > 0) THEN
            TotalNewMsgsInArea := FileSize(MsgHdrF) - MsgNum1 + 1
          ELSE
            TotalNewMsgsInArea := 0;
          MsgNum1 := FileSize(MsgHdrF);
          IF (TotalNewMsgsAllAreas + TotalNewMsgsInArea > General.MaxQWKTotal) THEN
            MsgNum1 := (FileSize(MsgHdrF) - TotalNewMsgsInArea) + (General.MaxQWKtotal - TotalNewMsgsAllAreas);
          IF (TotalNewMsgsInArea > general.maxqwkbase) AND
             (((FileSize(MsgHdrF) - TotalNewMsgsInArea) + General.MaxQWKBase) < MsgNum1) THEN
            MsgNum1 := (FileSize(MsgHdrF) - TotalNewMsgsInArea) + General.MaxQWKBase;
          Seek(MsgHdrF,MsgNum1- 1);
          Read(MsgHdrF,MHeader);
          LoadLastReadRecord(LastReadRecord);
          LastReadRecord.LastRead := MHeader.Date;
          SaveLastReadRecord(LastReadRecord);
          Inc(TotalNewMsgsAllAreas, MsgNum1 - (FileSize(MsgHdrF) - TotalNewMsgsInArea));
          Close(MsgHdrF);
        END;
      END;
  END;

BEGIN
  NL;
  IF (ThisUser.DefArcType < 1) OR (ThisUser.DefArcType > MaxArcs) OR
    (NOT General.FileArcInfo[ThisUser.DefArcType].Active) THEN
  BEGIN
    Print('Please select an archive type first.');
    Exit;
  END;

  IF (MakeQWKFor > 0) OR (Exist(TempDir+'QWK\'+General.PacketName+'QWK') AND
      PYNQ('Create a new QWK packet for download? ',0,FALSE)) THEN
    PurgeDir(TempDir+'QWK\',FALSE)
  ELSE
    PurgeDir(TempDir+'QWK\',FALSE);

  SaveMsgArea := MsgArea;

  SaveConfSystem := ConfSystem;
  ConfSystem := FALSE;
  IF (SaveConfSystem) THEN
    NewCompTables;

  OffLineMail := TRUE;

  IF (NOT Exist(TempDir+'QWK\'+General.PacketName+'QWK')) THEN
  BEGIN
    Assign(ControlTxt,TempDir+'QWK\CONTROL.DAT');
    ReWrite(ControlTxt);
    WriteLn(ControlTxt,StripColor(General.BBSName));
    WriteLn(ControlTxt);
    WriteLn(ControlTxt,General.BBSPhone);
    WriteLn(ControlTxt,General.SysOpName,', Sysop');
    WriteLn(ControlTxt,'0,'+General.PacketName);
    WriteLn(ControlTxt,Copy(DateStr,1,2)+'-'+Copy(DateStr,4,2)+'-'+Copy(DateStr,7,4)+','+TimeStr);
    WriteLn(ControlTxt,ThisUser.Name);
    WriteLn(ControlTxt);
    WriteLn(ControlTxt,'0');
    WriteLn(ControlTxt,'0');

    AvailableMsgAreas := 1;

    FOR MArea := 1 TO NumMsgAreas DO
      IF MsgAreaAC(MArea) THEN
        Inc(AvailableMsgAreas);

    WriteLn(ControlTxt,(AvailableMsgAreas - 1));

    FOR MArea := -1 TO NumMsgAreas DO
      IF (MArea > 0) AND MsgAreaAC(MArea) THEN
      BEGIN
        WriteLn(ControlTxt,MemMsgArea.QWKIndex);
        WriteLn(ControlTxt,Caps(StripColor(MemMsgArea.FileName)));
      END
      ELSE IF (MArea = -1) THEN
      BEGIN
        WriteLn(ControlTxt,0);
        WriteLn(ControlTxt,'Private Mail');
      END;

    WriteLn(ControlTxt,'WELCOME');
    WriteLn(ControlTxt,'NEWS');
    WriteLn(ControlTxt,'GOODBYE');
    Close(ControlTxt);

    IF (ThisUser.ScanFilesQWK) THEN
    BEGIN
      Assign(NewFilesF,TempDir+'QWK\NEWFILES.DAT');
      ReWrite(NewFilesF);
      InitFArray(FArray);
      FArrayRecNum := 0;
      GlobalNewFileScan(FArrayRecNum);
      Close(NewFilesF);
      LastError := IOResult;
    END;

    IF (General.QWKWelcome <> '') THEN
    BEGIN
      S := General.QWKWelcome;
      IF (OkANSI) AND Exist(S+'.ANS') THEN
        S := S +'.ANS'
      ELSE
        S := S +'.ASC';
      CopyMoveFile(TRUE,'',S,TempDir+'QWK\WELCOME',FALSE);
    END;

    IF (General.QWKNews <> '') THEN
    BEGIN
      S := General.QWKNews;
      IF (OkANSI) AND Exist(S+'.ANS') THEN
        S := S +'.ANS'
      ELSE
        S := S +'.ASC';
      CopyMoveFile(TRUE,'',S,TempDir+'QWK\NEWS',FALSE);
    END;

    IF (General.QWKGoodBye <> '') THEN
    BEGIN
      S := General.QWKGoodBye;
      IF (OkANSI) AND Exist(S+'.ANS') THEN
        S := S +'.ANS'
      ELSE
        S := S +'.ASC';
      CopyMoveFile(TRUE,'',S,TempDir+'QWK\GOODBYE',FALSE);
    END;

    Assign(MsgFile,TempDir+'QWK\MESSAGES.DAT');

    S := 'The Renegade Developement Team, Copyright (c) 1992-2009 (All rights reserved)';
    WHILE (Length(S) < 128) DO
      S := S + ' ';
    ReWrite(MsgFile,1);
    BlockWrite(MsgFile,S[1],128);

    FillChar(QWKHeader.Crap,SizeOf(QWKHeader.Crap),0);

    Assign(PNDXFile,TempDir+'QWK\PERSONAL.NDX');
    ReWrite(PNDXFile);

    LastK := 0;
    (*
    TotalNewMsgsInArea := 0;
    *)
    TotalMsgsAllAreas := 0;
    TotalNewMsgsAllAreas := 0;
    TotalYourMsgsAllAreas := 0;

    TempPause := FALSE;
    Abort := FALSE;
    Next := FALSE;

    CLS;
    Print(Centre('|The QWKÿSystem is now gathering mail.'));
    NL;
    PrintACR('sÚÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄ¿');
    PrintACR('s³t Num s³u Message area name     s³v  Short  s³w Echo s³x  Total  '+
             's³y New s³z Your s³{ Size s³');
    PrintACR('sÀÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÙ');

    FillChar(QWKHeader.MsgPWord,SizeOf(QWKHeader.MsgPWord),' ');

    FillChar(QWKHeader.RNum,SizeOf(QWKHeader.RNum),' ');

    QWKHeader.Status := 225;

    FOR MArea := -1 TO NumMsgAreas DO
    BEGIN
      IF (IOResult <> 0) THEN
      BEGIN
        WriteLn('error processing QWK packet.');
        Exit;
      END;

      IF (MArea = 0) OR ((MArea = -1) AND (NOT ThisUser.PrivateQWK)) OR
         ((CompMsgArea(MArea,0) = 0) AND (MArea >= 0)) THEN
        Continue;

      InitMsgArea(MArea);

      IF (MArea > 0) THEN
        UseMsgArea := MemMsgArea.QWKIndex
      ELSE
        UseMsgArea := 0;

      IF AACS(MemMsgArea.ACS) AND ((LastReadRecord.NewScan) OR
        (MAForceRead IN MemMsgArea.MAFlags)) AND (NOT Abort) AND (NOT HangUp) THEN
      BEGIN
        LastError := IOResult;
        Reset(MsgHdrF);
        IF (IOResult = 2) THEN
          ReWrite(MsgHdrF);
        Reset(MsgTxtF,1);
        IF (IOResult = 2) THEN
          ReWrite(MsgTxtF,1);

        QWKHeader.MBase := UseMsgArea;

        IndexR.Conf := UseMsgArea;

        TotalNewMsgsInArea := 0;

        TotalYourMsgsInArea := 0;

        PrintMain('}'+PadRightInt(MArea,4)+
                  '    ~'+PadLeftStr(MemMsgArea.Name,22)+
                  '  '+PadLeftStr(MemMsgArea.FileName,11)+
                  '€'+PadLeftStr(ShowYesNo(MemMsgArea.MAType <> 0),3)+
                  ''+PadRightInt(FileSize(MsgHdrF),8));

        Upload_Display;

        IF (UseMsgArea > 0) THEN
          MsgNum := FirstNew
        ELSE
          MsgNum := 1;

        IF (MsgNum > 0) THEN
        BEGIN

          S := IntToStr(UseMsgArea);

          WHILE (Length(S) < 3) DO
            S := '0' + S;

          Assign(NDXFile,TempDir+'QWK\'+S+'.NDX');
          ReWrite(NDXFile);

          WKey;

          WHILE (MsgNum <= FileSize(MsgHdrF)) AND
                (TotalNewMsgsInArea < General.MaxQWKBase) AND
                ((TotalNewMsgsAllAreas + TotalNewMsgsInArea) < General.MaxQWKTotal) AND
                (NOT Abort) AND (NOT HangUp) DO
          BEGIN
            IF (MArea >= 0) THEN
              Inc(TotalNewMsgsInArea);
            WKey;
            IF ((Timer - LastUpdate) > 3) OR ((Timer - LastUpdate) < 0) THEN
            BEGIN
              BackErase(22);
              Upload_Display;
            END;
            Seek(MsgHdrF,(MsgNum - 1));
            Read(MsgHdrF,MHeader);
            IF (NOT (MDeleted IN MHeader.Status)) AND
                NOT (Unvalidated IN MHeader.Status) AND
                NOT (FromYou(MHeader) AND NOT ThisUser.GetOwnQWK) AND
                NOT ((Prvt IN MHeader.Status) AND NOT (FromYou(MHeader) OR ToYou(MHeader))) AND
                NOT ((MArea = -1) AND NOT (ToYou(MHeader))) THEN
            BEGIN

              IF (MArea = -1) THEN
                Inc(TotalNewMsgsInArea);

              IF (Prvt IN MHeader.Status) THEN
                QWKHeader.Flag := '*'
              ELSE
                QWKHeader.Flag := ' ';

              S := IntToStr(MsgNum);
              FillChar(QWKHeader.Num[1],SizeOf(QWKHeader.Num),' ');
              Move(S[1],QWKHeader.Num[1],Length(S));

              PackToDate(DT,MHeader.Date);

              IF (MHeader.From.Anon = 0) THEN
                S := ZeroPad(IntToStr(DT.Month))+
                    '-'+ZeroPad(IntToStr(DT.Day))+
                    '-'+Copy(IntToStr(DT.Year),3,2)
              ELSE
                S := '';

              FillChar(QWKHeader.MsgDate[1],SizeOf(QWKHeader.MsgDate),' ');
              Move(S[1],QWKHeader.MsgDate[1],Length(S));

              IF (MHeader.From.Anon = 0) THEN
                S := ZeroPad(IntToStr(DT.Hour))+
                     ':'+ZeroPad(IntToStr(DT.Min))
              ELSE
                S := '';

              FillChar(QWKHeader.MsgTime,SizeOf(QWKHeader.MsgTime),' ');
              Move(S[1],QWKHeader.MsgTime[1],Length(S));

              S := MHeader.MTo.A1S;
              IF (MARealName IN MemMsgArea.MAFlags) THEN
                S := AllCaps(MHeader.MTo.Real);
              S := Caps(Usename(MHeader.MTo.Anon,S));

              FillChar(QWKHeader.MsgTo,SizeOf(QWKHeader.MsgTo),' ');
              Move(S[1],QWKHeader.MsgTo[1],Length(S));

              S := MHeader.From.A1S;
              IF (MARealName IN MemMsgArea.MAFlags) THEN
                S := AllCaps(MHeader.From.Real);
              S := Caps(Usename(MHeader.From.Anon,S));

              FillChar(QWKHeader.MsgFrom[1],SizeOf(QWKHeader.MsgFrom),' ');
              Move(S[1],QWKHeader.MsgFrom[1],Length(S));

              FillChar(QWKHeader.MsgSubj[1],SizeOf(QWKHeader.MsgSubj),' ');

              IF (MHeader.FileAttached > 0) THEN
                MHeader.Subject := StripName(MHeader.Subject);

              Move(MHeader.Subject[1],QWKHeader.MsgSubj[1],Length(MHeader.Subject));

              Marker := FilePos(MsgFile);

              BlockWrite(MsgFile,QWKHeader,128);

              Real_To_Msb(FileSize(MsgFile) DIV 128,IndexR.Pointer);
              Write(NDXFile,IndexR);

              IF ToYou(MHeader) THEN
              BEGIN
                Write(PNDXFile,IndexR);
                Inc(TotalYourMsgsInArea);
              END;

              X := 1;
              TempTextSize := 0;
              Texts := '';

              IF ((MHeader.Pointer - 1) < FileSize(MsgTxtF)) AND
                 (((MHeader.Pointer - 1) + MHeader.TextSize) <= FileSize(MsgTxtF)) THEN
              BEGIN
                Seek(MsgTxtF,(MHeader.Pointer - 1));
                REPEAT
                  BlockRead(MsgTxtF,S[0],1);
                  BlockRead(MsgTxtF,S[1],Byte(S[0]));
                  Inc(TempTextSize,(Length(S) + 1));
                  S := S + 'ã';
                  Texts := Texts + S;
                  IF (Length(Texts) > 128) THEN
                  BEGIN
                    BlockWrite(MsgFile,Texts[1],128);
                    Inc(X);
                    Move(Texts[129],Texts[1],(Length(Texts) - 128));
                    Dec(Texts[0],128);
                  END;
                UNTIL (TempTextSize >= MHeader.TextSize);
                IF (Texts <> '') THEN
                BEGIN
                  IF (Length(Texts) < 128) THEN
                  BEGIN
                    FillChar(Texts[Length(Texts) + 1],(128 - Length(Texts)),32);
                    Texts[0] := #128;
                  END;
                  BlockWrite(MsgFile,Texts[1],128);
                  Inc(X);
                END;
              END
              ELSE
              BEGIN
                Include(MHeader.Status,MDeleted);
                MHeader.TextSize := 0;
                MHeader.Pointer := -1;
                Seek(MsgHdrF,(MsgNum - 1));
                Write(MsgHdrF,MHeader);
              END;

              S := IntToStr(X);

              FillChar(QWKHeader.NumBlocks[1],SizeOf(QWKHeader.NumBlocks),' ');
              Move(S[1],QWKHeader.NumBlocks[1],Length(S));

              Seek(MsgFile,Marker);
              BlockWrite(MsgFile,QWKHeader,128);
              Seek(MsgFile,FileSize(MsgFile));
            END;
            Inc(MsgNum);
          END;
          Close(NDXFile);
        END;
        BackErase(22);
        Upload_Display;
        NL;
        IF (TotalNewMsgsInArea >= General.MaxQWKBase) THEN
          Print('Maximum number of messages per area reached.');
        IF ((TotalNewMsgsAllAreas + TotalNewMsgsInArea) >= General.MaxQWKTotal) THEN
          Print('Maximum number of messages per QWK packet reached.');
        LastK := FileSize(MsgFile);
        Inc(TotalNewMsgsAllAreas,TotalNewMsgsInArea);
        Inc(TotalYourMsgsAllAreas,TotalYourMsgsInArea);
        Inc(TotalMsgsAllAreas,FileSize(MsgHdrF));
        Close(MsgHdrF);
        Close(MsgTxtF);
      END;
      IF ((TotalNewMsgsAllAreas + TotalNewMsgsInArea) >= General.MaxQWKTotal) OR Abort THEN
        Break;
    END;

    IF (FileSize(PNDXFile) = 0) THEN
    BEGIN
      Close(PNDXFile);
      Erase(PNDXFile);
    END
    ELSE
      Close(PNDXFile);
    NL;

    IF (NOT Abort) THEN
      Print('^0     Totals:'+PadRightInt(TotalMsgsAllAreas,43)+PadRightInt(TotalNewMsgsAllAreas,7)+
            PadRightInt(TotalYourMsgsAllAreas,6)+
            PadRightStr(IntToStr(FileSize(MsgFile) DIV 1024)+'k',8));

    Close(MsgFile);
    NL;

    lil := 0;
    IF (TotalNewMsgsAllAreas < 1) OR (Abort) THEN
    BEGIN
      IF (TotalNewMsgsAllAreas < 1) THEN
        Print('No new messages!');
      OffLineMail := FALSE;
      ConfSystem := SaveConfSystem;
      IF (SaveConfSystem) THEN
        NewCompTables;
      MsgArea := SaveMsgArea;
      LoadMsgArea(MsgArea);
      Exit;
    END;

    IF (MakeQWKFor = 0) THEN
    BEGIN
      NL;
      IF NOT PYNQ('Proceed to packet compression: ',0,TRUE) THEN
      BEGIN
        OffLineMail := FALSE;
        ConfSystem := SaveConfSystem;
        IF (SaveConfSystem) THEN
          NewCompTables;
        MsgArea := SaveMsgArea;
        LoadMsgArea(MsgArea);
        Exit;
      END;
    END;

    NL;
    Star('Compressing '+General.PacketName+'.QWK');

    ArcComp(Ok,ThisUser.DefArcType,TempDir+'QWK\'+General.PacketName+'.QWK',TempDir+'QWK\*.*');
    IF (NOT Ok) OR (NOT Exist(TempDir+'QWK\'+General.PacketName+'.QWK')) THEN
    BEGIN
      NL;
      Print('Error archiving QWK packet!');
      OffLineMail := FALSE;
      ConfSystem := SaveConfSystem;
      IF (SaveConfSystem) THEN
        NewCompTables;
      MsgArea := SaveMsgArea;
      LoadMsgArea(MsgArea);
      Exit;
    END;

    SysOpLog('QWK packet created.');
  END;

  FindFirst(TempDir+'QWK\'+General.PacketName+'.QWK',AnyFile,DirInfo);
  IF (InCom) AND (NSL < (DirInfo.Size DIV Rate)) AND (NOT General.qwktimeignore) THEN
  BEGIN
    NL;
    Print('Sorry, not enough time left online to transfer.');
    OffLineMail := FALSE;
    ConfSystem := SaveConfSystem;
    IF (SaveConfSystem) THEN
      NewCompTables;
    MsgArea := SaveMsgArea;
    LoadMsgArea(MsgArea);
    Exit;
  END;

  Star('Compressed packet size is '+ConvertBytes(DirInfo.Size,FALSE)+'.');

  IF (InCom) AND (NOT HangUp) THEN
  BEGIN
    SaveFileArea := FileArea;
    FileArea := -1;
    WITH MemFileArea DO
    BEGIN
      AreaName := 'Offline Mail';
      DLPath := TempDir+'QWK\';
      ULPath := TempDir+'QWK\';
      FAFlags := [FANoRatio];
    END;
    WITH FileInfo DO
    BEGIN
      FileName := Align(General.PacketName+'.QWK');
      Description := 'QWK Download';
      FilePoints := 0;
      Downloaded := 0;
      FileSize := GetFileSize(TempDir+'QWK\'+General.PacketName+'.QWK');
      OwnerNum := UserNum;
      OwnerName := Caps(ThisUser.Name);
      FileDate := Date2PD(DateStr);
      VPointer := -1;
      VTextSize := 0;
      FIFlags := [];
    END;
    TransferFlags := [IsQWK];
    DLX(FileInfo,-1,TransferFlags);
    FileArea := SaveFileArea;
    LoadFileArea(FileArea);
    IF (IsTransferOk IN TransferFlags) AND (NOT (IsKeyboardAbort IN TransferFlags)) THEN
    BEGIN

      Star('Updating message pointers');

      Inc(PublicReadThisCall,TotalNewMsgsAllAreas);

      UpdatePointers;

      Star('Message pointers updated');

      IF (ThisUser.PrivateQWK) THEN
      BEGIN
        KillEmail;
        Star('Private messages killed.');
      END;

    END;
  END
  ELSE
  BEGIN
    S := General.QWKLocalPath+General.PacketName;
    IF Exist(S+'.QWK') AND ((MakeQWKFor > 0) OR NOT (PYNQ(^M^J'Replace existing .QWK? ',0,FALSE))) THEN
      FOR C := 'A' TO 'Z' DO
        IF NOT (Exist(S+'.QW'+C)) THEN
        BEGIN
          S := S + '.QW' + C;
          Break;
        END;
    IF (Pos('.', S) = 0) THEN
      S := S + '.QWK';

    CopyMoveFile(TRUE,'',TempDir+'QWK\'+General.PacketName+'.QWK',S,FALSE);

    NL;
    UpdatePointers;
    IF (ThisUser.PrivateQWK) THEN
      KillEmail;
  END;
  IF Exist(TempDir+'QWK\'+General.PacketName+'.REP') THEN
  BEGIN
    NL;
    Star('Bidirectional upload of '+General.PacketName+'.REP detected');
    UploadPacket(TRUE);
  END;
  OffLineMail := FALSE;
  ConfSystem := SaveConfSystem;
  IF (SaveConfSystem) THEN
    NewCompTables;
  MsgArea := SaveMsgArea;
  LoadMsgArea(MsgArea);
  LastError := IOResult;
END;


PROCEDURE uploadpacket(Already:Boolean);
VAR
  F: FILE;
  User: UserRecordType;
  MHeader: MHeaderRec;
  QWKHeader: QWKHeadeRec;

  S,
  Os: STRING;

  Counter,
  Counter1: Byte;

  RCode,
  MArea,
  SaveMsgArea: Integer;

  X,
  Blocks: Word;

  TransferTime,
  TempDate: LongInt;

  Ok,
  UploadOk,
  KeyboardAbort,
  AddBatch,
  SaveConfSystem: Boolean;

  FUNCTION FindBase(IndexNumber: Word): Word;
  VAR
    j,
    k: Integer;
  BEGIN
    Reset(MsgAreaFile);
    j := 0;
    k := 0;
    WHILE (j = 0) AND NOT (EOF(MsgAreaFile)) DO
    BEGIN
      Inc(k);
      Read(MsgAreaFile,MemMsgArea);
      IF (MemMsgArea.QWKIndex = IndexNumber) THEN
        j := k;
    END;
    Close(MsgAreaFile);
    FindBase := k;
  END;

BEGIN
  IF (RPost IN ThisUser.Flags) THEN
  BEGIN
    NL;
    Print('You are restricted from posting messages.');
    Exit;
  END;

  SaveMsgArea := MsgArea;  (* Was ReadMsgArea *)

  SaveConfSystem := ConfSystem;
  ConfSystem := FALSE;
  IF (SaveConfSystem) THEN
    NewCompTables;

  PurgeDir(TempDir+'UP\',FALSE);

  TimeLock := TRUE;

  UploadOk := TRUE;
  KeyboardAbort := FALSE;

  IF (ComPortSpeed = 0) OR (UpQWKFor > 0) THEN
    CopyMoveFile(TRUE,'',General.QWKLocalPath+General.PacketName+'.REP',TempDir + 'QWK\' + General.PacketName+'.REP',FALSE)
  ELSE
  BEGIN
    IF (NOT Already) THEN
      Receive(General.PacketName+'.REP',TempDir+'\QWK',FALSE,UploadOk,KeyboardAbort,AddBatch,TransferTime)
    ELSE
      CopyMoveFile(FALSE,'',TempDir+'UP\'+General.PacketName+'.REP',
               TempDir+'QWK\'+General.PacketName+'.REP',FALSE);
  END;

  TimeLock := FALSE;

  IF (UploadOk) AND (NOT KeyboardAbort) THEN
  BEGIN

    SysOpLog('Uploaded REP packet');

    IF (NOT Already) THEN
      Print('Transfer successful');

    ExecBatch(Ok,TempDir+'QWK\',General.ArcsPath+
              FunctionalMCI(General.FileArcInfo[ThisUser.DefArcType].UnArcLine,
              TempDir+'QWK\'+General.PacketName+'.REP',
              General.PacketName+'.MSG'),
              General.FileArcInfo[ThisUser.DefArcType].SuccLevel,RCode,FALSE);

    IF (Ok) AND Exist(TempDir+'QWK\'+General.PacketName+'.MSG') THEN
    BEGIN
      Assign(F,TempDir+'QWK\'+General.PacketName+'.MSG');
      Reset(F,1);

      GetFTime(F,TempDate);

      IF (TempDate = ThisUser.LastQWK) THEN
      BEGIN
        NL;
        Print('This packet has already been uploaded here.');
        Close(F);
        Exit;
      END;

      ThisUser.LastQWK := TempDate;

      MHeader.FileAttached := 0;
      MHeader.MTo.UserNum := 0;
      MHeader.MTo.Anon := 0;
      MHeader.ReplyTo := 0;
      MHeader.Replies := 0;

      TempDate := GetPackDateTime;

      BlockRead(F,S,128);
      WHILE NOT EOF(F) DO
      BEGIN
        IF (IOResult <> 0) THEN
        BEGIN
          WriteLn('error processing REP packet.');
          Break;
        END;

        BlockRead(F,QWKHeader,128);

        S[0] := #6;
        Move(QWKHeader.NumBlocks[1],S[1],6);

        Blocks := (StrToInt(S) - 1);

        IF (QWKHeader.MBase = 0) THEN
          MArea := -1
        ELSE
          MArea := FindBase(QWKHeader.MBase);

        InitMsgArea(MArea);

        IF AACS(MemMsgArea.ACS) AND AACS(MemMsgArea.PostACS) AND NOT
           ((PublicPostsToday >= General.MaxPubPost) AND (NOT MsgSysOp)) THEN
        BEGIN
          LastError := IOResult;
          Reset(MsgHdrF);
          IF (IOResult = 2) THEN
            ReWrite(MsgHdrF);
          Reset(MsgTxtF,1);
          IF (IOResult = 2) THEN
            ReWrite(MsgTxtF,1);

          IF AACS(General.QWKNetworkACS) THEN
          BEGIN
            S[0] := #25;
            Move(QWKHeader.MsgFrom[1],S[1],SizeOf(QWKHeader.MsgFrom));
            WHILE (S[Length(S)] = ' ') DO
              Dec(S[0]);
            MHeader.From.UserNum := 0;
          END
          ELSE
          BEGIN
            IF (MARealName IN MemMsgArea.MAFlags) THEN
              S := ThisUser.RealName
            ELSE
              S := ThisUser.Name;
            MHeader.From.UserNum := UserNum;
          END;

          MHeader.From.A1S := S;
          MHeader.From.Real := S;
          MHeader.From.Name := S;
          MHeader.From.Anon := 0;

          S[0] := #25;
          Move(QWKHeader.MsgTo[1],S[1],SizeOf(QWKHeader.MsgTo));

          WHILE (S[Length(S)] = ' ') DO
            Dec(S[0]);

          MHeader.MTo.A1S := S;
          MHeader.MTo.Real := S;
          MHeader.MTo.Name := S;
          MHeader.MTo.UserNum := SearchUser(MHeader.MTo.Name,FALSE);

          MHeader.Pointer := (FileSize(MsgTxtF) + 1);
          MHeader.Date := TempDate;
          Inc(TempDate);
          GetDayOfWeek(MHeader.DayOfWeek);

          MHeader.Status := [];

          IF (QWKHeader.Flag IN ['*','+']) AND (MAPrivate IN MemMsgArea.MAFlags) THEN
            Include(MHeader.Status,Prvt);

          IF (RValidate IN ThisUser.Flags) THEN
            Include(MHeader.Status,Unvalidated);

          IF (AACS(MemMsgArea.MCIACS)) THEN
            Include(MHeader.Status,AllowMCI);

          Move(QWKHeader.MsgSubj[1],S[1],SizeOf(QWKHeader.MsgSubj));
          S[0] := Chr(SizeOf(QWKHeader.MsgSubj));

          WHILE (S[Length(S)] = ' ') DO
            Dec(S[0]);

          MHeader.Subject := S;

          SysOpLog(MHeader.From.Name+' posted on '+MemMsgArea.Name);
          SysOpLog('To: '+MHeader.MTo.Name);

          MHeader.OriginDate[0] := #14;
          Move(QWKHeader.MsgDate[1],MHeader.OriginDate[1],8);
          MHeader.OriginDate[9] := #32;
          Move(QWKHeader.MsgTime[1],MHeader.OriginDate[10],5);

          MHeader.TextSize := 0;

          IF (AllCaps(MHeader.MTo.A1S) <> 'QMAIL') THEN
          BEGIN
            Seek(MsgTxtF,FileSize(MsgTxtF));
            Os := '';
            X := 1;
            WHILE (X <= Blocks) AND (IOResult = 0) DO
            BEGIN
              BlockRead(F,S[1],128);
              S[0] := #128;
              S := Os + S;
              WHILE (Pos('ã',S) > 0) DO
              BEGIN
                Os := Copy(S,1,Pos('ã',S)-1);
                S := Copy(S,Pos('ã',S)+1,Length(S));
                IF (MemMsgArea.MAType <> 0) AND (Copy(Os,1,4) = '--- ') THEN
                  Os := ''
                ELSE
                BEGIN
                  IF (LennMCI(Os) > 78) THEN
                    Os := Copy(Os,1,78 + Length(Os) - LennMCI(Os));
                  Inc(MHeader.TextSize,Length(Os)+1);
                  BlockWrite(MsgTxtF,Os,Length(Os)+1);
                END;
              END;
              Os := S;
              Inc(X);
            END;

            WHILE (S[Length(S)] = ' ') DO
              Dec(S[0]);

            IF (Length(S) > 0) THEN
            BEGIN
              Inc(MHeader.TextSize,(Length(S) + 1));
              BlockWrite(MsgTxtF,S,(Length(S) + 1));
            END;

            IF (MemMsgArea.MAType <> 0) THEN
            BEGIN
              NewEchoMail := TRUE;
              IF NOT (MAScanOut IN MemMsgArea.MAFlags) THEN
                UpdateBoard;
            END;

            IF (MemMsgArea.MAType <> 0) AND (MAAddTear IN MemMsgArea.MAFlags) THEN
              WITH MemMsgArea DO
              BEGIN
                S := '--- Renegade v'+General.Version;
                Inc(MHeader.TextSize,(Length(S) + 1));
                BlockWrite(MsgTxtF,S,(Length(S) + 1));
                IF (MemMsgArea.Origin <> '') THEN
                  S := MemMsgArea.Origin
                ELSE
                  S := General.Origin;
                S := ' * Origin: '+S+' (';
                IF (AKA > 19) THEN
                  AKA := 0;
                S := S + IntToStr(General.AKA[AKA].Zone)+':'+
                         IntToStr(General.AKA[AKA].Net)+'/'+
                         IntToStr(General.AKA[AKA].Node);
                IF (General.AKA[AKA].Point > 0) THEN
                  S := S +'.'+IntToStr(General.AKA[AKA].Point);
                S := S + ')';
                Inc(MHeader.TextSize,(Length(S) + 1));
                BlockWrite(MsgTxtF,S,(Length(S) + 1));
              END;

            CLS;
            Ok := FALSE;
            UploadOk := FALSE;
            Seek(MsgHdrF,FileSize(MsgHdrF));
            Write(MsgHdrF,MHeader);

            IF (UpQWKFor <= 0) THEN
              Anonymous(TRUE,MHeader);

            IF (MArea = -1) THEN
            BEGIN
              IF (MHeader.MTo.UserNum = 0) THEN
              BEGIN
                IF (AACS(General.NetMailACS)) AND
                   (PYNQ(^M^J'Is this to be a netmail message? ',0,FALSE)) THEN
                BEGIN
                  IF (General.AllowAlias) AND PYNQ('Send this with your real name? ',0,FALSE) THEN
                    MHeader.From.A1S := ThisUser.RealName;
                  WITH MHeader.MTo DO
                    GetNetAddress(Name,Zone,Net,Node,Point,X,FALSE);
                  IF (MHeader.MTo.Name = '') THEN
                    Include(MHeader.Status,MDeleted)
                  ELSE
                  BEGIN
                    Inc(ThisUser.Debit,X);
                    Include(MHeader.Status,NetMail);
                    MHeader.NetAttribute := General.NetAttribute *
                                            [Intransit,Private,Crash,KillSent,Hold,Local];
                    ChangeFlags(MHeader);
                    Counter1 := 0;
                    Counter := 0;
                    WHILE (Counter <= 19) AND (Counter1 = 0) DO
                    BEGIN
                      IF (General.AKA[Counter].Zone = MHeader.MTo.Zone) AND
                         (General.AKA[Counter].Zone <> 0) THEN
                        Counter1 := Counter;
                      Inc(Counter);
                    END;
                    MHeader.From.Zone := General.AKA[Counter1].Zone;
                    MHeader.From.Net := General.AKA[Counter1].Net;
                    MHeader.From.Node := General.AKA[Counter1].Node;
                    MHeader.From.Point := General.AKA[Counter1].Point;
                  END;
                END
                ELSE
                  Include(MHeader.Status,MDeleted);
              END
              ELSE
              BEGIN
                IF (MHeader.MTo.UserNum > 1) THEN
                BEGIN
                  Inc(ThisUser.EmailSent);

                  IF (PrivatePostsToday < 255) THEN
                    Inc(PrivatePostsToday);

                END
                ELSE
                BEGIN
                  Inc(ThisUser.Feedback);

                  IF (FeedbackPostsToday < 255) THEN
                    Inc(FeedbackPostsToday);

                END;
                LoadURec(User,MHeader.MTo.UserNum);
                Inc(User.Waiting);
                SaveURec(User,MHeader.MTo.UserNum);
              END;
            END
            ELSE
            BEGIN
              Inc(ThisUser.MsgPost);

              IF (PublicPostsToday < 255) THEN
                Inc(PublicPostsToday);

              AdjustBalance(General.CreditPost);
            END;
            Seek(MsgHdrF,(FileSize(MsgHdrF) - 1));
            Write(MsgHdrF,MHeader);

          END
          ELSE
          BEGIN
            IF (MHeader.Subject = 'DROP') THEN
            BEGIN
              LoadLastReadRecord(LastReadRecord);
              LastReadRecord.NewScan := FALSE;
              SaveLastReadRecord(LastReadRecord)
            END
            ELSE IF (MHeader.Subject = 'ADD') THEN
            BEGIN
              LoadLastReadRecord(LastReadRecord);
              LastReadRecord.NewScan := TRUE;
              SaveLastReadRecord(LastReadRecord);
            END;
            Seek(F,FilePos(F) + (Blocks * 128));
          END;
          Close(MsgHdrF);
          Close(MsgTxtF);
        END
        ELSE
          Seek(F,FilePos(F) + (Blocks * 128));
      END;
      Close(F);
    END
    ELSE
      Print('Unable to decompress REP packet.');
  END
  ELSE
    Print('Transfer unsuccessful');

  IF Exist(General.QWKLocalPath+General.PacketName+'.REP') AND (ComPortSpeed = 0)
     AND (UpQWKFor = 0) AND PYNQ(^M^J'Delete REP packet? ',0,FALSE) THEN
    Kill(General.QWKLocalPath+General.PacketName+'.REP');

  PurgeDir(TempDir+'QWK\',FALSE);

  Update_Screen;

  IF (SaveConfSystem) THEN
  BEGIN
    ConfSystem := SaveConfSystem;
    NewCompTables;
  END;

  MsgArea := SaveMsgArea;
  InitMsgArea(MsgArea);

  LastError := IOResult;
END;

END.
