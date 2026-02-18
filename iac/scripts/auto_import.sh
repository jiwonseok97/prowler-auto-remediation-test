#!/usr/bin/env bash
set -euo pipefail

TF_DIR="${1:-terraform/remediation}"
IMPORT_MAP="${2:-artifacts/import-map.txt}"

if [[ ! -f "$IMPORT_MAP" ]]; then
  echo "[INFO] no import map found, skipping import"
  exit 0
fi

while IFS='|' read -r addr rid; do
  [[ -z "$addr" || -z "$rid" ]] && continue
  echo "[INFO] terraform import $addr $rid"
  if ! terraform -chdir="$TF_DIR" import "$addr" "$rid"; then
    echo "[BLOCK] import failed for $addr"
    exit 30
  fi
done < "$IMPORT_MAP"

echo "[OK] imports completed"
