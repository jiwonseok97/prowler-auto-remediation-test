resource "aws_network_acl_rule" "fix_network_acl_ingress_deny_416a79de71" {
  network_acl_id = "acl-0884d865327f5b687"
  egress         = false
  rule_number    = 253
  protocol       = "-1"
  rule_action    = "deny"
  cidr_block     = "0.0.0.0/0"
  lifecycle {
    ignore_changes = [icmp_type, icmp_code]
  }
}
