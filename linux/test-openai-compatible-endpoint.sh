#!/usr/bin/env bash
set -euo pipefail

base_url="http://127.0.0.1:11436/v1"
model="gemma4-12b-q4km-llamacpp"
prompt="Reply with exactly: local model ready"
max_tokens="64"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --base-url) base_url="$2"; shift 2 ;;
    --model) model="$2"; shift 2 ;;
    --prompt) prompt="$2"; shift 2 ;;
    --max-tokens) max_tokens="$2"; shift 2 ;;
    *) echo "Unknown argument: $1" >&2; exit 2 ;;
  esac
done

tmp="$(mktemp)"
trap 'rm -f "$tmp"' EXIT

python3 - "$model" "$prompt" "$max_tokens" > "$tmp" <<'PY'
import json
import sys

model, prompt, max_tokens = sys.argv[1], sys.argv[2], int(sys.argv[3])
print(json.dumps({
    "model": model,
    "messages": [{"role": "user", "content": prompt}],
    "max_tokens": max_tokens,
    "stream": False,
}))
PY

start="$(date +%s)"
curl -fsS \
  -H "content-type: application/json" \
  -d @"$tmp" \
  "$base_url/chat/completions" |
  python3 -m json.tool
end="$(date +%s)"
echo "elapsed_seconds=$((end - start))"

