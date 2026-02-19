resource "aws_network_acl_rule" "fix_network_acl_ingress_deny_ab0e76454b" {
  network_acl_id = "acl-04f1a439902c4ba67"
  egress         = false
  rule_number    = 252
  protocol       = "6"
  rule_action    = "deny"
  cidr_block     = "0.0.0.0/0"
  from_port      = 3389
  to_port        = 3389
  lifecycle {
    ignore_changes = [icmp_type, icmp_code]
  }
}
