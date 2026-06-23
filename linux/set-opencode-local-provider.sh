#!/usr/bin/env bash
set -euo pipefail

backend="ollama"
model_size="12b"
ollama_model=""
llamacpp_model=""
llamacpp_port="11436"
config_path="${OPENCODE_CONFIG:-$HOME/.config/opencode/opencode.json}"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --backend) backend="$2"; shift 2 ;;
    --size) model_size="$2"; shift 2 ;;
    --ollama-model) ollama_model="$2"; shift 2 ;;
    --llamacpp-model) llamacpp_model="$2"; shift 2 ;;
    --llamacpp-port) llamacpp_port="$2"; shift 2 ;;
    --config) config_path="$2"; shift 2 ;;
    *) echo "Unknown argument: $1" >&2; exit 2 ;;
  esac
done

if [[ "$backend" != "ollama" && "$backend" != "llamacpp" ]]; then
  echo "--backend must be 'ollama' or 'llamacpp'." >&2
  exit 2
fi
case "$model_size" in
  12b|26b|31b) ;;
  *) echo "--size must be one of: 12b, 26b, 31b." >&2; exit 2 ;;
esac

ollama_model="${ollama_model:-gemma4-opencode:$model_size}"
llamacpp_model="${llamacpp_model:-gemma4-$model_size-q4km-llamacpp}"

mkdir -p "$(dirname "$config_path")"
if [[ -f "$config_path" ]]; then
  cp "$config_path" "$config_path.bak-$(date +%Y%m%d-%H%M%S)"
fi

python3 - "$config_path" "$backend" "$ollama_model" "$llamacpp_model" "$llamacpp_port" <<'PY'
import json
import sys

config_path, backend, ollama_model, llamacpp_model, llamacpp_port = sys.argv[1:]
sizes = ("12b", "26b", "31b")

def model_map(names):
    out = {}
    for name in names:
        out.setdefault(name, {"name": name})
    return out

selected_model = f"ollama/{ollama_model}" if backend == "ollama" else f"llamacpp/{llamacpp_model}"
config = {
    "$schema": "https://opencode.ai/config.json",
    "provider": {
        "ollama": {
            "npm": "@ai-sdk/openai-compatible",
            "name": "Ollama Local",
            "options": {"baseURL": "http://127.0.0.1:11434/v1"},
            "models": model_map(
                [*(f"gemma4-opencode:{size}" for size in sizes),
                 *(f"gemma4:{size}" for size in sizes),
                 ollama_model,
                 "gpt-oss:20b"]
            ),
        },
        "llamacpp": {
            "npm": "@ai-sdk/openai-compatible",
            "name": "llama.cpp Local",
            "options": {"baseURL": f"http://127.0.0.1:{llamacpp_port}/v1"},
            "models": model_map(
                [*(f"gemma4-{size}-q4km-llamacpp" for size in sizes),
                 llamacpp_model]
            ),
        },
    },
    "model": selected_model,
}

with open(config_path, "w", encoding="utf-8") as f:
    json.dump(config, f, indent=2)
PY

cat "$config_path"
