#!/bin/bash
# Ubuntu system setup script (idempotent)
# Runs all setup helpers — safe to run repeatedly.
set -euo pipefail

DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(cd "$DIR/../.." && pwd)"
HELPERS="$DIR/setup-helpers"

"$HELPERS/base.sh"

echo ""
echo "=== Redo development setup ==="
"$HELPERS/redo.sh"

HOST="$(nix eval --raw "$REPO_DIR#hostNames.\"$(hostname)\"" 2>/dev/null)" || {
  echo "$(hostname) is not listed in hosts.nix, so there is nothing to apply." >&2
  exit 1
}

echo ""
echo "=== ${HOST}-specific setup ==="
"$HELPERS/${HOST}.sh"
