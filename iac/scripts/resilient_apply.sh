#!/usr/bin/env bash
set -euo pipefail

TF_DIR="${1:-terraform/remediation}"
STATE_DIR="${2:-artifacts}"
mkdir -p "$STATE_DIR"

REGION="${TF_VAR_region:-${AWS_DEFAULT_REGION:-}}"
REGION_ARG=()
if [[ -n "$REGION" ]]; then
  REGION_ARG=(-var "region=${REGION}")
fi

terraform -chdir="$TF_DIR" init -input=false >/dev/null
terraform -chdir="$TF_DIR" plan -out=tfplan -input=false "${REGION_ARG[@]}" >/dev/null
terraform -chdir="$TF_DIR" show -json tfplan > "$STATE_DIR/plan.json"

if jq -e 'any((.resource_changes // [])[]?; any((.change.actions // [])[]?; . == "replace"))' "$STATE_DIR/plan.json" >/dev/null; then
  echo "[BLOCK] replacement detected in remediation plan"
  exit 10
fi

for i in 1 2; do
  terraform -chdir="$TF_DIR" apply -auto-approve -input=false "${REGION_ARG[@]}"
  set +e
  terraform -chdir="$TF_DIR" plan -detailed-exitcode -input=false -out=tfplan-check "${REGION_ARG[@]}" >/dev/null
  PLAN_EXIT=$?
  set -e
  terraform -chdir="$TF_DIR" show -json tfplan-check > "$STATE_DIR/plan-check-$i.json" || true

  if [[ $PLAN_EXIT -eq 0 ]]; then
    echo "[OK] idempotent apply confirmed"
    exit 0
  fi
  if [[ $PLAN_EXIT -eq 1 ]]; then
    echo "[BLOCK] terraform plan failed after apply #$i"
    exit 11
  fi
  echo "[WARN] drift still detected after apply #$i"
done

echo "[BLOCK] drift loop suspected after 2 attempts"
exit 20