@echo off
:: This is the default LOGON.BAT file.  It is executed right after a
:: user reads Email.  If you have utilities that run each time someone
:: logs on, put them in here.  The parameters passed are:
::   %1 - Node number
::   %2 - User Number
::   %3 - Actual baud rate <not locked baud rate>
::   %4 - Dropfile path (DOOR.SYS is dropped)
::   %5 - Username
::
::
:: Note:  For %5 to be the username, dropfile path for node must not
:: be "", which is what Renegade tries to default to at this time.
:: This is not hard to fix.  Also, username is passed just as Renegade
:: stores it, in all uppercase.  This means %5 is likely NOT the full
:: username.  4DOS allows you to get the whole thing as %5&, those
:: without 4DOS will have to find other batch tricks.

