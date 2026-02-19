resource "aws_network_acl_rule" "fix_network_acl_ingress_deny_4f00e16e3d" {
  network_acl_id = "acl-0e8faca2c3368de06"
  egress         = false
  rule_number    = 51
  protocol       = "-1"
  rule_action    = "deny"
  cidr_block     = "0.0.0.0/0"
  lifecycle {
    ignore_changes = [icmp_type, icmp_code]
  }
}
