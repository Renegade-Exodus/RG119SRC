{$IFDEF WIN32}
{$I DEFINES.INC}
{$ENDIF}

{$A+,B-,D+,E-,F+,I-,L+,N-,O+,R-,S+,V-}

UNIT ShortMsg;

INTERFACE

USES
  Common;

PROCEDURE ReadShortMessage;
PROCEDURE SendShortMessage(CONST UNum: Integer; CONST Message: AStr);

IMPLEMENTATION

PROCEDURE ReadShortMessage;
VAR
  ShortMsgFile: FILE OF ShortMessageRecordType;
  ShortMsg: ShortMessageRecordType;
  RecNum: LongInt;
BEGIN
  Assign(ShortMsgFile,General.DataPath+'SHORTMSG.DAT');
  Reset(ShortMsgFile);
  IF (IOResult = 0) THEN
  BEGIN
    UserColor(1);
    RecNum := 0;
    WHILE (RecNum <= (FileSize(ShortMsgFile) - 1)) AND (NOT HangUp) DO
    BEGIN
      Seek(ShortMsgFile,RecNum);
      Read(ShortMsgFile,ShortMsg);
      IF (ShortMsg.Destin = UserNum) THEN
      BEGIN
        Print(ShortMsg.Msg);
        ShortMsg.Destin := -1;
        Seek(ShortMsgFile,RecNum);
        Write(ShortMsgFile,ShortMsg);
      END;
      Inc(RecNum);
    END;
    Close(ShortMsgFile);
    UserColor(1);
  END;
  Exclude(ThisUser.Flags,SMW);
  SaveURec(ThisUser,UserNum);
  LastError := IOResult;
END;

PROCEDURE SendShortMessage(CONST UNum: Integer; CONST Message: AStr);
VAR
  ShortMsgFile: FILE OF ShortMessageRecordType;
  ShortMsg: ShortMessageRecordType;
  User: UserRecordType;
BEGIN
  IF (UNum >= 1) AND (UNum <= (MaxUsers - 1)) THEN
  BEGIN
    Assign(ShortMsgFile,General.DataPath+'SHORTMSG.DAT');
    Reset(ShortMsgFile);
    IF (IOResult = 2) THEN
      ReWrite(ShortMsgFile);
    Seek(ShortMsgFile,FileSize(ShortMsgFile));
    WITH ShortMsg DO
    BEGIN
      Msg := Message;
      Destin := UNum;
    END;
    Write(ShortMsgFile,ShortMsg);
    Close(ShortMsgFile);
    LoadURec(User,UNum);
    Include(User.Flags,SMW);
    SaveURec(User,UNum);
    LastError := IOResult;
  END;
END;

END.
