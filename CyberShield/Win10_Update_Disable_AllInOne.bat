@echo off
:: ============================================================
::  Win10 ALL-IN-ONE: Permanent Update Disable + Red Dot Remove
::  - Blocks Windows Update permanently (with auto-guard)
::  - Removes update tray icon / red dot / restart notifications
::  - Troubleshoot tools that will NOT re-enable updates
::  - Does NOT touch internet / DNS / browser
:: ============================================================
if /i "%~1"=="/guard" goto GUARD

title Win10 All-In-One Update Disable
setlocal EnableDelayedExpansion

net session >nul 2>&1
if %errorlevel% neq 0 (
    powershell -NoProfile -Command "Start-Process -FilePath '%~f0' -Verb RunAs"
    exit /b
)

:MENU
cls
echo ============================================================
echo   WIN10 ALL-IN-ONE: UPDATE DISABLE + RED DOT REMOVE
echo ============================================================
echo   1. DISABLE updates permanently + REMOVE red dot (recommended)
echo   2. RESTORE everything to default
echo   3. Check status
echo   ----------------------------------------------------------
echo   4. Troubleshoot: Repair system files (SFC + DISM)
echo   5. Troubleshoot: Check disk (runs at next reboot)
echo   6. Troubleshoot: Internet quick-fix (DNS flush only)
echo   7. Clean temp files
echo   8. Create restore point
echo   0. Exit
echo ============================================================
set /p choice=Choose: 
if "%choice%"=="1" goto DISABLE
if "%choice%"=="2" goto RESTOREALL
if "%choice%"=="3" goto STATUS
if "%choice%"=="4" goto REPAIR
if "%choice%"=="5" goto CHKDSK
if "%choice%"=="6" goto NETFIX
if "%choice%"=="7" goto CLEAN
if "%choice%"=="8" goto RESTOREPT
if "%choice%"=="0" exit /b
goto MENU

:: ------------------------------------------------------------
:DISABLE
cls
echo [*] Creating restore point...
powershell -NoProfile -Command "Enable-ComputerRestore -Drive $env:SystemDrive; Checkpoint-Computer -Description 'Before update disable' -RestorePointType MODIFY_SETTINGS" >nul 2>&1

echo [*] Blocking updates + removing red dot...
call :APPLY

echo [*] Installing guard (re-applies at every startup + every 15 min)...
if not exist "%ProgramData%\WUGuard" mkdir "%ProgramData%\WUGuard"
copy /y "%~f0" "%ProgramData%\WUGuard\guard.bat" >nul
schtasks /Create /TN "WUGuard_Startup" /TR "\"%ProgramData%\WUGuard\guard.bat\" /guard" /SC ONSTART /RU SYSTEM /RL HIGHEST /F >nul
schtasks /Create /TN "WUGuard_Repeat"  /TR "\"%ProgramData%\WUGuard\guard.bat\" /guard" /SC MINUTE /MO 15 /RU SYSTEM /RL HIGHEST /F >nul

echo [*] Refreshing taskbar (screen blinks for a second)...
call :REFRESHTASKBAR

echo.
echo [OK] Windows Update DISABLED and red dot REMOVED.
echo      Guard keeps it that way even after troubleshooting.
echo      Please restart the PC once. Internet is untouched.
pause
goto MENU

:: ------------------------------------------------------------
:RESTOREALL
cls
echo [*] Removing guard...
schtasks /Delete /TN "WUGuard_Startup" /F >nul 2>&1
schtasks /Delete /TN "WUGuard_Repeat" /F >nul 2>&1
rd /s /q "%ProgramData%\WUGuard" >nul 2>&1

echo [*] Removing update policies...
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate" /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\DeliveryOptimization" /v DODownloadMode /f >nul 2>&1

echo [*] Restoring services...
sc config wuauserv start= demand >nul 2>&1
sc config UsoSvc start= delayed-auto >nul 2>&1
sc config WaaSMedicSvc start= demand >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Services\wuauserv" /v Start /t REG_DWORD /d 3 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Services\UsoSvc" /v Start /t REG_DWORD /d 2 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Services\WaaSMedicSvc" /v Start /t REG_DWORD /d 3 /f >nul 2>&1
net start wuauserv >nul 2>&1
net start UsoSvc >nul 2>&1

echo [*] Restoring tasks, icon and notifications...
for %%T in (
 "\Microsoft\Windows\WindowsUpdate\Scheduled Start"
 "\Microsoft\Windows\UpdateOrchestrator\Schedule Scan"
 "\Microsoft\Windows\UpdateOrchestrator\USO_UxBroker"
 "\Microsoft\Windows\UpdateOrchestrator\UpdateModelTask"
 "\Microsoft\Windows\WaaSMedic\PerformRemediation"
) do schtasks /Change /TN %%T /Enable >nul 2>&1

set IFEO=HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options
reg delete "%IFEO%\MusNotification.exe" /f >nul 2>&1
reg delete "%IFEO%\MusNotificationUx.exe" /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings" /v RestartNotificationsAllowed2 /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Notifications\Settings\Windows.SystemToast.SecurityAndMaintenance" /v Enabled /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Notifications\Settings\Windows.SystemToast.UpdateSettings" /v Enabled /t REG_DWORD /d 1 /f >nul 2>&1
call :REFRESHTASKBAR

echo [OK] Everything restored to Windows default.
pause
goto MENU

:: ------------------------------------------------------------
:STATUS
cls
for %%S in (wuauserv UsoSvc WaaSMedicSvc) do (
    for /f "tokens=3" %%A in ('sc qc %%S ^| find "START_TYPE"') do echo %%S : start = %%A
    for /f "tokens=4" %%B in ('sc query %%S ^| find "STATE"') do echo %%S : state = %%B
)
echo.
reg query "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" /v NoAutoUpdate 2>nul || echo Update policy: NOT blocked
reg query "HKLM\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings" /v RestartNotificationsAllowed2 2>nul | find "0x0" >nul && echo Red dot / restart notice: HIDDEN || echo Red dot / restart notice: visible
schtasks /Query /TN "WUGuard_Repeat" >nul 2>&1 && echo Guard: ACTIVE || echo Guard: not installed
ping -n 2 8.8.8.8 | find "Reply" >nul && echo Internet: OK || echo Internet: no reply
pause
goto MENU

:: ------------------------------------------------------------
:REPAIR
cls
DISM /Online /Cleanup-Image /CheckHealth
DISM /Online /Cleanup-Image /RestoreHealth
sfc /scannow
echo.
echo [*] Re-applying update block + red dot removal...
call :APPLY
echo [OK] Done.
pause
goto MENU

:CHKDSK
cls
echo Y | chkdsk %SystemDrive% /f /r
pause
goto MENU

:NETFIX
cls
ipconfig /flushdns
echo [OK] DNS cache flushed. Nothing else changed.
pause
goto MENU

:CLEAN
cls
del /q /f /s "%TEMP%\*" >nul 2>&1
del /q /f /s "%windir%\Temp\*" >nul 2>&1
powershell -NoProfile -Command "Clear-RecycleBin -Force -ErrorAction SilentlyContinue"
echo [OK] Temp files cleaned. Browser data untouched.
pause
goto MENU

:RESTOREPT
cls
powershell -NoProfile -Command "Enable-ComputerRestore -Drive $env:SystemDrive; Checkpoint-Computer -Description 'Manual restore point' -RestorePointType MODIFY_SETTINGS"
echo [OK] Restore point requested.
pause
goto MENU

:: ------------------------------------------------------------
::  CORE ROUTINE (used by menu AND by the guard)
:: ------------------------------------------------------------
:APPLY
set WU=HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate
set AU=%WU%\AU
set IFEO=HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options

:: --- Disable updates (policy) ---
reg add "%AU%" /v NoAutoUpdate /t REG_DWORD /d 1 /f >nul 2>&1
reg add "%AU%" /v AUOptions /t REG_DWORD /d 1 /f >nul 2>&1
reg add "%AU%" /v NoAutoRebootWithLoggedOnUsers /t REG_DWORD /d 1 /f >nul 2>&1
reg add "%WU%" /v DoNotConnectToWindowsUpdateInternetLocations /t REG_DWORD /d 1 /f >nul 2>&1
reg add "%WU%" /v DisableWindowsUpdateAccess /t REG_DWORD /d 1 /f >nul 2>&1
reg add "%WU%" /v SetDisableUXWUAccess /t REG_DWORD /d 1 /f >nul 2>&1
reg add "%WU%" /v ExcludeWUDriversInQualityUpdate /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\DeliveryOptimization" /v DODownloadMode /t REG_DWORD /d 0 /f >nul 2>&1

:: --- Disable services ---
for %%S in (wuauserv UsoSvc WaaSMedicSvc) do (
    net stop %%S /y >nul 2>&1
    sc config %%S start= disabled >nul 2>&1
    reg add "HKLM\SYSTEM\CurrentControlSet\Services\%%S" /v Start /t REG_DWORD /d 4 /f >nul 2>&1
    sc failure %%S reset= 0 actions= ""/0/""/0/""/0 >nul 2>&1
)

:: --- Disable scheduled tasks ---
for %%T in (
 "\Microsoft\Windows\WindowsUpdate\Scheduled Start"
 "\Microsoft\Windows\WindowsUpdate\sih"
 "\Microsoft\Windows\WindowsUpdate\sihboot"
 "\Microsoft\Windows\UpdateOrchestrator\Schedule Scan"
 "\Microsoft\Windows\UpdateOrchestrator\Schedule Scan Static Task"
 "\Microsoft\Windows\UpdateOrchestrator\USO_UxBroker"
 "\Microsoft\Windows\UpdateOrchestrator\Reboot"
 "\Microsoft\Windows\UpdateOrchestrator\Reboot_AC"
 "\Microsoft\Windows\UpdateOrchestrator\Reboot_Battery"
 "\Microsoft\Windows\UpdateOrchestrator\UpdateModelTask"
 "\Microsoft\Windows\WaaSMedic\PerformRemediation"
) do schtasks /Change /TN %%T /Disable >nul 2>&1

:: --- Remove red dot / tray icon / notifications ---
reg add "HKLM\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings" /v RestartNotificationsAllowed2 /t REG_DWORD /d 0 /f >nul 2>&1
reg add "%WU%" /v SetUpdateNotificationLevel /t REG_DWORD /d 1 /f >nul 2>&1
reg add "%WU%" /v UpdateNotificationLevel /t REG_DWORD /d 2 /f >nul 2>&1
reg add "%WU%" /v SetAutoRestartNotificationDisable /t REG_DWORD /d 1 /f >nul 2>&1

reg delete "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\RebootRequired" /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Services\Pending" /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\RebootPending" /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\RebootInProgress" /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Orchestrator\RebootRequired" /f >nul 2>&1

reg add "%IFEO%\MusNotification.exe"   /v Debugger /t REG_SZ /d "%windir%\System32\systray.exe" /f >nul 2>&1
reg add "%IFEO%\MusNotificationUx.exe" /v Debugger /t REG_SZ /d "%windir%\System32\systray.exe" /f >nul 2>&1
taskkill /f /im MusNotification.exe   >nul 2>&1
taskkill /f /im MusNotificationUx.exe >nul 2>&1

reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Notifications\Settings\Windows.SystemToast.SecurityAndMaintenance" /v Enabled /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Notifications\Settings\Windows.SystemToast.UpdateSettings" /v Enabled /t REG_DWORD /d 0 /f >nul 2>&1
exit /b

:REFRESHTASKBAR
taskkill /f /im explorer.exe >nul 2>&1
start explorer.exe
exit /b

:: ------------------------------------------------------------
:GUARD
call :APPLY
exit /b
