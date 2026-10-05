#!/bin/bash
# Why the tailnet keeps dropping while the machine stays up. Read-only.
set -uo pipefail

out=/tmp/wifi-diagnosis.txt
exec > >(tee "$out") 2>&1
trap 'echo; echo "saved to $out"' EXIT

iface="$(nmcli -t -f DEVICE,TYPE device | awk -F: '$2=="wifi"{print $1; exit}')"
echo "=== wifi interface: ${iface:-none found} ==="

if [ -n "$iface" ]; then
  echo "--- power saving (want: off/disabled) ---"
  iwconfig "$iface" 2>/dev/null | grep -i "power management" ||
    cat "/sys/class/net/$iface/device/power/control" 2>/dev/null ||
    echo "(could not read; iw and iwconfig both missing)"

  echo "--- NetworkManager powersave (2 = disabled) ---"
  nmcli -f 802-11-wireless.powersave connection show \
    "$(nmcli -t -f NAME,TYPE connection show --active | awk -F: '$2 ~ /wireless/{print $1; exit}')" 2>/dev/null ||
    echo "(no active wireless connection)"

  echo "--- driver ---"
  basename "$(readlink -f "/sys/class/net/$iface/device/driver")" 2>/dev/null
fi

echo
echo "=== link drops, last 3h ==="
journalctl -u NetworkManager --since "-3h" --no-pager 2>/dev/null |
  grep -iE "disconnect|deauth|roam|link is not ready|state change" | tail -15 ||
  echo "(nothing)"

echo
echo "=== tailscaled complaints, last 3h ==="
journalctl -u tailscaled --since "-3h" --no-pager 2>/dev/null |
  grep -iE "network map|control|error|reconnect|backoff|derp" | tail -15 ||
  echo "(nothing)"

echo
echo "=== suspend/resume events, last 3h ==="
journalctl --since "-3h" --no-pager 2>/dev/null |
  grep -iE "suspend|resume|hibernat" | tail -8 || echo "(none)"

echo
echo "=== clock (TLS fails on skew) ==="
timedatectl 2>/dev/null | grep -E "Local time|synchronized|NTP service"
