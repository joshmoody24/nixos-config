#!/bin/bash
set -euo pipefail

REPO_DIR="$(cd "$(dirname "$0")/../.." && pwd)"
home-manager switch --flake "$REPO_DIR#josh@$(hostname)"
