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

echo Verificando struttura build...
if not exist "%WINDOWS_BUILD_PATH%\LigaDuckManager.exe" (
  echo ❌ File mancante: LigaDuckManager.exe
  exit /b 1
)
if not exist "%WINDOWS_BUILD_PATH%\flutter_windows.dll" (
  echo ❌ File mancante: flutter_windows.dll
  exit /b 1
)
if not exist "%WINDOWS_BUILD_PATH%\data\icudtl.dat" (
  echo ❌ File mancante: data\icudtl.dat
  exit /b 1
)
if not exist "%WINDOWS_BUILD_PATH%\data\app.so" (
  echo ❌ File mancante: data\app.so
  exit /b 1
)
if not exist "%WINDOWS_BUILD_PATH%\data\flutter_assets" (
  echo ❌ Cartella mancante: data\flutter_assets
  exit /b 1
)
echo ✓ Struttura build verificata

REM Crea README per utenti Windows
set "README_PATH=%WINDOWS_BUILD_PATH%\README.txt"
(
  echo =================================================
  echo   Liga Duck Manager - Windows
  echo =================================================
  echo.
  echo IMPORTANTE - Come estrarre ed eseguire:
  echo.
  echo 1. Estrai TUTTO il contenuto di questo ZIP in una cartella
  echo 2. NON spostare solo il file .exe - deve rimanere insieme agli altri file!
  echo 3. Esegui "LigaDuckManager.exe"
  echo.
  echo La struttura delle cartelle DEVE essere:
  echo   LigaDuckManager.exe
  echo   flutter_windows.dll
  echo   data/
  echo     icudtl.dat
  echo     app.so
  echo     flutter_assets/
  echo.
  echo Se l'app non si avvia, verifica che:
  echo - Hai estratto TUTTI i file
  echo - La cartella "data" è accanto al file .exe
  echo - Hai Windows 10 o superiore
  echo.
  echo Per supporto: https://github.com/ripudima/ligaduck
) > "%README_PATH%"

echo ✓ README creato

echo Creating ZIP...
set "ZIP_DEST=build\ligaduck-v%VERSION%-windows.zip"

REM Calcola percorso assoluto della radice del repository partendo dalla cartella di build
for %%I in ("%WINDOWS_BUILD_PATH%\..\..\..\..\..") do set "REPO_ROOT=%%~fI"
set "ZIP_FULL=%REPO_ROOT%\ligaduck-v%VERSION%-windows.zip"

pushd "%WINDOWS_BUILD_PATH%" >nul

powershell -NoProfile -Command "Compress-Archive -Path * -DestinationPath '%ZIP_FULL%' -Force"

popd >nul

if exist "%ZIP_FULL%" (
  echo ✓ ZIP creato: %ZIP_FULL%
  dir /-C "%ZIP_FULL%"
  echo.
  echo Contenuto ZIP:
  powershell -NoProfile -Command "Get-Content (Get-ChildItem '%ZIP_FULL%' | Select-Object -First 1).FullName -Raw | Select-String 'LigaDuck' -Context 0,5"
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