#!/usr/bin/env bash
set -euo pipefail

ROOT="${1:-remediation}"
ART_DIR="${2:-artifacts}"

bash iac/scripts/resilient_apply.sh "$ROOT" "$ART_DIR"
