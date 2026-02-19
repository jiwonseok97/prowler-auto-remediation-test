resource "aws_network_acl_rule" "allow_ingress_any_port_remediation_ad31ee5796" {
  network_acl_id = "acl-0aefc1d1492a25a53"
  rule_number    = 100
  egress         = false
  protocol       = "-1"
  rule_action    = "deny"
  cidr_block     = "0.0.0.0/0"
  from_port      = 0
  to_port        = 0
}
