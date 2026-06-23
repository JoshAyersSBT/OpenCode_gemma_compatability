param(
  [int]$Port = 11436
)

$ErrorActionPreference = "Stop"

$matches = Get-CimInstance Win32_Process |
  Where-Object {
    $_.Name -eq "llama-server.exe" -and
    $_.CommandLine -match ("--port\s+" + [regex]::Escape([string]$Port)) -and
    $_.ExecutablePath -notmatch "\\Ollama\\"
  }

if (-not $matches) {
  Write-Host "No standalone llama-server found on port $Port."
  exit 0
}

foreach ($proc in $matches) {
  Stop-Process -Id $proc.ProcessId -Force
  Write-Host "Stopped llama-server PID $($proc.ProcessId)."
}

