resource "aws_flow_log" "fix_vpc_flow_logs_7dc469089b" {
  vpc_id               = "vpc-00176713df46332e8"
  traffic_type         = "ALL"
  log_destination_type = "s3"
  log_destination      = "arn:aws:s3:::aws-cloudtrail-logs-132410971304-0971c04b"
}
