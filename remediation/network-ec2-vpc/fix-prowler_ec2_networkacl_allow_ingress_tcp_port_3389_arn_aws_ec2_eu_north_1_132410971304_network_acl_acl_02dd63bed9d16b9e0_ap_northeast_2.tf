resource "aws_network_acl_rule" "remediate_ec2_networkacl_allow_ingress_tcp_port_3389_6a4599f015" {
  network_acl_id = "acl-02dd63bed9d16b9e0"
  rule_number    = 100
  egress         = false
  protocol       = "tcp"
  rule_action    = "deny"
  cidr_block     = "0.0.0.0/0"
  from_port      = 3389
  to_port        = 3389
}
