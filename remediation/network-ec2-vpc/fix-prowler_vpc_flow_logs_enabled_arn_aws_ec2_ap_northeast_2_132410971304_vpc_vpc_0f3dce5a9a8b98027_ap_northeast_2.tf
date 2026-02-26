resource "aws_flow_log" "fix_vpc_flow_logs_5c0405ec06" {
  vpc_id               = "vpc-0f3dce5a9a8b98027"
  traffic_type         = "ALL"
  log_destination_type = "s3"
  log_destination      = "arn:aws:s3:::aws-cloudtrail-logs-132410971304-0971c04b"
}
