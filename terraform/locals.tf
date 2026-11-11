locals {
  app            = "kantor"
  env            = "dev"
  container_name = "web"
  container_port = 8080 # nginx-unprivileged listens on 8080 (non-root can't bind 80)

  # Placeholder for the first apply only: CI owns the image from then on (ignore_changes below)
  bootstrap_image = "nginxinc/nginx-unprivileged:stable-alpine"

  # Owned by sketch-infra (ci/): CI may create and change this stack's roles only with it attached
  boundary_arn = "arn:aws:iam::${var.account_id}:policy/kantor-stack-boundary"
}
