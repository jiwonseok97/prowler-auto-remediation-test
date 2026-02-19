resource "aws_network_acl" "acl-0ebd5da14e1dbdbc7_7864a97953" {
  vpc_id     = "vpc-0123456789abcdef"
  subnet_ids = ["subnet-0123456789abcdef", "subnet-fedcba9876543210"]

  ingress {
    from_port  = 0
    to_port    = 0
    rule_no    = 100
    action     = "allow"
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

  tags = {
    Name = "Example Network ACL"
  }
}
