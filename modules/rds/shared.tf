# Subnet group (used by both)
resource "aws_db_subnet_group" "default" {
  name       = "${var.name}-subnet-group"
  subnet_ids = var.publicly_accessible ? var.subnet_public_ids : var.subnet_private_ids

  tags = merge(
    var.tags,
    {
      Name = "${var.name}-db-subnet-group"
    }
  )
}

# Security group (used by both)
resource "aws_security_group" "rds" {
  name        = "${var.name}-sg"
  description = "Security group for RDS"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = local.db_port
    to_port     = local.db_port
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/8"] # Restrict to private subnets
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(
    var.tags,
    {
      Name = "${var.name}-rds-sg"
    }
  )
}

# Local values for dynamic configuration
locals {
  db_port = contains(["postgres", "aurora-postgresql"], var.use_aurora ? var.engine_cluster : var.engine) ? 5432 : 3306

  # Default database parameters
  default_parameters = {
    max_connections            = "100"
    log_statement              = "all"
    work_mem                   = "4MB"
    shared_preload_libraries   = "pg_stat_statements"
    log_min_duration_statement = "1000"
  }
}
