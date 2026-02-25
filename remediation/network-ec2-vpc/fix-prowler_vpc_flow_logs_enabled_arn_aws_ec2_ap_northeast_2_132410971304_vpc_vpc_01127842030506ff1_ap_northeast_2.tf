resource "aws_flow_log" "fix_vpc_flow_logs_abe426687a" {
  vpc_id               = "vpc-01127842030506ff1"
  traffic_type         = "ALL"
  log_destination_type = "s3"
  log_destination      = "arn:aws:s3:::aws-cloudtrail-logs-132410971304-0971c04b"
}
