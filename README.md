# opencode Local Model Kit

Portable PowerShell helpers for running opencode against local Gemma models through either Ollama or llama.cpp.

This kit does three things:

- Creates Ollama opencode variants with a larger context window, for example `gemma4-opencode:12b`.
- Switches `~/.config/opencode/opencode.json` between Ollama and llama.cpp providers.
- Starts a standalone `llama-server` on a side port for speed testing without stopping Ollama.

## Quick Start: Ollama

### Windows PowerShell

Create the 12B opencode variant:

```powershell
.\scripts\New-OllamaOpencodeVariant.ps1 -BaseModel gemma4:12b -VariantName gemma4-opencode:12b -NumCtx 32768 -PullIfMissing
```

Point opencode at Ollama using that variant:

```powershell
.\scripts\Set-OpenCodeLocalProvider.ps1 -Backend ollama -OllamaModel gemma4-opencode:12b
```

### Pop!_OS / Linux

Create the 12B opencode variant:

```bash
./linux/new-ollama-opencode-variant.sh --base gemma4:12b --variant gemma4-opencode:12b --num-ctx 32768 --pull-if-missing
```

Point opencode at Ollama using that variant:

```bash
./linux/set-opencode-local-provider.sh --backend ollama --ollama-model gemma4-opencode:12b
```

## Quick Start: llama.cpp

### Windows PowerShell

Install llama.cpp if needed:

```powershell
.\scripts\Install-LlamaCpp.ps1
```

Start a standalone llama.cpp OpenAI-compatible server on port `11436`:

```powershell
.\scripts\Start-LlamaCppOpenCodeServer.ps1 -BaseModel gemma4:12b -Port 11436 -ContextSize 32768 -Parallel 1 -Reasoning off
```

Test it:

```powershell
.\scripts\Test-OpenAICompatibleEndpoint.ps1 -BaseUrl http://127.0.0.1:11436/v1 -Model gemma4-12b-q4km-llamacpp
```

Point opencode at llama.cpp:

```powershell
.\scripts\Set-OpenCodeLocalProvider.ps1 -Backend llamacpp -LlamaCppPort 11436 -LlamaCppModel gemma4-12b-q4km-llamacpp
```

Stop only the standalone llama.cpp server started by this kit:

```powershell
.\scripts\Stop-LlamaCppOpenCodeServer.ps1 -Port 11436
```

### Pop!_OS / Linux

Install dependencies and build llama.cpp under `~/.local/share/opencode-local-model-kit/llama.cpp`:

```bash
./linux/install-llamacpp-popos.sh
```

Start a standalone llama.cpp OpenAI-compatible server on port `11436`:

```bash
./linux/start-llamacpp-opencode-server.sh --base gemma4:12b --port 11436 --ctx 32768 --parallel 1 --reasoning off
```

Test it:

```bash
./linux/test-openai-compatible-endpoint.sh --base-url http://127.0.0.1:11436/v1 --model gemma4-12b-q4km-llamacpp
```

Point opencode at llama.cpp:

```bash
./linux/set-opencode-local-provider.sh --backend llamacpp --llamacpp-port 11436 --llamacpp-model gemma4-12b-q4km-llamacpp
```

Stop only the standalone llama.cpp server started by this kit:

```bash
./linux/stop-llamacpp-opencode-server.sh --port 11436
```

## Notes

- The 12B Ollama model pulled during setup was already `Q4_K_M`.
- Ollama's OpenAI-compatible endpoint ignored request-level `num_ctx` overrides on this machine, so the context fix is baked into an Ollama variant via `PARAMETER num_ctx 32768`.
- The standalone llama.cpp server can run next to Ollama, but it competes for GPU/CPU/RAM. On this laptop, the first 4-slot llama.cpp run was much slower than Ollama; the included launcher defaults to one slot.
- `Set-OpenCodeLocalProvider.ps1` backs up the existing opencode config before writing a new one.
- The Linux scripts back up `~/.config/opencode/opencode.json` before changing it. The Pop!_OS llama.cpp installer prefers CUDA when `nvidia-smi` is present, otherwise Vulkan.
