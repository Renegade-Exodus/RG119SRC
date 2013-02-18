{$IFDEF WIN32}
{$I DEFINES.INC}
{$ENDIF}

{$A+,B-,D+,E-,F+,I-,L+,N-,O+,R-,S+,V-}

UNIT Vote;

INTERFACE

USES
  Common;

FUNCTION GetTopics: Byte;
FUNCTION UnVotedTopics: Byte;
PROCEDURE ListTopics(UsePause: Boolean);
PROCEDURE VoteAll;
PROCEDURE VoteOne(TopicNum: Byte);
PROCEDURE Results(ListVoters: Boolean);
PROCEDURE TrackUser;
PROCEDURE AddTopic;

IMPLEMENTATION

USES
  Common5,
  MiscUser;

VAR
  AvailableTopics: ARRAY [1..25] OF Byte;

FUNCTION GetTopics: Byte;
VAR
  TopicNum,
  NumTopics: Byte;
BEGIN
  FillChar(AvailableTopics,SizeOf(AvailableTopics),0);
  Abort := FALSE;
  Next := FALSE;
  NumTopics := 0;
  Reset(VotingFile);
  TopicNum := 1;
  WHILE (TopicNum <= NumVotes) AND (NOT Abort) AND (NOT HangUp) DO
  BEGIN
    Seek(VotingFile,(TopicNum - 1));
    Read(VotingFile,Topic);
    IF AACS(Topic.ACS) THEN
    BEGIN
      Inc(NumTopics);
      AvailableTopics[NumTopics] := TopicNum;
    END;
    Inc(TopicNum);
  END;
  Close(VotingFile);
  LastError := IOResult;
  GetTopics := NumTopics;
END;

FUNCTION UnVotedTopics: Byte;
VAR
  TopicNum,
  NumTopics: Byte;
BEGIN
  Abort := FALSE;
  Next := FALSE;
  NumTopics := 0;
  Reset(VotingFile);
  TopicNum := 1;
  WHILE (TopicNum <= NumVotes) AND (NOT Abort) AND (NOT HangUp) DO
  BEGIN
    Seek(VotingFile,(TopicNum - 1));
    Read(VotingFile,Topic);
    IF AACS(Topic.ACS) AND (ThisUser.Vote[TopicNum] = 0) THEN
      Inc(NumTopics);
    Inc(TopicNum);
  END;
  Close(VotingFile);
  LastError := IOResult;
  UnVotedTopics := NumTopics;
END;

PROCEDURE ListTopics(UsePause: Boolean);
VAR
  TopicNum,
  NumTopics: Byte;
BEGIN
  NumTopics := GetTopics;
  IF (NumTopics = 0) THEN
  BEGIN
    NL;
    Print('There are no topics available.');
    PauseScr(FALSE);
    Exit;
  END;
  Abort := FALSE;
  Next := FALSE;
  (*
  CLS;
  PrintACR('|03ÚÄÄÄÄÄÂÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿');
  PrintACR('³|11|17 Num |03|16³|11|17Votes|03|16³|11|17 Choice                                   '+
           '                       |03|16³');
  PrintACR('ÀÄÄÄÄÄÁÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ');
  *)
  lRGLngStr(61,FALSE);
  Reset(VotingFile);
  TopicNum := 1;
  WHILE (TopicNum <= NumTopics) AND (NOT Abort) AND (NOT HangUp) DO
  BEGIN
    Seek(VotingFile,(AvailableTopics[TopicNum] - 1));
    Read(VotingFile,Topic);
    PrintACR('|07'+PadRightInt(TopicNum,5)+
             '|10'+PadRightInt(Topic.NumVotedQuestion,7)+
             '|14  '+Topic.Question1);
    IF (Topic.Question2 <> '') THEN
      PrintACR(PadRightStr('',12)+'|14  '+Topic.Question2);
    WKey;
    Inc(TopicNum);
  END;
  Close(VotingFile);
  LastError := IOResult;
  IF (UsePause) THEN
  BEGIN
    NL;
    PauseScr(FALSE);
  END;
END;

PROCEDURE TopicResults(TopicNum: Byte; User: UserRecordType; ListVoters: Boolean);
VAR
  ChoiceNum: Byte;
  NumVoted,
  UNum,
  TempMaxUsers: Integer;
BEGIN
  Reset(VotingFile);
  Seek(VotingFile,(TopicNum - 1));
  Read(VotingFile,Topic);
  Close(VotingFile);
  Abort := FALSE;
  Next := FALSE;
  CLS;
  PrintACR('^5Topic: ^3'+Topic.Question1);
  IF (Topic.Question2 <> '') THEN
    PrintACR('^5     : ^3'+Topic.Question2);
  NL;
  PrintACR('^5Created By: ^3'+Topic.CreatedBy);
  NL;
  (*
  PrintACR('|03ÚÄÄÄÂÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿');
  PrintACR('³|11|17 N |03|16³|11|17  %  |03|16'+
           '³|11|17 Choice                                                            |03|16³');
  PrintACR('ÀÄÄÄÁÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ');
  *)
  lRGLngStr(62,FALSE);
  ChoiceNum := 1;
  WHILE (ChoiceNum <= Topic.ChoiceNumber) AND (NOT Abort) AND (NOT HangUp) DO
  BEGIN
    PrintACR('^3'+PadRightInt(Topic.Answers[ChoiceNum].NumVotedAnswer,4)+
             CTP(Topic.Answers[ChoiceNum].NumVotedAnswer,Topic.NumVotedQuestion)+
             AOnOff(User.Vote[TopicNum] = ChoiceNum,' |12',' |10')+
             PadRightInt(ChoiceNum,2)+
             '.'+Topic.Answers[ChoiceNum].Answer1);
    IF (Topic.Answers[ChoiceNum].Answer2 <> '') THEN
      PrintACR(PadLeftStr('',14)+Topic.Answers[ChoiceNum].Answer2);

    IF (ListVoters) AND (Topic.Answers[ChoiceNum].NumVotedAnswer > 0) THEN
    BEGIN
      NumVoted := Topic.Answers[ChoiceNum].NumVotedAnswer;
      Reset(UserFile);
      TempMaxUsers := (MaxUsers - 1);
      UNum := 1;
      WHILE (UNum <= TempMaxUsers) AND (NumVoted > 0) AND (NOT Abort) AND (NOT HangUp) DO
      BEGIN
        LoadURec(User,UNum);
        IF (User.Vote[TopicNum] = ChoiceNum) THEN
        BEGIN
          PrintACR(PadLeftStr('^1',14)+Caps(User.Name)+' #'+IntToStr(UNum));
          Dec(NumVoted);
        END;
        Inc(UNum);
      END;
      Close(UserFile);
    END;
    Inc(ChoiceNum);
  END;
  LastError := IOResult;
  NL;
  PauseScr(FALSE);
END;

PROCEDURE GoVote(TopicNum: Byte);
VAR
  InputStr: Str2;
  ChoiceNum: Byte;
BEGIN
  Reset(VotingFile);
  Seek(VotingFile,(TopicNum - 1));
  Read(VotingFile,Topic);
  Abort := FALSE;
  Next := FALSE;
  CLS;
  Print('^5Renegade Voting:');
  NL;
  PrintACR('^5Topic: ^3'+Topic.Question1);
  IF (Topic.Question2 <> '') THEN
    PrintACR('^5     : ^3'+Topic.Question2);
  NL;
  PrintACR('^5Created by: ^3'+Topic.CreatedBy);
  NL;
  ChoiceNum := 1;
  WHILE (ChoiceNum <= Topic.ChoiceNumber) AND (NOT Abort) AND (NOT HangUp) DO
  BEGIN
    PrintACR('^3'+PadRightInt(ChoiceNum,3)+'.^9 '+Topic.Answers[ChoiceNum].Answer1);
    IF (Topic.Answers[ChoiceNum].Answer2 <> '') THEN
      PrintACR('     ^9'+Topic.Answers[ChoiceNum].Answer2);
    Inc(ChoiceNum);
  END;
  Dec(ChoiceNum);
  IF (AACS(Topic.AddAnswersACS)) AND (ChoiceNum < 25) THEN
  BEGIN
    Inc(ChoiceNum);
    Print('^3'+PadRightInt(ChoiceNum,3)+'.^9 <Pick this one to add your own choice>');
  END;
  IF (ThisUser.Vote[TopicNum] >= 1) AND (ThisUser.Vote[TopicNum] <= Topic.ChoiceNumber) THEN
  BEGIN
    NL;
    IF PYNQ('Change your vote? ',0,FALSE) THEN
    BEGIN
      Dec(Topic.Answers[ThisUser.Vote[TopicNum]].NumVotedAnswer);
      Dec(Topic.NumVotedQuestion);
      ThisUser.Vote[TopicNum] := 0;
      Seek(VotingFile,(TopicNum - 1));
      Write(VotingFile,Topic);
    END
    ELSE
    BEGIN
      Close(VotingFile);
      Exit;
    END;
  END;
  NL;
  Prt('Your choice: ');
  MPL(Length(IntToStr(ChoiceNum)));
  ScanInput(InputStr,'Q'^M);
  ChoiceNum := StrToInt(InputStr);
  IF (ChoiceNum = (Topic.ChoiceNumber + 1)) AND AACS(Topic.AddAnswersACS) AND (ChoiceNum <= 25) THEN
  BEGIN
    NL;
    Prt('Choice '+IntToStr(ChoiceNum)+': ');
    MPL(65);
    InputWC(Topic.Answers[ChoiceNum].Answer1,65);
    IF (Topic.Answers[ChoiceNum].Answer1 <> '') THEN
    BEGIN
      Prt(PadLeftStr('',7+Length(IntToStr(ChoiceNum)))+': ');
      MPL(65);
      InputWC(Topic.Answers[ChoiceNum].Answer2,65);
      NL;
      IF (NOT PYNQ('Add this choice? ',0,FALSE)) THEN
      BEGIN
        Topic.Answers[ChoiceNum].Answer1 := '';
        Topic.Answers[ChoiceNum].Answer2 := '';
      END
      ELSE
      BEGIN
        Inc(Topic.ChoiceNumber);
        Topic.Answers[ChoiceNum].NumVotedAnswer := 1;
        Inc(Topic.NumVotedQuestion);
        ThisUser.Vote[TopicNum] := ChoiceNum;
        SL1('Added choice to '+Topic.Question1+':');
        SysOpLog(Topic.Answers[ChoiceNum].Answer1);
        IF (Topic.Answers[ChoiceNum].Answer2 <> '') THEN
          SysOpLog(Topic.Answers[ChoiceNum].Answer2);
      END;
    END;
  END
  ELSE IF (ChoiceNum >= 1) AND (ChoiceNum <= Topic.ChoiceNumber) THEN
  BEGIN
    Inc(Topic.Answers[ChoiceNum].NumVotedAnswer);
    Inc(Topic.NumVotedQuestion);
    ThisUser.Vote[TopicNum] := ChoiceNum;
  END;
  Seek(VotingFile,(TopicNum - 1));
  Write(VotingFile,Topic);
  Close(VotingFile);
  SaveURec(ThisUser,UserNum);
  NL;
  IF PYNQ('See results? ',0,TRUE) THEN
    TopicResults(TopicNum,ThisUser,FALSE);
  IF (InputStr = 'Q') THEN
    Abort := TRUE;
  LastError := IOResult;
END;

PROCEDURE VoteAll;
VAR
  TopicNum,
  NumTopics: Byte;
  Found: Boolean;
BEGIN
  IF (RVoting IN ThisUser.Flags) THEN
  BEGIN
    NL;
    Print('You are restricted from voting.');
    PauseScr(FALSE);
    Exit;
  END;
  NumTopics := GetTopics;
  IF (NumTopics = 0) THEN
  BEGIN
    NL;
    Print('There are no topics available.');
    PauseScr(FALSE);
    Exit;
  END;
  Abort := FALSE;
  Next := FALSE;
  Found := FALSE;
  TopicNum := 1;
  WHILE (TopicNum <= NumTopics) AND (NOT Abort) AND (NOT HangUp) DO
  BEGIN
    IF (ThisUser.Vote[AvailableTopics[TopicNum]] = 0) THEN
    BEGIN
      GoVote(AvailableTopics[TopicNum]);
      Found := TRUE;
    END;
    Inc(TopicNum);
  END;
  IF (NOT Found) THEN
  BEGIN
    NL;
    Print('You have voted on all available topics.');
    PauseScr(FALSE);
  END;
END;

PROCEDURE VoteOne(TopicNum: Byte);
VAR
  NumTopics: Byte;
BEGIN
  IF (RVoting IN ThisUser.Flags) THEN
  BEGIN
    NL;
    Print('You are restricted from voting.');
    PauseScr(FALSE);
    Exit;
  END;
  NumTopics := GetTopics;
  IF (NumTopics = 0) THEN
  BEGIN
    NL;
    Print('There are no topics available.');
    PauseScr(FALSE);
    Exit;
  END;
  IF (TopicNum < 1) AND (TopicNum > NumTopics) THEN
  BEGIN
    NL;
    Print('The range must be from 1 to '+IntToStr(NumTopics)+'.');
    PauseScr(FALSE);
    Exit;
  END;
  IF (ThisUser.Vote[AvailableTopics[TopicNum]] > 0) AND (NOT AACS(General.ChangeVote)) THEN
  BEGIN
    NL;
    Print('You can only vote once on this topic.');
    PauseScr(FALSE);
    Exit;
  END;
  GoVote(AvailableTopics[TopicNum]);
END;

PROCEDURE Results(ListVoters: Boolean);
VAR
  InputStr: Str2;
  TopicNum,
  NumTopics: Byte;
BEGIN
  NumTopics := GetTopics;
  IF (NumTopics = 0) THEN
  BEGIN
    NL;
    Print('There are no topics available.');
    PauseScr(FALSE);
    Exit;
  END;
  REPEAT
    NL;
    Prt('Results of which topic? (^51^4-^5'+IntToStr(NumTopics)+'^4) [^5?^4=^5List^4]: ');
    MPL(Length(IntToStr(NumTopics)));
    ScanInput(InputStr,^M'?');
    IF (InputStr = '?') THEN
      ListTopics(FALSE);
  UNTIL (InputStr <> '?') OR (HangUp);
  IF (InputStr <> ^M) THEN
  BEGIN
    TopicNum := StrToInt(InputStr);
    IF (TopicNum >= 1) AND (TopicNum <= NumTopics) THEN
      TopicResults(AvailableTopics[TopicNum],ThisUser,ListVoters)
    ELSE
    BEGIN
      NL;
      Print('^1The range must be from 1 to '+IntToStr(NumTopics)+'.');
      PauseScr(FALSE);
    END;
  END;
END;

PROCEDURE TrackUser;
VAR
  User: UserRecordType;
  NumTopics,
  TopicNum: Byte;
  Unum: Integer;
  Found: Boolean;
BEGIN
  NumTopics := GetTopics;
  IF (NumTopics = 0) THEN
  BEGIN
    NL;
    Print('There are no topics available.');
    PauseScr(FALSE);
    Exit;
  END;
  NL;
  Print('Track voting for which user (1-'+IntToStr(MaxUsers - 1)+')?');
  NL;
  Print('Enter User Number, Name, or Partial Search String.');
  Prt(': ');
  lFindUserWS(Unum);
  IF (Unum < 1) THEN
    PauseScr(FALSE)
  ELSE
  BEGIN
    LoadURec(User,Unum);
    IF (RVoting IN User.Flags) THEN
    BEGIN
      NL;
      Print('^1This user is restricted from voting.');
      PauseScr(FALSE);
      Exit;
    END;
    Abort := FALSE;
    Next := FALSE;
    Found := FALSE;
    TopicNum := 1;
    WHILE (TopicNum <= NumTopics) AND (NOT Abort) AND (NOT HangUp) DO
    BEGIN
      IF (User.Vote[TopicNum] > 0) THEN
      BEGIN
        TopicResults(TopicNum,User,FALSE);
        Found := TRUE;
      END;
      Inc(TopicNum);
    END;
    IF (NOT Found) THEN
    BEGIN
      NL;
      Print('^1This user has not voted on any topics.');
      PauseScr(FALSE);
    END;
  END;
END;

PROCEDURE AddTopic;
VAR
  ChoiceNum: Byte;
BEGIN
  IF (NumVotes = MaxVotes) THEN
  BEGIN
    NL;
    Prt('No room for additional topics!');
    PauseScr(FALSE);
    Exit;
  END;
  FillChar(Topic,SizeOf(Topic),'0');
  CLS;
  Print('^3Voting addition:');
  NL;
  Print('^9Now enter your topic.  You have up to two lines for your topic.');
  Print('^9Press [Enter] on a blank line to leave blank or abort.');
  NL;
  Prt('Topic: ');
  MPL(SizeOf(Topic.Question1) - 1);
  InputWC(Topic.Question1,SizeOf(Topic.Question1) - 1);
  IF (Topic.Question1 <> '') THEN
  BEGIN
    Prt(PadLeftStr('',5)+': ');
    MPL(SizeOf(Topic.Question2) - 1);
    InputWC(Topic.Question2,SizeOf(Topic.Question2) - 1);
    NL;
    IF PYNQ('Are you sure? ',0,FALSE) THEN
    BEGIN
      Topic.CreatedBy := Caps(ThisUser.Name);
      Topic.NumVotedQuestion := 0;
      Topic.ACS := 'VV';
      NL;
      IF PYNQ('Allow other users to add choices? ',0,FALSE) THEN
        Topic.AddAnswersACS := Topic.ACS
      ELSE
        Topic.AddAnswersACS := General.AddChoice;
      NL;
      Print('^9Now enter the choices.  You have up to two lines for each');
      Print('choice. Press [Enter] on a blank first choice line to end.');
      NL;
      Topic.ChoiceNumber := 0;
      Abort := FALSE;
      Next := FALSE;
      ChoiceNum := 0;
      WHILE (ChoiceNum < 25) AND (NOT Abort) AND (NOT HangUp) DO
      BEGIN
        Inc(ChoiceNum);
        Prt('Choice '+PadRightInt(ChoiceNum,2)+': ');
        MPL(SizeOf(Topic.Answers[ChoiceNum].Answer1) - 1);
        InputWC(Topic.Answers[ChoiceNum].Answer1,SizeOf(Topic.Answers[ChoiceNum].Answer1) - 1);
        IF (Topic.Answers[ChoiceNum].Answer1 = '') THEN
          Abort := TRUE
        ELSE
        BEGIN
          Inc(Topic.ChoiceNumber);
          Prt(PadLeftStr('',9)+': ');
          MPL(SizeOf(Topic.Answers[ChoiceNum].Answer2) - 1);
          InputWC(Topic.Answers[ChoiceNum].Answer2,SizeOf(Topic.Answers[ChoiceNum].Answer2) - 1);
          Topic.Answers[ChoiceNum].NumVotedAnswer := 0;
        END;
      END;
      IF ((ChoiceNum > 1) OR (Topic.ChoiceNumber > 0)) THEN
      BEGIN
        NL;
        IF  (PYNQ('Add this topic? ',0,FALSE)) THEN
        BEGIN
          Reset(VotingFile);
          Seek(VotingFile,FileSize(VotingFile));
          Write(VotingFile,Topic);
          Close(VotingFile);
          Inc(NumVotes);
          SysOpLog('Added voting topic: '+Topic.Question1);
          IF (Topic.Question2 <> '') THEN
            SysOpLog('                  : '+Topic.Question2);
        END;
      END;
    END;
  END;
  LastError := IOResult;
  NL;
  PauseScr(FALSE);
END;

END.
