@echo off
setlocal
title iRacing - Find My Values
color 0B

echo ============================================================
echo   find_my_values.bat   (READ-ONLY - changes nothing)
echo   Prints the per-machine values needed by the CONFIG block
echo   in pre_iracing_launch.bat. Copy each value into the
echo   matching  set "..."  line there.
echo   Tip: run as Administrator for the most complete results.
echo ============================================================
echo.

echo [NVIDIA GPU base, driver, and device instances]
powershell -NoProfile -ExecutionPolicy Bypass -Command "$ErrorActionPreference='SilentlyContinue'; $d=Get-CimInstance Win32_VideoController | Where-Object {$_.Name -match 'NVIDIA'} | Select-Object -First 1; if(-not $d){Write-Host '  No NVIDIA GPU detected.'; exit}; $base=($d.PNPDeviceID -split '\\')[1]; Write-Host ('  NV_BASE   = HKLM\System\CurrentControlSet\Enum\PCI\' + $base); Write-Host ('  NV_DRIVER = ' + $d.DriverVersion); $ins=Get-ChildItem ('HKLM:\SYSTEM\CurrentControlSet\Enum\PCI\' + $base) | Select-Object -ExpandProperty PSChildName; if($ins){$i=1; foreach($x in $ins){Write-Host ('  NV_INST' + $i + '  = ' + $x); $i++}} else {Write-Host '  (could not read device instances - try running as Administrator)'}"
echo.

echo [AMD Ryzen Balanced power plan GUID]
powershell -NoProfile -ExecutionPolicy Bypass -Command "$p=powercfg /list | Select-String 'Ryzen Balanced'; if($p){$g=([regex]'[0-9a-fA-F-]{36}').Match($p.ToString()).Value; Write-Host ('  POWER_GUID = ' + $g)} else {Write-Host '  AMD Ryzen Balanced plan not found - create it (guide Section 06), then re-run.'}"
echo.
echo   All power plans (for reference):
powercfg /list
echo.

echo [CPU topology hint for NV_CPU_MASK]
echo   Logical processors on this machine: %NUMBER_OF_PROCESSORS%
echo   With SMT on, logical CPUs pair by physical core:
echo     0/1 = core 0,  2/3 = core 1,  4/5 = core 2,  ...
echo   Pick a core away from CPU 0 (the sim thread). Mask = 1
echo   shifted left by the CPU number, in hex (e.g. CPU 4 = 10).
echo   Best practice: benchmark with AutoGpuAffinity.
echo.

echo ============================================================
echo   Done. Paste these into the CONFIG block of
echo   pre_iracing_launch.bat, then verify with LatencyMon.
echo ============================================================
echo.
pause
