resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "${var.pj_name}-vpc"
  }
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.pj_name}-igw"
  }
}

# Elastic IP（NATゲートウェイ用のパブリックIPを割り当て）
resource "aws_eip" "nat_gw" {
  domain = "vpc" # VPC用EIP
  tags = {
    Name = "${var.pj_name}-nat-eip"
  }
}

# NATゲートウェイ
resource "aws_nat_gateway" "main" {
  subnet_id     = aws_subnet.public[0].id
  allocation_id = aws_eip.nat_gw.id

  tags = {
    Name = "${var.pj_name}-nat-gw"
  }
}


# パブリックサブネット
resource "aws_subnet" "public" {
  count = length(var.alb_public_subnets)

  vpc_id            = aws_vpc.main.id
  cidr_block        = var.alb_public_subnets[count.index].cidr
  availability_zone = var.alb_public_subnets[count.index].az

  tags = {
    Name = "${var.pj_name}-public-${var.alb_public_subnets[count.index].az}-subnet"
  }
}

# パブリックサブネット用RT
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.pj_name}-public-rt"
  }
}
resource "aws_route" "public_default_route" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.main.id
}
# 各パブリックサブネットをルートテーブルに関連付ける
resource "aws_route_table_association" "public" {
  count = length(aws_subnet.public)

  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}


# プライベートサブネット（Webサーバ)
resource "aws_subnet" "web_private" {
  count = length(var.web_private_subnets)

  vpc_id            = aws_vpc.main.id
  cidr_block        = var.web_private_subnets[count.index].cidr
  availability_zone = var.web_private_subnets[count.index].az

  tags = {
    Name = "${var.pj_name}-web-private-${var.web_private_subnets[count.index].az}-subnet"
  }
}

# プライベートサブネット（DBサーバ)
resource "aws_subnet" "db_private" {
  count = length(var.db_private_subnets)

  vpc_id            = aws_vpc.main.id
  cidr_block        = var.db_private_subnets[count.index].cidr
  availability_zone = var.db_private_subnets[count.index].az

  tags = {
    Name = "${var.pj_name}-db-private-${var.db_private_subnets[count.index].az}-subnet"
  }
}

# プライベートサブネット用RT
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.pj_name}-private-rt"
  }
}
resource "aws_route" "private_default_route" {
  route_table_id         = aws_route_table.private.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_nat_gateway.main.id
}
locals {
  all_private_subnets = concat(aws_subnet.web_private[*].id, aws_subnet.db_private[*].id)
}
# 各プライベートサブネットをルートテーブルに関連付ける
resource "aws_route_table_association" "private" {
  count = length((local.all_private_subnets))

  subnet_id      = local.all_private_subnets[count.index]
  route_table_id = aws_route_table.private.id
}
