#!/usr/bin/env bash
set -euo pipefail

ROOT="${1:-remediation}"
ART_DIR="${2:-artifacts}"
ONLY_CATEGORIES="${3:-}"
LOG_DIR="$ART_DIR/apply"
mkdir -p "$LOG_DIR"

attempted=0
succeeded=0
failed_categories=""

apply_category() {
  local c="$1"
  local d="$ROOT/$c"
  local logfile="$LOG_DIR/${c}.log"

  [ -d "$d" ] || return 0
  if ! find "$d" -maxdepth 1 -name '*.tf' | grep -q .; then
    echo "skip $c (no tf files)" | tee -a "$logfile"
    return 0
  fi

  attempted=$((attempted + 1))
  echo "apply category=$c" | tee -a "$logfile"

  cat > "$d/_apply_provider.tf" <<'TF'
terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = ">= 5.0"
    }
  }
}
provider "aws" {
  region = "ap-northeast-2"
}
TF

  if [ -n "${AWS_REGION:-}" ]; then
    sed -i "s/ap-northeast-2/${AWS_REGION}/g" "$d/_apply_provider.tf"
  fi

  if ! terraform -chdir="$d" init -input=false -no-color | tee -a "$logfile"; then
    echo "init failed $c" | tee -a "$logfile"
    failed_categories="$failed_categories $c"
    rm -f "$d/_apply_provider.tf"
    return 0
  fi

  bash iac/scripts/auto_import.sh "$d" "$logfile" || true

  if ! terraform -chdir="$d" plan -input=false -no-color -out=tfplan | tee -a "$logfile"; then
    echo "plan failed $c" | tee -a "$logfile"
    failed_categories="$failed_categories $c"
    rm -f "$d/_apply_provider.tf"
    return 0
  fi

  if terraform -chdir="$d" apply -input=false -auto-approve -no-color tfplan | tee -a "$logfile"; then
    succeeded=$((succeeded + 1))
  else
    echo "apply failed $c" | tee -a "$logfile"
    failed_categories="$failed_categories $c"
  fi

  rm -f "$d/_apply_provider.tf"
}

if [ -n "$ONLY_CATEGORIES" ]; then
  IFS=',' read -r -a cats <<< "$ONLY_CATEGORIES"
else
  cats=("iam" "s3" "network-ec2-vpc" "cloudtrail" "cloudwatch")
fi

for c in "${cats[@]}"; do
  [ -z "$c" ] && continue
  apply_category "$c"
done

cat "$LOG_DIR"/*.log > "$LOG_DIR/apply.log" || true

echo "attempted=$attempted" | tee -a "$LOG_DIR/apply.log"
echo "succeeded=$succeeded" | tee -a "$LOG_DIR/apply.log"
echo "failed_categories=${failed_categories:-none}" | tee -a "$LOG_DIR/apply.log"

if [ "$attempted" -gt 0 ] && [ "$succeeded" -eq 0 ]; then
  exit 1
fi
