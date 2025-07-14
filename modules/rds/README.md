# Universal RDS Module

Universal Terraform module for creating Amazon RDS infrastructure that supports both Aurora Cluster and standard RDS instances.

## Features

This module automatically creates:

- **Aurora Cluster** or **standard RDS instance** based on the `use_aurora` parameter
- **DB Subnet Group** for placing the database in appropriate subnets
- **Security Group** with database access rules
- **Parameter Group** with basic performance and logging parameters

## Operating Modes

### Aurora Cluster (`use_aurora = true`)
- Creates Aurora Cluster with one writer instance
- Adds reader replicas (count specified by `aurora_replica_count` parameter)
- Automatically creates cluster parameter group
- Supports automatic failover and read scaling

### Standard RDS (`use_aurora = false`)
- Creates a single aws_db_instance
- Supports Multi-AZ deployment
- Configurable allocated storage
- Creates DB parameter group

## Usage Examples

### Aurora PostgreSQL Cluster

```hcl
module "aurora_postgres" {
  source = "./modules/rds"

  name                = "my-aurora-cluster"
  use_aurora          = true
  
  # Aurora-specific settings
  engine_cluster             = "aurora-postgresql"
  engine_version_cluster     = "15.3"
  parameter_group_family_aurora = "aurora-postgresql15"
  aurora_replica_count       = 2
  
  # Database configuration
  db_name  = "myapp"
  username = "dbadmin"
  password = var.db_password
  
  # Infrastructure
  vpc_id              = var.vpc_id
  subnet_private_ids  = var.private_subnet_ids
  subnet_public_ids   = var.public_subnet_ids
  publicly_accessible = false
  
  # Instance configuration
  instance_class = "db.r6g.large"
  
  # Custom parameters
  parameters = {
    max_connections = "200"
    work_mem       = "8192"  # 8MB in KB
    log_statement  = "all"
  }
  
  tags = {
    Environment = "production"
    Application = "myapp"
  }
}
```

### Standard PostgreSQL RDS

```hcl
module "standard_postgres" {
  source = "./modules/rds"

  name       = "my-postgres-db"
  use_aurora = false
  
  # RDS-specific settings
  engine                      = "postgres"
  engine_version             = "14.7"
  parameter_group_family_rds = "postgres14"
  allocated_storage          = 100
  multi_az                   = true
  
  # Database configuration
  db_name  = "myapp"
  username = "dbadmin"
  password = var.db_password
  
  # Infrastructure
  vpc_id              = var.vpc_id
  subnet_private_ids  = var.private_subnet_ids
  subnet_public_ids   = var.public_subnet_ids
  publicly_accessible = false
  
  # Instance configuration
  instance_class = "db.t3.medium"
  
  # Custom parameters
  parameters = {
    max_connections          = "150"
    shared_preload_libraries = "pg_stat_statements"
    work_mem                = "6144"  # 6MB in KB
  }
  
  tags = {
    Environment = "staging"
    Application = "myapp"
  }
}
```

### Aurora MySQL Cluster

```hcl
module "aurora_mysql" {
  source = "./modules/rds"

  name       = "my-mysql-cluster"
  use_aurora = true
  
  # Aurora MySQL settings
  engine_cluster             = "aurora-mysql"
  engine_version_cluster     = "8.0.mysql_aurora.3.02.0"
  parameter_group_family_aurora = "aurora-mysql8.0"
  aurora_replica_count       = 1
  
  # Database configuration
  db_name  = "myapp"
  username = "admin"
  password = var.db_password
  
  # Infrastructure
  vpc_id              = var.vpc_id
  subnet_private_ids  = var.private_subnet_ids
  subnet_public_ids   = var.public_subnet_ids
  publicly_accessible = false
  
  # Instance configuration
  instance_class = "db.r6g.xlarge"
  
  # MySQL-specific parameters
  parameters = {
    max_connections = "300"
    innodb_buffer_pool_size = "75"
  }
  
  tags = {
    Environment = "production"
    Application = "myapp"
  }
}
```

## Module Variables

### Main Parameters

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `name` | `string` | - | **Required**. Name of RDS instance or cluster |
| `use_aurora` | `bool` | `false` | Defines DB type: true = Aurora Cluster, false = Standard RDS |
| `db_name` | `string` | - | **Required**. Database name |
| `username` | `string` | - | **Required**. Database username |
| `password` | `string` | - | **Required**. Database password |

### Network Parameters

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `vpc_id` | `string` | - | **Required**. VPC ID for database creation |
| `subnet_private_ids` | `list(string)` | - | **Required**. Private subnet IDs |
| `subnet_public_ids` | `list(string)` | - | **Required**. Public subnet IDs |
| `publicly_accessible` | `bool` | `false` | Whether DB should be publicly accessible |

### Engine Parameters

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `engine` | `string` | `"postgres"` | Engine for Standard RDS |
| `engine_cluster` | `string` | `"aurora-postgresql"` | Engine for Aurora Cluster |
| `engine_version` | `string` | `"14.7"` | Engine version for Standard RDS |
| `engine_version_cluster` | `string` | `"15.3"` | Engine version for Aurora |

### Instance Parameters

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `instance_class` | `string` | `"db.t3.micro"` | Database instance class |
| `allocated_storage` | `number` | `20` | Storage size in GB (Standard RDS only) |
| `multi_az` | `bool` | `false` | Multi-AZ deployment (Standard RDS only) |

### Aurora-specific Parameters

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `aurora_replica_count` | `number` | `1` | Number of reader replicas |
| `parameter_group_family_aurora` | `string` | `"aurora-postgresql15"` | Parameter group family for Aurora |

### Parameter Groups

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `parameter_group_family_rds` | `string` | `"postgres15"` | Parameter group family for RDS |
| `parameters` | `map(string)` | See below | Custom database parameters |

#### Default parameters include:

```hcl
parameters = {
  max_connections          = "100"
  log_statement           = "all"
  work_mem                = "4096"  # 4MB in KB
  shared_preload_libraries = "pg_stat_statements"
  log_min_duration_statement = "1000"
}
```

### Other Parameters

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `backup_retention_period` | `number` | `7` | Backup retention period (days) |
| `tags` | `map(string)` | `{}` | Tags for resources |

## Outputs

| Output | Description |
|--------|-------------|
| `endpoint` | Database endpoint |
| `reader_endpoint` | Reader endpoint (Aurora only) |
| `port` | Database port |
| `database_name` | Database name |
| `username` | Database username |
| `security_group_id` | Security Group ID |
| `subnet_group_name` | DB Subnet Group name |
| `identifier` | Database identifier |
| `parameter_group_name` | Parameter Group name |
| `cluster_members` | Aurora cluster members list |
| `engine_version` | Database engine version |
| `connection_string` | Database connection string |

## How to Change Database Type, Engine, Instance Class

### Changing Database Type (Aurora ↔ Standard RDS)

To switch between Aurora and Standard RDS, change the `use_aurora` parameter:

```hcl
# For Aurora
use_aurora = true

# For Standard RDS
use_aurora = false
```

**Warning**: Changing this parameter will create a new database and destroy the old one!

### Changing Engine

#### For Standard RDS:
```hcl
engine = "postgres"  # or "mysql", "mariadb"
engine_version = "14.7"
parameter_group_family_rds = "postgres14"
```

#### For Aurora:
```hcl
engine_cluster = "aurora-postgresql"  # or "aurora-mysql"
engine_version_cluster = "15.3"
parameter_group_family_aurora = "aurora-postgresql15"
```

### Changing Instance Class

```hcl
# For development/testing
instance_class = "db.t3.micro"

# For production workloads
instance_class = "db.r6g.large"    # Memory optimized
instance_class = "db.m6g.xlarge"   # General purpose
instance_class = "db.c6g.2xlarge"  # Compute optimized
```

### Common Configuration Examples

#### Development Environment
```hcl
use_aurora     = false
instance_class = "db.t3.micro"
multi_az       = false
allocated_storage = 20
backup_retention_period = 1
```

#### Staging Environment
```hcl
use_aurora     = false
instance_class = "db.t3.medium"
multi_az       = true
allocated_storage = 100
backup_retention_period = 7
```

#### Production Environment
```hcl
use_aurora     = true
instance_class = "db.r6g.large"
aurora_replica_count = 2
backup_retention_period = 30
```

## Supported Engines

### Standard RDS
- `postgres` (PostgreSQL)
- `mysql` (MySQL)
- `mariadb` (MariaDB)

### Aurora
- `aurora-postgresql`
- `aurora-mysql`

## Parameter Formatting

When configuring database parameters, use the correct format for your database engine:

### PostgreSQL Parameters
- **Memory parameters**: Use kilobytes (KB) as integers
  - `work_mem = "4096"` (4MB)
  - `shared_buffers = "32768"` (32MB)
- **Time parameters**: Use milliseconds
  - `log_min_duration_statement = "1000"` (1 second)
- **String parameters**: Use quoted strings
  - `log_statement = "all"`
  - `shared_preload_libraries = "pg_stat_statements"`

### MySQL Parameters
- **Memory parameters**: Can use units or percentages
  - `innodb_buffer_pool_size = "75"` (75% of memory)
  - `key_buffer_size = "268435456"` (256MB in bytes)

## Security

- Security Group by default allows access only from private subnets (10.0.0.0/8)
- Database password is marked as sensitive
- Public access is disabled by default
- Supports encryption at rest and in transit

## Requirements

- Terraform >= 1.0
- AWS Provider >= 4.0
- Created VPC and subnets
- IAM permissions for creating RDS resources

## License

MIT
