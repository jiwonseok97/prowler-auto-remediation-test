resource "aws_network_acl_rule" "fix_network_acl_ingress_deny_ea8666fafc" {
  network_acl_id = "acl-076f5acb0865e8b47"
  egress         = false
  rule_number    = 253
  protocol       = "-1"
  rule_action    = "deny"
  cidr_block     = "0.0.0.0/0"
  lifecycle {
    ignore_changes = [icmp_type, icmp_code]
  }
}
