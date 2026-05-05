#!/bin/bash
set -e

# Script per build Android APK
# Uso: ./scripts/build_android.sh 43.01.00

VERSION=$1

if [ -z "$VERSION" ]; then
  echo "❌ Errore: Specifica una versione (es: 43.01.00)"
  exit 1
fi

echo "📦 Build Android APK v$VERSION"
echo "================================"

# Build APK
echo "Building Android APK..."
flutter build apk --release

# Copia e rinomina
APK_SOURCE="build/app/outputs/flutter-apk/app-release.apk"
APK_DEST="build/ligaduck-v$VERSION.apk"

if [ -f "$APK_SOURCE" ]; then
  cp "$APK_SOURCE" "$APK_DEST"
  echo "✓ APK creato: $APK_DEST"
  ls -lh "$APK_DEST"
  
  # Copia in Downloads
  DOWNLOADS_DEST="$HOME/Downloads/ligaduck-v$VERSION.apk"
  cp "$APK_DEST" "$DOWNLOADS_DEST"
  echo "✓ APK copiato in Downloads: $DOWNLOADS_DEST"
else
  echo "❌ APK non trovato in $APK_SOURCE"
  exit 1
fi

echo ""
echo "✅ Build Android completato!"
echo "File build: $APK_DEST"
echo "File Downloads: $HOME/Downloads/ligaduck-v$VERSION.apk"
