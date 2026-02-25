resource "aws_network_acl_rule" "fix_network_acl_ingress_deny_badbdf44a5" {
  network_acl_id = "acl-0dca3f4bca0feec8a"
  egress         = false
  rule_number    = 253
  protocol       = "-1"
  rule_action    = "deny"
  cidr_block     = "0.0.0.0/0"
  lifecycle {
    ignore_changes = [icmp_type, icmp_code]
  }
}
