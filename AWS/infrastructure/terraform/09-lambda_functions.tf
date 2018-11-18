resource "aws_lambda_function" "lambda_grib2geotiff" {
  function_name = "ServerlessExample"
  count = "${var.deploy_lambda_convert_grib2geotiff}"
  s3_bucket = "${var.arcus_internal_bucket_name}"
  s3_key    = "lambda/lambda_grib2geotiff.zip"

  handler = "lambda_function.lambda_handler"
  runtime = "python3.6"

  role = "${aws_iam_role.lambda_exec.arn}"
}