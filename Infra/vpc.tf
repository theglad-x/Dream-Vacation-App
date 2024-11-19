resource "aws_vpc" "vpc" {
  cidr_block           = local.cidr_block
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "${local.name}-k8s-vpc"
  }
}


resource "aws_subnet" "private-us-east-1a" {
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = local.private_subnets_blocks[0]
  availability_zone = local.azs[0]

  tags = {
    "Name"                                        = "${local.name}-k8s-private-us-east-1a"
    "kubernetes.io/role/internal-elb"             = "1"
    "kubernetes.io/cluster/${local.cluster_name}" = "shared"
  }
}


resource "aws_subnet" "private-us-east-1b" {
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = local.private_subnets_blocks[1]
  availability_zone = local.azs[1]

  tags = {
    "Name"                                        = "${local.name}-k8s-private-us-east-1b"
    "kubernetes.io/role/internal-elb"             = "1"
    "kubernetes.io/cluster/${local.cluster_name}" = "shared"
  }
}


resource "aws_subnet" "public-us-east-1a" {
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = local.public_subnets_blocks[0]
  availability_zone       = local.azs[0]
  map_public_ip_on_launch = true

  tags = {
    "Name"                                        = "${local.name}-k8s-public-us-east-1a"
    "kubernetes.io/role/elb"                      = "1"
    "kubernetes.io/cluster/${local.cluster_name}" = "shared"
  }
}


resource "aws_subnet" "public-us-east-1b" {
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = local.public_subnets_blocks[1]
  availability_zone       = local.azs[1]
  map_public_ip_on_launch = true

  tags = {
    "Name"                                        = "${local.name}-k8s-public-us-east-1b"
    "kubernetes.io/role/elb"                      = "1"
    "kubernetes.io/cluster/${local.cluster_name}" = "shared"
  }
}


resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc.id

  tags = {
    Name = "${local.name}-k8s-igw"
  }
}


resource "aws_eip" "eip" {
  depends_on = [aws_internet_gateway.igw]

  tags = {
    Name = "${local.name}-k8s-elastic-ip"
  }
}


resource "aws_nat_gateway" "nat-gw" {
  subnet_id     = aws_subnet.public-us-east-1a.id
  allocation_id = aws_eip.eip.id


  tags = {
    Name = "${local.name}-k8s-nat-gw"
  }

  depends_on = [aws_internet_gateway.igw]
}


resource "aws_route_table" "public-rt" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "${local.name}-public-rt"
  }
}


resource "aws_route_table" "private-rt" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.nat-gw.id
  }

  tags = {
    Name = "${local.name}-private-rt"
  }
}


resource "aws_route_table_association" "public-rta-1a" {
  subnet_id      = aws_subnet.public-us-east-1a.id
  route_table_id = aws_route_table.public-rt.id
}

resource "aws_route_table_association" "public-rta-1b" {
  subnet_id      = aws_subnet.public-us-east-1b.id
  route_table_id = aws_route_table.public-rt.id
}

resource "aws_route_table_association" "private-rta-1a" {
  subnet_id      = aws_subnet.private-us-east-1a.id
  route_table_id = aws_route_table.private-rt.id
}

resource "aws_route_table_association" "private-rta-1b" {
  subnet_id      = aws_subnet.private-us-east-1b.id
  route_table_id = aws_route_table.private-rt.id
}