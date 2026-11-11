terraform {
  required_version = ">= 1.10"
  required_providers {
    aws = { source = "hashicorp/aws", version = "~> 6.0" }
  }

  backend "s3" {
    key = "kantor-infra/terraform.tfstate" # shared settings: backend.hcl; bucket: backend.local.hcl locally, backend-bucket in CI
  }
}

# The whole stack lives in sketch-dev. Credentials come from the environment: CI already runs as
# kantor-tf-plan / kantor-tf-apply there; locally (AWS_PROFILE=sketch-root) assume_role_name hops in.
provider "aws" {
  region              = "eu-central-1"
  allowed_account_ids = [var.account_id]
  dynamic "assume_role" {
    for_each = var.assume_role_name == null ? [] : [var.assume_role_name]
    content {
      role_arn = "arn:aws:iam::${var.account_id}:role/${assume_role.value}"
    }
  }
  default_tags {
    tags = { project = "kantor", env = "dev", managed-by = "terraform", repo = "prohres/kantor-infra" }
  }
}
