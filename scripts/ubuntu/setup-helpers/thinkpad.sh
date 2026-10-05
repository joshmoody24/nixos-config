#!/bin/bash
set -euo pipefail

echo "Installing NVIDIA drivers..."
sudo ubuntu-drivers autoinstall

# The iwlwifi card drops the link for a minute at a time when it powers down,
# which takes the tailnet with it. This machine exists to be reachable, so the
# battery is the cheaper thing to spend.
NM_POWERSAVE='[connection]
wifi.powersave = 2'
NM_POWERSAVE_FILE=/etc/NetworkManager/conf.d/wifi-powersave-off.conf
if [ "$(sudo cat "$NM_POWERSAVE_FILE" 2>/dev/null)" != "$NM_POWERSAVE" ]; then
  echo "Disabling wifi power saving..."
  echo "$NM_POWERSAVE" | sudo tee "$NM_POWERSAVE_FILE" > /dev/null
  sudo systemctl restart NetworkManager
fi

# NetworkManager only governs what it manages; the driver has its own idea.
IWLWIFI_OPTS='options iwlwifi power_save=0
options iwlmvm power_scheme=1'
IWLWIFI_FILE=/etc/modprobe.d/iwlwifi-no-powersave.conf
if [ "$(sudo cat "$IWLWIFI_FILE" 2>/dev/null)" != "$IWLWIFI_OPTS" ]; then
  echo "Disabling iwlwifi driver power saving (takes effect on reboot)..."
  echo "$IWLWIFI_OPTS" | sudo tee "$IWLWIFI_FILE" > /dev/null
fi

DIR="$(cd "$(dirname "$0")" && pwd)"
"$DIR/dashboard.sh"

echo "Thinkpad setup done! Reboot recommended for NVIDIA drivers."
