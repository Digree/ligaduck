#!/bin/bash
set -e

# Script per creare release su GitHub con artefatti già buildati
# Uso: ./scripts/create_github_release.sh 43.01.00

VERSION=$1

if [ -z "$VERSION" ]; then
  echo "❌ Errore: Specifica una versione (es: 43.01.00)"
  exit 1
fi

echo "🚀 Creazione GitHub Release v$VERSION"
echo "======================================"

# Verifica che gh CLI sia installato
if ! command -v gh &> /dev/null; then
  echo "❌ GitHub CLI (gh) non installato"
  echo "   Installa con: brew install gh"
  exit 1
fi

# Verifica artefatti
APK="build/ligaduck-v$VERSION.apk"
IPA="build/ligaduck-v$VERSION.ipa"
DMG="build/ligaduck-v$VERSION.dmg"
ZIP="build/ligaduck-v$VERSION-windows.zip"

ARTIFACTS=()

if [ -f "$APK" ]; then
  echo "✓ Trovato APK Android"
  ARTIFACTS+=("$APK")
else
  echo "⚠️  APK Android non trovato"
fi

if [ -f "$IPA" ]; then
  echo "✓ Trovato IPA iOS"
  ARTIFACTS+=("$IPA")
else
  echo "⚠️  IPA iOS non trovato"
fi

if [ -f "$DMG" ]; then
  echo "✓ Trovato DMG macOS"
  ARTIFACTS+=("$DMG")
else
  echo "⚠️  DMG macOS non trovato"
fi

if [ -f "$ZIP" ]; then
  echo "✓ Trovato ZIP Windows"
  ARTIFACTS+=("$ZIP")
else
  echo "⚠️  ZIP Windows non trovato"
fi

if [ ${#ARTIFACTS[@]} -eq 0 ]; then
  echo "❌ Nessun artefatto trovato!"
  echo "   Buildate prima con gli script build_*.sh"
  exit 1
fi

echo ""
echo "Artefatti da caricare: ${#ARTIFACTS[@]}"

# Chiedi note di rilascio
echo ""
echo "📝 Inserisci le note di rilascio (premi Ctrl+D quando hai finito):"
RELEASE_NOTES=$(cat)

if [ -z "$RELEASE_NOTES" ]; then
  RELEASE_NOTES="Release $VERSION"
fi

# Aggiorna version.json
echo ""
echo "Aggiornamento version.json..."

REPO_URL="https://github.com/Digree/ligaduck"
ANDROID_URL="$REPO_URL/releases/download/v$VERSION/ligaduck-v$VERSION.apk"
IOS_URL="https://apps.apple.com/app/ligaduck"
MACOS_URL="$REPO_URL/releases/download/v$VERSION/ligaduck-v$VERSION.dmg"
WINDOWS_URL="$REPO_URL/releases/download/v$VERSION/ligaduck-v$VERSION-windows.zip"
CURRENT_DATE=$(date +%Y-%m-%d)

cat > version.json << EOF
{
  "lastUpdate": "$CURRENT_DATE",
  "android": {
    "version": "$VERSION",
    "downloadUrl": "$ANDROID_URL",
    "releaseNotes": "$RELEASE_NOTES"
  },
  "ios": {
    "version": "$VERSION",
    "downloadUrl": "$IOS_URL",
    "releaseNotes": "$RELEASE_NOTES"
  },
  "macos": {
    "version": "$VERSION",
    "downloadUrl": "$MACOS_URL",
    "releaseNotes": "$RELEASE_NOTES"
  },
  "windows": {
    "version": "$VERSION",
    "downloadUrl": "$WINDOWS_URL",
    "releaseNotes": "$RELEASE_NOTES"
  }
}
EOF

echo "✓ version.json aggiornato"

# Git commit e tag
echo ""
echo "Git commit e tag..."
git add version.json pubspec.yaml
git commit -m "Release v$VERSION"
git tag -a "v$VERSION" -m "Release $VERSION"
git push origin master
git push origin "v$VERSION"
echo "✓ Commit e tag pushati"

# Crea release su GitHub
echo ""
echo "Creazione release su GitHub..."
gh release create "v$VERSION" \
  --title "Release $VERSION" \
  --notes "$RELEASE_NOTES" \
  "${ARTIFACTS[@]}"

echo ""
echo "✅ Release v$VERSION creata con successo!"
echo "   URL: $REPO_URL/releases/tag/v$VERSION"
