variable "ecr_name" {
  description = "Name of the ECR repository"
  type        = string
}

variable "scan_on_push" {
  description = "Whether to perform image scanning on push"
  type        = bool
  default     = false
}

variable "image_mutability" {
  description = "The tag mutability setting for the repository"
  type        = string
  default     = "MUTABLE"
  validation {
    condition     = contains(["MUTABLE", "IMMUTABLE"], var.image_mutability)
    error_message = "Image mutability must be either MUTABLE or IMMUTABLE."
  }
}

variable "encryption_configuration" {
  description = "Encryption configuration for the repository"
  type = object({
    encryption_type = string
    kms_key         = optional(string)
  })
  default = {
    encryption_type = "AES256"
    kms_key         = null
  }
}

variable "lifecycle_policy" {
  description = "Lifecycle policy document for the repository"
  type        = string
  default     = ""
}

variable "repository_policy" {
  description = "Repository policy document for the repository"
  type        = string
  default     = ""
}

variable "tags" {
  description = "A map of tags to assign to the resource"
  type        = map(string)
  default     = {}
}
