resource "aws_flow_log" "fix_vpc_flow_logs_1a4d37d155" {
  vpc_id               = "vpc-0958e25bd5e60fe30"
  traffic_type         = "ALL"
  log_destination_type = "s3"
  log_destination      = "arn:aws:s3:::aws-cloudtrail-logs-132410971304-0971c04b"
}
