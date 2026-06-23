#!/usr/bin/env bash
set -euo pipefail

backend="ollama"
model_size="12b"
num_ctx="32768"
pull_if_missing="false"
install_llamacpp="false"
llamacpp_port="11436"
parallel="1"
reasoning="off"
kit_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
linux_dir="$kit_root/linux"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --backend) backend="$2"; shift 2 ;;
    --size) model_size="$2"; shift 2 ;;
    --num-ctx) num_ctx="$2"; shift 2 ;;
    --pull-if-missing) pull_if_missing="true"; shift ;;
    --install-llamacpp) install_llamacpp="true"; shift ;;
    --llamacpp-port) llamacpp_port="$2"; shift 2 ;;
    --parallel) parallel="$2"; shift 2 ;;
    --reasoning) reasoning="$2"; shift 2 ;;
    *) echo "Unknown argument: $1" >&2; exit 2 ;;
  esac
done

case "$backend" in
  ollama|llamacpp) ;;
  *) echo "--backend must be one of: ollama, llamacpp." >&2; exit 2 ;;
esac
case "$model_size" in
  12b|26b|31b) ;;
  *) echo "--size must be one of: 12b, 26b, 31b." >&2; exit 2 ;;
esac
case "$reasoning" in
  on|off|auto) ;;
  *) echo "--reasoning must be one of: on, off, auto." >&2; exit 2 ;;
esac

run_step() {
  local name="$1"
  shift
  printf '\n==> %s\n' "$name"
  "$@"
}

variant_args=(
  "$linux_dir/new-ollama-opencode-variant.sh"
  --size "$model_size"
  --num-ctx "$num_ctx"
)
if [[ "$pull_if_missing" == "true" ]]; then
  variant_args+=(--pull-if-missing)
fi

run_step "Create Ollama opencode variant for Gemma 4 $model_size" "${variant_args[@]}"

if [[ "$backend" == "ollama" ]]; then
  run_step "Point opencode at Ollama variant" \
    "$linux_dir/set-opencode-local-provider.sh" \
    --backend ollama \
    --size "$model_size"

  printf '\nSetup complete. opencode is configured for Ollama model gemma4-opencode:%s.\n' "$model_size"
  exit 0
fi

if [[ "$install_llamacpp" == "true" ]]; then
  run_step "Install llama.cpp if needed" "$linux_dir/install-llamacpp-popos.sh"
fi

run_step "Start standalone llama.cpp server" \
  "$linux_dir/start-llamacpp-opencode-server.sh" \
  --size "$model_size" \
  --port "$llamacpp_port" \
  --ctx "$num_ctx" \
  --parallel "$parallel" \
  --reasoning "$reasoning"

run_step "Test llama.cpp OpenAI-compatible endpoint" \
  "$linux_dir/test-openai-compatible-endpoint.sh" \
  --base-url "http://127.0.0.1:$llamacpp_port/v1" \
  --size "$model_size"

run_step "Point opencode at llama.cpp server" \
  "$linux_dir/set-opencode-local-provider.sh" \
  --backend llamacpp \
  --size "$model_size" \
  --llamacpp-port "$llamacpp_port"

printf '\nSetup complete. opencode is configured for llama.cpp model gemma4-%s-q4km-llamacpp.\n' "$model_size"
