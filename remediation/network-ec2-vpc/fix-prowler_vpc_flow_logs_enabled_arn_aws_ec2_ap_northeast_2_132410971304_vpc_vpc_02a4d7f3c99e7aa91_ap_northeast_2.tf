resource "aws_flow_log" "fix_vpc_flow_logs_aafb96cd94" {
  vpc_id               = "vpc-02a4d7f3c99e7aa91"
  traffic_type         = "ALL"
  log_destination_type = "s3"
  log_destination      = "arn:aws:s3:::aws-cloudtrail-logs-132410971304-0971c04b"
}
