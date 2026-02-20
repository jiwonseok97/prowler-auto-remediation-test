resource "aws_flow_log" "fix_vpc_flow_logs_2d5ad66cfc" {
  vpc_id               = "vpc-0d7d5c421a1cea550"
  traffic_type         = "ALL"
  log_destination_type = "s3"
  log_destination      = "arn:aws:s3:::aws-cloudtrail-logs-132410971304-0971c04b"
}
