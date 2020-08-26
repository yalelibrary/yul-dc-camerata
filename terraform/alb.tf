# alb.tf

resource "aws_alb" "main" {
  name            = "${var.cluster_name}-load-balancer"
  subnets         = aws_subnet.public.*.id
  security_groups = [aws_security_group.lb.id]
}

resource "aws_alb_target_group" "mft" {
  name                 = "${var.cluster_name}-mft-target-group"
  deregistration_delay = 30
  port                 = var.app_ports["mft"]
  protocol             = "HTTP"
  vpc_id               = aws_vpc.main.id
  target_type          = "ip"

  health_check {
    healthy_threshold   = "3"
    interval            = "30"
    protocol            = "HTTP"
    matcher             = "200"
    timeout             = "3"
    path                = "/"
    unhealthy_threshold = "2"
  }
}

resource "aws_alb_target_group" "image" {
  name                 = "${var.cluster_name}-image-target-group"
  deregistration_delay = 30
  port                 = var.app_ports["image"]
  protocol             = "HTTP"
  vpc_id               = aws_vpc.main.id
  target_type          = "ip"

  health_check {
    healthy_threshold   = "3"
    interval            = "30"
    protocol            = "HTTP"
    matcher             = "200"
    timeout             = "3"
    path                = "/"
    unhealthy_threshold = "2"
  }
}

resource "aws_alb_target_group" "blacklight" {
  name                 = "${var.cluster_name}-blacklight-target-group"
  deregistration_delay = 30
  port                 = var.app_ports["blacklight"]
  protocol             = "HTTP"
  vpc_id               = aws_vpc.main.id
  target_type          = "ip"

  health_check {
    healthy_threshold   = "3"
    interval            = "30"
    protocol            = "HTTP"
    matcher             = "200,401"
    timeout             = "60"
    path                = "/"
    unhealthy_threshold = "2"
  }
}
resource "aws_alb_target_group" "mgmt" {
  name                 = "${var.cluster_name}-mgmt-target-group"
  deregistration_delay = 30
  port                 = var.app_ports["mgmt"]
  protocol             = "HTTP"
  vpc_id               = aws_vpc.main.id
  target_type          = "ip"

  health_check {
    healthy_threshold   = "3"
    interval            = "30"
    protocol            = "HTTP"
    matcher             = "200"
    timeout             = "60"
    path                = "/"
    unhealthy_threshold = "2"
  }
}

# Redirect all traffic from the ALB to the target group
resource "aws_alb_listener" "http" {
  load_balancer_arn = aws_alb.main.id
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "redirect"
    redirect {
      port        = 443
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

# Redirect all traffic from the ALB to the target group
resource "aws_alb_listener" "https" {
  load_balancer_arn = aws_alb.main.id
  port              = 443
  protocol          = "HTTPS"

  default_action {
    target_group_arn = aws_alb_target_group.blacklight.id
    type             = "forward"
  }
}

resource "aws_alb_listener_rule" "images_rule" {
  listener_arn = aws_alb_listener.https.arn
  priority     = 70
  action {
    type = "forward"
    forward {
      target_group {
        arn = aws_alb_target_group.mgmt.arn
      }
    }
  }
  condition {
    path_pattern {
      values = ["/iiif/*"]
    }
  }
}
resource "aws_alb_listener_rule" "mft_rule" {
  listener_arn = aws_alb_listener.https.arn
  priority     = 80
  action {
    type = "forward"
    forward {
      target_group {
        arn = aws_alb_target_group.mgmt.arn
      }
    }
  }
  condition {
    path_pattern {
      values = ["/manifests/*"]
    }
  }
}
resource "aws_alb_listener_rule" "mgmt" {
  listener_arn = aws_alb_listener.https.arn
  priority     = 90
  action {
    type = "forward"
    forward {
      target_group {
        arn = aws_alb_target_group.mgmt.arn
      }
    }
  }
  condition {
    path_pattern {
      values = ["/management/*"]
    }
  }
}

resource "alb_listener_certificate" "star_dce" {
  listener_arn    = aws_alb_listener.https.arn
  certificate_arn = aws_acm_certificate.star_dce.arn

}

resource "aws_acm_certificate" "star_dce" {
  statuses = ["ISSUED"]
  domain   = "*.curationexperts.com"

}
