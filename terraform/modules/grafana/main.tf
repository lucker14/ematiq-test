# Grafana module - Deploy Grafana for log visualization

data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

resource "aws_launch_template" "grafana" {
  name_prefix   = "grafana-${var.environment}-"
  image_id      = data.aws_ami.amazon_linux.id
  instance_type = "t3.large"

  network_interfaces {
    associate_public_ip_address = false
    security_groups             = [var.grafana_security_group_id]
  }

  user_data = base64encode(templatefile("${path.module}/user-data.sh", {
    loki_endpoint = var.loki_endpoint
  }))

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name        = "grafana-${var.environment}"
      Environment = var.environment
    }
  }
}

resource "aws_autoscaling_group" "grafana" {
  name                = "grafana-${var.environment}"
  vpc_zone_identifier = var.private_subnet_ids
  min_size            = 1
  max_size            = 2
  desired_capacity    = 1

  launch_template {
    id      = aws_launch_template.grafana.id
    version = "$Latest"
  }

  target_group_arns = [aws_lb_target_group.grafana.arn]

  tag {
    key                 = "Name"
    value               = "grafana-${var.environment}"
    propagate_at_launch = true
  }

  tag {
    key                 = "Environment"
    value               = var.environment
    propagate_at_launch = true
  }
}

resource "aws_lb" "grafana" {
  name               = "grafana-alb-${var.environment}"
  internal           = false
  load_balancer_type = "application"
  subnets            = var.public_subnet_ids # Assuming public for access

  security_groups = [var.grafana_security_group_id]

  tags = {
    Name        = "grafana-alb-${var.environment}"
    Environment = var.environment
  }
}

resource "aws_lb_target_group" "grafana" {
  name     = "grafana-${var.environment}"
  port     = 3000
  protocol = "HTTP"
  vpc_id   = var.vpc_id

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    protocol            = "HTTP"
    path                = "/api/health"
    port                = "3000"
    interval            = 30
  }
}

resource "aws_lb_listener" "grafana" {
  load_balancer_arn = aws_lb.grafana.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.grafana.arn
  }
}
