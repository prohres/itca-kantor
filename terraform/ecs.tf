resource "aws_ecs_cluster" "app" {
  name = "${local.app}-${local.env}"
  setting {
    name  = "containerInsights"
    value = "disabled" # cost; service metrics in CloudWatch are enough for the demo
  }
}

resource "aws_cloudwatch_log_group" "app" {
  #checkov:skip=CKV_AWS_158:Default encryption is enough for access logs of a public site
  #checkov:skip=CKV_AWS_338:Short retention on purpose (demo, cost)
  name              = "/ecs/${local.app}-${local.env}"
  retention_in_days = 14
}

data "aws_iam_policy_document" "ecs_tasks_trust" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

# Used by the ECS agent to pull the image and write logs; the app itself needs no AWS access
resource "aws_iam_role" "execution" {
  name               = "${local.app}-${local.env}-execution"
  assume_role_policy = data.aws_iam_policy_document.ecs_tasks_trust.json
}

resource "aws_iam_role_policy_attachment" "execution" {
  role       = aws_iam_role.execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_ecs_task_definition" "app" {
  family                   = "${local.app}-${local.env}"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = 256
  memory                   = 512
  execution_role_arn       = aws_iam_role.execution.arn

  container_definitions = jsonencode([{
    name                   = local.container_name
    image                  = local.bootstrap_image
    essential              = true
    readonlyRootFilesystem = false # nginx writes its cache and pid; revisit with tmpfs mounts
    portMappings           = [{ containerPort = local.container_port, protocol = "tcp" }]
    logConfiguration = {
      logDriver = "awslogs"
      options = {
        awslogs-group         = aws_cloudwatch_log_group.app.name
        awslogs-region        = "eu-central-1"
        awslogs-stream-prefix = local.container_name
      }
    }
  }])
}

resource "aws_ecs_service" "app" {
  name                              = local.app
  cluster                           = aws_ecs_cluster.app.id
  task_definition                   = aws_ecs_task_definition.app.arn
  desired_count                     = var.desired_count
  launch_type                       = "FARGATE"
  health_check_grace_period_seconds = 30

  network_configuration {
    subnets          = data.aws_subnets.default.ids
    security_groups  = [aws_security_group.tasks.id]
    assign_public_ip = true # no NAT in the default VPC: the public IP is the way out to the registry
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.app.arn
    container_name   = local.container_name
    container_port   = local.container_port
  }

  deployment_circuit_breaker {
    enable   = true
    rollback = true # a deploy that never gets healthy goes back to the last good task definition
  }

  lifecycle {
    ignore_changes = [task_definition] # CI registers new revisions; Terraform would roll them back
  }

  depends_on = [aws_lb_listener.http]
}
