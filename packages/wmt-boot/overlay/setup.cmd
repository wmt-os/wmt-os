@echo off

if "%OS%"=="Windows_NT" goto NT

start mshta.exe "file:%0\..\setup-web.html"
goto END

:NT
start "" mshta.exe "%~dp0setup-web.html"

:END
