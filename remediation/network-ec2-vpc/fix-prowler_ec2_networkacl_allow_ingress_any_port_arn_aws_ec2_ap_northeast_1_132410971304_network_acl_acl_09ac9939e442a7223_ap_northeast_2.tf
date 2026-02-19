resource "aws_network_acl_rule" "remediation_c823637d8a" {
  network_acl_id = "acl-09ac9939e442a7223"
  rule_number    = 100
  egress         = false
  protocol       = "-1"
  rule_action    = "deny"
  cidr_block     = "0.0.0.0/0"
  from_port      = 0
  to_port        = 0
}
