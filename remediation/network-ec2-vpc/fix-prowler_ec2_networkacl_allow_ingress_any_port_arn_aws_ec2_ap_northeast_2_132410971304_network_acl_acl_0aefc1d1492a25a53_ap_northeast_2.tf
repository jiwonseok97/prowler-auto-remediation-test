resource "aws_network_acl_rule" "fix_network_acl_ingress_deny_ad31ee5796" {
  network_acl_id = "acl-0aefc1d1492a25a53"
  egress         = false
  rule_number    = 51
  protocol       = "-1"
  rule_action    = "deny"
  cidr_block     = "0.0.0.0/0"
  lifecycle {
    ignore_changes = [icmp_type, icmp_code]
  }
}
