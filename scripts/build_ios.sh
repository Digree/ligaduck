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

# Build iOS archive
echo "Building iOS archive..."
echo "⚠️  Questo richiede certificati Apple Developer configurati"
echo ""

flutter build ipa --release

IPA_PATH="build/ios/ipa/Liga Duck Manager.ipa"

if [ -f "$IPA_PATH" ]; then
  # Rinomina IPA
  IPA_DEST="build/ligaduck-v$VERSION.ipa"
  cp "$IPA_PATH" "$IPA_DEST"
  echo "✓ IPA creato: $IPA_DEST"
  ls -lh "$IPA_DEST"
else
  echo "⚠️  IPA non trovato in $IPA_PATH"
  echo ""
  echo "Possibili cause:"
  echo "  - Certificati Apple Developer non configurati"
  echo "  - Provisioning profile mancante"
  echo "  - Xcode non configurato correttamente"
  echo ""
  echo "Per configurare i certificati:"
  echo "  1. Apri Xcode"
  echo "  2. Preferences > Accounts > Aggiungi Apple ID"
  echo "  3. Seleziona il team di sviluppo"
  echo "  4. Apri ios/Runner.xcworkspace"
  echo "  5. Signing & Capabilities > Seleziona team"
  echo ""
  
  # Controlla se l'archive esiste almeno
  ARCHIVE_PATH="build/ios/archive/Runner.xcarchive"
  if [ -d "$ARCHIVE_PATH" ]; then
    echo "✓ Archive creato in: $ARCHIVE_PATH"
    echo "  Puoi esportare manualmente l'IPA da Xcode:"
    echo "  Window > Organizer > Archives > Distribute App"
  fi
  
  exit 1
fi

echo ""
echo "✅ Build iOS completato!"
echo "File: $IPA_DEST"
echo ""
echo "📝 Note:"
echo "  - Per pubblicare su App Store: usa Xcode Organizer"
echo "  - Per TestFlight: carica l'IPA su App Store Connect"
echo "  - Per distribuzione diretta: serve certificato Enterprise"
