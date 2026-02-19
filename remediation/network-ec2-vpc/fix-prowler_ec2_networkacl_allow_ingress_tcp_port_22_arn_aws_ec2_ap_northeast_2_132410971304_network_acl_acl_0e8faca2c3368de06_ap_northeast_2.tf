resource "aws_network_acl_rule" "fix_network_acl_ingress_deny_99b74d2457" {
  network_acl_id = "acl-0e8faca2c3368de06"
  egress         = false
  rule_number    = 1
  protocol       = "6"
  rule_action    = "deny"
  cidr_block     = "0.0.0.0/0"
  from_port      = 22
  to_port        = 22
  lifecycle {
    ignore_changes = [icmp_type, icmp_code]
  }
}
