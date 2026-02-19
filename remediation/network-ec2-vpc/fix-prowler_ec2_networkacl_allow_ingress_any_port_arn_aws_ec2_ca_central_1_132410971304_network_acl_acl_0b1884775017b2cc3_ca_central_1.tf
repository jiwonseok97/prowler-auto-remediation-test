resource "aws_network_acl_rule" "fix_network_acl_ingress_deny_4697831d9c" {
  network_acl_id = "acl-0b1884775017b2cc3"
  egress         = false
  rule_number    = 253
  protocol       = "-1"
  rule_action    = "deny"
  cidr_block     = "0.0.0.0/0"
  lifecycle {
    ignore_changes = [icmp_type, icmp_code]
  }
}
