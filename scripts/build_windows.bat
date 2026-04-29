@echo off
setlocal enabledelayedexpansion

REM Script per build Windows ZIP
REM Uso: scripts\build_windows.bat 43.01.00

if "%~1"=="" (
  echo ❌ Errore: Specifica una versione (es: 43.01.00)
  exit /b 1
)

set "VERSION=%~1"

echo 📦 Build Windows ZIP v%VERSION%
echo =================================

echo Building Windows app...
flutter build windows --release

set "WINDOWS_BUILD_PATH=build\windows\x64\runner\Release"

if not exist "%WINDOWS_BUILD_PATH%" (
  echo ❌ Build Windows non trovato in %WINDOWS_BUILD_PATH%
  exit /b 1
)

echo ✓ App Windows creata

echo Creating ZIP...
set "ZIP_DEST=build\ligaduck-v%VERSION%-windows.zip"

REM Calcola percorso assoluto della radice del repository partendo dalla cartella di build
for %%I in ("%WINDOWS_BUILD_PATH%\..\..\..\..\..") do set "REPO_ROOT=%%~fI"
set "ZIP_FULL=%REPO_ROOT%\ligaduck-v%VERSION%-windows.zip"

pushd "%WINDOWS_BUILD_PATH%" >nul

powershell -NoProfile -Command " $list = Get-ChildItem -File -Recurse | Where-Object { $_.Extension -ne '.pdb' } | ForEach-Object { $_.FullName }; if (-not $list) { Write-Error 'Nessun file da aggiungere.'; exit 1 }; Compress-Archive -Path $list -DestinationPath '%ZIP_FULL%' -Force "

popd >nul

if exist "%ZIP_FULL%" (
  echo ✓ ZIP creato: %ZIP_FULL%
  dir /-C "%ZIP_FULL%"
) else (
  echo ❌ ZIP non creato
  exit /b 1
)

echo.
echo ✅ Build Windows completato!
echo File: %ZIP_FULL%

endlocal
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