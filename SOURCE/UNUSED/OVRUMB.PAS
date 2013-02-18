unit OvrUMB;

  { Unit OvrUMB : Uses an upper memory block as overlay buffer         }
  {                                                                    }
  {   Version 1.2 (15/09/94)                                           }
  {                                                                    }
  {   Author : Jean-Marc Lasgouttes                                    }
  {                                                                    }
  {   e-mail : Jean-Marc.Lasgouttes@inria.fr                           }


{$A+,F-,O-,S-}


interface

  uses Overlay;

  Procedure OvrSetBufUMB(Size:longint);
  {Frees the current overlay buffer (which must be before the heap),
   allocates a new buffer of Size bytes in upper memory and sets the
   overlay manager to use this buffer. This is only possible if the
   heap is empty and no overlays are currently loaded. This procedure
   must not be used if the buffer has been already reallocated
   somewhere

   #OvrMovBufToUMB# is an automatic version of this procedure that generate
   more efficient code.}

  Procedure OvrMovBufToUMB;
  {Same procedure as #OvrSetBufUMB#, except that the size of the UMB buffer
   is the biggest available upper memory block. No rellocation occurs if
   the biggest block is smaller than the current overlay buffer. This is the
   most convenient procedure to use.}

  Function UMB_MaxAvail:longint;
  {Returns the size of the biggest available upper memory block}

implementation

  const OvrUMBSeg:word=0;      {The Segment of the overlay buffer}

  var   OldExitProc:Pointer;   {The old ExitProc (surprise!)}
	SaveMemStrat,	       {Temporary variables to save system state}
	SaveUMBLink:word;

  Function ChangeMemStrat:boolean; assembler;
  {Save the current memory allocation strategy and change it in order
   to allocate upper memory}
  asm
    MOV   AX, 5800h		       {Save memory allocation strategy}
    INT   21h
    MOV   SaveMemStrat, AX
    MOV   AX, 5802h                    {Save UMB Link state}
    INT   21h
    MOV   SaveUMBLink, AX
    JC    @@1                          {If this function is not recognized}
                                       {  then DOS version <5 : Error}
    MOV   AX, 5801h                    {Set memory allocation strategy to}
    MOV   BX, 40h                      {  use only upper memory}
    INT   21h
    MOV   AX, 5803h                    {Add UMB to DOS memory chain}
    MOV   BX, 1
    INT   21h
    JNC   @@2			       {Error: no UMB provider}
@@1:MOV   AX, false                    {Return an error}
    JMP   @@3
@@2:MOV   AX, true                     {Return success}
@@3:
  end;

  Procedure ResetMemStrat; assembler;
  {Restore the memory allocation strategy as it was before the call to
   ChangeMemStrat}
  asm
    MOV   AX, 5801h		       {Reset the memory allocation strategy}
    MOV   BX, SaveMemStrat
    INT   21h
    MOV   AX, 5803h	               {Reset the UMB link state}
    MOV   BX, SaveUMBLink
    INT   21h
  end;

  Procedure ReleaseUMB(UMBSeg:word); assembler;
  {Releases the block corresponding to UMBSeg if UMBSeg<>0}
  asm
    MOV   AX, UMBSeg                   {If the segment is zero, do nothing}
    CMP   AX, 0
    JZ    @@1
    MOV   AX, 5802h	               {Save UMB Link state}
    INT   21h
    MOV   SaveUMBLink, AX
    MOV   AX, 5803h
    MOV   BX, 0		               {Remove UMB from DOS memory chain}
    INT   21h
    MOV   AH, 49h                      {Free block used by UMBSeg}
    MOV   ES, UMBSeg
    INT   21h
    MOV   AX, 5803h                    {Reset UMB link state}
    MOV   BX, SaveUMBLink
    INT   21h
@@1:
  end;

  Procedure PrimSetBufUMB(Size:word); assembler;
  {The basic procedure called by OvrSetBufUMB and OvrMovBufToUMB. Size
   is given in paragraphs.}
  asm
    XOR   AX, AX                       {Check for errors: }
    CMP   AX, OvrDOSHandle             {  Is the Overlay file opened?}
    JZ    @@3
    CMP   AX, OvrLoadList              {  Are there some Overlays loaded?}
    JNZ   @@3
    MOV   AX, OvrHeapEnd               {  Is the buffer already rellocated?}
    CMP   AX, WORD PTR HeapOrg+2
    JNZ   @@3
    CMP   AX, WORD PTR HeapPtr+2       {  Is there something in the heap?}
    JNZ   @@3
    MOV   AH, 48h                      {Allocate UMBSize segments of memory}
    MOV   BX, Size
    INT   21h
    JNC   @@1
    MOV   AX, ovrNoMemory              {Not enough UMB}
    JMP   @@2
@@1:MOV   OvrUMBSeg, AX                {Keep the segment in OvrUMBSeg}
    MOV   AX, OvrHeapOrg
    MOV   WORD PTR HeapOrg+2, AX       {Seg(HeapOrg):=OvrHeapOrg}
    MOV   WORD PTR HeapPtr+2, AX       {Seg(HeapPtr):=OvrHeapOrg}
    MOV   WORD PTR FreeList+2, AX      {Seg(FreeList):=OvrHeapOrg}
    XOR   AX, AX
    MOV   WORD PTR HeapOrg, AX         {Ofs(HeapOrg):=0}
    MOV   WORD PTR HeapPtr, AX         {Ofs(HeapPtr):=0}
    MOV   WORD PTR FreeList, AX        {Ofs(FreeList):=0}
    MOV   AX, OvrUMBSeg
    MOV   OvrHeapOrg, AX               {OvrHeapOrg:=OvrUMBSeg }
    MOV   OvrHeapPtr, AX               {OvrHeapPtr:=OvrUMBSeg }
    ADD   AX, Size
    MOV   OvrHeapEnd, AX               {OvrHeapEnd:=OvrUMBSeg+Size}
    MOV   AX, ovrOK                    {Success}
    JMP   @@2
@@3:MOV   AX, ovrError
@@2:MOV   OvrResult, AX                {Put the result in OvrResult}
  end;

  Function UMB_MaxAvail:longint; assembler;
  asm
    CALL  ChangeMemStrat               {Allow the use of upper memory}
    CMP   AX, false
    JZ    @@1                          {if it not possible, return 0}
    MOV   AH, 48h                      {Try to allocate too much memory}
    MOV   BX, 0FFFFh
    INT   21h                          {BX contains the size of the biggest}
    MOV   AX, BX                       {  available block}
    XOR   DX, DX
    SHL   AX, 1                        {Multiply by 16 and put the result}
    RCL   DX, 1                        {  in DX:AX}
    SHL   AX, 1
    RCL   DX, 1
    SHL   AX, 1
    RCL   DX, 1
    SHL   AX, 1
    RCL   DX, 1
    JMP   @@2
@@1:XOR   AX, AX
    XOR   DX, DX
@@2:PUSH  AX
    PUSH  DX
    CALL  ResetMemStrat                {Reset the memory allocation strategy}
    POP   DX
    POP   AX
  end;

  Procedure OvrSetBufUMB(Size:longint); assembler;
  asm
    CALL  ChangeMemStrat               {Allow the use of upper memory}
    CMP   AX, false
    JZ    @@1                          {If it is impossible, abort}
    MOV   AX, WORD PTR Size            {Transform Size}
    MOV   DX, WORD PTR Size+2          {  into a number of paragraphs}
    MOV   CL, 04h
    SHR   AX, CL
    ROR   DX, CL
    AND   DX, 0F000h
    OR    AX, DX                       {  the result is in AX}
    CMP   AX, OvrHeapSize              {If AX < OvrHeapSize --> Error}
    JB    @@1
    PUSH  AX
    CALL  PrimSetBufUMB                {Actually allocate and set the buffer}
    JMP   @@2
@@1:MOV   AX, ovrError                 {Report an Error}
    MOV   OvrResult, AX
@@2:CALL  ResetMemStrat
  end;

  Procedure OvrMovBufToUMB; assembler;
  asm
    CALL  ChangeMemStrat               {Allow the use of upper memory}
    CMP   AX, false
    JZ    @@1                          {If it is impossible, abort}
    MOV   AH, 48h                      {Try to allocate too much memory}
    MOV   BX, 0FFFFh
    INT   21h                          {BX contains the size of the biggest}
                                       {  available upper memory block}
    MOV   AX, OvrHeapEnd               {Compute the size of the}
    SUB   AX, OvrHeapOrg               {  current Overlay buffer}
    CMP   AX, BX                       {Is the UMB bigger than the current buffer?}
    JNB   @@1                          {If not, abort}
    PUSH  BX
    CALL  PrimSetBufUMB                {Actually allocate and set the buffer}
    JMP   @@2
@@1:MOV   OvrResult, OvrNoMemory
@@2:CALL  ResetMemStrat
  end;

  Procedure OvrUMBExitProc; far;
  begin
    ExitProc:=OldExitProc;             {Chain to the old exit handler}
    ReleaseUMB(OvrUMBSeg);             {Release the overlay buffer}
  end;

begin
  OldExitProc:=ExitProc;
  ExitProc:=@OvrUMBExitProc;           {Release the UMB on exit}
end.
