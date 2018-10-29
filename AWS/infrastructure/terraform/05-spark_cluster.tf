resource "aws_emr_cluster" "arcus-emr-cluster" {
  name          = "emr-test-arn"
  release_label = "emr-5.9.0"
  applications  = ["Spark"]
  count = "${var.create_emr_cluster}"

  ec2_attributes {
    subnet_id                         = "${aws_subnet.public-emr.id}"
    instance_profile                  = "EMR_EC2_DefaultRole"
    emr_managed_master_security_group = "${aws_security_group.arcus_emr_master_sg.id}"
    emr_managed_slave_security_group  = "${aws_security_group.arcus_emr_slave_sg.id}"
    additional_master_security_groups = "${aws_security_group.arcus-public-ssh.id},${aws_security_group.arcus-public-ssl.id}"
    additional_slave_security_groups  = "${aws_security_group.arcus-public-ssh.id},${aws_security_group.arcus-public-ssl.id}"
    key_name = "${var.key_name}"
  }

  master_instance_type = "${var.amisize_emr_master_instance}"
  core_instance_type   = "${var.amisize_emr_core_instance}"
  core_instance_count  = 1
  log_uri = "s3://${var.arcus_internal_bucket_name}/logs/emr"

  tags {
    name     = "${var.project}-emr"
    project = "${var.project}"
  }

  bootstrap_action {
    path = "s3://devel-arcus-internal/run-if"
    name = "runif"
    args = ["instance.isMaster=true", "echo running on master node"]
  }

  configurations = "test-fixtures/emr_configurations.json"

  service_role = "${aws_iam_role.iam_emr_service_role.arn}"
}

resource "aws_security_group" "arcus_emr_master_sg" {
  name        = "arcus_emr_master_sg"
  description = "To be used with AWS managed ingress/egress rules"
  vpc_id      = "${aws_vpc.arcus.id}"

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  lifecycle {
    ignore_changes = ["ingress", "egress"]
  }

  revoke_rules_on_delete = "true"
  depends_on = ["aws_subnet.public-emr"]


  tags {
    name = "${var.project}_emr_master_sg"
    project = "${var.project}"
  }
}

resource "aws_security_group" "arcus_emr_slave_sg" {
  name        = "arcus_emr_slave_sg"
  description = "To be used with AWS managed ingress/egress rules"
  vpc_id      = "${aws_vpc.arcus.id}"

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  lifecycle {
    ignore_changes = ["ingress", "egress"]
  }

  revoke_rules_on_delete = "true"
  depends_on = ["aws_subnet.public-emr"]

  tags {
    name    = "${var.project}_emr_slave_sg"
    project = "${var.project}"
  }
}