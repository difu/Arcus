resource "aws_launch_configuration" "geoserver_cluster-lc" {
  image_id             = "${data.aws_ami.amazonlinux.image_id}"
  instance_type        = "t2.micro"
  iam_instance_profile = "${aws_iam_instance_profile.arcus-instance-profile.id}"
  security_groups = [
    "${aws_security_group.arcus-public-ssh.id}",
    "${aws_security_group.arcus-public-ssl.id}",
    "${aws_security_group.arcus-public-http.id}",
    "${aws_security_group.arcus-nfs.id}",
  ]
  user_data = <<-EOF
#!/bin/bash
echo "hello, I am WebServer on host " >index.html
`hostname` >> index.html
nohup busybox httpd -f -p 80 &
EOF

  lifecycle {
    create_before_destroy = true
  }
  key_name = "${var.key_name}"
}

data "aws_availability_zones" "allzones" {}

resource "aws_autoscaling_group" "geoerver-autoscale-group" {
  count = "${var.create_geoserver_cluster}"
  launch_configuration = "${aws_launch_configuration.geoserver_cluster-lc.name}"
  availability_zones = [ "${data.aws_availability_zones.allzones.names}"]
  depends_on           = ["aws_launch_configuration.geoserver_cluster-lc",
                        "aws_efs_mount_target.public_a",
                        "aws_efs_mount_target.public_b",
                        "aws_efs_mount_target.public_c"]
  min_size = 1
  max_size = 4
  enabled_metrics = [
    "GroupMinSize",
    "GroupMaxSize",
    "GroupDesiredCapacity",
    "GroupInServiceInstances",
    "GroupTotalInstances"]
  metrics_granularity = "1Minute"
  load_balancers = ["${aws_elb.elb_geoserver.id}"]
  health_check_type = "ELB"
  tags = [
    {
      key                 = "project"
      value               = "${var.project}"
      propagate_at_launch = true
    },
    {
      key                 = "software"
      value               = ""
      propagate_at_launch = true
    },
  ]

}

resource "aws_autoscaling_policy" "autopolicy-up" {
  name = "terraform-autoplicy"
  scaling_adjustment = 1
  adjustment_type = "ChangeInCapacity"
  cooldown = 300
  autoscaling_group_name = "${aws_autoscaling_group.geoerver-autoscale-group.name}"
}

resource "aws_cloudwatch_metric_alarm" "cpualarm-up" {
  alarm_name = "high-cpu-geoserver-cluster-node"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods = "2"
  metric_name = "CPUUtilization"
  namespace = "AWS/EC2"
  period = "120"
  statistic = "Average"
  threshold = "60"

  dimensions {
    AutoScalingGroupName = "${aws_autoscaling_group.geoerver-autoscale-group.name}"
  }

  alarm_description = "This metric monitor EC2 instance cpu utilization"
  alarm_actions = [
    "${aws_autoscaling_policy.autopolicy-up.arn}"]
}

resource "aws_autoscaling_policy" "autopolicy-down" {
  name = "terraform-autoplicy-down"
  scaling_adjustment = -1
  adjustment_type = "ChangeInCapacity"
  cooldown = 300
  autoscaling_group_name = "${aws_autoscaling_group.geoerver-autoscale-group.name}"
}

resource "aws_cloudwatch_metric_alarm" "cpualarm-down" {
  alarm_name = "low-cpu-geoserver-cluster-node"
  comparison_operator = "LessThanOrEqualToThreshold"
  evaluation_periods = "2"
  metric_name = "CPUUtilization"
  namespace = "AWS/EC2"
  period = "120"
  statistic = "Average"
  threshold = "10"

  dimensions {
    AutoScalingGroupName = "${aws_autoscaling_group.geoerver-autoscale-group.name}"
  }

  alarm_description = "EC2 instance cpu utilization"
  alarm_actions = [
    "${aws_autoscaling_policy.autopolicy-down.arn}"]
}

resource "aws_elb" "elb_geoserver" {
  name = "terraform-elb"
  availability_zones = [
    "${data.aws_availability_zones.allzones.names}"]
  security_groups = [
    "${aws_security_group.arcus-public-ssl.id}",
    "${aws_security_group.arcus-public-http.id}",
  ]
  access_logs {
    bucket = "${var.arcus_internal_bucket_name}"
    bucket_prefix = "logs/elb"
    interval = 5
  }
  listener {
    instance_port = 80
    instance_protocol = "http"
    lb_port = 80
    lb_protocol = "http"
  }
  health_check {
    healthy_threshold = 2
    unhealthy_threshold = 2
    timeout = 3
    target = "HTTP:80/"
    interval = 30
  }

  cross_zone_load_balancing = true
  idle_timeout = 400
  connection_draining = true
  connection_draining_timeout = 400

  tags {
    Name = "elb_geoserver"
  }
}

resource "aws_lb_cookie_stickiness_policy" "cookie_stickness" {
  name = "cookiestickness"
  load_balancer = "${aws_elb.elb_geoserver.id}"
  lb_port = 80
  cookie_expiration_period = 600
}

output "availabilityzones" {
  value = [
    "${data.aws_availability_zones.allzones.names}"]
}

output "elb-dns" {
  value = "${aws_elb.elb_geoserver.dns_name}"
}