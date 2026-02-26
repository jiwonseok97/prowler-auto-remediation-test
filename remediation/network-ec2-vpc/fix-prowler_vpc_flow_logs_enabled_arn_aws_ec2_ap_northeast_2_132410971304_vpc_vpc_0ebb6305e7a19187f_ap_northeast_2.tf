resource "aws_flow_log" "fix_vpc_flow_logs_e91ccf361c" {
  vpc_id               = "vpc-0ebb6305e7a19187f"
  traffic_type         = "ALL"
  log_destination_type = "s3"
  log_destination      = "arn:aws:s3:::aws-cloudtrail-logs-132410971304-0971c04b"
}
