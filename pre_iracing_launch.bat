@echo off
setlocal EnableDelayedExpansion
title iRacing Pre-Launch Optimizer v2.3
color 0A

echo ============================================================
echo   iRacing Pre-Launch Optimizer v2.3
echo   7800X3D / RTX 4090 / Triple 2560x1440 240Hz
echo ============================================================
echo.

net session >nul 2>&1
if %errorlevel% neq 0 (
    color 0C
    echo [FAIL] Must run as Administrator
    pause
    exit /b 1
)
echo [OK]   Running as Administrator

:: ---------------------------------------------------------------
:: Pending reboot check
:: ---------------------------------------------------------------
reg query "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\RebootRequired" >nul 2>&1
if %errorlevel%==0 (echo [WARN] Pending Windows reboot detected) else (echo [OK]   No pending reboot)

:: ---------------------------------------------------------------
:: Xbox Game Bar
:: ---------------------------------------------------------------
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\GameDVR" /v AppCaptureEnabled /t REG_DWORD /d 0 /f >nul 2>&1
echo [OK]   Xbox Game Bar disabled

:: ---------------------------------------------------------------
:: NVIDIA interrupt affinity - all three device instances
:: Windows alternates between instances on reboot so set all three
:: AssignmentSetOverride 10 (hex) = CPU 4 (Thread 4, Core 2)
:: DevicePolicy 4 = IrqPolicySpecifiedProcessors
:: DevicePriority 3 = High
:: ---------------------------------------------------------------
set NVIDIA_BASE=HKLM\System\CurrentControlSet\Enum\PCI\VEN_10DE^&DEV_2684^&SUBSYS_88EF1043^&REV_A1

reg add "%NVIDIA_BASE%\4^&15a5c2648^&0^&000B\Device Parameters\Interrupt Management\Affinity Policy" /v DevicePolicy /t REG_DWORD /d 4 /f >nul 2>&1
reg add "%NVIDIA_BASE%\4^&15a5c2648^&0^&000B\Device Parameters\Interrupt Management\Affinity Policy" /v AssignmentSetOverride /t REG_BINARY /d 10 /f >nul 2>&1
reg add "%NVIDIA_BASE%\4^&15a5c2648^&0^&000B\Device Parameters\Interrupt Management\Affinity Policy" /v DevicePriority /t REG_DWORD /d 3 /f >nul 2>&1

reg add "%NVIDIA_BASE%\4^&1babdf5b^&0^&0009\Device Parameters\Interrupt Management\Affinity Policy" /v DevicePolicy /t REG_DWORD /d 4 /f >nul 2>&1
reg add "%NVIDIA_BASE%\4^&1babdf5b^&0^&0009\Device Parameters\Interrupt Management\Affinity Policy" /v AssignmentSetOverride /t REG_BINARY /d 10 /f >nul 2>&1
reg add "%NVIDIA_BASE%\4^&1babdf5b^&0^&0009\Device Parameters\Interrupt Management\Affinity Policy" /v DevicePriority /t REG_DWORD /d 3 /f >nul 2>&1

reg add "%NVIDIA_BASE%\4^&285f7309^&0^&000C\Device Parameters\Interrupt Management\Affinity Policy" /v DevicePolicy /t REG_DWORD /d 4 /f >nul 2>&1
reg add "%NVIDIA_BASE%\4^&285f7309^&0^&000C\Device Parameters\Interrupt Management\Affinity Policy" /v AssignmentSetOverride /t REG_BINARY /d 10 /f >nul 2>&1
reg add "%NVIDIA_BASE%\4^&285f7309^&0^&000C\Device Parameters\Interrupt Management\Affinity Policy" /v DevicePriority /t REG_DWORD /d 3 /f >nul 2>&1

echo [OK]   NVIDIA interrupt affinity set on all 3 device instances (CPU 4 / Thread 4)

:: ---------------------------------------------------------------
:: DISABLE Windows Update (prevents mid-session restart)
:: ---------------------------------------------------------------
sc config wuauserv start= disabled >nul 2>&1
sc stop wuauserv >nul 2>&1
timeout /t 2 /nobreak >nul
sc query wuauserv | find "STOPPED" >nul 2>&1
if %errorlevel%==0 (echo [OK]   Windows Update disabled and stopped) else (echo [WARN] Windows Update may still be running)

:: ---------------------------------------------------------------
:: DISABLE Update Orchestrator
:: ---------------------------------------------------------------
sc config UsoSvc start= disabled >nul 2>&1
sc stop UsoSvc >nul 2>&1
timeout /t 1 /nobreak >nul
echo [OK]   Update Orchestrator disabled

:: ---------------------------------------------------------------
:: DISABLE Windows Search
:: ---------------------------------------------------------------
sc config WSearch start= disabled >nul 2>&1
sc stop WSearch >nul 2>&1
timeout /t 1 /nobreak >nul
sc query WSearch | find "STOPPED" >nul 2>&1
if %errorlevel%==0 (echo [OK]   Windows Search disabled and stopped) else (echo [WARN] Windows Search may still be running)

:: ---------------------------------------------------------------
:: SysMain
:: ---------------------------------------------------------------
sc query SysMain | find "RUNNING" >nul 2>&1
if %errorlevel%==0 (sc stop SysMain >nul 2>&1 & echo [OK]   SysMain stopped) else (echo [OK]   SysMain already stopped)

:: ---------------------------------------------------------------
:: Print Spooler
:: ---------------------------------------------------------------
sc query Spooler | find "RUNNING" >nul 2>&1
if %errorlevel%==0 (sc stop Spooler >nul 2>&1 & echo [OK]   Print Spooler stopped) else (echo [OK]   Print Spooler already stopped)

:: ---------------------------------------------------------------
:: WiFi
:: ---------------------------------------------------------------
sc query WlanSvc | find "RUNNING" >nul 2>&1
if %errorlevel%==0 (sc stop WlanSvc >nul 2>&1 & echo [OK]   WiFi stopped) else (echo [OK]   WiFi already stopped)

:: ---------------------------------------------------------------
:: Bluetooth
:: ---------------------------------------------------------------
sc query BthAvctpSvc | find "RUNNING" >nul 2>&1
if %errorlevel%==0 (sc stop BthAvctpSvc >nul 2>&1)
sc query BTAGService | find "RUNNING" >nul 2>&1
if %errorlevel%==0 (sc stop BTAGService >nul 2>&1)
sc query bthserv | find "RUNNING" >nul 2>&1
if %errorlevel%==0 (sc stop bthserv >nul 2>&1 & echo [OK]   Bluetooth stopped) else (echo [OK]   Bluetooth already stopped)

:: ---------------------------------------------------------------
:: Xbox Live
:: ---------------------------------------------------------------
sc query XblAuthManager | find "RUNNING" >nul 2>&1
if %errorlevel%==0 (sc stop XblAuthManager >nul 2>&1 & echo [OK]   Xbox Live Auth stopped) else (echo [OK]   Xbox Live Auth already stopped)

:: ---------------------------------------------------------------
:: Backblaze
:: ---------------------------------------------------------------
sc query bzserv >nul 2>&1
if %errorlevel%==0 (
    sc query bzserv | find "RUNNING" >nul 2>&1
    if !errorlevel!==0 (sc stop bzserv >nul 2>&1 & echo [OK]   Backblaze stopped) else (echo [OK]   Backblaze already stopped)
) else (echo [OK]   Backblaze not running)

:: ---------------------------------------------------------------
:: Power plan - AMD Ryzen Balanced
:: ---------------------------------------------------------------
powercfg /setactive c584c850-222a-4f65-ae2c-fe6e5b7a0c40 >nul 2>&1
if %errorlevel%==0 (echo [OK]   Power plan set to AMD Ryzen Balanced) else (echo [WARN] Could not set AMD Ryzen Balanced)

:: ---------------------------------------------------------------
:: Process Lasso
:: ---------------------------------------------------------------
tasklist | find /i "ProcessLasso.exe" >nul 2>&1
if %errorlevel%==0 (
    echo [OK]   Process Lasso running
) else (
    echo [WARN] Starting Process Lasso...
    start "" "C:\Program Files\Process Lasso\ProcessLasso.exe"
    timeout /t 3 /nobreak >nul
    tasklist | find /i "ProcessLasso.exe" >nul 2>&1
    if !errorlevel!==0 (echo [OK]   Process Lasso started) else (echo [FAIL] Could not start Process Lasso)
)

:: ---------------------------------------------------------------
:: Defender exclusion check
:: ---------------------------------------------------------------
powershell -command "if ((Get-MpPreference).ExclusionPath -contains 'C:\Program Files (x86)\iRacing') { exit 0 } else { exit 1 }" >nul 2>&1
if %errorlevel%==0 (echo [OK]   Defender iRacing exclusion active) else (echo [WARN] Defender exclusion missing)

:: ---------------------------------------------------------------
:: NVIDIA driver version check
:: ---------------------------------------------------------------
for /f "tokens=*" %%a in ('powershell -command "(Get-WmiObject Win32_VideoController | Where-Object {$_.Name -like '*NVIDIA*'}).DriverVersion" 2^>nul') do set NVDRIVER=%%a
if defined NVDRIVER (
    if "!NVDRIVER!"=="32.0.15.9649" (echo [OK]   NVIDIA driver confirmed: !NVDRIVER!) else (echo [WARN] NVIDIA driver changed: !NVDRIVER! - re-verify affinity settings)
) else (echo [WARN] Could not read NVIDIA driver version)

:: ---------------------------------------------------------------
:: Final wuauserv check
:: ---------------------------------------------------------------
sc query wuauserv | find "RUNNING" >nul 2>&1
if %errorlevel%==0 (sc stop wuauserv >nul 2>&1 & echo [WARN] Windows Update restarted - stopped again) else (echo [OK]   Windows Update confirmed stopped)

echo.
echo ============================================================
echo   Pre-launch complete. Launch iRacing now.
echo   Run post_iracing_session.bat when done racing.
echo ============================================================
echo.
pause
