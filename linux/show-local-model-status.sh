#!/usr/bin/env bash
set -euo pipefail

port="11436"
while [[ $# -gt 0 ]]; do
  case "$1" in
    --port) port="$2"; shift 2 ;;
    *) echo "Unknown argument: $1" >&2; exit 2 ;;
  esac
done

echo "== Ollama models =="
if command -v ollama >/dev/null 2>&1; then
  ollama list
else
  echo "ollama not found"
fi

echo
echo "== Ollama running models =="
if command -v ollama >/dev/null 2>&1; then
  ollama ps || true
fi

echo
echo "== llama-server processes =="
pgrep -af "llama-server" || true

echo
echo "== llama.cpp health =="
curl -fsS "http://127.0.0.1:$port/health" || true
echo

