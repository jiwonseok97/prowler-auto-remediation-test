resource "aws_network_acl_rule" "fix_network_acl_ingress_deny_7a55ca522b" {
  network_acl_id = "acl-0572e1ab82993bb20"
  egress         = false
  rule_number    = 51
  protocol       = "-1"
  rule_action    = "deny"
  cidr_block     = "0.0.0.0/0"
  lifecycle {
    ignore_changes = [icmp_type, icmp_code]
  }
}
