resource "aws_flow_log" "fix_vpc_flow_logs_a25b75b7be" {
  vpc_id               = "vpc-0204bfe3f225cb78d"
  traffic_type         = "ALL"
  log_destination_type = "s3"
  log_destination      = "arn:aws:s3:::aws-cloudtrail-logs-132410971304-0971c04b"
}
