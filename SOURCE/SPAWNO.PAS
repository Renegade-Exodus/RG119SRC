{$IFDEF WIN32}
{$I DEFINES.INC}
{$ENDIF}

UNIT SPAWNO;

INTERFACE

CONST
  (* symbolic constants for specifying permissible swap locations *)
  (* add/or together the desired destinations *)
  Swap_Disk = 0;
  Swap_XMS = 1;
  Swap_EMS = 2;
  Swap_Ext = 4;
  Swap_All = $FF;     (* swap to any available destination *)

  (* error codes *)
  ENotFound = 2;
  ENoPath = 3;
  EAccess = 5;
  ENoMem = 8;
  E2Big = 20;
  EWriteFault = 29;

VAR
  Spawno_Error: Integer; (* error code when Spawn returns -1 *)

PROCEDURE Init_Spawno(Swap_Dirs: STRING; Swap_Types: Integer; Min_Res: Integer; Res_Stack: Integer);
	(* Min_Res = minimum number of paragraphs to keep resident
	   Res_Stack = minimum paragraphs of stack to keep resident
		       (0 = no change)
	 *)

FUNCTION Spawn(ProgName: STRING; Arguments: STRING; EnvSeg: Integer): Integer;

IMPLEMENTATION

{$IFDEF MSDOS}
{$L SPAWNTP.OBJ}

PROCEDURE Init_Spawno(Swap_Dirs: STRING; Swap_Types: Integer; Min_Res: Integer; Res_Stack: Integer); EXTERNAL;

FUNCTION Spawn(ProgName: STRING; Arguments: STRING; EnvSeg: Integer): Integer;  EXTERNAL;
{$ENDIF}
{$IFDEF WIN32}
PROCEDURE Init_Spawno(Swap_Dirs: STRING; Swap_Types: Integer; Min_Res: Integer; Res_Stack: Integer);
BEGIN
  WriteLn('REETODO SPAWNO Init_Spawno'); Halt;
END;

FUNCTION Spawn(ProgName: STRING; Arguments: STRING; EnvSeg: Integer): Integer;
BEGIN
  WriteLn('REETODO SPAWNO Spawn'); Halt;
END;
{$ENDIF}

END.

