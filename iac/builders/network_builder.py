from __future__ import annotations


def build_network(findings: list[dict]) -> str:
    if not findings:
        return ""
    return """
# Network builder remediation
resource \"aws_security_group\" \"ai_remed_restrictive_sg\" {
  name   = \"ai-remed-sg\"
  vpc_id = data.aws_vpc.default.id

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = \"tcp\"
    cidr_blocks = [\"10.0.0.0/8\"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = \"-1\"
    cidr_blocks = [\"0.0.0.0/0\"]
  }
}

data \"aws_vpc\" \"default\" {
  default = true
}
""".strip() + "\n"
