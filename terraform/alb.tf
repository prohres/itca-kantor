resource "aws_lb" "app" {
  #checkov:skip=CKV_AWS_91:Access logs need a log bucket; revisit with a log-archive account
  #checkov:skip=CKV2_AWS_28:No WAF for the demo (cost)
  #checkov:skip=CKV_AWS_150:Deletion protection off on purpose: the env is scaled down / destroyed between sessions
  name                       = "${local.app}-${local.env}"
  load_balancer_type         = "application"
  security_groups            = [aws_security_group.alb.id]
  subnets                    = data.aws_subnets.default.ids
  drop_invalid_header_fields = true
}

resource "aws_lb_target_group" "app" {
  name                 = "${local.app}-${local.env}"
  port                 = local.container_port
  protocol             = "HTTP"
  target_type          = "ip" # Fargate tasks register by IP
  vpc_id               = data.aws_vpc.default.id
  deregistration_delay = 15 # static site, no long requests to drain; faster deploys

  health_check {
    path                = "/" # served by the bootstrap image and the app alike
    healthy_threshold   = 2
    unhealthy_threshold = 3
    interval            = 15
  }
}

resource "aws_lb_listener" "http" {
  #checkov:skip=CKV_AWS_2:HTTP only until there is a domain + ACM certificate (backlog)
  #checkov:skip=CKV_AWS_103:No TLS on this listener (see above)
  load_balancer_arn = aws_lb.app.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app.arn
  }
}
