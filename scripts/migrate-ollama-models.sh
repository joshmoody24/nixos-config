#!/bin/bash
# Migrate ollama models from user directory to system service directory.
# Safe to run multiple times — skips if no user models exist.
set -euo pipefail

SRC="$HOME/.ollama/models"
DEST="/usr/share/ollama/.ollama/models"

if [ ! -d "$SRC" ] || [ -z "$(ls -A "$SRC" 2>/dev/null)" ]; then
  echo "No models found in $SRC — nothing to migrate."
  exit 0
fi

echo "Migrating models from $SRC to $DEST..."
sudo cp -rn "$SRC/"* "$DEST/"
sudo chown -R ollama:ollama "$DEST"
echo "Done. You can verify with: ollama list"
echo "To free space, remove the old models: rm -rf $SRC"
