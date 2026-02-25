#!/bin/bash
# Ubuntu system setup script (idempotent)
# Runs all setup helpers — safe to run repeatedly.
set -euo pipefail

DIR="$(cd "$(dirname "$0")" && pwd)"
HELPERS="$DIR/setup-helpers"

"$HELPERS/base.sh"

echo ""
echo "=== Redo development setup ==="
"$HELPERS/redo.sh"

HOST="$(hostname | sed 's/^joshm-//')"
if [ -f "$HELPERS/${HOST}.sh" ]; then
  echo ""
  echo "=== ${HOST}-specific setup ==="
  "$HELPERS/${HOST}.sh"
fi
