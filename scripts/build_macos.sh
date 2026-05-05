#!/bin/bash
set -e

# Script per build macOS DMG
# Uso: ./scripts/build_macos.sh 43.01.00

VERSION=$1

if [ -z "$VERSION" ]; then
  echo "❌ Errore: Specifica una versione (es: 43.01.00)"
  exit 1
fi

echo "📦 Build macOS DMG v$VERSION"
echo "================================"

# Verifica che siamo su macOS
if [[ "$OSTYPE" != "darwin"* ]]; then
  echo "❌ Questo script funziona solo su macOS"
  exit 1
fi

# Build macOS app
echo "Building macOS app..."
flutter build macos --release

APP_PATH="build/macos/Build/Products/Release/Liga Duck Manager.app"

if [ ! -d "$APP_PATH" ]; then
  echo "❌ App macOS non trovata in $APP_PATH"
  exit 1
fi

echo "✓ App macOS creata"

# Crea DMG se create-dmg è installato
if command -v create-dmg &> /dev/null; then
  echo "Creating DMG..."
  DMG_DEST="build/ligaduck-v$VERSION.dmg"
  
  # Rimuovi DMG esistente se presente
  rm -f "$DMG_DEST"
  
  create-dmg \
    --volname "Liga Duck Manager" \
    --window-pos 200 120 \
    --window-size 600 400 \
    --icon-size 100 \
    --app-drop-link 450 185 \
    "$DMG_DEST" \
    "$APP_PATH" || true
  
  if [ -f "$DMG_DEST" ]; then
    echo "✓ DMG creato: $DMG_DEST"
    ls -lh "$DMG_DEST"
    
    # Copia in Downloads
    DOWNLOADS_DMG="$HOME/Downloads/ligaduck-v$VERSION.dmg"
    cp "$DMG_DEST" "$DOWNLOADS_DMG"
    echo "✓ DMG copiato in Downloads: $DOWNLOADS_DMG"
  else
    echo "⚠️  DMG creation failed, creating ZIP instead..."
    ZIP_DEST="build/ligaduck-v$VERSION-macos.zip"
    cd build/macos/Build/Products/Release
    zip -r "../../../../../$ZIP_DEST" "Liga Duck Manager.app" > /dev/null
    cd - > /dev/null
    echo "✓ ZIP creato: $ZIP_DEST"
    ls -lh "$ZIP_DEST"
    
    # Copia in Downloads
    DOWNLOADS_ZIP="$HOME/Downloads/ligaduck-v$VERSION-macos.zip"
    cp "$ZIP_DEST" "$DOWNLOADS_ZIP"
    echo "✓ ZIP copiato in Downloads: $DOWNLOADS_ZIP"
  fi
else
  echo "⚠️  create-dmg non installato, creating ZIP instead..."
  ZIP_DEST="build/ligaduck-v$VERSION-macos.zip"
  cd build/macos/Build/Products/Release
  zip -r "../../../../../$ZIP_DEST" "Liga Duck Manager.app" > /dev/null
  cd - > /dev/null
  echo "✓ ZIP creato: $ZIP_DEST"
  ls -lh "$ZIP_DEST"
  
  # Copia in Downloads
  DOWNLOADS_ZIP="$HOME/Downloads/ligaduck-v$VERSION-macos.zip"
  cp "$ZIP_DEST" "$DOWNLOADS_ZIP"
  echo "✓ ZIP copiato in Downloads: $DOWNLOADS_ZIP"
fi

echo ""
echo "✅ Build macOS completato!"
echo "File Downloads: $HOME/Downloads/ligaduck-v$VERSION.*"
