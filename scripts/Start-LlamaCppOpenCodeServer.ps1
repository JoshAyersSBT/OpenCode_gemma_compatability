param(
  [string]$BaseModel = "gemma4:12b",
  [int]$Port = 11436,
  [int]$ContextSize = 32768,
  [int]$Parallel = 1,
  [ValidateSet("on", "off", "auto")]
  [string]$Reasoning = "off",
  [switch]$InstallIfMissing
)

$ErrorActionPreference = "Stop"

function Find-LlamaServer {
  $cmd = Get-Command llama-server -ErrorAction SilentlyContinue
  if ($cmd) { return $cmd.Source }

  $found = Get-ChildItem -Path "$env:LOCALAPPDATA\Microsoft\WinGet\Packages" -Recurse -Filter "llama-server.exe" -ErrorAction SilentlyContinue | Select-Object -First 1
  if ($found) { return $found.FullName }

  if ($InstallIfMissing) {
    winget install --id ggml.llamacpp --accept-source-agreements --accept-package-agreements
    $found = Get-ChildItem -Path "$env:LOCALAPPDATA\Microsoft\WinGet\Packages" -Recurse -Filter "llama-server.exe" -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($found) { return $found.FullName }
  }

  throw "llama-server.exe was not found. Run Install-LlamaCpp.ps1 first."
}

function Get-OllamaGgufPath {
  param([string]$Model)
  $modelfile = ollama show $Model --modelfile
  $paths = @()
  foreach ($line in $modelfile) {
    if ($line -match '^FROM\s+(.+)$') {
      $candidate = $Matches[1].Trim()
      if (Test-Path -LiteralPath $candidate) {
        $paths += Get-Item -LiteralPath $candidate
      }
    }
  }
  $modelBlob = $paths | Sort-Object Length -Descending | Select-Object -First 1
  if (-not $modelBlob) {
    throw "Could not find a local GGUF blob for Ollama model '$Model'."
  }
  return $modelBlob.FullName
}

$server = Find-LlamaServer
$modelPath = Get-OllamaGgufPath $BaseModel

$root = Split-Path -Parent $PSScriptRoot
$logs = Join-Path $root "logs"
New-Item -ItemType Directory -Force -Path $logs | Out-Null
$stamp = Get-Date -Format "yyyyMMdd-HHmmss"
$stdout = Join-Path $logs "llama-server-$Port-$stamp.log"
$stderr = Join-Path $logs "llama-server-$Port-$stamp.err.log"

$args = @(
  "--host", "127.0.0.1",
  "--port", "$Port",
  "--model", $modelPath,
  "--ctx-size", "$ContextSize",
  "--parallel", "$Parallel",
  "--gpu-layers", "auto",
  "--flash-attn", "auto",
  "--reasoning", $Reasoning,
  "--reasoning-budget", "0",
  "--cache-ram", "0",
  "--no-warmup",
  "--jinja"
)

Start-Process `
  -WindowStyle Hidden `
  -FilePath $server `
  -ArgumentList $args `
  -RedirectStandardOutput $stdout `
  -RedirectStandardError $stderr `
  -WorkingDirectory $root

$ready = $false
for ($i = 0; $i -lt 90; $i++) {
  Start-Sleep -Seconds 2
  try {
    Invoke-RestMethod "http://127.0.0.1:$Port/health" -TimeoutSec 2 | Out-Null
    $ready = $true
    break
  } catch {}
}

[pscustomobject]@{
  Ready = $ready
  Url = "http://127.0.0.1:$Port"
  OpenAIBaseUrl = "http://127.0.0.1:$Port/v1"
  Server = $server
  ModelPath = $modelPath
  Stdout = $stdout
  Stderr = $stderr
}

