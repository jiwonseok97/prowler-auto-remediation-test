terraform {
  # Partial backend config – bucket/key/region supplied via -backend-config in CI
  backend "s3" {}
}
