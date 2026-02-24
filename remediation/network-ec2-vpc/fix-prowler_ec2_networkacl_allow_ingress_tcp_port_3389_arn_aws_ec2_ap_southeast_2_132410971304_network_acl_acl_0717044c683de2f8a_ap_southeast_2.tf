resource "aws_network_acl_rule" "fix_network_acl_ingress_deny_a57f343c98" {
  network_acl_id = "acl-0717044c683de2f8a"
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
