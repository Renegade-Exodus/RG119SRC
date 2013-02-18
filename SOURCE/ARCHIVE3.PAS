{$IFDEF WIN32}
{$I DEFINES.INC}
{$ENDIF}

{$A+,B-,D-,E-,F+,I-,L-,N-,O+,R-,S+,V-}

UNIT Archive3;

INTERFACE

PROCEDURE ReZipStuff;

IMPLEMENTATION

USES
  Dos,
  Archive1,
  Common,
  Execbat,
  File0,
  File11,
  TimeFunc;

PROCEDURE CvtFiles(FArea: Integer; FileName,ReZipCmd: AStr; VAR TotalFiles: SmallInt; VAR TotalOldSize,TotalNewSize: LongInt);
VAR
  S: AStr;
  DS: DirStr;
  NS: NameStr;
  ES: ExtStr;
  AType: Byte;
  ReturnCode,
  DirFileRecNum: Integer;
  OldSiz,
  NewSiz: LongInt;
  Ok: Boolean;
BEGIN
  IF (FileArea <> FArea) THEN
    ChangeFileArea(FArea);
  IF (FileArea = FArea) AND (NOT (FACDROM IN MemFileArea.FAFlags)) THEN
  BEGIN
    RecNo(FileInfo,FileName,DirFileRecNum);
    IF (BadDownloadPath) THEN
      Exit;
    WHILE (DirFileRecNum <> -1) AND (NOT Abort) AND (NOT HangUp) DO
    BEGIN
      Seek(FileInfoFile,DirFileRecNum);
      Read(FileInfoFile,FileInfo);

      IF Exist(MemFileArea.DLPath+FileInfo.FileName) THEN
        FileName := MemFileArea.DLPath+FileInfo.FileName
      ELSE
        FileName := MemFileArea.ULPath+FileInfo.FileName;

      AType := ArcType(FileName);
      IF (AType <> 0) THEN
      BEGIN
        DisplayFileAreaHeader;
        NL;
        Star('Converting "'+SQOutSp(FileName)+'"');
        Ok := FALSE;
        IF (NOT Exist(FileName)) THEN
          Star('File "'+SQOutSp(FileName)+'" doesn''t exist.')
        ELSE
        BEGIN

          IF (ReZipCmd <> '') THEN
          BEGIN
            OldSiz := GetFileSize(FileName);

            ExecBatch(Ok,TempDir+'ARC\',ReZipCmd+' '+SQOutSp(FileName),-1,ReturnCode,FALSE);

            NewSiz := GetFileSize(FileName);

            FileInfo.FileSize := NewSiz;

            Seek(FileInfoFile,DirFileRecNum);
            Write(FileInfoFile,FileInfo);

          END
          ELSE
          BEGIN
            Ok := TRUE;
            S := FileName;

            OldSiz := GetFileSize(FileName);

            ConvA(Ok,AType,AType,SQOutSp(FileName),SQOutSp(S));

            IF (Ok) THEN
              IF (NOT Exist(SQOutSp(S))) THEN
              BEGIN
                Star('Unable to access "'+SQOutSp(S)+'"');
                SysOpLog('Unable to access '+SQOutSp(S));
                Ok := FALSE;
              END;

            IF (Ok) THEN
            BEGIN

              FileInfo.FileName := Align(StripName(SQOutSp(S)));
              Seek(FileInfoFile,DirFileRecNum);
              Write(FileInfoFile,FileInfo);

              FSplit(FileName,DS,NS,ES);
              FileName := DS+NS+'.#$%';
              Kill(FileName);
              IF (IOResult <> 0) THEN
              BEGIN
                Star('Unable to erase '+SQOutSp(FileName));
                SysOpLog('Unable to erase '+SQOutSp(FileName));
              END;

              Ok := Exist(SQOutSp(S));
              IF (NOT Ok) THEN
              BEGIN
                Star('Unable to access '+SQOutSp(S));
                SysOpLog('Unable to access '+SQOutSp(S));
              END
              ELSE
              BEGIN
                NewSiz := GetFileSize(S);

                FileInfo.FileSize := NewSiz;

                Seek(FileInfoFile,DirFileRecNum);
                Write(FileInfoFile,FileInfo);
                ArcComment(Ok,AType,MemFileArea.CmtType,SQOutSp(S));
              END;
            END
            ELSE
            BEGIN
              SysOpLog('Unable to convert '+SQOutSp(FileName));
              Star('Unable to convert '+SQOutSp(FileName));
            END;
          END;

          IF (Ok) THEN
          BEGIN
            Inc(TotalOldSize,OldSiz);
            Inc(TotalNewSize,NewSiz);
            Inc(TotalFiles);
            Star('Old total space took up  : '+ConvertBytes(OldSiz,FALSE));
            Star('New total space taken up : '+ConvertBytes(NewSiz,FALSE));
            IF ((OldSiz - NewSiz) > 0) THEN
              Star('Space saved              : '+ConvertBytes(OldSiz - NewSiz,FALSE))
            ELSE
              Star('Space wasted             : '+ConvertBytes(NewSiz - OldSiz,FALSE));
          END;

        END;
      END;
      WKey;
      NRecNo(FileInfo,DirFileRecNum);
    END;
    Close(FileInfoFile);
    Close(ExtInfoFile);
  END;
  LastError := IOResult;
END;

PROCEDURE ReZipStuff;
TYPE
  TotalsRecordType = RECORD
    TotalFiles: SmallInt;
    TotalOldSize,
    TotalNewSize: LongInt
  END;
VAR
  TotalsRecord: TotalsRecordType;
  FileName: Str12;
  ReZipCmd: Str78;
  FArea,
  SaveFileArea: Integer;
BEGIN
  FillChar(TotalsRecord,SizeOf(TotalsRecord),0);
  NL;
  Print('Re-compress archives -');
  NL;
  Print('Filespec:');
  Prt(':');
  MPL(12);
  Input(FileName,12);
  IF (FileName = '') THEN
  BEGIN
    NL;
    Print('Aborted!');
    Exit;
  END;
  ReZipCmd := '';
  NL;
  Print('^7Do you wish to use a REZIP external utility?');
  IF PYNQ('(such as REZIP.EXE)? (Y/N): ',0,FALSE) THEN
  BEGIN
    NL;
    Print('Enter commandline (example: "REZIP"): ');
    Prt(':');
    Input(ReZipCmd,78);
    IF (ReZipCmd = '') THEN
    BEGIN
      NL;
      Print('Aborted.');
      Exit;
    END;
  END;
  NL;
  Print('Conversion process initiated: '+DateStr+' '+TimeStr+'.');
  SysOpLog('Conversion process initiated: '+DateStr+' '+TimeStr+'.');
  NL;
  Abort := FALSE;
  Next := FALSE;
  IF NOT PYNQ('Search all file areas? ',0,FALSE) THEN
    CvtFiles(FileArea,FileName,ReZipCmd,TotalsRecord.TotalFiles,TotalsRecord.TotalOldSize,TotalsRecord.TotalNewSize)
  ELSE
  BEGIN
    SaveFileArea := FileArea;
    FArea := 1;
    WHILE (FArea >= 1) AND (FArea <= NumFileAreas) AND (NOT Abort) AND (NOT HangUp) DO
    BEGIN
      CvtFiles(FArea,FileName,ReZipCmd,TotalsRecord.TotalFiles,TotalsRecord.TotalOldSize,TotalsRecord.TotalNewSize);
      WKey;
      Inc(FArea);
    END;
    FileArea := SaveFileArea;
    LoadFileArea(FileArea);
  END;
  NL;
  Print('Conversion process complete at '+DateStr+' '+TimeStr+'.');
  SysOpLog('Conversion process complete at '+DateStr+' '+TimeStr+'.');
  NL;
  Star('Total archives converted : '+IntToStr(TotalsRecord.TotalFiles));
  Star('Old total space took up  : '+ConvertBytes(TotalsRecord.TotalOldSize,FALSE));
  Star('New total space taken up : '+ConvertBytes(TotalsRecord.TotalNewSize,FALSE));

  IF ((TotalsRecord.TotalOldSize - TotalsRecord.TotalNewSize) > 0) THEN
    Star('Space saved              : '+ConvertBytes(TotalsRecord.TotalOldSize - TotalsRecord.TotalNewSize,FALSE))
  ELSE
    Star('Space wasted             : '+ConvertBytes(TotalsRecord.TotalNewSize - TotalsRecord.TotalOldSize,FALSE));


  SysOpLog('Converted '+IntToStr(TotalsRecord.TotalFiles)+' archives; old size='+
           ConvertBytes(TotalsRecord.TotalOldSize,FALSE)+' , new size='+ConvertBytes(TotalsRecord.TotalNewSize,FALSE));
END;

END.
