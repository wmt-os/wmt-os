@echo off
REM WMT OS kernel rollback -- swap the active (script) and backup (script.bak) boot slots
if "%OS%"=="Windows_NT" cd /d "%~dp0"
cls
echo  WMT OS  --  Kernel Rollback
echo.
if not exist script\version goto NOSCRIPT
if not exist script.bak\version goto NOBACKUP
echo  Now booting:
type script\version
echo.
echo  Switch to:
type script.bak\version
echo.
echo  Press a key to switch, or close this window to cancel.
pause
ren script script.tmp
ren script.bak script
ren script.tmp script.bak
cls
echo  Done -- the device will next boot:
type script\version
echo.
echo  Reboot to apply.  Run this again to switch back.
pause
goto END
:NOSCRIPT
echo  Cannot find the \script folder -- run this from the card's root.
pause
goto END
:NOBACKUP
echo  Only one kernel is installed -- nothing to roll back to.
pause
:END
