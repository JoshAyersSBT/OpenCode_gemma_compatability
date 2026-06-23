param(
  [ValidateSet("ollama", "llamacpp")]
  [string]$Backend = "ollama",
  [ValidateSet("12b", "26b", "31b")]
  [string]$ModelSize = "12b",
  [string]$OllamaModel,
  [string]$LlamaCppModel,
  [int]$LlamaCppPort = 11436,
  [string]$ConfigPath = (Join-Path $env:USERPROFILE ".config\opencode\opencode.json")
)

$ErrorActionPreference = "Stop"

if (-not $OllamaModel) {
  $OllamaModel = "gemma4-opencode:$ModelSize"
}
if (-not $LlamaCppModel) {
  $LlamaCppModel = "gemma4-$ModelSize-q4km-llamacpp"
}

function Add-Model {
  param(
    [System.Collections.Specialized.OrderedDictionary]$Models,
    [string]$Name
  )
  if (-not $Models.Contains($Name)) {
    $Models[$Name] = [ordered]@{ name = $Name }
  }
}

$configDir = Split-Path -Parent $ConfigPath
New-Item -ItemType Directory -Force -Path $configDir | Out-Null

if (Test-Path -LiteralPath $ConfigPath) {
  $stamp = Get-Date -Format "yyyyMMdd-HHmmss"
  Copy-Item -LiteralPath $ConfigPath -Destination "$ConfigPath.bak-$stamp" -Force
}

$model = if ($Backend -eq "ollama") { "ollama/$OllamaModel" } else { "llamacpp/$LlamaCppModel" }
$ollamaModels = [ordered]@{}
foreach ($size in @("12b", "26b", "31b")) {
  Add-Model $ollamaModels "gemma4-opencode:$size"
  Add-Model $ollamaModels "gemma4:$size"
}
Add-Model $ollamaModels $OllamaModel
Add-Model $ollamaModels "gpt-oss:20b"

$llamaCppModels = [ordered]@{}
foreach ($size in @("12b", "26b", "31b")) {
  Add-Model $llamaCppModels "gemma4-$size-q4km-llamacpp"
}
Add-Model $llamaCppModels $LlamaCppModel

$config = [ordered]@{
  '$schema' = "https://opencode.ai/config.json"
  provider = [ordered]@{
    ollama = [ordered]@{
      npm = "@ai-sdk/openai-compatible"
      name = "Ollama Local"
      options = [ordered]@{
        baseURL = "http://127.0.0.1:11434/v1"
      }
      models = $ollamaModels
    }
    llamacpp = [ordered]@{
      npm = "@ai-sdk/openai-compatible"
      name = "llama.cpp Local"
      options = [ordered]@{
        baseURL = "http://127.0.0.1:$LlamaCppPort/v1"
      }
      models = $llamaCppModels
    }
  }
  model = $model
}

$config | ConvertTo-Json -Depth 20 | Set-Content -LiteralPath $ConfigPath -NoNewline
Get-Content -Raw -LiteralPath $ConfigPath
