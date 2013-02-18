{$IFDEF WIN32}
{$I DEFINES.INC}
{$ENDIF}

{$A+,B-,D+,E-,F+,I-,L+,N-,O+,R-,S+,V-}

UNIT ExecBat;

INTERFACE

USES
  Common,
  MyIO;

PROCEDURE ExecWindow(VAR Ok: Boolean;
                     CONST Dir,
                     BatLine: AStr;
                     OkLevel: Integer;
                     VAR RCode: Integer);
PROCEDURE ExecBatch(VAR Ok: Boolean;
                    Dir,
                    BatLine: AStr;
                    OkLevel: Integer;
                    VAR RCode: Integer;
                    Windowed: Boolean);
PROCEDURE Shel(CONST s: AStr);
PROCEDURE Shel2(x: Boolean);

IMPLEMENTATION

USES
  Crt,
  Dos;

VAR
  CurInt21: Pointer;
  WindPos,
  WindLo,
  WindHi: Word;
  WindAttr: Byte;

  SaveX,
  SaveY: Byte;
  SavCurWind: Integer;

{$IFDEF MSDOS}
{$L EXECWIN}

PROCEDURE SetCsInts; EXTERNAL;
PROCEDURE NewInt21; EXTERNAL;
{$ENDIF}

PROCEDURE ExecWindow(VAR Ok: Boolean;
                     CONST Dir,
                     BatLine: AStr;
                     OkLevel: Integer;
                     VAR RCode: Integer);
VAR
  SaveWindowOn: Boolean;
  SaveCurWindow: Byte;
  s: AStr;

{-Exec a program in a Window}

{$IFDEF Ver70}
  VAR
    TmpInt21 : Pointer;
{$ENDIF}

BEGIN
  SaveCurWindow := General.CurWindow;
  SaveWindowOn := General.WindowOn;
  General.WindowOn := TRUE;

  SaveX := WhereX;
  SaveY := WhereY;
  SaveScreen(Wind);

  ClrScr;

  lStatus_Screen(1,'',FALSE,s);

  {Store global copies of Window data for interrupt handler}
  WindAttr := 7;
  WindLo := WindMin;
  WindHi := WindMax;

{$IFDEF MSDOS}
  {Assure cursor is in Window}
  INLINE
  (
    {;get cursor pos}
    $B4/$03/                     {  mov ah,3}
    $30/$FF/                     {  xor bh,bh}
    $CD/$10/                     {  int $10}
    {;assure it's within Window}
    $8B/$0E/>WindLo/             {  mov cx,[>windlo]}
    $38/$EE/                     {  cmp dh,ch ;row above minimum?}
    $73/$02/                     {  jae okxlo ;jump IF so}
    $88/$EE/                     {  mov dh,ch}
    {okxlo:}
    $38/$CA/                     {  cmp dl,cl ;col above minimum?}
    $73/$02/                     {  jae okylo ;jump IF so}
    $88/$CA/                     {  mov dl,cl}
    {okylo:}
    $8B/$0E/>WindHi/             {  mov cx,[>windhi]}
    $38/$EE/                     {  cmp dh,ch ;row below maximum?}
    $76/$02/                     {  jbe okxhi ;jump IF so}
    $88/$EE/                     {  mov dh,ch}
    {okxhi:}
    $38/$CA/                     {  cmp dl,cl ;col below maximum?}
    $76/$02/                     {  jbe okyhi ;jump IF so}
    $88/$CA/                     {  mov dl,cl}
    {okyhi:}
    $89/$16/>WindPos/            {  mov [>windpos],dx ;save current position}
    {;position cursor}
    $B4/$02/                     {  mov ah,2}
    $30/$FF/                     {  xor bh,bh}
    $CD/$10);                    {  int $10}

   {Take over interrupt}
   GetIntVec($21,CurInt21);
   SetCsInts;
   SetIntVec($21,@NewInt21);
{$ENDIF}

  {$IFDEF Ver70}
    {Prevent SwapVectors from undoing our int21 change}
    TmpInt21 := SaveInt21;
    SaveInt21 := @NewInt21;
  {$ENDIF}

  {Exec the program}
  ExecBatch(Ok,Dir,BatLine,OkLevel,RCode,TRUE);

  {$IFDEF Ver70}
    SaveInt21 := TmpInt21;
  {$ENDIF}

  Window(1,1,MaxDisplayCols,MaxDisplayRows);
  RemoveWindow(Wind);

{$IFDEF MSDOS}
  {Restore interrupt}
  SetIntVec($21,CurInt21);
{$ENDIF}
  General.CurWindow := SaveCurWindow;
  General.WindowOn := SaveWindowOn;
  LastScreenSwap := (Timer - 5);
  lStatus_Screen(General.CurWindow,'',FALSE,s);

  GoToXY(SaveX,SaveY);
END;

PROCEDURE ExecBatch(VAR Ok: Boolean;     { result                     }
                    Dir: AStr;           { directory takes place in   }
                    BatLine: AStr;       { .BAT file line to execute  }
                    OkLevel: Integer;    { DOS errorlevel for success }
                    VAR RCode: Integer;     { errorlevel returned }
                    Windowed: Boolean);  { Windowed? }
VAR
  BatchFile: Text;
  SaveDir: AStr;
  BName: STRING[20];
BEGIN
  BName := 'TEMP'+IntToStr(ThisNode)+'.BAT';
  GetDir(0,SaveDir);
  Dir := BSlash(FExpand(Dir),FALSE);
  Assign(BatchFile,BName);
  ReWrite(BatchFile);
  WriteLn(BatchFile,'@ECHO OFF');
  WriteLn(BatchFile,Chr(ExtractDriveNumber(Dir) + 64)+':');
  IF (Dir <> '') THEN
    WriteLn(BatchFile,'CD '+Dir);
  IF (NOT WantOut) THEN
    BatLine := BatLine + ' > NUL';
  WriteLn(BatchFile,BatLine);
  WriteLn(BatchFile,':DONE');
  WriteLn(BatchFile,Chr(ExtractDriveNumber(SaveDir) + 64)+':');
  WriteLn(BatchFile,'CD '+SaveDir);
  WriteLn(BatchFile,'Exit');
  Close(BatchFile);

  IF (WantOut) AND (NOT Windowed) THEN
    Shel(BatLine);

  IF (NOT WantOut) THEN
    BName := BName + ' > NUL';

  ShellDOS(FALSE,BName,RCode);

  Shel2(Windowed);

  ChDir(SaveDir);
  Kill(BName);
  IF (OkLevel <> -1) THEN
    Ok := (RCode = OkLevel)
  ELSE
    Ok := TRUE;
  LastError := IOResult;
END;

PROCEDURE Shel(CONST s: AStr);
BEGIN
  SavCurWind := General.CurWindow;
  SaveX := WhereX;
  SaveY := WhereY;
  SetWindow(Wind,1,1,80,25,7,0,0);
  ClrScr;
  TextBackGround(1);
  TextColor(15);
  ClrEOL;
  Write(s);
  TextBackGround(0);
  TextColor(7);
  WriteLn;
END;

PROCEDURE Shel2(x: Boolean);
BEGIN
  ClrScr;
  RemoveWindow(Wind);
  IF (x) THEN
    Exit;
  GoToXY(SaveX,SaveY);
  LastScreenSwap := (Timer - 5);
END;

END.
