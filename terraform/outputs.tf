output "url" {
  description = "Public URL of the dev environment"
  value       = "http://${aws_lb.app.dns_name}"
}

output "ecr_repository_url" {
  description = "Registry the build job pushes to"
  value       = aws_ecr_repository.app.repository_url
}

output "deploy" {
  description = "Inputs for the deploy workflow"
  value = {
    role_arn       = aws_iam_role.deploy.arn
    cluster        = aws_ecs_cluster.app.name
    service        = aws_ecs_service.app.name
    task_family    = aws_ecs_task_definition.app.family
    container_name = local.container_name
  }
}
