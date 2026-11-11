# Role the deploy job chains into from gha-app-deploy-dev (sketch-infra ci/). It can roll out a new
# task definition revision of this one service, nothing else.
data "aws_iam_policy_document" "deploy_trust" {
  statement {
    actions = ["sts:AssumeRole", "sts:TagSession"]
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${var.admin_account_id}:role/gha-app-deploy-dev"] # one role, not the account
    }
  }
}

resource "aws_iam_role" "deploy" {
  name                 = "app-deploy"
  assume_role_policy   = data.aws_iam_policy_document.deploy_trust.json
  permissions_boundary = local.boundary_arn
}

data "aws_iam_policy_document" "deploy" {
  statement {
    sid       = "TaskDefinitions"
    actions   = ["ecs:DescribeTaskDefinition", "ecs:RegisterTaskDefinition"] # no resource-level scoping
    resources = ["*"]
  }
  statement {
    sid       = "RollOutThisService"
    actions   = ["ecs:UpdateService", "ecs:DescribeServices"]
    resources = [aws_ecs_service.app.id]
  }
  statement {
    sid       = "FindTheSmokeUrl" # service -> target group -> load balancer DNS name
    actions   = ["elasticloadbalancing:DescribeTargetGroups", "elasticloadbalancing:DescribeLoadBalancers"]
    resources = ["*"] # Describe calls have no resource-level scoping
  }
  statement {
    sid       = "PassOnlyTheExecutionRole"
    actions   = ["iam:PassRole"]
    resources = [aws_iam_role.execution.arn]
    condition {
      test     = "StringEquals"
      variable = "iam:PassedToService"
      values   = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy" "deploy" {
  name   = "deploy-service"
  role   = aws_iam_role.deploy.id
  policy = data.aws_iam_policy_document.deploy.json
}
