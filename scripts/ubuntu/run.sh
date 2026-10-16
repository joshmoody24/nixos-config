#!/bin/bash
# Runs one phase of the Ubuntu setup on every helper this machine needs, in
# order. Both phases are safe to re-run.
#
#   bootstrap  installs what a new machine is missing, and is run once
#   apply      makes a machine match the repo, and is run after every change
set -euo pipefail

PHASE="${1:?usage: run.sh bootstrap|apply}"
DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(cd "$DIR/../.." && pwd)"
HELPERS="$DIR/setup-helpers"
. "$HELPERS/lib.sh"

"$HELPERS/base.sh" "$PHASE"

# Only base.sh can be named without asking nix, because on a new machine it is
# what installs nix in the first place.
nix_on_path
HOST="$(nix eval --raw "$REPO_DIR#hostNames.\"$(hostname)\"" 2>/dev/null)" || {
  echo "$(hostname) is not listed in hosts.nix, so there is nothing to $PHASE." >&2
  exit 1
}

echo ""
echo "=== Redo development setup ==="
"$HELPERS/redo.sh" "$PHASE"

echo ""
echo "=== ${HOST}-specific setup ==="
"$HELPERS/${HOST}.sh" "$PHASE"

echo ""
echo "Ubuntu $PHASE done!"
