variable "aws_region" {
  description = "AWS region for the backend infrastructure"
  type        = string
  default     = "eu-central-1"
}

variable "bucket_name" {
  description = "The name of the S3 bucket for Terraform state"
  type        = string
  default     = "terraform-state-bucket-127214174194"
}

variable "table_name" {
  description = "The name of the DynamoDB table for Terraform locks"
  type        = string
  default     = "terraform-locks"
}

variable "create_empty_state" {
  description = "Whether to create an empty state file to bootstrap the backend"
  type        = bool
  default     = true
}

variable "state_key" {
  description = "The key (path) for the main infrastructure state file"
  type        = string
  default     = "main-infra/terraform.tfstate"
}
