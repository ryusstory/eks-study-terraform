data "aws_availability_zones" "available" {
    state = "available"
}

resource "aws_vpc" "eks" {
    cidr_block           = var.vpc_cidr
    enable_dns_support   = true
    enable_dns_hostnames = true
    tags = {
        Name = "${var.name}-VPC"
    }
}
# eks_worker_subnet -> public_subnet

resource "aws_subnet" "public_subnets" {
    count = length(var.public_subnet_cidrs)

    availability_zone       = data.aws_availability_zones.available.names[count.index]
    cidr_block              = var.public_subnet_cidrs[count.index]
    vpc_id                  = aws_vpc.eks.id
    map_public_ip_on_launch = true
    tags = {
        Name = "${var.name}-eks_worker_subnet${count.index + 1}"
        "kubernetes.io/cluster/${var.name}-eks" = "shared"
        "kubernetes.io/role/elb" = 1
    }
}

resource "aws_internet_gateway" "eks_internet_gateway" {
    vpc_id = aws_vpc.eks.id
}

resource "aws_route_table" "eks_worker_subnet_routingtable" {
    vpc_id = aws_vpc.eks.id
    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.eks_internet_gateway.id
    }
    tags = {
        Name = "${var.name}-eks_worker_subnet_routingtable"
    }
}

resource "aws_route_table_association" "WorkerSubnet1RouteTableAssociations" {
    count = length(aws_subnet.public_subnets)

    subnet_id      = aws_subnet.public_subnets[count.index].id
    route_table_id = aws_route_table.eks_worker_subnet_routingtable.id
}
