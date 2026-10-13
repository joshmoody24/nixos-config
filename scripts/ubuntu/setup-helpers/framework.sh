#!/bin/bash
set -euo pipefail

NIRI_SESSION_BIN="$HOME/.nix-profile/bin/niri-session"

if [ ! -x "$NIRI_SESSION_BIN" ]; then
  echo "niri is not installed yet; run home-manager first."
  echo "Framework setup done!"
  exit 0
fi

# Offer niri at the login screen next to GNOME. This runs the packaged
# niri-session, which starts niri.service and so activates
# graphical-session.target; Ubuntu's portal backends refuse to run without it.
# GDM's PATH is also too bare for niri's spawn-at-startup to find anything, so
# the session sets one. It needs the daemon profile too, which is the only place
# the `nix` binary itself lives.
NIRI_SESSION="[Desktop Entry]
Name=Niri
Comment=A scrollable-tiling Wayland compositor
Exec=/usr/bin/env PATH=$HOME/.local/bin:$HOME/.nix-profile/bin:/nix/var/nix/profiles/default/bin:/usr/local/bin:/usr/bin:/bin $NIRI_SESSION_BIN
Type=Application
DesktopNames=niri"
NIRI_SESSION_FILE=/usr/share/wayland-sessions/niri.desktop

if [ "$(sudo cat "$NIRI_SESSION_FILE" 2>/dev/null)" != "$NIRI_SESSION" ]; then
  echo "Adding niri to the login screen..."
  echo "$NIRI_SESSION" | sudo tee "$NIRI_SESSION_FILE" > /dev/null
fi

# xdg-desktop-portal is Ubuntu's, so it only looks for backend preferences
# under /usr/share. Without this, file pickers and screen sharing pick nothing.
PORTALS_SOURCE="$HOME/.nix-profile/share/xdg-desktop-portal/niri-portals.conf"
PORTALS_FILE=/usr/share/xdg-desktop-portal/niri-portals.conf

if ! sudo cmp -s "$PORTALS_SOURCE" "$PORTALS_FILE"; then
  echo "Installing niri's portal preferences..."
  sudo cp "$PORTALS_SOURCE" "$PORTALS_FILE"
fi

# swaylock must come from apt: see the note in shared/niri.nix.
if ! command -v swaylock &>/dev/null; then
  echo "Installing swaylock..."
  sudo apt install -y swaylock
fi

echo "Framework setup done!"
