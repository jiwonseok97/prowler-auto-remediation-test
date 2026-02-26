resource "aws_network_acl_rule" "fix_network_acl_ingress_deny_34d7c80022" {
  network_acl_id = "acl-0884d865327f5b687"
  egress         = false
  rule_number    = 251
  protocol       = "6"
  rule_action    = "deny"
  cidr_block     = "0.0.0.0/0"
  from_port      = 22
  to_port        = 22
  lifecycle {
    ignore_changes = [icmp_type, icmp_code]
  }
}
