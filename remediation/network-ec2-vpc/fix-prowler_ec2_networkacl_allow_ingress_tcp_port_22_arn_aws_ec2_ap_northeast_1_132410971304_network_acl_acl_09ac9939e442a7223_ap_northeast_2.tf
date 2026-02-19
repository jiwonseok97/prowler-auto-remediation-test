resource "aws_network_acl_rule" "remediate_ec2_networkacl_allow_ingress_tcp_port_22_ca4a9ae4b9" {
  network_acl_id = "acl-09ac9939e442a7223"
  rule_number    = 100
  egress         = false
  protocol       = "tcp"
  rule_action    = "deny"
  cidr_block     = "0.0.0.0/0"
  from_port      = 22
  to_port        = 22
}
