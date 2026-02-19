resource "aws_flow_log" "fix_vpc_flow_logs_b4bf9a5c39" {
  vpc_id               = "vpc-00673f54bd91d54bf"
  traffic_type         = "ALL"
  log_destination_type = "s3"
  log_destination      = "arn:aws:s3:::aws-cloudtrail-logs-132410971304-0971c04b"
}
