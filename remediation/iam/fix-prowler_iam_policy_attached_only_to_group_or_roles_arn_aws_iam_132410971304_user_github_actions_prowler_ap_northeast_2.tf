resource "aws_iam_user_policy_attachment" "github-actions-prowler_policy_attachment_0a05d17762" {
  user       = "github-actions-prowler"
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}
