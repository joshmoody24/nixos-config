#!/bin/bash
# The thinkpad kiosk: an unprivileged `dash` user autologged into a session that
# shows the rendered dashboard and nothing else, so an open lid exposes nothing.
set -euo pipefail

REPO_DIR="$(cd "$(dirname "$0")/../../.." && pwd)"
DOTFILES="$REPO_DIR/shared/dotfiles/dashboard"
STATE_DIR=/var/lib/redo-dashboard
TALK="$STATE_DIR/dashboard.deque"
RENDERED_MARKER="rendered by redo-dashboard"

if ! id dash &>/dev/null; then
  echo "Creating dash user..."
  # A real shell: GDM starts the session through it. dash has no password and
  # no authorized keys, so this is not a way in.
  sudo useradd --create-home --shell /bin/bash --comment "Dashboard kiosk" dash
fi

sudo usermod --shell /bin/bash dash

# Rendered output is world-readable; only josh's collectors write it.
sudo install -d -m 755 -o josh -g josh "$STATE_DIR"

# Until a collector has run, the kiosk shows the placeholder. render marks its
# own output, so refreshing the placeholder here can never clobber real data.
if ! grep -q "$RENDERED_MARKER" "$TALK" 2>/dev/null; then
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
# profile, so it gets its own; the build happens as josh because dash cannot
# read $REPO_DIR either, and store paths are world-readable. nix is addressed
# absolutely because sudo's secure_path does not include it, and dash has no
# nix.conf enabling the experimental commands.
NIX=/nix/var/nix/profiles/default/bin/nix
NIX_FLAGS=(--extra-experimental-features nix-command --extra-experimental-features flakes)

echo "Building deque..."
DEQUE="$("$NIX" build "${NIX_FLAGS[@]}" --no-link --print-out-paths "$REPO_DIR#deque")"

if ! sudo -u dash -H "$NIX" profile list "${NIX_FLAGS[@]}" 2>/dev/null | grep -q "$DEQUE"; then
  echo "Installing deque into dash's profile..."
  sudo -u dash -H "$NIX" profile remove deque "${NIX_FLAGS[@]}" &>/dev/null || true
  sudo -u dash -H "$NIX" profile install "$DEQUE" "${NIX_FLAGS[@]}"
fi

# The kiosk script lives where josh can rewrite it, so font and terminal tweaks
# need no sudo. GDM's session file is root-owned and never has to change again.
KIOSK="$STATE_DIR/kiosk.sh"
install -m 755 "$DOTFILES/kiosk.sh" "$KIOSK"
sudo install -m 755 /dev/stdin /usr/local/bin/redo-dashboard-kiosk <<LAUNCHER
#!/bin/sh
exec $KIOSK
LAUNCHER

# Restarting the display is how a kiosk change takes effect; needing a password
# for it would mean needing to be sitting at the machine.
SUDO_GDM="josh ALL=(root) NOPASSWD: /usr/bin/systemctl restart gdm, /usr/bin/systemctl restart gdm.service"
if [ "$(sudo cat /etc/sudoers.d/redo-dashboard 2>/dev/null)" != "$SUDO_GDM" ]; then
  echo "Allowing josh to restart the display..."
  echo "$SUDO_GDM" | sudo tee /etc/sudoers.d/redo-dashboard > /dev/null
  sudo chmod 440 /etc/sudoers.d/redo-dashboard
fi
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
daemon = "[daemon]\nAutomaticLoginEnable=true\nAutomaticLogin=dash\n"
text = re.sub(r"\[daemon\]\n", daemon, text, count=1)
open(path, "w").write(text)
PY
fi

# Which session GDM starts comes from AccountsService, not custom.conf; without
# this dash lands in the stock GNOME session.
sudo sed -i '/^AutomaticLoginSession=/d' "$GDM_CONF"

ACCOUNTS_USER=/var/lib/AccountsService/users/dash
ACCOUNTS_RECORD="[User]
Session=dashboard
XSession=dashboard
SystemAccount=false"
if [ "$(sudo cat "$ACCOUNTS_USER" 2>/dev/null)" != "$ACCOUNTS_RECORD" ]; then
  echo "Pointing dash at the dashboard session..."
  sudo install -d -m 775 /var/lib/AccountsService/users
  echo "$ACCOUNTS_RECORD" | sudo tee "$ACCOUNTS_USER" > /dev/null
fi

echo "Dashboard setup done! Reboot to land in the kiosk."
