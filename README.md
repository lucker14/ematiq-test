# Loki-based Logging System for AWS

This project implements a cost-effective, scalable logging solution for AWS using Loki, Fluent Bit, and Grafana. It replaces CloudWatch Logs with a more efficient alternative that addresses the pain points of expensive ingestion, limited cross-service search, and lack of custom tagging.

## 🎯 Goals

The system aims to:
- **Collect logs** from AWS ECS (Docker containers), EC2 instances (syslog, nginx, etc.), external servers, and Kubernetes clusters
- **Scale to >5TB daily** log volume with production-grade reliability
- **Provide UI access** via Grafana with LogQL query language for grep-like searches and fast time-based queries
- **Offer CLI access** through logcli for programmatic log retrieval
- **Be cost-effective** - estimated 40-50% savings compared to CloudWatch Logs at 5TB/day scale
- **Follow industry standards** using CNCF-graduated Loki project

## 🏗️ Architecture

```
Log Sources → Fluent Bit Collectors → Loki Distributor → Ingesters → S3 Storage + DynamoDB Index
                                      ↓
                            Querier ← Grafana UI + logcli
```

### Components

| Component | Purpose | AWS Service |
|-----------|---------|-------------|
| **Fluent Bit** | Lightweight log forwarder | ECS sidecar, EC2 agent |
| **Loki Distributor** | Log ingestion & routing | EC2 ASG behind NLB |
| **Loki Ingesters** | Process & store logs | EC2 ASG with EBS |
| **Loki Queriers** | Handle queries | EC2 ASG with caching |
| **Storage** | Persistent log data | S3 + DynamoDB |
| **Grafana** | Visualization & queries | EC2 with ALB |

## 📁 Project Structure

```
.
├── terraform/                 # Infrastructure as Code
│   ├── backend.tf            # Terraform backend configuration
│   ├── main.tf               # Root configuration
│   ├── variables.tf          # Global variables for deployment
│   ├── variables.tf.example  # Example variable values
│   ├── dev.tfvars            # Example dev variable file
│   ├── outputs.tf            # Output values
│   └── modules/              # Reusable modules
│       ├── networking/       # VPC, subnets, security groups
│       ├── storage/          # S3 bucket, DynamoDB table
│       ├── loki/             # Loki deployment (Distributor, Ingesters, Queriers)
│       ├── grafana/          # Grafana deployment
│       └── fluent_bit/       # Log collection configurations
├── scripts/                   # Deployment and utility scripts
│   ├── deploy.sh             # Main deployment script
│   ├── test-logs.sh          # Log ingestion test script
│   └── validate.sh           # Terraform validation helper
├── docs/                      # Documentation and configuration guides
│   ├── fluentbit-quickstart.md
│   └── interview-prep.md
└── README.md                 # This file
```

## 🚀 Deployment

### Prerequisites

- AWS account with appropriate permissions
- Terraform >= 1.0
- AWS CLI configured

### Steps

1. **Clone and configure:**
   ```bash
   git clone <repository>
   cd ematiq-test
   cp terraform/variables.tf.example terraform/variables.tf
   cp terraform/dev.tfvars terraform/local.tfvars  # optional, using dev defaults
   ```

   - Update `terraform/variables.tf` with your AWS account, region, VPC CIDRs, and Loki configuration.
   - Update `terraform/backend.tf` with your S3 backend bucket, key path, DynamoDB lock table, and region.

2. **Validate configuration:**
   ```bash
   bash scripts/validate.sh
   ```

3. **Deploy infrastructure:**
   ```bash
   chmod +x scripts/deploy.sh
   ./scripts/deploy.sh
   ```

   - If you use a variable file, pass it when planning/applying in the script or by editing the deploy flow.

4. **Test log ingestion:**
   ```bash
   ./scripts/test-logs.sh <loki-endpoint>
   ```

5. **Access Grafana:**
   - URL: `https://<grafana-alb-dns>`
   - Default credentials: `admin/admin123`
   - Change the password immediately after the first login.

## 🔧 Configuration

Detailed Terraform configuration information is available in `docs/configuration.md`.

## 📊 Log Collection Setup

### AWS ECS (Primary Focus)

This repository includes a sample ECS task definition only when `enable_ecs = true` and `enable_example_ecs_task = true`. That sample task is a template for how your own ECS task definitions should be configured.

Update your ECS task definitions to include FireLens for your application containers:

```hcl
container_definitions = [{
  name      = "app"
  image     = "myapp:latest"
  logConfiguration = {
    logDriver = "awsfirelens"
    options = {
      Name       = "loki"
      Loki_URL   = "http://<loki-endpoint>:3100/loki/api/v1/push"
      labels     = "service=myapp,env=prod"
      tenant     = "default"
    }
  }
}, {
  name      = "log_router"
  image     = "amazon/aws-for-fluent-bit:latest"
  firelensConfiguration = {
    type = "fluentbit"
    options = {
      enable-ecs-log-metadata = "true"
    }
  }
  logConfiguration = {
    logDriver = "awslogs"
    options = {
      awslogs-group         = "/ecs/firelens-${var.environment}"
      awslogs-region        = "${var.aws_region}"
      awslogs-stream-prefix = "ecs"
    }
  }
}]
```

- The application logs are sent to Loki.
- The FireLens router container itself may still emit minimal CloudWatch logs for its own control-plane operation.
- Set `ecs_firelens_log_group_retention` to a small number to reduce CloudWatch cost.

If you do not want ECS sample resources, set `enable_ecs = false` and `enable_example_ecs_task = false`.

### AWS EC2

Fluent Bit is automatically configured via user data to collect:
- `/var/log/syslog`
- `/var/log/app/*.log` (JSON format)
- Custom application logs

### External Servers

Install Fluent Bit and configure output to Loki endpoint with authentication.

### Kubernetes

Deploy Fluent Bit DaemonSet with Loki output plugin.

## 🔍 Querying Logs

### Grafana UI

1. Navigate to Explore
2. Select Loki data source
3. Use LogQL queries:
   ```logql
   {job="myapp"} |= "error"           # Grep for errors
   {job="api"} |~ "connection.*refused"  # Regex search
   {job="myapp", env="prod"}          # Filter by labels
   sum(rate({job="api"}[5m])) by (status)  # Metrics
   ```

### CLI (logcli)

```bash
# Install logcli
curl -L https://github.com/grafana/loki/releases/download/v2.9.1/logcli-linux-amd64.zip -o logcli.zip
unzip logcli.zip
sudo mv logcli-linux-amd64 /usr/local/bin/logcli

# Query examples
logcli query '{job="myapp"} |= "error"' --addr=http://<loki-endpoint>:3100
logcli query -S 1h '{job="api"}' --addr=http://<loki-endpoint>:3100  # Last hour
```

## 💰 Cost Analysis

For 5TB/day log volume:

| Component | CloudWatch Logs | Loki Solution | Savings |
|-----------|-----------------|---------------|---------|
| Ingestion | ~$3,840/month | - | - |
| Storage | ~$4,500/month | ~$2,565/month | - |
| Compute | - | ~$1,600/month | - |
| **Total** | **~$8,340/month** | **~$4,165/month** | **50%** |

*Assumes 70% compression, S3 Glacier transition after 7 days*

## 🔧 Configuration

### Loki Configuration

Key settings in `terraform/modules/loki/user-data.sh`:
- Retention: 30 days
- Replication factor: 3 (ingesters)
- Chunk size: 1MB
- Query cache: Enabled

### Scaling

- **Distributor**: 2-5 instances (stateless)
- **Ingesters**: 3-10 instances (stateful with EBS)
- **Queriers**: 2-10 instances (auto-scale based on load)

## 🔒 Security

- VPC isolation
- Security groups restrict access
- IAM roles with least privilege
- TLS termination at ALB
- Optional: mTLS between components

## 📈 Monitoring

- CloudWatch alarms on ASG metrics
- Loki self-monitoring via Prometheus (optional)
- Log ingestion rates and query performance

## 🤝 Contributing

1. Follow Terraform best practices
2. Test changes in dev environment
3. Update documentation
4. Create pull requests with clear descriptions

## 📝 Notes

- This is a template implementation - customize variables for your environment
- Costs are estimates; monitor actual usage
- Consider backup strategies for DynamoDB index
- Test failover scenarios in production
- Document runbooks for common operations

## ❓ Questions & Considerations

- **AWS Region**: Which region for deployment?
- **Retention Period**: How long to keep logs? (Current: 30 days)
- **Authentication**: Basic auth vs. IAM vs. mTLS?
- **Domain**: Custom domain for Grafana?
- **Monitoring**: Prometheus for Loki metrics?
- **Backup**: S3 cross-region replication?
- **Migration**: Gradual migration from CloudWatch Logs?