param(
  [string]$BaseModel = "gemma4:12b",
  [string]$VariantName = "gemma4-opencode:12b",
  [int]$NumCtx = 32768,
  [switch]$PullIfMissing
)

$ErrorActionPreference = "Stop"

function Test-OllamaModel {
  param([string]$Name)
  $models = ollama list
  return ($models -match ("^" + [regex]::Escape($Name) + "\s"))
}

if (-not (Test-OllamaModel $BaseModel)) {
  if (-not $PullIfMissing) {
    throw "Base model '$BaseModel' is not installed. Re-run with -PullIfMissing or pull it manually."
  }
  ollama pull $BaseModel
}

$modelfile = Join-Path $env:TEMP ("Modelfile." + ($VariantName -replace "[:\\/]", "-"))
@"
FROM $BaseModel
PARAMETER num_ctx $NumCtx
"@ | Set-Content -LiteralPath $modelfile -NoNewline

ollama create $VariantName -f $modelfile
ollama show $VariantName --parameters

