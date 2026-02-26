param(
  [Parameter(Mandatory = $true)]
  [string]$OutputDir,
  [string]$Region = "ap-northeast-2"
)

$ErrorActionPreference = "Stop"
New-Item -ItemType Directory -Force -Path $OutputDir | Out-Null
New-Item -ItemType Directory -Force -Path (Join-Path $OutputDir "s3_bucket_details") | Out-Null

function Invoke-AwsDump {
  param(
    [Parameter(Mandatory = $true)][string]$Command,
    [Parameter(Mandatory = $true)][string]$OutFile
  )
  try {
    Invoke-Expression "$Command | Out-File -Encoding utf8 `"$OutFile`""
  } catch {
    Write-Warning "failed: $Command"
  }
}

$meta = @()
$meta += "backup_started_utc=$((Get-Date).ToUniversalTime().ToString('s'))Z"
$meta += "region=$Region"
try {
  $identity = aws sts get-caller-identity | ConvertFrom-Json
  $meta += "account_id=$($identity.Account)"
  $meta += "caller_arn=$($identity.Arn)"
} catch {
  $meta += "account_id="
  $meta += "caller_arn="
}
$meta | Out-File -Encoding utf8 (Join-Path $OutputDir "backup_meta.txt")

Invoke-AwsDump "aws iam get-account-summary" (Join-Path $OutputDir "iam_account_summary.json")
Invoke-AwsDump "aws iam list-instance-profiles" (Join-Path $OutputDir "iam_instance_profiles.json")
Invoke-AwsDump "aws iam list-roles" (Join-Path $OutputDir "iam_roles.json")

Invoke-AwsDump "aws ec2 get-ebs-encryption-by-default --region $Region" (Join-Path $OutputDir "ec2_ebs_encryption_by_default.json")
Invoke-AwsDump "aws ec2 get-ebs-default-kms-key-id --region $Region" (Join-Path $OutputDir "ec2_ebs_default_kms_key_id.json")
Invoke-AwsDump "aws ec2 describe-security-groups --region $Region" (Join-Path $OutputDir "ec2_security_groups.json")
Invoke-AwsDump "aws ec2 describe-security-group-rules --region $Region" (Join-Path $OutputDir "ec2_security_group_rules.json")
Invoke-AwsDump "aws ec2 describe-iam-instance-profile-associations --region $Region" (Join-Path $OutputDir "ec2_instance_profile_associations.json")

Invoke-AwsDump "aws cloudtrail describe-trails --region $Region --include-shadow-trails" (Join-Path $OutputDir "cloudtrail_describe_trails.json")
Invoke-AwsDump "aws cloudtrail get-event-selectors --trail-name vuln-trail --region $Region" (Join-Path $OutputDir "cloudtrail_event_selectors_vuln-trail.json")
Invoke-AwsDump "aws cloudtrail get-trail-status --name vuln-trail --region $Region" (Join-Path $OutputDir "cloudtrail_status_vuln-trail.json")

Invoke-AwsDump "aws logs describe-log-groups --region $Region" (Join-Path $OutputDir "logs_log_groups.json")
Invoke-AwsDump "aws logs describe-metric-filters --region $Region" (Join-Path $OutputDir "logs_metric_filters.json")
Invoke-AwsDump "aws cloudwatch describe-alarms --region $Region" (Join-Path $OutputDir "cloudwatch_alarms.json")

Invoke-AwsDump "aws s3api list-buckets" (Join-Path $OutputDir "s3_buckets.json")

$bucketsFile = Join-Path $OutputDir "s3_buckets.json"
if (Test-Path $bucketsFile) {
  try {
    $doc = Get-Content -Raw $bucketsFile | ConvertFrom-Json
    foreach ($b in $doc.Buckets) {
      $name = [string]$b.Name
      if ([string]::IsNullOrWhiteSpace($name)) { continue }
      $lname = $name.ToLowerInvariant()
      if ($lname -notmatch "cloudtrail|prowler|tfstate|terraform") { continue }
      $detailDir = Join-Path $OutputDir "s3_bucket_details"
      Invoke-AwsDump "aws s3api get-bucket-versioning --bucket $name" (Join-Path $detailDir "$name.versioning.json")
      Invoke-AwsDump "aws s3api get-bucket-encryption --bucket $name" (Join-Path $detailDir "$name.encryption.json")
      Invoke-AwsDump "aws s3api get-public-access-block --bucket $name" (Join-Path $detailDir "$name.public_access_block.json")
      Invoke-AwsDump "aws s3api get-bucket-policy --bucket $name" (Join-Path $detailDir "$name.policy.json")
      Invoke-AwsDump "aws s3api get-bucket-logging --bucket $name" (Join-Path $detailDir "$name.logging.json")
    }
  } catch {
    Write-Warning "failed to process bucket details"
  }
}

"backup_completed_utc=$((Get-Date).ToUniversalTime().ToString('s'))Z" | Add-Content (Join-Path $OutputDir "backup_meta.txt")
Write-Output "done: $OutputDir"
