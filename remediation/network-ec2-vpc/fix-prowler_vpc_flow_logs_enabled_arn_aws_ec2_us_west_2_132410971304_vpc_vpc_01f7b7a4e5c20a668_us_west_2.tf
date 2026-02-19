resource "aws_flow_log" "fix_vpc_flow_logs_7ba19be004" {
  vpc_id               = "vpc-01f7b7a4e5c20a668"
  traffic_type         = "ALL"
  log_destination_type = "s3"
  log_destination      = "arn:aws:s3:::aws-cloudtrail-logs-132410971304-0971c04b"
}
