resource "aws_network_acl_rule" "remediation_65b17d607b" {
  network_acl_id = "acl-0ebd5da14e1dbdbc7"
  rule_number    = 100
  egress         = false
  protocol       = "tcp"
  rule_action    = "deny"
  cidr_block     = "0.0.0.0/0"
  from_port      = 3389
  to_port        = 3389
}
