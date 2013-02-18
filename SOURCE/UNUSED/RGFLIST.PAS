PROGRAM RGFLIST;



PROCEDURE DownloadFileListing;
VAR
  FArea: Integer;

  PROCEDURE SearchFileAreaSpec(FArea: Integer; FName: Str12; VAR FArrayRecNum: Byte);
  VAR
    F: FileInfoRecordType;
    DirFileRecNum: Integer;
  BEGIN
    IF (FileArea <> FArea) THEN
      ChangeFileArea(FArea);
    IF (FileArea = FArea) THEN
    BEGIN
      RecNo(F,FName,DirFileRecNum);
      IF (BadDownloadPath) THEN
        Exit;
      WHILE (DirFileRecNum <> -1) AND (NOT Next) AND (NOT Abort) AND (NOT HangUp) DO
      BEGIN
        Seek(DirFile,DirFileRecNum);
        Read(DirFile,F);
        IF (CanSee(F)) THEN
        BEGIN
          WITH FArray[FArrayRecNum] DO
          BEGIN
            FArrayFileArea := FileArea;
            FArrayDirFileRecNum := DirFileRecNum;
          END;
          DisplayFileAreaHeader;
          Display_File(F,FArrayRecNum,'',FALSE);
          Inc(FArrayRecNum);
          IF (FArrayRecNum = 100) THEN
            FArrayRecNum := 0;
        END;
        NRecNo(F,FName,DirFileRecNum);
      END;
      Close(DirFile);
      Close(VerbF);
    END;
  END;

BEGIN
  FArea := 1;
  WHILE (FArea <= NumFileAreas) DO
  BEGIN
    SearchFileAreaSpec(FArea,FName,FArrayRecNum);
    Inc(FArea);
  END;
END;

BEGIN
END.