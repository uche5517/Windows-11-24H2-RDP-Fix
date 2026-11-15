@echo off
setlocal
title RDP Wrapper - regenerate offsets for the current build

rem Reads the installed termsrv.dll and prints the ini section for THIS build.
rem Run this after a Windows update: if RDPConf turns red, generate the new
rem section, paste it into rdpwrap.ini, then run update.bat.

set "FINDER=%~dp0..\RDPWrapOffsetFinder-1.0\64bit\RDPWrapOffsetFinder.exe"
if /i not "%PROCESSOR_ARCHITECTURE%"=="AMD64" set "FINDER=%~dp0..\RDPWrapOffsetFinder-1.0\32bit\RDPWrapOffsetFinder.exe"
if not exist "%FINDER%" set "FINDER=%USERPROFILE%\Desktop\RDP project\RDPWrapOffsetFinder-1.0\64bit\RDPWrapOffsetFinder.exe"

if not exist "%FINDER%" (
    echo [-] RDPWrapOffsetFinder.exe not found.
    echo     Expected next to this folder at: ..\RDPWrapOffsetFinder-1.0\64bit\
    pause
    exit /b 1
)

echo [*] Using: %FINDER%
echo [*] Reading %SystemRoot%\System32\termsrv.dll ...
echo.

pushd "%~dp0"
"%FINDER%" > "%~dp0offsets-current.ini" 2>&1
popd

if errorlevel 1 (
    echo [-] Offset finder failed. Run it from its own folder to see the error.
    pause
    exit /b 1
)

type "%~dp0offsets-current.ini"
echo.
echo [OK] Section above written to offsets-current.ini
echo     Paste it into rdpwrap.ini ^(keep the [x.y.build.ubr] and
echo     [-SLInit] headers^), then run update.bat.
echo.
pause
