resource "aws_network_acl" "acl-0717044c683de2f8a_c498eac20d" {
  vpc_id     = "vpc-0123456789abcdef"
  subnet_ids = ["subnet-0123456789abcdef", "subnet-fedcba9876543210"]

  ingress {
    from_port  = 0
    to_port    = 0
    rule_no    = 100
    action     = "deny"
    protocol   = "-1"
    cidr_block = "0.0.0.0/0"
  }

  egress {
    from_port  = 0
    to_port    = 0
    rule_no    = 100
    action     = "allow"
    protocol   = "-1"
    cidr_block = "0.0.0.0/0"
  }
}
