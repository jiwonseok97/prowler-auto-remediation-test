resource "aws_flow_log" "fix_vpc_flow_logs_92434b8089" {
  vpc_id               = "vpc-018685e78ded4212d"
  traffic_type         = "ALL"
  log_destination_type = "s3"
  log_destination      = "arn:aws:s3:::aws-cloudtrail-logs-132410971304-0971c04b"
}
