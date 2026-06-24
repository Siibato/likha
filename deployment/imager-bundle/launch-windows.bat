@echo off
REM Likha Classroom Server — Pi Imager Launcher (Windows)
REM This script launches Raspberry Pi Imager pre-loaded with the Likha OS manifest.

setlocal EnableDelayedExpansion

set "BUNDLE_DIR=%~dp0"
set "IMAGE_NAME=likha-server.img.xz"
set "MANIFEST=%BUNDLE_DIR%os_list.json"
set "TEMPLATE=%BUNDLE_DIR%os_list_template.json"
set "IMAGE_PATH=%BUNDLE_DIR%%IMAGE_NAME%"

REM ---- Sanity checks ----
if not exist "%IMAGE_PATH%" (
    msg * "Missing image file: likha-server.img.xz was not found in this folder."
    exit /b 1
)

set "SCHOOL_CONFIG=%BUNDLE_DIR%school-config.txt"
findstr /R /C:"^MESH_GROUP_ID=$" "%SCHOOL_CONFIG%" >nul
if %errorlevel% == 0 (
    msg * "Please fill in MESH_GROUP_ID in school-config.txt before flashing."
    start "" "%SCHOOL_CONFIG%"
    exit /b 1
)

REM Find Raspberry Pi Imager
set "IMAGER_EXE=C:\Program Files (x86)\Raspberry Pi Imager\rpi-imager.exe"
if not exist "%IMAGER_EXE%" (
    set "IMAGER_EXE=C:\Program Files\Raspberry Pi Imager\rpi-imager.exe"
)
if not exist "%IMAGER_EXE%" (
    echo Raspberry Pi Imager not found.
    echo Please download and install it from https://www.raspberrypi.com/software/
    start https://www.raspberrypi.com/software/
    pause
    exit /b 1
)

REM ---- Prepare manifest ----
copy /Y "%TEMPLATE%" "%MANIFEST%" >nul
powershell -Command "(Get-Content '%MANIFEST%') -replace 'BUNDLE_DIR_PLACEHOLDER', '%BUNDLE_DIR:\=/%' | Set-Content '%MANIFEST%'"

REM ---- Launch ----
"%IMAGER_EXE%" --repo "%MANIFEST%"

REM ---- Post-flash: copy school config to boot partition ----
echo.
echo ============================================
echo Pi Imager is now open. Flash your SD card.
echo When done, press any key to copy config...
echo (Press Ctrl+C to skip)
echo ============================================
pause >nul

for %%D in (D: E: F: G: H: I: J: K: L: M: N: O: P: Q: R: S: T: U: V: W: X: Y: Z:) do (
    if exist "%%D\config.txt" (
        copy /Y "%SCHOOL_CONFIG%" "%%D\likha-config.txt" >nul
        echo School config copied to %%D\likha-config.txt
        pause
        goto :eof
    )
)
echo Boot partition not found. Please re-insert SD card and copy school-config.txt manually.
pause
