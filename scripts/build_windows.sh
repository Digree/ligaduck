#!/bin/bash
set -e

# Script per build Windows ZIP
# Uso: ./scripts/build_windows.sh 43.01.00

VERSION=$1

if [ -z "$VERSION" ]; then
  echo "❌ Errore: Specifica una versione (es: 43.01.00)"
  exit 1
fi

echo "📦 Build Windows ZIP v$VERSION"
echo "================================"

# Verifica che siamo su Windows o che il cross-compile sia supportato
if [[ "$OSTYPE" != "msys" && "$OSTYPE" != "cygwin" ]]; then
  echo "⚠️  Attenzione: Non sei su Windows. Il build potrebbe fallire."
fi

# Build Windows app
echo "Building Windows app..."
flutter build windows --release

WINDOWS_BUILD_PATH="build/windows/x64/runner/Release"

if [ ! -d "$WINDOWS_BUILD_PATH" ]; then
  echo "❌ Build Windows non trovato in $WINDOWS_BUILD_PATH"
  exit 1
fi

echo "✓ App Windows creata"

# Verifica struttura necessaria
echo "Verificando struttura build..."
REQUIRED_FILES=(
  "LigaDuckManager.exe"
  "flutter_windows.dll"
  "data/icudtl.dat"
  "data/app.so"
  "data/flutter_assets"
)

for file in "${REQUIRED_FILES[@]}"; do
  if [ ! -e "$WINDOWS_BUILD_PATH/$file" ]; then
    echo "❌ File/cartella mancante: $file"
    exit 1
  fi
done
echo "✓ Struttura build verificata"

# Crea README per utenti Windows
README_PATH="$WINDOWS_BUILD_PATH/README.txt"
cat > "$README_PATH" << 'EOF'
=================================================
  Liga Duck Manager - Windows
=================================================

IMPORTANTE - Come estrarre ed eseguire:

1. Estrai TUTTO il contenuto di questo ZIP in una cartella
2. NON spostare solo il file .exe - deve rimanere insieme agli altri file!
3. Esegui "LigaDuckManager.exe"

La struttura delle cartelle DEVE essere:
  LigaDuckManager.exe
  flutter_windows.dll
  data/
    icudtl.dat
    app.so
    flutter_assets/

Se l'app non si avvia, verifica che:
- Hai estratto TUTTI i file
- La cartella "data" è accanto al file .exe
- Hai Windows 10 o superiore

Per supporto: https://github.com/ripudima/ligaduck
EOF

echo "✓ README creato"

# Crea ZIP
ZIP_DEST="build/ligaduck-v$VERSION-windows.zip"
echo "Creating ZIP..."

cd "$WINDOWS_BUILD_PATH"
zip -r "../../../../../ligaduck-v$VERSION-windows.zip" . -x "*.pdb"
cd - > /dev/null

if [ -f "$ZIP_DEST" ]; then
  echo "✓ ZIP creato: $ZIP_DEST"
  ls -lh "$ZIP_DEST"
  
  # Copia in Downloads
  DOWNLOADS_ZIP="$HOME/Downloads/ligaduck-v$VERSION-windows.zip"
  cp "$ZIP_DEST" "$DOWNLOADS_ZIP"
  echo "✓ ZIP copiato in Downloads: $DOWNLOADS_ZIP"
  
  # Verifica contenuto ZIP
  echo ""
  echo "Contenuto ZIP (prime 15 righe):"
  unzip -l "$ZIP_DEST" | head -20
else
  echo "❌ ZIP non creato"
  exit 1
fi

echo ""
echo "✅ Build Windows completato!"
echo "File build: $ZIP_DEST"
echo "File Downloads: $HOME/Downloads/ligaduck-v$VERSION-windows.zip"
