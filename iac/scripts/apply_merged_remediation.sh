#!/usr/bin/env bash
set -euo pipefail

ROOT="${1:-remediation}"
mkdir -p artifacts/apply

for c in iam s3 cloudtrail cloudwatch; do
  d="$ROOT/$c"
  [ -d "$d" ] || continue

  if ! find "$d" -maxdepth 1 -name '*.tf' | grep -q .; then
    echo "skip $c (no tf)" | tee -a artifacts/apply/apply.log
    continue
  fi

  echo "apply category=$c" | tee -a artifacts/apply/apply.log
  terraform -chdir="$d" init -input=false -no-color
  terraform -chdir="$d" plan -input=false -no-color -out=tfplan || true
  terraform -chdir="$d" apply -input=false -auto-approve -no-color tfplan

done