# Create the main VPC
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr_block # CIDR block for our VPC (e.g., 10.0.0.0/16)
  enable_dns_support   = true               # Enable DNS support in VPC
  enable_dns_hostnames = true               # Enable DNS hostnames for resources in VPC

  tags = {
    Name = "${var.vpc_name}-vpc" # Add tag that includes VPC name
  }
}

# Create public subnets
resource "aws_subnet" "public" {
  count                   = length(var.public_subnets)          # Create multiple subnets, count determined by public_subnets list length
  vpc_id                  = aws_vpc.main.id                     # Attach each subnet to the VPC created above
  cidr_block              = var.public_subnets[count.index]     # CIDR block for specific subnet from public_subnets list
  availability_zone       = var.availability_zones[count.index] # Define availability zones for each subnet
  map_public_ip_on_launch = true                                # Automatically assign public IP addresses to instances in subnet

  tags = {
    Name = "${var.vpc_name}-public-subnet-${count.index + 1}" # Tag with subnet numbering
    # count.index is the loop index starting from 0
    # ${count.index + 1} adds +1 to get human-readable numbering (1, 2, 3 instead of 0, 1, 2)
  }
}

# Create private subnets
resource "aws_subnet" "private" {
  count             = length(var.private_subnets)         # Create multiple private subnets, count matches private_subnets list length
  vpc_id            = aws_vpc.main.id                     # Attach each private subnet to VPC
  cidr_block        = var.private_subnets[count.index]    # CIDR block for specific subnet from private_subnets list
  availability_zone = var.availability_zones[count.index] # Define availability zones for subnets

  tags = {
    Name = "${var.vpc_name}-private-subnet-${count.index + 1}"
  }
}

# Create Internet Gateway for public subnets
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.vpc_name}-igw" # Tag for identifying Internet Gateway
  }
}

# Create Elastic IP for NAT Gateway(s)
resource "aws_eip" "nat" {
  count  = var.enable_nat_gateway ? (var.single_nat_gateway ? 1 : length(var.private_subnets)) : 0
  domain = "vpc"

  tags = {
    Name = var.single_nat_gateway ? "${var.vpc_name}-nat-eip" : "${var.vpc_name}-nat-eip-${count.index + 1}"
  }

  depends_on = [aws_internet_gateway.igw]
}

# Create NAT Gateway(s)
resource "aws_nat_gateway" "nat" {
  count         = var.enable_nat_gateway ? (var.single_nat_gateway ? 1 : length(var.private_subnets)) : 0
  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public[count.index].id

  tags = {
    Name = var.single_nat_gateway ? "${var.vpc_name}-nat-gateway" : "${var.vpc_name}-nat-gateway-${count.index + 1}"
  }

  depends_on = [aws_internet_gateway.igw]
}

