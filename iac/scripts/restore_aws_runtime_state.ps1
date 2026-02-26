param(
  [Parameter(Mandatory = $true)]
  [string]$BackupDir,
  [string]$Region = "ap-northeast-2"
)

$ErrorActionPreference = "Stop"

if (-not (Test-Path $BackupDir)) {
  throw "backup dir not found: $BackupDir"
}

function Invoke-AwsSafe {
  param([Parameter(Mandatory = $true)][string]$Command)
  try {
    Invoke-Expression $Command | Out-Null
  } catch {
    Write-Warning "failed: $Command"
  }
}

Write-Output "restore source: $BackupDir"
Write-Output "region: $Region"

# 1) EBS default encryption state
$ebsFile = Join-Path $BackupDir "ec2_ebs_encryption_by_default.json"
if (Test-Path $ebsFile) {
  try {
    $doc = Get-Content -Raw $ebsFile | ConvertFrom-Json
    if ($doc.EbsEncryptionByDefault -eq $true) {
      Invoke-AwsSafe "aws ec2 enable-ebs-encryption-by-default --region $Region"
    } elseif ($doc.EbsEncryptionByDefault -eq $false) {
      Invoke-AwsSafe "aws ec2 disable-ebs-encryption-by-default --region $Region"
    }
  } catch {
    Write-Warning "failed to parse $ebsFile"
  }
}

$kmsFile = Join-Path $BackupDir "ec2_ebs_default_kms_key_id.json"
if (Test-Path $kmsFile) {
  try {
    $doc = Get-Content -Raw $kmsFile | ConvertFrom-Json
    if ($doc.KmsKeyId) {
      Invoke-AwsSafe "aws ec2 modify-ebs-default-kms-key-id --region $Region --kms-key-id $($doc.KmsKeyId)"
    }
  } catch {
    Write-Warning "failed to parse $kmsFile"
  }
}

# 2) EC2 instance profile associations (best-effort)
$assocFile = Join-Path $BackupDir "ec2_instance_profile_associations.json"
if (Test-Path $assocFile) {
  try {
    $doc = Get-Content -Raw $assocFile | ConvertFrom-Json
    foreach ($a in $doc.IamInstanceProfileAssociations) {
      $instanceId = [string]$a.InstanceId
      $arn = [string]$a.IamInstanceProfile.Arn
      if (-not $instanceId -or -not $arn) { continue }
      if ($arn -match ":instance-profile/(.+)$") {
        $profileName = $Matches[1].Split("/")[0]
        if ($profileName) {
          Invoke-AwsSafe "aws ec2 associate-iam-instance-profile --region $Region --instance-id $instanceId --iam-instance-profile Name=$profileName"
        }
      }
    }
  } catch {
    Write-Warning "failed to parse $assocFile"
  }
}

# 3) CloudTrail event selectors for vuln-trail snapshot
$trailSelectors = Join-Path $BackupDir "cloudtrail_event_selectors_vuln-trail.json"
if (Test-Path $trailSelectors) {
  try {
    $doc = Get-Content -Raw $trailSelectors | ConvertFrom-Json
    $trailName = "vuln-trail"
    if ($doc.TrailARN -and $doc.TrailARN -match ":trail/(.+)$") {
      $trailName = $Matches[1]
    }
    $tmp = Join-Path $env:TEMP ("trail-selectors-" + [Guid]::NewGuid().ToString() + ".json")
    $payload = @{}
    if ($doc.EventSelectors) {
      $payload.EventSelectors = $doc.EventSelectors
    } elseif ($doc.AdvancedEventSelectors) {
      $payload.AdvancedEventSelectors = $doc.AdvancedEventSelectors
    }
    if ($payload.Keys.Count -gt 0) {
      $payload | ConvertTo-Json -Depth 30 | Out-File -Encoding utf8 $tmp
      Invoke-AwsSafe "aws cloudtrail put-event-selectors --region $Region --trail-name $trailName --cli-input-json file://$tmp"
      Remove-Item -Force $tmp -ErrorAction SilentlyContinue
    }
  } catch {
    Write-Warning "failed to restore cloudtrail selectors"
  }
}

Write-Output "restore completed (best-effort)."
Write-Output "note: security-group exact rollback is intentionally excluded for safety."
