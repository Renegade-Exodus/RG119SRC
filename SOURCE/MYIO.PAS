{$IFDEF WIN32}
{$I DEFINES.INC}
{$ENDIF}

{$A+,B-,D+,E-,F+,I-,L+,N-,O+,R+,S-,V-}

UNIT MyIO;

INTERFACE

TYPE
  AStr = STRING[160];
  WindowRec = ARRAY[0..8000] OF Byte;
  ScreenType = ARRAY [0..3999] OF Byte;
  Infield_Special_Function_Proc_Rec = PROCEDURE(c: Char);

CONST
  Infield_Seperators: SET OF Char = [' ','\','.'];

  Infield_Only_Allow_On: BOOLEAN = FALSE;
  Infield_Arrow_Exit: BOOLEAN = FALSE;
  Infield_Arrow_Exited: BOOLEAN = FALSE;
  Infield_Arrow_Exited_Keep: BOOLEAN = FALSE;
  Infield_Special_Function_On: BOOLEAN = FALSE;
  Infield_Arrow_Exit_TypeDefs: BOOLEAN = FALSE;
  Infield_Normal_Exit_Keydefs: BOOLEAN = FALSE;
  Infield_Normal_Exited: BOOLEAN = FALSE;

VAR
  Wind: WindowRec;
{$IFDEF MSDOS}
  MonitorType: Byte ABSOLUTE $0000:$0449;
  ScreenAddr: ScreenType ABSOLUTE $B800:$0000;
{$ENDIF}
{$IFDEF WIN32}
  MonitorType: Byte = 3; // REENOTE 3=CO80, a safe assumption I think
{$ENDIF}
  ScreenSize: Integer;
  MaxDisplayRows,
  MaxDisplayCols,
  Infield_Out_FGrd,
  Infield_Out_BkGd,
  Infield_Inp_FGrd,
  Infield_Inp_BkGd,
  Infield_Last_Arrow,
  Infield_Last_Normal: Byte;
  Infield_Special_Function_Proc: infield_special_function_proc_rec;
  Infield_Only_Allow,
  Infield_Special_Function_Keys,
  Infield_Arrow_Exit_Types,
  Infield_Normal_Exit_Keys: STRING;

{$IFDEF MSDOS}
PROCEDURE Update_Logo(VAR Addr1,Addr2; BlkLen: Integer);
{$ENDIF}
{$IFDEF WIN32}
procedure Update_Logo(Data: Array of Char; OriginX, OriginY, DataLength: integer);
{$ENDIF}
PROCEDURE CursorOn(b: BOOLEAN);
PROCEDURE infield1(x,y: Byte; VAR s: AStr; Len: Byte);
PROCEDURE Infielde(VAR s: AStr; Len: Byte);
PROCEDURE Infield(VAR s: AStr; Len: Byte);
FUNCTION l_yn: BOOLEAN;
FUNCTION l_pynq(CONST s: AStr): BOOLEAN;
PROCEDURE CWrite(CONST s: AStr);
PROCEDURE CWriteAt(x,y: Integer; CONST s: AStr);
FUNCTION CStringLength(CONST s: AStr): Integer;
PROCEDURE cwritecentered(y: Integer; CONST s: AStr);
PROCEDURE Box(LineType,TLX,TLY,BRX,BRY: Integer);
PROCEDURE SaveScreen(VAR Wind: WindowRec);
PROCEDURE RemoveWindow(VAR Wind: WindowRec);
PROCEDURE SetWindow(VAR Wind: WindowRec; TLX,TLY,BRX,BRY,TColr,BColr,BoxType: Integer);

IMPLEMENTATION

USES
  Crt
{$IFDEF WIN32}
  ,RPScreen
  ,VpSysLow
{$ENDIF}
  ;

{$IFDEF WIN32}
VAR
  SavedScreen: TScreenBuf;
{$ENDIF}

{$IFDEF MSDOS}
PROCEDURE CursorOn(b: BOOLEAN); ASSEMBLER;
ASM
  cmp b, 1
  je @turnon
  mov ch, 9
  mov cl, 0
  jmp @goforit
  @turnon:
  mov ch, 6
  mov cl, 7
  @goforit:
  mov ah,1
  int 10h
END;
{$ENDIF}
{$IFDEF WIN32}
PROCEDURE CursorOn(b: BOOLEAN);
BEGIN
  if (b) then
  begin
    RPShowCursor;
  end else
  begin
    RPHideCursor;
  end;
END;
{$ENDIF}

PROCEDURE infield1(x,y: Byte; VAR s: AStr; Len: Byte);
VAR
  SaveS: AStr;
  c: Char;
  SaveTextAttr,
  SaveX,
  SaveY: Byte;
  i,
  p,
  z: Integer;
  Ins,
  Done,
  NoKeyYet: BOOLEAN;

  PROCEDURE gocpos;
  BEGIN
    GoToXY(x + p - 1,y);
  END;

  PROCEDURE Exit_W_Arrow;
  VAR
    i: Integer;
  BEGIN
    Infield_Arrow_Exited := TRUE;
    Infield_Last_Arrow := Ord(c);
    Done := TRUE;
    IF (Infield_Arrow_Exited_Keep) THEN
    BEGIN
      z := Len;
      FOR i := Len DOWNTO 1 DO
        IF (s[i] = ' ') THEN
          Dec(z)
        ELSE
          i := 1;
      s[0] := chr(z);
    END
    ELSE
      s := SaveS;
  END;

  PROCEDURE Exit_W_Normal;
  VAR
    i: Integer;
  BEGIN
    Infield_Normal_Exited := TRUE;
    Infield_Last_Normal := Ord(c);
    Done := TRUE;
    IF (Infield_Arrow_Exited_Keep) THEN
    BEGIN
      z := Len;
      FOR i := Len DOWNTO 1 DO
        IF (s[i] = ' ') THEN
          Dec(z)
        ELSE
          i := 1;
      s[0] := chr(z);
    END
    ELSE
      s := SaveS;
  END;

BEGIN
  SaveTextAttr := TextAttr;
  SaveX := WhereX;
  SaveY := WhereY;
  SaveS := s;
  Ins := FALSE;
  Done := FALSE;
  Infield_Arrow_Exited := FALSE;
  GoToXY(x,y);
  TextAttr := (Infield_Inp_BkGd * 16) + Infield_Inp_FGrd;
  FOR i := 1 TO Len DO
    Write(' ');
  FOR i := (Length(s) + 1) TO Len DO
    s[i] := ' ';
  GoToXY(x,y);
  Write(s);
  p := 1;
  gocpos;
  NoKeyYet := TRUE;
  REPEAT
    REPEAT
      c := ReadKey
    UNTIL ((NOT Infield_Only_Allow_On) OR
           (Pos(c,Infield_Special_Function_Keys) <> 0) OR
           (Pos(c,Infield_Normal_Exit_Keys) <> 0) OR
           (Pos(c,Infield_Only_Allow) <> 0) OR (c = #0));

    IF ((Infield_Normal_Exit_Keydefs) AND
      (Pos(c,Infield_Normal_Exit_Keys) <> 0)) THEN
        Exit_W_Normal;

    IF ((Infield_Special_Function_On) AND
        (Pos(c,Infield_Special_Function_Keys) <> 0)) THEN
      Infield_Special_Function_Proc(c)
    ELSE
    BEGIN
      IF (NoKeyYet) THEN
      BEGIN
        NoKeyYet := FALSE;
        IF (c IN [#32..#255]) THEN
        BEGIN
          GoToXY(x,y);
          FOR i := 1 TO Len DO
          BEGIN
            Write(' ');
            s[i] := ' ';
          END;
          GoToXY(x,y);
        END;
      END;
      CASE c OF
        #0 : BEGIN
               c := ReadKey;
               IF ((Infield_Arrow_Exit) AND (Infield_Arrow_Exit_TypeDefs) AND
                   (Pos(c,Infield_Arrow_Exit_Types) <> 0)) THEN
                 Exit_W_Arrow
               ELSE
               CASE c OF
                 #72,#80 :
                       IF (Infield_Arrow_Exit) THEN
                         Exit_W_Arrow;
                 #75 : IF (p > 1) THEN
                         Dec(p);
                 #77 : IF (p < Len + 1) THEN
                         Inc(p);
                 #71 : p := 1;
                 #79 : BEGIN
                         z := 1;
                         FOR i := Len DOWNTO 2 DO
                          IF ((s[i - 1] <> ' ') AND (z = 1)) THEN
                            z := i;
                         IF (s[z] = ' ') THEN
                           p := z
                         ELSE
                           p := Len + 1;
                       END;
                 #82 : Ins := NOT Ins;
                 #83 : IF (p <= Len) THEN
                       BEGIN
                         FOR i := p TO (Len - 1) DO
                         BEGIN
                           s[i] := s[i + 1];
                           Write(s[i]);
                         END;
                         s[Len] := ' ';
                         Write(' ');
                       END;
                #115 : IF (p > 1) THEN
                       BEGIN
                         i := (p - 1);
                         WHILE ((NOT (s[i - 1] IN Infield_Seperators)) OR
                               (s[i] IN Infield_Seperators)) AND (i > 1) DO
                           Dec(i);
                         p := i;
                       END;
                #116 : IF (p <= Len) THEN
                       BEGIN
                         i := p + 1;
                         WHILE ((NOT (s[i-1] IN Infield_Seperators)) OR
                               (s[i] IN Infield_Seperators)) AND (i <= Len) DO
                           Inc(i);
                         p := i;
                       END;
                #117 : IF (p <= Len) THEN
                         FOR i := p TO Len DO
                         BEGIN
                           s[i] := ' ';
                           Write(' ');
                         END;
               END;
               gocpos;
             END;
       #27 : BEGIN
               s := SaveS;
               Done := TRUE;
             END;
       #13 : BEGIN
               Done := TRUE;
               z := Len;
               FOR i := Len DOWNTO 1 DO
                IF (s[i] = ' ') THEN
                  Dec(z)
                ELSE
                  i := 1;
               s[0] := chr(z);
             END;
        #8 : IF (p <> 1) THEN
             BEGIN
               Dec(p);
               s[p] := ' ';
               gocpos;
               Write(' ');
               gocpos;
             END;
      ELSE
        IF ((c IN [#32..#255]) AND (p <= Len)) THEN
        BEGIN
          IF ((Ins) AND (p <> Len)) THEN
          BEGIN
            Write(' ');
            FOR i := Len DOWNTO (p + 1) DO
              s[i] := s[i - 1];
            FOR i := (p + 1) TO Len DO
              Write(s[i]);
            gocpos;
          END;
          Write(c);
          s[p] := c;
          Inc(p);
        END;
      END;
    END;
  UNTIL (Done);
  GoToXY(x,y);
  TextAttr := (Infield_Out_BkGd * 16) + Infield_Out_FGrd;
  FOR i := 1 TO Len DO
    Write(' ');
  GoToXY(x,y);
  Write(s);
  GoToXY(SaveX,SaveY);
  TextAttr := SaveTextAttr;
  Infield_Only_Allow_On := FALSE;
  Infield_Special_Function_On := FALSE;
  Infield_Normal_Exit_Keydefs := FALSE;
END;

PROCEDURE Infielde(VAR s: AStr; Len: Byte);
BEGIN
  infield1(WhereX,WhereY,s,Len);
END;

PROCEDURE Infield(VAR S: AStr; Len: Byte);
BEGIN
  S := '';
  Infielde(S,Len);
END;

FUNCTION l_yn: BOOLEAN;
VAR
  C: Char;
BEGIN
  REPEAT
    C := UpCase(ReadKey)
  UNTIL (C IN ['Y','N',#13,#27]);
  IF (C = 'Y') THEN
  BEGIN
    l_yn := TRUE;
    WriteLn('Yes');
  END
  ELSE
  BEGIN
    l_yn := FALSE;
    WriteLn('No');
  END;
END;

FUNCTION l_pynq(CONST S: AStr): BOOLEAN;
BEGIN
  TextColor(4);
  Write(S);
  TextColor(11);
  l_pynq := l_yn;
END;

PROCEDURE CWrite(CONST S: AStr);
VAR
  C: Char;
  Counter: Byte;
  LastB,
  LastC: BOOLEAN;
BEGIN
  LastB := FALSE;
  LastC := FALSE;
  FOR Counter := 1 TO Length(S) DO
  BEGIN
    C := S[Counter];
    IF ((LastB) OR (LastC)) THEN
    BEGIN
      IF (LastB) THEN
        TextBackGround(Ord(C))
      ELSE IF (LastC) THEN
        TextColor(Ord(C));
      LastB := FALSE;
      LastC := FALSE;
    END
    ELSE
      CASE C OF
        #2 : LastB := TRUE;
        #3 : LastC := TRUE;
      ELSE
        Write(C);
    END;
  END;
END;

PROCEDURE CWriteAt(x,y: Integer; CONST s: AStr);
BEGIN
  GoToXY(x,y);
  CWrite(s);
END;

FUNCTION CStringLength(CONST s: AStr): Integer;
VAR
  Len,
  i: Integer;
BEGIN
  Len := Length(s);
  i := 1;
  WHILE (i <= Length(s)) DO
  BEGIN
    IF ((s[i] = #2) OR (s[i] = #3)) THEN
    BEGIN
      Dec(Len,2);
      Inc(i);
    END;
    Inc(i);
  END;
  CStringLength := Len;
END;

PROCEDURE cwritecentered(y: Integer; CONST s: AStr);
BEGIN
  CWriteAt(40 - (CStringLength(s) DIV 2),y,s);
END;

{*
 *  ÚÄÄÄ¿   ÉÍÍÍ»   °°°°°   ±±±±±   ²²²²²   ÛÛÛÛÛ   ÖÄÄÄ·  ÕÍÍÍ¸
 *  ³ 1 ³   º 2 º   ° 3 °   ± 4 ±   ² 5 ²   Û 6 Û   º 7 º  ³ 8 ³
 *  ÀÄÄÄÙ   ÈÍÍÍ¼   °°°°°   ±±±±±   ²²²²²   ÛÛÛÛÛ   ÓÄÄÄ½  ÔÍÍÍ¾
 *}
PROCEDURE Box(LineType,TLX,TLY,BRX,BRY: Integer);
VAR
  TL,TR,BL,BR,HLine,VLine: Char;
  i: Integer;
BEGIN
  Window(1,1,MaxDisplayCols,MaxDisplayRows);
  CASE LineType OF
    1 : BEGIN
          TL := #218;
          TR := #191;
          BL := #192;
          BR := #217;
          VLine := #179;
          HLine := #196;
        END;
    2 : BEGIN
          TL := #201;
          TR := #187;
          BL := #200;
          BR := #188;
          VLine := #186;
          HLine := #205;
        END;
    3 : BEGIN
          TL := #176;
          TR := #176;
          BL := #176;
          BR := #176;
          VLine := #176;
          HLine := #176;
        END;
    4 : BEGIN
          TL := #177;
          TR := #177;
          BL := #177;
          BR := #177;
          VLine := #177;
          HLine := #177;
        END;
    5 : BEGIN
          TL := #178;
          TR := #178;
          BL := #178;
          BR := #178;
          VLine := #178;
          HLine := #178;
        END;
    6 : BEGIN
          TL := #219;
          TR := #219;
          BL := #219;
          BR := #219;
          VLine := #219;
          HLine := #219;
        END;
    7 : BEGIN
          TL := #214;
          TR := #183;
          BL := #211;
          BR := #189;
          VLine := #186;
          HLine := #196;
        END;
    8 : BEGIN
          TL := #213;
          TR := #184;
          BL := #212;
          BR := #190;
          VLine := #179;
          HLine := #205;
        END;
    ELSE
    BEGIN
      TL := #32;
      TR := #32;
      BL := #32;
      BR := #32;
      VLine := #32;
      HLine := #32;
    END;
  END;
  GoToXY(TLX,TLY);
  Write(TL);
  GoToXY(BRX,TLY);
  Write(TR);
  GoToXY(TLX,BRY);
  Write(BL);
  GoToXY(BRX,BRY);
  Write(BR);
  FOR i := (TLX + 1) TO (BRX - 1) DO
  BEGIN
    GoToXY(i,TLY);
    Write(HLine);
  END;
  FOR i := (TLX + 1) TO (BRX - 1) DO
  BEGIN
    GoToXY(i,BRY);
    Write(HLine);
  END;
  FOR i := (TLY + 1) TO (BRY - 1) DO
  BEGIN
    GoToXY(TLX,i);
    Write(VLine);
  END;
  FOR i := (TLY + 1) TO (BRY - 1) DO
  BEGIN
    GoToXY(BRX,I);
    Write(VLine);
  END;
  IF (LineType > 0) THEN
    Window((TLX + 1),(TLY + 1),(BRX - 1),(BRY - 1))
  ELSE
    Window(TLX,TLY,BRX,BRY);
END;

PROCEDURE SaveScreen(VAR Wind: WindowRec);
BEGIN
{$IFDEF MSDOS}
  Move(ScreenAddr[0],Wind[0],ScreenSize);
{$ENDIF}
{$IFDEF WIN32}
  RPSaveScreen(SavedScreen);
{$ENDIF}
END;

PROCEDURE RemoveWindow(VAR Wind: WindowRec);
BEGIN
{$IFDEF MSDOS}
  Move(Wind[0],ScreenAddr[0],ScreenSize);
{$ENDIF}
{$IFDEF WIN32}
  RPRestoreScreen(SavedScreen);
{$ENDIF}
END;

PROCEDURE SetWindow(VAR Wind: WindowRec; TLX,TLY,BRX,BRY,TColr,BColr,BoxType:Integer);
BEGIN
  SaveScreen(Wind);                        { save under Window }
  Window(TLX,TLY,BRX,BRY);                 { SET Window size }
  TextColor(TColr);
  TextBackGround(BColr);
  ClrScr;                                  { clear window for action }
  Box(BoxType,TLX,TLY,BRX,BRY);            { Set the border }
END;

{$IFDEF MSDOS}
PROCEDURE Update_Logo(VAR Addr1,Addr2; BlkLen: Integer);
BEGIN
  INLINE (
    $1E/
    $C5/$B6/ADDR1/
    $C4/$BE/ADDR2/
    $8B/$8E/BLKLEN/
    $E3/$5B/
    $8B/$D7/
    $33/$C0/
    $FC/
    $AC/
    $3C/$20/
    $72/$05/
    $AB/
    $E2/$F8/
    $EB/$4C/
    $3C/$10/
    $73/$07/
    $80/$E4/$F0/
    $0A/$E0/
    $EB/$F1/
    $3C/$18/
    $74/$13/
    $73/$19/
    $2C/$10/
    $02/$C0/
    $02/$C0/
    $02/$C0/
    $02/$C0/
    $80/$E4/$8F/
    $0A/$E0/
    $EB/$DA/
    $81/$C2/$A0/$00/
    $8B/$FA/
    $EB/$D2/
    $3C/$1B/
    $72/$07/
    $75/$CC/
    $80/$F4/$80/
    $EB/$C7/
    $3C/$19/
    $8B/$D9/
    $AC/
    $8A/$C8/
    $B0/$20/
    $74/$02/
    $AC/
    $4B/
    $32/$ED/
    $41/
    $F3/$AB/
    $8B/$CB/
    $49/
    $E0/$AA/
    $1F);
END;
{$ENDIF}
{$IFDEF WIN32}
procedure Update_Logo(Data: Array of Char; OriginX, OriginY, DataLength: integer);
var 
  i, x, y, count, counter: Integer;
  character: Char;
  spaces: String;
begin
  i := 0;
  x := OriginX;
  y := OriginY;
  spaces := '                                                                                '; // 80 spaces
  
  while (i < DataLength) do
  begin
    case Data[i] of
	  #0..#15: begin
	             TextColor(Ord(Data[i]));
	           end;
	  #16..#23: begin
	              TextBackground(Ord(Data[i]) - 16);
				end;
	  #24: begin
	         x := OriginX;
			 Inc(y);
		   end;
	  #25: begin
	         Inc(i);
			 count := Ord(Data[i])+1;
			 SysWrtCharStrAtt(@spaces[1], count, x-1, y-1, TextAttr);
			 Inc(x, count);
	       end;
	  #26: begin
	         Inc(i);
			 count := Ord(Data[i])+1;
			 Inc(i);
			 character := Data[i];
			 for counter := 1 to count do
			 begin
			   SysWrtCharStrAtt(@Data[i], 1, x-1, y-1, TextAttr);
			   Inc(x);
			 end;
	       end;
	  #27: begin
	         TextAttr := TextAttr XOR $80; // Invert blink flag
	       end;
	  #32..#255: begin
	               SysWrtCharStrAtt(@Data[i], 1, x-1, y-1, TextAttr);
				   Inc(x);
	             end;
    end;
	Inc(i);
  end;
end;
{$ENDIF}

END.
