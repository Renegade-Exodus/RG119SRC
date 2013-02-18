{$IFDEF WIN32}
{$I DEFINES.INC}
{$ENDIF}

{$A+,B-,D+,E-,F+,I-,L+,N-,O+,R-,S+,V-}

UNIT File5;

INTERFACE

PROCEDURE MiniDOS;
PROCEDURE UploadAll;

IMPLEMENTATION

USES
  Dos,
  Common,
  Arcview,
  Archive1,
  ExecBat,
  File0,
  File1,
  File2,
  File8,
  File9,
  File11,
  MultNode,
  Sysop4;

PROCEDURE MiniDOS;
VAR
  XWord: ARRAY [1..9] OF AStr;
  (*
  DirInfo: SearchRec;
  *)
  CurDir,
  s,
  s1: AStr;
  Done,
  NoCmd,
  NoSpace,
  Junk,
  junk2,
  junk3,
  Found: Boolean;
  TransferTime: LongInt;

  PROCEDURE Parse(CONST s: AStr);
  VAR
    i,
    j,
    k: Integer;
  BEGIN
    FOR i := 1 TO 9 DO
      XWord[i] := '';
    i := 1;
    j := 1;
    k := 1;
    IF (Length(s) = 1) THEN
      XWord[1] := s;
    WHILE (i < Length(s)) DO
    BEGIN
      Inc(i);
      IF ((s[i] = ' ') OR (Length(s) = i)) THEN
      BEGIN
        IF (Length(s) = i) THEN
          Inc(i);
        XWord[k] := AllCaps(Copy(s,j,(i - j)));
        j := (i + 1);
        Inc(k);
      END;
    END;
  END;

  PROCEDURE VersionInfo;
  BEGIN
    NL;
    Print('Renegade''s internal DOS emulator.  Supported commands are limited.');
    NL;
    NL;
  END;

  FUNCTION DOSErrorMsg(ErrorNum: Byte): AStr;
  VAR
    S: AStr;
  BEGIN
    CASE ErrorNum OF
      1 : S := 'The snytax of the command is incorrect.';
    END;
    DOSErrorMsg := S;
  END;

  PROCEDURE DoCmd(CONST Cmd: AStr);
  VAR
    F: FILE;
    ps,
    ns,
    es,
    op,
    np,
    s1,
    s2,
    s3: AStr;
    NumFiles,
    TSiz: LongInt;
    i,
    j: Byte;
    RetLevel: Integer;
    b,
    Ok: Boolean;
  BEGIN
    Abort := FALSE;
    Next := FALSE;
    NoCmd := FALSE;
    s := XWord[1];
    IF (s = '?') OR (s = 'HELP') THEN
      PrintF('DOSHELP')
    ELSE IF (s = 'EDIT') THEN
    BEGIN
      IF ((Exist(XWord[2])) AND (XWord[2] <> '')) THEN
        TEdit(XWord[2])
      ELSE IF (XWord[2] = '') THEN
        TEdit1
      ELSE
        TEdit(XWord[2]);
    END
    ELSE IF (s = 'EXIT') THEN
      Done := TRUE
    ELSE IF (s = 'DEL') THEN
    BEGIN
      IF ((NOT Exist(XWord[2])) AND (NOT IsWildCard(XWord[2]))) OR (XWord[2] = '') THEN
        Print('File not found.')
      ELSE
      BEGIN
        XWord[2] := FExpand(XWord[2]);
        FindFirst(XWord[2],AnyFile - VolumeID - Directory,DirInfo);
        IF (NOT IsWildCard(XWord[2])) OR (PYNQ('Are you sure? ',0,FALSE)) THEN
        REPEAT
          Kill(DirInfo.Name);
          FindNext(DirInfo);
        UNTIL (DOSError <> 0) OR (HangUp);
      END;
    END
    ELSE IF (s = 'TYPE') THEN
    BEGIN
      PrintF(FExpand(XWord[2]));
      IF (NoFile) THEN
        Print('File not found.');
    END
    ELSE IF (Copy(s,1,3) = 'REN') THEN
    BEGIN
      IF ((NOT Exist(XWord[2])) AND (XWord[2] <> '')) THEN
        Print('File not found.')
      ELSE
      BEGIN
        XWord[2] := FExpand(XWord[2]);
        Assign(F,XWord[2]);
        ReName(F,XWord[3]);
        IF (IOResult <> 0) THEN
          Print('File not found.');
      END
    END
    ELSE IF (s = 'DIR') THEN
    BEGIN
      b := TRUE;
      FOR i := 2 TO 9 DO
        IF (XWord[i] = '/W') THEN
        BEGIN
          b := FALSE;
          XWord[i] := '';
        END;
      IF (XWord[2] = '') THEN
        XWord[2] := '*.*';
      s1 := CurDir;
      XWord[2] := FExpand(XWord[2]);
      FSplit(XWord[2],ps,ns,es);
      s1 := ps;
      s2 := ns + es;
      IF (s2[1] = '.') THEN
        s2 := '*' + s2;
      IF (s2 = '') THEN
        s2 := '*.*';
      IF (Pos('.', s2) = 0) THEN
        s2 := s2 + '.*';
      IF (NOT IsWildCard(XWord[2])) THEN
      BEGIN
        FindFirst(XWord[2],AnyFile,DirInfo);
        IF ((DOSError = 0) AND (DirInfo.Attr = Directory)) OR ((Length(s1) = 3) AND (s1[3] = '\')) THEN
        BEGIN
          s1 := BSlash(XWord[2],TRUE);
          s2 := '*.*';
        END;
      END;
      NL;
      DosDir(s1,s2,b);
      NL;
    END
    ELSE IF ((s = 'CD') OR (s = 'CHDIR')) AND (XWord[2] <> '') OR (Copy(s,1,3) = 'CD\') THEN
    BEGIN
      IF (Copy(s,1,3) = 'CD\') THEN
        XWord[2] := Copy(s,3,Length(s)-2);
      XWord[2] := FExpand(XWord[2]);
      ChDir(XWord[2]);
      IF (IOResult <> 0) THEN
        Print('Invalid pathname.');
    END
    (*  Done - Lee Palmer - 01/09/08 *)
    ELSE IF (s = 'MD') OR (s = 'MKDIR') THEN
    BEGIN
      IF (XWord[2] = '') THEN
        Print(DOSErrorMsg(1))
      ELSE
      BEGIN
        FindFirst(XWord[2],AnyFile,DirInfo);
        IF (DosError = 0) THEN
          Print('A subdirectory or file '+XWord[2]+' already exists.')
        ELSE
        BEGIN
          MkDir(XWord[2]);
          IF (IOResult <> 0) THEN
            Print('Access is denied.');
        END;
      END;

    END
    ELSE IF ((s = 'RD') OR (s = 'RMDIR')) THEN
    BEGIN
      (* Finish Me *)
      IF (XWord[2] = '') THEN
        Print(DOSErrorMsg(1))
      ELSE
      BEGIN
        FindFirst(XWord[2],AnyFile,DirInfo);
        IF (DosError <> 0) THEN
          Print('The system cannot find the file specified.')
        ELSE
        BEGIN
          Abort := FALSE;
          Found := FALSE;
          FindFirst(BSlash(XWord[2],TRUE)+'*.*',AnyFile,DirInfo);
          WHILE (DosError = 0) AND (NOT Abort) AND (NOT HangUp) DO
          BEGIN
            IF (DirInfo.Name <> '.') AND (DirInfo.Name <> '..') THEN
            BEGIN
              Abort := TRUE;
              Found := TRUE;
            END;
            FindNext(DirInfo);
          END;
          Abort := FALSE;
          IF (Found) THEN
            Print('The directory is not empty.')
          ELSE
          BEGIN
            RmDir(XWord[2]);
            IF (IOResult <> 0) THEN
              Print('Access is denied.');
          END;
        END;
      END;

    END
    ELSE IF (s = 'COPY') THEN
    BEGIN
      IF (XWord[2] <> '') THEN
      BEGIN
        IF (IsWildCard(XWord[3])) THEN
          Print('Wildcards not allowed in destination parameter!')
        ELSE
        BEGIN
          IF (XWord[3] = '') THEN
            XWord[3] := CurDir;
          XWord[2] := BSlash(FExpand(XWord[2]),FALSE);
          XWord[3] := FExpand(XWord[3]);
          FindFirst(XWord[3],AnyFile,DirInfo);
          b := ((DOSError = 0) AND (DirInfo.Attr AND Directory = Directory));
          IF ((NOT b) AND (Copy(XWord[3],2,2) = ':\') AND (Length(XWord[3]) = 3)) THEN
            b := TRUE;
          FSplit(XWord[2],op,ns,es);
          op := BSlash(OP,TRUE);
          IF (b) THEN
            np := BSlash(XWord[3],TRUE)
          ELSE
          BEGIN
            FSplit(XWord[3],np,ns,es);
            np := BSlash(np,TRUE);
          END;

          j := 0;
          Abort := FALSE;
          Next := FALSE;
          FindFirst(XWord[2],AnyFile - Directory - VolumeID,DirInfo);
          WHILE (DOSError = 0) AND (NOT Abort) AND (NOT HangUp) DO
          BEGIN
            s1 := op + DirInfo.Name;
            IF (b) THEN
              s2 := np + DirInfo.Name
            ELSE
              s2 := np + ns + es;

            IF CopyMoveFile(TRUE,s1+' -> '+s2+' :',s1,s2,TRUE) THEN
            BEGIN
              Inc(j);
              NL;
            END;

            NL;
            IF (NOT Empty) THEN
              WKey;
            FindNext(DirInfo);
          END;
          Print('  '+IntToStr(j)+' file(s) copied.');
        END;
      END;
    END
    ELSE IF (s = 'MOVE') THEN
    BEGIN
      IF (XWord[2] <> '') THEN
      BEGIN
        IF (IsWildCard(XWord[3])) THEN
          Print('Wildcards not allowed in destination parameter!')
        ELSE
        BEGIN
          IF (XWord[3] = '') THEN
            XWord[3] := CurDir;
          XWord[2] := BSlash(FExpand(XWord[2]),FALSE);
          XWord[3] := FExpand(XWord[3]);
          FindFirst(XWord[3],AnyFile,DirInfo);
          b := ((DOSError = 0) AND (DirInfo.Attr AND Directory = Directory));
          IF ((NOT b) AND (Copy(XWord[3],2,2) = ':\') AND (Length(XWord[3]) = 3)) THEN
            b := TRUE;
          FSplit(XWord[2],op,ns,es);
          op := BSlash(op,TRUE);
          IF (b) THEN
            np := BSlash(XWord[3],TRUE)
          ELSE
          BEGIN
            FSplit(XWord[3],np,ns,es);
            np := BSlash(np,TRUE);
          END;
          j := 0;
          Abort := FALSE;
          Next := FALSE;
          FindFirst(XWord[2],AnyFile - Directory - VolumeID,DirInfo);
          WHILE (DOSError = 0) AND (NOT Abort) AND (NOT HangUp) DO
          BEGIN
            s1 := op + DirInfo.Name;
            IF (b) THEN
              s2 := np + DirInfo.Name
            ELSE
              s2 := np + ns + es;
            CopyMoveFile(FALSE,s1+' -> '+s2+' :',s1,s2,TRUE);
            BEGIN
              Inc(j);
              NL;
            END;
            IF (NOT Empty) THEN
              WKey;
            FindNext(DirInfo);
          END;
          Print('  '+IntToStr(j)+' file(s) moved.');
        END;
      END;
    END
    ELSE IF (s = 'CLS') THEN
      CLS
    ELSE IF (Length(s) = 2) AND (s[1] >= 'A') AND (s[1] <= 'Z') AND (s[2] = ':') THEN
    BEGIN
      GetDir(Ord(s[1]) - 64,s1);
      IF (IOResult <> 0) THEN
        Print('Invalid drive.')
      ELSE
      BEGIN
        ChDir(s1);
        IF (IOResult <> 0) THEN
        BEGIN
          Print('Invalid drive.');
          ChDir(CurDir);
        END;
      END;
    END
    ELSE IF (s = 'VIEW') THEN
    BEGIN
      IF (XWord[2] = '') THEN
        Print('Syntax is: "VIEW filename"')
      ELSE
      BEGIN
        s1 := XWord[2];
        IF (Pos('.',s1) = 0) THEN
          s1 := s1 + '*.*';
        ViewInternalArchive(s1);
      END;
    END
    ELSE IF (s = 'SEND') AND (XWord[2] <> '') THEN
    BEGIN
      IF Exist(XWord[2]) THEN
        UnlistedDownload(FExpand(XWord[2]))
      ELSE
        Print('File not found.');
    END
    ELSE IF (s = 'RECEIVE') THEN
    BEGIN
      Prt('File Name: ');
      MPL(12);
      Input(s,12);
      s := StripName(s);
      Receive(s,'',FALSE,Junk,junk2,junk3,TransferTime);
      IF (Junk) THEN
        SysOpLog('DOS emulator upload of: '+s);
    END
    ELSE IF (s = 'VER') THEN
      VersionInfo
    ELSE IF (s = 'DIRSIZE') THEN
    BEGIN
      NL;
      IF (XWord[2] = '') THEN
        Print('Needs a parameter.')
      ELSE
      BEGIN
        NumFiles := 0;
        TSiz := 0;
        FindFirst(XWord[2],AnyFile,DirInfo);
        WHILE (DOSError = 0) DO
        BEGIN
          Inc(TSiz,DirInfo.Size);
          Inc(NumFiles);
          FindNext(DirInfo);
        END;
        IF (NumFiles = 0) THEN
          Print('No files found!')
        ELSE
          Print('"'+AllCaps(XWord[2])+'": '+IntToStr(NumFiles)+' files, '+ConvertBytes(TSiz,FALSE));
      END;
      NL;
    END
    ELSE IF (s = 'DISKFREE') THEN
    BEGIN
      IF (XWord[2] = '') THEN
        j := ExtractDriveNumber(CurDir)
      ELSE
        j := ExtractDriveNumber(XWord[2]);
      IF (DiskFree(j) = -1) THEN
        Print('Invalid drive specification'^M^J)
      ELSE
        Print(^M^J + ConvertBytes(DiskFree(j),FALSE)+' free on '+Chr(j + 64)+':'^M^J);
    END
    ELSE IF (s = 'EXT') THEN
    BEGIN
      s1 := Cmd;
      j := Pos('EXT',AllCaps(s1)) + 3;
      s1 := Copy(s1,j,Length(s1) - (j - 1));
      WHILE (s1[1] = ' ') AND (Length(s1) > 0) DO
        Delete(s1,1,1);
      IF (s1 <> '') THEN
      BEGIN
        Shel('Running "'+s1+'"');
        ShellDOS(FALSE,s1,RetLevel);
        Shel2(FALSE);
      END;
    END
    ELSE IF (s = 'CONVERT') OR (s = 'CVT') THEN
    BEGIN
      IF (XWord[2] = '') THEN
      BEGIN
        NL;
        Print(s+' - Renegade archive conversion command.');
        NL;
        Print('Syntax is:   "'+s+' <Old Archive-name> <New Archive-extension>"');
        NL;
        Print('Renegade will convert from the one archive format to the other.');
        Print('You only need to specify the 3-letter extension of the new format.');
        NL;
      END
      ELSE
      BEGIN
        IF (NOT Exist(XWord[2])) OR (XWord[2] = '') THEN
          Print('File not found.')
        ELSE
        BEGIN
          i := ArcType(XWord[2]);
          IF (i = 0) THEN
            InvArc
          ELSE
          BEGIN
            s3 := XWord[3];
            s3 := Copy(s3,(Length(s3) - 2),3);
            j := ArcType('FILENAME.'+s3);
            FSplit(XWord[2],ps,ns,es);
            IF (Length(XWord[3]) <= 3) AND (j <> 0) THEN
              s3 := ps+ns+'.'+General.FileArcInfo[j].ext
            ELSE
              s3 := XWord[3];
            IF (j = 0) THEN
              InvArc
            ELSE
            BEGIN
              Ok := TRUE;
              ConvA(Ok,i,j,SQOutSp(FExpand(XWord[2])),SQOutSp(FExpand(s3)));
              IF (Ok) THEN
                Kill(SQOutSp(FExpand(XWord[2])))
              ELSE
                Star('Conversion unsuccessful.');
            END;
          END;
        END;
      END;
    END ELSE IF (s = 'UNARC') OR (s = 'UNZIP') THEN
    BEGIN
      IF (XWord[2] = '') THEN
      BEGIN
        NL;
        Print(s+' - Renegade archive de-compression command.');
        NL;
        Print('Syntax: '+s+' <ARCHIVE> [FILESPECS]');
        NL;
        Print('The archive type can be any archive format which has been');
        Print('configured into Renegade via System Configuration.');
        NL;
      END
      ELSE
      BEGIN
        i := ArcType(XWord[2]);
        IF (NOT Exist(XWord[2])) THEN
          Print('File not found.')
        ELSE IF (i = 0) THEN
          InvArc
        ELSE
        BEGIN
          s3 := '';
          IF (XWord[3] = '') THEN
            s3 := ' *.*'
          ELSE FOR j := 3 TO 9 DO
            IF (XWord[j] <> '') THEN
              s3 := s3 + ' '+XWord[j];
          s3 := Copy(s3,2,Length(s3)-1);
          ExecBatch(Junk,BSlash(CurDir,TRUE),General.ArcsPath+
          FunctionalMCI(General.FileArcInfo[i].UnArcLine,XWord[2],s3),
                        0,
                        RetLevel,
                        FALSE);
        END;
      END;
    END
    ELSE IF ((s = 'ARC') OR (s = 'ZIP') OR (s = 'PKARC') OR (s = 'PKPAK') OR (s = 'PKZIP')) THEN
    BEGIN
      IF (XWord[2] = '') THEN
      BEGIN
        NL;
        Print(s+' - Renegade archive compression command.');
        NL;
        Print('Syntax is:   "'+s+' <Archive-name> Archive filespecs..."');
        NL;
        Print('The archive type can be ANY archive format which has been');
        Print('configured into Renegade via System Configuration.');
        NL;
      END
      ELSE
      BEGIN
        i := ArcType(XWord[2]);
        IF (i = 0) THEN
          InvArc
        ELSE
        BEGIN
          s3 := '';
          IF (XWord[3] = '') THEN
            s3 := ' *.*'
          ELSE FOR j := 3 TO 9 DO
            IF (XWord[j] <> '') THEN
              s3 := s3 + ' '+FExpand(XWord[j]);
          s3 := Copy(s3,2,(Length(s3) - 1));
          ExecBatch(Junk,
                    BSlash(CurDir,TRUE),
                    General.ArcsPath+FunctionalMCI(General.FileArcInfo[i].ArcLine,FExpand(XWord[2]),s3),
                    0,
                    RetLevel,
                    FALSE);
        END;
      END;
    END
    ELSE
    BEGIN
      NoCmd := TRUE;
      IF (s <> '') THEN
        Print('Bad command or file name.')
    END;
  END;

BEGIN
  Done := FALSE;
  NL;
  Print('Type "EXIT" to return to Renegade');
  NL;
  VersionInfo;
  REPEAT
    GetDir(0,CurDir);
    Prompt('^1'+CurDir+'>');
    InputL(s1,128);
    Parse(s1);
    Check_Status;
    DoCmd(s1);
    IF (NOT NoCmd) THEN
      SysOpLog('> '+s1);
  UNTIL (Done) OR (HangUp);
  ChDir(StartDir);
END;

PROCEDURE UploadAll;
VAR
  FileName: Str12;
  FArrayRecNum: Byte;
  FArea,
  SaveFileArea: Integer;
  SearchAllFileAreas: Boolean;

  PROCEDURE UploadFiles(FArea: Integer; FileName1: Str12; VAR FArrayRecNum1: Byte);
  VAR
    (*
    DirInfo: SearchRec;
    *)
    Cmd: Char;
    NumExtDesc: Byte;
    DirFileRecNum,
    GotPts,
    Counter: Integer;
    FSize: LongInt;
    FlagAll,
    Ok,
    FirstOne,
    GotDesc,
    Found: Boolean;
  BEGIN
    FirstOne := TRUE;
    FlagAll := FALSE;

    IF (FileArea <> FArea) THEN
      ChangeFileArea(FArea);
    IF (FileArea = FArea) THEN
    BEGIN
      LoadFileArea(FileArea);

      LIL := 0;
      CLS;
      Found := FALSE;
      Prompt('^1Scanning ^5'+MemFileArea.AreaName+' #'+IntToStr(CompFileArea(FArea,0))+'^1 ...');

      FindFirst(MemFileArea.DLPath+FileName1,AnyFile - VolumeID - Directory - DOS.Hidden,DirInfo);
      WHILE (DOSError = 0) AND (NOT Abort) AND (NOT HangUp) DO
      BEGIN
        DirInfo.Name := Align(DirInfo.Name);
        RecNo(FileInfo,DirInfo.Name,DirFileRecNum);
        IF (BadDownloadPath) THEN
          Exit;

        IF (DirFileRecNum = -1) THEN
        BEGIN

          FSize := GetFileSize(MemFileArea.DLPath+DirInfo.Name);
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

          UpdateFileInfo(FileInfo,DirInfo.Name,GotPts);

          IF (FirstOne) THEN
          BEGIN
            DisplayFileAreaHeader;
            FirstOne := FALSE;
          END;

          GotDesc := FALSE;

          IF (General.FileDiz) AND (DizExists(MemFileArea.DLPath+DirInfo.Name)) THEN
          BEGIN
            GetDiz(FileInfo,ExtendedArray,NumExtDesc);
            Star('Complete.');
            Prompt(' ^9'+PadRightInt(FArrayRecNum1,2)+' ^5'+DirInfo.Name+' ^4'+GetFileStats(FileInfo)+' ');
            IF (FlagAll) THEN
              Ok := TRUE
            ELSE
            BEGIN
              Prt('Upload? (Yes,No,All,Quit): ');
              OneK(Cmd,'QYNA',TRUE,TRUE);
              Ok := (Cmd = 'Y') OR (Cmd = 'A');
              FlagAll := (Cmd = 'A');
              Abort := (Cmd = 'Q');
            END;
            GotDesc := TRUE;
          END
          ELSE
          BEGIN
            Prompt(' ^9'+PadRightInt(FArrayRecNum1,2)+' ^5'+DirInfo.Name+' ^4'+GetFileStats(FileInfo)+' ');
            MPL(50);
            InputL(FileInfo.Description,50);
            Ok := TRUE;
            IF (FileInfo.Description <> '') AND (FileInfo.Description[1] = '.') THEN
            BEGIN
              IF (Length(FileInfo.Description) = 1) THEN
              BEGIN
                Abort := TRUE;
                Exit;
              END;
              Cmd := UpCase(FileInfo.Description[2]);
              CASE Cmd OF
                'D' : BEGIN
                        Kill(MemFileArea.DLPath+DirInfo.Name);
                        Ok := FALSE;
                      END;
                'N' : BEGIN
                        Next := TRUE;
                        Exit;
                      END;
                'S' : Ok := FALSE;
              END;
            END;
          END;

          Inc(FArrayRecNum1);
          IF (FArrayRecNum1 = 100) THEN
            FArrayRecNum1 := 0;

          IF (Ok) THEN
          BEGIN
            IF (NOT GotDesc) THEN
            BEGIN
              FillChar(ExtendedArray,SizeOf(ExtendedArray),0);
              Counter := 0;
              REPEAT
                Inc(Counter);
                Prt(PadLeftStr('',28));
                MPL(50);
                InputL(ExtendedArray[Counter],50);
                IF (ExtendedArray[Counter] = '') THEN
                  Counter := MaxExtDesc;
              UNTIL (Counter = MaxExtDesc) OR (HangUp);
              NL;
            END;
            WriteFV(FileInfo,FileSize(FileInfoFile),ExtendedArray);
            SysOpLog('^3Uploaded "^5'+SQOutSp(DirInfo.Name)+'^3" to ^5'+MemFileArea.AreaName);
            Found := TRUE;
          END;
        END;
        Close(FileInfoFile);
        Close(ExtInfoFile);
        WKey;
        FindNext(DirInfo);
      END;
      IF (NOT Found) THEN
      BEGIN
        LIL := 0;
        BackErase(15 + LennMCI(MemFileArea.AreaName) + Length(IntToStr(CompFileArea(FArea,0))));
      END;
    END;
  END;

BEGIN
  NL;
  Print('Upload files into file areas -');
  NL;
  SearchAllFileAreas := PYNQ('Search all file areas? ',0,FALSE);
  NL;
  IF NOT PYNQ('Search by file spec? ',0,FALSE) THEN
    FileName := '*.*'
  ELSE
  BEGIN
    NL;
    Prompt('File name (^5<CR>^1=^5All^1): ');
    GetFileName(FileName);
  END;
  NL;
  Print('^1Enter . to end processing, .S to skip the file, .N to skip to');
  Print('^1the next directory, and .D to delete the file.');
  NL;
  PauseScr(FALSE);
  InitFArray(FArray);
  FArrayRecNum := 0;
  Abort := FALSE;
  Next := FALSE;
  IF (NOT SearchAllFileAreas) THEN
    UploadFiles(FileArea,FileName,FArrayRecNum)
  ELSE
  BEGIN
    SaveFileArea := FileArea;
    FArea := 1;
    WHILE (FArea >= 1) AND (FArea <= NumFileAreas) AND (NOT Abort) AND (NOT HangUp) DO
    BEGIN
      UploadFiles(FArea,FileName,FArrayRecNum);
      WKey;
      Inc(FArea);
    END;
    FileArea := SaveFileArea;
    LoadFileArea(FileArea);
  END;
END;

END.

