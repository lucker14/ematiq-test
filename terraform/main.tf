# Main Terraform configuration for Loki-based logging system
# This sets up the core infrastructure for log aggregation in AWS

terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

data "aws_caller_identity" "current" {}

# Include modules
module "networking" {
  source = "./modules/networking"

  vpc_cidr           = var.vpc_cidr
  public_subnets     = var.public_subnets
  private_subnets    = var.private_subnets
  availability_zones = var.availability_zones
  environment        = var.environment
}

module "storage" {
  source = "./modules/storage"

  environment                = var.environment
  retention_days             = var.retention_days
  transition_to_ia_days      = var.transition_to_ia_days
  transition_to_glacier_days = var.transition_to_glacier_days
  expiration_days            = var.expiration_days
}

module "loki" {
  source = "./modules/loki"

  vpc_id                            = module.networking.vpc_id
  private_subnet_ids                = module.networking.private_subnet_ids
  loki_security_group_id            = module.networking.loki_security_group_id
  loki_config                       = var.loki_config
  environment                       = var.environment
  retention_days                    = var.retention_days
  aws_region                        = var.aws_region
  aws_account_id                    = data.aws_caller_identity.current.account_id
  loki_distributor_instance_type    = var.loki_distributor_instance_type
  loki_distributor_min_size         = var.loki_distributor_min_size
  loki_distributor_desired_capacity = var.loki_distributor_desired_capacity
  loki_distributor_max_size         = var.loki_distributor_max_size
  loki_ingester_instance_type       = var.loki_ingester_instance_type
  loki_ingester_volume_size         = var.loki_ingester_volume_size
  loki_ingester_min_size            = var.loki_ingester_min_size
  loki_ingester_desired_capacity    = var.loki_ingester_desired_capacity
  loki_ingester_max_size            = var.loki_ingester_max_size
  loki_querier_instance_type        = var.loki_querier_instance_type
  loki_querier_min_size             = var.loki_querier_min_size
  loki_querier_desired_capacity     = var.loki_querier_desired_capacity
  loki_querier_max_size             = var.loki_querier_max_size

  depends_on = [module.storage]
}

module "grafana" {
  source = "./modules/grafana"

  vpc_id                    = module.networking.vpc_id
  private_subnet_ids        = module.networking.private_subnet_ids
  public_subnet_ids         = module.networking.public_subnet_ids
  grafana_security_group_id = module.networking.grafana_security_group_id
  loki_endpoint             = module.loki.loki_endpoint
  environment               = var.environment
}

module "fluent_bit" {
  source = "./modules/fluent_bit"

  loki_endpoint = module.loki.loki_endpoint
  environment   = var.environment

  enable_ecs                       = var.enable_ecs
  enable_ec2_agent                 = var.enable_ec2_agent
  enable_example_ecs_task          = var.enable_example_ecs_task
  ecs_firelens_log_group_retention = var.ecs_firelens_log_group_retention
}