# VPC Outputs
output "vpc_id" {
  description = "ID of the created VPC"
  value       = module.vpc.vpc_id
}

output "public_subnets" {
  description = "List of IDs of the public subnets"
  value       = module.vpc.public_subnets
}

output "private_subnets" {
  description = "List of IDs of the private subnets"
  value       = module.vpc.private_subnets
}

output "internet_gateway_id" {
  description = "ID of the Internet Gateway"
  value       = module.vpc.internet_gateway_id
}

output "nat_gateway_ids" {
  description = "List of IDs of the NAT Gateways"
  value       = module.vpc.nat_gateway_ids
}

output "nat_gateway_ips" {
  description = "List of public Elastic IPs of the NAT Gateways"
  value       = module.vpc.nat_gateway_ips
}

output "private_route_table_ids" {
  description = "List of IDs of the private route tables"
  value       = module.vpc.private_route_table_ids
}

output "public_route_table_id" {
  description = "ID of the public route table"
  value       = module.vpc.public_route_table_id
}

# ECR Outputs
output "ecr_repository_url" {
  description = "URL of the ECR repository"
  value       = module.ecr.repository_url
}

output "ecr_repository_arn" {
  description = "ARN of the ECR repository"
  value       = module.ecr.repository_arn
}

output "ecr_repository_name" {
  description = "Name of the ECR repository"
  value       = module.ecr.repository_name
}

output "ecr_registry_id" {
  description = "Registry ID where the repository was created"
  value       = module.ecr.registry_id
}

# EKS

output "eks_cluster_endpoint" {
  description = "EKS API endpoint for connecting to the cluster"
  value       = module.eks.eks_cluster_endpoint
}

output "eks_cluster_name" {
  description = "Name of the EKS cluster"
  value       = module.eks.eks_cluster_name
}

output "eks_node_role_arn" {
  description = "IAM role ARN for EKS Worker Nodes"
  value       = module.eks.eks_node_role_arn
}

output "eks_console_url" {
  description = "URL to access EKS cluster in AWS Console"
  value       = module.eks.eks_console_url
}

output "current_user_arn" {
  description = "ARN of the current AWS user with EKS access"
  value       = module.eks.current_user_arn
}

output "jenkins_release" {
  value = module.jenkins.jenkins_release_name
}

output "jenkins_namespace" {
  value = module.jenkins.jenkins_namespace
}

# RDS Outputs
output "rds_endpoint" {
  description = "RDS instance endpoint or Aurora cluster endpoint"
  value       = module.rds.endpoint
}

output "rds_reader_endpoint" {
  description = "Aurora cluster reader endpoint (Aurora only)"
  value       = module.rds.reader_endpoint
}

output "rds_port" {
  description = "RDS instance or Aurora cluster port"
  value       = module.rds.port
}

output "rds_database_name" {
  description = "Name of the database"
  value       = module.rds.database_name
}

output "rds_username" {
  description = "Master username for the database"
  value       = module.rds.username
  sensitive   = true
}

output "rds_security_group_id" {
  description = "ID of the RDS security group"
  value       = module.rds.security_group_id
}

output "rds_subnet_group_name" {
  description = "Name of the DB subnet group"
  value       = module.rds.subnet_group_name
}

output "rds_identifier" {
  description = "RDS instance identifier or Aurora cluster identifier"
  value       = module.rds.identifier
}

output "rds_parameter_group_name" {
  description = "Name of the parameter group"
  value       = module.rds.parameter_group_name
}

output "rds_engine_version" {
  description = "Running version of the database engine"
  value       = module.rds.engine_version
}

output "rds_connection_string" {
  description = "Database connection string"
  value       = module.rds.connection_string
  sensitive   = true
}

# Aurora PostgreSQL Outputs
output "aurora_endpoint" {
  description = "Aurora cluster endpoint"
  value       = module.aurora_postgres_example.endpoint
}

output "aurora_reader_endpoint" {
  description = "Aurora cluster reader endpoint"
  value       = module.aurora_postgres_example.reader_endpoint
}

output "aurora_port" {
  description = "Aurora cluster port"
  value       = module.aurora_postgres_example.port
}

output "aurora_database_name" {
  description = "Name of the database"
  value       = module.aurora_postgres_example.database_name
}

output "aurora_username" {
  description = "Master username for the database"
  value       = module.aurora_postgres_example.username
  sensitive   = true
}

output "aurora_security_group_id" {
  description = "ID of the Aurora security group"
  value       = module.aurora_postgres_example.security_group_id
}

output "aurora_subnet_group_name" {
  description = "Name of the DB subnet group"
  value       = module.aurora_postgres_example.subnet_group_name
}

output "aurora_identifier" {
  description = "Aurora cluster identifier"
  value       = module.aurora_postgres_example.identifier
}

output "aurora_parameter_group_name" {
  description = "Name of the parameter group"
  value       = module.aurora_postgres_example.parameter_group_name
}

output "aurora_engine_version" {
  description = "Running version of the database engine"
  value       = module.aurora_postgres_example.engine_version
}

output "aurora_connection_string" {
  description = "Database connection string"
  value       = module.aurora_postgres_example.connection_string
  sensitive   = true
}
