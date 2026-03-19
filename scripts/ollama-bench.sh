#!/usr/bin/env bash
set -euo pipefail

if [ $# -eq 0 ]; then
  echo "Usage: ollama-bench.sh <model> [prompt]"
  echo ""
  echo "Available models:"
  curl -s http://localhost:11434/api/tags | jq -r '.models[].name'
  exit 1
fi

MODEL="$1"
PROMPT="${2:-Tell me a story}"

curl -s http://localhost:11434/api/generate \
  -d "{\"model\":\"$MODEL\",\"prompt\":\"$PROMPT\",\"stream\":false}" \
  | jq 'if .error then error(.error) else {model: .model, total_duration_s: (.total_duration/1e9), eval_count, tokens_per_second: (.eval_count / (.eval_duration/1e9))} end'
