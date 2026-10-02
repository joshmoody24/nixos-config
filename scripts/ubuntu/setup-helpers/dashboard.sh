#!/bin/bash
# The thinkpad kiosk: an unprivileged `dash` user autologged into a session that
# shows the rendered dashboard and nothing else, so an open lid exposes nothing.
set -euo pipefail

REPO_DIR="$(cd "$(dirname "$0")/../../.." && pwd)"
DOTFILES="$REPO_DIR/shared/dotfiles/dashboard"
STATE_DIR=/var/lib/redo-dashboard
TALK="$STATE_DIR/dashboard.deque"

if ! id dash &>/dev/null; then
  echo "Creating dash user..."
  sudo useradd --create-home --shell /usr/sbin/nologin --comment "Dashboard kiosk" dash
fi

# Rendered output is world-readable; only josh's collectors write it.
sudo install -d -m 755 -o josh -g josh "$STATE_DIR"
if [ ! -f "$TALK" ]; then
  sudo install -m 644 -o josh -g josh "$DOTFILES/placeholder.deque" "$TALK"
fi

# cage and foot come from apt so they link against the system's Mesa; a
# nix-built compositor would need nixGL, which dash cannot get from here.
for pkg in cage foot; do
  if ! dpkg -s "$pkg" &>/dev/null; then
    echo "Installing $pkg..."
    sudo apt install -y "$pkg"
  fi
done

# deque touches no GPU, so it comes from the flake. dash cannot see josh's
# profile, so it gets its own.
if ! sudo -u dash -H nix profile list 2>/dev/null | grep -q deque; then
  echo "Installing deque into dash's profile..."
  sudo -u dash -H nix profile install "$REPO_DIR#deque"
fi

sudo install -m 755 "$DOTFILES/kiosk.sh" /usr/local/bin/redo-dashboard-kiosk
sudo install -D -m 644 "$DOTFILES/dashboard.desktop" \
  /usr/share/wayland-sessions/dashboard.desktop

# GDM autologin into that session. Ctrl+Alt+F2 still reaches a getty as josh.
GDM_CONF=/etc/gdm3/custom.conf
if ! grep -q "^AutomaticLogin=dash" "$GDM_CONF"; then
  echo "Configuring GDM autologin..."
  sudo python3 - "$GDM_CONF" <<'PY'
import sys, re
path = sys.argv[1]
text = open(path).read()
daemon = "[daemon]\nAutomaticLoginEnable=true\nAutomaticLogin=dash\nAutomaticLoginSession=dashboard.desktop\n"
text = re.sub(r"\[daemon\]\n", daemon, text, count=1)
open(path, "w").write(text)
PY
fi

echo "Dashboard setup done! Reboot to land in the kiosk."
