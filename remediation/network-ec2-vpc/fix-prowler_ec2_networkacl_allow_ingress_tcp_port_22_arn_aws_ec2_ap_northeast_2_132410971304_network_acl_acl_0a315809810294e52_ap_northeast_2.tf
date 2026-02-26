resource "aws_network_acl_rule" "fix_network_acl_ingress_deny_0e17930546" {
  network_acl_id = "acl-0a315809810294e52"
  egress         = false
  rule_number    = 101
  protocol       = "6"
  rule_action    = "deny"
  cidr_block     = "0.0.0.0/0"
  from_port      = 22
  to_port        = 22
  lifecycle {
    ignore_changes = [icmp_type, icmp_code]
  }
}
