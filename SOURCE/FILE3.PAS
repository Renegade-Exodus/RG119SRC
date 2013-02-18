{$IFDEF WIN32}
{$I DEFINES.INC}
{$ENDIF}

{$A+,B-,D+,E-,F+,I-,L+,N-,O+,R-,S+,V-}

UNIT File3;

INTERFACE

PROCEDURE ReCheck;

IMPLEMENTATION

USES
  Dos,
  Common,
  File0,
  File1;

PROCEDURE CheckFiles(FArea: Integer; CheckDiz: Boolean);
VAR
  FN: AStr;
  NumExtDesc: Byte;
  DirFileRecNum: Integer;
  FSize: LongInt;
BEGIN
  IF (FileArea <> FArea) THEN
    ChangeFileArea(FArea);
  IF (FileArea = FArea) THEN
  BEGIN
    RecNo(FileInfo,'*.*',DirFileRecNum);
    IF (BadDownloadPath) THEN
      Exit;
    NL;
    Print('^1Checking ^5'+MemFileArea.AreaName+' #'+IntToStr(CompFileArea(FArea,0))+'^1 ...');
    WHILE (DirFileRecNum <> - 1) AND (NOT Abort) AND (NOT HangUp) DO
    BEGIN
      Seek(FileInfoFile,DirFileRecNum);
      Read(FileInfoFile,FileInfo);

      IF Exist(MemFileArea.DLPath+FileInfo.FileName) THEN
        FN := MemFileArea.DLPath+SQOutSp(FileInfo.FileName)
      ELSE
        FN := MemFileArea.ULPath+SQOutSp(FileInfo.FileName);

      FSize := GetFileSize(FN);
      IF (FSize = 0) THEN
      BEGIN
        FileInfo.FileSize := 0;
        Include(FileInfo.FIFlags,FIIsRequest);
      END
      ELSE
      BEGIN
        FileInfo.FileSize := FSize;
        Exclude(FileInfo.FIFlags,FIIsRequest);
      END;

      IF (CheckDiz) AND (DizExists(FN)) THEN
      BEGIN
        FillChar(ExtendedArray,SizeOf(ExtendedArray),0);
        GetDiz(FileInfo,ExtendedArray,NumExtDesc);
        WriteFV(FileInfo,DirFileRecNum,ExtendedArray);
      END;

      Seek(FileInfoFile,DirFileRecNum);
      Write(FileInfoFile,FileInfo);

      NRecNo(FileInfo,DirFileRecNum);
    END;
    Close(FileInfoFile);
    Close(ExtInfoFile);
  END;
  LastError := IOResult;
END;

PROCEDURE ReCheck;
VAR
  SaveFileArea,
  FArea: Integer;
  CheckDiz,
  SaveConfSystem,
  SaveTempPause: Boolean;
BEGIN
  CheckDiz := PYNQ('%LFReimport descriptions? ',0,FALSE);
  SaveTempPause := TempPause;
  TempPause := FALSE;
  Abort := FALSE;
  Next := FALSE;
  NL;
  IF (NOT PYNQ('Recheck all file areas? ',0,FALSE)) THEN
    CheckFiles(FileArea,CheckDiz)
  ELSE
  BEGIN
    SaveFileArea := FileArea;
    SaveConfSystem := ConfSystem;
    IF (SaveConfSystem) THEN
      NewCompTables;
    FArea := 1;
    WHILE (FArea >= 1) AND (FArea <= NumFileAreas) AND (NOT Abort) AND (NOT HangUp) DO
    BEGIN
      Checkfiles(FArea,CheckDiz);
      WKey;
      Inc(FArea);
    END;
    ConfSystem := SaveConfSystem;
    IF (SaveConfSystem) THEN
      NewCompTables;
    FileArea := SaveFileArea;
    LoadFileArea(FileArea);
  END;
  TempPause := SaveTempPause;
END;

END.
