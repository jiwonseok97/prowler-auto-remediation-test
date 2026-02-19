#!/usr/bin/env bash
set -euo pipefail

TARGET_DIR="${1:?target terraform dir required}"
LOG_FILE="${2:-/dev/stdout}"
AWS_REGION_FALLBACK="${AWS_REGION:-${AWS_DEFAULT_REGION:-}}"
AWS_ACCOUNT_ID_FALLBACK="${AWS_ACCOUNT_ID:-}"

IMPORT_MAP="$TARGET_DIR/import-map.txt"
[ -f "$IMPORT_MAP" ] || exit 0
declare -A SEEN_ADDRS=()

if [ -z "$AWS_ACCOUNT_ID_FALLBACK" ]; then
  set +e
  AWS_ACCOUNT_ID_FALLBACK="$(aws sts get-caller-identity --query Account --output text 2>/dev/null)"
  set -e
fi

try_import() {
  local addr="$1"
  local iid="$2"
  terraform -chdir="$TARGET_DIR" import -input=false -no-color "$addr" "$iid" 2>&1
}

while IFS= read -r line || [ -n "$line" ]; do
  [ -z "$line" ] && continue
  [[ "$line" == \#* ]] && continue

  addr="$(echo "$line" | cut -d'|' -f1)"
  iid="$(echo "$line" | cut -d'|' -f2)"
  optional="$(echo "$line" | cut -d'|' -f3)"
  cid="$(echo "$line" | cut -d'|' -f4)"

  [ -z "$addr" ] && continue
  [ -z "$iid" ] && continue
  if [ -n "${SEEN_ADDRS[$addr]+x}" ]; then
    echo "skip duplicate import address $addr ($cid)" | tee -a "$LOG_FILE"
    continue
  fi
  SEEN_ADDRS[$addr]=1

  set +e
  out="$(try_import "$addr" "$iid")"
  rc=$?
  set -e

  # aws_cloudtrail import can be sensitive to id format across provider versions.
  if [ $rc -ne 0 ] && [[ "$addr" == aws_cloudtrail.* ]]; then
    retries=()
    if [ -n "$AWS_REGION_FALLBACK" ] && [ -n "$AWS_ACCOUNT_ID_FALLBACK" ] && [[ "$iid" != arn:aws:cloudtrail:* ]]; then
      retries+=("arn:aws:cloudtrail:${AWS_REGION_FALLBACK}:${AWS_ACCOUNT_ID_FALLBACK}:trail/${iid}")
    fi
    if [ -n "$AWS_REGION_FALLBACK" ] && [[ "$iid" != *:* ]]; then
      retries+=("${iid}:${AWS_REGION_FALLBACK}")
    fi
    for alt in "${retries[@]}"; do
      set +e
      out_alt="$(try_import "$addr" "$alt")"
      rc_alt=$?
      set -e
      if [ $rc_alt -eq 0 ]; then
        out="$out_alt"
        rc=0
        iid="$alt"
        break
      fi
    done
  fi

  if [ $rc -eq 0 ]; then
    echo "imported $addr ($cid) with id=$iid" | tee -a "$LOG_FILE"
    continue
  fi

  if echo "$out" | grep -qi "Resource already managed by Terraform"; then
    echo "already managed; skip import $addr ($cid)" | tee -a "$LOG_FILE"
    continue
  fi

  if echo "$out" | grep -qi "Cannot import non-existent remote object"; then
    if [ "$optional" = "true" ]; then
      echo "optional missing sub-config; allow create $addr ($cid)" | tee -a "$LOG_FILE"
      continue
    fi
  fi

  echo "import failed/skipped $addr ($cid)" | tee -a "$LOG_FILE"
  echo "$out" | tee -a "$LOG_FILE"
  echo "$out" >> "$LOG_FILE"
done < "$IMPORT_MAP"
