#!/bin/bash
set -euo pipefail

NIRI="$HOME/.nix-profile/bin/niri"

if [ ! -x "$NIRI" ]; then
  echo "niri is not installed yet; run home-manager first."
  echo "Framework setup done!"
  exit 0
fi

# Offer niri at the login screen next to GNOME. The session runs `niri
# --session` rather than the packaged `niri-session`, which looks for systemd
# units that a nix profile install does not put on the user unit path. GDM's
# PATH is also too bare for niri's spawn-at-startup to find anything, so the
# session sets one.
NIRI_SESSION="[Desktop Entry]
Name=Niri
Comment=A scrollable-tiling Wayland compositor
Exec=/usr/bin/env PATH=$HOME/.local/bin:$HOME/.nix-profile/bin:/usr/local/bin:/usr/bin:/bin $NIRI --session
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

echo "Framework setup done!"
