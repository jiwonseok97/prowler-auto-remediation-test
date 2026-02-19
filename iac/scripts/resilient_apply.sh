#!/usr/bin/env bash
set -uo pipefail

apply_one() {
  local category_dir="$1"
  local state_dir="$2"

  if [ ! -d "$category_dir" ]; then
    echo "SKIP missing category dir: $category_dir"
    return 0
  fi

  mkdir -p "$state_dir"
  pushd "$category_dir" >/dev/null || return 0

  local has_tf
  has_tf=$(find . -maxdepth 1 -type f -name '*.tf' | wc -l)
  if [ "$has_tf" -eq 0 ]; then
    echo "SKIP no tf files in $category_dir"
    popd >/dev/null || true
    return 0
  fi

  terraform init -input=false -no-color >/dev/null 2>&1 || terraform init -input=false -no-color || true

  terraform apply -auto-approve -input=false -no-color \
    -state="$PWD/../../$state_dir/terraform.tfstate"
  rc=$?

  if [ $rc -ne 0 ]; then
    echo "FAIL apply: $category_dir"
  else
    echo "OK apply: $category_dir"
  fi

  popd >/dev/null || true
  return 0
}

if [ "$#" -ge 2 ]; then
  apply_one "$1" "$2"
  exit 0
fi

PLAN_DIR="terraform/remediation"
for category in iam s3 network-ec2-vpc cloudtrail cloudwatch; do
  apply_one "$PLAN_DIR/$category" "artifacts/$category"
done

exit 0
