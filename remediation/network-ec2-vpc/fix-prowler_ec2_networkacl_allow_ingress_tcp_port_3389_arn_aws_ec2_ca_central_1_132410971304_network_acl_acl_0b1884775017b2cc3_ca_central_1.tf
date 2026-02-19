resource "aws_network_acl_rule" "fix_network_acl_ingress_deny_f57d42976b" {
  network_acl_id = "acl-0b1884775017b2cc3"
  egress         = false
  rule_number    = 252
  protocol       = "6"
  rule_action    = "deny"
  cidr_block     = "0.0.0.0/0"
  from_port      = 3389
  to_port        = 3389
  lifecycle {
    ignore_changes = [icmp_type, icmp_code]
  }
}
