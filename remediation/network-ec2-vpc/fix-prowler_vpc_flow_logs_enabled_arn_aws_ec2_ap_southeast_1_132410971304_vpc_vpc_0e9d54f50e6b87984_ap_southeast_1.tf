resource "aws_flow_log" "fix_vpc_flow_logs_e608c1d37e" {
  vpc_id               = "vpc-0e9d54f50e6b87984"
  traffic_type         = "ALL"
  log_destination_type = "s3"
  log_destination      = "arn:aws:s3:::aws-cloudtrail-logs-132410971304-0971c04b"
}
