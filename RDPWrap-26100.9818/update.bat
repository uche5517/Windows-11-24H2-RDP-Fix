@echo off
setlocal
title RDP Wrapper 1.6.2 - re-apply configuration

rem ---- require administrator -------------------------------------------
net session >nul 2>&1
if errorlevel 1 (
    echo [*] Requesting administrator rights...
    powershell -NoProfile -Command "Start-Process -FilePath '%~f0' -Verb RunAs"
    exit /b
)

if not exist "%~dp0rdpwrap.ini" goto :noini

echo [*] Re-applying RDP Wrapper...
"%~dp0RDPWInst.exe" -w
if errorlevel 1 goto :failed

copy /y "%~dp0rdpwrap.ini" "%ProgramFiles%\RDP Wrapper\rdpwrap.ini" >nul

echo [*] Restarting TermService...
net stop TermService /y >nul 2>&1
net start TermService >nul 2>&1

echo.
echo [OK] Done. Check with RDPConf.exe.
echo.
pause
exit /b 0

:noini
echo [-] rdpwrap.ini is missing from this folder.
goto :pause_end

:failed
echo [-] Update failed. Run regen-offsets.bat - your build may need new offsets.
goto :pause_end

:pause_end
pause
exit /b 1
