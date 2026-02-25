resource "aws_network_acl_rule" "fix_network_acl_ingress_deny_061b178fdc" {
  network_acl_id = "acl-0908a8c50bf9615a7"
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
