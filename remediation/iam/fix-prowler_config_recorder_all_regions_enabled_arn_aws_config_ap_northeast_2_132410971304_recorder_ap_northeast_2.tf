resource "aws_config_configuration_recorder" "fix_config_recorder_7d3084496f" {
  name     = "default"
  role_arn = "arn:aws:iam::132410971304:role/aws-service-role/config.amazonaws.com/AWSServiceRoleForConfig"

  recording_group {
    all_supported                 = true
    include_global_resource_types = true
  }
}

resource "aws_config_delivery_channel" "fix_config_delivery_channel_7d3084496f" {
  name           = "default"
  s3_bucket_name = "aws-cloudtrail-logs-132410971304-0971c04b"
  depends_on     = [aws_config_configuration_recorder.fix_config_recorder_7d3084496f]
}

resource "aws_config_configuration_recorder_status" "fix_config_recorder_status_7d3084496f" {
  name       = "default"
  is_enabled = true
  depends_on = [aws_config_delivery_channel.fix_config_delivery_channel_7d3084496f]
}
