#!/usr/bin/env bash
set -euo pipefail

PREFIX="${PREFIX:-$HOME/.local/share/opencode-local-model-kit}"
REPO_DIR="${REPO_DIR:-$PREFIX/llama.cpp}"
BUILD_DIR="$REPO_DIR/build"

mkdir -p "$PREFIX"

echo "Installing Pop!_OS build dependencies..."
sudo apt-get update
sudo apt-get install -y \
  build-essential \
  cmake \
  git \
  curl \
  pkg-config \
  libcurl4-openssl-dev

backend="VULKAN"
if command -v nvidia-smi >/dev/null 2>&1; then
  backend="CUDA"
fi

if [[ "$backend" == "CUDA" ]]; then
  echo "NVIDIA detected. Installing CUDA build dependency package if available..."
  sudo apt-get install -y nvidia-cuda-toolkit || {
    echo "Could not install nvidia-cuda-toolkit; falling back to Vulkan."
    backend="VULKAN"
  }
fi

if [[ "$backend" == "VULKAN" ]]; then
  echo "Using Vulkan backend."
  sudo apt-get install -y libvulkan-dev vulkan-tools glslc || true
fi

if [[ ! -d "$REPO_DIR/.git" ]]; then
  git clone https://github.com/ggml-org/llama.cpp.git "$REPO_DIR"
else
  git -C "$REPO_DIR" pull --ff-only
fi

cmake_args=(-S "$REPO_DIR" -B "$BUILD_DIR" -DCMAKE_BUILD_TYPE=Release -DLLAMA_CURL=ON)
if [[ "$backend" == "CUDA" ]]; then
  cmake_args+=(-DGGML_CUDA=ON)
else
  cmake_args+=(-DGGML_VULKAN=ON)
fi

cmake "${cmake_args[@]}"
cmake --build "$BUILD_DIR" --config Release -j"$(nproc)"

server="$BUILD_DIR/bin/llama-server"
if [[ ! -x "$server" ]]; then
  server="$BUILD_DIR/bin/server"
fi

if [[ ! -x "$server" ]]; then
  echo "Could not find built llama-server under $BUILD_DIR/bin" >&2
  exit 1
fi

mkdir -p "$HOME/.local/bin"
ln -sf "$server" "$HOME/.local/bin/llama-server"

echo "Installed llama-server: $server"
echo "Symlinked: $HOME/.local/bin/llama-server"
echo "Make sure $HOME/.local/bin is on PATH."

