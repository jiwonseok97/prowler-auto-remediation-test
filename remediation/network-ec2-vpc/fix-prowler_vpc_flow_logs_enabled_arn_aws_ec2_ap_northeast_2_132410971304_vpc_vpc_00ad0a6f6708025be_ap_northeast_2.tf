resource "aws_flow_log" "fix_vpc_flow_logs_2e2a4c1502" {
  vpc_id               = "vpc-00ad0a6f6708025be"
  traffic_type         = "ALL"
  log_destination_type = "s3"
  log_destination      = "arn:aws:s3:::aws-cloudtrail-logs-132410971304-0971c04b"
}
