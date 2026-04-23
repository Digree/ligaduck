#!/bin/bash

# Script di build per Flutter con versionamento automatico (macOS/Linux)
# Uso: ./build.sh [--release] [--debug] [--ios] [--android]

RELEASE=true
DEBUG=false
IOS=false
ANDROID=false

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --debug)
            RELEASE=false
            DEBUG=true
            shift
            ;;
        --ios)
            IOS=true
            shift
            ;;
        --android)
            ANDROID=true
            shift
            ;;
        --release)
            RELEASE=true
            DEBUG=false
            shift
            ;;
        *)
            shift
            ;;
    esac
done

# Se nessuna piattaforma specificata, build iOS per default su macOS
if [ "$IOS" = false ] && [ "$ANDROID" = false ]; then
    IOS=true
fi

# Esegui lo script di aggiornamento versione
echo "📦 Aggiornamento build number..."
./scripts/update_build_number.sh

# Determina le flag di build
BUILD_FLAGS=""
if [ "$RELEASE" = true ]; then
    BUILD_FLAGS="--release"
elif [ "$DEBUG" = true ]; then
    BUILD_FLAGS="--debug"
fi

# Esegui il build appropriato
if [ "$IOS" = true ]; then
    echo ""
    echo "🔨 Building iOS..."
    flutter build ios $BUILD_FLAGS
fi

if [ "$ANDROID" = true ]; then
    echo ""
    echo "🔨 Building Android..."
    flutter build apk $BUILD_FLAGS
fi

echo ""
echo "✓ Build completato!"
