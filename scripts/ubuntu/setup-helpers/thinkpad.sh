#!/bin/bash
set -euo pipefail

. "$(dirname "$0")/lib.sh"

echo "Installing NVIDIA drivers..."
sudo ubuntu-drivers autoinstall

# The iwlwifi card drops the link for a minute at a time when it powers down,
# which takes the tailnet with it. This machine exists to be reachable, so the
# battery is the cheaper thing to spend.
install_system_file 644 /etc/NetworkManager/conf.d/wifi-powersave-off.conf '[connection]
wifi.powersave = 2' \
  sudo systemctl restart NetworkManager

# NetworkManager only governs what it manages; the driver has its own idea,
# and only reads this at boot.
install_system_file 644 /etc/modprobe.d/iwlwifi-no-powersave.conf 'options iwlwifi power_save=0
options iwlmvm power_scheme=1'

# This machine sits on a desk on a network with ~34 access points, and
# iwlwifi's 802.11r fast roaming fails against them ("key not allowed"),
# collapsing the link every few minutes. Pinning one AP never enters that
# code path. Roaming buys a stationary machine nothing.
#
# UPDATE THIS if the access point is replaced or the desk moves: find the
# strongest with `nmcli -f SSID,BSSID,SIGNAL device wifi list | grep REDO`.
WIFI_SSID=REDO
WIFI_BSSID=96:ED:E1:04:B3:6B

if [ -n "$WIFI_BSSID" ]; then
  if [ "$(nmcli -g 802-11-wireless.bssid connection show "$WIFI_SSID" 2>/dev/null)" != "$WIFI_BSSID" ]; then
    echo "Pinning $WIFI_SSID to $WIFI_BSSID..."
    sudo nmcli connection modify "$WIFI_SSID" 802-11-wireless.bssid "$WIFI_BSSID"
    sudo nmcli connection up "$WIFI_SSID" >/dev/null
  fi
else
  echo "WIFI_BSSID is unset in thinkpad.sh; wifi will keep roaming."
fi

DIR="$(cd "$(dirname "$0")" && pwd)"
"$DIR/dashboard.sh"

echo "Thinkpad setup done! Reboot recommended for NVIDIA drivers."
