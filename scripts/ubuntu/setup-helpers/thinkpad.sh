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

# This machine sits on a desk on a network with ~34 access points, and
# iwlwifi's 802.11r fast roaming fails against them ("key not allowed"),
# collapsing the link every few minutes. Pinning one AP never enters that
# code path. Roaming buys a stationary machine nothing.
#
# UPDATE THIS if the access point is replaced or the desk moves: find the
# strongest with `nmcli -f SSID,BSSID,SIGNAL device wifi list | grep REDO`.
WIFI_SSID=REDO
WIFI_BSSID=

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
