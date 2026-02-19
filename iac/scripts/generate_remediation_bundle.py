#!/usr/bin/env python3
"""Generate remediation terraform files from prioritized findings."""
import argparse
import hashlib
import json
import os
import re
import shutil
import subprocess
import tempfile
from datetime import datetime, timezone
from pathlib import Path
from typing import Any, Dict, List, Optional, Tuple

import boto3
import yaml

CATEGORIES = ["iam", "s3", "network-ec2-vpc", "cloudtrail", "cloudwatch"]
OPTIONAL_IMPORT_TYPES = {
    "aws_s3_bucket_public_access_block",
    "aws_s3_bucket_server_side_encryption_configuration",
    "aws_s3_account_public_access_block",
    "aws_s3_bucket_policy",
    "aws_s3_bucket_logging",
    "aws_config_configuration_recorder",
    "aws_config_delivery_channel",
    "aws_config_configuration_recorder_status",
    "aws_cloudwatch_log_group",
    "aws_network_acl_rule",
}
USE_BEDROCK_FALLBACK = os.getenv("BEDROCK_FALLBACK", "").strip().lower() in {"1", "true", "yes"}


def safe_id(x: str) -> str:
    return re.sub(r"[^a-zA-Z0-9_]+", "_", x).strip("_").lower()


def load_map(path: Path) -> Dict[str, Any]:
    doc = yaml.safe_load(path.read_text(encoding="utf-8")) or {}
    checks = doc.get("checks", {}) if isinstance(doc, dict) else {}
    return checks if isinstance(checks, dict) else {}


def category_of(service: str, check_id: str) -> str:
    s = (service or "").lower()
    c = (check_id or "").lower()
    if c.startswith("prowler-"):
        c = c.split("prowler-", 1)[1]
    # Prefer check-id prefix over service field because some findings have broad/mismatched service labels.
    if c.startswith("iam_"):
        return "iam"
    if c.startswith("accessanalyzer_"):
        return "iam"
    if c.startswith("config_"):
        return "iam"
    if c.startswith("kms_"):
        return "iam"
    if c.startswith("s3_"):
        return "s3"
    if c.startswith("ec2_") or c.startswith("vpc_"):
        return "network-ec2-vpc"
    if c.startswith("cloudtrail_"):
        return "cloudtrail"
    if c.startswith("cloudwatch_") or c.startswith("logs_"):
        return "cloudwatch"
    if s == "iam":
        return "iam"
    if s == "s3":
        return "s3"
    if s in {"ec2", "vpc"}:
        return "network-ec2-vpc"
    if s == "cloudtrail":
        return "cloudtrail"
    if s in {"cloudwatch", "logs"}:
        return "cloudwatch"
    return ""


def render_with_bedrock(model_id: str, prompt: str) -> str:
    client = boto3.client("bedrock-runtime")
    body = {
        "anthropic_version": "bedrock-2023-05-31",
        "max_tokens": 1200,
        "temperature": 0,
        "messages": [{"role": "user", "content": prompt}],
    }
    resp = client.invoke_model(modelId=model_id, body=json.dumps(body))
    payload = json.loads(resp["body"].read())
    text = "".join(x.get("text", "") for x in payload.get("content", []))
    return text.strip()


def strip_code_fence(s: str) -> str:
    t = s.strip()
    if t.startswith("```"):
        t = t.split("\n", 1)[1] if "\n" in t else ""
        if t.endswith("```"):
            t = t[:-3]
    return t.strip()


def extract_bucket(arn: str) -> str:
    if arn.startswith("arn:aws:s3:::"):
        return arn.split("arn:aws:s3:::", 1)[1].split("/")[0]
    return ""


def extract_trail_name(arn: str) -> str:
    if ":trail/" in arn:
        return arn.split(":trail/", 1)[1]
    return ""


def extract_log_group(arn: str) -> str:
    if ":log-group:" in arn:
        return arn.split(":log-group:", 1)[1].split(":", 1)[0]
    return ""


def extract_vpc_id(arn: str) -> str:
    if ":vpc/" in arn:
        return arn.split(":vpc/", 1)[1]
    return ""


def extract_nacl_id(arn: str) -> str:
    if ":network-acl/" in arn:
        return arn.split(":network-acl/", 1)[1]
    return ""


def extract_kms_key_id(arn: str) -> str:
    if ":key/" in arn:
        return arn.split(":key/", 1)[1]
    return ""


def materialize_vars(tf_code: str, finding: Dict[str, Any], account_id: str, region: str) -> str:
    arn = finding.get("resource_arn", "")
    bucket = extract_bucket(arn)
    trail = extract_trail_name(arn)
    log_group = extract_log_group(arn)
    kms = f"arn:aws:kms:{region}:{account_id}:alias/aws/logs"

    out = tf_code
    if bucket:
        out = out.replace("var.bucket_name", f'"{bucket}"')
    if trail:
        out = out.replace("var.cloudtrail_name", f'"{trail}"')
    if log_group:
        out = out.replace("var.log_group_name", f'"{log_group}"')
    out = out.replace("var.kms_key_arn", f'"{kms}"')
    out = out.replace("var.account_id", f'"{account_id}"')
    out = out.replace("var.region", f'"{region}"')
    out = re.sub(r'variable\s+"[^"]+"\s*\{[^{}]*\}\s*', "", out, flags=re.DOTALL)
    return out


def get_cloudtrail_detail(region: str, trail_name: str) -> Dict[str, Any]:
    if not trail_name:
        return {}
    try:
        ct = boto3.client("cloudtrail", region_name=region)
        resp = ct.describe_trails(trailNameList=[trail_name], includeShadowTrails=False)
        trails = resp.get("trailList", []) or []
        return trails[0] if trails else {}
    except Exception:
        return {}


def pick_default_trail(region: str) -> Dict[str, Any]:
    try:
        ct = boto3.client("cloudtrail", region_name=region)
        resp = ct.describe_trails(includeShadowTrails=False)
        trails = resp.get("trailList", []) or []
        if trails:
            return trails[0]
    except Exception:
        return {}
    return {}


def pick_default_cloudtrail_log_group(region: str, account_id: str) -> str:
    trail = pick_default_trail(region)
    arn = str(trail.get("CloudWatchLogsLogGroupArn", "") or "")
    lg = extract_log_group(arn)
    if lg:
        return lg
    return f"/aws/cloudtrail/{account_id}"


def pick_default_log_bucket(account_id: str) -> str:
    try:
        s3 = boto3.client("s3")
        resp = s3.list_buckets()
        buckets = [b.get("Name", "") for b in resp.get("Buckets", [])]
        preferred_prefixes = [
            f"aws-cloudtrail-logs-{account_id}",
            f"prowler-terraform-state-{account_id}",
            f"prowler-dashboard-{account_id}",
        ]
        for pfx in preferred_prefixes:
            for b in buckets:
                if b.startswith(pfx):
                    return b
        return buckets[0] if buckets else ""
    except Exception:
        return ""


def extract_sg_id(arn: str) -> str:
    if ":security-group/" in arn:
        return arn.split(":security-group/", 1)[1]
    return ""


def lookup_vpc_for_sg(arn: str, region: str) -> str:
    sg_id = extract_sg_id(arn)
    if not sg_id:
        return ""
    try:
        ec2 = boto3.client("ec2", region_name=region)
        resp = ec2.describe_security_groups(GroupIds=[sg_id])
        for sg in resp.get("SecurityGroups", []):
            vpc_id = sg.get("VpcId", "")
            if vpc_id:
                return vpc_id
    except Exception:
        return ""
    return ""


def pick_available_nacl_rule_number(nacl_id: str, region: str, preferred: int) -> int:
    if not nacl_id:
        return preferred
    try:
        ec2 = boto3.client("ec2", region_name=region)
        resp = ec2.describe_network_acls(NetworkAclIds=[nacl_id])
        used = set()
        for acl in resp.get("NetworkAcls", []) or []:
            for entry in acl.get("Entries", []) or []:
                if bool(entry.get("Egress", False)):
                    continue
                num = entry.get("RuleNumber")
                if isinstance(num, int):
                    used.add(num)
        if preferred not in used:
            return preferred
        for n in range(1, 32766):
            if n not in used:
                return n
    except Exception:
        pass
    return preferred


def build_nacl_restrict_ingress_tf(finding: Dict[str, Any], region: str) -> str:
    cid = str(finding.get("check_id", "")).lower()
    cid = cid.split("prowler-", 1)[1] if cid.startswith("prowler-") else cid
    nacl_id = extract_nacl_id(finding.get("resource_arn", ""))
    if not nacl_id:
        return ""

    proto = "-1"
    from_port = ""
    to_port = ""
    preferred = 50
    if "tcp_port_22" in cid:
        proto = "6"
        from_port = "22"
        to_port = "22"
        preferred = 52
    elif "tcp_port_3389" in cid:
        proto = "6"
        from_port = "3389"
        to_port = "3389"
        preferred = 53
    elif "any_port" in cid:
        proto = "-1"
        preferred = 51
    else:
        return ""

    rule_number = pick_available_nacl_rule_number(nacl_id, region, preferred)
    finding["_nacl_rule_import_id"] = f"{nacl_id}:false:{rule_number}:{proto}:0.0.0.0/0"

    lines = [
        'resource "aws_network_acl_rule" "fix_network_acl_ingress_deny" {',
        f'  network_acl_id = "{nacl_id}"',
        "  egress         = false",
        f"  rule_number    = {rule_number}",
        f'  protocol       = "{proto}"',
        '  rule_action    = "deny"',
        '  cidr_block     = "0.0.0.0/0"',
    ]
    if from_port and to_port:
        lines.append(f"  from_port      = {from_port}")
        lines.append(f"  to_port        = {to_port}")
    lines.extend(
        [
            "  lifecycle {",
            "    ignore_changes = [icmp_type, icmp_code]",
            "  }",
            "}",
            "",
        ]
    )
    return "\n".join(lines)


def uniquify_resource_names(tf_code: str, suffix: str) -> Tuple[str, List[Tuple[str, str]]]:
    mapping: List[Tuple[str, str]] = []
    tag = hashlib.sha1(suffix.encode("utf-8")).hexdigest()[:10]
    rename_refs: List[Tuple[str, str]] = []

    def repl(m: re.Match) -> str:
        rtype = m.group(1)
        rname = m.group(2)
        new_name = f"{rname}_{tag}"
        mapping.append((f"{rtype}.{new_name}", rtype))
        rename_refs.append((f"{rtype}.{rname}", f"{rtype}.{new_name}"))
        return f'resource "{rtype}" "{new_name}" {{'

    out = re.sub(r'resource\s+"([^"]+)"\s+"([^"]+)"\s*\{', repl, tf_code)
    for old_ref, new_ref in rename_refs:
        out = re.sub(rf"\b{re.escape(old_ref)}\b", new_ref, out)
    return out, mapping


def infer_template_by_rule(check_id: str, category: str) -> Optional[str]:
    c = check_id.lower()
    if c.startswith("prowler-"):
        c = c.split("prowler-", 1)[1]
    if category == "s3" and "secure_transport" in c:
        return None
    if category == "iam" and "password" in c and "policy" in c:
        return "iac/snippets/iam/fix-iam_password_policy_strong.tf"
    if category == "s3" and ("public" in c or "acl" in c or "policy" in c):
        if "account_level_public_access" in c:
            return "iac/snippets/s3/fix-s3_account_public_access_block.tf"
        return "iac/snippets/s3/fix-s3_bucket_public_access_block.tf"
    if category == "s3" and ("encrypt" in c or "encryption" in c):
        return "iac/snippets/s3/fix-s3_bucket_default_encryption.tf"
    if category == "cloudtrail" and ("log_file_validation" in c or "validation" in c):
        return "iac/snippets/cloudtrail/fix-cloudtrail_log_file_validation_enabled.tf"
    if category == "cloudtrail" and ("kms_encryption" in c or "kms" in c):
        return "iac/snippets/cloudtrail/fix-cloudtrail_kms_encryption_enabled.tf"
    if category == "network-ec2-vpc" and "securitygroup_default_restrict_traffic" in c:
        return "iac/snippets/network-ec2-vpc/fix-ec2_securitygroup_default_restrict_traffic.tf"
    if category == "cloudwatch" and ("kms" in c or "encrypt" in c or "encryption" in c):
        return "iac/snippets/cloudwatch/fix-cloudwatch_log_group_encrypted.tf"
    return None


def import_id_for_type(resource_type: str, finding: Dict[str, Any]) -> str:
    arn = finding.get("resource_arn", "")
    if resource_type in {
        "aws_s3_bucket_public_access_block",
        "aws_s3_bucket_server_side_encryption_configuration",
        "aws_s3_bucket_policy",
    }:
        return finding.get("_trail_bucket", "") or finding.get("_config_bucket", "") or extract_bucket(arn)
    if resource_type == "aws_cloudtrail":
        return finding.get("_trail_name", "") or extract_trail_name(arn)
    if resource_type == "aws_cloudwatch_log_group":
        return finding.get("_log_group_name", "") or extract_log_group(arn)
    if resource_type == "aws_iam_account_password_policy":
        return finding.get("account_id", "")
    if resource_type == "aws_s3_account_public_access_block":
        return finding.get("account_id", "")
    if resource_type == "aws_default_security_group":
        return finding.get("_vpc_id", "")
    if resource_type == "aws_kms_key":
        return extract_kms_key_id(arn) or arn
    if resource_type == "aws_accessanalyzer_analyzer":
        return finding.get("_analyzer_name", "")
    if resource_type == "aws_s3_bucket_logging":
        return finding.get("_trail_bucket", "") or finding.get("_source_bucket", "") or extract_bucket(arn)
    if resource_type in {"aws_config_configuration_recorder", "aws_config_configuration_recorder_status"}:
        return finding.get("_config_recorder_name", "")
    if resource_type == "aws_config_delivery_channel":
        return finding.get("_config_delivery_channel_name", "")
    if resource_type == "aws_network_acl_rule":
        return finding.get("_nacl_rule_import_id", "")
    return ""


def validate_tf_snippet(tf_code: str) -> bool:
    terraform_bin = shutil.which("terraform")
    if not terraform_bin:
        return True

    provider_stub = """
terraform {
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
""".strip()

    with tempfile.TemporaryDirectory() as td:
        work = Path(td)
        (work / "main.tf").write_text(tf_code.rstrip() + "\n", encoding="utf-8")
        (work / "_provider.tf").write_text(provider_stub + "\n", encoding="utf-8")

        init = subprocess.run(
            [terraform_bin, f"-chdir={work}", "init", "-backend=false", "-input=false", "-no-color"],
            capture_output=True,
            text=True,
        )
        if init.returncode != 0:
            return False

        validate = subprocess.run(
            [terraform_bin, f"-chdir={work}", "validate", "-no-color"],
            capture_output=True,
            text=True,
        )
        return validate.returncode == 0


def check_priority(check_id: str) -> int:
    c = (check_id or "").lower()
    if c.startswith("prowler-"):
        c = c.split("prowler-", 1)[1]
    if c == "cloudtrail_kms_encryption_enabled":
        return 100
    if c == "cloudtrail_log_file_validation_enabled":
        return 90
    if c in {"cloudtrail_s3_dataevents_read_enabled", "cloudtrail_s3_dataevents_write_enabled"}:
        return 80
    if c == "s3_bucket_secure_transport_policy":
        return 70
    if c == "vpc_flow_logs_enabled":
        return 85
    if "networkacl_allow_ingress_any_port" in c:
        return 88
    if "networkacl_allow_ingress_tcp_port_22" in c or "networkacl_allow_ingress_tcp_port_3389" in c:
        return 87
    if c.startswith("cloudwatch_log_metric_filter_") or c.startswith("cloudwatch_changes_to_"):
        return 75
    return 10


def build_secure_transport_policy_tf(finding: Dict[str, Any]) -> str:
    bucket = extract_bucket(finding.get("resource_arn", ""))
    if not bucket:
        return ""

    policy_doc: Dict[str, Any] = {"Version": "2012-10-17", "Statement": []}
    try:
        s3 = boto3.client("s3")
        resp = s3.get_bucket_policy(Bucket=bucket)
        raw = resp.get("Policy", "")
        if raw:
            loaded = json.loads(raw)
            if isinstance(loaded, dict):
                policy_doc = loaded
    except Exception:
        pass

    stmts = policy_doc.get("Statement", [])
    if not isinstance(stmts, list):
        stmts = [stmts] if stmts else []

    wanted_sid = "DenyInsecureTransport"
    already = False
    for s in stmts:
        if not isinstance(s, dict):
            continue
        if s.get("Sid") == wanted_sid:
            already = True
            break
        cond = s.get("Condition", {})
        bool_cond = cond.get("Bool", {}) if isinstance(cond, dict) else {}
        if isinstance(bool_cond, dict) and str(bool_cond.get("aws:SecureTransport", "")).lower() == "false":
            already = True
            break

    if not already:
        stmts.append(
            {
                "Sid": wanted_sid,
                "Effect": "Deny",
                "Principal": "*",
                "Action": "s3:*",
                "Resource": [f"arn:aws:s3:::{bucket}", f"arn:aws:s3:::{bucket}/*"],
                "Condition": {"Bool": {"aws:SecureTransport": "false"}},
            }
        )
    policy_doc["Statement"] = stmts
    policy_json = json.dumps(policy_doc, indent=2)
    return (
        'resource "aws_s3_bucket_policy" "fix_s3_secure_transport" {\n'
        f'  bucket = "{bucket}"\n'
        "  policy = <<POLICY\n"
        f"{policy_json}\n"
        "POLICY\n"
        "}\n"
    )


def build_vpc_flow_logs_tf(finding: Dict[str, Any], account_id: str) -> str:
    vpc_id = extract_vpc_id(finding.get("resource_arn", ""))
    if not vpc_id:
        return ""
    bucket = pick_default_log_bucket(account_id)
    if not bucket:
        return ""
    return (
        'resource "aws_flow_log" "fix_vpc_flow_logs" {\n'
        f'  vpc_id               = "{vpc_id}"\n'
        '  traffic_type         = "ALL"\n'
        '  log_destination_type = "s3"\n'
        f'  log_destination      = "arn:aws:s3:::{bucket}"\n'
        "}\n"
    )


def build_access_analyzer_tf(finding: Dict[str, Any], region: str, account_id: str) -> str:
    name = ""
    try:
        aa = boto3.client("accessanalyzer", region_name=region)
        resp = aa.list_analyzers(type="ACCOUNT")
        analyzers = resp.get("analyzers", []) or []
        if analyzers:
            name = str(analyzers[0].get("name", ""))
    except Exception as exc:
        msg = str(exc).lower()
        # If runner role cannot read/create access analyzer, skip safely.
        if "accessdenied" in msg or "not authorized" in msg:
            return ""
        name = ""
    if not name:
        name = f"account-analyzer-{account_id}-{region}".lower()
    finding["_analyzer_name"] = name
    return (
        'resource "aws_accessanalyzer_analyzer" "fix_accessanalyzer" {\n'
        f'  analyzer_name = "{name}"\n'
        '  type          = "ACCOUNT"\n'
        "}\n"
    )


def build_config_recorder_tf(finding: Dict[str, Any], region: str, account_id: str) -> str:
    recorder_name = ""
    role_arn = ""
    channel_name = ""
    bucket_name = ""
    try:
        cfg = boto3.client("config", region_name=region)
        rec = cfg.describe_configuration_recorders().get("ConfigurationRecorders", []) or []
        if rec:
            recorder_name = str(rec[0].get("name", ""))
            role_arn = str(rec[0].get("roleARN", ""))
        ch = cfg.describe_delivery_channels().get("DeliveryChannels", []) or []
        if ch:
            channel_name = str(ch[0].get("name", ""))
            bucket_name = str(ch[0].get("s3BucketName", ""))
    except Exception:
        pass

    if not recorder_name:
        recorder_name = "default"
    if not role_arn:
        role_arn = f"arn:aws:iam::{account_id}:role/aws-service-role/config.amazonaws.com/AWSServiceRoleForConfig"
    if not channel_name:
        channel_name = "default"
    if not bucket_name:
        bucket_name = pick_default_log_bucket(account_id)
    if not bucket_name:
        return ""
    finding["_config_bucket"] = bucket_name

    finding["_config_recorder_name"] = recorder_name
    finding["_config_delivery_channel_name"] = channel_name

    policy_doc: Dict[str, Any] = {"Version": "2012-10-17", "Statement": []}
    try:
        s3 = boto3.client("s3")
        resp = s3.get_bucket_policy(Bucket=bucket_name)
        raw = resp.get("Policy", "")
        if raw:
            loaded = json.loads(raw)
            if isinstance(loaded, dict):
                policy_doc = loaded
    except Exception:
        pass

    stmts = policy_doc.get("Statement", [])
    if not isinstance(stmts, list):
        stmts = [stmts] if stmts else []

    has_acl = False
    has_put = False
    has_list = False
    for s in stmts:
        if not isinstance(s, dict):
            continue
        principal = s.get("Principal", {})
        service = principal.get("Service", "") if isinstance(principal, dict) else ""
        action = s.get("Action", [])
        actions = [action] if isinstance(action, str) else (action if isinstance(action, list) else [])
        actions_l = [str(a).lower() for a in actions]
        if str(service).lower() == "config.amazonaws.com" and "s3:getbucketacl" in actions_l:
            has_acl = True
        if str(service).lower() == "config.amazonaws.com" and "s3:putobject" in actions_l:
            has_put = True
        if str(service).lower() == "config.amazonaws.com" and "s3:listbucket" in actions_l:
            has_list = True

    if not has_acl:
        stmts.append(
            {
                "Sid": "AWSConfigBucketAclCheck",
                "Effect": "Allow",
                "Principal": {"Service": "config.amazonaws.com"},
                "Action": "s3:GetBucketAcl",
                "Resource": f"arn:aws:s3:::{bucket_name}",
                "Condition": {
                    "StringEquals": {"aws:SourceAccount": account_id},
                    "ArnLike": {"aws:SourceArn": f"arn:aws:config:{region}:{account_id}:*"},
                },
            }
        )
    if not has_list:
        stmts.append(
            {
                "Sid": "AWSConfigBucketListCheck",
                "Effect": "Allow",
                "Principal": {"Service": "config.amazonaws.com"},
                "Action": "s3:ListBucket",
                "Resource": f"arn:aws:s3:::{bucket_name}",
                "Condition": {
                    "StringEquals": {"aws:SourceAccount": account_id},
                    "ArnLike": {"aws:SourceArn": f"arn:aws:config:{region}:{account_id}:*"},
                },
            }
        )
    if not has_put:
        stmts.append(
            {
                "Sid": "AWSConfigBucketDelivery",
                "Effect": "Allow",
                "Principal": {"Service": "config.amazonaws.com"},
                "Action": "s3:PutObject",
                "Resource": f"arn:aws:s3:::{bucket_name}/AWSLogs/{account_id}/Config/*",
                "Condition": {
                    "StringEquals": {
                        "s3:x-amz-acl": "bucket-owner-full-control",
                        "aws:SourceAccount": account_id,
                    },
                    "ArnLike": {"aws:SourceArn": f"arn:aws:config:{region}:{account_id}:*"},
                },
            }
        )
    policy_doc["Statement"] = stmts
    policy_json = json.dumps(policy_doc, indent=2)

    return (
        'resource "aws_s3_bucket_policy" "fix_config_bucket_policy" {\n'
        f'  bucket = "{bucket_name}"\n'
        "  policy = <<POLICY\n"
        f"{policy_json}\n"
        "POLICY\n"
        "}\n\n"
        'resource "aws_config_configuration_recorder" "fix_config_recorder" {\n'
        f'  name     = "{recorder_name}"\n'
        f'  role_arn = "{role_arn}"\n'
        "\n"
        "  recording_group {\n"
        "    all_supported                 = true\n"
        "    include_global_resource_types = true\n"
        "  }\n"
        "}\n\n"
        'resource "aws_config_delivery_channel" "fix_config_delivery_channel" {\n'
        f'  name           = "{channel_name}"\n'
        f'  s3_bucket_name = "{bucket_name}"\n'
        '  depends_on     = [aws_s3_bucket_policy.fix_config_bucket_policy, aws_config_configuration_recorder.fix_config_recorder]\n'
        "}\n\n"
        'resource "aws_config_configuration_recorder_status" "fix_config_recorder_status" {\n'
        f'  name       = "{recorder_name}"\n'
        "  is_enabled = true\n"
        "  depends_on = [aws_config_delivery_channel.fix_config_delivery_channel]\n"
        "}\n"
    )


def build_kms_rotation_tf(finding: Dict[str, Any]) -> str:
    key_id = extract_kms_key_id(finding.get("resource_arn", ""))
    if not key_id:
        return ""
    return (
        'resource "aws_kms_key" "fix_kms_rotation" {\n'
        "  enable_key_rotation = true\n"
        "}\n"
    )


def build_cloudtrail_required_bucket_policy_tf(
    trail_name: str,
    bucket: str,
    account_id: str,
    region: str,
) -> str:
    if not trail_name or not bucket:
        return ""

    source_arn = f"arn:aws:cloudtrail:{region}:{account_id}:trail/{trail_name}"
    policy_doc: Dict[str, Any] = {"Version": "2012-10-17", "Statement": []}
    try:
        s3 = boto3.client("s3")
        resp = s3.get_bucket_policy(Bucket=bucket)
        raw = resp.get("Policy", "")
        if raw:
            loaded = json.loads(raw)
            if isinstance(loaded, dict):
                policy_doc = loaded
    except Exception:
        pass

    stmts = policy_doc.get("Statement", [])
    if not isinstance(stmts, list):
        stmts = [stmts] if stmts else []

    has_acl = False
    has_put = False
    for s in stmts:
        if not isinstance(s, dict):
            continue
        principal = s.get("Principal", {})
        service = principal.get("Service", "") if isinstance(principal, dict) else ""
        action = s.get("Action", [])
        actions = [action] if isinstance(action, str) else (action if isinstance(action, list) else [])
        actions_l = [str(a).lower() for a in actions]
        if str(service).lower() == "cloudtrail.amazonaws.com" and "s3:getbucketacl" in actions_l:
            has_acl = True
        if str(service).lower() == "cloudtrail.amazonaws.com" and "s3:putobject" in actions_l:
            has_put = True

    if not has_acl:
        stmts.append(
            {
                "Sid": "AWSCloudTrailAclCheck20150319",
                "Effect": "Allow",
                "Principal": {"Service": "cloudtrail.amazonaws.com"},
                "Action": "s3:GetBucketAcl",
                "Resource": f"arn:aws:s3:::{bucket}",
                "Condition": {"StringEquals": {"aws:SourceArn": source_arn}},
            }
        )
    if not has_put:
        stmts.append(
            {
                "Sid": "AWSCloudTrailWrite20150319",
                "Effect": "Allow",
                "Principal": {"Service": "cloudtrail.amazonaws.com"},
                "Action": "s3:PutObject",
                "Resource": f"arn:aws:s3:::{bucket}/AWSLogs/{account_id}/*",
                "Condition": {
                    "StringEquals": {
                        "s3:x-amz-acl": "bucket-owner-full-control",
                        "aws:SourceArn": source_arn,
                    }
                },
            }
        )
    policy_doc["Statement"] = stmts
    policy_json = json.dumps(policy_doc, indent=2)
    return (
        'resource "aws_s3_bucket_policy" "fix_cloudtrail_bucket_policy" {\n'
        f'  bucket = "{bucket}"\n'
        "  policy = <<POLICY\n"
        f"{policy_json}\n"
        "POLICY\n"
        "}\n\n"
    )


def cloudtrail_supports_dataevents_patch(region: str, trail_name: str) -> bool:
    if not trail_name:
        return False
    try:
        ct = boto3.client("cloudtrail", region_name=region)
        resp = ct.get_event_selectors(TrailName=trail_name)
        advanced = resp.get("AdvancedEventSelectors", []) or []
        # If advanced selectors are in use, in-place event_selector mutation is high-risk and often rejected.
        if isinstance(advanced, list) and len(advanced) > 0:
            return False
        return True
    except Exception:
        return False


def build_cloudtrail_tf(finding: Dict[str, Any], region: str, account_id: str) -> str:
    cid_l = str(finding.get("check_id", "")).lower()
    trail_name = extract_trail_name(finding.get("resource_arn", ""))
    detail = get_cloudtrail_detail(region, trail_name) if trail_name else {}
    if not detail:
        detail = pick_default_trail(region)
    if not detail:
        return ""
    name = str(detail.get("Name", "") or trail_name)
    s3_bucket = str(detail.get("S3BucketName", ""))
    if not name or not s3_bucket:
        return ""
    finding["_trail_name"] = name
    finding["_trail_bucket"] = s3_bucket
    policy_prefix = ""

    include_global = "true" if bool(detail.get("IncludeGlobalServiceEvents", True)) else "false"
    multi_region = "true" if bool(detail.get("IsMultiRegionTrail", True)) else "false"
    enable_logging = "true" if bool(detail.get("LogFileValidationEnabled", True)) else "true"

    if "cloudtrail_logs_s3_bucket_access_logging_enabled" in cid_l:
        source_bucket = s3_bucket
        target_bucket = pick_default_log_bucket(account_id) or source_bucket
        finding["_source_bucket"] = source_bucket

        policy_doc: Dict[str, Any] = {"Version": "2012-10-17", "Statement": []}
        try:
            s3 = boto3.client("s3")
            resp = s3.get_bucket_policy(Bucket=target_bucket)
            raw = resp.get("Policy", "")
            if raw:
                loaded = json.loads(raw)
                if isinstance(loaded, dict):
                    policy_doc = loaded
        except Exception:
            pass

        stmts = policy_doc.get("Statement", [])
        if not isinstance(stmts, list):
            stmts = [stmts] if stmts else []
        has_logging_put = False
        for st in stmts:
            if not isinstance(st, dict):
                continue
            principal = st.get("Principal", {})
            service = str(principal.get("Service", "")).lower() if isinstance(principal, dict) else ""
            action = st.get("Action", [])
            actions = [action] if isinstance(action, str) else (action if isinstance(action, list) else [])
            actions_l = [str(a).lower() for a in actions]
            if "logging.s3.amazonaws.com" in service and "s3:putobject" in actions_l:
                has_logging_put = True
                break
        if not has_logging_put:
            stmts.append(
                {
                    "Sid": "S3ServerAccessLogsPolicy",
                    "Effect": "Allow",
                    "Principal": {"Service": "logging.s3.amazonaws.com"},
                    "Action": "s3:PutObject",
                    "Resource": f"arn:aws:s3:::{target_bucket}/s3-access-logs/*",
                    "Condition": {"StringEquals": {"aws:SourceAccount": account_id}},
                }
            )
        policy_doc["Statement"] = stmts
        policy_json = json.dumps(policy_doc, indent=2)
        return (
            'resource "aws_s3_bucket_policy" "fix_cloudtrail_accesslog_target_policy" {\n'
            f'  bucket = "{target_bucket}"\n'
            "  policy = <<POLICY\n"
            f"{policy_json}\n"
            "POLICY\n"
            "}\n\n"
            'resource "aws_s3_bucket_logging" "fix_cloudtrail_bucket_logging" {\n'
            f'  bucket        = "{source_bucket}"\n'
            f'  target_bucket = "{target_bucket}"\n'
            '  target_prefix = "s3-access-logs/"\n'
            "  depends_on    = [aws_s3_bucket_policy.fix_cloudtrail_accesslog_target_policy]\n"
            "}\n"
        )

    lines = [
        'resource "aws_cloudtrail" "fix_cloudtrail" {',
        f'  name                          = "{name}"',
        f'  s3_bucket_name                = "{s3_bucket}"',
        f"  include_global_service_events = {include_global}",
        f"  is_multi_region_trail         = {multi_region}",
        f"  enable_logging                = {enable_logging}",
    ]

    if "log_file_validation_enabled" in cid_l:
        lines.append("  enable_log_file_validation    = true")
    elif "s3_dataevents_" in cid_l:
        if not cloudtrail_supports_dataevents_patch(region, name):
            return ""
        policy_prefix = build_cloudtrail_required_bucket_policy_tf(name, s3_bucket, account_id, region)
        lines.append("  enable_log_file_validation    = true")
        lines.extend(
            [
                "",
                "  event_selector {",
                "    read_write_type           = \"All\"",
                "    include_management_events = true",
                "",
                "    data_resource {",
                "      type   = \"AWS::S3::Object\"",
                "      values = [\"arn:aws:s3:::\"]",
                "    }",
                "  }",
            ]
        )
    elif "cloudtrail_cloudwatch_logging_enabled" in cid_l:
        lg_arn = str(detail.get("CloudWatchLogsLogGroupArn", ""))
        role_arn = str(detail.get("CloudWatchLogsRoleArn", ""))
        if not lg_arn:
            log_group_name = pick_default_cloudtrail_log_group(region, account_id)
            lg_arn = f"arn:aws:logs:{region}:{account_id}:log-group:{log_group_name}:*"
            finding["_log_group_name"] = log_group_name
            policy_prefix += (
                'resource "aws_cloudwatch_log_group" "fix_cloudtrail_log_group" {\n'
                f'  name = "{log_group_name}"\n'
                "}\n\n"
            )
        if not role_arn:
            role_name = f"CloudTrail_CloudWatchLogs_Role_{safe_id(name)}"[:64]
            role_arn = f"arn:aws:iam::{account_id}:role/{role_name}"
            policy_doc = {
                "Version": "2012-10-17",
                "Statement": [
                    {
                        "Effect": "Allow",
                        "Action": [
                            "logs:CreateLogStream",
                            "logs:PutLogEvents",
                        ],
                        "Resource": [lg_arn.replace(":*", ":log-stream:*"), lg_arn],
                    }
                ],
            }
            assume_doc = {
                "Version": "2012-10-17",
                "Statement": [
                    {"Effect": "Allow", "Principal": {"Service": "cloudtrail.amazonaws.com"}, "Action": "sts:AssumeRole"}
                ],
            }
            policy_prefix += (
                'resource "aws_iam_role" "fix_cloudtrail_cw_role" {\n'
                f'  name               = "{role_name}"\n'
                f"  assume_role_policy = <<POLICY\n{json.dumps(assume_doc, indent=2)}\nPOLICY\n"
                "}\n\n"
                'resource "aws_iam_role_policy" "fix_cloudtrail_cw_role_policy" {\n'
                f'  name   = "{role_name}-policy"\n'
                "  role   = aws_iam_role.fix_cloudtrail_cw_role.id\n"
                f"  policy = <<POLICY\n{json.dumps(policy_doc, indent=2)}\nPOLICY\n"
                "}\n\n"
            )
        lines.append("  enable_log_file_validation    = true")
        lines.append(f'  cloud_watch_logs_group_arn    = "{lg_arn}"')
        lines.append(f'  cloud_watch_logs_role_arn     = "{role_arn}"')
    elif "kms_encryption_enabled" in cid_l:
        kms = str(detail.get("KmsKeyId", ""))
        if not kms:
            kms_alias = f"cloudtrail-remediation-{safe_id(name)}"[:250]
            policy_prefix += (
                'resource "aws_kms_key" "fix_cloudtrail_kms_key" {\n'
                '  description         = "CloudTrail encryption key created by remediation"\n'
                "  enable_key_rotation = true\n"
                "}\n\n"
                'resource "aws_kms_alias" "fix_cloudtrail_kms_alias" {\n'
                f'  name          = "alias/{kms_alias}"\n'
                "  target_key_id = aws_kms_key.fix_cloudtrail_kms_key.key_id\n"
                "}\n\n"
            )
            kms = "${aws_kms_key.fix_cloudtrail_kms_key.arn}"
        lines.append("  enable_log_file_validation    = true")
        if kms.startswith("${"):
            lines.append(f"  kms_key_id                    = {kms}")
        else:
            lines.append(f'  kms_key_id                    = "{kms}"')
    else:
        return ""

    if "s3_dataevents_" in cid_l:
        lines.extend(
            [
                "",
                "  depends_on = [aws_s3_bucket_policy.fix_cloudtrail_bucket_policy]",
            ]
        )

    lines.extend(
        [
            "",
            "  lifecycle {",
            "    ignore_changes = [",
            "      event_selector,",
            "      insight_selector,",
            "      sns_topic_name,",
            "      tags,",
            "      tags_all",
            "    ]",
            "  }",
            "}",
            "",
        ]
    )
    body = "\n".join(lines)
    if "s3_dataevents_" in cid_l or policy_prefix:
        return policy_prefix + body
    return body


def cloudtrail_bucket_policy_ready(bucket: str) -> bool:
    if not bucket:
        return False
    try:
        s3 = boto3.client("s3")
        resp = s3.get_bucket_policy(Bucket=bucket)
        raw = resp.get("Policy", "")
        if not raw:
            return False
        doc = json.loads(raw)
        stmts = doc.get("Statement", [])
        if not isinstance(stmts, list):
            stmts = [stmts]
        has_acl = False
        has_put = False
        for s in stmts:
            if not isinstance(s, dict):
                continue
            principal = s.get("Principal", {})
            service = ""
            if isinstance(principal, dict):
                service = str(principal.get("Service", "")).lower()
            action = s.get("Action", [])
            actions = [action] if isinstance(action, str) else (action if isinstance(action, list) else [])
            actions_l = [str(a).lower() for a in actions]
            if "cloudtrail.amazonaws.com" in service and "s3:getbucketacl" in actions_l:
                has_acl = True
            if "cloudtrail.amazonaws.com" in service and "s3:putobject" in actions_l:
                has_put = True
        return has_acl and has_put
    except Exception:
        return False


CLOUDWATCH_PATTERNS: Dict[str, str] = {
    "cloudwatch_log_metric_filter_unauthorized_api_calls": '{ ($.errorCode = "*UnauthorizedOperation") || ($.errorCode = "AccessDenied*") }',
    "cloudwatch_log_metric_filter_authentication_failures": '{ ($.eventName = "ConsoleLogin") && ($.errorMessage = "Failed authentication") }',
    "cloudwatch_log_metric_filter_policy_changes": '{ ($.eventName = "DeleteGroupPolicy") || ($.eventName = "DeleteRolePolicy") || ($.eventName = "DeleteUserPolicy") || ($.eventName = "PutGroupPolicy") || ($.eventName = "PutRolePolicy") || ($.eventName = "PutUserPolicy") || ($.eventName = "CreatePolicy") || ($.eventName = "DeletePolicy") || ($.eventName = "CreatePolicyVersion") || ($.eventName = "DeletePolicyVersion") || ($.eventName = "AttachRolePolicy") || ($.eventName = "DetachRolePolicy") || ($.eventName = "AttachUserPolicy") || ($.eventName = "DetachUserPolicy") || ($.eventName = "AttachGroupPolicy") || ($.eventName = "DetachGroupPolicy") }',
    "cloudwatch_log_metric_filter_security_group_changes": '{ ($.eventName = "AuthorizeSecurityGroupIngress") || ($.eventName = "AuthorizeSecurityGroupEgress") || ($.eventName = "RevokeSecurityGroupIngress") || ($.eventName = "RevokeSecurityGroupEgress") || ($.eventName = "CreateSecurityGroup") || ($.eventName = "DeleteSecurityGroup") }',
    "cloudwatch_log_metric_filter_for_s3_bucket_policy_changes": '{ ($.eventSource = "s3.amazonaws.com") && (($.eventName = "PutBucketAcl") || ($.eventName = "PutBucketPolicy") || ($.eventName = "PutBucketCors") || ($.eventName = "PutBucketLifecycle") || ($.eventName = "PutBucketReplication") || ($.eventName = "DeleteBucketPolicy") || ($.eventName = "DeleteBucketCors") || ($.eventName = "DeleteBucketLifecycle") || ($.eventName = "DeleteBucketReplication")) }',
    "cloudwatch_log_metric_filter_disable_or_scheduled_deletion_of_kms_cmk": '{ ($.eventSource = "kms.amazonaws.com") && (($.eventName = "DisableKey") || ($.eventName = "ScheduleKeyDeletion")) }',
    "cloudwatch_changes_to_vpcs_alarm_configured": '{ ($.eventName = "CreateVpc") || ($.eventName = "DeleteVpc") || ($.eventName = "ModifyVpcAttribute") || ($.eventName = "AcceptVpcPeeringConnection") || ($.eventName = "CreateVpcPeeringConnection") || ($.eventName = "DeleteVpcPeeringConnection") || ($.eventName = "RejectVpcPeeringConnection") || ($.eventName = "AttachClassicLinkVpc") || ($.eventName = "DetachClassicLinkVpc") || ($.eventName = "DisableVpcClassicLink") || ($.eventName = "EnableVpcClassicLink") }',
    "cloudwatch_changes_to_network_route_tables_alarm_configured": '{ ($.eventName = "CreateRoute") || ($.eventName = "CreateRouteTable") || ($.eventName = "ReplaceRoute") || ($.eventName = "ReplaceRouteTableAssociation") || ($.eventName = "DeleteRouteTable") || ($.eventName = "DeleteRoute") || ($.eventName = "DisassociateRouteTable") }',
    "cloudwatch_changes_to_network_gateways_alarm_configured": '{ ($.eventName = "CreateCustomerGateway") || ($.eventName = "DeleteCustomerGateway") || ($.eventName = "AttachInternetGateway") || ($.eventName = "CreateInternetGateway") || ($.eventName = "DeleteInternetGateway") || ($.eventName = "DetachInternetGateway") }',
    "cloudwatch_changes_to_network_acls_alarm_configured": '{ ($.eventName = "CreateNetworkAcl") || ($.eventName = "CreateNetworkAclEntry") || ($.eventName = "DeleteNetworkAcl") || ($.eventName = "DeleteNetworkAclEntry") || ($.eventName = "ReplaceNetworkAclEntry") || ($.eventName = "ReplaceNetworkAclAssociation") }',
    "cloudwatch_log_metric_filter_and_alarm_for_cloudtrail_configuration_changes_enabled": '{ ($.eventName = "CreateTrail") || ($.eventName = "UpdateTrail") || ($.eventName = "DeleteTrail") || ($.eventName = "StartLogging") || ($.eventName = "StopLogging") }',
    "cloudwatch_log_metric_filter_and_alarm_for_aws_config_configuration_changes_enabled": '{ ($.eventSource = "config.amazonaws.com") && (($.eventName = "StopConfigurationRecorder") || ($.eventName = "DeleteDeliveryChannel") || ($.eventName = "PutDeliveryChannel") || ($.eventName = "PutConfigurationRecorder")) }',
    "cloudwatch_log_metric_filter_root_usage": '{ ($.userIdentity.type = "Root") && ($.userIdentity.invokedBy NOT EXISTS) && ($.eventType != "AwsServiceEvent") }',
    "cloudwatch_log_metric_filter_sign_in_without_mfa": '{ ($.eventName = "ConsoleLogin") && ($.additionalEventData.MFAUsed != "Yes") }',
    "cloudwatch_log_metric_filter_aws_organizations_changes": '{ ($.eventSource = "organizations.amazonaws.com") && (($.eventName = "AcceptHandshake") || ($.eventName = "AttachPolicy") || ($.eventName = "CreateAccount") || ($.eventName = "CreateOrganizationalUnit") || ($.eventName = "CreatePolicy") || ($.eventName = "DeclineHandshake") || ($.eventName = "DeleteOrganization") || ($.eventName = "DeleteOrganizationalUnit") || ($.eventName = "DeletePolicy") || ($.eventName = "DetachPolicy") || ($.eventName = "DisablePolicyType") || ($.eventName = "EnablePolicyType") || ($.eventName = "InviteAccountToOrganization") || ($.eventName = "LeaveOrganization") || ($.eventName = "MoveAccount") || ($.eventName = "RemoveAccountFromOrganization") || ($.eventName = "UpdatePolicy") || ($.eventName = "UpdateOrganizationalUnit")) }',
}


def build_cloudwatch_metric_alarm_tf(finding: Dict[str, Any], account_id: str, region: str) -> str:
    cid_l = str(finding.get("check_id", "")).lower()
    cid_l = cid_l.split("prowler-", 1)[1] if cid_l.startswith("prowler-") else cid_l
    pattern = CLOUDWATCH_PATTERNS.get(cid_l)
    if not pattern:
        return ""
    log_group = extract_log_group(finding.get("resource_arn", ""))
    if not log_group:
        log_group = pick_default_cloudtrail_log_group(region, account_id)
    finding["_log_group_name"] = log_group
    metric_ns = "CISBenchmark"
    metric_name = safe_id(cid_l)[:128]
    alarm_name = f"alarm-{metric_name}"[:255]
    filter_name = f"filter-{metric_name}"[:255]
    return (
        'resource "aws_cloudwatch_log_group" "fix_cloudwatch_log_group" {\n'
        f'  name = "{log_group}"\n'
        "}\n\n"
        'resource "aws_cloudwatch_log_metric_filter" "fix_cloudwatch_metric_filter" {\n'
        f'  name           = "{filter_name}"\n'
        f'  log_group_name = "{log_group}"\n'
        f'  pattern        = "{pattern.replace(chr(34), chr(92)+chr(34))}"\n'
        "\n"
        "  metric_transformation {\n"
        f'    name      = "{metric_name}"\n'
        f'    namespace = "{metric_ns}"\n'
        '    value     = "1"\n'
        "  }\n"
        "  depends_on = [aws_cloudwatch_log_group.fix_cloudwatch_log_group]\n"
        "}\n\n"
        'resource "aws_cloudwatch_metric_alarm" "fix_cloudwatch_metric_alarm" {\n'
        f'  alarm_name          = "{alarm_name}"\n'
        '  comparison_operator = "GreaterThanOrEqualToThreshold"\n'
        "  evaluation_periods  = 1\n"
        f'  metric_name         = "{metric_name}"\n'
        f'  namespace           = "{metric_ns}"\n'
        '  period              = 300\n'
        '  statistic           = "Sum"\n'
        '  threshold           = 1\n'
        '  alarm_description   = "Auto-generated remediation alarm"\n'
        "}\n"
    )


def cloudwatch_log_group_exists(name: str, region: str) -> bool:
    if not name:
        return False
    try:
        logs = boto3.client("logs", region_name=region)
        resp = logs.describe_log_groups(logGroupNamePrefix=name, limit=1)
        for g in resp.get("logGroups", []) or []:
            if g.get("logGroupName") == name:
                return True
    except Exception:
        return False
    return False


def main() -> None:
    p = argparse.ArgumentParser()
    p.add_argument("--input", required=True)
    p.add_argument("--output-root", required=True)
    p.add_argument("--snippet-map", required=True)
    p.add_argument("--account-id", required=True)
    p.add_argument("--region", required=True)
    p.add_argument("--model-id", required=True)
    a = p.parse_args()

    rows: List[Dict[str, Any]] = json.loads(Path(a.input).read_text(encoding="utf-8"))
    snippet_map = load_map(Path(a.snippet_map))

    out_root = Path(a.output_root)
    out_root.mkdir(parents=True, exist_ok=True)

    overall: Dict[str, Any] = {
        "created_at": datetime.now(timezone.utc).isoformat(),
        "account": a.account_id,
        "region": a.region,
        "baseline_fail_count": len([x for x in rows if x.get("status") == "FAIL"]),
        "categories": {},
        "import_map": {},
        "skipped": [],
    }

    for cat in CATEGORIES:
        cat_dir = out_root / cat
        cat_dir.mkdir(parents=True, exist_ok=True)
        for old_tf in cat_dir.glob("*.tf"):
            old_tf.unlink(missing_ok=True)
        overall["categories"][cat] = []
        overall["import_map"][cat] = []
    import_seen: Dict[str, set[str]] = {cat: set() for cat in CATEGORIES}

    fail_rows = [x for x in rows if x.get("status") == "FAIL"]
    fail_rows.sort(key=lambda x: check_priority(x.get("check_id", "")), reverse=True)

    cloudtrail_with_kms: set[str] = set()
    cloudtrail_with_dataevents: set[str] = set()

    for f in fail_rows:
        cid = f.get("check_id", "unknown")
        cat = category_of(f.get("service", ""), cid)
        if not cat:
            overall["skipped"].append({"check_id": cid, "reason": "unsupported_category"})
            continue

        cid_l = cid.lower()
        trail_name = extract_trail_name(f.get("resource_arn", ""))
        if not trail_name and "cloudtrail_" in cid_l:
            trail_name = str(pick_default_trail(a.region).get("Name", ""))
        if "cloudtrail_kms_encryption_enabled" in cid_l and trail_name:
            cloudtrail_with_kms.add(trail_name)
        if "cloudtrail_s3_dataevents_" in cid_l and trail_name:
            if trail_name in cloudtrail_with_dataevents:
                overall["categories"][cat].append(
                    {
                        "check_id": cid,
                        "manual_required": True,
                        "files": [],
                        "priority": f.get("osfp", {}).get("priority_bucket", "P3"),
                        "score": f.get("osfp", {}).get("priority_score", 0),
                        "reason": "consolidated_duplicate_dataevents",
                    }
                )
                continue
            cloudtrail_with_dataevents.add(trail_name)
        if "cloudtrail_log_file_validation_enabled" in cid_l and trail_name and trail_name in cloudtrail_with_kms:
            overall["categories"][cat].append(
                {
                    "check_id": cid,
                    "manual_required": True,
                    "files": [],
                    "priority": f.get("osfp", {}).get("priority_bucket", "P3"),
                    "score": f.get("osfp", {}).get("priority_score", 0),
                    "reason": "consolidated_into_kms_cloudtrail_fix",
                }
            )
            continue

        key = safe_id(
            f"{cid}_{f.get('resource_arn', '')}_{f.get('region', '')}_{f.get('resource_id', '')}"
        )

        if f.get("manual_required") or f.get("non_terraform"):
            overall["categories"][cat].append(
                {
                    "check_id": cid,
                    "manual_required": True,
                    "files": [],
                    "priority": f.get("osfp", {}).get("priority_bucket", "P3"),
                    "score": f.get("osfp", {}).get("priority_score", 0),
                    "reason": "manual_or_non_terraform",
                }
            )
            continue

        file_name = f"fix-{key}.tf"
        target = out_root / cat / file_name

        template_path = ""
        mapped = snippet_map.get(cid)
        if isinstance(mapped, dict):
            template_path = mapped.get("template", "")
        if not template_path:
            template_path = infer_template_by_rule(cid, cat) or ""

        tf_code = ""
        if "s3_bucket_secure_transport_policy" in cid_l:
            tf_code = build_secure_transport_policy_tf(f)
        elif "vpc_flow_logs_enabled" in cid_l:
            tf_code = build_vpc_flow_logs_tf(f, a.account_id)
        elif "networkacl_allow_ingress_any_port" in cid_l or "networkacl_allow_ingress_tcp_port_22" in cid_l or "networkacl_allow_ingress_tcp_port_3389" in cid_l:
            tf_code = build_nacl_restrict_ingress_tf(f, a.region)
        elif "accessanalyzer_enabled" in cid_l:
            tf_code = build_access_analyzer_tf(f, a.region, a.account_id)
        elif "config_recorder_all_regions_enabled" in cid_l:
            tf_code = build_config_recorder_tf(f, a.region, a.account_id)
        elif "kms_cmk_rotation_enabled" in cid_l:
            tf_code = build_kms_rotation_tf(f)
        elif cid_l.startswith("prowler-cloudtrail_") or cid_l.startswith("cloudtrail_"):
            tf_code = build_cloudtrail_tf(f, a.region, a.account_id)
        elif cid_l.startswith("prowler-cloudwatch_") or cid_l.startswith("cloudwatch_"):
            tf_code = build_cloudwatch_metric_alarm_tf(f, a.account_id, a.region)
        elif template_path and Path(template_path).exists():
            tf_code = Path(template_path).read_text(encoding="utf-8")
        elif USE_BEDROCK_FALLBACK:
            prompt = (
                "Output only valid Terraform HCL. No markdown, no preamble. "
                "Generate minimal-change remediation for this finding: "
                + json.dumps(f)
            )
            try:
                tf_code = strip_code_fence(render_with_bedrock(a.model_id, prompt))
            except Exception:
                tf_code = ""
        else:
            overall["categories"][cat].append(
                {
                    "check_id": cid,
                    "manual_required": True,
                    "files": [],
                    "priority": f.get("osfp", {}).get("priority_bucket", "P3"),
                    "score": f.get("osfp", {}).get("priority_score", 0),
                    "reason": "unsupported_no_template",
                }
            )
            continue

        if "securitygroup_default_restrict_traffic" in cid.lower():
            vpc_id = lookup_vpc_for_sg(f.get("resource_arn", ""), f.get("region", a.region))
            if vpc_id:
                f["_vpc_id"] = vpc_id
                tf_code = tf_code.replace("var.vpc_id", f'"{vpc_id}"')

        tf_code = materialize_vars(tf_code, f, a.account_id, a.region)
        tf_code, resource_addrs = uniquify_resource_names(tf_code, key)

        if "resource " not in tf_code:
            overall["categories"][cat].append(
                {
                    "check_id": cid,
                    "manual_required": True,
                    "files": [],
                    "priority": f.get("osfp", {}).get("priority_bucket", "P3"),
                    "score": f.get("osfp", {}).get("priority_score", 0),
                    "reason": "generation_failed_or_invalid_hcl",
                }
            )
            continue

        if "var." in tf_code:
            overall["categories"][cat].append(
                {
                    "check_id": cid,
                    "manual_required": True,
                    "files": [],
                    "priority": f.get("osfp", {}).get("priority_bucket", "P3"),
                    "score": f.get("osfp", {}).get("priority_score", 0),
                    "reason": "unresolved_variables",
                }
            )
            continue

        if not validate_tf_snippet(tf_code):
            overall["categories"][cat].append(
                {
                    "check_id": cid,
                    "manual_required": True,
                    "files": [],
                    "priority": f.get("osfp", {}).get("priority_bucket", "P3"),
                    "score": f.get("osfp", {}).get("priority_score", 0),
                    "reason": "generated_hcl_failed_validation",
                }
            )
            continue

        target.write_text(tf_code.rstrip() + "\n", encoding="utf-8")

        for addr, rtype in resource_addrs:
            iid = import_id_for_type(rtype, f)
            if iid:
                if addr in import_seen.get(cat, set()):
                    continue
                import_seen[cat].add(addr)
                overall["import_map"][cat].append(
                    {
                        "check_id": cid,
                        "address": addr,
                        "import_id": iid,
                        "resource_type": rtype,
                        "optional": rtype in OPTIONAL_IMPORT_TYPES,
                    }
                )

        overall["categories"][cat].append(
            {
                "check_id": cid,
                "manual_required": False,
                "files": [str(target).replace("\\", "/")],
                "priority": f.get("osfp", {}).get("priority_bucket", "P3"),
                "score": f.get("osfp", {}).get("priority_score", 0),
            }
        )

    for cat in CATEGORIES:
        lines = []
        for row in overall["import_map"][cat]:
            lines.append(f"{row['address']}|{row['import_id']}|{str(row['optional']).lower()}|{row['check_id']}")
        (out_root / cat / "import-map.txt").write_text("\n".join(lines) + ("\n" if lines else ""), encoding="utf-8")

    (out_root / "_generation_manifest.json").write_text(json.dumps(overall, indent=2), encoding="utf-8")


if __name__ == "__main__":
    main()
