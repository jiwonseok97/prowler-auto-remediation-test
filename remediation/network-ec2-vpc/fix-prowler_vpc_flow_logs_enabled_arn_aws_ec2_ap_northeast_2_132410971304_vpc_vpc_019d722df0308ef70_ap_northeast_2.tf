resource "aws_flow_log" "fix_vpc_flow_logs_9a6a3894df" {
  vpc_id               = "vpc-019d722df0308ef70"
  traffic_type         = "ALL"
  log_destination_type = "s3"
  log_destination      = "arn:aws:s3:::aws-cloudtrail-logs-132410971304-0971c04b"
}
