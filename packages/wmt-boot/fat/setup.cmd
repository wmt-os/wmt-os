@echo off

if "%OS%"=="Windows_NT" goto NT

start mshta.exe "file:%0\..\setup.html"
goto END

:NT
start "" mshta.exe "%~dp0setup.html"

:END
