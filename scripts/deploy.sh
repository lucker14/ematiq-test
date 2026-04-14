#!/bin/bash
# Deployment script for logging system

set -e

echo "Starting deployment of logging system..."

# Initialize Terraform
cd terraform
terraform init

# Validate configuration
terraform validate

# Plan deployment
terraform plan -out=tfplan

# Ask for confirmation
read -p "Do you want to apply the plan? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Deployment cancelled."
    exit 1
fi

# Apply configuration
terraform apply tfplan

echo "Deployment completed successfully!"
echo "Outputs:"
terraform output