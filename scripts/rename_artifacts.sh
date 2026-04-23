#!/usr/bin/env bash
# Rename build artifacts to 'Liga Duck Manager'
# Usage: ./scripts/rename_artifacts.sh
set -euo pipefail
cd "$(dirname "$0")/.."
exts=(apk ipa dmg)
for ext in "${exts[@]}"; do
  file=$(find build -type f -name "*.$ext" 2>/dev/null | awk 'NF' | xargs -r ls -t | head -n1 || true)
  if [ -n "$file" ]; then
    dir=$(dirname "$file")
    target="$dir/Liga Duck Manager.$ext"
    if [ "$file" = "$target" ]; then
      echo "Already named: $file"
    else
      cp -f "$file" "$target"
      echo "Copied $(basename "$file") -> $(basename "$target")"
    fi
  fi
done
