resource "aws_flow_log" "fix_vpc_flow_logs_586fbaab8d" {
  vpc_id               = "vpc-0ad18cac76a0ab778"
  traffic_type         = "ALL"
  log_destination_type = "s3"
  log_destination      = "arn:aws:s3:::aws-cloudtrail-logs-132410971304-0971c04b"
}
