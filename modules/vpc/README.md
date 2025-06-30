# AWS VPC Module

This module creates a complete AWS VPC (Virtual Private Cloud) infrastructure with public and private subnets, internet gateway, and routing tables. It provides a secure and scalable network foundation for your AWS resources.

## Features

- ✅ VPC with custom CIDR block
- ✅ Multiple public subnets across availability zones
- ✅ Multiple private subnets across availability zones
- ✅ Internet Gateway for public internet access
- ✅ Route tables and associations
- ✅ DNS support and hostnames enabled
- ✅ Auto-assign public IPs in public subnets
- ✅ Comprehensive tagging

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                        VPC (10.0.0.0/16)                   │
│                                                             │
│  ┌──────────────────┐              ┌──────────────────┐     │
│  │   Public Subnet  │              │  Private Subnet  │     │
│  │   10.0.1.0/24    │              │   10.0.4.0/24    │     │
│  │      AZ-1        │              │      AZ-1        │     │
│  └──────────────────┘              └──────────────────┘     │
│           │                                 │               │
│  ┌──────────────────┐              ┌──────────────────┐     │
│  │   Public Subnet  │              │  Private Subnet  │     │
│  │   10.0.2.0/24    │              │   10.0.5.0/24    │     │
│  │      AZ-2        │              │      AZ-2        │     │
│  └──────────────────┘              └──────────────────┘     │
│           │                                 │               │
│  ┌──────────────────┐              ┌──────────────────┐     │
│  │   Public Subnet  │              │  Private Subnet  │     │
│  │   10.0.3.0/24    │              │   10.0.6.0/24    │     │
│  │      AZ-3        │              │      AZ-3        │     │
│  └──────────────────┘              └──────────────────┘     │
│           │                                                 │
│    ┌─────────────┐                                          │
│    │ Internet    │                                          │
│    │ Gateway     │                                          │
│    └─────────────┘                                          │
└─────────────────────────────────────────────────────────────┘
                    │
              ┌─────────────┐
              │  Internet   │
              └─────────────┘
```

## Usage

### Basic Usage

```hcl
module "vpc" {
  source             = "./modules/vpc"
  vpc_cidr_block     = "10.0.0.0/16"
  public_subnets     = ["10.0.1.0/24", "10.0.2.0/24"]
  private_subnets    = ["10.0.4.0/24", "10.0.5.0/24"]
  availability_zones = ["eu-central-1a", "eu-central-1b"]
  vpc_name           = "my-vpc"
}
```

### Production Usage

```hcl
module "vpc" {
  source             = "./modules/vpc"
  vpc_cidr_block     = "10.0.0.0/16"
  public_subnets     = [
    "10.0.1.0/24",  # Public subnet AZ-1
    "10.0.2.0/24",  # Public subnet AZ-2
    "10.0.3.0/24"   # Public subnet AZ-3
  ]
  private_subnets    = [
    "10.0.4.0/24",  # Private subnet AZ-1
    "10.0.5.0/24",  # Private subnet AZ-2
    "10.0.6.0/24"   # Private subnet AZ-3
  ]
  availability_zones = [
    "eu-central-1a",
    "eu-central-1b",
    "eu-central-1c"
  ]
  vpc_name           = "production-vpc"
}
```

## Variables

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| vpc_cidr_block | CIDR block for the VPC | `string` | n/a | yes |
| public_subnets | List of CIDR blocks for public subnets | `list(string)` | n/a | yes |
| private_subnets | List of CIDR blocks for private subnets | `list(string)` | n/a | yes |
| availability_zones | List of availability zones for subnets | `list(string)` | n/a | yes |
| vpc_name | Name prefix for VPC resources | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| vpc_id | ID of the created VPC |
| public_subnets | List of IDs of the public subnets |
| private_subnets | List of IDs of the private subnets |
| internet_gateway_id | ID of the Internet Gateway |

## Resources Created

### Core VPC Resources
- **aws_vpc**: Main VPC with DNS support enabled
- **aws_internet_gateway**: Internet Gateway for public internet access

### Subnets
- **aws_subnet (public)**: Public subnets with auto-assign public IP
- **aws_subnet (private)**: Private subnets for internal resources

### Routing
- **aws_route_table**: Route table for public subnets
- **aws_route**: Route to Internet Gateway (0.0.0.0/0)
- **aws_route_table_association**: Associates public subnets with route table

## Network Design Principles

### Public Subnets
- **Purpose**: Host resources that need direct internet access
- **Features**: Auto-assign public IPs, route to Internet Gateway
- **Use Cases**: Load balancers, bastion hosts, NAT gateways

### Private Subnets
- **Purpose**: Host internal resources without direct internet access
- **Features**: No public IPs, no direct internet routing
- **Use Cases**: Application servers, databases, internal services

### High Availability
- **Multi-AZ**: Resources distributed across multiple availability zones
- **Fault Tolerance**: Failure in one AZ doesn't affect others
- **Scalability**: Easy to add more subnets and AZs

## Common Use Cases

### 1. Web Application Architecture

```hcl
# Use public subnets for:
resource "aws_lb" "app_lb" {
  load_balancer_type = "application"
  subnets           = module.vpc.public_subnets
}

# Use private subnets for:
resource "aws_instance" "app_server" {
  subnet_id = module.vpc.private_subnets[0]
}
```

### 2. Database Subnet Groups

```hcl
resource "aws_db_subnet_group" "main" {
  name       = "main-db-subnet-group"
  subnet_ids = module.vpc.private_subnets
}
```

### 3. ECS/EKS Clusters

```hcl
resource "aws_ecs_cluster" "main" {
  name = "main-cluster"
}

resource "aws_ecs_service" "app" {
  cluster = aws_ecs_cluster.main.id
  
  network_configuration {
    subnets = module.vpc.private_subnets
  }
}
```

## Security Considerations

### Network Segmentation
- **Public/Private Separation**: Clear separation between internet-facing and internal resources
- **Subnet Isolation**: Different tiers in different subnets
- **Security Groups**: Additional layer of security at instance level

### Best Practices
1. **Least Privilege**: Only public subnets have internet access
2. **Defense in Depth**: Multiple layers of security
3. **Network ACLs**: Consider adding network ACLs for additional security
4. **Flow Logs**: Enable VPC Flow Logs for monitoring

## Extending the Module

### Adding NAT Gateways for Private Subnets

```hcl
# Add to the module for private subnet internet access
resource "aws_eip" "nat" {
  count  = length(var.public_subnets)
  domain = "vpc"
}

resource "aws_nat_gateway" "main" {
  count         = length(var.public_subnets)
  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public[count.index].id
}
```

### Adding VPC Endpoints

```hcl
# S3 VPC Endpoint
resource "aws_vpc_endpoint" "s3" {
  vpc_id       = aws_vpc.main.id
  service_name = "com.amazonaws.${data.aws_region.current.name}.s3"
}
```

## Troubleshooting

### Common Issues

1. **CIDR Conflicts**: Ensure CIDR blocks don't overlap
   ```
   Error: CIDR block 10.0.1.0/24 overlaps with existing subnet
   ```

2. **Availability Zone Limits**: Check AZ availability in your region
   ```bash
   aws ec2 describe-availability-zones --region eu-central-1
   ```

3. **Internet Connectivity**: Ensure route table has route to Internet Gateway
   ```bash
   aws ec2 describe-route-tables --filters "Name=vpc-id,Values=vpc-xxxxxxxx"
   ```

## Cost Optimization

- **NAT Gateways**: Consider using NAT instances for lower cost
- **VPC Endpoints**: Use VPC endpoints to avoid NAT Gateway costs for AWS services
- **Right-sizing**: Choose appropriate subnet sizes based on requirements

## Monitoring and Logging

### VPC Flow Logs
```hcl
resource "aws_flow_log" "vpc_flow_log" {
  iam_role_arn    = aws_iam_role.flow_log.arn
  log_destination = aws_cloudwatch_log_group.vpc.arn
  traffic_type    = "ALL"
  vpc_id          = aws_vpc.main.id
}
```

### CloudWatch Metrics
- Monitor network utilization
- Track data transfer costs
- Set up alerts for unusual traffic patterns
