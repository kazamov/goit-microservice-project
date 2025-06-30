# AWS ECR Module

This module creates an Amazon Elastic Container Registry (ECR) repository with configurable security and lifecycle policies.

## Features

- ✅ ECR repository creation
- ✅ Image scanning configuration
- ✅ Encryption configuration (AES256 or KMS)
- ✅ Lifecycle policies for automatic cleanup
- ✅ Repository policies for access control
- ✅ Tag mutability configuration
- ✅ Comprehensive outputs

## Usage

### Basic Usage

```hcl
module "ecr" {
  source       = "./modules/ecr"
  ecr_name     = "my-app"
  scan_on_push = true
}
```

### Advanced Usage

```hcl
module "ecr" {
  source            = "./modules/ecr"
  ecr_name          = "my-app"
  scan_on_push      = true
  image_mutability  = "IMMUTABLE"
  
  encryption_configuration = {
    encryption_type = "KMS"
    kms_key         = "arn:aws:kms:us-west-2:123456789012:key/12345678-1234-1234-1234-123456789012"
  }
  
  lifecycle_policy = file("${path.module}/lifecycle-policy.json")
  
  tags = {
    Environment = "production"
    Project     = "my-project"
  }
}
```

## Variables

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| ecr_name | Name of the ECR repository | `string` | n/a | yes |
| scan_on_push | Whether to scan images on push | `bool` | `false` | no |
| image_mutability | Tag mutability setting | `string` | `"MUTABLE"` | no |
| encryption_configuration | Encryption configuration | `object` | `{encryption_type = "AES256", kms_key = null}` | no |
| lifecycle_policy | Lifecycle policy document | `string` | `""` | no |
| repository_policy | Repository policy document | `string` | `""` | no |
| tags | Additional tags | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| repository_url | The URL of the repository |
| repository_arn | The ARN of the repository |
| repository_name | The name of the repository |
| registry_id | The registry ID where the repository was created |

## Default Lifecycle Policy

If no custom lifecycle policy is provided, the module applies a default policy that:
- Deletes untagged images after 1 day
- Keeps only the latest 10 tagged images

## Examples

### Using with Docker Commands

After creating the repository, you can use it with Docker:

```bash
# Get login token
aws ecr get-login-password --region eu-central-1 | docker login --username AWS --password-stdin <account-id>.dkr.ecr.eu-central-1.amazonaws.com

# Build and tag your image
docker build -t my-app .
docker tag my-app:latest <account-id>.dkr.ecr.eu-central-1.amazonaws.com/my-app:latest

# Push to ECR
docker push <account-id>.dkr.ecr.eu-central-1.amazonaws.com/my-app:latest
```

### Custom Lifecycle Policy Example

See `examples/ecr-lifecycle-policy.json` for a comprehensive lifecycle policy example.

## Security Considerations

- Enable image scanning (`scan_on_push = true`) to detect vulnerabilities
- Use KMS encryption for sensitive images
- Implement proper IAM policies for repository access
- Use immutable tags for production images
- Regularly review and update lifecycle policies
