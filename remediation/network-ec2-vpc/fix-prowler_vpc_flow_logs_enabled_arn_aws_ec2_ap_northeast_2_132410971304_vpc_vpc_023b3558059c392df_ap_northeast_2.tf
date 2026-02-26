resource "aws_flow_log" "fix_vpc_flow_logs_c79582128f" {
  vpc_id               = "vpc-023b3558059c392df"
  traffic_type         = "ALL"
  log_destination_type = "s3"
  log_destination      = "arn:aws:s3:::aws-cloudtrail-logs-132410971304-0971c04b"
}
