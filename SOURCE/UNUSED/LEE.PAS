Var
  Name: String[35];
  name1: string[35];
  Current: Integer;
  Done: Boolean;
BEGIN
  Name := '12345678901234567890123456789012345';
  Name1 := Copy('123456789012345678901234567890123456',1,35);
  IF (Name < Name) THEN
    Current := 1
  ELSE IF (Name > Name1) THEN
    Current := 2
  ELSE
    Done := TRUE;
  IF (Done) THEN
    Writeln('Matches!');
END.