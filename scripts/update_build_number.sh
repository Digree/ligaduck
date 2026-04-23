#!/bin/bash

# Script per aggiornare il build number basato sul commit count
# Uso: ./scripts/update_build_number.sh

PUBSPEC_PATH="pubspec.yaml"

# Ottieni il numero totale di commit
COMMIT_COUNT=$(git rev-list --all --count)
if [ -z "$COMMIT_COUNT" ]; then
    COMMIT_COUNT=1
fi

# Ottieni il commit hash corto
COMMIT_HASH=$(git rev-parse --short HEAD)
if [ -z "$COMMIT_HASH" ]; then
    echo "Error: Unable to get commit hash"
    exit 1
fi

# Leggi la versione attuale dal pubspec.yaml
if [ ! -f "$PUBSPEC_PATH" ]; then
    echo "Error: pubspec.yaml not found"
    exit 1
fi

# Estrai versione e build number (format: "version: X.Y.Z+N")
CURRENT_VERSION=$(grep "^version:" "$PUBSPEC_PATH" | sed -E 's/version:[[:space:]]*([0-9]+\.[0-9]+\.[0-9]+).*/\1/')

if [ -z "$CURRENT_VERSION" ]; then
    echo "Error: Unable to parse version from pubspec.yaml"
    exit 1
fi

# Aggiorna il pubspec.yaml con il nuovo build number
sed -i '' "s/^version:.*/version: $CURRENT_VERSION+$COMMIT_COUNT/" "$PUBSPEC_PATH"

echo "✓ Build number aggiornato"
echo "  Version: $CURRENT_VERSION+$COMMIT_COUNT"
echo "  Commit: $COMMIT_HASH (Total commits: $COMMIT_COUNT)"
echo ""
