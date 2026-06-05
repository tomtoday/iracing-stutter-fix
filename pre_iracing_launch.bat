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

:: ===============================================================
:: CONFIG  --  REPLACE EVERYTHING IN THIS BLOCK WITH YOUR VALUES
:: The values below are examples from the system this guide was
:: built on (7800X3D / RTX 4090). They will NOT match your machine.
:: Run find_my_values.bat to discover your own, or see Sections 05
:: and 06 of guide.html.
:: ===============================================================

:: NVIDIA GPU registry base -- the VEN/DEV/SUBSYS/REV portion of your
:: GPU's PCI DeviceID. Find with:
::   wmic path Win32_PnPEntity where "Name like '%NVIDIA%'" get DeviceID
set "NV_BASE=HKLM\System\CurrentControlSet\Enum\PCI\VEN_10DE&DEV_2684&SUBSYS_88EF1043&REV_A1"

:: NVIDIA device instance IDs -- the trailing segment after the base.
:: Windows alternates between them on reboot, so list ALL of yours.
:: Leave unused slots empty. Use plain & (no ^ carets).
set "NV_INST1=4&15a5c2648&0&000B"
set "NV_INST2=4&1babdf5b&0&0009"
set "NV_INST3=4&285f7309&0&000C"

:: Target logical CPU for GPU interrupts, as a KAFFINITY hex bitmask.
::
:: WHY move them at all: iRacing's sim/physics thread runs on CPU 0. Any
:: GPU interrupt (DPC) that also fires on CPU 0 preempts the sim thread
:: and shows up as a stutter. Pinning GPU interrupts to a different
:: PHYSICAL core removes that contention.
::
:: WHY CPU 4 (7800X3D, 8c/16t, SMT on): logical CPUs pair up by physical
:: core -- 0/1 = core0, 2/3 = core1, 4/5 = core2, etc. CPU 0 is the sim
:: thread, so we want a different physical core -- not CPU 1, which is
:: CPU 0's SMT sibling on the same core. CPU 4 is the first thread of
:: core 2, leaving a little breathing room around the sim thread. It is a
:: sensible default, NOT a proven optimum (see "benchmark it" below).
:: X3D chips are single-CCD, so every core shares the V-cache -- the
:: choice is about dodging busy cores, not cache locality.
::
:: HOW the mask works: one bit per logical CPU, value = 1 << cpu_number.
::   CPU 0 -> 01   CPU 2 -> 04   CPU 4 -> 10   CPU 6 -> 40
:: One byte (two hex digits) covers CPU 0-7. Targeting CPU 8+ needs a
:: multi-byte LITTLE-ENDIAN value (REG_BINARY) that is easy to get wrong
:: by hand -- e.g. CPU 8 is 0001, not 0100. Let AutoGpuAffinity write it,
:: and ALWAYS confirm in LatencyMon that DPC load actually moved to your
:: target core and not back onto CPU 0.
::
:: HOW to find the best core for YOUR system: don't guess -- benchmark it.
:: AutoGpuAffinity (github.com/valleyofdoom/AutoGpuAffinity) tests each
:: core and reports which gives the lowest frame times. Afterwards,
:: LatencyMon confirms DPC load actually moved off CPU 0 onto your target.
set "NV_CPU_MASK=10"

:: AMD Ryzen Balanced power plan GUID. Find with:  powercfg /list
set "POWER_GUID=c584c850-222a-4f65-ae2c-fe6e5b7a0c40"

:: Expected NVIDIA driver version (the DriverVersion string, not the
:: marketing number). find_my_values.bat prints it.
set "NV_DRIVER=32.0.15.9649"
:: ===============================================================

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
:: NVIDIA interrupt affinity - applied to every configured instance
:: DevicePolicy 4        = IrqPolicySpecifiedProcessors
:: AssignmentSetOverride = NV_CPU_MASK (hex bitmask, see CONFIG)
:: DevicePriority 3      = High
:: Instance IDs come from CONFIG and are expanded INSIDE the quotes,
:: so the & stays literal and the real registry key is targeted.
:: ---------------------------------------------------------------
for %%I in ("%NV_INST1%" "%NV_INST2%" "%NV_INST3%") do if not "%%~I"=="" (
    reg add "%NV_BASE%\%%~I\Device Parameters\Interrupt Management\Affinity Policy" /v DevicePolicy /t REG_DWORD /d 4 /f >nul 2>&1
    reg add "%NV_BASE%\%%~I\Device Parameters\Interrupt Management\Affinity Policy" /v AssignmentSetOverride /t REG_BINARY /d %NV_CPU_MASK% /f >nul 2>&1
    reg add "%NV_BASE%\%%~I\Device Parameters\Interrupt Management\Affinity Policy" /v DevicePriority /t REG_DWORD /d 3 /f >nul 2>&1
)
echo [OK]   NVIDIA interrupt affinity applied to configured instances (mask %NV_CPU_MASK%)

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
powercfg /setactive %POWER_GUID% >nul 2>&1
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
    if "!NVDRIVER!"=="%NV_DRIVER%" (echo [OK]   NVIDIA driver confirmed: !NVDRIVER!) else (echo [WARN] NVIDIA driver changed: !NVDRIVER! - re-verify affinity settings)
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
