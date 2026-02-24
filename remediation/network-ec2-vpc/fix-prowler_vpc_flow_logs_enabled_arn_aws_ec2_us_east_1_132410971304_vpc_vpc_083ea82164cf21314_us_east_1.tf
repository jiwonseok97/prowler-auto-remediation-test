resource "aws_flow_log" "fix_vpc_flow_logs_b7dc49157a" {
  vpc_id               = "vpc-083ea82164cf21314"
  traffic_type         = "ALL"
  log_destination_type = "s3"
  log_destination      = "arn:aws:s3:::aws-cloudtrail-logs-132410971304-0971c04b"
}
