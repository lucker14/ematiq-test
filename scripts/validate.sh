#!/bin/bash
set -e

cd "$(dirname "$0")/.."

echo "Formatting Terraform files..."
terraform fmt -recursive terraform

echo "Validating Terraform syntax and configuration..."
cd terraform
terraform init -backend=false
terraform validate

echo "Terraform syntax and initial validation successful."
