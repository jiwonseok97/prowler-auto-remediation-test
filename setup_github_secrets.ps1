param(
  [Parameter(Mandatory = $true)]
  [string]$Repo
)

$ErrorActionPreference = "Stop"

function Require-Gh {
  if (-not (Get-Command gh -ErrorAction SilentlyContinue)) {
    throw "GitHub CLI(gh)가 필요합니다. 설치 후 다시 실행하세요."
  }
}

function Set-Secret([string]$Name, [string]$Value) {
  if ([string]::IsNullOrWhiteSpace($Value)) {
    throw "$Name 값이 비어 있습니다."
  }
  $Value | gh secret set $Name --repo $Repo
}

Require-Gh

Write-Host "GitHub Actions secrets 설정을 시작합니다. (repo: $Repo)"

$awsAccessKey = Read-Host "AWS_ACCESS_KEY_ID"
$awsSecretKey = Read-Host "AWS_SECRET_ACCESS_KEY"
$awsRegion = Read-Host "AWS_DEFAULT_REGION (예: ap-northeast-2)"
$aiModel = Read-Host "AI_MODEL (예: anthropic.claude-3-haiku-20240307-v1:0)"
$aiApiKey = Read-Host "AI_API_KEY (Bedrock면 bedrock 입력 가능)"

Set-Secret "AWS_ACCESS_KEY_ID" $awsAccessKey
Set-Secret "AWS_SECRET_ACCESS_KEY" $awsSecretKey
Set-Secret "AWS_DEFAULT_REGION" $awsRegion
Set-Secret "AI_MODEL" $aiModel
Set-Secret "AI_API_KEY" $aiApiKey

Write-Host "완료: GitHub Actions secrets가 설정되었습니다."
