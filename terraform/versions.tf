terraform {
  required_version = ">= 1.10"
  required_providers {
    aws = { source = "hashicorp/aws", version = "~> 6.0" }
  }

  backend "s3" {
    key = "kantor-infra/terraform.tfstate" # shared settings: backend.hcl + backend.local.hcl (bucket)
  }
}

# Credentials come from the environment (AWS_PROFILE=sketch-root); each account is reached
# through the role Organizations created in it, and allowed_account_ids pins the target.
# Account ids come from accounts.auto.tfvars (not in git: the repo is public).
provider "aws" {
  region              = "eu-central-1"
  allowed_account_ids = [var.dev_account_id] # sketch-dev: the app runtime
  assume_role {
    role_arn = "arn:aws:iam::${var.dev_account_id}:role/OrganizationAccountAccessRole"
  }
  default_tags {
    tags = { project = "kantor", env = "dev", managed-by = "terraform", repo = "prohres/kantor-infra" }
  }
}

provider "aws" {
  alias               = "admin"
  region              = "eu-central-1"
  allowed_account_ids = [var.admin_account_id] # sketch-admin: CI hub, holds the shared registry
  assume_role {
    role_arn = "arn:aws:iam::${var.admin_account_id}:role/OrganizationAccountAccessRole"
  }
  default_tags {
    tags = { project = "kantor", managed-by = "terraform", repo = "prohres/kantor-infra" }
  }
}
