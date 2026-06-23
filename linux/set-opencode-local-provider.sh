#!/usr/bin/env bash
set -euo pipefail

backend="ollama"
ollama_model="gemma4-opencode:12b"
llamacpp_model="gemma4-12b-q4km-llamacpp"
llamacpp_port="11436"
config_path="${OPENCODE_CONFIG:-$HOME/.config/opencode/opencode.json}"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --backend) backend="$2"; shift 2 ;;
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

mkdir -p "$(dirname "$config_path")"
if [[ -f "$config_path" ]]; then
  cp "$config_path" "$config_path.bak-$(date +%Y%m%d-%H%M%S)"
fi

if [[ "$backend" == "ollama" ]]; then
  selected_model="ollama/$ollama_model"
else
  selected_model="llamacpp/$llamacpp_model"
fi

cat > "$config_path" <<EOF
{
  "\$schema": "https://opencode.ai/config.json",
  "provider": {
    "ollama": {
      "npm": "@ai-sdk/openai-compatible",
      "name": "Ollama Local",
      "options": {
        "baseURL": "http://127.0.0.1:11434/v1"
      },
      "models": {
        "$ollama_model": { "name": "$ollama_model" },
        "gemma4-opencode:26b": { "name": "gemma4-opencode:26b" },
        "gemma4:12b": { "name": "gemma4:12b" },
        "gemma4:26b": { "name": "gemma4:26b" },
        "gpt-oss:20b": { "name": "gpt-oss:20b" }
      }
    },
    "llamacpp": {
      "npm": "@ai-sdk/openai-compatible",
      "name": "llama.cpp Local",
      "options": {
        "baseURL": "http://127.0.0.1:$llamacpp_port/v1"
      },
      "models": {
        "$llamacpp_model": { "name": "$llamacpp_model" }
      }
    }
  },
  "model": "$selected_model"
}
EOF

cat "$config_path"

