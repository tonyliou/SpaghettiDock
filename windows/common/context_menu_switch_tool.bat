@echo off

:menu
cls
echo =======================================
echo       Context Menu Switch Tool

echo 1. Switch to Traditional Menu
echo 2. Restore Simple Menu
echo 3. Exit

echo =======================================
set /p choice=Please select an option: 

if "%choice%" == "1" goto traditional
if "%choice%" == "2" goto simple
if "%choice%" == "3" goto exit

echo Invalid choice, please try again.
pause
goto menu

:traditional
echo Switching to Traditional Menu...
reg add "HKCU\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}\InprocServer32" /f /ve
if %errorlevel% equ 0 (
    echo Successfully switched to the Traditional Menu.
) else (
    echo Failed to switch, please check permissions or other issues.
)
pause
goto menu

:simple
echo Restoring Simple Menu...
reg delete "HKCU\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}" /f
if %errorlevel% equ 0 (
    echo Successfully restored the Simple Menu.
) else (
    echo Failed to restore, please check permissions or other issues.
)
pause
goto menu

:exit
echo Program terminated, press any key to exit.
pause
exit