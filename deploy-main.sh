#!/bin/bash

# Deploy Main Infrastructure Script

set -e

echo "🚀 Deploying Main Infrastructure..."

cd main-infra

echo "📋 Initializing Terraform..."
terraform init

echo "📋 Planning deployment..."
terraform plan

echo "📋 Applying configuration..."
terraform apply -auto-approve

echo "✅ Main infrastructure deployed successfully!"
echo ""
echo "📋 Infrastructure Outputs:"
terraform output

echo ""
echo "🎉 Complete infrastructure is now deployed!"
echo "💡 To destroy:"
echo "   cd main-infra && terraform destroy  # Destroys main infra only"
echo "   cd infra-backend && terraform destroy  # Destroys backend (optional)"
