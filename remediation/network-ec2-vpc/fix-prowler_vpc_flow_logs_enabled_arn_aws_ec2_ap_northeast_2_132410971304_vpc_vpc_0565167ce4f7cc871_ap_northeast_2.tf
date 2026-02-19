resource "aws_flow_log" "fix_vpc_flow_logs_59d9dab1ce" {
  vpc_id               = "vpc-0565167ce4f7cc871"
  traffic_type         = "ALL"
  log_destination_type = "s3"
  log_destination      = "arn:aws:s3:::aws-cloudtrail-logs-132410971304-0971c04b"
}
