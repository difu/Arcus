//  The policy allows an instance to forward logs to CloudWatch, and
//  create the Log Stream or Log Group if it doesn't exist.
resource "aws_iam_policy" "forward-logs" {
  name        = "arcus-node-forward-logs"
  path        = "/"
  description = "Allows an instance to forward logs to CloudWatch"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents",
        "logs:DescribeLogStreams"
    ],
      "Resource": [
        "arn:aws:logs:*:*:*"
    ]
  }
 ]
}
    EOF
}

//  This policy allows an instance to discover a arcus cluster leader.
resource "aws_iam_policy" "leader-discovery" {
  name        = "arcus-node-leader-discovery"
  path        = "/"
  description = "This policy allows a arcus server to discover a arcus leader by examining the instances in a arcus cluster Auto-Scaling group. It needs to describe the instances in the auto scaling group, then check the IPs of the instances."

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "Stmt1468377974000",
            "Effect": "Allow",
            "Action": [
                "autoscaling:DescribeAutoScalingInstances",
                "autoscaling:DescribeAutoScalingGroups",
                "ec2:DescribeInstances"
            ],
            "Resource": [
                "*"
            ]
        }
    ]
}
    EOF
}

resource "aws_iam_policy" "Arcus-internal-S3-read" {
  name        = "arcus-node-read-S3"
  path        = "/S3/"
  description = "This policy allows an arcus server to read S3 bucket"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "s3:Get*",
        "s3:List*"
      ],
      "Resource": "*"
    }
  ]
}
    EOF
}


resource "aws_iam_policy" "Arcus-describe-tags" {
  name        = "arcus-describe-tags"
  path        = "/S3/"
  description = "This policy allows an arcus instance to describe tags"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [ "ec2:DescribeTags"],
      "Resource": ["*"]
    }
  ]
}
    EOF
}

//  Create a role which arcus instances will assume.
//  This role has a policy saying it can be assumed by ec2
//  instances.
resource "aws_iam_role" "grib-parse-instance-role" {
  name = "arcus-instance-role"

  assume_role_policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": "sts:AssumeRole",
            "Principal": {
                "Service": "ec2.amazonaws.com"
            },
            "Effect": "Allow",
            "Sid": ""
        }
    ]
}
EOF
}

//  Attach the policies to the role.
resource "aws_iam_policy_attachment" "arcus-instance-forward-logs" {
  name       = "arcus-instance-forward-logs"
  roles      = ["${aws_iam_role.grib-parse-instance-role.name}"]
  policy_arn = "${aws_iam_policy.forward-logs.arn}"
}

resource "aws_iam_policy_attachment" "arcus-instance-leader-discovery" {
  name       = "arcus-instance-leader-discovery"
  roles      = ["${aws_iam_role.grib-parse-instance-role.name}"]
  policy_arn = "${aws_iam_policy.leader-discovery.arn}"
}

resource "aws_iam_policy_attachment" "arcus-instance-S3-read" {
  name       = "arcus-instance-leader-discovery"
  roles      = ["${aws_iam_role.grib-parse-instance-role.name}"]
  policy_arn = "${aws_iam_policy.Arcus-internal-S3-read.arn}"
}

resource "aws_iam_policy_attachment" "arcus-instance-tags-read" {
  name       = "arcus-describe-tags"
  roles      = ["${aws_iam_role.grib-parse-instance-role.name}"]
  policy_arn = "${aws_iam_policy.Arcus-describe-tags.arn}"
}

//  Create a instance profile for the role.
resource "aws_iam_instance_profile" "arcus-instance-profile" {
  name = "grib-parse-instance-profile"
  role = "${aws_iam_role.grib-parse-instance-role.name}"
}
