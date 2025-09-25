resource "aws_vpc" "demo_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "demo-vpc"
  }
}

resource "aws_subnet" "demo_subnet" {
  vpc_id            = aws_vpc.demo_vpc.id
  cidr_block        = var.subnet_cidr
  availability_zone = var.az
  map_public_ip_on_launch = true

  tags = {
    Name = var.subnet_name
  }
}

resource "aws_subnet" "demo_subnet_b" {
  vpc_id            = aws_vpc.demo_vpc.id
  cidr_block        = var.subnet_cidr2
  availability_zone = var.az2
  map_public_ip_on_launch = true

  tags = {
    Name = "demo-subnet-b"
  }
}

resource "aws_internet_gateway" "demo_igw" {
  vpc_id = aws_vpc.demo_vpc.id

  tags = {
    Name = var.igw_name
  }
}

resource "aws_route_table" "demo_rt" {
  vpc_id = aws_vpc.demo_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.demo_igw.id
  }

  tags = {
    Name = var.rt_name
  }
}

resource "aws_route_table_association" "demo_rta" {
  subnet_id      = aws_subnet.demo_subnet.id
  route_table_id = aws_route_table.demo_rt.id
}

resource "aws_route_table_association" "demo_rta_b" {
  subnet_id      = aws_subnet.demo_subnet_b.id
  route_table_id = aws_route_table.demo_rt.id
}