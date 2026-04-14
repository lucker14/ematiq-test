# Fluent Bit module - Log collection configurations

data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

# ECS Task Definition with FireLens
# TODO: this is a sample task definition only. Real ECS deployments need a cluster/service and may use this as a template.
resource "aws_ecs_task_definition" "app_with_firelens" {
  count                    = var.enable_ecs && var.enable_example_ecs_task ? 1 : 0
  family                   = "app-with-firelens-${var.environment}"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "512"
  memory                   = "1024"
  execution_role_arn       = aws_iam_role.ecs_execution[0].arn
  task_role_arn            = aws_iam_role.ecs_task[0].arn

  container_definitions = jsonencode([
    {
      name      = "app"
      image     = "nginx:latest" # TODO: replace with your actual application image
      cpu       = 256
      memory    = 512
      essential = true

      portMappings = [
        {
          containerPort = 80
          hostPort      = 80
        }
      ]

      logConfiguration = {
        logDriver = "awsfirelens"
        options = {
          Name        = "loki"
          Loki_URL    = "http://${var.loki_endpoint}:3100/loki/api/v1/push"
          labels      = "service=app,env=${var.environment}"
          label_keys  = "container_name,ecs_task_definition_family"
          remove_keys = "docker_id,source"
          Retry_Limit = "5"
          Buffer_Size = "32k"
          tenant      = "default"
        }
      }
    },
    {
      name      = "log_router"
      image     = "amazon/aws-for-fluent-bit:latest"
      cpu       = 128
      memory    = 256
      essential = true

      firelensConfiguration = {
        type = "fluentbit"
        options = {
          enable-ecs-log-metadata = "true"
        }
      }

      logConfiguration = {
        # TODO: FireLens on Fargate still requires awslogs for the router container itself.
        # Actual application logs are sent to Loki; this CloudWatch group is only control-plane logging.
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.firelens[0].name
          awslogs-region        = data.aws_region.current.name
          awslogs-stream-prefix = "ecs"
        }
      }
    }
  ])
}

# CloudWatch log group for FireLens logs
resource "aws_cloudwatch_log_group" "firelens" {
  count             = var.enable_ecs ? 1 : 0
  name              = "/ecs/firelens-${var.environment}"
  retention_in_days = var.ecs_firelens_log_group_retention
}

# IAM roles for ECS
resource "aws_iam_role" "ecs_execution" {
  count = var.enable_ecs ? 1 : 0
  name  = "ecs-execution-role-${var.environment}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_execution" {
  count      = var.enable_ecs ? 1 : 0
  role       = aws_iam_role.ecs_execution[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role" "ecs_task" {
  count = var.enable_ecs ? 1 : 0
  name  = "ecs-task-role-${var.environment}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

# Launch template for EC2 with Fluent Bit
resource "aws_launch_template" "ec2_fluent_bit" {
  count         = var.enable_ec2_agent ? 1 : 0
  name_prefix   = "ec2-fluent-bit-${var.environment}-"
  image_id      = data.aws_ami.amazon_linux.id
  instance_type = "t3.micro"

  user_data = base64encode(templatefile("${path.module}/fluent-bit-ec2.sh", {
    loki_endpoint = var.loki_endpoint
    environment   = var.environment
  }))

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name        = "ec2-fluent-bit-${var.environment}"
      Environment = var.environment
    }
  }
}

data "aws_region" "current" {}