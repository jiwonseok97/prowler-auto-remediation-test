resource "aws_flow_log" "fix_vpc_flow_logs_d9954e8c2b" {
  vpc_id               = "vpc-01078e2c869d87b89"
  traffic_type         = "ALL"
  log_destination_type = "s3"
  log_destination      = "arn:aws:s3:::aws-cloudtrail-logs-132410971304-0971c04b"
}
