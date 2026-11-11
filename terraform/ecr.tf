# One registry for every environment, in the CI hub: environments pull the same digest
resource "aws_ecr_repository" "app" {
  #checkov:skip=CKV_AWS_136:AES256 on purpose (no KMS cost); access is limited by IAM
  provider             = aws.admin
  name                 = local.app
  image_tag_mutability = "IMMUTABLE" # a tag can never point to another image

  image_scanning_configuration {
    scan_on_push = true # basic scan; CI also runs trivy before the push
  }

  encryption_configuration {
    encryption_type = "AES256"
  }
}

resource "aws_ecr_lifecycle_policy" "app" {
  provider   = aws.admin
  repository = aws_ecr_repository.app.name
  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Promoted images: keep the last 10 for rollback"
        selection    = { tagStatus = "tagged", tagPrefixList = ["prod-"], countType = "imageCountMoreThan", countNumber = 10 }
        action       = { type = "expire" }
      },
      {
        rulePriority = 2
        description  = "Untagged layers left by failed pushes"
        selection    = { tagStatus = "untagged", countType = "sinceImagePushed", countUnit = "days", countNumber = 1 }
        action       = { type = "expire" }
      },
      {
        rulePriority = 3
        description  = "Every other build: keep the last 20"
        selection    = { tagStatus = "any", countType = "imageCountMoreThan", countNumber = 20 }
        action       = { type = "expire" }
      },
    ]
  })
}

# Workload accounts pull; pushing stays with the CI role in this account
data "aws_iam_policy_document" "ecr_pull" {
  statement {
    sid     = "WorkloadPull"
    actions = ["ecr:BatchGetImage", "ecr:GetDownloadUrlForLayer", "ecr:BatchCheckLayerAvailability"]
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${var.dev_account_id}:root"] # the account still has to grant it in IAM
    }
  }
}

resource "aws_ecr_repository_policy" "app" {
  provider   = aws.admin
  repository = aws_ecr_repository.app.name
  policy     = data.aws_iam_policy_document.ecr_pull.json
}
