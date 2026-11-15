@echo off
setlocal
title RDP Wrapper 1.6.2 - uninstall

rem ---- require administrator -------------------------------------------
net session >nul 2>&1
if errorlevel 1 (
    echo [*] Requesting administrator rights...
    powershell -NoProfile -Command "Start-Process -FilePath '%~f0' -Verb RunAs"
    exit /b
)

if not exist "%~dp0RDPWInst.exe" goto :noinst

echo [*] Removing RDP Wrapper (restores TermService ServiceDll to termsrv.dll)...
"%~dp0RDPWInst.exe" -u
if errorlevel 1 goto :failed

echo [*] Restarting TermService...
net stop TermService /y >nul 2>&1
net start TermService >nul 2>&1

echo.
echo [OK] Uninstalled. Single-session RDP behaviour is restored.
echo.
pause
exit /b 0

:noinst
echo [-] RDPWInst.exe is missing from this folder.
goto :pause_end

:failed
echo [-] Uninstall failed. See README.md ^(troubleshooting^).
goto :pause_end

:pause_end
pause
exit /b 1
