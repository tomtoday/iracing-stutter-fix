@echo off
setlocal EnableDelayedExpansion
title iRacing Post-Session Restore v2.2
color 0B

echo ============================================================
echo   iRacing Post-Session Restore v2.2
echo   Re-enabling services disabled before racing
echo ============================================================
echo.

net session >nul 2>&1
if %errorlevel% neq 0 (color 0C & echo [FAIL] Must run as Administrator & pause & exit /b 1)
echo [OK]   Running as Administrator
echo.

:: Re-enable and start services that were DISABLED
sc config wuauserv start= auto >nul 2>&1
sc start wuauserv >nul 2>&1
sc query wuauserv | find "RUNNING" >nul 2>&1
if %errorlevel%==0 (echo [OK]   Windows Update re-enabled and started) else (echo [WARN] Windows Update re-enabled - may take a moment)

sc config UsoSvc start= auto >nul 2>&1
sc start UsoSvc >nul 2>&1
echo [OK]   Update Orchestrator re-enabled

sc config WSearch start= delayed-auto >nul 2>&1
sc start WSearch >nul 2>&1
timeout /t 2 /nobreak >nul
sc query WSearch | find "RUNNING" >nul 2>&1
if %errorlevel%==0 (echo [OK]   Windows Search re-enabled and started) else (echo [WARN] Windows Search re-enabled - may take a moment)

:: Restart services that were only stopped
sc start SysMain >nul 2>&1 & echo [OK]   SysMain started
sc start Spooler >nul 2>&1 & echo [OK]   Print Spooler started
sc start WlanSvc >nul 2>&1 & echo [OK]   WiFi started
sc start bthserv >nul 2>&1
timeout /t 1 /nobreak >nul
sc start BthAvctpSvc >nul 2>&1
sc start BTAGService >nul 2>&1
echo [OK]   Bluetooth started
sc start XblAuthManager >nul 2>&1 & echo [OK]   Xbox Live Auth started

:: Backblaze
sc query bzserv >nul 2>&1
if %errorlevel%==0 (sc start bzserv >nul 2>&1 & echo [OK]   Backblaze started)

:: Restore Xbox Game Bar
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\GameDVR" /v AppCaptureEnabled /t REG_DWORD /d 1 /f >nul 2>&1
echo [OK]   Xbox Game Bar restored

echo.
echo ============================================================
echo   Post-session restore complete.
echo   All services restored to normal operation.
echo ============================================================
echo.
pause
