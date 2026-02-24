resource "aws_flow_log" "fix_vpc_flow_logs_10b3f04039" {
  vpc_id               = "vpc-07026a62847200142"
  traffic_type         = "ALL"
  log_destination_type = "s3"
  log_destination      = "arn:aws:s3:::aws-cloudtrail-logs-132410971304-0971c04b"
}
