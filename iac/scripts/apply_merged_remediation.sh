#!/usr/bin/env bash
set -euo pipefail

ROOT="${1:-remediation}"
mkdir -p artifacts/apply

apply_category() {
  local c="$1"
  local d="$ROOT/$c"
  local logfile="artifacts/apply/${c}.log"

  [ -d "$d" ] || return 0
  if ! find "$d" -maxdepth 1 -name '*.tf' | grep -q .; then
    echo "skip $c (no tf)" | tee -a "$logfile"
    return 0
  fi

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
provider "aws" {}
TF

  terraform -chdir="$d" init -input=false -no-color | tee -a "$logfile"

  local import_map="$d/import-map.txt"
  if [ -f "$import_map" ]; then
    while IFS= read -r line || [ -n "$line" ]; do
      [ -z "$line" ] && continue
      [[ "$line" == \#* ]] && continue

      addr="$(echo "$line" | cut -d'|' -f1)"
      iid="$(echo "$line" | cut -d'|' -f2)"
      optional="$(echo "$line" | cut -d'|' -f3)"
      cid="$(echo "$line" | cut -d'|' -f4)"

      [ -z "$addr" ] && continue
      [ -z "$iid" ] && continue

      out="$(terraform -chdir="$d" import -input=false -no-color "$addr" "$iid" 2>&1)"
      rc=$?
      if [ $rc -eq 0 ]; then
        echo "imported $addr ($cid)" | tee -a "$logfile"
        continue
      fi

      if echo "$out" | grep -qi "Cannot import non-existent remote object"; then
        if [ "$optional" = "true" ]; then
          echo "optional missing sub-config; continue $addr ($cid)" | tee -a "$logfile"
          continue
        fi
      fi

      echo "import skip/fail $addr ($cid)" | tee -a "$logfile"
      echo "$out" >> "$logfile"
    done < "$import_map"
  fi

  terraform -chdir="$d" plan -input=false -no-color -out=tfplan | tee -a "$logfile"
  terraform -chdir="$d" apply -input=false -auto-approve -no-color tfplan | tee -a "$logfile"

  rm -f "$d/_apply_provider.tf"
}

for c in iam s3 cloudtrail cloudwatch; do
  apply_category "$c"
done

cat artifacts/apply/*.log > artifacts/apply/apply.log || true