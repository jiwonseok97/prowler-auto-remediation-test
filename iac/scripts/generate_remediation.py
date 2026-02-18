#!/usr/bin/env python3
"""Generate remediation Terraform per category using snippets + Bedrock + builders."""

from __future__ import annotations

import argparse
import json
import os
import re
from collections import defaultdict
from pathlib import Path
from typing import Any

from iac.builders.cloudwatch_builder import build_cloudwatch
from iac.builders.network_builder import build_network

try:
    import boto3
except Exception:  # pragma: no cover
    boto3 = None

SUPPORTED = ["iam", "s3", "network-ec2-vpc", "cloudtrail", "cloudwatch"]


def extract_tf(text: str) -> str:
    blocks = re.findall(r"```(?:hcl|terraform)?\s*(.*?)```", text, flags=re.S | re.I)
    if blocks:
        return "\n\n".join(x.strip() for x in blocks if x.strip()) + "\n"
    return text.strip() + "\n"


def call_bedrock(model_id: str, region: str, category: str, findings: list[dict[str, Any]], snippet: str) -> str:
    if boto3 is None:
        raise RuntimeError("boto3 unavailable")

    client = boto3.client("bedrock-runtime", region_name=region)
    prompt = {
        "task": "Generate safe Terraform remediation resources",
        "category": category,
        "constraints": [
            "Output only Terraform/HCL.",
            "No provider/terraform/variable/output blocks.",
            "Use non-destructive resource config.",
            "Use resource names with ai_remed_ prefix.",
        ],
        "findings": findings[:20],
        "snippet": snippet,
    }

    payload = {
        "anthropic_version": "bedrock-2023-05-31",
        "max_tokens": 1400,
        "temperature": 0,
        "messages": [
            {
                "role": "user",
                "content": [{"type": "text", "text": json.dumps(prompt, ensure_ascii=False)}],
            }
        ],
    }

    resp = client.invoke_model(modelId=model_id, contentType="application/json", body=json.dumps(payload))
    body = json.loads(resp["body"].read())
    parts = body.get("content", [])
    text = "\n".join(p.get("text", "") for p in parts if isinstance(p, dict)).strip()
    if not text:
        raise RuntimeError("empty model output")
    return extract_tf(text)


def builder_tf(category: str, findings: list[dict[str, Any]]) -> str:
    if category == "cloudwatch":
        return build_cloudwatch(findings)
    if category == "network-ec2-vpc":
        return build_network(findings)
    return ""


def render_category_file(category: str, run_id: str, snippet: str, ai_tf: str, built_tf: str) -> str:
    # Comment out snippet so placeholder values (REPLACE_*) don't break terraform apply
    snippet_commented = "\n".join(f"# {line}" for line in snippet.strip().splitlines()) if snippet.strip() else ""
    return (
        'terraform {\n'
        '  required_version = ">= 1.5.0"\n'
        '  required_providers {\n'
        '    aws = {\n'
        '      source  = "hashicorp/aws"\n'
        '      version = ">= 5.0"\n'
        '    }\n'
        '  }\n'
        '}\n\n'
        'variable "region" {\n'
        '  type    = string\n'
        '  default = ""\n'
        '}\n\n'
        'provider "aws" {\n'
        '  region = var.region != "" ? var.region : null\n'
        '}\n\n'
        f"# category: {category}\n"
        f"# run_id: {run_id}\n\n"
        f"# === snippet reference (not applied) ===\n"
        f"{snippet_commented}\n\n"
        f"# === ai_generated ===\n{ai_tf.strip()}\n\n"
        f"# === builder_generated ===\n{built_tf.strip()}\n"
    )


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--normalized-findings", default="artifacts/normalized-findings.json")
    parser.add_argument("--snippet-root", default="iac/snippets")
    parser.add_argument("--output-root", default="terraform/remediation")
    parser.add_argument("--run-id", default="manual")
    parser.add_argument("--log", default="artifacts/remediation/summary.log")
    args = parser.parse_args()

    findings = json.loads(Path(args.normalized_findings).read_text(encoding="utf-8"))
    by_cat: dict[str, list[dict[str, Any]]] = defaultdict(list)
    for f in findings:
        c = f.get("category")
        if c in SUPPORTED:
            by_cat[c].append(f)

    model_id = os.getenv("AI_MODEL", "")
    region = os.getenv("AWS_DEFAULT_REGION", "")

    output_root = Path(args.output_root)
    output_root.mkdir(parents=True, exist_ok=True)

    generated = []
    for category in SUPPORTED:
        cat_findings = by_cat.get(category, [])
        if not cat_findings:
            continue

        snippet_path = Path(args.snippet_root) / category / "main.tf"
        snippet = snippet_path.read_text(encoding="utf-8") if snippet_path.exists() else ""

        ai_tf = "# no_ai_output"
        bedrock_ok = False
        error = ""

        if model_id and region:
            try:
                ai_tf = call_bedrock(model_id, region, category, cat_findings, snippet)
                bedrock_ok = True
            except Exception as e:
                error = str(e)

        built_tf = builder_tf(category, cat_findings)

        cat_dir = output_root / category
        cat_dir.mkdir(parents=True, exist_ok=True)
        (cat_dir / "main.tf").write_text(
            render_category_file(category, args.run_id, snippet, ai_tf, built_tf),
            encoding="utf-8",
        )
        (cat_dir / "imports.sh").write_text("#!/usr/bin/env bash\nset -euo pipefail\n", encoding="utf-8")

        generated.append(
            {
                "category": category,
                "path": str((cat_dir / "main.tf")).replace('\\', '/'),
                "findings": len(cat_findings),
                "bedrock_ok": bedrock_ok,
                "error": error,
            }
        )

    manifest = {
        "run_id": args.run_id,
        "baseline_fail_count": len(findings),
        "categories": generated,
        "unsupported_examples": ["fms", "organizations", "root MFA"],
    }
    (output_root / "manifest.json").write_text(json.dumps(manifest, indent=2), encoding="utf-8")

    log_path = Path(args.log)
    log_path.parent.mkdir(parents=True, exist_ok=True)
    log_path.write_text(
        "\n".join(
            [
                f"baseline_fail_count={len(findings)}",
                f"generated_categories={','.join(x['category'] for x in generated) if generated else 'none'}",
                f"model={model_id or 'none'}",
            ]
        ) + "\n",
        encoding="utf-8",
    )

    print(json.dumps(manifest))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
