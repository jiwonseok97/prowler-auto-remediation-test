resource "aws_network_acl_rule" "fix_network_acl_ingress_deny_add66ea6eb" {
  network_acl_id = "acl-0057dcde73056600a"
  egress         = false
  rule_number    = 253
  protocol       = "-1"
  rule_action    = "deny"
  cidr_block     = "0.0.0.0/0"
  lifecycle {
    ignore_changes = [icmp_type, icmp_code]
  }
}
