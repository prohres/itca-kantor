# Registry of this environment, inside the stack: destroyed with it (images too), rebuilt by CI after up
resource "aws_ecr_repository" "app" {
  #checkov:skip=CKV_AWS_136:AES256 on purpose (no KMS cost); access is limited by IAM
  name                 = local.app
  image_tag_mutability = "IMMUTABLE" # a tag can never point to another image
  force_delete         = true        # down removes the images as well; otherwise destroy fails on a non-empty repo

  image_scanning_configuration {
    scan_on_push = true # basic scan; CI also runs trivy before the push
  }

  encryption_configuration {
    encryption_type = "AES256"
  }
}

resource "aws_ecr_lifecycle_policy" "app" {
  repository = aws_ecr_repository.app.name
  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Untagged layers left by failed pushes"
        selection    = { tagStatus = "untagged", countType = "sinceImagePushed", countUnit = "days", countNumber = 1 }
        action       = { type = "expire" }
      },
      {
        rulePriority = 2
        description  = "Every other build: keep the last 20"
        selection    = { tagStatus = "any", countType = "imageCountMoreThan", countNumber = 20 }
        action       = { type = "expire" }
      },
    ]
  })
}

# The build role in the CI hub pushes across accounts; tasks here pull through the execution role (IAM)
data "aws_iam_policy_document" "ecr_push" {
  statement {
    sid = "CiHubBuildPush"
    actions = ["ecr:BatchCheckLayerAvailability", "ecr:InitiateLayerUpload", "ecr:UploadLayerPart",
      "ecr:CompleteLayerUpload", "ecr:PutImage", "ecr:BatchGetImage", "ecr:DescribeImages",
    "ecr:DescribeRepositories"]
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${var.admin_account_id}:role/gha-app-build"] # one role, not the account
    }
  }
}

resource "aws_ecr_repository_policy" "app" {
  repository = aws_ecr_repository.app.name
  policy     = data.aws_iam_policy_document.ecr_push.json
}
