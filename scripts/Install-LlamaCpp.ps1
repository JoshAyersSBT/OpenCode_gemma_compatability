param(
  [string]$PackageId = "ggml.llamacpp"
)

$ErrorActionPreference = "Stop"

if (Get-Command llama-server -ErrorAction SilentlyContinue) {
  Write-Host "llama-server is already on PATH."
  exit 0
}

$existing = Get-ChildItem -Path "$env:LOCALAPPDATA\Microsoft\WinGet\Packages" -Recurse -Filter "llama-server.exe" -ErrorAction SilentlyContinue | Select-Object -First 1
if ($existing) {
  Write-Host "llama-server already installed at $($existing.FullName)"
  exit 0
}

winget install --id $PackageId --accept-source-agreements --accept-package-agreements

