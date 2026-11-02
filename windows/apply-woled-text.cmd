@echo off
rem Double-click to run apply-woled-text.ps1 (it sits next to this file).
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0apply-woled-text.ps1" %*
echo.
pause
