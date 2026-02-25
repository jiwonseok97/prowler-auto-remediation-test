resource "aws_flow_log" "fix_vpc_flow_logs_358b2a1001" {
  vpc_id               = "vpc-06f1691190269dd4e"
  traffic_type         = "ALL"
  log_destination_type = "s3"
  log_destination      = "arn:aws:s3:::aws-cloudtrail-logs-132410971304-0971c04b"
}
