param(
  [string]$UpstreamPath = "..\prowler-upstream"
)

$ErrorActionPreference = "Stop"

$resolved = Resolve-Path $UpstreamPath
Write-Host "Using upstream path: $resolved"

docker info | Out-Null

Push-Location $resolved
try {
  docker compose up -d
  Write-Host ""
  Write-Host "Prowler upstream app started."
  Write-Host "UI:  http://localhost:3000"
  Write-Host "API: http://localhost:8080/api/v1/docs"
} finally {
  Pop-Location
}
