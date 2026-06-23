#!/usr/bin/env bash
set -euo pipefail

model_size="12b"
base=""
variant=""
num_ctx="32768"
pull_if_missing="false"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --size) model_size="$2"; shift 2 ;;
    --base) base="$2"; shift 2 ;;
    --variant) variant="$2"; shift 2 ;;
    --num-ctx) num_ctx="$2"; shift 2 ;;
    --pull-if-missing) pull_if_missing="true"; shift ;;
    *) echo "Unknown argument: $1" >&2; exit 2 ;;
  esac
done

case "$model_size" in
  12b|26b|31b) ;;
  *) echo "--size must be one of: 12b, 26b, 31b." >&2; exit 2 ;;
esac

base="${base:-gemma4:$model_size}"
variant="${variant:-gemma4-opencode:$model_size}"

if ! command -v ollama >/dev/null 2>&1; then
  echo "ollama is not installed or not on PATH." >&2
  exit 1
fi

if ! ollama list | awk '{print $1}' | grep -Fxq "$base"; then
  if [[ "$pull_if_missing" != "true" ]]; then
    echo "Base model '$base' is not installed. Re-run with --pull-if-missing or run: ollama pull $base" >&2
    exit 1
  fi
  ollama pull "$base"
fi

modelfile="$(mktemp)"
trap 'rm -f "$modelfile"' EXIT
cat > "$modelfile" <<EOF
FROM $base
PARAMETER num_ctx $num_ctx
EOF

ollama create "$variant" -f "$modelfile"
ollama show "$variant" --parameters
