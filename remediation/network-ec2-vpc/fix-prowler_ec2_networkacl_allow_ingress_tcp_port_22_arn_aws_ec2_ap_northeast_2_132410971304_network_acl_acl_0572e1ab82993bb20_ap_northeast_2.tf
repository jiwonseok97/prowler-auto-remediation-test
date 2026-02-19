resource "aws_network_acl_rule" "fix_network_acl_ingress_deny_ec1218ba4f" {
  network_acl_id = "acl-0572e1ab82993bb20"
  egress         = false
  rule_number    = 52
  protocol       = "6"
  rule_action    = "deny"
  cidr_block     = "0.0.0.0/0"
  from_port      = 22
  to_port        = 22
  lifecycle {
    ignore_changes = [icmp_type, icmp_code]
  }
}
