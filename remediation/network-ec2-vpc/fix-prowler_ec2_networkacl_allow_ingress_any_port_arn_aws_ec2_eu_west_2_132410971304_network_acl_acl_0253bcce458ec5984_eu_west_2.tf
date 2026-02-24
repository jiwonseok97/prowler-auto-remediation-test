resource "aws_network_acl_rule" "fix_network_acl_ingress_deny_f610fd3e15" {
  network_acl_id = "acl-0253bcce458ec5984"
  egress         = false
  rule_number    = 253
  protocol       = "-1"
  rule_action    = "deny"
  cidr_block     = "0.0.0.0/0"
  lifecycle {
    ignore_changes = [icmp_type, icmp_code]
  }
}
