#!/usr/bin/env bash
set -euo pipefail

# Usage:
#   bash iac/scripts/backup_aws_runtime_state.sh <output_dir> [region]
#
# Example:
#   bash iac/scripts/backup_aws_runtime_state.sh backup/state-20260222/aws ap-northeast-2

OUT_DIR="${1:-}"
REGION="${2:-${AWS_REGION:-${AWS_DEFAULT_REGION:-ap-northeast-2}}}"

if [ -z "$OUT_DIR" ]; then
  echo "usage: $0 <output_dir> [region]" >&2
  exit 1
fi

mkdir -p "$OUT_DIR"

echo "backup region: $REGION"
echo "backup started: $(date -u +%Y-%m-%dT%H:%M:%SZ)" > "$OUT_DIR/backup_meta.txt"
echo "region=$REGION" >> "$OUT_DIR/backup_meta.txt"

ACCOUNT_ID="$(aws sts get-caller-identity --query Account --output text 2>/dev/null || true)"
ARN="$(aws sts get-caller-identity --query Arn --output text 2>/dev/null || true)"
echo "account_id=${ACCOUNT_ID}" >> "$OUT_DIR/backup_meta.txt"
echo "caller_arn=${ARN}" >> "$OUT_DIR/backup_meta.txt"

# Core snapshots
aws iam get-account-summary > "$OUT_DIR/iam_account_summary.json" || true
aws iam list-instance-profiles > "$OUT_DIR/iam_instance_profiles.json" || true
aws iam list-roles > "$OUT_DIR/iam_roles.json" || true

aws ec2 get-ebs-encryption-by-default --region "$REGION" > "$OUT_DIR/ec2_ebs_encryption_by_default.json" || true
aws ec2 get-ebs-default-kms-key-id --region "$REGION" > "$OUT_DIR/ec2_ebs_default_kms_key_id.json" || true
aws ec2 describe-security-groups --region "$REGION" > "$OUT_DIR/ec2_security_groups.json" || true
aws ec2 describe-security-group-rules --region "$REGION" > "$OUT_DIR/ec2_security_group_rules.json" || true
aws ec2 describe-iam-instance-profile-associations --region "$REGION" > "$OUT_DIR/ec2_instance_profile_associations.json" || true

aws cloudtrail describe-trails --region "$REGION" --include-shadow-trails > "$OUT_DIR/cloudtrail_describe_trails.json" || true
aws cloudtrail get-event-selectors --trail-name vuln-trail --region "$REGION" > "$OUT_DIR/cloudtrail_event_selectors_vuln-trail.json" || true
aws cloudtrail get-trail-status --name vuln-trail --region "$REGION" > "$OUT_DIR/cloudtrail_status_vuln-trail.json" || true

aws logs describe-log-groups --region "$REGION" > "$OUT_DIR/logs_log_groups.json" || true
aws logs describe-metric-filters --region "$REGION" > "$OUT_DIR/logs_metric_filters.json" || true
aws cloudwatch describe-alarms --region "$REGION" > "$OUT_DIR/cloudwatch_alarms.json" || true

aws s3api list-buckets > "$OUT_DIR/s3_buckets.json" || true

# Bucket-level snapshots for likely relevant buckets (cloudtrail/prowler)
mkdir -p "$OUT_DIR/s3_bucket_details"
python - <<'PY' "$OUT_DIR/s3_buckets.json" "$OUT_DIR/s3_bucket_details"
import json, sys, subprocess
from pathlib import Path

buckets_file = Path(sys.argv[1])
detail_dir = Path(sys.argv[2])
if not buckets_file.exists():
    raise SystemExit(0)
doc = json.loads(buckets_file.read_text(encoding="utf-8"))
for b in doc.get("Buckets", []) or []:
    name = (b.get("Name") or "").strip()
    if not name:
        continue
    lname = name.lower()
    if not any(tok in lname for tok in ("cloudtrail", "prowler", "tfstate", "terraform")):
        continue
    for op, suffix in [
        (["aws", "s3api", "get-bucket-versioning", "--bucket", name], "versioning"),
        (["aws", "s3api", "get-bucket-encryption", "--bucket", name], "encryption"),
        (["aws", "s3api", "get-public-access-block", "--bucket", name], "public_access_block"),
        (["aws", "s3api", "get-bucket-policy", "--bucket", name], "policy"),
        (["aws", "s3api", "get-bucket-logging", "--bucket", name], "logging"),
    ]:
        out = detail_dir / f"{name}.{suffix}.json"
        try:
            p = subprocess.run(op, capture_output=True, text=True, check=False)
            if p.returncode == 0 and p.stdout.strip():
                out.write_text(p.stdout, encoding="utf-8")
        except Exception:
            pass
PY

echo "backup completed: $(date -u +%Y-%m-%dT%H:%M:%SZ)" >> "$OUT_DIR/backup_meta.txt"
echo "done: $OUT_DIR"
