@echo off
setlocal
title iRacing - Find My Values
color 0B

echo ============================================================
echo   find_my_values.bat   (READ-ONLY - changes nothing)
echo   Prints the per-machine values for the three
echo   "=== CUSTOMIZE ===" sections in pre_iracing_launch.bat.
echo   Tip: run as Administrator for the most complete results.
echo ============================================================
echo.

echo [CUSTOMIZE 1 of 3 - AMD Ryzen Balanced power plan GUID]
powershell -NoProfile -ExecutionPolicy Bypass -Command "$p=powercfg /list | Select-String 'Ryzen Balanced'; if($p){$g=([regex]'[0-9a-fA-F-]{36}').Match($p.ToString()).Value; Write-Host ('  POWER_GUID = ' + $g)} else {Write-Host '  AMD Ryzen Balanced plan not found - create it (guide Section 06), then re-run.'}"
echo.

echo [CUSTOMIZE 2 of 3 - NVIDIA GPU VEN/DEV path + device instances]
powershell -NoProfile -ExecutionPolicy Bypass -Command "$ErrorActionPreference='SilentlyContinue'; $d=Get-CimInstance Win32_VideoController | Where-Object {$_.Name -match 'NVIDIA'} | Select-Object -First 1; if(-not $d){Write-Host '  No NVIDIA GPU detected.'; exit}; $base=($d.PNPDeviceID -split '\\')[1]; Write-Host ('  VEN/DEV path = HKLM\System\CurrentControlSet\Enum\PCI\' + $base); $ins=Get-ChildItem ('HKLM:\SYSTEM\CurrentControlSet\Enum\PCI\' + $base) | Select-Object -ExpandProperty PSChildName; if($ins){$i=1; foreach($x in $ins){Write-Host ('  INSTANCE ' + $i + '   = ' + $x); $i++}} else {Write-Host '  (could not read device instances - try running as Administrator)'}"
echo.

echo [CUSTOMIZE 3 of 3 - NVIDIA driver version string]
powershell -NoProfile -ExecutionPolicy Bypass -Command "$d=Get-CimInstance Win32_VideoController | Where-Object {$_.Name -match 'NVIDIA'} | Select-Object -First 1; if($d){Write-Host ('  NV_DRIVER = ' + $d.DriverVersion)} else {Write-Host '  No NVIDIA GPU detected.'}"
echo.

echo   Note: the template applies MSI disable + interrupt affinity to
echo   CPU 7 automatically (not a value you fill in). To target a
echo   different core, see Section 05 and benchmark with AutoGpuAffinity.
echo.

echo ============================================================
echo   Done. Paste these into the matching "=== CUSTOMIZE ==="
echo   sections of pre_iracing_launch.bat, then verify with LatencyMon.
echo ============================================================
echo.
pause
