# IAM remediation snippet
resource "aws_iam_account_password_policy" "secure" {
  minimum_password_length        = 14
  require_lowercase_characters   = true
  require_uppercase_characters   = true
  require_numbers                = true
  require_symbols                = true
  allow_users_to_change_password = true
  max_password_age               = 90
  hard_expiry                    = false
}

resource "aws_iam_user_policy" "least_privilege_example" {
  name = "least-privilege-example"
  user = "vuln-user"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["s3:ListAllMyBuckets"]
      Resource = "*"
    }]
  })
}
