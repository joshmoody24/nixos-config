#!/bin/bash
set -euo pipefail

MODEL="$1"
PROMPT="${2:-Tell me a story}"

curl -s http://localhost:11434/api/generate \
  -d "{\"model\":\"$MODEL\",\"prompt\":\"$PROMPT\",\"stream\":false}" \
  | jq '{model: .model, total_duration_s: (.total_duration/1e9), eval_count, tokens_per_second: (.eval_count / (.eval_duration/1e9))}'
