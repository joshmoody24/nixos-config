#!/bin/bash
set -euo pipefail

REPO_DIR="$(cd "$(dirname "$0")/../../.." && pwd)"
. "$(dirname "$0")/lib.sh"

SYSTEMD_DOTFILES="$REPO_DIR/shared/dotfiles/systemd"
NIRI_SESSION_BIN="$HOME/.nix-profile/bin/niri-session"
PORTALS_SOURCE="$HOME/.nix-profile/share/xdg-desktop-portal/niri-portals.conf"
PORTALS_FILE=/usr/share/xdg-desktop-portal/niri-portals.conf

bootstrap() {
  # swaylock must come from apt: see the note in shared/niri.nix.
  apt_install swaylock
}

apply() {
  # Keeps password checks working for programs running as you; see the script's
  # own comment.
  echo "Installing the shadow group repair timer..."
  sudo install -D -m 755 "$SYSTEMD_DOTFILES/restore-shadow-group" \
    /usr/local/sbin/restore-shadow-group
  for unit in restore-shadow-group.service restore-shadow-group.timer; do
    sudo install -D -m 644 "$SYSTEMD_DOTFILES/$unit" "/etc/systemd/system/$unit"
  done
  sudo systemctl daemon-reload
  sudo systemctl enable --now restore-shadow-group.timer
  sudo systemctl start restore-shadow-group.service

  if [ ! -x "$NIRI_SESSION_BIN" ]; then
    echo "niri is not installed yet; the login screen entry needs another apply."
    return
  fi

  # Offer niri at the login screen next to GNOME. This runs the packaged
  # niri-session, which starts niri.service and so activates
  # graphical-session.target; Ubuntu's portal backends refuse to run without it.
  # GDM's PATH is also too bare for niri's spawn-at-startup to find anything, so
  # the session sets one. It needs the daemon profile too, which is the only place
  # the `nix` binary itself lives.
  install_system_file 644 /usr/share/wayland-sessions/niri.desktop "[Desktop Entry]
Name=Niri
Comment=A scrollable-tiling Wayland compositor
Exec=/usr/bin/env PATH=$HOME/.local/bin:$HOME/.nix-profile/bin:/nix/var/nix/profiles/default/bin:/usr/local/bin:/usr/bin:/bin $NIRI_SESSION_BIN
Type=Application
DesktopNames=niri"

  # xdg-desktop-portal is Ubuntu's, so it only looks for backend preferences
  # under /usr/share. Without this, file pickers and screen sharing pick nothing.
  if ! sudo cmp -s "$PORTALS_SOURCE" "$PORTALS_FILE"; then
    echo "Installing niri's portal preferences..."
    sudo cp "$PORTALS_SOURCE" "$PORTALS_FILE"
  fi
}

run_phase "${1:-}"
