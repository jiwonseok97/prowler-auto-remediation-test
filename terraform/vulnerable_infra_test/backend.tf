terraform {
  backend "local" {
    path = "terraform-test-infra.tfstate"
  }
}
