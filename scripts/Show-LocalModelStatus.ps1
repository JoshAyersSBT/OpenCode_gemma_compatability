param(
  [int]$LlamaCppPort = 11436
)

$ErrorActionPreference = "Continue"

"== Ollama models =="
ollama list

"== Ollama running models =="
ollama ps

"== llama.cpp standalone processes =="
Get-CimInstance Win32_Process |
  Where-Object { $_.Name -eq "llama-server.exe" } |
  Select-Object ProcessId, ExecutablePath, CommandLine |
  Format-List

"== llama.cpp health =="
try {
  Invoke-RestMethod "http://127.0.0.1:$LlamaCppPort/health" -TimeoutSec 3 | ConvertTo-Json -Depth 5
} catch {
  $_.Exception.Message
}

