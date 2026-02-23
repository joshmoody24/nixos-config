#!/bin/bash
set -euo pipefail

HELPERS="$(cd "$(dirname "$0")/setup-helpers" && pwd)"

echo "=== Base Ubuntu setup ==="
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

echo ""
echo "All done!"
