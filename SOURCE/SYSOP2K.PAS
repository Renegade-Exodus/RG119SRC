{$IFDEF WIN32}
{$I DEFINES.INC}
{$ENDIF}

{$A+,B-,D+,E-,F+,I-,L+,N-,O+,R-,S+,V-}

UNIT SysOp2K;

INTERFACE

PROCEDURE DisplayArcs;
PROCEDURE DisplayCmt;
PROCEDURE ArchiveConfiguration;

IMPLEMENTATION

USES
  Common;


PROCEDURE DisplayArcs;
VAR
  RecNumToList: Byte;
BEGIN
  Abort := FALSE;
  Next := FALSE;
  PrintACR('^0 ##^4:^3Ext^4:^3Compression cmdline      ^4:^3Decompression cmdline    ^4:^3Success Code');
  PrintACR('^4 ==:===:=========================:=========================:============');
  RecNumToList := 1;
  WHILE (RecNumToList <= NumArcs) AND (NOT Abort) AND (NOT HangUp) DO
  BEGIN
    WITH General.FileArcInfo[RecNumToList] DO
      PrintACR(AOnOff(Active,'^5+','^1-')+
               '^0'+PadRightInt(RecNumToList,2)+
               ' ^3'+PadLeftStr(Ext,3)+
               ' ^5'+PadLeftStr(ArcLine,25)+
               ' '+PadLeftStr(UnArcLine,25)+
               ' '+AOnOff(SuccLevel <> - 1,IntToStr(SuccLevel),'-1 (ignores)'));
    Inc(RecNumToList);
  END;
END;

PROCEDURE DisplayCmt;
VAR
  RecNumToList: Byte;
BEGIN
  FOR RecNumToList := 1 TO 3 DO
    PrintACR('^1'+IntToStr(RecNumToList)+'. Archive comment file: ^5'+
             AOnOff(General.FileArcComment[RecNumToList] <> '',
                    General.FileArcComment[RecNumToList],'*None*'));
END;

PROCEDURE ArchiveConfiguration;
VAR
  TempArchive: FileArcInfoRecordType;
  Cmd: Char;
  RecNumToList: Byte;
  Changed : Boolean;

  FUNCTION DisplayArcStr(S: AStr): AStr;
  BEGIN
    IF (S <> '') THEN
      DisplayArcStr := S
    ELSE
      DisplayArcStr := '*None*';
    IF (S[1] = '/') THEN
    BEGIN
      S := '"'+S+'" - ';
      CASE s[3] OF
        '1' : DisplayArcStr := S + '*Internal* ZIP viewer';
        '2' : DisplayArcStr := S + '*Internal* ARC/PAK viewer';
        '3' : DisplayArcStr := S + '*Internal* ZOO viewer';
        '4' : DisplayArcStr := S + '*Internal* LZH viewer';
        '5' : DisplayArcStr := S + '*Internal* ARJ viewer';
      END;
    END;
  END;

  PROCEDURE InitArchiveVars(VAR Archive: FileArcInfoRecordType);
  BEGIN
    FillChar(Archive,SizeOf(Archive),0);
    WITH Archive DO
    BEGIN
      Active := FALSE;
      Ext := 'AAA';
      ListLine := '';
      ArcLine := '';
      UnArcLine := '';
      TestLine := '';
      CmtLine := '';
      SuccLevel := -1;
    END;
  END;

  PROCEDURE DeleteArchive(TempArchive1: FileArcInfoRecordType; RecNumToDelete: Byte);
  VAR
    RecNum: Byte;
  BEGIN
    IF (NumArcs = 0) THEN
      Messages(4,0,'archive records')
    ELSE
    BEGIN
      RecNumToDelete := 0;
      InputByteWOC('%LFArchive to delete?',RecNumToDelete,[NumbersOnly],1,NumArcs);
      IF (RecNumToDelete >= 1) AND (RecNumToDelete <= NumArcs) THEN
      BEGIN
        TempArchive1 := General.FileArcInfo[RecNumToDelete];
        Print('%LFArchive: ^5'+TempArchive1.Ext);
        IF PYNQ('%LFAre you sure you want to delete it? ',0,FALSE) THEN
        BEGIN
          Print('%LF[> Deleting archive record ...');
          FOR RecNum := RecNumToDelete TO (NumArcs - 1) DO
            General.FileArcInfo[RecNum] := General.FileArcInfo[RecNum + 1];
          General.FileArcInfo[NumArcs].Ext := '';
          Dec(NumArcs);
          SysOpLog('* Deleted archive: ^5'+TempArchive1.Ext);
        END;
      END;
    END;
  END;

  PROCEDURE CheckArchive(Archive: FileArcInfoRecordType; StartErrMsg,EndErrMsg: Byte; VAR Ok: Boolean);
  VAR
    Counter: Byte;
  BEGIN
    FOR Counter := StartErrMsg TO EndErrMsg DO
      CASE Counter OF
        1 : IF (Archive.Ext = '') OR (Archive.Ext = 'AAA') THEN
            BEGIN
              Print('%LF^7The archive extension is invalid!^1');
              OK := FALSE;
            END;
      END;
  END;

  PROCEDURE EditArchive(TempArchive1: FileArcInfoRecordType; VAR Archive: FileArcInfoRecordType; VAR Cmd1: Char;
                        VAR RecNumToEdit: Byte; VAR Changed1: Boolean; Editing: Boolean);
  VAR
    CmdStr: AStr;
    Ok: Boolean;
  BEGIN
    WITH Archive DO
      REPEAT
        IF (Cmd1 <> '?') THEN
        BEGIN
          Abort := FALSE;
          Next := FALSE;
          CLS;
          IF (Editing) THEN
            PrintACR('^5Editing archive #'+IntToStr(RecNumToEdit)+
                     ' of '+IntToStr(NumArcs))
          ELSE
            PrintACR('^5Inserting archive #'+IntToStr(RecNumToEdit)+' of '+IntToStr(NumArcs + 1));
          NL;
          PrintACR('^11. Active                 : ^5'+ShowYesNo(Active));
          PrintACR('^12. Extension name         : ^5'+Ext);
          PrintACR('^13. Interior list method   : ^5'+DisplayArcStr(ListLine));
          PrintACR('^14. Compression cmdline    : ^5'+DisplayArcStr(ArcLine));
          PrintACR('^15. Decompression cmdline  : ^5'+DisplayArcStr(UnArcLine));
          PrintACR('^16. File testing cmdline   : ^5'+DisplayArcStr(TestLine));
          PrintACR('^17. Add comment cmdline    : ^5'+DisplayArcStr(CmtLine));
          PrintACR('^18. Errorlevel for success : ^5'++AOnOff(SuccLevel <> - 1,IntToStr(SuccLevel),'-1 (ignores)'));
        END;
        IF (NOT Editing) THEN
          CmdStr := '12345678'
        ELSE
          CmdStr := '12345678[]FJL';
        LOneK('%LFModify menu [^5?^4=^5Help^4]: ',Cmd1,'Q?'+CmdStr+^M,TRUE,TRUE);
        CASE Cmd1 OF
          '1' : BEGIN
                  Active := NOT Active;
                  Changed1 := TRUE;
                END;
          '2' : REPEAT
                  TempArchive1.Ext := Ext;
                  Ok := TRUE;
                  InputWN1('%LFNew extension: ',Ext,(SizeOf(Ext) - 1),[InterActiveEdit,UpperOnly],Changed1);
                  CheckArchive(Archive,1,1,Ok);
                  IF (NOT Ok) THEN
                    Ext := TempArchive1.Ext;
                UNTIL (Ok) OR (HangUp);
          '3' : InputWN1('%LFNew interior list method: ',ListLine,(SizeOf(ListLine) - 1),[InterActiveEdit],Changed1);
          '4' : InputWN1('%LFNew compression command line: ',ArcLine,(SizeOf(ArcLine) - 1),[InterActiveEdit],Changed1);
          '5' : InputWN1('%LFNew decompression command line: ',UnArcLine,(SizeOf(UnArcLine) - 1),
                         [InterActiveEdit],Changed1);
          '6' : InputWN1('%LFNew file testing command line: ',TestLine,(SizeOf(TestLine) - 1),
                         [InterActiveEdit],Changed1);
          '7' : InputWN1('%LFNew add comment command line: ',CmtLine,(SizeOf(CmtLine) - 1),[InterActiveEdit],Changed1);
          '8' : InputIntegerWC('%LFNew errorlevel for success',SuccLevel,[DisplayValue,NumbersOnly],-1,255,Changed1);
          '[' : IF (RecNumToEdit > 1) THEN
                  Dec(RecNumToEdit)
                ELSE
                BEGIN
                  Messages(2,0,'');
                  Cmd1 := #0;
                END;
          ']' : IF (RecNumToEdit < NumArcs) THEN
                  Inc(RecNumToEdit)
                ELSE
                BEGIN
                  Messages(3,0,'');
                  Cmd1 := #0;
                END;
          'F' : IF (RecNumToEdit <> 1) THEN
                  RecNumToEdit := 1
                ELSE
                BEGIN
                  Messages(2,0,'');
                  Cmd1 := #0;
                END;
          'J' : BEGIN
                  InputByteWOC('%LFJump to entry?',RecNumToEdit,[NumbersOnly],1,NumArcs);
                  IF (RecNumToEdit < 1) OR (RecNumToEdit > NumArcs) THEN
                    Cmd1 := #0;
                END;
          'L' : IF (RecNumToEdit <> NumArcs) THEN
                  RecNumToEdit := NumArcs
                ELSE
                BEGIN
                  Messages(3,0,'');
                  Cmd1 := #0;
                END;
          '?' : BEGIN
                  Print('%LF^1<^3CR^1>Redisplay current screen');
                  Print('^31^1-^38^1:Modify item');
                  IF (NOT Editing) THEN
                    LCmds(20,3,'Quit and save','')
                  ELSE
                  BEGIN
                    LCmds(20,3,'[Back entry',']Forward entry');
                    LCmds(20,3,'First entry in list','Jump to entry');
                    LCmds(20,3,'Last entry in list','Quit and save');
                  END;
                END;
        END;
      UNTIL (Pos(Cmd1,'Q[]FJL') <> 0) OR (HangUp);
  END;

  PROCEDURE InsertArchive(TempArchive1: FileArcInfoRecordType; Cmd1: Char; RecNumToInsertBefore: Byte);
  VAR
    RecNum,
    RecNumToEdit: Byte;
    Ok,
    Changed1: Boolean;
  BEGIN
    IF (NumArcs = MaxArcs) THEN
      Messages(5,MaxArcs,'archive records')
    ELSE
    BEGIN
      RecNumToInsertBefore := 0;
      InputByteWOC('%LFArchive to insert before?',RecNumToInsertBefore,[NumbersOnly],1,(NumArcs + 1));
      IF (RecNumToInsertBefore >= 1) AND (RecNumToInsertBefore <= (NumArcs + 1)) THEN
      BEGIN
        InitArchiveVars(TempArchive1);
        IF (RecNumToInsertBefore = 1) THEN
          RecNumToEdit := 1
        ELSE IF (RecNumToInsertBefore = (NumArcs + 1)) THEN
          RecNumToEdit := (NumArcs + 1)
        ELSE
          RecNumToEdit := RecNumToInsertBefore;
        REPEAT
          OK := TRUE;
          EditArchive(TempArchive1,TempArchive1,Cmd1,RecNumToEdit,Changed1,FALSE);
          CheckArchive(TempArchive1,1,2,Ok);
          IF (NOT OK) THEN
            IF (NOT PYNQ('%LFContinue inserting archive? ',0,TRUE)) THEN
              Abort := TRUE;
        UNTIL (OK) OR (Abort) OR (HangUp);
        IF (NOT Abort) AND (PYNQ('%LFIs this what you want? ',0,FALSE)) THEN
        BEGIN
          Print('%LF[> Inserting archive record ...');
          IF (RecNumToInsertBefore <> (NumArcs + 1)) THEN
            FOR RecNum := (NumArcs + 1) DOWNTO (RecNumToInsertBefore + 1) DO
              General.FileArcInfo[RecNum] := General.FileArcInfo[RecNum - 1];
          General.FileArcInfo[RecNumToInsertBefore] := TempArchive1;
          Inc(NumArcs);
          SysOpLog('* Inserted archive: ^5'+TempArchive1.Ext);
        END;
      END;
    END;
  END;

  PROCEDURE ModifyArchive(TempArchive1: FileArcInfoRecordType; Cmd1: Char; RecNumToEdit: Byte);
  VAR
    Archive: FileArcInfoRecordType;
    SaveRecNumToEdit: Byte;
    OK,
    Changed1: Boolean;
  BEGIN
    IF (NumArcs = 0) THEN
      Messages(4,0,'archive records')
    ELSE
    BEGIN
      RecNumToEdit := 0;
      InputByteWOC('%LFArchive to modify?',RecNumToEdit,[NumbersOnly],1,NumArcs);
      IF (RecNumToEdit >= 1) AND (RecNumToEdit <= NumArcs) THEN
      BEGIN
        SaveRecNumToEdit := 0;
        Cmd1 := #0;
        WHILE (Cmd1 <> 'Q') AND (NOT HangUp) DO
        BEGIN
          IF (SaveRecNumToEdit <> RecNumToEdit) THEN
          BEGIN
            Archive := General.FileArcInfo[RecNumToEdit];
            SaveRecNumToEdit := RecNumToEdit;
            Changed1 := FALSE;
          END;
          REPEAT
            Ok := TRUE;
            EditArchive(TempArchive1,Archive,Cmd1,RecNumToEdit,Changed1,TRUE);
            CheckArchive(Archive,1,2,Ok);
            IF (NOT OK) THEN
            BEGIN
              PauseScr(FALSE);
              IF (RecNumToEdit <> SaveRecNumToEdit) THEN
                RecNumToEdit := SaveRecNumToEdit;
            END;
          UNTIL (Ok) OR (HangUp);
          IF (Changed1) THEN
          BEGIN
            General.FileArcInfo[SaveRecNumToEdit] := Archive;
            Changed1 := FALSE;
            SysOpLog('* Modified archive: ^5'+Archive.Ext);
          END;
        END;
      END;
    END;
  END;

BEGIN
  Cmd := #0;
  REPEAT
    IF (Cmd <> '?') THEN
    BEGIN
      CLS;
      DisplayArcs;
      NL;
      DisplayCmt;
    END;
    LOneK('%LFArchive editor [^5?^4=^5Help^4]: ',Cmd,'QDIM123?'^M,TRUE,TRUE);
    CASE Cmd OF
      'D' : DeleteArchive(TempArchive,RecNumToList);
      'I' : InsertArchive(TempArchive,Cmd,RecNumToList);
      'M' : ModifyArchive(TempArchive,Cmd,RecNumToList);
      '1'..'3' :
            BEGIN
              Changed := FALSE;
              InputWNWC('%LFNew comment file #'+IntToStr(Ord(Cmd) - 48)+': ',General.FileArcComment[Ord(Cmd) - 48],40,Changed);
              IF (Changed) THEN
                SysOpLog('* Modified comment: ^5'+IntToStr(Ord(Cmd) - 48)+'.');
            END;
      '?' : BEGIN
              Print('%LF^1<^3CR^1>Next screen or redisplay current screen');
              Print('^1(^3?^1)Help/First archive');
              Print('^31^1-^33^1:Modify Item');
              LCmds(16,3,'Delete archive','Insert archive');
              LCmds(16,3,'Modify archive','Quit');
            END;
    END;
  UNTIL (Cmd = 'Q') OR (HangUp);
END;

END.
