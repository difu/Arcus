resource "aws_efs_file_system" "arcus-efs" {
  creation_token = "arcus-efs-token"

  tags {
    Name = "${var.project} shared NFS storage"
  }
}

resource "aws_efs_mount_target" "public_a" {
  file_system_id = "${aws_efs_file_system.arcus-efs.id}"
  subnet_id      = "${aws_subnet.public-a.id}"
  security_groups = ["${aws_security_group.arcus-nfs.id}"]
}

resource "aws_efs_mount_target" "public_b" {
  file_system_id = "${aws_efs_file_system.arcus-efs.id}"
  subnet_id      = "${aws_subnet.public-b.id}"
  security_groups = ["${aws_security_group.arcus-nfs.id}"]
}

resource "aws_efs_mount_target" "public_c" {
  file_system_id = "${aws_efs_file_system.arcus-efs.id}"
  subnet_id      = "${aws_subnet.public-c.id}"
  security_groups = ["${aws_security_group.arcus-nfs.id}"]
}