resource "aws_lambda_permission" "allow_bucket" {
  count = "${var.deploy_lambda_convert_grib2geotiff}"
  statement_id  = "AllowExecutionFromS3Bucket"
  action        = "lambda:InvokeFunction"
  function_name = "${aws_lambda_function.lambda_grib2geotiff.function_name}"
  principal     = "s3.amazonaws.com"
  source_arn    = "${aws_s3_bucket.internal_bucket.arn}"
}

resource "aws_lambda_function" "lambda_grib2geotiff" {
  function_name = "ServerlessExample"
  count = "${var.deploy_lambda_convert_grib2geotiff}"
  s3_bucket = "${var.arcus_internal_bucket_name}"
  s3_key    = "lambda/lambda_grib2geotiff.zip"

  handler = "lambda_function.lambda_handler"
  runtime = "python3.6"

  role = "${aws_iam_role.lambda_exec.arn}"

  vpc_config {
    security_group_ids = [
        "${aws_security_group.arcus-public-ssl.id}",
        "${aws_security_group.arcus-public-http.id}",
    ]
    subnet_ids = [
        "${aws_subnet.public-a.id}",
        "${aws_subnet.public-b.id}",
        "${aws_subnet.public-c.id}",
  ]
  }
}

resource "aws_s3_bucket_notification" "bucket_notification_new_object" {
  bucket = "${aws_s3_bucket.internal_bucket.id}"

  lambda_function {
    lambda_function_arn = "${aws_lambda_function.lambda_grib2geotiff.arn}"
    events              = ["s3:ObjectCreated:*"]
#    filter_prefix       = "AWSLogs/"
#    filter_suffix       = ".log"
  }
}