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
