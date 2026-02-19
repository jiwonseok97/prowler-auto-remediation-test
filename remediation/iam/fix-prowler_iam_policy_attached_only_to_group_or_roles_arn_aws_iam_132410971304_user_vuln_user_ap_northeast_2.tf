resource "aws_iam_user_policy_attachment" "vuln-user-policy-attachment_dd3b137ea3" {
  user       = "vuln-user"
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}
