#!/bin/bash
set -euo pipefail

# Configure Ollama to use ROCm with the Radeon 780M (gfx1103)
OLLAMA_OVERRIDE_DIR="/etc/systemd/system/ollama.service.d"
OLLAMA_OVERRIDE="$OLLAMA_OVERRIDE_DIR/rocm.conf"
OLLAMA_OVERRIDE_CONTENT='[Service]
Environment="HSA_OVERRIDE_GFX_VERSION=11.0.0"'

if [ ! -f "$OLLAMA_OVERRIDE" ] || [ "$(cat "$OLLAMA_OVERRIDE")" != "$OLLAMA_OVERRIDE_CONTENT" ]; then
  echo "Configuring Ollama for ROCm (Radeon 780M)..."
  sudo mkdir -p "$OLLAMA_OVERRIDE_DIR"
  echo "$OLLAMA_OVERRIDE_CONTENT" | sudo tee "$OLLAMA_OVERRIDE" > /dev/null
  sudo systemctl daemon-reload
  sudo systemctl restart ollama
fi

echo "Framework setup done!"
