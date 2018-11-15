/*
resource "aws_volume_attachment" "ebs_opt_oracle" {
  count = "${var.create_oracle_instance}"
  device_name = "/dev/sdh"
  volume_id   = "${aws_ebs_volume.opt_oracle.id}"
  instance_id = "${aws_instance.oracle_instance.id}"
}
*/

resource "aws_instance" "oracle_instance" {
  count = "${var.create_oracle_instance}"
  ami               = "ami-dd3c0f36" // Centos
  availability_zone = "${lookup(var.subnetaz1, var.aws_region)}"
  subnet_id         = "${aws_subnet.public-a.id}"
  instance_type     = "${var.amisize_oracle_instance}"
  iam_instance_profile = "${aws_iam_instance_profile.arcus-instance-profile.id}"
  user_data            = "${data.template_file.bootstrap_all.rendered}"
  key_name = "${var.key_name}"
  root_block_device {
    volume_size = 25
  }
  vpc_security_group_ids = [
    "${aws_security_group.arcus-public-ssh.id}",
    "${aws_security_group.arcus-public-ssl.id}",
    "${aws_security_group.arcus-nfs.id}",
    "${aws_security_group.arcus-public-http.id}",
    "${aws_security_group.arcus-tns.id}",
  ]
  depends_on = ["aws_efs_mount_target.public_a",
                "aws_efs_mount_target.public_b",
                "aws_efs_mount_target.public_c"]
  tags {
    name    = "${var.project} oracle instance"
    project = "${var.project}"
    software = "oracledb"
  }
}

/*
resource "aws_ebs_volume" "opt_oracle" {
  count = "${var.create_oracle_instance}"
  availability_zone = "${lookup(var.subnetaz1, var.aws_region)}"
  size              = 13

  tags {
    name    = "${var.project} oracle opt volume"
    project = "${var.project}"
  }
}*/
