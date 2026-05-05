#!/bin/bash

# Script per creare una release su GitHub automaticamente
# Uso: ./scripts/create_release.sh [versione]
# Esempio: ./scripts/create_release.sh 43.01.00

set -e  # Exit on error

# Colori per output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Verifica che sia passata la versione
if [ -z "$1" ]; then
    echo -e "${RED}❌ Errore: Specifica la versione${NC}"
    echo "Uso: ./scripts/create_release.sh [versione]"
    echo "Esempio: ./scripts/create_release.sh 43.01.00"
    exit 1
fi

NEW_VERSION="$1"
echo -e "${BLUE}📦 Creazione release v${NEW_VERSION}${NC}\n"

# Verifica che gh CLI sia installato
if ! command -v gh &> /dev/null; then
    echo -e "${RED}❌ GitHub CLI (gh) non è installato${NC}"
    echo "Installa con: brew install gh"
    echo "Poi autentica con: gh auth login"
    exit 1
fi

# Verifica autenticazione GitHub
if ! gh auth status &> /dev/null; then
    echo -e "${YELLOW}⚠️  Non sei autenticato su GitHub${NC}"
    echo "Esegui: gh auth login"
    exit 1
fi

# 1. Aggiorna la versione in pubspec.yaml
echo -e "${YELLOW}1. Aggiornamento pubspec.yaml...${NC}"
sed -i '' "s/^version:.*/version: $NEW_VERSION/" pubspec.yaml
echo -e "${GREEN}✓ Versione aggiornata a $NEW_VERSION${NC}\n"

# 2. Build dell'app
echo -e "${YELLOW}2. Build dell'applicazione...${NC}"

# Android APK
if [ "$BUILD_ANDROID" != "false" ]; then
    echo "  Building Android APK..."
    flutter build apk --release
    
    # Rinomina APK con versione
    APK_SOURCE="build/app/outputs/flutter-apk/app-release.apk"
    APK_DEST="build/ligaduck-v${NEW_VERSION}.apk"
    cp "$APK_SOURCE" "$APK_DEST"
    echo -e "${GREEN}  ✓ APK creato: $APK_DEST${NC}"
    
    # Copia in Downloads se la directory esiste (locale, non CI)
    if [ -d "$HOME/Downloads" ]; then
        DOWNLOADS_APK="$HOME/Downloads/ligaduck-v${NEW_VERSION}.apk"
        cp "$APK_DEST" "$DOWNLOADS_APK"
        echo -e "${GREEN}  ✓ APK copiato in Downloads${NC}"
    fi
fi

# macOS (se su macOS)
if [[ "$OSTYPE" == "darwin"* ]]; then
    echo "  Building macOS app..."
    flutter build macos --release
    
    # Crea DMG (richiede create-dmg: brew install create-dmg)
    if command -v create-dmg &> /dev/null; then
        DMG_DEST="build/ligaduck-v${NEW_VERSION}.dmg"
        create-dmg \
            --volname "LigaDuck" \
            --window-pos 200 120 \
            --window-size 600 400 \
            --icon-size 100 \
            --app-drop-link 450 185 \
            "$DMG_DEST" \
            "build/macos/Build/Products/Release/ligaduck.app" 2>/dev/null || true
        
        if [ -f "$DMG_DEST" ]; then
            echo -e "${GREEN}  ✓ DMG creato: $DMG_DEST${NC}"
            
            # Copia in Downloads se la directory esiste (locale, non CI)
            if [ -d "$HOME/Downloads" ]; then
                DOWNLOADS_DMG="$HOME/Downloads/ligaduck-v${NEW_VERSION}.dmg"
                cp "$DMG_DEST" "$DOWNLOADS_DMG"
                echo -e "${GREEN}  ✓ DMG copiato in Downloads${NC}"
            fi
        fi
    else
        echo -e "${YELLOW}  ⚠️  create-dmg non installato, salto creazione DMG${NC}"
        echo "     Installa con: brew install create-dmg"
    fi
fi

# Windows (build sempre, zip solo su macOS/Linux con zip)
echo "  Building Windows app..."
flutter build windows --release

if [ -d "build/windows/x64/runner/Release" ]; then
    WIN_DEST="build/ligaduck-v${NEW_VERSION}-windows.zip"
    
    # Crea lo zip con il contenuto della cartella Release
    if command -v zip &> /dev/null; then
        cd build/windows/x64/runner/Release
        zip -r "../../../../../ligaduck-v${NEW_VERSION}-windows.zip" ./* > /dev/null
        cd ../../../../../
        
        if [ -f "$WIN_DEST" ]; then
            echo -e "${GREEN}  ✓ Windows ZIP creato: $WIN_DEST${NC}"
            
            # Copia in Downloads se la directory esiste (locale, non CI)
            if [ -d "$HOME/Downloads" ]; then
                DOWNLOADS_WIN="$HOME/Downloads/ligaduck-v${NEW_VERSION}-windows.zip"
                cp "$WIN_DEST" "$DOWNLOADS_WIN"
                echo -e "${GREEN}  ✓ Windows ZIP copiato in Downloads${NC}"
            fi
        fi
    else
        echo -e "${YELLOW}  ⚠️  zip non trovato, crea manualmente da: build/windows/x64/runner/Release${NC}"
    fi
fi

echo ""

# 3. Aggiorna version.json
echo -e "${YELLOW}3. Aggiornamento version.json...${NC}"

# Chiedi note di rilascio
echo -e "${BLUE}Inserisci le note di rilascio (premi CTRL+D quando hai finito):${NC}"
RELEASE_NOTES=$(cat)

# Aggiorna il file version.json
cat > version.json << EOF
{
  "lastUpdate": "$(date +%Y-%m-%d)",
  "android": {
    "version": "$NEW_VERSION",
    "downloadUrl": "https://github.com/Digree/ligaduck/releases/download/v${NEW_VERSION}/ligaduck-v${NEW_VERSION}.apk",
    "releaseNotes": "$RELEASE_NOTES"
  },
  "ios": {
    "version": "$NEW_VERSION",
    "downloadUrl": "https://apps.apple.com/app/ligaduck/YOUR_APP_ID",
    "releaseNotes": "$RELEASE_NOTES"
  },
  "macos": {
    "version": "$NEW_VERSION",
    "downloadUrl": "https://github.com/Digree/ligaduck/releases/download/v${NEW_VERSION}/ligaduck-v${NEW_VERSION}.dmg",
    "releaseNotes": "$RELEASE_NOTES"
  },
  "windows": {
    "version": "$NEW_VERSION",
    "downloadUrl": "https://github.com/Digree/ligaduck/releases/download/v${NEW_VERSION}/ligaduck-v${NEW_VERSION}-windows.zip",
    "releaseNotes": "$RELEASE_NOTES"
  }
}
EOF

echo -e "${GREEN}✓ version.json aggiornato${NC}\n"

# 4. Commit e push
echo -e "${YELLOW}4. Commit dei cambiamenti...${NC}"
git add pubspec.yaml version.json
git commit -m "Release v${NEW_VERSION}"
git tag -a "v${NEW_VERSION}" -m "Release v${NEW_VERSION}"
git push origin main
git push origin "v${NEW_VERSION}"
echo -e "${GREEN}✓ Modifiche committate e tag creato${NC}\n"

# 5. Crea release su GitHub
echo -e "${YELLOW}5. Creazione release su GitHub...${NC}"

# Prepara i file da caricare
FILES_TO_UPLOAD=""
if [ -f "build/ligaduck-v${NEW_VERSION}.apk" ]; then
    FILES_TO_UPLOAD="$FILES_TO_UPLOAD build/ligaduck-v${NEW_VERSION}.apk"
fi
if [ -f "build/ligaduck-v${NEW_VERSION}.dmg" ]; then
    FILES_TO_UPLOAD="$FILES_TO_UPLOAD build/ligaduck-v${NEW_VERSION}.dmg"
fi
if [ -f "build/ligaduck-v${NEW_VERSION}-windows.zip" ]; then
    FILES_TO_UPLOAD="$FILES_TO_UPLOAD build/ligaduck-v${NEW_VERSION}-windows.zip"
fi

# Crea la release
if [ -n "$FILES_TO_UPLOAD" ]; then
    gh release create "v${NEW_VERSION}" \
        --title "LigaDuck v${NEW_VERSION}" \
        --notes "$RELEASE_NOTES" \
        $FILES_TO_UPLOAD
else
    echo -e "${RED}❌ Nessun file da caricare${NC}"
    exit 1
fi

echo -e "\n${GREEN}🎉 Release v${NEW_VERSION} creata con successo!${NC}"
echo -e "${BLUE}Visualizza su: https://github.com/Digree/ligaduck/releases${NC}"
