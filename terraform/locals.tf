locals {
  app            = "kantor"
  env            = "dev"
  container_name = "web"
  container_port = 8080 # nginx-unprivileged listens on 8080 (non-root can't bind 80)

  # Placeholder for the first apply only: CI owns the image from then on (ignore_changes below)
  bootstrap_image = "nginxinc/nginx-unprivileged:stable-alpine"
}
