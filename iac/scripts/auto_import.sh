#!/usr/bin/env bash
set -euo pipefail

TARGET_DIR="${1:?target terraform dir required}"
LOG_FILE="${2:-/dev/stdout}"

IMPORT_MAP="$TARGET_DIR/import-map.txt"
[ -f "$IMPORT_MAP" ] || exit 0

while IFS= read -r line || [ -n "$line" ]; do
  [ -z "$line" ] && continue
  [[ "$line" == \#* ]] && continue

  addr="$(echo "$line" | cut -d'|' -f1)"
  iid="$(echo "$line" | cut -d'|' -f2)"
  optional="$(echo "$line" | cut -d'|' -f3)"
  cid="$(echo "$line" | cut -d'|' -f4)"

  [ -z "$addr" ] && continue
  [ -z "$iid" ] && continue

  set +e
  out="$(terraform -chdir="$TARGET_DIR" import -input=false -no-color "$addr" "$iid" 2>&1)"
  rc=$?
  set -e

  if [ $rc -eq 0 ]; then
    echo "imported $addr ($cid)" | tee -a "$LOG_FILE"
    continue
  fi

  if echo "$out" | grep -qi "Cannot import non-existent remote object"; then
    if [ "$optional" = "true" ]; then
      echo "optional missing sub-config; allow create $addr ($cid)" | tee -a "$LOG_FILE"
      continue
    fi
  fi

  echo "import failed/skipped $addr ($cid)" | tee -a "$LOG_FILE"
  echo "$out" >> "$LOG_FILE"
done < "$IMPORT_MAP"
