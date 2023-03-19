
resource "aws_vpc" "cloudwave-vpc" {
    cidr_block = var.vpc_cidr
    tags = {
      Name = "${var.environment}-vpc"
  }
  
}
resource "aws_internet_gateway" "cloudwave-igw" {
  vpc_id = aws_vpc.cloudwave-vpc.id
   tags = {
    Name = "${var.environment}-igw"
  }
  
}
resource "aws_subnet" "mypubsubnet" {
  cidr_block = var.pubsubcidr
  availability_zone = var.pubsubaz
  vpc_id = aws_vpc.cloudwave-vpc.id
   tags = {
    Name = "${var.environment}-pubsubnet"
  }
  
}
resource "aws_subnet" "myprisubnet" {
  cidr_block = var.prisubcidr
  availability_zone = var.prisubaz
  vpc_id = aws_vpc.cloudwave-vpc.id
   tags = {
    Name = "${var.environment}-prisubnet"
  }
  
}
resource "aws_route_table" "cloudwave-rt" {
  vpc_id = aws_vpc.cloudwave-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.cloudwave-igw.id
  }
   tags = {
    Name = "${var.environment}-rt"
  }
}
resource "aws_route_table_association" "cloudwave-subass" {
  subnet_id      = aws_subnet.mypubsubnet.id
  route_table_id = aws_route_table.cloudwave-rt.id
}

resource "aws_eip" "cloudwave-eip" {
  vpc      = true
}

resource "aws_nat_gateway" "cloudwave-NAT" {
  allocation_id = aws_eip.cloudwave-eip.id
  subnet_id     = aws_subnet.myprisubnet.id

  tags = {
    Name = "${var.environment}-NAT"
  }
  depends_on = [aws_internet_gateway.cloudwave-igw]
}










