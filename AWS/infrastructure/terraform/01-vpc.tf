resource "aws_vpc" "arcus" {
  cidr_block           = "${var.vpc_cidr}"
  enable_dns_hostnames = true

  tags {
    name    = "${var.project} VPC"
    project = "Arcus"
  }
}

//  Create an Internet Gateway for the VPC
resource "aws_internet_gateway" "arcus-igw" {
  vpc_id = "${aws_vpc.arcus.id}"

  tags {
    name    = "${var.project} IGW"
    project = "Arcus"
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
    name    = "${var.project} Public Subnet A"
    project = "${var.project}"
  }
}

resource "aws_subnet" "public-b" {
  vpc_id                  = "${aws_vpc.arcus.id}"
  cidr_block              = "${var.public_subnet_cidr2}"
  availability_zone       = "${lookup(var.subnetaz2, var.aws_region)}"
  map_public_ip_on_launch = true
  depends_on              = ["aws_internet_gateway.arcus-igw"]

  tags {
    name    = "${var.project} Public Subnet B"
    project = "${var.project}"
  }
}

resource "aws_subnet" "public-c" {
  vpc_id                  = "${aws_vpc.arcus.id}"
  cidr_block              = "${var.public_subnet_cidr3}"
  availability_zone       = "${lookup(var.subnetaz3, var.aws_region)}"
  map_public_ip_on_launch = true
  depends_on              = ["aws_internet_gateway.arcus-igw"]

  tags {
    name    = "${var.project} Public Subnet C"
    project = "${var.project}"
  }
}

resource "aws_subnet" "public-emr" {
  vpc_id                  = "${aws_vpc.arcus.id}"
  cidr_block              = "${var.public_subnet_cidr_emr}"
  map_public_ip_on_launch = true
  depends_on              = ["aws_internet_gateway.arcus-igw"]

  tags {
    name    = "${var.project} Public Subnet EMR"
    project = "${var.project}"
  }
}

resource "aws_route_table" "public" {
  vpc_id = "${aws_vpc.arcus.id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.arcus-igw.id}"
  }

  tags {
    name    = "${var.project} Public Route Table"
    project = "${var.project}"
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

resource "aws_route_table_association" "public-emr" {
  subnet_id      = "${aws_subnet.public-emr.id}"
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
    name    = "${var.project} Public SSH"
    project = "${var.project}"
  }
}

resource "aws_security_group" "arcus-public-ssl" {
  name        = "${var.project}-public-ssl"
  description = "Security group that allows SSL traffic to internet"
  vpc_id      = "${aws_vpc.arcus.id}"

  egress {
    from_port   = "443"
    to_port     = "443"
    protocol    = "6"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags {
    name    = "${var.project} Public SSL Egress"
    project = "${var.project}"
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
    name    = "${var.project} Public http Egress"
    project = "${var.project}"
  }
}

resource "aws_security_group" "arcus-nfs" {
  name        = "arcus-public-nfs"
  description = "Security group that allows nfs connection"
  vpc_id      = "${aws_vpc.arcus.id}"

  egress {
    from_port   = "2049"
    to_port     = "2049"
    protocol    = "6"
    cidr_blocks = ["${var.vpc_cidr}",]
  }

   ingress {
    from_port   = "2049"
    to_port     = "2049"
    protocol    = "6"
    cidr_blocks = ["${var.vpc_cidr}",]
  }

  tags {
    name    = "${var.project} NFS Ingress/Egress"
    project = "${var.project}"
  }
}

resource "aws_security_group" "arcus-tns" {
  name        = "arcus-public-tns"
  description = "Security group that allows nfs connection"
  vpc_id      = "${aws_vpc.arcus.id}"

  egress {
    from_port   = "1521"
    to_port     = "1521"
    protocol    = "6"
    cidr_blocks = ["${var.vpc_cidr}",]
  }

   ingress {
    from_port   = "1521"
    to_port     = "1521"
    protocol    = "6"
    cidr_blocks = ["${var.vpc_cidr}",]
  }

  tags {
    name    = "${var.project} TNS Ingress/Egress"
    project = "${var.project}"
  }
}