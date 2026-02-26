resource "aws_flow_log" "fix_vpc_flow_logs_d538a54f1e" {
  vpc_id               = "vpc-0c88fa3f0008c0495"
  traffic_type         = "ALL"
  log_destination_type = "s3"
  log_destination      = "arn:aws:s3:::aws-cloudtrail-logs-132410971304-0971c04b"
}
