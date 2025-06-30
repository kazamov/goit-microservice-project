output "s3_bucket_name" {
  description = "Name of the S3 bucket created for Terraform state"
  value       = module.s3_backend.s3_bucket_name
}

output "s3_bucket_arn" {
  description = "ARN of the S3 bucket created for Terraform state"
  value       = module.s3_backend.s3_bucket_arn
}

output "dynamodb_table_name" {
  description = "Name of the DynamoDB table created for Terraform locks"
  value       = module.s3_backend.dynamodb_table_name
}

output "dynamodb_table_arn" {
  description = "ARN of the DynamoDB table created for Terraform locks"
  value       = module.s3_backend.dynamodb_table_arn
}

output "backend_config" {
  description = "Backend configuration for use in main infrastructure"
  value = {
    bucket         = module.s3_backend.s3_bucket_name
    key            = var.state_key
    region         = var.aws_region
    dynamodb_table = module.s3_backend.dynamodb_table_name
    encrypt        = true
  }
}
