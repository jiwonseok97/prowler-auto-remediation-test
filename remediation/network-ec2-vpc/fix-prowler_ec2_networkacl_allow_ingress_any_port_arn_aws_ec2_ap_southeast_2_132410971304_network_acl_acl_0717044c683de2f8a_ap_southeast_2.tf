resource "aws_network_acl_rule" "fix_network_acl_ingress_deny_2aa856cee1" {
  network_acl_id = "acl-0717044c683de2f8a"
  egress         = false
  rule_number    = 253
  protocol       = "-1"
  rule_action    = "deny"
  cidr_block     = "0.0.0.0/0"
  lifecycle {
    ignore_changes = [icmp_type, icmp_code]
  }
}
