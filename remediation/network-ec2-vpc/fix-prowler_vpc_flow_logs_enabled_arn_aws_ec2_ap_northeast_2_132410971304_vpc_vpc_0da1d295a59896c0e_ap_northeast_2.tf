resource "aws_flow_log" "fix_vpc_flow_logs_2386e2ca28" {
  vpc_id               = "vpc-0da1d295a59896c0e"
  traffic_type         = "ALL"
  log_destination_type = "s3"
  log_destination      = "arn:aws:s3:::aws-cloudtrail-logs-132410971304-0971c04b"
}
