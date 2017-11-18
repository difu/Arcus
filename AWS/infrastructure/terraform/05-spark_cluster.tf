resource "aws_emr_cluster" "arcus-emr-cluster" {
  name          = "emr-test-arn"
  release_label = "emr-5.9.0"
  applications  = ["Spark"]

  ec2_attributes {
    subnet_id                         = "${aws_subnet.public-a.id}"
    instance_profile                  = "EMR_EC2_DefaultRole"
    additional_master_security_groups = "${aws_security_group.arcus-public-ssh.id}"
    additional_slave_security_groups  = "${aws_security_group.arcus-public-ssh.id}"
    key_name = "${var.key_name}"
  }

  master_instance_type = "${var.amisize_emr_master_instance}"
  core_instance_type   = "${var.amisize_emr_core_instance}"
  core_instance_count  = 1
  log_uri = "s3://${var.arcus_internal_bucket_name}/logs"

  tags {
    name     = "arcus-emr"
  }

  bootstrap_action {
    path = "s3://elasticmapreduce/bootstrap-actions/run-if"
    name = "runif"
    args = ["instance.isMaster=true", "echo running on master node"]
  }

  configurations = "test-fixtures/emr_configurations.json"

  service_role = "${aws_iam_role.iam_emr_service_role.arn}"
}
