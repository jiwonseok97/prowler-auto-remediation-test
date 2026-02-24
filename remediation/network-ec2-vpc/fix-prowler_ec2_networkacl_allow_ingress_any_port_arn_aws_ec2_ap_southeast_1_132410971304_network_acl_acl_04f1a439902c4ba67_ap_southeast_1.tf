resource "aws_network_acl_rule" "fix_network_acl_ingress_deny_37c15d83fa" {
  network_acl_id = "acl-04f1a439902c4ba67"
  egress         = false
  rule_number    = 253
  protocol       = "-1"
  rule_action    = "deny"
  cidr_block     = "0.0.0.0/0"
  lifecycle {
    ignore_changes = [icmp_type, icmp_code]
  }
}
