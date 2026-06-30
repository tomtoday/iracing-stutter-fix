@echo off
setlocal EnableDelayedExpansion
title iRacing Pre-Launch Optimizer v3.2 (example)
color 0A

:: ================================================================
:: iRacing Pre-Launch Optimizer — Real System Example v3.2
:: AMD Ryzen 7800X3D / RTX 4090 / Triple 2560x1440 240Hz / Win11
:: ================================================================
:: USE AT YOUR OWN RISK. Run as Administrator.
::
:: This is a real working script from the guide author's system.
:: It will NOT work on your system without changes.
:: Use pre_iracing_launch.bat (the template) instead — it explains
:: exactly what to replace and how to find each value.
::
:: Provided as a reference so you can see what a complete,
:: working script looks like with real values filled in.
:: ================================================================

net session >nul 2>&1
if %errorlevel% neq 0 (
    echo Requesting admin elevation...
    powershell -command "Start-Process cmd -ArgumentList '/k \"%~f0\"' -Verb RunAs"
    exit /b
)
echo [OK]   Running as Administrator

:: Pending reboot check
reg query "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\RebootRequired" >nul 2>&1
if %errorlevel%==0 (echo [WARN] Pending Windows reboot detected) else (echo [OK]   No pending reboot)

:: Defender — suspend real-time monitoring for session (requires Tamper Protection OFF)
start /b "" powershell -NonInteractive -NoProfile -command "Set-MpPreference -DisableRealtimeMonitoring $true" >nul 2>&1
timeout /t 4 /nobreak >nul
powershell -NonInteractive -NoProfile -command "if ((Get-MpPreference).DisableRealtimeMonitoring) { exit 0 } else { exit 1 }" >nul 2>&1
set _DEFENDER_OFF=%errorlevel%
if %_DEFENDER_OFF%==0 (echo [OK]   Defender real-time monitoring suspended) else (echo [WARN] Defender still active - exclusions will be applied as fallback)

:: Xbox Game Bar
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\GameDVR" /v AppCaptureEnabled /t REG_DWORD /d 0 /f >nul 2>&1
echo [OK]   Xbox Game Bar disabled

:: HAGS (Hardware-Accelerated GPU Scheduling)
reg add "HKLM\SYSTEM\CurrentControlSet\Control\GraphicsDrivers" /v HwSchMode /t REG_DWORD /d 1 /f >nul 2>&1
echo [OK]   HAGS disabled

:: Windows Game Mode
reg add "HKCU\Software\Microsoft\GameBar" /v AllowAutoGameMode /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKCU\Software\Microsoft\GameBar" /v AutoGameModeEnabled /t REG_DWORD /d 0 /f >nul 2>&1
echo [OK]   Game Mode disabled

:: USB Selective Suspend
reg add "HKLM\SYSTEM\CurrentControlSet\Services\USB" /v DisableSelectiveSuspend /t REG_DWORD /d 1 /f >nul 2>&1
echo [OK]   USB Selective Suspend disabled

:: DISABLE Windows Update
sc config wuauserv start= disabled >nul 2>&1
sc stop wuauserv >nul 2>&1
timeout /t 2 /nobreak >nul
sc query wuauserv | find "STOPPED" >nul 2>&1
if %errorlevel%==0 (echo [OK]   Windows Update disabled and stopped) else (echo [WARN] Windows Update may still be running)

:: DISABLE Update Orchestrator
sc config UsoSvc start= disabled >nul 2>&1
sc stop UsoSvc >nul 2>&1
echo [OK]   Windows Update Orchestrator disabled

:: DISABLE Windows Search
sc config WSearch start= disabled >nul 2>&1
sc stop WSearch >nul 2>&1
timeout /t 1 /nobreak >nul
sc query WSearch | find "STOPPED" >nul 2>&1
if %errorlevel%==0 (echo [OK]   Windows Search disabled and stopped) else (echo [WARN] Windows Search may still be running)

:: Stop remaining services
sc query Spooler | find "RUNNING" >nul 2>&1
if %errorlevel%==0 (sc stop Spooler >nul 2>&1 & echo [OK]   Print Spooler stopped) else (echo [OK]   Print Spooler already stopped)
sc query WlanSvc | find "RUNNING" >nul 2>&1
if %errorlevel%==0 (sc stop WlanSvc >nul 2>&1 & echo [OK]   WiFi service stopped) else (echo [OK]   WiFi already stopped)
sc query BthAvctpSvc | find "RUNNING" >nul 2>&1
if %errorlevel%==0 (sc stop BthAvctpSvc >nul 2>&1)
sc query BTAGService | find "RUNNING" >nul 2>&1
if %errorlevel%==0 (sc stop BTAGService >nul 2>&1)
sc query bthserv | find "RUNNING" >nul 2>&1
if %errorlevel%==0 (sc stop bthserv >nul 2>&1 & echo [OK]   Bluetooth stopped) else (echo [OK]   Bluetooth already stopped)
sc query XblAuthManager | find "RUNNING" >nul 2>&1
if %errorlevel%==0 (sc stop XblAuthManager >nul 2>&1 & echo [OK]   Xbox Live Auth stopped) else (echo [OK]   Xbox Live Auth already stopped)

:: Backblaze (if installed)
sc query bzserv >nul 2>&1
if %errorlevel%==0 (
    sc query bzserv | find "RUNNING" >nul 2>&1
    if !errorlevel!==0 (sc stop bzserv >nul 2>&1 & echo [OK]   Backblaze stopped) else (echo [OK]   Backblaze already stopped)
) else (echo [OK]   Backblaze not installed)

:: OneDrive
taskkill /IM OneDrive.exe /F >nul 2>&1
timeout /t 2 /nobreak >nul
tasklist | find /i "OneDrive.exe" >nul 2>&1
if %errorlevel%==0 (echo [WARN] OneDrive still running) else (echo [OK]   OneDrive stopped)

:: Close Chrome and Claude
taskkill /IM chrome.exe /F >nul 2>&1
tasklist | find /i "chrome.exe" >nul 2>&1
if %errorlevel%==0 (echo [WARN] Chrome still running) else (echo [OK]   Chrome closed)
taskkill /IM "Claude.exe" /F >nul 2>&1
taskkill /IM "claude-desktop.exe" /F >nul 2>&1
echo [OK]   Claude closed

:: ----------------------------------------------------------------
:: AMD Ryzen Balanced power plan
:: GUID is system-specific — yours will be different.
:: Find yours with: powercfg /list
:: ----------------------------------------------------------------
powercfg /setactive c584c850-222a-4f65-ae2c-fe6e5b7a0c40 >nul 2>&1
if %errorlevel%==0 (echo [OK]   Power plan set to AMD Ryzen Balanced) else (echo [WARN] Could not set AMD Ryzen Balanced - check GUID)

:: Process Lasso
tasklist | find /i "ProcessLasso.exe" >nul 2>&1
if %errorlevel%==0 (
    echo [OK]   Process Lasso running
) else (
    echo [WARN] Starting Process Lasso...
    start "" "C:\Program Files\Process Lasso\ProcessLasso.exe"
    timeout /t 3 /nobreak >nul
)

:: Monitor refresh rate check
for /f "tokens=*" %%a in ('powershell -command "(Get-WmiObject Win32_VideoController | Where-Object {$_.Name -like '*NVIDIA*'}).CurrentRefreshRate" 2^>nul') do set MONHZ=%%a
if defined MONHZ (
    if !MONHZ! GEQ 230 (
        echo [OK]   Monitor refresh rate: !MONHZ! Hz
    ) else (
        color 0C
        echo [FAIL] Monitor refresh rate: !MONHZ! Hz - must be at max Hz before racing
        echo        Fix: Settings ^> System ^> Display ^> Advanced display ^> refresh rate
        echo        Do this for ALL monitors, then re-run this script
        pause
        color 0A
    )
) else (
    echo [WARN] Could not check monitor refresh rate
)

:: Trophi.ai CPU affinity (CPUs 12-15 = 0xF000) — remove if not using Trophi.ai
powershell -command "$procs = @('trophi.ai','trophi.ai.messagebroker','trophi.ai.profiler','UnityCrashHandler64'); foreach ($n in $procs) { $p = Get-Process $n -ErrorAction SilentlyContinue; if ($p) { $p | ForEach-Object { $_.ProcessorAffinity = [IntPtr]0xF000 } } }" >nul 2>&1
echo [OK]   Trophi.ai processes pinned to CPUs 12-15

:: ----------------------------------------------------------------
:: NVIDIA interrupt affinity — all 5 device instances to CPU 7
:: Step 1: MSI mode disabled per instance (required on Win11 — without this, affinity is ignored)
:: Step 2: AssignmentSetOverride = 8000000000000000 (REG_BINARY, little-endian = CPU 7)
::
:: These instance IDs are specific to this RTX 4090 system.
:: Find yours: see guide.html Section 05 for the full discovery commands.
:: Note: instance "4" (bare number) appeared after the 610.62 driver install.
:: ----------------------------------------------------------------
set "_NVINST=4"
call :nvidia_affinity
set "_NVINST=4&15a5c264&0&000B"
call :nvidia_affinity
set "_NVINST=4&15a5c2648&0&000B"
call :nvidia_affinity
set "_NVINST=4&1BABDF5B&0&0009"
call :nvidia_affinity
set "_NVINST=4&285f7309&0&000C"
call :nvidia_affinity
echo [OK]   NVIDIA MSI disabled + affinity CPU7 on all 5 instances

:: Defender exclusions — fallback if suspension failed
if %_DEFENDER_OFF%==0 goto :skip_exclusions
echo [WARN] Applying Defender exclusions as fallback...
set "_DP=C:\Program Files (x86)\iRacing" & set "_DL=iRacing install" & call :defender_path
set "_DP=%USERPROFILE%\OneDrive\Equipment\iRacing" & set "_DL=iRacing documents" & call :defender_path
set "_DP=C:\Program Files\Process Lasso" & set "_DL=Process Lasso" & call :defender_path
set "_DP=C:\Program Files\CapFrameX" & set "_DL=CapFrameX" & call :defender_path
set "_DP=%LOCALAPPDATA%\trophi.ai" & set "_DL=Trophi.ai" & call :defender_path
set "_DP=C:\Program Files (x86)\RhinoDe LLC\Trading Paints" & set "_DL=Trading Paints" & call :defender_path
set "_DC=iRacingSim64DX11.exe" & call :defender_proc
set "_DC=iracinglocalserver64.exe" & call :defender_proc
set "_DC=iRacingService.exe" & call :defender_proc
set "_DC=CapFrameX.exe" & call :defender_proc
set "_DC=LatencyMon.exe" & call :defender_proc
set "_DC=trading paints.exe" & call :defender_proc
set "_DC=ProcessLasso.exe" & call :defender_proc
set "_DC=SimProManager.exe" & call :defender_proc
goto :after_exclusions
:skip_exclusions
echo [OK]   Defender exclusion checks skipped - monitoring suspended
:after_exclusions

:: NVIDIA driver version check
:: 32.0.16.1062 = driver 610.62 in WMI format. Update this after each driver install:
::   wmic path Win32_VideoController where "Name like '%NVIDIA%'" get DriverVersion
for /f "tokens=*" %%a in ('powershell -command "(Get-WmiObject Win32_VideoController | Where-Object {$_.Name -like '*NVIDIA*'}).DriverVersion" 2^>nul') do set NVDRIVER=%%a
if defined NVDRIVER (
    if "!NVDRIVER!"=="32.0.16.1062" (echo [OK]   NVIDIA driver confirmed: !NVDRIVER!) else (echo [WARN] NVIDIA driver changed: !NVDRIVER! - re-verify GoInterruptPolicy after driver updates)
) else (echo [WARN] Could not read NVIDIA driver version)

:: Final wuauserv check
sc query wuauserv | find "RUNNING" >nul 2>&1
if %errorlevel%==0 (sc stop wuauserv >nul 2>&1 & echo [WARN] Windows Update restarted itself - stopped again) else (echo [OK]   Windows Update confirmed stopped)

echo.
echo ============================================================
echo   Pre-launch complete. Launch iRacing now.
echo   Run post_iracing_session.bat when done racing.
echo ============================================================
echo.
pause
goto :eof

:nvidia_affinity
set "_BASE=HKLM\System\CurrentControlSet\Enum\PCI\VEN_10DE&DEV_2684&SUBSYS_88EF1043&REV_A1\!_NVINST!\Device Parameters\Interrupt Management"
:: Disable MSI mode — required on Win11 or affinity is silently ignored
reg add "!_BASE!\MessageSignaledInterruptProperties" /v MSISupported /t REG_DWORD /d 0 /f >nul 2>&1
:: Set interrupt affinity to CPU 7
reg add "!_BASE!\Affinity Policy" /v DevicePolicy /t REG_DWORD /d 4 /f >nul 2>&1
reg add "!_BASE!\Affinity Policy" /v AssignmentSetOverride /t REG_BINARY /d 8000000000000000 /f >nul 2>&1
reg add "!_BASE!\Affinity Policy" /v DevicePriority /t REG_DWORD /d 3 /f >nul 2>&1
if !errorlevel!==0 (echo [OK]   NVIDIA MSI disabled + affinity CPU7: "!_NVINST!") else (echo [WARN] Could not set: "!_NVINST!")
exit /b

:defender_path
powershell -command "$p=(Get-MpPreference).ExclusionPath; if ($p -contains '!_DP!') { exit 0 } else { exit 1 }" >nul 2>&1
if !errorlevel!==1 (
    powershell -command "Add-MpPreference -ExclusionPath '!_DP!'" >nul 2>&1
    if !errorlevel!==0 (echo [FIXED] Defender exclusion added: "!_DL!") else (echo [FAIL]  Could not add: "!_DP!")
) else (echo [OK]    Defender exclusion: "!_DL!")
exit /b

:defender_proc
powershell -command "$p=(Get-MpPreference).ExclusionProcess; if ($p -contains '!_DC!') { exit 0 } else { exit 1 }" >nul 2>&1
if !errorlevel!==1 (
    powershell -command "Add-MpPreference -ExclusionProcess '!_DC!'" >nul 2>&1
    if !errorlevel!==0 (echo [FIXED] Defender process exclusion added: "!_DC!") else (echo [FAIL]  Could not add: "!_DC!")
) else (echo [OK]    Defender exclusion: "!_DC!" ^(process^))
exit /b
