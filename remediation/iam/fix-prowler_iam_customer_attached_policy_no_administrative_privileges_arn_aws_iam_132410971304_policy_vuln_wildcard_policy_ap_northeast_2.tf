resource "aws_iam_policy" "vuln-wildcard-policy_d8342c209e" {
  name        = "vuln-wildcard-policy"
  description = "Remediated policy with reduced permissions"
  policy      = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "iam:GetUser",
        "iam:GetUserPolicy",
        "iam:ListAttachedUserPolicies",
        "iam:ListGroupsForUser",
        "iam:ListUserPolicies",
        "iam:ListUsers"
      ],
      "Resource": [
        "arn:aws:iam::132410971304:user/*"
      ]
    }
  ]
}
EOF
}
