#!/usr/bin/env bash
set -euo pipefail

ROOT="${1:-remediation}"
mkdir -p artifacts/validation

for c in iam s3 network-ec2-vpc cloudtrail cloudwatch; do
  d="$ROOT/$c"
  [ -d "$d" ] || continue

  if ! find "$d" -maxdepth 1 -name '*.tf' | grep -q .; then
    echo "skip $c (no tf files)"
    continue
  fi

  terraform -chdir="$d" fmt -recursive

  cat > "$d/_validate_provider.tf" <<'TF'
terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = ">= 5.0"
    }
  }
}
provider "aws" {
  region = "us-east-1"
}
TF

  terraform -chdir="$d" init -backend=false -input=false -no-color
  terraform -chdir="$d" validate -no-color
  rm -f "$d/_validate_provider.tf"
done
