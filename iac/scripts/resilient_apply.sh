#!/usr/bin/env bash
set -euo pipefail

TF_DIR="${1:-terraform/remediation}"
STATE_DIR="${2:-artifacts}"
mkdir -p "$STATE_DIR"

terraform -chdir="$TF_DIR" init -input=false >/dev/null
terraform -chdir="$TF_DIR" plan -out=tfplan -input=false >/dev/null
terraform -chdir="$TF_DIR" show -json tfplan > "$STATE_DIR/plan.json"

if grep -q '"replace"' "$STATE_DIR/plan.json"; then
  echo "[BLOCK] replacement detected in remediation plan"
  exit 10
fi

for i in 1 2; do
  terraform -chdir="$TF_DIR" apply -auto-approve -input=false
  terraform -chdir="$TF_DIR" plan -out=tfplan-check -input=false >/dev/null
  terraform -chdir="$TF_DIR" show -json tfplan-check > "$STATE_DIR/plan-check-$i.json"
  if grep -q '"resource_changes":\[\]' "$STATE_DIR/plan-check-$i.json"; then
    echo "[OK] idempotent apply confirmed"
    exit 0
  fi
  echo "[WARN] drift still detected after apply #$i"
done

echo "[BLOCK] drift loop suspected after 2 attempts"
exit 20
