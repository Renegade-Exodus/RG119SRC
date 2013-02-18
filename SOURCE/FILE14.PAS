{$IFDEF WIN32}
{$I DEFINES.INC}
{$ENDIF}

{$A+,B-,D+,E-,F+,I-,L+,N-,O+,R-,S+,V-}

UNIT File14;

INTERFACE

USES
  Common;

FUNCTION IsGIFExt(CONST FileName: AStr): Boolean;
FUNCTION IsGIFDesc(CONST Description: AStr): Boolean;
FUNCTION GetGIFSpecs(CONST FileName: AStr; Description: AStr; Which: Byte): AStr;
PROCEDURE AddGIFSpecs;

IMPLEMENTATION

USES
  File0,
  File11;

FUNCTION IsGIFExt(CONST FileName: AStr): Boolean;
VAR
  TempFN: AStr;
BEGIN
  TempFN := AllCaps(SQOutSp(StripName(FileName)));
  IsGIFExt := (Copy(TempFN,(Length(TempFN) - 2),3) = 'GIF');
END;

FUNCTION IsGIFDesc(CONST Description: AStr): Boolean;
BEGIN
  IsGIFDesc := (Pos('< Bad GIF >',Description) <> 0) OR
               (Pos('< Missing GIF >',Description) <> 0) OR
               ((Description[1] = '(') AND (Pos('x',Description) IN [1..7]) AND (Pos('c)',Description) <> 0));
END;

FUNCTION GetGIFSpecs(CONST FileName: AStr; Description: AStr; Which: Byte): AStr;
VAR
  F: FILE;
  Buf: ARRAY [1..11] OF Byte;
  Sig: AStr;
  X,
  Y,
  C,
  C1,
  Counter,
  NumRead: Word;
BEGIN
  FillChar(Buf,SizeOf(Buf),0);
  Sig := '';
  X := 0;
  Y := 0;
  C := 0;
  NumRead := 0;
  Assign(F,FileName);
  Reset(F,1);
  IF (IOResult <> 0) THEN
    Sig := '< Missing GIF >'
  ELSE
  BEGIN
    BlockRead(F,Buf,SizeOf(Buf),NumRead);
    Close(F);
    IF (NumRead <> 11) THEN
      Sig := '< Bad GIF >'
    ELSE IF (Buf[1] <> Ord('G')) OR (Buf[2] <> Ord('I')) OR (Buf[3] <> Ord('F')) THEN
      Sig := '< Missing GIF >';
  END;
  IF (Sig <> '< Bad GIF >') AND (Sig <> '< Missing GIF >') THEN
  BEGIN
    FOR Counter := 1 TO 6 DO
      Sig := Sig + Chr(Buf[Counter]);
    X := ((Buf[7] + Buf[8]) * 256);
    Y := ((Buf[9] + Buf[10]) * 256);
    C1 := ((Buf[11] AND 7) + 1);
    C := 1;
    FOR Counter := 1 TO C1 DO
      C := (C * 2);
  END;
  IF (Which = 1) THEN
    GetGIFSpecs := '^3'+Align(StripName(FileName))+
                   ' ^5'+PadLeftStr(IntToStr(X)+'x'+IntToStr(Y),11)+
                   ' '+PadLeftStr(IntToStr(C)+' colors',10)+
                   ' '+AOnOff((Sig = '< Missing GIF >') OR (Sig = '< Bad GIF >'),'^8'+Sig+'^1','^7'+Sig+'^1')
  ELSE IF (Which IN [2,3]) THEN
  BEGIN
    IF (Sig = '< Missing GIF >') THEN
      GetGifSpecs := Copy('^8< Missing GIF > ^9'+Description,1,50)
    ELSE IF (Sig = '< Bad GIF >') THEN
      GetGIFSpecs := Copy('^8< Bad GIF > ^9'+Description,1,50)
    ELSE
      GetGIFSPecs := Copy('('+IntToStr(X)+'x'+IntToStr(Y)+','+IntToStr(C)+'c) '+Description,1,50);
  END;
  IF (Sig = '< Missing GIF >') OR (Sig = '< Bad GIF >') THEN
    SysOpLog('^7Bad or missing GIF: "^5'+StripName(FileName)+'^7" in ^5'+MemFileArea.AreaName);
END;

PROCEDURE AddGIFSpecs;
VAR
  FArrayRecNum: Byte;
  FArea,
  SaveFileArea: Integer;
  TotalFiles: LongInt;

  PROCEDURE AddFileAreaGIFSpecs(FArea: Integer; VAR FArrayRecNum1: Byte; VAR TotalFiles1: LongInt);
  VAR
    DirFileRecNum: Integer;
    Found: Boolean;
  BEGIN
    IF (FileArea <> FArea) THEN
      ChangeFileArea(FArea);
    IF (FileArea = FArea) THEN
    BEGIN
      RecNo(FileInfo,'*.*',DirFileRecNum);
      IF (BadDownloadPath) THEN
        Exit;
      IF (FAUseGifSpecs IN MemFileArea.FAFlags) THEN
      BEGIN
        LIL := 0;
        CLS;
        Found := FALSE;
        Prompt('^1Scanning ^5'+MemFileArea.AreaName+' #'+IntToStr(CompFileArea(FArea,0))+'^1 ...');
        WHILE (DirFileRecNum <> -1) AND (NOT Abort) AND (NOT HangUp) DO
        BEGIN
          Seek(FileInfoFile,DirFileRecNum);
          Read(FileInfoFile,FileInfo);
          IF (IsGIFExt(FileInfo.FileName) AND (NOT IsGIFDesc(FileInfo.Description))) THEN
          BEGIN
            FileInfo.Description := GetGIFSpecs(MemFileArea.DLPath+SQOutSp(FileInfo.FileName),FileInfo.Description,3);
            WITH FArray[FArrayRecNum1] DO
            BEGIN
              FArrayFileArea := FileArea;
              FArrayDirFileRecNum := DirFileRecNum;
            END;
            lDisplay_File(FileInfo,FArrayRecNum1,'',FALSE);
            Inc(FArrayRecNum1);
            IF (FArrayRecNum1 = 100) THEN
              FArrayRecNum1 := 0;
            Seek(FileInfoFile,DirFileRecNum);
            Write(FileInfoFile,FileInfo);
            Inc(TotalFiles1);
            Found := TRUE;
          END;
          Wkey;
          NRecNo(FileInfo,DirFileRecNum);
        END;
        IF (NOT Found) THEN
        BEGIN
          LIL := 0;
          BackErase(15 + LennMCI(MemFileArea.AreaName) + Length(IntToStr(CompFileArea(FArea,0))));
        END;
      END;
      Close(FileInfoFile);
      Close(ExtInfoFile);
      LastError := IOResult;
    END;
  END;

BEGIN
  NL;
  Print('Adding GIF Resolution to file descriptions -');
  InitFArray(FArray);
  FArrayRecNum := 0;
  TotalFiles := 0;
  Abort := FALSE;
  Next := FALSE;
  NL;
  IF (NOT PYNQ('Search all file areas? ',0,FALSE)) THEN
    AddFileAreaGIFSpecs(FileArea,FArrayRecNum,TotalFiles)
  ELSE
  BEGIN
    SaveFileArea := FileArea;
    FArea := 1;
    WHILE (FArea >= 1) AND (FArea <= NumFileAreas) AND (NOT Abort) AND (NOT HangUp) DO
    BEGIN
      AddFileAreaGIFSpecs(FArea,FArrayRecNum,TotalFiles);
      WKey;
      Inc(FArea);
    END;
    FileArea := SaveFileArea;
    LoadFileArea(FileArea);
  END;
  NL;
  Print('Added GIF specifications to '+FormatNumber(TotalFiles)+' '+Plural('file',Totalfiles)+'.');
  SysOpLog('Added GIF specifications to '+FormatNumber(TotalFiles)+' '+Plural('file',Totalfiles)+'.');
END;

END.
