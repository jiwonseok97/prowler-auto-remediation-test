from __future__ import annotations


def build_cloudwatch(findings: list[dict]) -> str:
    if not findings:
        return ""
    return """
# CloudWatch builder remediation
resource \"aws_cloudwatch_log_group\" \"ai_remed_cloudwatch_log_group\" {
  name              = \"/secure/log-group\"
  retention_in_days = 90
}
""".strip() + "\n"
