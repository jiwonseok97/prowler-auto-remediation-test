resource "aws_network_acl" "example_9661cb895d" {
  vpc_id     = "vpc-0123456789abcdef"
  subnet_ids = ["subnet-0123456789abcdef", "subnet-fedcba9876543210"]

  ingress {
    rule_no    = 100
    protocol   = -1
    action     = "deny"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }

  egress {
    rule_no    = 100
    protocol   = -1
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }
}
