resource "aws_network_acl_rule" "fix_network_acl_ingress_deny_29c4b86f72" {
  network_acl_id = "acl-0ae7a4508e4f18172"
  egress         = false
  rule_number    = 101
  protocol       = "-1"
  rule_action    = "deny"
  cidr_block     = "0.0.0.0/0"
  lifecycle {
    ignore_changes = [icmp_type, icmp_code]
  }
}
