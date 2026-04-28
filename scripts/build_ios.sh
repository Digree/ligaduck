#!/bin/bash
set -e

# Script per build iOS IPA
# Uso: ./scripts/build_ios.sh 43.01.00

VERSION=$1

if [ -z "$VERSION" ]; then
  echo "❌ Errore: Specifica una versione (es: 43.01.00)"
  exit 1
fi

echo "📦 Build iOS IPA v$VERSION"
echo "================================"

# Verifica che siamo su macOS
if [[ "$OSTYPE" != "darwin"* ]]; then
  echo "❌ Questo script funziona solo su macOS"
  exit 1
fi

# Verifica che Xcode sia installato
if ! command -v xcodebuild &> /dev/null; then
  echo "❌ Xcode non installato o xcodebuild non disponibile"
  exit 1
fi

# Build iOS app
echo "Building iOS app..."
flutter build ios --release

APP_PATH="build/ios/iphoneos/Runner.app"

if [ ! -d "$APP_PATH" ]; then
  echo "❌ App iOS non trovata in $APP_PATH"
  exit 1
fi

echo "✓ App iOS creata"

# Crea struttura Payload
echo "Creazione struttura IPA..."
PAYLOAD_DIR="build/Payload"
rm -rf "$PAYLOAD_DIR"
mkdir -p "$PAYLOAD_DIR"

# Copia l'app nella cartella Payload
cp -r "$APP_PATH" "$PAYLOAD_DIR/"
echo "✓ App copiata in Payload/"

# Crea IPA
IPA_NAME="Liga Duck Manager.ipa"
IPA_DEST="build/ligaduck-v$VERSION.ipa"

echo "Creazione IPA..."
cd build
zip -r "$IPA_NAME" Payload > /dev/null
cd ..

# Rinomina con versione
if [ -f "build/$IPA_NAME" ]; then
  mv "build/$IPA_NAME" "$IPA_DEST"
  echo "✓ IPA creato: $IPA_DEST"
  ls -lh "$IPA_DEST"
  
  # Pulisci cartella Payload temporanea
  rm -rf "$PAYLOAD_DIR"
  echo "✓ Payload temporaneo rimosso"
else
  echo "❌ Errore nella creazione dell'IPA"
  exit 1
fi

echo ""
echo "✅ Build iOS completato!"
echo "File: $IPA_DEST"
echo ""
echo "📝 Note:"
echo "  - Questo è un IPA ad-hoc per test/distribuzione interna"
echo "  - Per App Store: usa flutter build ipa --release con certificati"
echo "  - Per TestFlight: carica su App Store Connect"
echo "  - Per installazione diretta: serve dispositivo con UDID registrato"
