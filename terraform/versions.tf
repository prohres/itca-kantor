terraform {
  required_version = ">= 1.10"
  required_providers {
    aws = { source = "hashicorp/aws", version = "~> 6.0" }
  }

  backend "s3" {
    key = "itca-kantor/terraform.tfstate" # shared settings: backend.hcl
  }
}

# Credentials come from the environment (AWS_PROFILE=sketch-root); each account is reached
# through the role Organizations created in it, and allowed_account_ids pins the target.
provider "aws" {
  region              = "eu-central-1"
  allowed_account_ids = ["699353518928"] # sketch-dev: the app runtime
  assume_role {
    role_arn = "arn:aws:iam::699353518928:role/OrganizationAccountAccessRole"
  }
  default_tags {
    tags = { project = "kantor", env = "dev", managed-by = "terraform", repo = "prohres/itca-kantor" }
  }
}

provider "aws" {
  alias               = "admin"
  region              = "eu-central-1"
  allowed_account_ids = ["686337362279"] # sketch-admin: CI hub, holds the shared registry
  assume_role {
    role_arn = "arn:aws:iam::686337362279:role/OrganizationAccountAccessRole"
  }
  default_tags {
    tags = { project = "kantor", managed-by = "terraform", repo = "prohres/itca-kantor" }
  }
}
