#!/usr/bin/env bash
# The dashboard session: one fullscreen terminal showing the rendered talk and
# nothing else. Run by GDM as the `dash` user.
#
# cage and foot come from apt so they link against the system's Mesa; only
# deque comes from nix, and it touches no GPU.
set -uo pipefail

talk="${REDO_DASHBOARD_TALK:-/var/lib/redo-dashboard/dashboard.deque}"
deque="$HOME/.nix-profile/bin/deque"

# deque exits if the talk is missing; waiting beats a crash loop on a cold boot.
until [ -f "$talk" ]; do
  sleep 5
done

exec cage -- foot "$deque" "$talk"
