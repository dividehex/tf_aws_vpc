resource "aws_vpc" "mod" {
  cidr_block = "${var.cidr}"
  enable_dns_hostnames = "${var.enable_dns_hostnames}"
  enable_dns_support = "${var.enable_dns_support}"
  tags { Name = "${var.name}" }
}

resource "aws_internet_gateway" "mod" {
  vpc_id = "${aws_vpc.mod.id}"
}

resource "aws_route_table" "public" {
  vpc_id = "${aws_vpc.mod.id}"
  tags { Name = "${var.name}-public" }
}

resource "aws_route" "public_internet_gateway" {
    route_table_id = "${aws_route_table.public.id}"
    destination_cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.mod.id}"
}

resource "aws_route_table" "private" {
  vpc_id = "${aws_vpc.mod.id}"
  tags { Name = "${var.name}-private" }
}

resource "aws_subnet" "private" {
  vpc_id = "${aws_vpc.mod.id}"
  cidr_block = "${element(var.private_subnets, count.index)}"
  availability_zone = "${element(var.azs_private, count.index)}"
  count = "${length(var.private_subnets)}"
  tags { Name = "${format("%s-private-%d", var.name, count.index + 1)}" }
}

resource "aws_subnet" "public" {
  vpc_id = "${aws_vpc.mod.id}"
  cidr_block = "${element(var.public_subnets, count.index)}"
  availability_zone = "${element(var.azs_public, count.index)}"
  count = "${length(var.public_subnets)}"
  tags { Name = "${format("%s-public-%d", var.name, count.index + 1)}" }

  map_public_ip_on_launch = true
}

resource "aws_route_table_association" "private" {
  count = "${length(var.private_subnets)}"
  subnet_id = "${element(aws_subnet.private.*.id, count.index)}"
  route_table_id = "${aws_route_table.private.id}"
}

resource "aws_route_table_association" "public" {
  count = "${length(var.public_subnets)}"
  subnet_id = "${element(aws_subnet.public.*.id, count.index)}"
  route_table_id = "${aws_route_table.public.id}"
}
