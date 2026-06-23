param(
  [ValidateSet("ollama", "llamacpp")]
  [string]$Backend = "ollama",
  [string]$OllamaModel = "gemma4-opencode:12b",
  [string]$LlamaCppModel = "gemma4-12b-q4km-llamacpp",
  [int]$LlamaCppPort = 11436,
  [string]$ConfigPath = (Join-Path $env:USERPROFILE ".config\opencode\opencode.json")
)

$ErrorActionPreference = "Stop"

$configDir = Split-Path -Parent $ConfigPath
New-Item -ItemType Directory -Force -Path $configDir | Out-Null

if (Test-Path -LiteralPath $ConfigPath) {
  $stamp = Get-Date -Format "yyyyMMdd-HHmmss"
  Copy-Item -LiteralPath $ConfigPath -Destination "$ConfigPath.bak-$stamp" -Force
}

$model = if ($Backend -eq "ollama") { "ollama/$OllamaModel" } else { "llamacpp/$LlamaCppModel" }

$config = [ordered]@{
  '$schema' = "https://opencode.ai/config.json"
  provider = [ordered]@{
    ollama = [ordered]@{
      npm = "@ai-sdk/openai-compatible"
      name = "Ollama Local"
      options = [ordered]@{
        baseURL = "http://127.0.0.1:11434/v1"
      }
      models = [ordered]@{
        $OllamaModel = [ordered]@{ name = $OllamaModel }
        "gemma4-opencode:26b" = [ordered]@{ name = "gemma4-opencode:26b" }
        "gemma4:12b" = [ordered]@{ name = "gemma4:12b" }
        "gemma4:26b" = [ordered]@{ name = "gemma4:26b" }
        "gpt-oss:20b" = [ordered]@{ name = "gpt-oss:20b" }
      }
    }
    llamacpp = [ordered]@{
      npm = "@ai-sdk/openai-compatible"
      name = "llama.cpp Local"
      options = [ordered]@{
        baseURL = "http://127.0.0.1:$LlamaCppPort/v1"
      }
      models = [ordered]@{
        $LlamaCppModel = [ordered]@{ name = $LlamaCppModel }
      }
    }
  }
  model = $model
}

$config | ConvertTo-Json -Depth 20 | Set-Content -LiteralPath $ConfigPath -NoNewline
Get-Content -Raw -LiteralPath $ConfigPath

