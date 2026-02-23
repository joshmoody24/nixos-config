#!/bin/bash
set -euo pipefail

echo "Installing NVIDIA drivers..."
sudo ubuntu-drivers autoinstall

echo "Thinkpad setup done! Reboot recommended for NVIDIA drivers."
