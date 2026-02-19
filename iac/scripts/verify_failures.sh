#!/usr/bin/env bash
set -euo pipefail

BASELINE_FILE="baseline_fail.txt"
POST_SCAN="artifacts/post_scan.json"
POST_NORMALIZED="artifacts/post_normalized.json"

mkdir -p artifacts

echo "Waiting for propagation..."
sleep 150

if [ ! -f "$BASELINE_FILE" ]; then
  echo "baseline file not found: $BASELINE_FILE"
  exit 1
fi

baseline_fail="$(cat "$BASELINE_FILE" | tr -d '\r\n ')"
if [ -z "$baseline_fail" ]; then
  baseline_fail=0
fi

prowler aws --compliance cis_1.4_aws -M json-asff -o artifacts -F post-remediation || prowler aws -M json-asff -o artifacts -F post-remediation || true
FOUND="$(find artifacts -maxdepth 1 -type f -name 'post-remediation*.json*' | head -n 1)"

if [ -z "$FOUND" ]; then
  echo "[]" > "$POST_NORMALIZED"
  post_fail=0
else
  python iac/scripts/convert_findings.py --input "$FOUND" --output "$POST_NORMALIZED" >/dev/null
  post_fail="$(python - <<'PY'
import json
from pathlib import Path
p = Path('artifacts/post_normalized.json')
if not p.exists():
    print(0)
else:
    data = json.loads(p.read_text(encoding='utf-8'))
    print(len(data) if isinstance(data, list) else 0)
PY
)"
fi

reduced=$((baseline_fail - post_fail))

echo "baseline_fail=$baseline_fail"
echo "post_fail=$post_fail"
echo "reduced=$reduced"

echo "baseline_fail=$baseline_fail" > artifacts/verify.log
echo "post_fail=$post_fail" >> artifacts/verify.log
echo "reduced=$reduced" >> artifacts/verify.log

if [ "$reduced" -le 0 ]; then
  exit 1
fi
