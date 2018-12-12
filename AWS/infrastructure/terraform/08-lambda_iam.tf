resource "aws_iam_role" "lambda_exec" {
  name = "lambda_execution_role"
  path = "/LAMBDA/"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "AWSLambdaVPCAccessExecutionRole-role-policy-attach" {
  role = "${aws_iam_role.lambda_exec.name}"
  policy_arn = "${data.aws_iam_policy.AWSLambdaVPCAccessExecutionRole.arn}"
}

resource "aws_iam_policy" "Arcus-internal-lambda-S3-read-write" {
  name        = "arcus-lambda-read-write-S3"
  path        = "/S3/"
  description = "This policy allows a lambda to read-write S3 bucket"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "s3:Get*",
        "s3:List*",
        "s3:Put*"
      ],
      "Resource": "*"
    }
  ]
}
    EOF
}


resource "aws_iam_policy_attachment" "lambda-S3-read" {
  name       = "LambdaS3Read"
  roles      = ["${aws_iam_role.lambda_exec.name}"]
  policy_arn = "${aws_iam_policy.Arcus-internal-lambda-S3-read-write.arn}"
}

data "aws_iam_policy" "AWSLambdaVPCAccessExecutionRole" {
  arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}
