#!/usr/bin/env bash
# The dashboard session: one fullscreen terminal showing the rendered talk and
# nothing else. Run by GDM as the `dash` user.
#
# cage and foot come from apt so they link against the system's Mesa; only
# deque comes from nix, and it touches no GPU.
set -uo pipefail

export REDO_DASHBOARD_TALK="${REDO_DASHBOARD_TALK:-/var/lib/redo-dashboard/dashboard.deque}"
export REDO_DASHBOARD_DEQUE="$HOME/.nix-profile/bin/deque"

# foot defaults to 8pt, which is unreadable on a 2560x1600 panel across a room.
export REDO_DASHBOARD_FONT="${REDO_DASHBOARD_FONT:-DejaVu Sans Mono:size=28}"

# Anything that ends deque, a stray keypress included, would otherwise leave a
# dead screen until the next reboot: GDM only autologs in once per boot.
# -s allows VT switching: without it cage swallows ctrl+alt+F1 and the only way
# out of the kiosk is a reboot. The other VTs still demand a password.
exec cage -s -- bash -c '
  while true; do
    if [ -f "$REDO_DASHBOARD_TALK" ]; then
      foot --font="$REDO_DASHBOARD_FONT" \
        "$REDO_DASHBOARD_DEQUE" "$REDO_DASHBOARD_TALK"
    fi
    sleep 2
  done
'
