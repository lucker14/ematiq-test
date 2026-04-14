# Configuration Guide

This document explains the Terraform configuration, deployment options, and important toggles for this Loki logging stack.

## Terraform files

- `terraform/backend.tf`
  - Contains the S3 backend configuration for state storage.
  - Replace `YOUR-TFSTATE-BUCKET`, `YOUR-TFSTATE-LOCK-TABLE`, and the region with your own settings.

- `terraform/variables.tf.example`
  - Example variable values for a dev environment.
  - Copy this file to `terraform/variables.tf` and customize values for your account.

- `terraform/dev.tfvars`
  - Example variable overrides for development.
  - Use this file to keep environment-specific settings separate from the main variable file.

- `terraform/variables.tf`
  - Root-level Terraform variables used by all modules.
  - Contains defaults and TODO notes for values that should be changed.

## Important variable groups

### General deployment settings

- `aws_region`: AWS region for resource deployment.
- `environment`: Logical environment name, such as `dev`, `staging`, or `prod`.
- `vpc_cidr`: CIDR range for the VPC.
- `public_subnets`: Public subnet CIDRs.
- `private_subnets`: Private subnet CIDRs.
- `availability_zones`: AZs to use.
- `retention_days`: Default retention days for logs and Loki storage.

### Fluent Bit / FireLens toggles

- `enable_ecs`
  - When `true`, the ECS FireLens sample resources and supporting IAM roles are created.
  - When `false`, ECS FireLens resources are skipped.

- `enable_ec2_agent`
  - When `true`, a standalone EC2 Fluent Bit launch template is created.
  - When `false`, the EC2 Fluent Bit agent is not deployed.

- `enable_example_ecs_task`
  - When `true` and `enable_ecs = true`, a sample ECS task definition with FireLens is deployed.
  - Recommended for testing and as a template only. Do not use it as your production app definition.

- `ecs_firelens_log_group_retention`
  - Retention days for the FireLens router CloudWatch group.
  - Keep this small to minimize CloudWatch cost, because only the router container logs are sent there.

### S3 lifecycle settings

- `transition_to_ia_days`: Days before S3 objects move to `STANDARD_IA`.
- `transition_to_glacier_days`: Days before S3 objects move to `GLACIER`.
- `expiration_days`: Days before S3 objects are deleted.

These are fully configurable. Example recommended defaults:
- `transition_to_ia_days = 30`
- `transition_to_glacier_days = 90`
- `expiration_days = 365`

### Loki sizing variables

#### Distributor
- `loki_distributor_instance_type`
- `loki_distributor_min_size`
- `loki_distributor_desired_capacity`
- `loki_distributor_max_size`

#### Ingester
- `loki_ingester_instance_type`
- `loki_ingester_volume_size`
- `loki_ingester_min_size`
- `loki_ingester_desired_capacity`
- `loki_ingester_max_size`

#### Querier
- `loki_querier_instance_type`
- `loki_querier_min_size`
- `loki_querier_desired_capacity`
- `loki_querier_max_size`

These values are used by the Loki module to size EC2 instances and autoscaling groups. Adjust them to match expected ingestion volume and query load.

## Optional components

The repository supports these optional log collection modes:

- ECS FireLens sample deployment (`enable_ecs`, `enable_example_ecs_task`)
- Standalone EC2 Fluent Bit agent (`enable_ec2_agent`)

You can deploy just the pieces you need by setting these flags in `terraform/variables.tf` or `terraform/dev.tfvars`.

## Useful workflows

### Validate before deploy

```bash
bash scripts/validate.sh
```

### Deploy

```bash
chmod +x scripts/deploy.sh
./scripts/deploy.sh
```

### Test ingestion

```bash
./scripts/test-logs.sh <loki-endpoint>
```

## Notes

- The sample ECS FireLens task is provided as an example only; real ECS apps should be configured with `awsfirelens` on the application container.
- CloudWatch usage is intentionally minimized. The only CloudWatch log group created is for the FireLens router container itself, not for application log storage.
- Use the backend configuration in `terraform/backend.tf` to manage state centrally and enable locking.
- Customize `terraform/dev.tfvars` or create your own environment-specific tfvars file.
