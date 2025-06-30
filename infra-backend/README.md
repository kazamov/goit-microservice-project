# Backend Infrastructure

This directory contains the Terraform configuration for creating the S3 bucket and DynamoDB table needed for remote state storage.

## Purpose

This project creates the foundation for remote Terraform state management:
- **S3 Bucket**: Stores Terraform state files
- **DynamoDB Table**: Provides state locking to prevent concurrent modifications
- **Empty State File**: Optionally bootstraps the backend with an empty state

## Architecture

```
infra-backend/     ← This project (uses local state)
└── Creates S3 + DynamoDB for remote state

main-infra/        ← Main project (uses remote state)
└── Uses the S3 backend created above
```

## Files

- `main.tf` - Main Terraform configuration
- `variables.tf` - Input variables
- `outputs.tf` - Output values (including backend config)

## Usage

### 1. Deploy Backend Infrastructure

```bash
cd infra-backend
terraform init
terraform plan
terraform apply
```

### 2. Get Backend Configuration

After applying, note the output values for configuring the main infrastructure:

```bash
terraform output backend_config
```

### 3. Configure Main Infrastructure

Use the output values to configure the backend in `../main-infra/backend.tf`.

## Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `aws_region` | AWS region | `eu-central-1` |
| `bucket_name` | S3 bucket name | `terraform-state-bucket-127214174194` |
| `table_name` | DynamoDB table name | `terraform-locks` |
| `create_empty_state` | Create empty state file | `true` |
| `state_key` | Path for main infra state | `main-infra/terraform.tfstate` |

## Important Notes

- This project uses **local state** since it creates the infrastructure for remote state
- The S3 bucket and DynamoDB table will persist even if main infrastructure is destroyed
- To completely clean up, destroy this project last: `terraform destroy`
