@echo off
setlocal
title RDP Wrapper 1.6.2 - install for 10.0.26100.9818

rem ---- require administrator -------------------------------------------
net session >nul 2>&1
if errorlevel 1 (
    echo [*] Requesting administrator rights...
    powershell -NoProfile -Command "Start-Process -FilePath '%~f0' -Verb RunAs"
    exit /b
)

if not exist "%~dp0RDPWInst.exe" goto :noinst
if not exist "%~dp0rdpwrap.ini" goto :noini

echo [*] Installing RDP Wrapper Library...
"%~dp0RDPWInst.exe" -i -o
if errorlevel 1 goto :failed

echo.
echo [*] Copying the 10.0.26100.9818 configuration into place...
copy /y "%~dp0rdpwrap.ini" "%ProgramFiles%\RDP Wrapper\rdpwrap.ini" >nul

echo [*] Restarting TermService so the new configuration is loaded...
net stop TermService /y >nul 2>&1
net start TermService >nul 2>&1

echo.
echo [OK] Installed. Configuration:
echo      %ProgramFiles%\RDP Wrapper\rdpwrap.ini
echo.
echo      Opening RDPConf - everything should be green / "fully supported".
start "" "%~dp0RDPConf.exe"
echo.
echo      If RDPConf shows a red row, run regen-offsets.bat and see README.md ^(troubleshooting^).
echo.
pause
exit /b 0

:noinst
echo [-] RDPWInst.exe is missing from this folder.
echo     Antivirus may have quarantined it - see README.md.
goto :pause_end

:noini
echo [-] rdpwrap.ini is missing from this folder.
goto :pause_end

:failed
echo [-] Installer failed. See README.md ^(troubleshooting^).
goto :pause_end

:pause_end
pause
exit /b 1
