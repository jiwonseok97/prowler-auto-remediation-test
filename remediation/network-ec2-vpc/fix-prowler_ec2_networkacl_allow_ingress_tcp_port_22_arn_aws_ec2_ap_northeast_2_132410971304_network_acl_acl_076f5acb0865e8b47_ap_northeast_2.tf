resource "aws_network_acl_rule" "fix_network_acl_ingress_deny_9536179812" {
  network_acl_id = "acl-076f5acb0865e8b47"
  egress         = false
  rule_number    = 251
  protocol       = "6"
  rule_action    = "deny"
  cidr_block     = "0.0.0.0/0"
  from_port      = 22
  to_port        = 22
  lifecycle {
    ignore_changes = [icmp_type, icmp_code]
  }
}
