resource "aws_flow_log" "fix_vpc_flow_logs_33142d295a" {
  vpc_id               = "vpc-04eb6666298723a01"
  traffic_type         = "ALL"
  log_destination_type = "s3"
  log_destination      = "arn:aws:s3:::aws-cloudtrail-logs-132410971304-0971c04b"
}
