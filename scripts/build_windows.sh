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

# Crea ZIP
ZIP_DEST="build/ligaduck-v$VERSION-windows.zip"
echo "Creating ZIP..."

cd "$WINDOWS_BUILD_PATH"
zip -r "../../../../../ligaduck-v$VERSION-windows.zip" . -x "*.pdb"
cd - > /dev/null

if [ -f "$ZIP_DEST" ]; then
  echo "✓ ZIP creato: $ZIP_DEST"
  ls -lh "$ZIP_DEST"
else
  echo "❌ ZIP non creato"
  exit 1
fi

echo ""
echo "✅ Build Windows completato!"
echo "File: $ZIP_DEST"
