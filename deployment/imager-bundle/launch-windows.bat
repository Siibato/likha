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
