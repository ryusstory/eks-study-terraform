resource "aws_subnet" "private_subnets" {
    count = length(var.private_subnet_cidrs)

    availability_zone       = data.aws_availability_zones.available.names[count.index]
    cidr_block              = var.private_subnet_cidrs[count.index]
    vpc_id                  = aws_vpc.eks.id
    map_public_ip_on_launch = false
    tags = {
        Name = "${var.name}-private_subnet${count.index + 1}"
        "kubernetes.io/cluster/${var.name}-eks" = "shared"
        "kubernetes.io/role/internal-elb" = 1
    }
}

resource aws_nat_gateway natgw {
  allocation_id = aws_eip.for_natgw.id
  subnet_id     = aws_subnet.public_subnets[0].id
}

resource aws_eip for_natgw {
  vpc      = true
}

resource "aws_route_table" "eks_private_subnet_routingtable" {
    vpc_id = aws_vpc.eks.id
    route {
        cidr_block = "0.0.0.0/0"
        nat_gateway_id = aws_nat_gateway.natgw.id
    }
}

resource "aws_route_table_association" "PrivateSubnetRouteTableAssociations" {
    count = length(aws_subnet.private_subnets)

    subnet_id      = aws_subnet.private_subnets[count.index].id
    route_table_id = aws_route_table.eks_private_subnet_routingtable.id
    depends_on = [
      aws_subnet.private_subnets
    ]
}