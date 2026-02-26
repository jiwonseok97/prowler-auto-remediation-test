resource "aws_flow_log" "fix_vpc_flow_logs_9c761531b5" {
  vpc_id               = "vpc-0b504cb23a27665c8"
  traffic_type         = "ALL"
  log_destination_type = "s3"
  log_destination      = "arn:aws:s3:::aws-cloudtrail-logs-132410971304-0971c04b"
}
