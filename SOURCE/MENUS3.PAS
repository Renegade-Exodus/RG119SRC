{$IFDEF WIN32}
{$I DEFINES.INC}
{$ENDIF}

{$A+,B-,D-,E-,F+,I-,L-,N-,O+,R-,S+,V-}

UNIT Menus3;

INTERFACE

USES
  Common;

PROCEDURE DoChangeMenu(VAR Done: BOOLEAN; VAR NewMenuCmd: ASTR; Cmd: CHAR; CONST MenuOption: Str50);

IMPLEMENTATION

PROCEDURE DoChangeMenu(VAR Done: BOOLEAN; VAR NewMenuCmd: ASTR; Cmd: CHAR; CONST MenuOption: Str50);
VAR
  TempStr,
  TempStr1: ASTR;
BEGIN
  CASE Cmd OF
    '^' : BEGIN
            TempStr1 := MenuOption;
            IF (Pos(';',TempStr1) <> 0) THEN
              TempStr1 := Copy(TempStr1,1,(Pos(';',TempStr1) - 1));
            IF (MenuOption <> '') THEN
            BEGIN
              TempStr := MenuOption;
              IF (Pos(';',TempStr) <> 0) THEN
                TempStr := Copy(TempStr,(Pos(';',TempStr) + 1),Length(TempStr));
              IF (UpCase(TempStr[1]) = 'C') THEN
                MenuStackPtr := 0;
              IF (Pos(';',TempStr) = 0) OR (Length(TempStr) = 1) THEN
                TempStr := ''
              ELSE
                TempStr := Copy(TempStr,(Pos(';',TempStr) + 1),Length(TempStr));
            END;
            IF (TempStr1 <> '') THEN
            BEGIN
              CurMenu := StrToInt(TempStr1);
              IF (TempStr <> '') THEN
                NewMenuCmd := AllCaps(TempStr);
              Done := TRUE;
              NewMenuToLoad := TRUE;
            END;
          END;
    '/' : BEGIN
            TempStr1 := MenuOption;
            IF (Pos(';',TempStr1) <> 0) THEN
              TempStr1 := Copy(TempStr1,1,Pos(';',TempStr1) - 1);
            IF ((MenuOption <> '') AND (MenuStackPtr <> MaxMenus)) THEN
            BEGIN
              TempStr := MenuOption;
              IF (Pos(';',TempStr) <> 0) THEN
                TempStr := Copy(TempStr,(Pos(';',TempStr) + 1),Length(TempStr));
              IF (UpCase(TempStr[1]) = 'C') THEN
                MenuStackPtr := 0;
              IF (Pos(';',TempStr) = 0) OR (Length(TempStr) = 1) THEN
                TempStr := ''
              ELSE
                TempStr := Copy(TempStr,(Pos(';',TempStr) + 1),Length(TempStr));
              IF (CurMenu <> StrToInt(TempStr1)) THEN
              BEGIN
                Inc(MenuStackPtr);
                MenuStack[MenuStackPtr] := CurMenu;
              END
              ELSE
                TempStr1 := '';
            END;
            IF (TempStr1 <> '') THEN
            BEGIN
              CurMenu := StrToInt(TempStr1);
              IF (TempStr <> '') THEN
                NewMenuCmd := AllCaps(TempStr);
              Done := TRUE;
              NewMenuToLoad := TRUE;
            END;
          END;
    '\' : BEGIN
            IF (MenuStackPtr <> 0) THEN
            BEGIN
              CurMenu := MenuStack[MenuStackPtr];
              Dec(MenuStackPtr);
            END;
            IF (UpCase(MenuOption[1]) = 'C') THEN
              MenuStackPtr := 0;
            IF (Pos(';',MenuOption) <> 0) THEN
              NewMenuCmd := AllCaps(Copy(MenuOption,(Pos(';',MenuOption) + 1),Length(MenuOption)));
            Done := TRUE;
            NewMenuToLoad := TRUE;
          END;
  END;
END;

END.
