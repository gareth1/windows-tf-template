#######################################
# Terraform internal settings

# Terraform config
terraform {
  backend "s3" {
    bucket   = "hootsuite-terraform"
    key      = "states/it-template/terraform.tfstate"
    region   = "us-east-1"
    role_arn = "arn:aws:iam::${var.terraform_backend_account_id}:role/terraform-resource-access"
  }
}

# Provider configurations
provider "aws" {
  region = var.region

  assume_role {
    role_arn     = "arn:aws:iam::${var.terraform_role_account_id}:role/terraform-resource-access"
    session_name = var.atlantis_user
  }
}

# Atlantis settings
variable "atlantis_user" {
  description = "GitHub username of who is running the Atlantis command"
  type        = string
  default     = "atlantis_user"
}
