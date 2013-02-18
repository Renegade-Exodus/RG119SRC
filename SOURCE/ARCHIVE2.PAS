{$IFDEF WIN32}
{$I DEFINES.INC}
{$ENDIF}

{$A+,B-,D+,E-,F+,I-,L+,N-,O+,R-,S+,V-}

UNIT Archive2;

INTERFACE

PROCEDURE DOArcCommand(Cmd: Char);

IMPLEMENTATION

USES
  Dos,
  Archive1,
  Archive3,
  Arcview,
  Common,
  ExecBat,
  File0,
  File1,
  File9,
  File11,
  TimeFunc;

CONST
  MaxDOSChrLine = 127;

PROCEDURE DOArcCommand(Cmd: Char);
CONST
  MaxFiles = 100;
VAR
  FI: FILE OF Byte;
  FileListArray: ARRAY [1..MaxFiles] OF AStr;
  F: FileInfoRecordType;
  (*
  DirInfo: SearchRec;
  *)
  FileName,
  S,
  S1,
  S2,
  OS1: AStr;
  DS: DirStr;
  NS: NameStr;
  ES: ExtStr;
  AType,
  BB,
  NumExtDesc,
  NumFiles,
  RecNum,
  Counter: Byte;
  Junk,
  RN,
  FArea,
  SaveFileArea,
  C_Files: Integer;
  C_OldSiz,
  C_NewSiz,
  OldSiz,
  NewSiz: LongInt;
  Ok,
  Ok1,
  FNX,
  WentToSysOp,
  DelBad: Boolean;

  PROCEDURE AddFL(F1: FileInfoRecordType; FN1: AStr; VAR NumFiles1: Byte; b: Boolean);
  VAR
    DirInfo1: SearchRec;
    DS1: DirStr;
    NS1: NameStr;
    ES1: ExtStr;
    SaveNumFiles: Byte;
    RN1: Integer;
  BEGIN
    SaveNumFiles := NumFiles1;
    IF (NOT b) THEN
    BEGIN
      RecNo(F1,FN1,RN1);
      IF (BadDownloadPath) THEN
        Exit;
      WHILE (RN1 <> -1) AND (NumFiles1 < MaxFiles) DO
      BEGIN
        Seek(FileInfoFile,RN1);
        Read(FileInfoFile,F1);
        Inc(NumFiles1);
        FileListArray[NumFiles1] := F1.FileName;
        NRecNo(F1,RN1);
      END;
    END
    ELSE
    BEGIN
      FSplit(FN1,DS1,NS1,ES1);
      ChDir(BSlash(DS1,FALSE));
      IF (IOResult <> 0) THEN
        Print('Path not found.')
      ELSE
      BEGIN
        FindFirst(FN1,AnyFile - Directory - VolumeID - Dos.Hidden - SysFile,DirInfo1);
        WHILE (DOSError = 0) AND (NumFiles1 < MaxFiles) DO
        BEGIN
          Inc(NumFiles1);
          FileListArray[NumFiles1] := FExpand(DS1+DirInfo1.Name);
          FindNext(DirInfo1);
        END;
      END;
      ChDir(StartDir);
    END;
    IF (NumFiles1 = SaveNumFiles) THEN
      Print('No matching files.')
    ELSE IF (NumFiles1 >= MaxFiles) THEN
      Print('File records filled.');
  END;

  PROCEDURE TestFiles(F1: FileInfoRecordType; FArea1: Integer; FN1: AStr; DelBad1: Boolean);
  VAR
    AType1: Byte;
    RN1: Integer;
    Ok2: Boolean;
  BEGIN
    IF (FileArea <> FArea1) THEN
      ChangeFileArea(FArea1);
    IF (FileArea = FArea1) THEN
    BEGIN
      RecNo(F1,FN1,RN1);
      IF (BadDownloadPath) THEN
        Exit;
      WHILE (RN1 <> -1) AND (NOT Abort) AND (NOT HangUp) DO
      BEGIN
        Seek(FileInfoFile,RN1);
        Read(FileInfoFile,F1);
        IF Exist(MemFileArea.DLPath+F1.FileName) THEN
          FN1 := MemFileArea.DLPath+F1.FileName
        ELSE
          FN1 := MemFileArea.ULPath+F1.FileName;
        AType1 := ArcType(FN1);
        IF (AType1 <> 0) THEN
        BEGIN
          DisplayFileAreaHeader;
          Star('Testing "'+SQOutSP(FN1)+'"');
          IF (NOT Exist(FN1)) THEN
            Star('File "'+SQOutSP(FN1)+'" does not exist.')
          ELSE
          BEGIN
            Ok2 := TRUE;
            ArcIntegrityTest(Ok2,AType1,SQOutSP(FN1));
            IF (NOT Ok2) THEN
            BEGIN
              Star('File "'+SQOutSP(FN1)+'" did not pass integrity test.');
              IF (DelBad1) THEN
              BEGIN
                DeleteFF(F1,RN1);
                Kill(FN1);
              END;
            END;
          END;
        END;
        WKey;
        NRecNo(F1,RN1);
      END;
      Close(FileInfoFile);
      Close(ExtInfoFile);
    END;
    LastError := IOResult;
  END;

  PROCEDURE CmtFiles(F1: FileInfoRecordType; FArea1: Integer; FN1: AStr);
  VAR
    AType1: Byte;
    RN1: Integer;
    Ok2: Boolean;
  BEGIN
    IF (FileArea <> FArea1) THEN
      ChangeFileArea(FArea1);
    IF (FileArea = FArea1) THEN
    BEGIN
      RecNo(F1,FN1,RN1);
      IF (BadDownloadPath) THEN
        Exit;
      WHILE (RN1 <> -1) AND (NOT Abort) AND (NOT HangUp) DO
      BEGIN
        Seek(FileInfoFile,RN1);
        Read(FileInfoFile,F1);
        IF Exist(MemFileArea.DLPath+F1.FileName) THEN
          FN1 := MemFileArea.DLPath+F1.FileName
        ELSE
          FN1 := MemFileArea.ULPath+F1.FileName;
        AType1 := ArcType(FN1);
        IF (AType1 <> 0) THEN
        BEGIN
          DisplayFileAreaHeader;
          NL;
          Star('Commenting "'+SQOutSP(FN1)+'"');
          IF (NOT Exist(FN1)) THEN
            Star('File "'+SQOutSP(FN1)+'" does not exist.')
          ELSE
          BEGIN
            Ok2 := TRUE;
            ArcComment(Ok2,AType1,MemFileArea.CmtType,SQOutSP(FN1));
            (* If NOT Ok *)

          END;
        END;
        WKey;
        NRecNo(F1,RN1);
      END;
      Close(FileInfoFile);
      Close(ExtInfoFile);
    END;
    LastError := IOResult;
  END;

  PROCEDURE CvtFiles(F1: FileInfoRecordType;
                     FArea1: Integer;
                     FN1: AStr;
                     Toa: Integer;
                     VAR C_Files1: Integer;
                     VAR C_OldSiz1,
                     C_NewSiz1: LongInt);
  VAR
    FI: FILE OF Byte;
    S3: AStr;
    AType1: Byte;
    RN1: Integer;
    Ok2: Boolean;
  BEGIN
    IF (FileArea <> FArea1) THEN
      ChangeFileArea(FArea1);
    IF (FileArea = FArea1) THEN
    BEGIN
      RecNo(F1,FN1,RN1);
      IF (BadDownloadPath) THEN
        Exit;
      WHILE (RN1 <> -1) AND (NOT Abort) AND (NOT HangUp) DO
      BEGIN
        Seek(FileInfoFile,RN1);
        Read(FileInfoFile,F1);
        IF Exist(MemFileArea.DLPath+F1.FileName) THEN
          FN1 := MemFileArea.DLPath+F1.FileName
        ELSE
          FN1 := MemFileArea.ULPath+F1.FileName;
        AType1 := ArcType(FN1);
        IF (AType1 <> 0) AND (AType1 <> Toa) THEN
        BEGIN
          DisplayFileAreaHeader;
          NL;
          Star('Converting "'+SQOutSP(FN1)+'"');
          Ok2 := FALSE;
          IF (NOT Exist(FN1)) THEN
          BEGIN
            Star('File "'+SQOutSP(FN1)+'" does not exist - changing extension.');
            S3 := Copy(FN1,1,Pos('.',FN1))+General.FileArcInfo[Toa].Ext;
            F1.FileName := Align(StripName(SQOutSP(S3)));
            Seek(FileInfoFile,RN1);
            Write(FileInfoFile,F1);
          END
          ELSE
          BEGIN
            Ok2 := TRUE;
            S3 := Copy(FN1,1,Pos('.',FN1))+General.FileArcInfo[Toa].Ext;
            ConvA(Ok2,AType1,BB,SQOutSP(FN1),SQOutSP(S3));
            IF (Ok2) THEN
            BEGIN

              Assign(FI,SQOutSP(FN1));
              Reset(FI);
              Ok2 := (IOResult = 0);
              IF (Ok2) THEN
              BEGIN
                OldSiz := FileSize(FI);
                Close(FI);
              END
              ELSE
                Star('Unable to access "'+SQOutSP(FN1)+'"');

              IF (Ok2) THEN
                IF (NOT Exist(SQOutSP(S3))) THEN
                BEGIN
                  Star('Unable to access "'+SQOutSP(S3)+'"');
                  SysOpLog('Unable to access '+SQOutSP(S3));
                  Ok2 := FALSE;
                END;
            END;

            IF (Ok2) THEN
            BEGIN
              F1.FileName := Align(StripName(SQOutSP(S3)));
              Seek(FileInfoFile,RN1);
              Write(FileInfoFile,F1);

              Kill(SQOutSP(FN1));

              Assign(FI,SQOutSP(S3));
              Reset(FI);
              Ok2 := (IOResult = 0);
              IF (NOT Ok2) THEN
              BEGIN
                Star('Unable to access '+SQOutSP(S3));
                SysOpLog('Unable to access '+SQOutSP(S3));
              END
              ELSE
              BEGIN
                NewSiz := FileSize(FI);
                F1.FileSize := NewSiz;
                Close(FI);
                Seek(FileInfoFile,RN1);
                Write(FileInfoFile,F1);
              END;

              IF (Ok2) THEN
              BEGIN
                Inc(C_OldSiz1,OldSiz);
                Inc(C_NewSiz1,NewSiz);
                Inc(C_Files1);
                Star('Old total space took up  : '+ConvertBytes(OldSiz,FALSE));
                Star('New total space taken up : '+ConvertBytes(NewSiz,FALSE));
                IF (OldSiz - NewSiz > 0) THEN
                  Star('Space saved              : '+ConvertBytes(OldSiz-NewSiz,FALSE))
                ELSE
                  Star('Space wasted             : '+ConvertBytes(NewSiz-OldSiz,FALSE));
              END;
            END
            ELSE
            BEGIN
              SysOpLog('Unable to convert '+SQOutSP(FN1));
              Star('Unable to convert '+SQOutSP(FN1));
            END;
          END;
        END;
        WKey;
        NRecNo(F,RN1);
      END;
      Close(FileInfoFile);
      Close(ExtInfoFile);
    END;
    LastError := IOResult;
  END;

BEGIN
  TempPause := FALSE;
  SaveFileArea := FileArea;
  InitFileArea(FileArea);
  IF (BadDownloadPath) THEN
    Exit;
  CASE Cmd OF
    'A' : BEGIN
            NL;
            Print('Add file(s) to archive (up to '+IntToStr(MaxFiles)+') -');
            NL;
            Print('Archive file name: ');
            Prt(':');
            MPL(78);
            Input(FileName,78);

            IF IsUL(FileName) AND (NOT FileSysOp) THEN
              FileName := '';

            IF (FileName = '') THEN
            BEGIN
              NL;
              Print('Aborted!');
            END
            ELSE
            BEGIN
              NumFiles := 0;
              IF (Pos('.',FileName) = 0) AND (MemFileArea.ArcType <> 0) THEN
                FileName := FileName+'.'+General.FileArcInfo[MemFileArea.ArcType].Ext;
              FNX := ISUL(FileName);
              IF (NOT FNX) THEN
              BEGIN
                IF Exist(MemFileArea.DLPath+FileName) THEN
                  FileName := MemFileArea.DLPath+FileName
                ELSE
                  FileName := MemFileArea.ULPath+FileName
              END;
              FileName := FExpand(FileName);
              AType := ArcType(FileName);
              IF (AType = 0) THEN
                InvArc
              ELSE
              BEGIN
                Cmd := 'A';
                REPEAT
                  IF (Cmd = 'A') THEN
                    REPEAT
                      NL;
                      Print('Add files to list - <CR> to end');
                      Prt(IntToStr(NumFiles + 1)+':');
                      MPL(70);
                      Input(S,70);
                      IF (S <> '') AND (NOT IsUL(S) OR FileSysOp) THEN
                      BEGIN
                        IF (Pos('.',S) = 0) THEN
                          S := S + '*.*';
                        AddFL(F,S,NumFiles,IsUL(S));
                      END;
                    UNTIL (S = '') OR (NumFiles >= MaxFiles) OR (HangUp);
                  NL;
                  Prt('Add files to list [^5?^4=^5Help^4]: ');
                  OneK(Cmd,'QADLR?',TRUE,TRUE);
                  NL;
                  CASE Cmd OF
                    '?' : BEGIN
                            LCmds(19,3,'Add more to list','Do it!');
                            LCmds(19,3,'List files in list','Remove files from list');
                            LCmds(19,3,'Quit','');
                          END;
                    'D' : BEGIN
                            RecNum := 0;
                            REPEAT
                              Inc(RecNum);
                              Counter := 1;
                              S2 := SQOutSP(FileListArray[RecNum]);
                              IF (NOT IsUL(S2)) THEN
                                S2 := MemFileArea.DLPath+S2;
                              S1 := FunctionalMCI(General.FileArcInfo[AType].ArcLine,FileName,S2);
                              OS1 := S1;
                              WHILE (Length(S1) <= MaxDOSChrLine) AND (RecNum < NumFiles) DO
                              BEGIN
                                Inc(RecNum);
                                Inc(Counter);
                                S2 := SQOutSP(FileListArray[RecNum]);
                                IF (NOT IsUL(S2)) THEN
                                  S2 := MemFileArea.DLPath+S2;
                                OS1 := S1;
                                S1 := S1+' '+S2;
                              END;
                              IF (Length(S1) > MaxDOSChrLine) THEN
                              BEGIN
                                Dec(RecNum);
                                Dec(Counter);
                                S1 := OS1;
                              END;
                              Ok := TRUE;
                              Star('Adding '+IntToStr(Counter)+' files to archive...');
                              ExecBatch(Ok,
                                        TempDir+'UP\',General.ArcsPath+S1,
                                        General.FileArcInfo[AType].SuccLevel,Junk,FALSE);
                              IF (NOT Ok) THEN
                              BEGIN
                                Star('errors in adding files');
                                Ok := PYNQ('Continue anyway? ',0,FALSE);
                                IF (HangUp) THEN
                                  Ok := FALSE;
                              END;
                            UNTIL (RecNum >= NumFiles) OR (NOT Ok);
                            ArcComment(Ok,AType,MemFileArea.CmtType,FileName);
                            NL;
                            IF (NOT FNX) THEN
                            BEGIN
                              S1 := StripName(FileName);
                              RecNo(F,S1,RN);
                              IF (BadDownloadPath) THEN
                                Exit;
                              IF (RN <> -1) THEN
                                Print('^5NOTE: File already exists in listing!');
                              IF PYNQ('Add archive to listing? ',0,FALSE) THEN
                              BEGIN

                                Assign(FI,FileName);
                                Reset(FI);
                                IF (IOResult = 0) THEN
                                BEGIN
                                  F.fileSize := FileSize(FI);
                                  Close(FI);
                                END;

                                F.FileName := Align(S1);
                                Ok1 := TRUE;
                                IF PYNQ('Replace a file in directory? ',0,FALSE) THEN
                                BEGIN
                                  REPEAT
                                    NL;
                                    Prt('Enter file name: ');
                                    MPL(12);
                                    Input(S2,12);
                                    IF (S2 = '') THEN
                                    BEGIN
                                      NL;
                                      Print('Aborted!');
                                    END
                                    ELSE
                                    BEGIN
                                      RecNo(F,S2,RN);
                                      IF (BadDownloadPath) THEN
                                        Exit;
                                      IF (RN = -1) THEN
                                        Print('File not found!');
                                    END;
                                  UNTIL (RN <> -1) OR (S2 = '') OR (HangUp);
                                  IF (S2 <> '') THEN
                                  BEGIN
                                    Seek(FileInfoFile,RN);
                                    Read(FileInfoFile,F);
                                    Kill(MemFileArea.ULPath+SQOutSP(F.FileName));
                                    F.FileName := Align(S1);
                                    Seek(FileInfoFile,RN);
                                    Write(FileInfoFile,F);
                                  END
                                  ELSE
                                    Ok1 := FALSE;
                                END
                                ELSE
                                  Ok1 := FALSE;
                                IF (NOT Ok1) THEN
                                BEGIN
                                  WentToSysOp := FALSE;
                                  GetFileDescription(F,ExtendedArray,NumExtDesc,WentToSysOp);
                                  F.FilePoints := 0;
                                  F.Downloaded := 0;
                                  F.OwnerNum := UserNum;
                                  F.OwnerName := AllCaps(ThisUser.Name);
                                  F.FileDate := Date2PD(DateStr);
                                  F.VPointer := -1;
                                  F.VTextSize := 0;
                                END;
                                F.FIFlags := [];

                                IF (NOT AACS(General.ULValReq)) AND (NOT General.ValidateAllFiles) THEN
                                  Include(F.FIFlags,FINotVal);

                                IF (NOT General.FileCreditRatio) THEN
                                  F.FilePoints := 0
                                ELSE
                                  F.FilePoints := ((F.FileSize DIV 1024) DIV General.FileCreditCompBaseSize);

                                IF (RN = -1) THEN
                                  WriteFV(F,FileSize(FileInfoFile),ExtendedArray)
                                ELSE
                                  WriteFV(F,RN,ExtendedArray);
                              END;
                            END;
                            IF PYNQ('Delete original files? ',0,FALSE) THEN
                              FOR RecNum := 1 TO NumFiles DO
                              BEGIN
                                S2 := SQOutSP(FileListArray[RecNum]);
                                IF (NOT IsUL(FileListArray[RecNum])) THEN
                                BEGIN
                                  RecNo(F,S2,RN);
                                  IF (BadDownloadPath) THEN
                                    Exit;
                                  IF (RN <> -1) THEN
                                    DeleteFF(F,RN);
                                  S2 := MemFileArea.DLPath+S2;
                                END;
                                Kill(S2);
                              END;
                            IF (Ok) THEN
                             Cmd := 'Q';
                          END;
                    'L' : IF (NumFiles = 0) THEN
                            Print('No files in list!')
                          ELSE
                          BEGIN
                            Abort := FALSE;
                            Next := FALSE;
                            S := '';
                            Counter := 0;
                            RecNum := 0;
                            REPEAT
                              Inc(RecNum);
                              IF IsUL(FileListArray[RecNum]) THEN
                                S := S + '^3'
                              ELSE
                                S := S + '^1';
                              S := S + Align(StripName(FileListArray[RecNum]));
                              Inc(Counter);
                              IF (Counter < 5) THEN
                                S := S + '    '
                              ELSE
                              BEGIN
                                PrintACR(S);
                                S := '';
                                Counter := 0;
                              END;
                            UNTIL (RecNum = NumFiles) OR (Abort) OR (HangUp);
                            IF (Counter in [1..4]) AND (NOT Abort) THEN
                              PrintACR(S);
                          END;
                    'R' : IF (NumFiles = 0) THEN
                            Print('No files in list!')
                          ELSE
                          BEGIN
                            Prt('Remove file name: ');
                            MPL(12);
                            Input(S,12);
                            IF (S = '') THEN
                            BEGIN
                              NL;
                              Print('Aborted!');
                            END
                            ELSE
                            BEGIN
                              RecNum := 0;
                              REPEAT
                                Inc(RecNum);
                                IF Align(StripName(FileListArray[RecNum])) = Align(S) THEN
                                BEGIN
                                  Prompt('^3'+SQOutSP(FileListArray[RecNum]));
                                  IF PYNQ('   Remove it? ',0,FALSE) THEN
                                  BEGIN
                                    FOR Counter := RecNum TO (NumFiles - 1) DO
                                      FileListArray[Counter] := FileListArray[Counter + 1];
                                    Dec(NumFiles);
                                    Dec(RecNum);
                                  END;
                                END;
                              UNTIL (RecNum >= NumFiles);
                            END;
                          END;
                  END;
                UNTIL (Cmd = 'Q') OR (HangUp);
                Cmd := #0;
              END;
            END;
          END;
    'C' : BEGIN
            NL;
            Print('Convert archive formats -');
            NL;
            Print('Filespec:');
            Prt(':');
            MPL(78);
            Input(FileName,78);
            IF (FileName = '') THEN
            BEGIN
              NL;
              Print('Aborted!');
            END
            ELSE
            BEGIN

              NL;
              REPEAT
                Prt('Archive type to use? (?=List): ');
                MPL(3);
                Input(S,3);
                IF (S = '?') THEN
                BEGIN
                  NL;
                  ListArcTypes;
                  NL;
                END;
              UNTIL (S <> '?');

              IF (StrToInt(S) <> 0) THEN
                BB := StrToInt(S)
              ELSE
                BB := ArcType('F.'+S);

              IF (BB <> 0) THEN
              BEGIN
                C_Files := 0;
                C_OldSiz := 0;
                C_NewSiz := 0;
                Abort := FALSE;
                Next := FALSE;
                SysOpLog('Conversion process initiated at '+DateStr+' '+TimeStr+'.');
                IF (IsUL(FileName)) THEN
                BEGIN
                  FSplit(FileName,DS,NS,ES);
                  FindFirst(FileName,AnyFile - Directory - VolumeID - Dos.Hidden - SysFile,DirInfo);
                  WHILE (DOSError = 0) AND (NOT Abort) AND (NOT HangUp) DO
                  BEGIN
                    FileName := FExpand(SQOutSP(DS+DirInfo.Name));
                    AType := ArcType(FileName);
                    IF (AType <> 0) AND (AType <> BB) THEN
                    BEGIN
                      Star('Converting "'+FileName+'"');
                      Ok := TRUE;
                      S := Copy(FileName,1,Pos('.',FileName))+General.FileArcInfo[BB].Ext;
                      ConvA(Ok,AType,BB,FileName,S);
                      IF (Ok) THEN
                      BEGIN

                        Assign(FI,SQOutSP(FileName));
                        Reset(FI);
                        Ok := (IOResult = 0);
                        IF (Ok) THEN
                        BEGIN
                          OldSiz := FileSize(FI);
                          Close(FI);
                        END
                        ELSE
                          Star('Unable to access '+SQOutSP(FileName));

                        IF (Ok) THEN
                          IF (NOT Exist(SQOutSP(S))) THEN
                          BEGIN
                            Star('Unable to access '+SQOutSP(S));
                            SysOpLog('Unable to access '+SQOutSP(S));
                            Ok := FALSE;
                          END;
                      END;
                      IF (Ok) THEN
                      BEGIN
                        Kill(SQOutSP(FileName));

                        Assign(FI,SQOutSP(S));
                        Reset(FI);
                        Ok := (IOResult = 0);
                        IF (Ok) THEN
                        BEGIN
                          NewSiz := FileSize(FI);
                          Close(FI);
                        END
                        ELSE
                          Star('Unable to access "'+SQOutSP(S)+'"');

                        IF (Ok) THEN
                        BEGIN
                          Inc(C_OldSiz,OldSiz);
                          Inc(C_NewSiz,NewSiz);
                          Inc(C_Files);
                          Star('Old total space took up  : '+ConvertBytes(OldSiz,FALSE));
                          Star('New total space taken up : '+ConvertBytes(NewSiz,FALSE));
                          IF (OldSiz - NewSiz > 0) THEN
                            Star('Space saved              : '+ConvertBytes(OldSiz-NewSiz,FALSE))
                          ELSE
                            Star('Space wasted             : '+ConvertBytes(NewSiz-OldSiz,FALSE));
                        END;
                      END
                      ELSE
                      BEGIN
                        SysOpLog('Unable to convert '+SQOutSP(FileName));
                        Star('Unable to convert '+SQOutSP(FileName));
                      END;
                    END;
                    WKey;
                    FindNext(DirInfo);
                  END;
                END
                ELSE
                BEGIN
                  NL;
                  IF (NOT PYNQ('Search all file areas? ',0,FALSE)) THEN
                    CvtFiles(F,FileArea,FileName,BB,C_Files,C_OldSiz,C_NewSiz)
                  ELSE
                  BEGIN
                    FArea := 1;
                    WHILE (FArea >= 1) AND (FArea <= NumFileAreas) AND (NOT Abort) AND (NOT HangUp) DO
                    BEGIN
                      CvtFiles(F,FArea,FileName,BB,C_Files,C_OldSiz,C_NewSiz);
                      WKey;
                      Inc(FArea);
                    END;
                  END;
                END;
                SysOpLog('Conversion process completed at '+DateStr+' '+TimeStr+'.');
                NL;
                Star('Total archives converted : '+IntToStr(C_Files));
                Star('Old total space took up  : '+ConvertBytes(C_OldSiz,FALSE));
                Star('New total space taken up : '+ConvertBytes(C_NewSiz,FALSE));
                IF ((C_OldSiz - C_NewSiz) > 0) THEN
                  Star('Space saved              : '+ConvertBytes((C_OldSiz - C_NewSiz),FALSE))
                ELSE
                  Star('Space wasted             : '+ConvertBytes((C_NewSiz - C_OldSiz),FALSE));
                SysOpLog('Converted '+IntToStr(C_Files)+' archives; old size='+
                         ConvertBytes(C_OldSiz,FALSE)+' , new size='+ConvertBytes(C_NewSiz,FALSE));
              END;
            END;
          END;
    'M' : BEGIN
            Ok := FALSE;
            FOR Counter := 1 TO 3 DO
              IF (General.FileArcComment[Counter] <> '') THEN
                Ok := TRUE;

            IF (NOT Ok) THEN
            BEGIN
              NL;
              Print('No comment''s are available.');
              PauseScr(FALSE);
              Exit;
            END;

            NL;
            Print('Comment field update -');
            NL;
            Print('Filespec:');
            Prt(':');
            MPL(78);
            Input(FileName,78);
            IF (FileName = '') THEN
            BEGIN
              NL;
              Print('Aborted!');
            END
            ELSE
            BEGIN
              Abort := FALSE;
              Next := FALSE;
              IF (IsUL(FileName)) THEN
              BEGIN

                S := '';
                NL;
                FOR Counter := 1 TO 3 DO
                  IF (General.FileArcComment[Counter] <> '') THEN
                  BEGIN
                    S := S + IntToStr(Counter);
                    Print('^1'+IntToStr(Counter)+'. Archive comment file: ^5'+General.FileArcComment[Counter]);
                  END;
                NL;
                Prt('Comment to use [0=Quit]: ');
                OneK(Cmd,'0'+S,TRUE,TRUE);

                IF (Cmd IN ['1'..'3']) THEN
                BEGIN
                  FSplit(FileName,DS,NS,ES);
                  FindFirst(FileName,AnyFile - Directory - VolumeID - Dos.Hidden - SysFile,DirInfo);
                  WHILE (DOSError = 0) AND (NOT Abort) AND (NOT HangUp) DO
                  BEGIN
                    FileName := FExpand(SQOutSP(DS+DirInfo.Name));
                    AType := ArcType(FileName);
                    IF (AType <> 0) THEN
                    BEGIN
                      Star('Commenting "'+FileName+'"');
                      Ok := TRUE;
                      ArcComment(Ok,AType,(Ord(Cmd) - 48),FileName);
                    END;
                    WKey;
                    FindNext(DirInfo);
                  END;
                END;
              END
              ELSE
              BEGIN
                NL;
                IF (NOT PYNQ('Search all file areas? ',0,FALSE)) THEN
                  CmtFiles(F,FileArea,FileName)
                ELSE
                BEGIN
                  FArea := 1;
                  WHILE (FArea >= 1) AND (FArea <= NumFileAreas) AND (NOT Abort) AND (NOT HangUp) DO
                  BEGIN
                    CmtFiles(F,FArea,FileName);
                    WKey;
                    Inc(FArea);
                  END;
                END;
              END;
            END;
            Cmd := #0;
          END;
    'T' : BEGIN
            NL;
            Print('File integrity testing -');
            NL;
            Print('Filespec:');
            Prt(':');
            MPL(78);
            Input(FileName,78);
            IF (FileName = '') THEN
            BEGIN
              NL;
              Print('Aborted!');
            END
            ELSE
            BEGIN
              NL;
              DelBad := PYNQ('Delete files that don''t pass the test? ',0,FALSE);
              NL;
              Abort := FALSE;
              Next := FALSE;
              IF (IsUL(FileName)) THEN
              BEGIN
                FSplit(FileName,DS,NS,ES);
                FindFirst(FileName,AnyFile - Directory - VolumeID - DOS.Hidden - SysFile,DirInfo);
                WHILE (DOSError = 0) AND (NOT Abort) AND (NOT HangUp) DO
                BEGIN
                  FileName := FExpand(SQOutSP(DS+DirInfo.Name));
                  AType := ArcType(FileName);
                  IF (AType <> 0) THEN
                  BEGIN
                    Star('Testing "'+FileName+'"');
                    Ok := TRUE;
                    ArcIntegrityTest(Ok,AType,FileName);
                    IF (Ok) THEN
                      Star('Passed integrity test.')
                    ELSE
                    BEGIN
                      Star('File "'+FileName+'" didn''t pass integrity test.');
                      IF (DelBad) THEN
                        Kill(FileName);
                    END;
                  END;
                  WKey;
                  FindNext(DirInfo);
                END;
              END
              ELSE
              BEGIN
                NL;
                IF (NOT PYNQ('Search all file areas? ',0,FALSE)) THEN
                  TestFiles(F,FileArea,FileName,DelBad)
                ELSE
                BEGIN
                  FArea := 1;
                  WHILE (FArea >= 1) AND (FArea <= NumFileAreas) AND (NOT Abort) AND (NOT HangUp) DO
                  BEGIN
                    TestFiles(F,FArea,FileName,DelBad);
                    WKey;
                    Inc(FArea);
                  END;
                END;
              END;
            END;
          END;
  END;
  FileArea := SaveFileArea;
  LoadFileArea(FileArea);
  LastError := IOResult;
END;

END.
