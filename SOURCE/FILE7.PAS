{$IFDEF WIN32}
{$I DEFINES.INC}
{$ENDIF}

{$A+,B-,D+,E-,F+,I-,L+,N-,O+,R-,S+,V-}

UNIT File7;

INTERFACE

PROCEDURE CheckFilesBBS;

IMPLEMENTATION

USES
  DOS,
  Common,
  File0,
  File1,
  File10,
  TimeFunc;

PROCEDURE AddToDirFile(FileInfo: FileInfoRecordType);
VAR
  User: UserRecordType;
  NumExtDesc: Byte;
BEGIN
  LoadURec(User,1);

  WITH FileInfo DO
  BEGIN
    (*
    FileName := '';    Value Passed
    Description := '';  Value Passed
    *)
    FilePoints := 0;
    Downloaded := 0;
    (*
    FileSize := 0;    Value Passed
    *)
    OwnerNum := 1;
    OwnerName := AllCaps(User.Name);
    FileDate := Date2PD(DateStr);
    VPointer := -1;
    VTextSize := 0;
    FIFlags := [FIHatched];
  END;

  IF (NOT General.FileCreditRatio) THEN
    FileInfo.FilePoints := 0
  ELSE
  BEGIN
    FileInfo.FilePoints := 0;
    IF (General.FileCreditCompBaseSize > 0) THEN
      FileInfo.FilePoints := ((FileInfo.FileSize DIV 1024) DIV General.FileCreditCompBaseSize);
  END;

  FillChar(ExtendedArray,SizeOf(ExtendedArray),0);

  IF (General.FileDiz) AND (DizExists(MemFileArea.DLPath+SQOutSp(FileInfo.FileName))) THEN
    GetDiz(FileInfo,ExtendedArray,NumExtDesc);

  WriteFV(FileInfo,FileSize(FileInfoFile),ExtendedArray);

  IF (UploadsToday < 2147483647) THEN
    Inc(UploadsToday);

  IF ((UploadKBytesToday + (FileInfo.FileSize DIV 1024)) < 2147483647) THEN
    Inc(UploadKBytesToday,(FileInfo.FileSize DIV 1024))
  ELSE
    UploadKBytesToday := 2147483647;

  SaveGeneral(FALSE);

  Print('^1hatched!');

  SysOpLog('   Hatched: "^5'+SQOutSp(FileInfo.FileName)+'^1" to "^5'+MemFileArea.AreaName+'^1"');

  LastError := IOResult;
END;

(* Sample FILES.BBS
TDRAW463.ZIP  THEDRAW SCREEN EDITOR VERSION 4.63 - (10/93) A text-orient
ZEJNGAME.LST  [4777] 12-30-01 ZeNet Games list, Updated December 29th, 2
*)

PROCEDURE CheckFilesBBS;
VAR
  BBSTxtFile: Text;
  TempStr: AStr;
  FArea,
  SaveFileArea,
  DirFileRecNum: Integer;
  Found,
  FirstTime,
  SaveTempPause: Boolean;
BEGIN
  SysOpLog('Scanning for FILES.BBS ...');
  SaveFileArea := FileArea;
  SaveTempPause := TempPause;
  TempPause := FALSE;
  Abort := FALSE;
  Next := FALSE;
  FArea := 1;
  WHILE (FArea >= 1) AND (FArea <= NumFileAreas) AND (NOT Abort) AND (NOT HangUp) DO
  BEGIN

    LoadFileArea(FArea);

    FirstTime := TRUE;
    Found := FALSE;
    LIL := 0;
    CLS;
    Prompt('^1Checking ^5'+MemFileArea.AreaName+' #'+IntToStr(CompFileArea(FArea,0))+'^1 ...');

    IF (Exist(MemFileArea.DLPath+'FILES.BBS')) THEN
    BEGIN

      Assign(BBSTxtFile,MemFileArea.DLPath+'FILES.BBS');
      Reset(BBSTxtFile);
      WHILE NOT EOF(BBSTxtFile) DO
      BEGIN
        ReadLn(BBSTxtFile,TempStr);
        TempStr := StripLeadSpace(TempStr);
        IF (TempStr <> '') THEN
        BEGIN

          FileInfo.FileName := Align(AllCaps(Copy(TempStr,1,(Pos(' ',TempStr) - 1))));

          IF (FirstTime) THEN
          BEGIN
            NL;
            NL;
            FirstTime := FALSE;
          END;

          Prompt('^1Processing "^5'+SQOutSp(FileInfo.FileName)+'^1" ... ');

          IF (NOT Exist(MemFileArea.DLPath+SQOutSp(FileInfo.FileName))) THEN
          BEGIN
            Print('^7missing!^1');
            SysOpLog('   ^7Missing: "^5'+SQOutSp(FileInfo.FileName)+'^7" from "^5'+MemFileArea.AreaName+'^7"');
          END
          ELSE
          BEGIN
            FileArea := FArea;
            RecNo(FileInfo,FileInfo.FileName,DirFileRecNum);
            IF (BadDownloadPath) THEN
              Exit;
            IF (DirFileRecNum <> -1) THEN
            BEGIN
              Print('^7duplicate!^1');
              SysOpLog('   ^7Duplicate: "^5'+SQOutSp(FileInfo.FileName)+'^7" from "^5'+MemFileArea.AreaName+'^7"');
            END
            ELSE
            BEGIN

              TempStr := StripLeadSpace(Copy(TempStr,Pos(' ',TempStr),Length(TempStr)));
              IF (TempStr[1] <> '[') THEN
                FileInfo.Description := Copy(TempStr,1,50)
              ELSE
              BEGIN
                TempStr := StripLeadSpace(Copy(TempStr,(Pos(']',TempStr) + 1),Length(TempStr)));
                FileInfo.Description := StripLeadSpace(Copy(TempStr,(Pos(' ',TempStr) + 1),50));
              END;

              FileInfo.FileSize := GetFileSize(MemFileArea.DLPath+SQOutSp(FileInfo.FileName));

              AddToDirFile(FileInfo);

            END;
            Close(FileInfoFile);
            Close(ExtInfoFile);
          END;
          Found := TRUE;
        END;
      END;
      Close(BBSTxtFile);

      IF (NOT (FACDROM IN MemFileArea.FAFlags)) THEN
        Erase(BBSTxtFile);
    END;

    IF (NOT Found) THEN
    BEGIN
      LIL := 0;
      BackErase(15 + LennMCI(MemFileArea.AreaName) + Length(IntToStr(CompFileArea(FArea,0))));
    END;

    Inc(FArea);

  END;
  TempPause := SaveTempPause;
  FileArea := SaveFileArea;
  LoadFileArea(FileArea);
  LastError := IOResult;
END;

END.