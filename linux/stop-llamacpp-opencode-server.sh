#!/usr/bin/env bash
set -euo pipefail

port="11436"
kit_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
log_dir="$kit_root/logs"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --port) port="$2"; shift 2 ;;
    *) echo "Unknown argument: $1" >&2; exit 2 ;;
  esac
done

pidfile="$log_dir/llama-server-$port.pid"

if [[ -f "$pidfile" ]]; then
  pid="$(cat "$pidfile")"
  if [[ -n "$pid" ]] && kill -0 "$pid" >/dev/null 2>&1; then
    kill "$pid"
    rm -f "$pidfile"
    echo "Stopped llama-server PID $pid."
    exit 0
  fi
fi

matches="$(pgrep -af "llama-server.*--port $port" || true)"
if [[ -z "$matches" ]]; then
  echo "No standalone llama-server found on port $port."
  exit 0
fi

echo "$matches" | awk '{print $1}' | while read -r pid; do
  kill "$pid"
  echo "Stopped llama-server PID $pid."
done

