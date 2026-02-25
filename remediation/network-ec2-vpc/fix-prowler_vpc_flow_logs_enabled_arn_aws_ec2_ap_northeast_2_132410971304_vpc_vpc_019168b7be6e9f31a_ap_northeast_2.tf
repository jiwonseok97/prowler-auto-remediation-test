resource "aws_flow_log" "fix_vpc_flow_logs_d7219cd211" {
  vpc_id               = "vpc-019168b7be6e9f31a"
  traffic_type         = "ALL"
  log_destination_type = "s3"
  log_destination      = "arn:aws:s3:::aws-cloudtrail-logs-132410971304-0971c04b"
}
