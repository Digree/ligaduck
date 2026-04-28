#!/bin/bash
set -e

# Script per aggiornare solo la versione in pubspec.yaml
# Uso: ./scripts/update_version.sh 43.01.00

VERSION=$1

if [ -z "$VERSION" ]; then
  echo "❌ Errore: Specifica una versione (es: 43.01.00)"
  exit 1
fi

echo "📝 Aggiornamento versione a $VERSION"

# Aggiorna pubspec.yaml
if [[ "$OSTYPE" == "darwin"* ]]; then
  sed -i '' "s/^version: .*/version: $VERSION/" pubspec.yaml
else
  sed -i "s/^version: .*/version: $VERSION/" pubspec.yaml
fi

echo "✓ pubspec.yaml aggiornato"

# Mostra la nuova versione
grep "^version:" pubspec.yaml
