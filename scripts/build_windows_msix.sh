#!/bin/bash
set -e

# Script per build Windows MSIX (da eseguire su Windows o WSL)
# Uso: ./scripts/build_windows_msix.sh 43.01.00

VERSION=$1

if [ -z "$VERSION" ]; then
  echo "❌ Errore: Specifica una versione (es: 43.01.00)"
  exit 1
fi

echo "📦 Build Windows MSIX v$VERSION"
echo "================================"

# Converti versione in formato MSIX (x.y.z.0) rimuovendo zeri iniziali
# awk con %d rimuove automaticamente gli zeri iniziali
MSIX_VERSION=$(echo $VERSION | awk -F. '{printf "%d.%d.%d.0", $1, $2, $3}')

echo "Aggiornamento versione MSIX a $MSIX_VERSION..."

# Aggiorna versione nel pubspec.yaml (compatibile sia con sed GNU che BSD/macOS)
if [[ "$OSTYPE" == "darwin"* ]]; then
  # macOS
  sed -i '' "s/msix_version:.*/msix_version: $MSIX_VERSION/" pubspec.yaml
else
  # Linux/WSL
  sed -i "s/msix_version:.*/msix_version: $MSIX_VERSION/" pubspec.yaml
fi

# Genera icone MSIX e icon.ico da icon44x44msix.png
echo "Generazione icone MSIX da icon44x44msix.png..."
if command -v python3 &>/dev/null; then
  python3 - << 'PYEOF'
from PIL import Image

src = Image.open("assets/icon/icon44x44msix.png").convert("RGBA")
w, h = src.size

# icon.ico per finestra Windows (sfondo trasparente)
sizes = [(256,256),(64,64),(48,48),(32,32),(16,16)]
frames = []
for (sw, sh) in sizes:
    frame = Image.new("RGBA", (sw, sh), (0, 0, 0, 0))
    ratio = min(sw / w, sh / h)
    nw, nh = int(w * ratio), int(h * ratio)
    resized = src.resize((nw, nh), Image.LANCZOS)
    frame.paste(resized, ((sw - nw) // 2, (sh - nh) // 2), resized)
    frames.append(frame)
frames[0].save("windows/runner/resources/icon.ico", format="ICO",
               sizes=sizes, append_images=frames[1:])

# Square44x44Logo per MSIX
sq44 = src.resize((44, 44), Image.LANCZOS)
sq44.save("assets/icon/msix/Square44x44Logo.png")
PYEOF
  echo "✓ icon.ico e Square44x44Logo.png generati da icon44x44msix.png"
else
  echo "⚠️  python3 non trovato, skip generazione icone"
fi

echo "Building Windows MSIX package..."
flutter pub get
flutter pub run msix:create --release --install-certificate false

MSIX_OUTPUT="build/windows/x64/runner/Release/ligaduck.msix"

if [ ! -f "$MSIX_OUTPUT" ]; then
  echo "❌ MSIX non trovato in $MSIX_OUTPUT"
  exit 1
fi

echo "✓ MSIX creato con successo"

# Rimuove il Wide tile (310x150) dall'AppxManifest per evitare il tile orizzontale
echo "Rimozione Wide tile dall'AppxManifest..."
if command -v python3 &>/dev/null; then
  python3 - << 'PYEOF'
import zipfile, shutil, os, re

msix_path = "build/windows/x64/runner/Release/ligaduck.msix"
tmp_path  = msix_path + ".tmp"

with zipfile.ZipFile(msix_path, 'r') as zin, \
     zipfile.ZipFile(tmp_path,  'w', compression=zipfile.ZIP_DEFLATED) as zout:
    for item in zin.infolist():
        data = zin.read(item.filename)
        if item.filename == "AppxManifest.xml":
            xml = data.decode("utf-8")
            # Rimuove Wide310x150Logo dall'attributo DefaultTile
            xml = re.sub(r'\s+Wide310x150Logo="[^"]*"', '', xml)
            # Rimuove il nodo ShowOn per wide310x150Logo
            xml = re.sub(r'\s*<uap:ShowOn\s+Tile="wide310x150Logo"\s*/>', '', xml)
            data = xml.encode("utf-8")
        zout.writestr(item, data)

os.replace(tmp_path, msix_path)
print("✓ Wide tile rimosso dall'AppxManifest")
PYEOF
else
  echo "⚠️  python3 non trovato, Wide tile non rimosso"
fi

# Crea cartella artifacts se non esiste
mkdir -p artifacts

# Rinomina e sposta MSIX
ARTIFACT_NAME="LigaDuckManager-Windows-v${VERSION}.msix"
cp "$MSIX_OUTPUT" "artifacts/$ARTIFACT_NAME"

echo "✓ MSIX salvato in: artifacts/$ARTIFACT_NAME"

# Copia script di installazione
cp "scripts/install_msix_windows.ps1" "artifacts/"
cp "scripts/INSTALL_MSIX_README.txt" "artifacts/README.txt"

echo "✓ File helper per installazione aggiunti"
echo ""
echo "📦 Build completato!"
echo "   File: artifacts/$ARTIFACT_NAME"
echo "   Helper: artifacts/install_msix_windows.ps1"
echo "   README: artifacts/README.txt"
echo ""
echo "💡 Per installare: Vedi artifacts/README.txt"
