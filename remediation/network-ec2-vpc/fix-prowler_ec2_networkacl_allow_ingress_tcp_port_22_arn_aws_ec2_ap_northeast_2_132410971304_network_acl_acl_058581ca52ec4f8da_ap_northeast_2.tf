resource "aws_network_acl_rule" "fix_network_acl_ingress_deny_585e4b17d3" {
  network_acl_id = "acl-058581ca52ec4f8da"
  egress         = false
  rule_number    = 102
  protocol       = "6"
  rule_action    = "deny"
  cidr_block     = "0.0.0.0/0"
  from_port      = 22
  to_port        = 22
  lifecycle {
    ignore_changes = [icmp_type, icmp_code]
  }
}
