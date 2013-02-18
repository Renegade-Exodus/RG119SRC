{$IFDEF WIN32}
{$I DEFINES.INC}
{$ENDIF}

{$A+,B-,D-,E-,F+,I-,L-,N-,O+,R-,S+,V-}

UNIT BBSList;

INTERFACE

PROCEDURE BBSList_Add;
PROCEDURE BBSList_Delete;
PROCEDURE BBSList_Edit;
PROCEDURE BBSList_View;
PROCEDURE BBSList_xView;

IMPLEMENTATION

USES
  Common,
  TimeFunc;

FUNCTION BBSListMCI(CONST S: ASTR; Data1,Data2: Pointer): STRING;
VAR
  BBSListPtr: ^BBSListRecordType;
  User: UserRecordType;
BEGIN
  BBSListPtr := Data1;
  BBSListMCI := S;
  CASE S[1] OF
    'X' : CASE S[2] OF
            'A' : BBSListMCI := BBSListPtr^.xA;
            'B' : BBSListMCI := BBSListPtr^.xB;
            'C' : BBSListMCI := BBSListPtr^.xC;
            'D' : BBSListMCI := BBSListPtr^.xD;
            'E' : BBSListMCI := BBSListPtr^.xE;
            'F' : BBSListMCI := BBSListPtr^.xF;
          END;
    'B' : CASE S[2] OF
            'N' : BBSListMCI := BBSListPtr^.BBSName;
          END;
    'D' : CASE S[2] OF
            'A' : BBSListMCI := Pd2Date(BBSListPtr^.DateAdded);
            'E' : BBSListMCI := Pd2Date(BBSListPtr^.DateEdited);
            'S' : BBSListMCI := BBSListPtr^.Description;
            '2' : BBSListMCI := BBSListPtr^.Description2
          END;
    'P' : CASE S[2] OF
            'N' : BBSListMCI := BBSListPtr^.PhoneNumber;
          END;
    'R' : CASE S[2] OF
            'N' : BBSListMCI := IntToStr(BBSListPtr^.RecordNum);
          END;
    'S' : CASE S[2] OF
            'N' : BBSListMCI := BBSListPtr^.SysOpName;
            'P' : BBSListMCI := BBSListPtr^.Speed;
            'W' : BBSListMCI := AllCaps(BBSListPtr^.Software);
          END;
    'T' : CASE S[2] OF
            'N' : BBSListMCI := BBSListPtr^.TelnetUrl;
          END;
    'U' : CASE S[2] OF
            'N' : BEGIN
                    LoadURec(User,BBSListPtr^.UserID);
                    BBSListMCI := User.Name;
                  END;
          END;
    'W' : CASE S[2] OF
            'S' : BBSListMCI := BBSListPtr^.WebSiteUrl;
          END;
  END;
END;

PROCEDURE BBSListScriptFile(VAR BBSList: BBSListRecordType);
VAR
  BBSScriptText: TEXT;
  Question: STRING;
  WhichOne: CHAR;
BEGIN
  Assign(BBSScriptText,General.MiscPath+'BBSLIST.SCR');
  Reset(BBSScriptText);
  WHILE NOT EOF(BBSScriptText) AND (NOT Abort) AND (NOT HangUp) DO
  BEGIN
    ReadLn(BBSScriptText,Question);
    IF (Question[1] = '[') THEN
    BEGIN
      WhichOne := UpCase(Question[2]);
      Question := Copy(Question,(Pos(':',Question) + 1),Length(Question));
      CASE WhichOne OF
        '1' : BEGIN
                NL;
                PRT(Question+' ');
                MPL(SizeOf(BBSList.BBSName) - 1);
                InputMain(BBSList.BBSName,(SizeOf(BBSList.BBSName) - 1),[InterActiveEdit,ColorsAllowed]);
                Abort := (BBSList.BBSName = '');
              END;
        '2' : BEGIN
                PRT(Question+' ');
                MPL(SizeOf(BBSList.SysOpName) - 1);
                InputMain(BBSList.SysOpName,(SizeOf(BBSList.SysOpName) - 1),[ColorsAllowed,InterActiveEdit]);
                Abort := (BBSList.SysOpName = '');
              END;
        '3' : BEGIN
                PrintACR(Question);
                MPL(SizeOf(BBSList.TelnetUrl) - 1);
                InputMain(BBSList.TelnetUrl,(SizeOf(BBSList.TelnetUrl) - 1),[ColorsAllowed,InterActiveEdit]);
                Abort := (BBSList.TelnetUrl = '');
              END;
        '4' : BEGIN
                PrintACR(Question);
                MPL(SizeOf(BBSList.WebSiteUrl) - 1);
                InputMain(BBSList.WebSiteUrl,(SizeOf(BBSList.WebSiteUrl) - 1),[ColorsAllowed,InterActiveEdit]);
                Abort := (BBSList.WebSiteUrl = '');
              END;
        '5' : BEGIN
                PRT(Question+' ');
                MPL(SizeOf(BBSList.PhoneNumber) - 1);
                InputMain(BBSList.PhoneNumber,(SizeOf(BBSList.PhoneNumber) - 1),[ColorsAllowed,InterActiveEdit]);
                Abort := (BBSList.PhoneNumber = '');
              END;
        '6' : BEGIN
                PRT(Question+' ');
                MPL(SizeOf(BBSList.Software) - 1);
                InputMain(BBSList.Software,(SizeOf(BBSList.Software) - 1),[ColorsAllowed,InterActiveEdit,UpperOnly]);
                Abort := (BBSList.Software = '');
              END;
        '7' : BEGIN
                PRT(Question+' ');
                MPL(SizeOf(BBSList.Speed) - 1);
                InputMain(BBSList.Speed,(SizeOf(BBSList.Speed) - 1),[ColorsAllowed,InterActiveEdit]);
                Abort := (BBSList.Speed = '');
              END;
        '8' : BEGIN
                Print(Question);
                MPL(SizeOf(BBSList.Description) - 1);
                InputMain(BBSList.Description,(SizeOf(BBSList.Description) - 1),[ColorsAllowed,InterActiveEdit]);
                Abort := (BBSList.Description = '');
              END;
        '9' : BEGIN
                IF (Question <> 'þ') THEN
                  Print(Question);
                MPL(SizeOf(BBSList.Description2) - 1);
                InputMain(BBSList.Description2,(SizeOf(BBSList.Description2) - 1),[ColorsAllowed,InterActiveEdit]);
                Abort := (BBSList.Description2 = '');
              END;
        'A' : BEGIN
                Print(Question);
                MPL(SizeOf(BBSList.xA) - 1);
                InputMain(BBSList.xA,(SizeOf(BBSList.xA) - 1),[ColorsAllowed,InterActiveEdit]);
                Abort := (BBSList.xA = '');
              END;
        'B' : BEGIN
                Print(Question);
                MPL(SizeOf(BBSList.xB) - 1);
                InputMain(BBSList.xB,(SizeOf(BBSList.xB) - 1),[ColorsAllowed,InterActiveEdit]);
                Abort := (BBSList.xB = '');
              END;
        'C' : BEGIN
                Print(Question);
                MPL(SizeOf(BBSList.xC) - 1);
                InputMain(BBSList.xC,(SizeOf(BBSList.xC) - 1),[ColorsAllowed,InterActiveEdit]);
                Abort := (BBSList.xC = '');
              END;
        'D' : BEGIN
                Print(Question);
                MPL(SizeOf(BBSList.xD) - 1);
                InputMain(BBSList.xD,(SizeOf(BBSList.xD) - 1),[ColorsAllowed,InterActiveEdit]);
                Abort := (BBSList.xD = '');
              END;
        'E' : BEGIN
                Print(Question);
                MPL(SizeOf(BBSList.xE) - 1);
                InputMain(BBSList.xE,(SizeOf(BBSList.xE) - 1),[ColorsAllowed,InterActiveEdit]);
                Abort := (BBSList.xE = '');
              END;
        'F' : BEGIN
                Print(Question);
                MPL(SizeOf(BBSList.xF) - 1);
                InputMain(BBSList.xF,(SizeOf(BBSList.xF) - 1),[ColorsAllowed,InterActiveEdit]);
                Abort := (BBSList.xF = '');
              END;
      END;
    END;
  END;
  Close(BBSScriptText);
  LastError := IOResult;
END;

FUNCTION BBSList_Exists: Boolean;
VAR
  BBSListFile: FILE OF BBSListRecordType;
  FSize: Longint;
  FExist: Boolean;
BEGIN
  FSize := 0;
  FExist := Exist(General.DataPath+'BBSLIST.DAT');
  IF (FExist) THEN
  BEGIN
    Assign(BBSListFile,General.DataPath+'BBSLIST.DAT');
    Reset(BBSListFile);
    FSize := FileSize(BBSListFile);
    Close(BBSListFile);
  END;
  IF (NOT FExist) OR (FSize = 0) THEN
  BEGIN
    NL;
    Print('There are currently no entries in the BBS List.');
    SysOpLog('The BBSLIST.DAT file is missing.');
  END;
  BBSList_Exists := (FExist) AND (FSize <> 0);
END;

PROCEDURE DisplayError(FName: ASTR; VAR FExists: Boolean);
BEGIN
  NL;
  PrintACR('|12ú |09The '+FName+'.*  File is missing.');
  PrintACR('|12ú |09Please, inform the Sysop!');
  SysOpLog('The '+FName+'.* file is missing.');
  FExists := FALSE;
END;

FUNCTION BBSListScript_Exists: Boolean;
VAR
  FExists: Boolean;
BEGIN
  FExists := Exist(General.MiscPath+'BBSLIST.SCR');
  IF (NOT FExists) THEN
    DisplayError('BBSLIST.SCR',FExists);
  BBSListScript_Exists := FExists;
END;

FUNCTION BBSListAddScreens_Exists: Boolean;
VAR
  FExistsH,
  FExistsN,
  FExistsT: Boolean;
BEGIN
  FExistsH := TRUE;
  FExistsN := TRUE;
  FExistsT := TRUE;
  IF (NOT ReadBuffer('BBSNH')) THEN
    DisplayError('BBSNH',FExistsH);
  IF (NOT ReadBuffer('BBSMN')) THEN
    DisplayError('BBSMN',FExistsN);
  IF (NOT ReadBuffer('BBSNT')) THEN
    DisplayError('BBSNT',FExistsT);
  BBSListAddScreens_Exists := (FExistsH) AND (FExistsN) AND (FExistsT);
END;

FUNCTION BBSListEditScreens_Exists: Boolean;
VAR
  FExistsT,
  FExistsM: Boolean;
BEGIN
  FExistsT := TRUE;
  FExistsM := TRUE;
  IF (NOT ReadBuffer('BBSLET')) THEN
    DisplayError('BBSLET',FExistsT);
  IF (NOT ReadBuffer('BBSLEM')) THEN
    DisplayError('BBSLEM',FExistsM);
  BBSListEditScreens_Exists := (FExistsT) AND (FExistsM);
END;

PROCEDURE BBSList_Renumber;
VAR
  BBSListFile: FILE OF BBSListRecordType;
  BBSList: BBSListRecordType;
  OnRec: Longint;
BEGIN
  Assign(BBSListFile,General.DataPath+'BBSLIST.DAT');
  Reset(BBSListFile);
  Abort := FALSE;
  OnRec := 1;
  WHILE (OnRec <= FileSize(BBSListFile)) DO
  BEGIN
    Seek(BBSListFile,(OnRec - 1));
    Read(BBSListFile,BBSList);
    BBSList.RecordNum := OnRec;
    Seek(BBSListFile,(OnRec - 1));
    Write(BBSListFile,BBSList);
    Inc(OnRec);
  END;
  Close(BBSListFile);
  LastError := IOResult;
END;

PROCEDURE BBSList_Sort;
VAR
  BBSListFile: FILE OF BBSListRecordType;
  BBSList1,
  BBSList2: BBSListRecordType;
  S,
  I,
  J,
  pl,
  Gap: INTEGER;
BEGIN
  IF (BBSList_Exists) THEN
  BEGIN
    Assign(BBSListFile,General.DataPath+'BBSLIST.DAT');
    Reset(BBSListFile);
    pl := FileSize(BBSListFile);
    Gap := pl;
    REPEAT;
      Gap := (Gap DIV 2);
      IF (Gap = 0) THEN
        Gap := 1;
      s := 0;
      FOR I := 1 TO (pl - Gap) DO
      BEGIN
        J := (I + Gap);
        Seek(BBSListFile,(i - 1));
        Read(BBSListFile,BBSList1);
        Seek(BBSListFile,(j - 1));
        Read(BBSListFile,BBSList2);
        IF (BBSList1.BBSName > BBSList2.BBSName) THEN
        BEGIN
          Seek(BBSListFile,(i - 1));
          Write(BBSListFile,BBSList2);
          Seek(BBSListFile,(j - 1));
          Write(BBSListFile,BBSList1);
          Inc(s);
        END;
      END;
    UNTIL (s = 0) AND (Gap = 1);
    Close(BBSListFile);
    LastError := IOResult;
    IF (PL > 0) THEN
    BEGIN
      NL;
      Print('Sorted '+IntToStr(pl)+' BBS List entries.');
      SysOpLog('Sorted the BBS Listing');
    END;
  END;
END;

PROCEDURE BBSList_Add;
VAR
  Data2: Pointer;
  BBSList: BBSListRecordType;
BEGIN
  IF (BBSListScript_Exists) AND (BBSListAddScreens_Exists) THEN
  BEGIN
    NL;
    IF PYNQ('Would you like to add an entry to the BBS List? ',0,FALSE) THEN
    BEGIN
      FillChar(BBSList,SizeOf(BBSList),0);
      BBSListScriptFile(BBSList);
      IF (NOT Abort) THEN
      BEGIN
        PrintF('BBSNH');
        ReadBuffer('BBSMN');
        DisplayBuffer(BBSListMCI,@BBSList,Data2);
        PrintF('BBSNT');
        NL;
        IF (PYNQ('Would you like to save this BBS Listing? ',0,TRUE)) THEN
        BEGIN
          Assign(BBSListFile,General.DataPath+'BBSLIST.DAT');
          IF (Exist(General.DataPath+'BBSLIST.DAT')) THEN
            Reset(BBSListFile)
          ELSE
            Rewrite(BBSListFile);
          Seek(BBSListFile,FileSize(BBSListFile));
          BBSList.UserID := UserNum;
          BBSList.DateAdded := GetPackDateTime;
          BBSList.DateEdited := BBSList.DateAdded;
          BBSList.RecordNum := (FileSize(BBSListFile) + 1);
          Write(BBSListFile,BBSList);
          Close(BBSListFile);
          LastError := IOResult;
          BBSList_Sort;
          BBSList_Renumber;
          SysOpLog('Added BBS Listing: '+BBSList.BBSName+'.');
        END;
      END;
    END;
  END;
END;

PROCEDURE BBSList_Delete;
VAR
  Data2: Pointer;
  BBSList: BBSListRecordType;
  OnRec,
  RecNum: Longint;
  Found: Boolean;
BEGIN
  IF (BBSList_Exists) AND (BBSListEditScreens_Exists) THEN
  BEGIN
    AllowContinue := FALSE;
    Found := FALSE;
    Abort := FALSE;
    Assign(BBSListFile,General.DataPath+'BBSLIST.DAT');
    Reset(BBSListFile);
    OnRec := 1;
    WHILE (OnRec <= FileSize(BBSListFile)) AND (NOT Abort) AND (NOT HangUp) DO
    BEGIN
      Seek(BBSListFile,(OnRec - 1));
      Read(BBSListFile,BBSList);
      IF (BBSList.UserID = UserNum) OR (CoSysOp) THEN
      BEGIN
        PrintF('BBSLET');
        ReadBuffer('BBSLEM');
        DisplayBuffer(BBSListMCI,@BBSList,Data2);
        NL;
        IF (PYNQ('Would you like to delete this BBS Listing? ',0,FALSE)) THEN
        BEGIN
          SysOpLog('Deleted BBS Listing: '+BBSList.BBSName+'.');
          IF ((OnRec - 1) <= (FileSize(BBSListFile) - 2)) THEN
            FOR RecNum := (OnRec - 1) TO (FileSize(BBSListFile) - 2) DO
            BEGIN
              Seek(BBSListFile,(RecNum + 1));
              Read(BBSListFile,BBSList);
              Seek(BBSListFile,RecNum);
              Write(BBSListFile,BBSList);
            END;
          Seek(BBSListFile,(FileSize(BBSListFile) - 1));
          Truncate(BBSListFile);
          Dec(OnRec);
        END;
        Found := TRUE;
      END;
      Inc(OnRec);
    END;
    Close(BBSListFile);
    LastError := IOResult;
    BBSList_ReNumber;
    IF (NOT Found) THEN
    BEGIN
      NL;
      Print('You may only delete BBS Listing''s that you have entered.');
      SysOpLog('Tried to delete a BBS Listing.');
    END;
  END;
END;

PROCEDURE BBSList_Edit;
VAR
  Data2: Pointer;
  BBSList: BBSListRecordType;
  OnRec: Longint;
  Found: Boolean;
BEGIN
  IF (BBSList_Exists) AND (BBSListEditScreens_Exists) AND (BBSListAddScreens_Exists) THEN
  BEGIN
    Assign(BBSListFile,General.DataPath+'BBSLIST.DAT');
    Reset(BBSListFile);
    AllowContinue := FALSE;
    Found := FALSE;
    Abort := FALSE;
    OnRec := 1;
    WHILE (OnRec <= FileSize(BBSListFile)) AND (NOT Abort) AND (NOT HangUp) DO
    BEGIN
      Seek(BBSListFile,(OnRec - 1));
      Read(BBSListFile,BBSList);
      IF (BBSList.UserID = UserNum) OR (CoSysOp) THEN
      BEGIN
        PrintF('BBSLET');
        ReadBuffer('BBSLEM');
        DisplayBuffer(BBSListMCI,@BBSList,Data2);
        NL;
        IF (PYNQ('Would you like to edit this BBS Listing? ',0,FALSE)) THEN
        BEGIN
          BBSListScriptFile(BBSList);
          IF (NOT Abort) THEN
          BEGIN
            PrintF('BBSNH');
            ReadBuffer('BBSMN');
            DisplayBuffer(BBSListMCI,@BBSList,Data2);
            PrintF('BBSNT');
            NL;
            IF (PYNQ('Would you like to save this BBS Listing? ',0,TRUE)) THEN
            BEGIN
              Seek(BBSListFile,(OnRec - 1));
              BBSList.DateEdited := GetPackDateTime;
              Write(BBSListFile,BBSList);
              SysOpLog('Edited BBS Listing: '+BBSList.BBSName+'.');
            END;
          END;
        END;
        Found := TRUE;
      END;
      Inc(OnRec);
    END;
    Close(BBSListFile);
    LastError := IOResult;
    IF (NOT Found) THEN
    BEGIN
      NL;
      Print('You may only edit BBS Listing''s that you have entered.');
      SysOpLog('Tried to edit a BBS Listing.');
    END;
  END;
END;

PROCEDURE BBSList_View;
VAR
  Data2: Pointer;
  BBSList: BBSListRecordType;
  OnRec: Longint;
BEGIN
  IF (BBSList_Exists) AND (BBSListAddScreens_Exists) THEN
  BEGIN
    Assign(BBSListFile,General.DataPath+'BBSLIST.DAT');
    Reset(BBSListFile);
    ReadBuffer('BBSMN');
    AllowContinue := TRUE;
    Abort := FALSE;
    PrintF('BBSNH');
    OnRec := 1;
    WHILE (OnRec <= FileSize(BBSListFile)) AND (NOT Abort) AND (NOT HangUp) DO
    BEGIN
      Seek(BBSListFile,(OnRec - 1));
      Read(BBSListFile,BBSList);
      DisplayBuffer(BBSListMCI,@BBSList,Data2);
      Inc(OnRec);
    END;
    Close(BBSListFile);
    LastError := IOResult;
    IF (NOT Abort) THEN
      PrintF('BBSNT');
    AllowContinue := FALSE;
    SysOpLog('Viewed the BBS Listing.');
  END;
END;

PROCEDURE BBSList_xView;   (* Do we need xview *)
VAR
  Data2: Pointer;
  BBSList: BBSListRecordType;
  OnRec: Longint;
BEGIN
  IF (BBSList_Exists) THEN   (* Add BBSME & BBSEH exist checking here *)
  BEGIN
    Assign(BBSListFile,General.DataPath+'BBSLIST.DAT');
    Reset(BBSListFile);
    IF (ReadBuffer('BBSME')) THEN
    BEGIN
      AllowContinue := TRUE;
      Abort := FALSE;
      PrintF('BBSEH');
      OnRec := 1;
      WHILE (OnRec <= FileSize(BBSListFile)) AND (NOT Abort) AND (NOT HangUp) DO
      BEGIN
        Seek(BBSListFile,(OnRec - 1));
        Read(BBSListFile,BBSList);
        DisplayBuffer(BBSListMCI,@BBSList,Data2);
        Inc(OnRec);
      END;
      IF (NOT Abort) THEN
        PrintF('BBSET');
      AllowContinue := FALSE;
      PauseScr(FALSE);
      SysOpLog('Viewed the BBS Listing.');
    END;
    Close(BBSListFile);
    LastError := IOResult;
  END;
END;

END.
