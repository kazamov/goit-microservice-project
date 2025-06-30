# AWS S3 Backend Module

This module creates AWS resources required for Terraform remote state management, including an S3 bucket for state storage and a DynamoDB table for state locking.

## Features

- ✅ S3 bucket for Terraform state storage
- ✅ Versioning enabled for state history
- ✅ Bucket ownership controls for security
- ✅ DynamoDB table for state locking
- ✅ Pay-per-request billing for cost optimization
- ✅ Comprehensive tagging

## Architecture

```
┌─────────────────┐    ┌──────────────────┐
│   S3 Bucket     │    │  DynamoDB Table  │
│                 │    │                  │
│ - State Storage │    │ - State Locking  │
│ - Versioning    │    │ - Concurrency    │
│ - Encryption    │    │   Control        │
└─────────────────┘    └──────────────────┘
```

## Usage

### Basic Usage

```hcl
module "s3_backend" {
  source      = "./modules/s3-backend"
  bucket_name = "my-terraform-state-bucket"
  table_name  = "terraform-locks"
}
```

### Advanced Usage with Backend Configuration

```hcl
# Step 1: Create the backend resources
module "s3_backend" {
  source      = "./modules/s3-backend"
  bucket_name = "my-terraform-state-bucket-unique-id"
  table_name  = "terraform-locks"
}

# Step 2: Configure backend (in backend.tf)
terraform {
  backend "s3" {
    bucket         = "my-terraform-state-bucket-unique-id"
    key            = "terraform.tfstate"
    region         = "eu-central-1"
    dynamodb_table = "terraform-locks"
    encrypt        = true
  }
}
```

## Variables

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| bucket_name | The name of the S3 bucket for Terraform state | `string` | n/a | yes |
| table_name | The name of the DynamoDB table for Terraform locks | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| bucket_name | Name of the created S3 bucket |
| table_name | Name of the created DynamoDB table |

## Resources Created

### S3 Bucket
- **aws_s3_bucket**: Main bucket for state storage
- **aws_s3_bucket_versioning**: Enables versioning for state history
- **aws_s3_bucket_ownership_controls**: Sets bucket ownership to BucketOwnerEnforced

### DynamoDB Table
- **aws_dynamodb_table**: Table for state locking with LockID as hash key
- **Billing Mode**: PAY_PER_REQUEST for cost optimization
- **Attributes**: Single string attribute "LockID"

## Setup Instructions

### 1. Initial Setup (Without Backend)

First, create the backend resources without using remote state:

```bash
# Comment out backend configuration in backend.tf
# terraform {
#   backend "s3" { ... }
# }

# Initialize and apply
terraform init
terraform apply
```

### 2. Migrate to Remote State

After creating the resources, uncomment the backend configuration and migrate:

```bash
# Uncomment backend configuration
terraform init -migrate-state
```

### 3. Verification

Verify the setup:

```bash
# Check if state is stored in S3
aws s3 ls s3://your-bucket-name/

# Check DynamoDB table
aws dynamodb describe-table --table-name terraform-locks
```

## Security Considerations

- **Bucket Name**: Use a globally unique bucket name
- **Encryption**: State files are encrypted at rest in S3
- **Access Control**: Configure appropriate IAM policies
- **Versioning**: Enabled for state recovery capabilities

## Cost Optimization

- **DynamoDB**: Uses PAY_PER_REQUEST billing mode
- **S3**: Standard storage class with versioning
- **Minimal Costs**: Only pay for actual usage

## Troubleshooting

### Common Issues

1. **Bucket Already Exists**: S3 bucket names must be globally unique
   ```bash
   # Solution: Add a unique suffix
   bucket_name = "terraform-state-bucket-${random_id.bucket_suffix.hex}"
   ```

2. **Access Denied**: Ensure proper IAM permissions
   ```json
   {
     "Version": "2012-10-17",
     "Statement": [
       {
         "Effect": "Allow",
         "Action": [
           "s3:ListBucket",
           "s3:GetObject",
           "s3:PutObject",
           "s3:DeleteObject"
         ],
         "Resource": [
           "arn:aws:s3:::your-bucket-name",
           "arn:aws:s3:::your-bucket-name/*"
         ]
       },
       {
         "Effect": "Allow",
         "Action": [
           "dynamodb:GetItem",
           "dynamodb:PutItem",
           "dynamodb:DeleteItem"
         ],
         "Resource": "arn:aws:dynamodb:region:account:table/terraform-locks"
       }
     ]
   }
   ```

3. **State Lock Issues**: If state is locked, you can force unlock
   ```bash
   terraform force-unlock LOCK_ID
   ```

## Best Practices

1. **Unique Naming**: Always use unique bucket names
2. **Cross-Region**: Consider cross-region replication for critical states
3. **Lifecycle Policies**: Implement lifecycle policies for old versions
4. **Monitoring**: Set up CloudWatch alerts for unusual activities
5. **Backup**: Regularly backup important state files
