resource "aws_network_acl_rule" "fix_network_acl_ingress_deny_3695d34e48" {
  network_acl_id = "acl-04909b92a28bc1c06"
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
