@echo off
:: WMT OS Setup Launcher
:: For Windows NT and CE

if "%OS%"=="Windows_NT" goto NT

start mshta.exe "file:%0\..\wmt-os-setup.html"
goto END

:NT
start "" mshta.exe "%~dp0wmt-os-setup.html"

:END
