resource "aws_network_acl_rule" "fix_network_acl_ingress_deny_be359c7ac0" {
  network_acl_id = "acl-058581ca52ec4f8da"
  egress         = false
  rule_number    = 102
  protocol       = "-1"
  rule_action    = "deny"
  cidr_block     = "0.0.0.0/0"
  lifecycle {
    ignore_changes = [icmp_type, icmp_code]
  }
}
