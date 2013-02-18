unit Sorting;
{=============================================}
{            James L. Allison                 }
{            1703 Neptune Lane                }
{            Houston, Texas  77062            }
{            Dec 22, 1988                     }
{=============================================}

{ Please feel free to use any part of this in any of your programs.}

interface
   uses TypeSpec;
type
   Item=TypeSpec.Character;   {This defines the objects being sorted.}
   List=array [0..0] of Item; {This is an array of objects to be sorted.}

   L_Less_Than_R = function(L,R:Item):boolean;
{  This is a user defined function that determines the
   order of the sort.  It may be as simple or complex as
   necessary to give the desired order.  In particular it
   can use any field in a record as the sort key, or use
   more than one key. }

   { Make sure that range check is off before you use any of these. }

procedure QuickSort  (var X:List; Less_Than:L_Less_Than_R; N:integer);
{  A very fast sort, uses recursion.
   May have stack problems on a large sort. }

procedure ShellSort  (var X:List; Less_Than:L_Less_Than_R; N:integer);
{  Almost as fast as QuickSort, but without recursion.
   The work horse of fast sorting methods. }

procedure LoopSort   (var X:List; Less_Than:L_Less_Than_R; N:integer);
{  No reason to use this.  Included only for comparison. }

procedure BubbleSort (var X:List; Less_Than:L_Less_Than_R; N:integer);
{  The only time to use this is when the array is almost in order, with
   only a couple of items out of place. It may be useful to modify this
   to make the sweep from the other end of the array.  BubbleSort is
   a special purpose method.  Stick to QuickSort or ShellSort.}

(*---------------------------------------------------------------------*)
implementation
(*---------------------------------------------------------------------*)
procedure Swap(var X:List;I,J:integer);
var
   Temp:Item;
   begin
      Temp:=X[I];
      X[I]:=X[J];
      X[J]:=Temp;
   end;
(*---------------------------------------------------------------------*)
procedure Qsort(var X:List;Less_Than:L_Less_Than_R;Left,Right:integer);
label
   Again;
var
   Pivot:Item;
   P,Q:integer;

   begin
      P:=Left;
      Q:=Right;
      Pivot:=X [(Left+Right) div 2];

      while P<=Q do
      begin
         while Less_Than(X[P],Pivot) do inc(P);
         while Less_Than(Pivot,X[Q]) do dec(Q);
         if P>Q then goto Again;
         Swap(X,P,Q);
         inc(P);dec(Q);
      end;

      Again:
      if Left<Q  then Qsort(X,Less_Than,Left,Q);
      if P<Right then Qsort(X,Less_Than,P,Right);
   end;

(*---------------------------------------------------------------------*)
procedure QuickSort(var X:List;Less_Than:L_Less_Than_R;N:integer);
   begin
      Qsort(X,Less_Than,0,N-1);
   end;

(*---------------------------------------------------------------------*)
procedure ShellSort(var X:List;Less_Than:L_Less_Than_R;N:integer);
var
   Gap,I,J:integer;

   begin
      Gap:=N div 2;

      while Gap>0 do
      begin
         I:=Gap;

         while I<N do
         begin
            J:=I-Gap;

            while (J>=0) and (Less_Than(X[J+Gap],X[J])) do
            begin
               Swap(X,J,J+Gap);
               dec(J,Gap);
            end;

            inc(I);
         end;

         Gap:=Gap div 2;
      end;

   end;

(*---------------------------------------------------------------------*)
procedure LoopSort(var X:List;Less_Than:L_Less_Than_R;N:integer);
var
   I,J:integer;
   begin
      for I:=0 to N-1 do
      begin
         for J:=I+1 to N-1 do
         begin
            if Less_Than(X[J],X[I])
            then
            begin
               Swap(X,I,J);
            end;
         end;
      end;
   end;

(*---------------------------------------------------------------------*)
procedure BubbleSort(var X:List;Less_Than:L_Less_Than_R;N:integer);
var
   J:integer;
   Finished:boolean;
   begin
      repeat
         Finished:=true;
         for J:=0 to N-2 do
         if Less_Than(X[J+1],X[J]) then
         begin
            Finished:=false;
            Swap(X,J,J+1);
         end;
      dec(N);
      until Finished;
   end;

   begin
   end.


