data "aws_ami" "amazonlinux" {
  most_recent = true

  owners = ["137112412989"]

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "name"
    values = ["amzn-ami-hvm-*"]
  }
}

resource "aws_launch_configuration" "grib-parse-cluster-lc" {
  name_prefix          = "consul-node-"
  image_id             = "${data.aws_ami.amazonlinux.image_id}"
  instance_type        = "${var.amisize_grib_parse_instance}"
  iam_instance_profile = "${aws_iam_instance_profile.grib-parse-instance-profile.id}"

  security_groups = [
    "${aws_security_group.arcus-public-ssh.id}",
  ]

  lifecycle {
    create_before_destroy = true
  }

  key_name = "${var.key_name}"
}

resource "aws_autoscaling_group" "grib-parse-cluster-asg" {
  depends_on           = ["aws_launch_configuration.grib-parse-cluster-lc"]
  name                 = "grib-parse-cluster-asg"
  launch_configuration = "${aws_launch_configuration.grib-parse-cluster-lc.name}"
  min_size             = "1"
  max_size             = "1"
  vpc_zone_identifier  = ["${aws_subnet.public-a.id}", "${aws_subnet.public-b.id}", "${aws_subnet.public-c.id}"]

  lifecycle {
    create_before_destroy = true
  }

  tag {
    key                 = "Name"
    value               = "Grib parse Node"
    propagate_at_launch = true
  }

  tag {
    key                 = "Project"
    value               = "Arcus"
    propagate_at_launch = true
  }
}