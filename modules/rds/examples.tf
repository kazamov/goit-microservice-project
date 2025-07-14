# Example usage of the universal RDS module

# Aurora PostgreSQL example
#module "aurora_postgres_example" {
#  source = "./modules/rds"
#
#  name       = "myapp-aurora"
#  use_aurora = true
#
#  # Database configuration
#  db_name  = "myappdb"
#  username = "dbadmin"
#  password = var.db_password # Define this in your variables
#
#  # Infrastructure (replace with your actual values)
#  vpc_id              = var.vpc_id
#  subnet_private_ids  = var.private_subnet_ids
#  subnet_public_ids   = var.public_subnet_ids
#  publicly_accessible = false
#
#  # Aurora settings
#  engine_cluster                = "aurora-postgresql"
#  engine_version_cluster        = "15.3"
#  parameter_group_family_aurora = "aurora-postgresql15"
#  aurora_replica_count          = 1
#  instance_class                = "db.r6g.large"
#
#  # Custom parameters
#  parameters = {
#    max_connections = "200"
#    work_mem        = "8192"  # 8MB in KB
#  }
#
#  tags = {
#    Environment = "production"
#    Application = "myapp"
#  }
#}

# Standard PostgreSQL RDS example
#module "standard_postgres_example" {
#  source = "./modules/rds"
#
#  name       = "myapp-postgres"
#  use_aurora = false
#
#  # Database configuration
#  db_name  = "myappdb"
#  username = "dbadmin"
#  password = var.db_password
#
#  # Infrastructure
#  vpc_id              = var.vpc_id
#  subnet_private_ids  = var.private_subnet_ids
#  subnet_public_ids   = var.public_subnet_ids
#  publicly_accessible = false
#
#  # RDS settings
#  engine                     = "postgres"
#  engine_version             = "14.7"
#  parameter_group_family_rds = "postgres14"
#  instance_class             = "db.t3.medium"
#  allocated_storage          = 100
#  multi_az                   = true
#
#  tags = {
#    Environment = "staging"
#    Application = "myapp"
#  }
#}

# Output examples
#output "aurora_endpoint" {
#  description = "Aurora cluster endpoint"
#  value       = module.aurora_postgres_example.endpoint
#}
#
#output "aurora_reader_endpoint" {
#  description = "Aurora cluster reader endpoint"
#  value       = module.aurora_postgres_example.reader_endpoint
#}
#
#output "standard_rds_endpoint" {
#  description = "Standard RDS endpoint"
#  value       = module.standard_postgres_example.endpoint
#}
#
#output "aurora_connection_string" {
#  description = "Aurora connection string"
#  value       = module.aurora_postgres_example.connection_string
#  sensitive   = true
#}
