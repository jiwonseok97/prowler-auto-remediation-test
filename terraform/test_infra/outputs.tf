output "vulnerable_bucket" {
  value = aws_s3_bucket.vuln_bucket.bucket
}

output "vulnerable_security_group" {
  value = aws_security_group.vuln_sg.id
}

output "cloudtrail_name" {
  value = aws_cloudtrail.vuln_trail.name
}
