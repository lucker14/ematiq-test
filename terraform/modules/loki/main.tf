# Loki module - Deploy Loki components (Distributor, Ingester, Querier)

data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

# IAM role for Loki instances
resource "aws_iam_role" "loki" {
  name = "loki-role-${var.environment}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "loki_ssm" {
  role       = aws_iam_role.loki.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role_policy" "loki_storage" {
  name = "loki-storage-${var.environment}"
  role = aws_iam_role.loki.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:ListBucket",
          "s3:PutObject",
          "s3:GetObject",
          "s3:DeleteObject"
        ]
        Resource = [
          "arn:aws:s3:::loki-logs-${data.aws_caller_identity.current.account_id}-${var.environment}",
          "arn:aws:s3:::loki-logs-${data.aws_caller_identity.current.account_id}-${var.environment}/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "dynamodb:DescribeTable",
          "dynamodb:GetItem",
          "dynamodb:PutItem",
          "dynamodb:DeleteItem",
          "dynamodb:Query",
          "dynamodb:BatchGetItem",
          "dynamodb:BatchWriteItem"
        ]
        Resource = "arn:aws:dynamodb:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:table/loki-index-${var.environment}"
      }
    ]
  })
}

resource "aws_iam_instance_profile" "loki" {
  name = "loki-profile-${var.environment}"
  role = aws_iam_role.loki.name
}

# Launch template for Loki Distributor
resource "aws_launch_template" "loki_distributor" {
  name_prefix   = "loki-distributor-${var.environment}-"
  image_id      = data.aws_ami.amazon_linux.id
  instance_type = var.loki_distributor_instance_type

  iam_instance_profile {
    name = aws_iam_instance_profile.loki.name
  }

  network_interfaces {
    associate_public_ip_address = false
    security_groups             = [var.loki_security_group_id]
  }

  user_data = base64encode(templatefile("${path.module}/user-data.sh", {
    component      = "distributor"
    config         = var.loki_config
    aws_region     = var.aws_region
    aws_account_id = var.aws_account_id
    environment    = var.environment
    retention_days = var.retention_days
  }))

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name        = "loki-distributor-${var.environment}"
      Environment = var.environment
      Component   = "distributor"
    }
  }
}

# Launch template for Loki Ingester
resource "aws_launch_template" "loki_ingester" {
  name_prefix   = "loki-ingester-${var.environment}-"
  image_id      = data.aws_ami.amazon_linux.id
  instance_type = var.loki_ingester_instance_type

  iam_instance_profile {
    name = aws_iam_instance_profile.loki.name
  }

  block_device_mappings {
    device_name = "/dev/xvda"
    ebs {
      volume_size = var.loki_ingester_volume_size # For WAL and local chunk storage
      volume_type = "gp3"
    }
  }

  network_interfaces {
    associate_public_ip_address = false
    security_groups             = [var.loki_security_group_id]
  }

  user_data = base64encode(templatefile("${path.module}/user-data.sh", {
    component      = "ingester"
    config         = var.loki_config
    aws_region     = var.aws_region
    aws_account_id = var.aws_account_id
    environment    = var.environment
    retention_days = var.retention_days
  }))

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name        = "loki-ingester-${var.environment}"
      Environment = var.environment
      Component   = "ingester"
    }
  }
}

# Launch template for Loki Querier
resource "aws_launch_template" "loki_querier" {
  name_prefix   = "loki-querier-${var.environment}-"
  image_id      = data.aws_ami.amazon_linux.id
  instance_type = var.loki_querier_instance_type

  iam_instance_profile {
    name = aws_iam_instance_profile.loki.name
  }

  network_interfaces {
    associate_public_ip_address = false
    security_groups             = [var.loki_security_group_id]
  }

  user_data = base64encode(templatefile("${path.module}/user-data.sh", {
    component      = "querier"
    config         = var.loki_config
    aws_region     = var.aws_region
    aws_account_id = var.aws_account_id
    environment    = var.environment
    retention_days = var.retention_days
  }))

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name        = "loki-querier-${var.environment}"
      Environment = var.environment
      Component   = "querier"
    }
  }
}

# Auto Scaling Groups
resource "aws_autoscaling_group" "loki_distributor" {
  name                = "loki-distributor-${var.environment}"
  vpc_zone_identifier = var.private_subnet_ids
  min_size            = var.loki_distributor_min_size
  max_size            = var.loki_distributor_max_size
  desired_capacity    = var.loki_distributor_desired_capacity

  launch_template {
    id      = aws_launch_template.loki_distributor.id
    version = "$Latest"
  }

  target_group_arns = [aws_lb_target_group.loki_distributor.arn]

  tag {
    key                 = "Name"
    value               = "loki-distributor-${var.environment}"
    propagate_at_launch = true
  }

  tag {
    key                 = "Environment"
    value               = var.environment
    propagate_at_launch = true
  }
}

resource "aws_autoscaling_group" "loki_ingester" {
  name                = "loki-ingester-${var.environment}"
  vpc_zone_identifier = var.private_subnet_ids
  min_size            = var.loki_ingester_min_size
  max_size            = var.loki_ingester_max_size
  desired_capacity    = var.loki_ingester_desired_capacity

  launch_template {
    id      = aws_launch_template.loki_ingester.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "loki-ingester-${var.environment}"
    propagate_at_launch = true
  }

  tag {
    key                 = "Environment"
    value               = var.environment
    propagate_at_launch = true
  }

  tag {
    key                 = "Component"
    value               = "ingester"
    propagate_at_launch = true
  }
}

resource "aws_autoscaling_group" "loki_querier" {
  name                = "loki-querier-${var.environment}"
  vpc_zone_identifier = var.private_subnet_ids
  min_size            = var.loki_querier_min_size
  max_size            = var.loki_querier_max_size
  desired_capacity    = var.loki_querier_desired_capacity

  launch_template {
    id      = aws_launch_template.loki_querier.id
    version = "$Latest"
  }

  target_group_arns = [aws_lb_target_group.loki_querier.arn]

  tag {
    key                 = "Name"
    value               = "loki-querier-${var.environment}"
    propagate_at_launch = true
  }

  tag {
    key                 = "Environment"
    value               = var.environment
    propagate_at_launch = true
  }
}

# Network Load Balancer
resource "aws_lb" "loki" {
  name               = "loki-nlb-${var.environment}"
  internal           = true
  load_balancer_type = "network"
  subnets            = var.private_subnet_ids

  tags = {
    Name        = "loki-nlb-${var.environment}"
    Environment = var.environment
  }
}

resource "aws_lb_target_group" "loki_distributor" {
  name     = "loki-distributor-${var.environment}"
  port     = 3100
  protocol = "TCP"
  vpc_id   = var.vpc_id

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    protocol            = "HTTP"
    path                = "/ready"
    port                = "3100"
    interval            = 30
  }
}

resource "aws_lb_target_group" "loki_querier" {
  name     = "loki-querier-${var.environment}"
  port     = 3100
  protocol = "TCP"
  vpc_id   = var.vpc_id

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    protocol            = "HTTP"
    path                = "/ready"
    port                = "3100"
    interval            = 30
  }
}

resource "aws_lb_listener" "loki_distributor" {
  load_balancer_arn = aws_lb.loki.arn
  port              = "3100"
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.loki_distributor.arn
  }
}

resource "aws_lb_listener" "loki_querier" {
  load_balancer_arn = aws_lb.loki.arn
  port              = "3101"
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.loki_querier.arn
  }
}

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}