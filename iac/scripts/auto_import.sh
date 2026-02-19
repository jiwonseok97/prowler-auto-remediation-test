#!/usr/bin/env bash
set -uo pipefail

if [ "$#" -lt 2 ]; then
  echo "usage: $0 <category_dir> <import_map>"
  exit 0
fi

CATEGORY_DIR="$1"
IMPORT_MAP="$2"

if [ ! -d "$CATEGORY_DIR" ]; then
  echo "category dir not found: $CATEGORY_DIR"
  exit 0
fi

if [ ! -f "$IMPORT_MAP" ]; then
  echo "import map not found: $IMPORT_MAP"
  exit 0
fi

pushd "$CATEGORY_DIR" >/dev/null || exit 0
terraform init -input=false -no-color >/dev/null 2>&1 || terraform init -input=false -no-color || true

while IFS= read -r line || [ -n "$line" ]; do
  row="$(echo "$line" | sed 's/^ *//;s/ *$//')"
  [ -z "$row" ] && continue
  [[ "$row" == \#* ]] && continue

  address="$(echo "$row" | cut -d'|' -f1)"
  import_id="$(echo "$row" | cut -d'|' -f2)"
  arn="$(echo "$row" | cut -d'|' -f3)"
  check_id="$(echo "$row" | cut -d'|' -f4)"
  optional_create="$(echo "$row" | cut -d'|' -f5)"

  if [ -z "$address" ] || [ -z "$import_id" ]; then
    echo "SKIP invalid import row: $row"
    continue
  fi

  echo "IMPORT check_id=${check_id:-unknown} address=$address id=$import_id arn=${arn:-n/a}"
  out="$(terraform import -input=false -no-color "$address" "$import_id" 2>&1)"
  rc=$?

  if [ $rc -eq 0 ]; then
    echo "IMPORTED $address"
    continue
  fi

  if echo "$out" | grep -qi "Cannot import non-existent remote object"; then
    if [ "$optional_create" = "true" ]; then
      echo "SKIP optional non-existent sub-config for $address (create during apply allowed)"
      continue
    fi
  fi

  echo "SKIP import failed for $address"
  echo "$out"

done < "$IMPORT_MAP"

popd >/dev/null || true
exit 0
