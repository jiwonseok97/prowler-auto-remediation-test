resource "aws_flow_log" "fix_vpc_flow_logs_31a3506763" {
  vpc_id               = "vpc-0ee76660afd5ade09"
  traffic_type         = "ALL"
  log_destination_type = "s3"
  log_destination      = "arn:aws:s3:::aws-cloudtrail-logs-132410971304-0971c04b"
}
