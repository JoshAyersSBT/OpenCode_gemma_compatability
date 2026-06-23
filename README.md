# opencode Local Model Kit

Portable PowerShell helpers for running opencode against local Gemma models through either Ollama or llama.cpp.

This kit does three things:

- Creates Ollama opencode variants with a larger context window, for example `gemma4-opencode:12b`, `gemma4-opencode:26b`, or `gemma4-opencode:31b`.
- Switches `~/.config/opencode/opencode.json` between Ollama and llama.cpp providers.
- Starts a standalone `llama-server` on a side port for speed testing without stopping Ollama.

## Quick Start: Ollama

### Windows PowerShell

Choose a Gemma 4 size: `12b`, `26b`, or `31b`. Create an opencode variant for that size:

```powershell
.\scripts\New-OllamaOpencodeVariant.ps1 -ModelSize 12b -NumCtx 32768 -PullIfMissing
```

Point opencode at Ollama using that variant:

```powershell
.\scripts\Set-OpenCodeLocalProvider.ps1 -Backend ollama -ModelSize 12b
```

### Pop!_OS / Linux

Choose a Gemma 4 size: `12b`, `26b`, or `31b`. Create an opencode variant for that size:

```bash
./linux/new-ollama-opencode-variant.sh --size 12b --num-ctx 32768 --pull-if-missing
```

Point opencode at Ollama using that variant:

```bash
./linux/set-opencode-local-provider.sh --backend ollama --size 12b
```

## Quick Start: llama.cpp

### Windows PowerShell

Install llama.cpp if needed:

```powershell
.\scripts\Install-LlamaCpp.ps1
```

Start a standalone llama.cpp OpenAI-compatible server on port `11436`:

```powershell
.\scripts\Start-LlamaCppOpenCodeServer.ps1 -ModelSize 12b -Port 11436 -ContextSize 32768 -Parallel 1 -Reasoning off
```

Test it:

```powershell
.\scripts\Test-OpenAICompatibleEndpoint.ps1 -BaseUrl http://127.0.0.1:11436/v1 -ModelSize 12b
```

Point opencode at llama.cpp:

```powershell
.\scripts\Set-OpenCodeLocalProvider.ps1 -Backend llamacpp -ModelSize 12b -LlamaCppPort 11436
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
./linux/start-llamacpp-opencode-server.sh --size 12b --port 11436 --ctx 32768 --parallel 1 --reasoning off
```

Test it:

```bash
./linux/test-openai-compatible-endpoint.sh --base-url http://127.0.0.1:11436/v1 --size 12b
```

Point opencode at llama.cpp:

```bash
./linux/set-opencode-local-provider.sh --backend llamacpp --size 12b --llamacpp-port 11436
```

Stop only the standalone llama.cpp server started by this kit:

```bash
./linux/stop-llamacpp-opencode-server.sh --port 11436
```

## Notes

- The scripts support Gemma 4 `12b`, `26b`, and `31b` through `-ModelSize` on Windows or `--size` on Linux. Exact model names can still be overridden with `-BaseModel`, `-VariantName`, `-OllamaModel`, `-LlamaCppModel`, `--base`, `--variant`, `--ollama-model`, or `--llamacpp-model`.
- The 12B Ollama model pulled during setup was already `Q4_K_M`.
- Ollama's OpenAI-compatible endpoint ignored request-level `num_ctx` overrides on this machine, so the context fix is baked into an Ollama variant via `PARAMETER num_ctx 32768`.
- The standalone llama.cpp server can run next to Ollama, but it competes for GPU/CPU/RAM. On this laptop, the first 4-slot llama.cpp run was much slower than Ollama; the included launcher defaults to one slot.
- `Set-OpenCodeLocalProvider.ps1` backs up the existing opencode config before writing a new one.
- The Linux scripts back up `~/.config/opencode/opencode.json` before changing it. The Pop!_OS llama.cpp installer prefers CUDA when `nvidia-smi` is present, otherwise Vulkan.
