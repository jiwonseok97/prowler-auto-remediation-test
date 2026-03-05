param(
  [string]$UpstreamPath = "..\prowler-upstream"
)

$ErrorActionPreference = "Stop"
$resolved = Resolve-Path $UpstreamPath
Write-Host "Using upstream path: $resolved"

Push-Location $resolved
try {
  docker compose ps
} finally {
  Pop-Location
}
