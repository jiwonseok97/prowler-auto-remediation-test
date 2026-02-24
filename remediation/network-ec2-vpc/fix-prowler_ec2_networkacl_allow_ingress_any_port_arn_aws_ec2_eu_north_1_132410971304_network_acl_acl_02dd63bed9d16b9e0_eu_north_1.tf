resource "aws_network_acl_rule" "fix_network_acl_ingress_deny_db4c578bc0" {
  network_acl_id = "acl-02dd63bed9d16b9e0"
  egress         = false
  rule_number    = 253
  protocol       = "-1"
  rule_action    = "deny"
  cidr_block     = "0.0.0.0/0"
  lifecycle {
    ignore_changes = [icmp_type, icmp_code]
  }
}
