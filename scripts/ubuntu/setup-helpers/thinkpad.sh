#!/bin/bash
set -euo pipefail

echo "Installing NVIDIA drivers..."
sudo ubuntu-drivers autoinstall

DIR="$(cd "$(dirname "$0")" && pwd)"
"$DIR/dashboard.sh"

echo "Thinkpad setup done! Reboot recommended for NVIDIA drivers."
