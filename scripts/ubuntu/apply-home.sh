#!/bin/bash
set -euo pipefail

REPO_DIR="$(cd "$(dirname "$0")/../.." && pwd)"
home-manager switch -b backup --flake "$REPO_DIR#josh@$(hostname)"
