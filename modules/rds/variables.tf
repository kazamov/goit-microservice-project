variable "name" {
  description = "Name of the RDS instance or cluster"
  type        = string
}

variable "engine" {
  description = "Database engine for standard RDS instance"
  type        = string
  default     = "postgres"
}

variable "engine_cluster" {
  description = "Database engine for Aurora cluster"
  type        = string
  default     = "aurora-postgresql"
}

variable "aurora_replica_count" {
  description = "Number of Aurora reader replicas to create"
  type        = number
  default     = 1
}

variable "aurora_instance_count" {
  description = "Total number of Aurora instances (including primary)"
  type        = number
  default     = 2 # 1 primary + 1 replica
}

variable "engine_version" {
  description = "Engine version for standard RDS instance"
  type        = string
  default     = "14.7"
}

variable "instance_class" {
  description = "The instance class for database instances"
  type        = string
  default     = "db.t3.micro"
}

variable "allocated_storage" {
  description = "Allocated storage in GB for standard RDS instance"
  type        = number
  default     = 20
}

variable "db_name" {
  description = "Name of the database to create"
  type        = string
}

variable "username" {
  description = "Master username for the database"
  type        = string
}

variable "password" {
  description = "Master password for the database"
  type        = string
  sensitive   = true
}

variable "vpc_id" {
  description = "VPC ID where the database will be created"
  type        = string
}

variable "subnet_private_ids" {
  description = "List of private subnet IDs for the database"
  type        = list(string)
}

variable "subnet_public_ids" {
  description = "List of public subnet IDs for the database"
  type        = list(string)
}

variable "publicly_accessible" {
  description = "Whether the database should be publicly accessible"
  type        = bool
  default     = false
}

variable "multi_az" {
  description = "Whether to enable Multi-AZ deployment for standard RDS"
  type        = bool
  default     = false
}

variable "parameters" {
  description = "A map of custom parameters to apply to the parameter group (will be merged with defaults)"
  type        = map(string)
  default     = {}
}

variable "use_aurora" {
  description = "Whether to create Aurora cluster (true) or standard RDS instance (false)"
  type        = bool
  default     = false
}

variable "backup_retention_period" {
  description = "The backup retention period for the database (in days)"
  type        = number
  default     = 7
}

variable "skip_final_snapshot" {
  description = "Determines whether a final DB snapshot is created before the DB instance is deleted"
  type        = bool
  default     = false
}

variable "tags" {
  description = "A map of tags to assign to the resource"
  type        = map(string)
  default     = {}
}

variable "parameter_group_family_aurora" {
  description = "DB parameter group family for Aurora cluster"
  type        = string
  default     = "aurora-postgresql15"
}

variable "engine_version_cluster" {
  description = "Engine version for Aurora cluster"
  type        = string
  default     = "15.3"
}

variable "parameter_group_family_rds" {
  description = "DB parameter group family for standard RDS"
  type        = string
  default     = "postgres15"
}
