#!/usr/bin/env bash
set -euo pipefail

model_size="12b"
base=""
port="11436"
ctx="32768"
parallel="1"
reasoning="off"
model_alias=""
server="${LLAMA_SERVER:-}"
kit_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
log_dir="$kit_root/logs"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --size) model_size="$2"; shift 2 ;;
    --base) base="$2"; shift 2 ;;
    --port) port="$2"; shift 2 ;;
    --ctx) ctx="$2"; shift 2 ;;
    --parallel) parallel="$2"; shift 2 ;;
    --reasoning) reasoning="$2"; shift 2 ;;
    --model-alias) model_alias="$2"; shift 2 ;;
    --server) server="$2"; shift 2 ;;
    *) echo "Unknown argument: $1" >&2; exit 2 ;;
  esac
done

case "$model_size" in
  12b|26b|31b) ;;
  *) echo "--size must be one of: 12b, 26b, 31b." >&2; exit 2 ;;
esac

base="${base:-gemma4:$model_size}"
model_alias="${model_alias:-gemma4-$model_size-q4km-llamacpp}"

if [[ -z "$server" ]]; then
  server="$(command -v llama-server || true)"
fi
if [[ -z "$server" ]]; then
  fallback="$HOME/.local/share/opencode-local-model-kit/llama.cpp/build/bin/llama-server"
  [[ -x "$fallback" ]] && server="$fallback"
fi
if [[ -z "$server" || ! -x "$server" ]]; then
  echo "llama-server not found. Run ./linux/install-llamacpp-popos.sh first." >&2
  exit 1
fi

if ! command -v ollama >/dev/null 2>&1; then
  echo "ollama is needed to locate the local GGUF blob for $base." >&2
  exit 1
fi

model_path="$(
  ollama show "$base" --modelfile |
    awk '/^FROM / {print substr($0, 6)}' |
    while read -r candidate; do
      [[ -f "$candidate" ]] && printf '%s\t%s\n' "$(stat -c%s "$candidate")" "$candidate"
    done |
    sort -nr |
    head -n1 |
    cut -f2-
)"

if [[ -z "$model_path" || ! -f "$model_path" ]]; then
  echo "Could not locate a GGUF blob for Ollama model '$base'." >&2
  exit 1
fi

mkdir -p "$log_dir"
stamp="$(date +%Y%m%d-%H%M%S)"
stdout="$log_dir/llama-server-$port-$stamp.log"
stderr="$log_dir/llama-server-$port-$stamp.err.log"
pidfile="$log_dir/llama-server-$port.pid"

"$server" \
  --host 127.0.0.1 \
  --port "$port" \
  --model "$model_path" \
  --alias "$model_alias" \
  --ctx-size "$ctx" \
  --parallel "$parallel" \
  --gpu-layers auto \
  --flash-attn auto \
  --reasoning "$reasoning" \
  --reasoning-budget 0 \
  --cache-ram 0 \
  --no-warmup \
  --jinja \
  >"$stdout" 2>"$stderr" &

pid="$!"
echo "$pid" > "$pidfile"

ready="false"
for _ in $(seq 1 90); do
  sleep 2
  if curl -fsS "http://127.0.0.1:$port/health" >/dev/null 2>&1; then
    ready="true"
    break
  fi
  if ! kill -0 "$pid" >/dev/null 2>&1; then
    break
  fi
done

cat <<EOF
ready=$ready
pid=$pid
url=http://127.0.0.1:$port
openai_base_url=http://127.0.0.1:$port/v1
model_alias=$model_alias
model_path=$model_path
stdout=$stdout
stderr=$stderr
EOF

if [[ "$ready" != "true" ]]; then
  echo "llama-server did not become healthy. Last log lines:" >&2
  tail -80 "$stderr" >&2 || true
  exit 1
fi
