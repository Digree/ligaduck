@echo off
setlocal enabledelayedexpansion

REM Script per build Windows ZIP
REM Uso: build_windows.bat 43.01.00

set VERSION=%1

if "%VERSION%"=="" (
    echo ❌ Errore: Specifica una versione ^(es: 43.01.00^)
    exit /b 1
)

echo 📦 Build Windows ZIP v%VERSION%
echo =================================

REM Build Windows app
echo Building Windows app...
flutter build windows --release

set WINDOWS_BUILD_PATH=build\windows\x64\runner\Release

if not exist "%WINDOWS_BUILD_PATH%" (
    echo ❌ Build Windows non trovato in %WINDOWS_BUILD_PATH%
    exit /b 1
)

echo ✓ App Windows creata

REM Crea ZIP
set ZIP_DEST=build\ligaduck-v%VERSION%-windows.zip

echo Creating ZIP...

REM Usa PowerShell per creare lo ZIP
powershell -Command ^
"Compress-Archive -Path '%WINDOWS_BUILD_PATH%\*' -DestinationPath '%ZIP_DEST%' -Force"

if exist "%ZIP_DEST%" (
    echo ✓ ZIP creato: %ZIP_DEST%
    dir "%ZIP_DEST%"
) else (
    echo ❌ ZIP non creato
    exit /b 1
)

echo.
echo ✅ Build Windows completato!
echo File: %ZIP_DEST%

endlocal