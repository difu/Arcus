resource "aws_vpc" "arcus" {
  cidr_block           = "${var.vpc_cidr}"
  enable_dns_hostnames = true

  tags {
    Name    = "Arcus VPC"
    Project = "Arcus"
  }
}

//  Create an Internet Gateway for the VPC
resource "aws_internet_gateway" "arcus-igw" {
  vpc_id = "${aws_vpc.arcus.id}"

  tags {
    Name    = "Arcus IGW"
    Project = "Arcus"
  }
}

//  Create a public subnet for each AZ.
resource "aws_subnet" "public-a" {
  vpc_id                  = "${aws_vpc.arcus.id}"
  cidr_block              = "${var.public_subnet_cidr1}"
  availability_zone       = "${lookup(var.subnetaz1, var.aws_region)}"
  map_public_ip_on_launch = true
  depends_on              = ["aws_internet_gateway.arcus-igw"]

  tags {
    Name    = "Arcus Public Subnet"
    Project = "Arcus"
  }
}

resource "aws_subnet" "public-b" {
  vpc_id                  = "${aws_vpc.arcus.id}"
  cidr_block              = "${var.public_subnet_cidr2}"
  availability_zone       = "${lookup(var.subnetaz2, var.aws_region)}"
  map_public_ip_on_launch = true
  depends_on              = ["aws_internet_gateway.arcus-igw"]

  tags {
    Name    = "Arcus Public Subnet"
    Project = "Arcus"
  }
}

resource "aws_subnet" "public-c" {
  vpc_id                  = "${aws_vpc.arcus.id}"
  cidr_block              = "${var.public_subnet_cidr3}"
  availability_zone       = "${lookup(var.subnetaz3, var.aws_region)}"
  map_public_ip_on_launch = true
  depends_on              = ["aws_internet_gateway.arcus-igw"]

  tags {
    Name    = "Arcus Public Subnet"
    Project = "Arcus"
  }
}

resource "aws_route_table" "public" {
  vpc_id = "${aws_vpc.arcus.id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.arcus-igw.id}"
  }

  tags {
    Name    = "Arcus Public Route Table"
    Project = "Arcus"
  }
}

resource "aws_route_table_association" "public-a" {
  subnet_id      = "${aws_subnet.public-a.id}"
  route_table_id = "${aws_route_table.public.id}"
}

resource "aws_route_table_association" "public-b" {
  subnet_id      = "${aws_subnet.public-b.id}"
  route_table_id = "${aws_route_table.public.id}"
}

resource "aws_route_table_association" "public-c" {
  subnet_id      = "${aws_subnet.public-c.id}"
  route_table_id = "${aws_route_table.public.id}"
}

resource "aws_security_group" "arcus-public-ssh" {
  name        = "arcus-public-ssh"
  description = "Security group that allows SSH traffic from internet"
  vpc_id      = "${aws_vpc.arcus.id}"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags {
    Name    = "Public SSH"
    Project = "Arcus"
  }
}

resource "aws_security_group" "arcus-public-ssl" {
  name        = "arcus-public-ssl"
  description = "Security group that allows SSL traffic to internet"
  vpc_id      = "${aws_vpc.arcus.id}"

  egress {
    from_port   = "443"
    to_port     = "443"
    protocol    = "6"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags {
    Name    = "Public SSL Egress"
    Project = "Arcus"
  }
}

resource "aws_security_group" "arcus-public-http" {
  name        = "arcus-public-http"
  description = "Security group that allows http traffic to internet"
  vpc_id      = "${aws_vpc.arcus.id}"

  egress {
    from_port   = "80"
    to_port     = "80"
    protocol    = "6"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags {
    Name    = "Public http Egress"
    Project = "Arcus"
  }
}