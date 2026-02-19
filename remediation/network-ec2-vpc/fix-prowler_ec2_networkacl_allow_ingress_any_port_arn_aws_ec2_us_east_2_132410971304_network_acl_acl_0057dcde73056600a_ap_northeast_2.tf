resource "aws_network_acl_rule" "allow_ingress_any_port_remediation_119a44eefc" {
  network_acl_id = "acl-0057dcde73056600a"
  rule_number    = 100
  egress         = false
  protocol       = "-1"
  rule_action    = "deny"
  cidr_block     = "0.0.0.0/0"
  from_port      = 0
  to_port        = 0
}
