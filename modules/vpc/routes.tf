# Create route table for public subnets
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id # Attach table to our VPC

  tags = {
    Name = "${var.vpc_name}-public-rt" # Tag for route table
  }
}

# Add route for internet access through Internet Gateway
resource "aws_route" "public_internet" {
  route_table_id         = aws_route_table.public.id   # Route table ID
  destination_cidr_block = "0.0.0.0/0"                 # All IP addresses
  gateway_id             = aws_internet_gateway.igw.id # Specify Internet Gateway as exit
}

# Associate route table with public subnets
resource "aws_route_table_association" "public" {
  count          = length(var.public_subnets) # Associate each subnet
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# Create route table for private subnets
resource "aws_route_table" "private" {
  count  = var.enable_nat_gateway ? (var.single_nat_gateway ? 1 : length(var.private_subnets)) : 1
  vpc_id = aws_vpc.main.id

  tags = {
    Name = var.single_nat_gateway ? "${var.vpc_name}-private-rt" : "${var.vpc_name}-private-rt-${count.index + 1}"
  }
}

# Add route for internet access through NAT Gateway (only if NAT is enabled)
resource "aws_route" "private_nat_gateway" {
  count                  = var.enable_nat_gateway ? (var.single_nat_gateway ? 1 : length(var.private_subnets)) : 0
  route_table_id         = aws_route_table.private[count.index].id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.nat[count.index].id

  timeouts {
    create = "5m"
  }
}

# Associate route table with private subnets
resource "aws_route_table_association" "private" {
  count          = length(var.private_subnets)
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = var.enable_nat_gateway ? (var.single_nat_gateway ? aws_route_table.private[0].id : aws_route_table.private[count.index].id) : aws_route_table.private[0].id
}
