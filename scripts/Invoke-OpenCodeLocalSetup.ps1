param(
  [ValidateSet("ollama", "llamacpp")]
  [string]$Backend = "ollama",
  [ValidateSet("12b", "26b", "31b")]
  [string]$ModelSize = "12b",
  [int]$NumCtx = 32768,
  [switch]$PullIfMissing,
  [switch]$InstallLlamaCpp,
  [int]$LlamaCppPort = 11436,
  [int]$Parallel = 1,
  [ValidateSet("on", "off", "auto")]
  [string]$Reasoning = "off"
)

$ErrorActionPreference = "Stop"

$scripts = $PSScriptRoot

function Invoke-Step {
  param(
    [string]$Name,
    [scriptblock]$Action
  )

  Write-Host ""
  Write-Host "==> $Name"
  & $Action
}

$variantArgs = @{
  ModelSize = $ModelSize
  NumCtx = $NumCtx
}
if ($PullIfMissing) {
  $variantArgs.PullIfMissing = $true
}

Invoke-Step "Create Ollama opencode variant for Gemma 4 $ModelSize" {
  & (Join-Path $scripts "New-OllamaOpencodeVariant.ps1") @variantArgs
}

if ($Backend -eq "ollama") {
  Invoke-Step "Point opencode at Ollama variant" {
    & (Join-Path $scripts "Set-OpenCodeLocalProvider.ps1") `
      -Backend ollama `
      -ModelSize $ModelSize
  }

  Write-Host ""
  Write-Host "Setup complete. opencode is configured for Ollama model gemma4-opencode:$ModelSize."
  exit 0
}

if ($InstallLlamaCpp) {
  Invoke-Step "Install llama.cpp if needed" {
    & (Join-Path $scripts "Install-LlamaCpp.ps1")
  }
}

Invoke-Step "Start standalone llama.cpp server" {
  & (Join-Path $scripts "Start-LlamaCppOpenCodeServer.ps1") `
    -ModelSize $ModelSize `
    -Port $LlamaCppPort `
    -ContextSize $NumCtx `
    -Parallel $Parallel `
    -Reasoning $Reasoning `
    -InstallIfMissing:$InstallLlamaCpp
}

Invoke-Step "Test llama.cpp OpenAI-compatible endpoint" {
  & (Join-Path $scripts "Test-OpenAICompatibleEndpoint.ps1") `
    -BaseUrl "http://127.0.0.1:$LlamaCppPort/v1" `
    -ModelSize $ModelSize
}

Invoke-Step "Point opencode at llama.cpp server" {
  & (Join-Path $scripts "Set-OpenCodeLocalProvider.ps1") `
    -Backend llamacpp `
    -ModelSize $ModelSize `
    -LlamaCppPort $LlamaCppPort
}

Write-Host ""
Write-Host "Setup complete. opencode is configured for llama.cpp model gemma4-$ModelSize-q4km-llamacpp."
