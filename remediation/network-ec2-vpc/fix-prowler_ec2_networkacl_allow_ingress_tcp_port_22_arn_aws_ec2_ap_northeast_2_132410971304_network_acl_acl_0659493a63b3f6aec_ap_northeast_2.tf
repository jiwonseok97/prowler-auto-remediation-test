resource "aws_network_acl_rule" "fix_network_acl_ingress_deny_89e08a2b4d" {
  network_acl_id = "acl-0659493a63b3f6aec"
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
