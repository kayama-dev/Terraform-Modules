# store the terraform state file in s3
terraform {
  backend "s3" {
    bucket    = "s3-state-remote-file"
    key       = "jupiter-website-ecs.tfstate"
    region    = "us-east-1"
    profile   = "Terraform-user"
  }
}