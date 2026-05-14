@echo off
setlocal enabledelayedexpansion

REM Script per build Windows MSIX
REM Uso: scripts\build_windows_msix.bat 43.01.00

if "%~1"=="" (
  echo ❌ Errore: Specifica una versione (es: 43.01.00)
  exit /b 1
)

set "VERSION=%~1"

echo 📦 Build Windows MSIX v%VERSION%
echo ==================================

REM Converti versione in formato MSIX (x.y.z.0) rimuovendo zeri iniziali
for /f "tokens=1,2,3 delims=." %%a in ("%VERSION%") do (
  set /a "MAJOR=%%a"
  set /a "MINOR=%%b"
  set /a "PATCH=%%c"
  set "MSIX_VERSION=!MAJOR!.!MINOR!.!PATCH!.0"
)

echo Aggiornamento versione MSIX a %MSIX_VERSION%...

REM Aggiorna versione nel pubspec.yaml
powershell -Command "(Get-Content pubspec.yaml) -replace 'msix_version:.*', 'msix_version: %MSIX_VERSION%' | Set-Content pubspec.yaml"

echo Generazione icona 44x44 per MSIX...
powershell -Command "Add-Type -AssemblyName System.Drawing; $src = [System.Drawing.Image]::FromFile((Resolve-Path 'assets\icon\icon.png')); $bmp = New-Object System.Drawing.Bitmap(44, 44); $g = [System.Drawing.Graphics]::FromImage($bmp); $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic; $g.DrawImage($src, 0, 0, 44, 44); $bmp.Save((Join-Path (Get-Location) 'assets\icon\msix\Square44x44Logo.png'), [System.Drawing.Imaging.ImageFormat]::Png); $g.Dispose(); $bmp.Dispose(); $src.Dispose()"
echo ✓ Icona 44x44 generata: assets\icon\msix\Square44x44Logo.png

echo Building Windows MSIX package...
flutter pub get
flutter pub run msix:create --release --install-certificate false

set "MSIX_OUTPUT=build\windows\x64\runner\Release\ligaduck.msix"

if not exist "%MSIX_OUTPUT%" (
  echo ❌ MSIX non trovato in %MSIX_OUTPUT%
  exit /b 1
)

echo ✓ MSIX creato con successo

REM Crea cartella artifacts se non esiste
if not exist "artifacts" mkdir artifacts

REM Rinomina e sposta MSIX
set "ARTIFACT_NAME=LigaDuckManager-Windows-v%VERSION%.msix"
copy "%MSIX_OUTPUT%" "artifacts\%ARTIFACT_NAME%"

echo ✓ MSIX salvato in: artifacts\%ARTIFACT_NAME%

REM Copia script di installazione
copy "scripts\install_msix_windows.ps1" "artifacts\"
copy "scripts\INSTALL_MSIX_README.txt" "artifacts\README.txt"

echo ✓ File helper per installazione aggiunti
echo.
echo 📦 Build completato!
echo    File: artifacts\%ARTIFACT_NAME%
echo    Helper: artifacts\install_msix_windows.ps1
echo    README: artifacts\README.txt
echo.
echo 💡 Per installare: Vedi artifacts\README.txt
