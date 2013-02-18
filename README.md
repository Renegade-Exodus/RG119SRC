Renegade v1.19
==============

This is a port of the current version of Renegade: v1.19.  My port of the older Y2Ka2 version can be found here: https://github.com/rickparrish/Renegade<br />
<br />
This is a fork of the official v1.19 release, which can be found here: https://github.com/Renegade-Exodus/RG119SRC<br />

==============================
Copyright Cott Lang, Patrick Spence, Gary Hall, Jeff Herrings, T.J. McMillen, Chris Hoppman, and Lee Palmer<br />
Ported to Win32 by Rick Parrish<br />

<hr />

TODO list:<br />
<ul>
  <li>Find/correct any usage of FOR loop variables after the loop (since they are 1 greater in VP than in BP</li>
  <li>Find/correct any file i/o on untyped files where Words or Integers are being read</li>
</ul>

Completed list<br />
<ul>
  <li>IFDEF out anything that doesn't compile and make a WIN32 placeholder that does a "WriteLn('REETODO UNIT FUNCTION'); Halt;" (then you can grep the executables for REETODO to see which REETODOs actually need to be implemented)</li>
  <li>IFDEF out any ASM code blocks and handle the same as above</li>
  <li>TYPEs of OF WORD to OF SMALLWORD (just in case they're used in a RECORD)</li>
  <li>TYPEs of OF INTEGER to OF SMALLINT (just in case they're used in a RECORD)</li>
  <li>WORD in RECORD to SMALLWORD</li>
  <li>INTEGER in RECORD to SMALLINT</li>
  <li>Anything passing 0 for the Attr parameter to FindFirst should pass AnyFile instead (VP returns no files when 0 is passed for Attr)</li>
  <li>Investigate FILEMODE usage to see if FILEMODEREADWRITE, TEXTMODEREAD or TEXTMODEREADWRITE should be used</li>
  <li>Implement any REETODOs that appear in compiled executables</li>
</ul>
