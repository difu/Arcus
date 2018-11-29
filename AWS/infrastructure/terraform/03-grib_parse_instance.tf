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

data "template_file" "bootstrap_all" {
  template = "${file("files/bootstrap_all.sh")}"

  vars {
    internal_bucket_name = "${var.arcus_internal_bucket_name}"
    eccodes_path = "${var.eccodes_path}"
    eccodes_version = "${var.eccodes_version}"
  }
}

resource "aws_launch_configuration" "grib-parse-cluster-lc" {
  name_prefix          = "grib-parse-node-"
  image_id             = "${data.aws_ami.amazonlinux.image_id}"
  instance_type        = "${var.amisize_grib_parse_instance}"
  user_data            = "${data.template_file.bootstrap_all.rendered}"
  iam_instance_profile = "${aws_iam_instance_profile.arcus-instance-profile.id}"

  security_groups = [
    "${aws_security_group.arcus-public-ssh.id}",
    "${aws_security_group.arcus-public-ssl.id}",
    "${aws_security_group.arcus-public-http.id}",
    "${aws_security_group.arcus-nfs.id}",
  ]

  lifecycle {
    create_before_destroy = true
  }

  key_name = "${var.key_name}"
}

resource "aws_autoscaling_group" "grib-parse-cluster-asg" {
  count = "${var.create_grib_parse_cluster}"
  depends_on           = ["aws_launch_configuration.grib-parse-cluster-lc",
                          "aws_efs_mount_target.public_a",
                          "aws_efs_mount_target.public_b",
                          "aws_efs_mount_target.public_c"]
  name                 = "grib-parse-cluster-asg"
  launch_configuration = "${aws_launch_configuration.grib-parse-cluster-lc.name}"
  min_size             = "${var.min_grib_parse_instances}"
  max_size             = "${var.max_grib_parse_instances}"
  vpc_zone_identifier  = ["${aws_subnet.public-a.id}", "${aws_subnet.public-b.id}", "${aws_subnet.public-c.id}"]

  lifecycle {
    create_before_destroy = true
  }


  tags = [
    {
      key                 = "project"
      value               = "${var.project}"
      propagate_at_launch = true
    },
    {
      key                 = "software"
      value               = "oracleclient eccodes gdal"
      propagate_at_launch = true
    },
  ]
}
