{$IFDEF WIN32}
{$I DEFINES.INC}
{$ENDIF}

{$A+,B-,D+,E-,F+,I-,L+,N-,O+,R-,S+,V-}

UNIT SysOp10;

INTERFACE

PROCEDURE VotingEditor;

IMPLEMENTATION

USES
  Common,
  MiscUser;

PROCEDURE VotingEditor;
VAR
  TempTopic: VotingRecordType;
  Cmd: Char;
  RecNumToList: Byte;
  SaveTempPause: Boolean;

  PROCEDURE InitTopicVars(VAR Topic: VotingRecordType);
  VAR
    User: UserRecordType;
    Counter: Byte;
  BEGIN
    LoadURec(User,UserNum);
    FillChar(Topic,SizeOf(Topic),0);
    WITH Topic DO
    BEGIN
      Question1 := '<< New Voting Topic >>';
      Question2 := '';
      ACS := 'VV';
      ChoiceNumber := 0;
      NumVotedQuestion := 0;
      CreatedBy := Caps(User.Name);
      AddAnswersACS := General.AddChoice;
      FOR Counter := 1 TO MaxChoices DO
        WITH Answers[Counter] DO
        BEGIN
          Answer1 := '<< New Topic Choice >>';
          Answer2 := '';
          NumVotedAnswer := 0;
        END;
    END;
  END;

  PROCEDURE DeleteChoice(VAR Topic: VotingRecordType; RecNumToDelete: Byte; VAR Changed: Boolean);
  VAR
    User: UserRecordType;
    RecNum,
    RecNum1: Byte;
    UNum: Integer;
  BEGIN
    IF (Topic.ChoiceNumber < 1) THEN
      Messages(4,0,'topic choices')
    ELSE
    BEGIN
      RecNum := 0;
      InputByteWOC('%LFDelete which choice',RecNum,[Numbersonly],1,Topic.ChoiceNumber);
      IF (RecNum >= 1) AND (RecNum <= Topic.ChoiceNumber) THEN
      BEGIN
        Dec(Topic.ChoiceNumber);
        Dec(Topic.NumVotedQuestion,Topic.Answers[RecNum].NumVotedAnswer);
        IF (RecNum < MaxChoices) THEN
          FOR RecNum1 := RecNum TO Topic.ChoiceNumber DO
          BEGIN
            Topic.Answers[RecNum1].Answer1 := Topic.Answers[RecNum1 + 1].Answer1;
            Topic.Answers[RecNum1].Answer2 := Topic.Answers[RecNum1 + 1].Answer2;
            Topic.Answers[RecNum1].NumVotedAnswer := Topic.Answers[RecNum1 + 1].NumVotedAnswer;
          END;
       Reset(UserFile);
       FOR UNum := 1 TO (FileSize(UserFile) - 1) DO
       BEGIN
         Seek(UserFile,Unum);
         Read(UserFile,User);
         IF (User.Vote[RecNumToDelete] = RecNum) THEN
           User.Vote[RecNumToDelete] := 0
         ELSE IF (User.Vote[RecNumToDelete] > RecNum) THEN
           Dec(User.Vote[RecNumToDelete]);
         Seek(UserFile,UNum);
         Write(UserFile,User);
       END;
       Close(UserFile);
       IF (ThisUser.Vote[RecNumToDelete] = RecNum) THEN
         ThisUser.Vote[RecNumToDelete] := 0;
       Changed := TRUE;
      END;
    END;
  END;

  PROCEDURE InsertChoice(VAR Topic: VotingRecordType; RecNumToEdit: Byte; VAR Changed: Boolean);
  BEGIN
    IF (Topic.ChoiceNumber >= MaxChoices) THEN
      Messages(5,MaxChoices,'topic choices')
    ELSE IF PYNQ('%LFAdd topic choice #'+IntToStr(Topic.ChoiceNumber + 1)+'? ',0,FALSE) THEN
    BEGIN
      InputWNWC('%LFChoice: ',Topic.Answers[Topic.ChoiceNumber + 1].Answer1,65,Changed);
      IF (Topic.Answers[Topic.ChoiceNumber + 1].Answer1 <> '') THEN
      BEGIN
        Topic.Answers[Topic.ChoiceNumber + 1].NumVotedAnswer := 0;
        InputWNWC(PadLeftStr('',6)+': ',Topic.Answers[Topic.ChoiceNumber + 1].Answer2,65,Changed);
        Inc(Topic.ChoiceNumber);
      END;
      Changed := TRUE;
    END;
  END;

  PROCEDURE CheckChoice(Topic: VotingRecordType; RecNum1: Byte; StartErrMsg,EndErrMsg: Byte; VAR Ok: Boolean);
  VAR
    Counter: Byte;
  BEGIN
    FOR Counter := StartErrMsg TO EndErrMsg DO
      CASE Counter OF
        1 : IF (Topic.Answers[RecNum1].Answer1 = '') OR (Topic.Answers[RecNum1].Answer1 = '<< New Topic Choice >>') THEN
            BEGIN
              Print('%LF^7The answer is invalid!^1');
              OK := FALSE;
            END;
      END;
  END;

  PROCEDURE ModifyChoice(TempTopic1: VotingRecordType; VAR Topic: VotingRecordType; RecNumToEdit: Byte; VAR Changed: Boolean);
  VAR
    Cmd1: Char;
    RecNum: Byte;
    Ok: Boolean;
  BEGIN
    IF (Topic.ChoiceNumber < 1) THEN
      Messages(4,0,'topic choices')
    ELSE
    BEGIN
      RecNum := 0;
      InputByteWOC('%LFModify which choice',RecNum,[Numbersonly],1,Topic.ChoiceNumber);
      IF (RecNum >= 1) AND (RecNum <= Topic.ChoiceNumber) THEN
      BEGIN
        REPEAT
          IF (Cmd1 <> '?') THEN
          BEGIN
            Abort := FALSE;
            Next := FALSE;
            Print('%CL^5Topic choice #'+IntToStr(RecNum)+' of '+IntToStr(Topic.ChoiceNumber));
            NL;
            PrintACR('^11. Choice: ^5'+Topic.Answers[RecNum].Answer1);
            IF (Topic.Answers[RecNum].Answer2 <> '') THEN
              PrintACR('^1         : ^5'+Topic.Answers[RecNum].Answer2);
            PrintACR('^12. Voters: ^5'+IntToStr(Topic.Answers[RecNum].NumVotedAnswer));
          END;
          LOneK('%LFModify menu [^5?^4=^5Help^4]: ',Cmd1,'Q12[]FJL?'^M,TRUE,TRUE);
          CASE Cmd1 OF
            '1' : BEGIN
                    REPEAT
                      TempTopic1.Answers[RecNum].Answer1 := Topic.Answers[RecNum].Answer1;
                      Ok := TRUE;
                      InputWNWC('%LFNew choice: ',Topic.Answers[RecNum].Answer1,
                                (SizeOf(Topic.Answers[RecNum].Answer1) - 1),Changed);
                      CheckChoice(Topic,RecNum,1,1,Ok);
                      IF (NOT Ok) THEN
                        Topic.Answers[RecNum].Answer1 := TempTopic1.Answers[RecNum].Answer1;
                    UNTIL (Ok) OR (HangUp);
                    IF (Topic.Answers[RecNum].Answer1 <> '') THEN
                      InputWNWC(PadLeftStr('',10)+': ',Topic.Answers[Recnum].Answer2,
                                (SizeOf(Topic.Answers[RecNum].Answer2) - 1),Changed);
                  END;
            '2' : InputIntegerWC('%LFNew number of voters',Topic.Answers[RecNum].NumVotedAnswer,[DisplayValue,NumbersOnly],0,
                                 (MaxUsers - 1),Changed);
            '[' : IF (RecNum > 1) THEN
                    Dec(RecNum)
                  ELSE
                  BEGIN
                    Messages(2,0,'');
                    Cmd1 := #0;
                  END;
            ']' : IF (RecNum < Topic.ChoiceNumber) THEN
                    Inc(RecNum)
                  ELSE
                  BEGIN
                    Messages(3,0,'');
                    Cmd1 := #0;
                  END;
            'F' : IF (RecNum <> 1) THEN
                    RecNum := 1
                  ELSE
                  BEGIN
                    Messages(2,0,'');
                    Cmd1 := #0;
                  END;
            'J' : BEGIN
                    InputByteWOC('%LFJump to entry',RecNum,[Numbersonly],1,Topic.ChoiceNumber);
                    IF (RecNum < 1) OR (RecNum > Topic.ChoiceNumber) THEN
                      Cmd1 := #0;
                  END;
            'L' : IF (RecNum <> Topic.ChoiceNumber) THEN
                    RecNum := Topic.ChoiceNumber
                  ELSE
                  BEGIN
                    Messages(3,0,'');
                    Cmd1 := #0;
                  END;
            '?' : BEGIN
                    Print('%LF^1<^3CR^1>Redisplay screen');
                    Print('^31-2^1:Modify item');
                    LCmds(20,3,'[Back entry',']Forward entry');
                    LCmds(20,3,'First entry in list','Jump to entry');
                    LCmds(20,3,'Last entry in list','Quit and save');
                  END;
          END;
        UNTIL (Cmd1 = 'Q') OR (HangUp);
      END;
    END;
  END;

  PROCEDURE ListChoices(VAR Topic: VotingRecordType; VAR RecNumToList1: Byte);
  VAR
    NumDone: Byte;
  BEGIN
    IF (RecNumToList1 < 1) OR (RecNumToList1 > Topic.ChoiceNumber) THEN
      RecNumToList1 := 1;
    Abort := FALSE;
    Next := FALSE;
    CLS;
    PrintACR('^0##^4:^3Answer^4:^3Choice');
    PrintACR('^4==:======:=====================================================================');
    NumDone := 0;
    WHILE (NumDone < (PageLength - 5)) AND (RecNumToList1 >= 1) AND (RecNumToList1 <= Topic.ChoiceNumber)
          AND (NOT Abort) AND (NOT HangUp) DO
    BEGIN
      PrintACR('^0'+PadRightInt(RecNumToList1,2)+
               ' ^3'+PadRightInt(Topic.Answers[RecNumToList1].NumVotedAnswer,6)+
               ' ^5'+Topic.Answers[RecNumToList1].Answer1);
      WKey;
      Inc(RecNumToList1);
      Inc(NumDone);
    END;
    IF (Topic.ChoiceNumber = 0) THEN
      Print('*** No voting choices defined ***');
  END;

  PROCEDURE ChoiceEditor(TempTopic1: VotingRecordType; VAR Topic: VotingRecordType; Cmd1: Char;
                         RecNumToEdit: Byte; VAR Changed: Boolean);
  VAR
    RecNumToList1: Byte;
  BEGIN
    SaveTempPause := TempPause;
    TempPause := FALSE;
    RecNumToList1 := 1;
    Cmd1 := #0;
    REPEAT
      IF (Cmd1 <> '?') THEN
        ListChoices(Topic,RecNumToList1);
      LOneK('%LFTopic choice editor [^5?^4=^5Help^4]: ',Cmd1,'QDIM?'^M,TRUE,TRUE);
      CASE Cmd1 OF
        ^M  : IF (RecNumToList1 < 1) OR (RecNumToList1 > Topic.ChoiceNumber) THEN
                RecNumToList1 := 1;
        'D' : DeleteChoice(Topic,RecNumToEdit,Changed);
        'I' : InsertChoice(Topic,RecNumToEdit,Changed);
        'M' : ModifyChoice(TempTopic1,Topic,RecNumToEdit,Changed);
        '?' : BEGIN
                Print('%LF^1<^3CR^1>Next screen or redisplay current screen');
                Print('^1(^3?^1)Help/First topic choice');
                LCmds(20,3,'Delete topic choice','Insert topic choice');
                LCmds(20,3,'Modify topic choice','Quit');
              END;
      END;
      IF (Cmd1 <> ^M) THEN
        RecNumToList1 := 1;
    UNTIL (Cmd1 = 'Q') OR (HangUp);
    TempPause := SaveTempPause;
  END;

  PROCEDURE DeleteTopic(TempTopic1: VotingRecordType; RecNumToDelete: Byte);
  VAR
    User: UserRecordType;
    RecNum: Integer;
  BEGIN
    IF (NumVotes = 0) THEN
      Messages(4,0,'voting topics')
    ELSE
    BEGIN
      RecNumToDelete := 0;
      InputByteWOC('%LFVoting topic to delete',RecNumToDelete,[NumbersOnly],1,NumVotes);
      IF (RecNumToDelete >= 1) AND (RecNumToDelete <= NumVotes) THEN
      BEGIN
        Reset(VotingFile);
        Seek(VotingFile,(RecNumToDelete - 1));
        Read(VotingFile,TempTopic1);
        Close(VotingFile);
        LastError := IOResult;
        Print('%LF^1Voting topic: ^5'+TempTopic1.Question1);
        IF (TempTopic1.Question2 <> '') THEN
          Print('^1'+PadLeftStr('',12)+': ^5'+TempTopic1.Question2);
        IF PYNQ('%LFAre you sure you want to delete it? ',0,FALSE) THEN
        BEGIN
          Print('%LF[> Deleting voting topic record ...');
          Dec(RecNumToDelete);
          Reset(VotingFile);
          IF (RecNumToDelete >= 0) AND (RecNumToDelete <= (FileSize(VotingFile) - 2)) THEN
            FOR RecNum := RecNumToDelete TO (FileSize(VotingFile) - 2) DO
            BEGIN
              Seek(VotingFile,(RecNum + 1));
              Read(VotingFile,Topic);
              Seek(VotingFile,RecNum);
              Write(VotingFile,Topic);
            END;
          Seek(VotingFile,(FileSize(VotingFile) - 1));
          Truncate(VotingFile);
          Close(VotingFile);
          LastError := IOResult;
          SysOpLog('* Deleted topic: ^5'+TempTopic1.Question1);
          IF (Topic.Question2 <> '') THEN
            SysOpLog(PadLeftStr('',15)+': ^5'+TempTopic1.Question2);
          Reset(UserFile);
          FOR RecNum := 1 TO (FileSize(UserFile) - 1) DO
          BEGIN
            Seek(UserFile,RecNum);
            Read(UserFile,User);
            Move(User.Vote[RecNumToDelete + 1],User.Vote[RecNumToDelete],(MaxVotes - RecNumToDelete));
            User.Vote[25] := 0;
            Seek(UserFile,RecNum);
            Write(UserFile,User);
          END;
          Close(UserFile);
          LastError := IOResult;
          Move(ThisUser.Vote[RecNumToDelete + 1],ThisUser.Vote[RecNumToDelete],(MaxVotes - RecNumToDelete));
          ThisUser.Vote[25] := 0;
          Dec(NumVotes);
        END;
      END;
    END;
  END;

  PROCEDURE CheckTopic(Topic: VotingRecordType; StartErrMsg,EndErrMsg: Byte; VAR Ok: Boolean);
  VAR
    Counter,
    Counter1: Byte;
  BEGIN
    FOR Counter := StartErrMsg TO EndErrMsg DO
      CASE Counter OF
        1 : IF (Topic.Question1 = '') OR (Topic.Question1 = '<< New Voting Topic >>') THEN
            BEGIN
              Print('%LF^7The question is invalid!^1');
              OK := FALSE;
            END;
        2 : IF (Topic.ChoiceNumber = 0) THEN
            BEGIN
              Print('%LF^7You must setup choices for your topic!^1');
              OK := FALSE;
            END;
      END;
  END;

  PROCEDURE EditTopic(TempTopic1: VotingRecordType; VAR Topic: VotingRecordType; VAR Cmd1: Char;
                      VAR RecNumToEdit: Byte; VAR Changed: Boolean; Editing: Boolean);
  VAR
    User: UserRecordType;
    CmdStr: AStr;
    Unum: Integer;
    Ok: Boolean;
  BEGIN
    WITH Topic DO
      REPEAT
        IF (Cmd1 <> '?') THEN
        BEGIN
          Abort := FALSE;
          Next := FALSE;
          CLS;
          IF (Editing) THEN
            PrintACR('^5Editing voting topic #'+IntToStr(RecNumToEdit)+' of '+IntToStr(NumVotes))
          ELSE
            PrintACR('^5Inserting voting topic #'+IntToStr(RecNumToEdit)+' of '+IntToStr(NumVotes + 1));
          NL;
          PrintACR('^11. Topic        : ^5'+Question1);
          IF (Question2 <> '') THEN
            PrintACR('^1'+PadLeftStr('',16)+': ^5'+Question2);
          PrintACR('^12. Creator      : ^5'+CreatedBy);
          PrintACR('^13. ACS to vote  : ^5'+AOnOff(ACS = '','*None*',ACS));
          PrintACR('^14. ACS to add   : ^5'+AOnOff(AddAnswersACS = '','*None*',AddAnswersACS));
          PrintACR('^15. Total votes  : ^5'+IntToStr(NumVotedQuestion));
          Print('%LF^1[Choices on this topic: ^5'+IntToStr(ChoiceNumber)+'^1]');
        END;
        IF (NOT Editing) THEN
          CmdStr := '12345C'
        ELSE
          CmdStr := '12345C[]FJL';
        LOneK('%LFModify menu [^5C^4=^5Choice Editor^4,^5?^4=^5Help^4]: ',Cmd1,'Q?'+CmdStr+^M,TRUE,TRUE);
        CASE Cmd1 OF
          '1' : BEGIN
                  REPEAT
                    TempTopic1.Question1 := Question1;
                    Ok := TRUE;
                    InputWNWC('%LFNew topic: ',Question1,(SizeOf(Question1) - 1),Changed);
                    CheckTopic(Topic,1,1,Ok);
                    IF (NOT Ok) THEN
                      Question1 := TempTopic1.Question1;
                  UNTIL (Ok) OR (HangUp);
                  IF (Question1 <> '') THEN
                    InputWNWC(PadLeftStr('',9)+': ',Question2,(SizeOf(Question2) - 1),Changed);
                END;
          '2' : BEGIN
                  Print('%LF^5New creator of this topic (1-'+IntToStr(MaxUsers - 1)+')?^1');
                  Print('%LFEnter User Number, Name, or Partial Search String.');
                  Prt(': ');
                  lFindUserWS(Unum);
                  IF (Unum < 1) THEN
                    PauseScr(FALSE)
                  ELSE
                  BEGIN
                    LoadURec(User,UNum);
                    IF (CreatedBy <> Caps(User.Name)) THEN
                      IF (PYNQ('%LFSet the new creator name to '+Caps(User.Name)+'? ',0,FALSE)) THEN
                      BEGIN
                        CreatedBy := Caps(User.Name);
                        Changed := TRUE;
                      END;
                  END;
                END;
          '3' : InputWN1('%LFNew voting ACS: ',ACS,(SizeOf(ACS) - 1),[InterActiveEdit],Changed);
          '4' : IF PYNQ('%LFAllow other users to add choices? ',0,FALSE) THEN
                  AddAnswersACS := ACS
                ELSE
                  AddAnswersACS := General.AddChoice;
          '5' : InputIntegerWOC('%LFNew number of voters',NumVotedQuestion,[DisplayValue,NumbersOnly],0,(MaxUsers - 1));
          'C' : ChoiceEditor(TempTopic1,Topic,Cmd1,RecNumToEdit,Changed);
          '[' : IF (RecNumToEdit > 1) THEN
                  Dec(RecNumToEdit)
                ELSE
                BEGIN
                  Messages(2,0,'');
                  Cmd1 := #0;
                END;
          ']' : IF (RecNumToEdit < NumVotes) THEN
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
                  InputByteWOC('%LFJump to entry',RecNumToEdit,[NumbersOnly],1,NumVotes);
                  IF (RecNumToEdit < 1) OR (RecNumToEdit > NumVotes) THEN
                    Cmd1 := #0;
                END;
          'L' : IF (RecNumToEdit <> NumVotes) THEN
                  RecNumToEdit := NumVotes
                ELSE
                BEGIN
                  Messages(3,0,'');
                  Cmd1 := #0;
                END;
          '?' : BEGIN
                  Print('%LF^1<^3CR^1>Redisplay current screen');
                  Print('^31^1-^35^1,^3C^1:Modify item');
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

  PROCEDURE InsertTopic(TempTopic1: VotingRecordType; Cmd1: Char; RecNumToInsertBefore: Byte);
  VAR
    RecNumToEdit: Byte;
    Ok,
    Changed: Boolean;
  BEGIN
    IF (NumVotes = MaxVotes) THEN
      Messages(5,MaxVotes,'voting topics')
    ELSE IF (PYNQ('%LFAdd voting topic #'+IntToStr(NumVotes + 1)+'? ',0,FALSE)) THEN
    BEGIN
      Reset(VotingFile);
      InitTopicVars(TempTopic1);
      RecNumToInsertBefore := (FileSize(VotingFile) + 1);
      IF (RecNumToInsertBefore = 1) THEN
        RecNumToedit := 1
      ELSE IF (RecNumToInsertBefore = (NumVotes + 1)) THEN
        RecNumToEdit := (NumVotes + 1)
      ELSE
        RecNumToEdit := RecNumToInsertBefore;
      REPEAT
        OK := TRUE;
        EditTopic(TempTopic1,TempTopic1,Cmd1,RecNumToEdit,Changed,FALSE);
        CheckTopic(TempTopic1,1,2,Ok);
        IF (NOT OK) THEN
          IF (NOT PYNQ('%LFContinue inserting topic? ',0,TRUE)) THEN
            Abort := TRUE;
      UNTIL (OK) OR (Abort) OR (HangUp);
      IF (NOT Abort) AND (PYNQ('%LFIs this what you want? ',0,FALSE)) THEN
      BEGIN
        Print('%LF[> Inserting voting topic record ...');
        Seek(VotingFile,FileSize(VotingFile));
        Write(VotingFile,TempTopic1);
        Close(VotingFile);
        LastError := IOResult;
        Inc(NumVotes);
        SysOpLog('* Inserted topic: ^5'+TempTopic1.Question1);
        IF (TempTopic1.Question2 <> '') THEN
          SysOpLog(PadLeftStr('',16)+': ^5'+TempTopic1.Question2);
      END;
    END;
  END;

  PROCEDURE ModifyTopic(TempTopic1: VotingRecordType; Cmd1: Char; RecNumToEdit: Byte);
  VAR
    SaveRecNumToEdit: Byte;
    Ok,
    Changed: Boolean;
  BEGIN
    IF (NumVotes = 0) THEN
      Messages(4,0,'voting topics')
    ELSE
    BEGIN
      RecNumToEdit := 0;
      InputByteWOC('%LFModify which topic',RecNumToEdit,[NumbersOnly],1,NumVotes);
      IF (RecNumToEdit >= 1) AND (RecNumToEdit <= NumVotes) THEN
      BEGIN
        SaveRecNumToEdit := 0;
        Cmd1 := #0;
        Reset(VotingFile);
        WHILE (Cmd1 <> 'Q') AND (NOT HangUp) DO
        BEGIN
          IF (SaveRecNumToEdit <> RecNumToEdit) THEN
          BEGIN
            Seek(VotingFile,(RecNumToEdit - 1));
            Read(VotingFile,Topic);
            SaveRecNumToEdit := RecNumToEdit;
            Changed := FALSE;
          END;
          REPEAT
            Ok := TRUE;
            EditTopic(TempTopic1,Topic,Cmd1,RecNumToEdit,Changed,TRUE);
            CheckTopic(Topic,1,2,Ok);
            IF (NOT OK) THEN
            BEGIN
              PauseScr(FALSE);
              IF (RecNumToEdit <> SaveRecNumToEdit) THEN
                RecNumToEdit := SaveRecNumToEdit;
            END;
          UNTIL (Ok) OR (HangUp);
          IF (Changed) THEN
          BEGIN
            Seek(VotingFile,(SaveRecNumToEdit - 1));
            Write(VotingFile,Topic);
            Changed := FALSE;
            SysOpLog('* Modified topic: ^5'+Topic.Question1);
            IF (Topic.Question2 <> '') THEN
              SysOpLog(PadLeftStr('',16)+': ^5'+Topic.Question2);
          END;
        END;
        Close(VotingFile);
        LastError := IOResult;
      END;
    END;
  END;

  PROCEDURE ResetTopic(RecNumToReset: Byte);
  VAR
    User: UserRecordType;
    RecNum: Byte;
    UNum: Integer;
  BEGIN
    IF (NumVotes = 0) THEN
      Messages(4,0,'voting topics')
    ELSE
    BEGIN
      RecNumToReset := 0;
      InputByteWOC('%LFReset which topic',RecNumToReset,[NumbersOnly],1,NumVotes);
      IF (RecNumToReset >= 1) AND (RecNumToReset <= NumVotes) THEN
      BEGIN
        Reset(VotingFile);
        Seek(VotingFile,(RecNumToReset - 1));
        Read(VotingFile,Topic);
        Close(VotingFile);
        Print('%LF^1Voting topic: ^5'+Topic.Question1);
        IF (Topic.Question2 <> '') THEN
          Print('^1'+PadLeftStr('',12)+': ^5'+Topic.Question2);
        IF PYNQ('%LFAre you sure you want to reset it? ',0,FALSE) THEN
        BEGIN
          Print('%LF[> Resetting voting topic record ...');
          Reset(VotingFile);
          Seek(VotingFile,(RecNumToReset - 1));
          Read(VotingFile,Topic);
          Topic.NumVotedQuestion := 0;
          FOR RecNum := 1 TO Topic.ChoiceNumber DO
            Topic.Answers[RecNum].NumVotedAnswer := 0;
          Seek(VotingFile,(RecNumToReset - 1));
          Write(VotingFile,Topic);
          Close(VotingFile);
          Reset(UserFile);
          FOR UNum := 1 TO (FileSize(UserFile) - 1) DO
          BEGIN
            Seek(UserFile,Unum);
            Read(UserFile,User);
            User.Vote[RecNumToReset] := 0;
            Seek(UserFile,UNum);
            Write(UserFile,User);
         END;
         Close(UserFile);
         ThisUser.Vote[RecNumToReset] := 0;
         SysOpLog('* Reset topic: ^5'+Topic.Question1);
         IF (Topic.Question2 <> '') THEN
           SysOpLog(PadLeftStr('',13)+': ^5'+Topic.Question2);
       END;
      END;
    END;
  END;

  PROCEDURE RecalculateTopics;
  VAR
    User: UserRecordType;
    RecNum,
    RecNum1: Byte;
    UNum: Integer;
  BEGIN
    IF (NumVotes = 0) THEN
      Messages(4,0,'voting topics')
    ELSE IF (PYNQ('%LFRecalculate all voting topics? ',0,FALSE)) THEN
    BEGIN
      Print('%LF[> Recalculating all voting topics ...');
      Reset(VotingFile);
      FOR RecNum := 1 TO NumVotes DO
      BEGIN
        Reset(VotingFile);
        Seek(VotingFile,(RecNum - 1));
        Read(VotingFile,Topic);
        Topic.NumVotedQuestion := 0;
        FOR RecNum1 := 1 TO Topic.ChoiceNumber DO
          Topic.Answers[RecNum1].NumVotedAnswer := 0;
        Seek(VotingFile,(RecNum - 1));
        Write(VotingFile,Topic);
      END;
      Close(VotingFile);
      Reset(VotingFile);
      Reset(UserFile);
      FOR UNum := 1 TO (FileSize(UserFile) - 1) DO
      BEGIN
        Seek(UserFile,Unum);
        Read(UserFile,User);
        IF (Deleted IN User.SFlags) THEN
        BEGIN
          FOR RecNum := 1 TO MaxVotes DO
            User.Vote[RecNum] := 0;
        END
        ELSE
        BEGIN
          FOR RecNum := 1 TO NumVotes DO
            IF (User.Vote[RecNum] <> 0) THEN
            BEGIN
              Seek(VotingFile,(RecNum - 1));
              Read(VotingFile,Topic);
              Inc(Topic.NumVotedQuestion);
              Inc(Topic.Answers[User.Vote[RecNum]].NumVotedAnswer);
              Seek(VotingFile,(RecNum - 1));
              Write(VotingFile,Topic);
            END;
        END;
        Seek(UserFile,Unum);
        Write(UserFile,User);
      END;
      Close(UserFile);
      Close(VotingFile);
      SysOpLog('* Recalculated all voting topics.');
    END;
  END;

  PROCEDURE ListTopics(VAR RecNumToList1: Byte);
  VAR
    NumDone: Byte;
  BEGIN
    IF (RecNumToList1 < 1) OR (RecNumToList1 > NumVotes) THEN
      RecNumToList1 := 1;
    Abort := FALSE;
    Next := FALSE;
    CLS;
    PrintACR('^0##^4:^3Votes^4:^3Topic');
    PrintACR('^4==:=====:======================================================================');
    Reset(VotingFile);
    NumDone := 0;
    WHILE (NumDone < (PageLength - 5)) AND (RecNumToList1 >= 1) AND (RecNumToList1 <= NumVotes)
          AND (NOT Abort) AND (NOT HangUp) DO
    BEGIN
      Seek(VotingFile,(RecNumToList1 - 1));
      Read(VotingFile,Topic);
      WITH Topic DO
        PrintACR('^0'+PadRightInt(RecNumToList1,2)+
                 '^3'+PadRightInt(NumVotedQuestion,6)+
                 '^5 '+Question1);
      WKey;
      Inc(RecNumToList1);
      Inc(NumDone);
    END;
    Close(VotingFile);
    LastError := IOResult;
    IF (NumVotes = 0) THEN
      Print('*** No voting topics defined ***');
  END;

BEGIN
  SaveTempPause := TempPause;
  TempPause := FALSE;
  RecNumToList := 1;
  Cmd := #0;
  REPEAT
    IF (Cmd <> '?') THEN
      ListTopics(RecNumToList);
    LOneK('%LFVoting topic editor [^5?^4=^5Help^4]: ',Cmd,'QDIMRS?'^M,TRUE,TRUE);
    CASE Cmd OF
      ^M  : IF (RecNumToList < 1) OR (RecNumToList > NumVotes) THEN
              RecNumToList := 1;
      'D' : DeleteTopic(TempTopic,RecNumToList);
      'I' : InsertTopic(TempTopic,Cmd,RecNumToList);
      'M' : ModifyTopic(TempTopic,Cmd,RecNumToList);
      'R' : ResetTopic(RecNumToList);
      'S' : RecalculateTopics;
      '?' : BEGIN
              Print('%LF^1<^3CR^1>Next screen or redisplay current screen');
              Print('^1(^3?^1)Help/First voting topic');
              LCmds(20,3,'Delete voting topic','Insert voting topic');
              LCmds(20,3,'Modify voting topic','Quit');
              LCmds(20,3,'Reset voting topic','SRecalculate voting topics');
            END;
    END;
    IF (Cmd <> ^M) THEN
      RecNumToList := 1;
  UNTIL (Cmd = 'Q') OR (HangUp);
  TempPause := SaveTempPause;
  LastError := IOResult;
END;

END.
