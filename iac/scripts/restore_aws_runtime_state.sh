#!/usr/bin/env bash
set -euo pipefail

# Usage:
#   bash iac/scripts/restore_aws_runtime_state.sh <backup_dir> [region]
#
# Notes:
# - Best-effort restore for high-impact controls touched by this pipeline.
# - Security group full rollback is intentionally NOT automatic by default
#   because it can be destructive in shared accounts.

BACKUP_DIR="${1:-}"
REGION="${2:-${AWS_REGION:-${AWS_DEFAULT_REGION:-ap-northeast-2}}}"

if [ -z "$BACKUP_DIR" ]; then
  echo "usage: $0 <backup_dir> [region]" >&2
  exit 1
fi

if [ ! -d "$BACKUP_DIR" ]; then
  echo "backup dir not found: $BACKUP_DIR" >&2
  exit 1
fi

echo "restore region: $REGION"
echo "restore source: $BACKUP_DIR"

# 1) Restore EBS account default encryption state
if [ -f "$BACKUP_DIR/ec2_ebs_encryption_by_default.json" ]; then
  ENABLED="$(python - <<'PY' "$BACKUP_DIR/ec2_ebs_encryption_by_default.json"
import json,sys
doc=json.load(open(sys.argv[1],encoding='utf-8'))
print(str(doc.get("EbsEncryptionByDefault", "")).lower())
PY
)"
  if [ "$ENABLED" = "true" ]; then
    aws ec2 enable-ebs-encryption-by-default --region "$REGION" || true
  elif [ "$ENABLED" = "false" ]; then
    aws ec2 disable-ebs-encryption-by-default --region "$REGION" || true
  fi
fi

if [ -f "$BACKUP_DIR/ec2_ebs_default_kms_key_id.json" ]; then
  KMS_KEY_ID="$(python - <<'PY' "$BACKUP_DIR/ec2_ebs_default_kms_key_id.json"
import json,sys
doc=json.load(open(sys.argv[1],encoding='utf-8'))
print(doc.get("KmsKeyId",""))
PY
)"
  if [ -n "$KMS_KEY_ID" ] && [ "$KMS_KEY_ID" != "None" ]; then
    aws ec2 modify-ebs-default-kms-key-id --region "$REGION" --kms-key-id "$KMS_KEY_ID" || true
  fi
fi

# 2) Restore EC2 instance-profile associations
if [ -f "$BACKUP_DIR/ec2_instance_profile_associations.json" ]; then
  python - <<'PY' "$BACKUP_DIR/ec2_instance_profile_associations.json" "$REGION"
import json,sys,subprocess
doc=json.load(open(sys.argv[1],encoding='utf-8'))
region=sys.argv[2]
for assoc in doc.get("IamInstanceProfileAssociations",[]) or []:
    instance_id=((assoc.get("InstanceId") or "")).strip()
    profile=((assoc.get("IamInstanceProfile") or {}).get("Arn") or "").strip()
    if not instance_id or not profile:
        continue
    name = ""
    if ":instance-profile/" in profile:
        name = profile.split(":instance-profile/",1)[1].split("/",1)[0]
    if not name:
        continue
    subprocess.run([
        "aws","ec2","associate-iam-instance-profile",
        "--region",region,
        "--instance-id",instance_id,
        "--iam-instance-profile",f"Name={name}",
    ], check=False)
PY
fi

# 3) Restore CloudTrail event selectors for vuln-trail snapshot (if present)
if [ -f "$BACKUP_DIR/cloudtrail_event_selectors_vuln-trail.json" ]; then
  python - <<'PY' "$BACKUP_DIR/cloudtrail_event_selectors_vuln-trail.json" "$REGION"
import json,sys,tempfile,subprocess,os
doc=json.load(open(sys.argv[1],encoding='utf-8'))
region=sys.argv[2]
selectors=doc.get("EventSelectors",[])
advanced=doc.get("AdvancedEventSelectors",[])
trail_name=doc.get("TrailARN","vuln-trail")
if ":trail/" in trail_name:
    trail_name=trail_name.split(":trail/",1)[1]
if selectors:
    payload={"EventSelectors":selectors}
    with tempfile.NamedTemporaryFile("w",delete=False,encoding="utf-8",suffix=".json") as f:
        json.dump(payload,f)
        p=f.name
    subprocess.run(["aws","cloudtrail","put-event-selectors","--region",region,"--trail-name",trail_name,"--cli-input-json",f"file://{p}"],check=False)
    os.unlink(p)
elif advanced:
    payload={"AdvancedEventSelectors":advanced}
    with tempfile.NamedTemporaryFile("w",delete=False,encoding="utf-8",suffix=".json") as f:
        json.dump(payload,f)
        p=f.name
    subprocess.run(["aws","cloudtrail","put-event-selectors","--region",region,"--trail-name",trail_name,"--cli-input-json",f"file://{p}"],check=False)
    os.unlink(p)
PY
fi

# 4) Restore CloudWatch metric filters (best-effort create/update)
if [ -f "$BACKUP_DIR/logs_metric_filters.json" ]; then
  python - <<'PY' "$BACKUP_DIR/logs_metric_filters.json" "$REGION"
import json,sys,subprocess
doc=json.load(open(sys.argv[1],encoding='utf-8'))
region=sys.argv[2]
for f in doc.get("metricFilters",[]) or []:
    lg=(f.get("logGroupName") or "").strip()
    name=(f.get("filterName") or "").strip()
    pattern=(f.get("filterPattern") or "")
    transforms=f.get("metricTransformations") or []
    if not lg or not name or not transforms:
        continue
    t=transforms[0]
    mn=(t.get("metricName") or "").strip()
    ns=(t.get("metricNamespace") or "").strip()
    val=(t.get("metricValue") or "1")
    if not mn or not ns:
        continue
    subprocess.run([
      "aws","logs","put-metric-filter",
      "--region",region,
      "--log-group-name",lg,
      "--filter-name",name,
      "--filter-pattern",pattern,
      "--metric-transformations",f"metricName={mn},metricNamespace={ns},metricValue={val}"
    ],check=False)
PY
fi

echo "restore completed (best-effort)."
echo "note: security-group exact rollback is intentionally excluded for safety."
