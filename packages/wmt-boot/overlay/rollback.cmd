@echo off
cd %0\..

cls
echo WMT OS Kernel Rollback
echo.

if not exist script\version goto NOSCRIPT
if not exist script.bak\version goto NOBACKUP

echo Current version:
type script\version
echo.
echo Previous version:
type script.bak\version
echo.
echo Press a key to switch, or close this window to cancel.
pause
echo.

ren script script.tmp
ren script.bak script
ren script.tmp script.bak
echo Done. The device will next boot:
type script\version
echo.
echo You may now reboot. Run this again to switch back.
pause

goto END

:NOSCRIPT
echo Cannot find the \script folder. Run this from the card's root.
pause
goto END

:NOBACKUP
echo Only one kernel is installed. Nothing to roll back to.
pause

:END
