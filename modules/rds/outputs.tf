# Database endpoint
output "endpoint" {
  description = "RDS instance endpoint or Aurora cluster endpoint"
  value       = var.use_aurora ? aws_rds_cluster.aurora[0].endpoint : aws_db_instance.standard[0].endpoint
}

# Reader endpoint (Aurora only)
output "reader_endpoint" {
  description = "Aurora cluster reader endpoint"
  value       = var.use_aurora ? aws_rds_cluster.aurora[0].reader_endpoint : null
}

# Database port
output "port" {
  description = "RDS instance or Aurora cluster port"
  value       = var.use_aurora ? aws_rds_cluster.aurora[0].port : aws_db_instance.standard[0].port
}

# Database name
output "database_name" {
  description = "Name of the database"
  value       = var.db_name
}

# Database username
output "username" {
  description = "Master username for the database"
  value       = var.username
  sensitive   = true
}

# Security group ID
output "security_group_id" {
  description = "ID of the RDS security group"
  value       = aws_security_group.rds.id
}

# Subnet group name
output "subnet_group_name" {
  description = "Name of the DB subnet group"
  value       = aws_db_subnet_group.default.name
}

# Resource identifier
output "identifier" {
  description = "RDS instance identifier or Aurora cluster identifier"
  value       = var.use_aurora ? aws_rds_cluster.aurora[0].cluster_identifier : aws_db_instance.standard[0].identifier
}

# Parameter group name
output "parameter_group_name" {
  description = "Name of the parameter group"
  value       = var.use_aurora ? aws_rds_cluster_parameter_group.aurora[0].name : aws_db_parameter_group.standard[0].name
}

# Aurora cluster members (Aurora only)
output "cluster_members" {
  description = "List of Aurora cluster members"
  value       = var.use_aurora ? aws_rds_cluster.aurora[0].cluster_members : []
}

# Engine version
output "engine_version" {
  description = "Running version of the database engine"
  value       = var.use_aurora ? aws_rds_cluster.aurora[0].engine_version : aws_db_instance.standard[0].engine_version
}

# Connection string
output "connection_string" {
  description = "Database connection string"
  value = var.use_aurora ? (
    "postgresql://${var.username}:${var.password}@${aws_rds_cluster.aurora[0].endpoint}:${aws_rds_cluster.aurora[0].port}/${var.db_name}"
    ) : (
    "postgresql://${var.username}:${var.password}@${aws_db_instance.standard[0].endpoint}:${aws_db_instance.standard[0].port}/${var.db_name}"
  )
  sensitive = true
}
