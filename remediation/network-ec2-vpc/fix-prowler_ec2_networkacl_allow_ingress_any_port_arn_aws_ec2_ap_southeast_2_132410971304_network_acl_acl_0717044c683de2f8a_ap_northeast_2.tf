resource "aws_network_acl_rule" "allow_ingress_any_port_c498eac20d" {
  network_acl_id = "acl-0717044c683de2f8a"
  rule_number    = 100
  egress         = false
  protocol       = "-1"
  rule_action    = "deny"
  cidr_block     = "0.0.0.0/0"
  from_port      = 0
  to_port        = 0
}
