resource "aws_flow_log" "fix_vpc_flow_logs_0f08eb405b" {
  vpc_id               = "vpc-099ef085633a8d818"
  traffic_type         = "ALL"
  log_destination_type = "s3"
  log_destination      = "arn:aws:s3:::aws-cloudtrail-logs-132410971304-0971c04b"
}
