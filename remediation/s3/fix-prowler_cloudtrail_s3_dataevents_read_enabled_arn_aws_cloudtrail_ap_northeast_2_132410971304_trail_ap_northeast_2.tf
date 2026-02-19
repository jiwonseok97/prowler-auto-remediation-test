resource "aws_cloudtrail" "ap-northeast-2_21ff33774c" {
  name                          = "ap-northeast-2"
  s3_bucket_name                = "my-cloudtrail-bucket"
  s3_key_prefix                 = "cloudtrail"
  is_multi_region_trail         = true
  include_global_service_events = true
  enable_log_file_validation    = true

  event_selector {
    read_write_type           = "All"
    include_management_events = true

    data_resource {
      type   = "AWS::S3::Object"
      values = ["arn:aws:s3:::"]
    }
  }
}
