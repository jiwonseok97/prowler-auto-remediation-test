resource "aws_network_acl_rule" "remediation_a8936417b7" {
  network_acl_id = "acl-0f15dbfa32fbce83b"
  rule_number    = 100
  egress         = false
  protocol       = "tcp"
  rule_action    = "deny"
  cidr_block     = "0.0.0.0/0"
  from_port      = 3389
  to_port        = 3389
}
