resource "aws_flow_log" "fix_vpc_flow_logs_30818bd2c2" {
  vpc_id               = "vpc-05b030359c392a304"
  traffic_type         = "ALL"
  log_destination_type = "s3"
  log_destination      = "arn:aws:s3:::aws-cloudtrail-logs-132410971304-0971c04b"
}
