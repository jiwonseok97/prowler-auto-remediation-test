#!/usr/bin/env bash
set -euo pipefail

LIMIT_USD="${1:-50}"

START_DATE="$(date -u +"%Y-%m-01")"
END_DATE="$(date -u -d "tomorrow" +"%Y-%m-%d")"

echo "Cost guard window: ${START_DATE} -> ${END_DATE} (MTD)"
echo "Cost guard limit: ${LIMIT_USD} USD"

MTD_COST="$(
  aws ce get-cost-and-usage \
    --time-period "Start=${START_DATE},End=${END_DATE}" \
    --granularity MONTHLY \
    --metrics UnblendedCost \
    --query 'ResultsByTime[0].Total.UnblendedCost.Amount' \
    --output text 2>/tmp/cost_guard_error.log || true
)"

if [[ -z "${MTD_COST}" || "${MTD_COST}" == "None" || "${MTD_COST}" == "null" ]]; then
  echo "ERROR: Failed to read monthly cost from Cost Explorer."
  if [[ -s /tmp/cost_guard_error.log ]]; then
    cat /tmp/cost_guard_error.log
  fi
  echo "Hint: allow ce:GetCostAndUsage for workflow role."
  exit 1
fi

python - "${MTD_COST}" "${LIMIT_USD}" <<'PY'
import sys
from decimal import Decimal

cost = Decimal(sys.argv[1])
limit = Decimal(sys.argv[2])
print(f"Current MTD UnblendedCost: {cost} USD")
if cost > limit:
    raise SystemExit(f"Budget guard tripped: {cost} > {limit} USD")
print("Budget guard passed.")
PY
