IDEAL
; This CRC-32 routine and tables were converted from code discovered
; in the DEZIP.PAS V2.0 by R. P. Byrne.  The comments there are:
;
; Converted to Turbo Pascal (tm) V4.0 March, 1988 by J.R.Louvau
; COPYRIGHT (C) 1986 Gary S. Brown.  You may use this program, or
; code or tables extracted from it, as desired without restriction.
;
; First, the polynomial itself and its table of feedback terms.  The
; polynomial is
; X^32+X^26+X^23+X^22+X^16+X^12+X^11+X^10+X^8+X^7+X^5+X^4+X^2+X^1+X^0
;
; Note that we take it "backwards" and put the highest-order term in
; the lowest-order bit.  The X^32 term is "implied"; the LSB is the
; X^31 term, etc.  The X^0 term (usually shown as "+1") results in
; the MSB being 1.
;
; Note that the usual hardware shift register implementation, which
; is what we're using (we're merely optimizing it by doing eight-bit
; chunks at a time) shifts bits into the lowest-order term.  In our
; implementation, that means shifting towards the right.  Why do we
; do it this way?  Because the calculated CRC must be transmitted in
; order from highest-order term to lowest-order term.  UARTs transmit
; characters in order from LSB to MSB.  By storing the CRC this way,
; we hand it to the UART in the order low-byte to high-byte; the UART
; sends each low-bit to high-bit; and the result is transmission bit
; by bit from highest- to lowest-order term without requiring any bit
; shuffling on our part.  Reception works similarly.
;
; The feedback terms table consists of 256, 32-bit entries.  Notes:
;
;     The table can be generated at runtime if desired; code to do so
;     is shown later.  It might not be obvious, but the feedback
;     terms simply represent the results of eight shift/xor opera-
;     tions for all combinations of data and CRC register values.
;
;     The values must be right-shifted by eight bits by the "updcrc"
;     logic; the shift must be unsigned (bring in zeroes).  On some
;     hardware you could probably optimize the shift in assembler by
;     using byte-swap instructions.
;     polynomial $edb88320
;
; <End of Pascal version comments>
;
; The Pascal logic is:
;
; Function UpdC32(Octet: Byte; Crc: LongInt) : LongInt;
; Begin
;
;   UpdC32 := CRC_32_TAB[Byte(Crc XOR LongInt(Octet))] XOR ((Crc SHR 8)
;             AND $00FFFFFF);
;
; End {UpdC32};
;
; This routine computes the 32 bit CRC used by PKZIP and its derivatives,
; and by Chuck Forsberg's "ZMODEM" protocol.  The block CRC computation
; should start with high-values (0ffffffffh), and finish by inverting all
; bits.
;
; This TASM conversion done by:
;
;   Edwin T. Floyd [76067,747]
;   #9 Adams Park Ct.
;   Columbus, GA 31909
;   404-576-3305 (work)
;   404-322-0076 (home)
;
; Borland's Turbo Assembler - TASM is required to assemble this program.
;
SEGMENT  code BYTE PUBLIC
         ASSUME cs:code

;            0
crc32tab dd     000000000h, 077073096h, 0ee0e612ch, 0990951bah
         dd     0076dc419h, 0706af48fh, 0e963a535h, 09e6495a3h
         dd     00edb8832h, 079dcb8a4h, 0e0d5e91eh, 097d2d988h
         dd     009b64c2bh, 07eb17cbdh, 0e7b82d07h, 090bf1d91h
;            1
         dd     01db71064h, 06ab020f2h, 0f3b97148h, 084be41deh
         dd     01adad47dh, 06ddde4ebh, 0f4d4b551h, 083d385c7h
         dd     0136c9856h, 0646ba8c0h, 0fd62f97ah, 08a65c9ech
         dd     014015c4fh, 063066cd9h, 0fa0f3d63h, 08d080df5h
;            2
         dd     03b6e20c8h, 04c69105eh, 0d56041e4h, 0a2677172h
         dd     03c03e4d1h, 04b04d447h, 0d20d85fdh, 0a50ab56bh
         dd     035b5a8fah, 042b2986ch, 0dbbbc9d6h, 0acbcf940h
         dd     032d86ce3h, 045df5c75h, 0dcd60dcfh, 0abd13d59h
;            3
         dd     026d930ach, 051de003ah, 0c8d75180h, 0bfd06116h
         dd     021b4f4b5h, 056b3c423h, 0cfba9599h, 0b8bda50fh
         dd     02802b89eh, 05f058808h, 0c60cd9b2h, 0b10be924h
         dd     02f6f7c87h, 058684c11h, 0c1611dabh, 0b6662d3dh
;            4
         dd     076dc4190h, 001db7106h, 098d220bch, 0efd5102ah
         dd     071b18589h, 006b6b51fh, 09fbfe4a5h, 0e8b8d433h
         dd     07807c9a2h, 00f00f934h, 09609a88eh, 0e10e9818h
         dd     07f6a0dbbh, 0086d3d2dh, 091646c97h, 0e6635c01h
;            5
         dd     06b6b51f4h, 01c6c6162h, 0856530d8h, 0f262004eh
         dd     06c0695edh, 01b01a57bh, 08208f4c1h, 0f50fc457h
         dd     065b0d9c6h, 012b7e950h, 08bbeb8eah, 0fcb9887ch
         dd     062dd1ddfh, 015da2d49h, 08cd37cf3h, 0fbd44c65h
;            6
         dd     04db26158h, 03ab551ceh, 0a3bc0074h, 0d4bb30e2h
         dd     04adfa541h, 03dd895d7h, 0a4d1c46dh, 0d3d6f4fbh
         dd     04369e96ah, 0346ed9fch, 0ad678846h, 0da60b8d0h
         dd     044042d73h, 033031de5h, 0aa0a4c5fh, 0dd0d7cc9h
;            7
         dd     05005713ch, 0270241aah, 0be0b1010h, 0c90c2086h
         dd     05768b525h, 0206f85b3h, 0b966d409h, 0ce61e49fh
         dd     05edef90eh, 029d9c998h, 0b0d09822h, 0c7d7a8b4h
         dd     059b33d17h, 02eb40d81h, 0b7bd5c3bh, 0c0ba6cadh
;            8
         dd     0edb88320h, 09abfb3b6h, 003b6e20ch, 074b1d29ah
         dd     0ead54739h, 09dd277afh, 004db2615h, 073dc1683h
         dd     0e3630b12h, 094643b84h, 00d6d6a3eh, 07a6a5aa8h
         dd     0e40ecf0bh, 09309ff9dh, 00a00ae27h, 07d079eb1h
;            9
         dd     0f00f9344h, 08708a3d2h, 01e01f268h, 06906c2feh
         dd     0f762575dh, 0806567cbh, 0196c3671h, 06e6b06e7h
         dd     0fed41b76h, 089d32be0h, 010da7a5ah, 067dd4acch
         dd     0f9b9df6fh, 08ebeeff9h, 017b7be43h, 060b08ed5h
;            A
         dd     0d6d6a3e8h, 0a1d1937eh, 038d8c2c4h, 04fdff252h
         dd     0d1bb67f1h, 0a6bc5767h, 03fb506ddh, 048b2364bh
         dd     0d80d2bdah, 0af0a1b4ch, 036034af6h, 041047a60h
         dd     0df60efc3h, 0a867df55h, 0316e8eefh, 04669be79h
;            B
         dd     0cb61b38ch, 0bc66831ah, 0256fd2a0h, 05268e236h
         dd     0cc0c7795h, 0bb0b4703h, 0220216b9h, 05505262fh
         dd     0c5ba3bbeh, 0b2bd0b28h, 02bb45a92h, 05cb36a04h
         dd     0c2d7ffa7h, 0b5d0cf31h, 02cd99e8bh, 05bdeae1dh
;            C
         dd     09b64c2b0h, 0ec63f226h, 0756aa39ch, 0026d930ah
         dd     09c0906a9h, 0eb0e363fh, 072076785h, 005005713h
         dd     095bf4a82h, 0e2b87a14h, 07bb12baeh, 00cb61b38h
         dd     092d28e9bh, 0e5d5be0dh, 07cdcefb7h, 00bdbdf21h
;            D
         dd     086d3d2d4h, 0f1d4e242h, 068ddb3f8h, 01fda836eh
         dd     081be16cdh, 0f6b9265bh, 06fb077e1h, 018b74777h
         dd     088085ae6h, 0ff0f6a70h, 066063bcah, 011010b5ch
         dd     08f659effh, 0f862ae69h, 0616bffd3h, 0166ccf45h
;            E
         dd     0a00ae278h, 0d70dd2eeh, 04e048354h, 03903b3c2h
         dd     0a7672661h, 0d06016f7h, 04969474dh, 03e6e77dbh
         dd     0aed16a4ah, 0d9d65adch, 040df0b66h, 037d83bf0h
         dd     0a9bcae53h, 0debb9ec5h, 047b2cf7fh, 030b5ffe9h
;            F
         dd     0bdbdf21ch, 0cabac28ah, 053b39330h, 024b4a3a6h
         dd     0bad03605h, 0cdd70693h, 054de5729h, 023d967bfh
         dd     0b3667a2eh, 0c4614ab8h, 05d681b02h, 02a6f2b94h
         dd     0b40bbe37h, 0c30c8ea1h, 05a05df1bh, 02d02ef8dh


         MODEL TPASCAL

PUBLIC   UpdateCRC32
PROC     UpdateCRC32 FAR initcrc:DWORD,inbuf:DWORD,inlen:WORD
; UpdateCRC32 takes an initial CRC value and updates it with inlen bytes from
; inbuf. The updated CRC is returned in DX:AX.  The Pascal declaration is:
; Function UpdateCRC32(InitCRC : LongInt; Var InBuf; InLen : Word) : LongInt;
; Stomps registers: AX,BX,CX,DX,ES,SI
         push   ds
         lds    si,[inbuf]    ; ds:si := ^inbuf
         les    ax,[initcrc]  ; dx:ax := initcrc
         mov    dx,es
         mov    cx,[inlen]    ; cx := inlen
         or     cx,cx
         jz     @@done
@@loop:
         xor    bh,bh
         mov    bl,al
         lodsb
         xor    bl,al
         mov    al,ah
         mov    ah,dl
         mov    dl,dh
         xor    dh,dh
         shl    bx,1
         shl    bx,1
         les    bx,[crc32tab+bx]
         xor    ax,bx
         mov    bx,es
         xor    dx,bx
         loop   @@loop
@@done:
         pop    ds
         ret
ENDP

ENDS
END
