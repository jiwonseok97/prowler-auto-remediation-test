resource "aws_network_acl" "acl-04f1a439902c4ba67_87a205d7c8" {
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
