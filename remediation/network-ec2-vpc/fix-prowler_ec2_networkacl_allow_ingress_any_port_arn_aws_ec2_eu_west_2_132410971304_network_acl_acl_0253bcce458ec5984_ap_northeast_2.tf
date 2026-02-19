resource "aws_network_acl_rule" "remediation_2fbdda8015" {
  network_acl_id = "acl-0253bcce458ec5984"
  rule_number    = 100
  egress         = false
  protocol       = "-1"
  rule_action    = "deny"
  cidr_block     = "0.0.0.0/0"
  from_port      = 0
  to_port        = 0
}
