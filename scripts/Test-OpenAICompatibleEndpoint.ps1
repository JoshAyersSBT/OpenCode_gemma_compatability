param(
  [string]$BaseUrl = "http://127.0.0.1:11436/v1",
  [string]$Model = "gemma4-12b-q4km-llamacpp",
  [string]$Prompt = "Reply with exactly: local model ready",
  [int]$MaxTokens = 64
)

$ErrorActionPreference = "Stop"

$body = @{
  model = $Model
  messages = @(
    @{ role = "user"; content = $Prompt }
  )
  max_tokens = $MaxTokens
  stream = $false
} | ConvertTo-Json -Depth 20

$sw = [Diagnostics.Stopwatch]::StartNew()
$response = Invoke-RestMethod `
  -Method Post `
  -Uri "$BaseUrl/chat/completions" `
  -ContentType "application/json" `
  -Body $body
$sw.Stop()

[pscustomobject]@{
  ElapsedSeconds = [Math]::Round($sw.Elapsed.TotalSeconds, 3)
  Finish = $response.choices[0].finish_reason
  Content = $response.choices[0].message.content
  Reasoning = $response.choices[0].message.reasoning_content
  Usage = ($response.usage | ConvertTo-Json -Compress)
}

