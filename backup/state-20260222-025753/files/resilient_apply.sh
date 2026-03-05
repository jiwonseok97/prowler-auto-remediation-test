#!/usr/bin/env bash
set -euo pipefail

ROOT="${1:-remediation}"
ART_DIR="${2:-artifacts}"
ONLY_CATEGORIES="${3:-}"
LOG_DIR="$ART_DIR/apply"
mkdir -p "$LOG_DIR"

attempted=0
succeeded=0
failed_categories=""

apply_category() {
  local c="$1"
  local d="$ROOT/$c"
  local logfile="$LOG_DIR/${c}.log"

  [ -d "$d" ] || return 0
  if ! find "$d" -maxdepth 1 -name '*.tf' | grep -q .; then
    echo "skip $c (no tf files)" | tee -a "$logfile"
    return 0
  fi

  attempted=$((attempted + 1))
  echo "apply category=$c" | tee -a "$logfile"

  apply_dir() {
    local workdir="$1"
    local provider_region="$2"
    local label="$3"

    cat > "$workdir/_apply_provider.tf" <<'TF'
terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = ">= 5.0"
    }
    null = {
      source = "hashicorp/null"
      version = ">= 3.0"
    }
  }
}
provider "aws" {
  region = "ap-northeast-2"
}
TF

    if [ -n "$provider_region" ]; then
      sed -i "s/ap-northeast-2/${provider_region}/g" "$workdir/_apply_provider.tf"
    elif [ -n "${AWS_REGION:-}" ]; then
      sed -i "s/ap-northeast-2/${AWS_REGION}/g" "$workdir/_apply_provider.tf"
    fi

    if ! terraform -chdir="$workdir" init -input=false -no-color | tee -a "$logfile"; then
      echo "init failed $c ($label)" | tee -a "$logfile"
      rm -f "$workdir/_apply_provider.tf"
      return 1
    fi

    bash iac/scripts/auto_import.sh "$workdir" "$logfile" || true

    if ! terraform -chdir="$workdir" plan -input=false -no-color -out=tfplan | tee -a "$logfile"; then
      echo "plan failed $c ($label)" | tee -a "$logfile"
      rm -f "$workdir/_apply_provider.tf"
      return 1
    fi

    if ! terraform -chdir="$workdir" apply -input=false -auto-approve -no-color tfplan | tee -a "$logfile"; then
      echo "apply failed $c ($label)" | tee -a "$logfile"
      rm -f "$workdir/_apply_provider.tf"
      return 1
    fi

    rm -f "$workdir/_apply_provider.tf"
    return 0
  }

  local regions=()
  while IFS= read -r f; do
    bn="$(basename "$f")"
    if [[ "$bn" =~ _([a-z]{2}(?:_[a-z0-9]+)+_[0-9])\.tf$ ]]; then
      r="${BASH_REMATCH[1]//_/-}"
      if [[ ! " ${regions[*]} " =~ " ${r} " ]]; then
        regions+=("$r")
      fi
    fi
  done < <(find "$d" -maxdepth 1 -name '*.tf' | sort)

  local category_failed=0
  local staged_any=0
  if [ "${#regions[@]}" -gt 0 ]; then
    for r in "${regions[@]}"; do
      staged="$d/.apply-${r}"
      rm -rf "$staged"
      mkdir -p "$staged"
      us="${r//-/_}"
      while IFS= read -r f; do
        bn="$(basename "$f")"
        if [[ "$bn" == *"_${us}.tf" ]]; then
          cp "$f" "$staged/$bn"
        fi
      done < <(find "$d" -maxdepth 1 -name '*.tf' | sort)
      if [ -f "$d/import-map.txt" ]; then
        cp "$d/import-map.txt" "$staged/import-map.txt"
      fi
      if ! find "$staged" -maxdepth 1 -name '*.tf' | grep -q .; then
        rm -rf "$staged"
        continue
      fi
      staged_any=1
      echo "apply category=$c region=$r" | tee -a "$logfile"
      if ! apply_dir "$staged" "$r" "region=$r"; then
        category_failed=1
      fi
      rm -rf "$staged"
    done
  fi

  global_stage="$d/.apply-global"
  rm -rf "$global_stage"
  mkdir -p "$global_stage"
  while IFS= read -r f; do
    bn="$(basename "$f")"
    if [[ ! "$bn" =~ _([a-z]{2}(?:_[a-z0-9]+)+_[0-9])\.tf$ ]]; then
      cp "$f" "$global_stage/$bn"
    fi
  done < <(find "$d" -maxdepth 1 -name '*.tf' | sort)
  if [ -f "$d/import-map.txt" ]; then
    cp "$d/import-map.txt" "$global_stage/import-map.txt"
  fi
  if find "$global_stage" -maxdepth 1 -name '*.tf' | grep -q .; then
    staged_any=1
    echo "apply category=$c region=global" | tee -a "$logfile"
    if ! apply_dir "$global_stage" "${AWS_REGION:-${AWS_DEFAULT_REGION:-}}" "region=global"; then
      category_failed=1
    fi
  fi
  rm -rf "$global_stage"

  if [ "$staged_any" -eq 0 ]; then
    echo "skip $c (no staged tf files)" | tee -a "$logfile"
    return 0
  fi
  if [ "$category_failed" -eq 0 ]; then
    succeeded=$((succeeded + 1))
  else
    failed_categories="$failed_categories $c"
  fi
}

if [ -n "$ONLY_CATEGORIES" ]; then
  IFS=',' read -r -a cats <<< "$ONLY_CATEGORIES"
else
  cats=("iam" "s3" "network-ec2-vpc" "cloudtrail" "cloudwatch")
fi

for c in "${cats[@]}"; do
  [ -z "$c" ] && continue
  apply_category "$c"
done

cat "$LOG_DIR"/*.log > "$LOG_DIR/apply.log" || true

echo "attempted=$attempted" | tee -a "$LOG_DIR/apply.log"
echo "succeeded=$succeeded" | tee -a "$LOG_DIR/apply.log"
echo "failed_categories=${failed_categories:-none}" | tee -a "$LOG_DIR/apply.log"

if [ "$attempted" -gt 0 ] && [ "$succeeded" -eq 0 ]; then
  exit 1
fi
