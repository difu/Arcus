resource "aws_lambda_permission" "allow_bucket" {
  count = "${var.deploy_lambda_convert_grib2geotiff}"
  statement_id  = "AllowExecutionFromS3Bucket"
  action        = "lambda:InvokeFunction"
  function_name = "${aws_lambda_function.lambda_grib2geotiff.function_name}"
  principal     = "s3.amazonaws.com"
  source_arn    = "${aws_s3_bucket.internal_bucket.arn}"
}

resource "aws_vpc_endpoint" "s3" {
  vpc_id       = "${aws_vpc.arcus.id}"
  service_name = "com.amazonaws.eu-central-1.s3" # TODO: Replace with variable
  policy = <<POLICY
    {
        "Version":"2008-10-17",
        "Statement": [
            {
                "Action": "*",
                "Effect": "Allow",
                "Resource": "*",
                "Principal": "*"

            }
        ]
    }
    POLICY
}

resource "aws_vpc_endpoint_route_table_association" "private_s3" {
  vpc_endpoint_id = "${aws_vpc_endpoint.s3.id}"
  route_table_id  = "${aws_route_table.public.id}"
}

resource "aws_lambda_function" "lambda_grib2geotiff" {
  function_name = "Grib2Geotiff"
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
  count = "${var.deploy_lambda_convert_grib2geotiff}"
  bucket = "${aws_s3_bucket.internal_bucket.id}"

  lambda_function {
    lambda_function_arn = "${aws_lambda_function.lambda_grib2geotiff.arn}"
    events              = ["s3:ObjectCreated:*"]
#    filter_prefix       = "AWSLogs/"
#    filter_suffix       = ".log"
  }
}

data "archive_file" "lambda_api_gw_test" {
  type = "zip"
  source_file = "../../lambda/test_api_gw/lambda_function.py"
  output_path = "lambda_api_gw_test.zip"
}

resource "aws_lambda_function" "test_api_gw-lambda" {
  filename = "${data.archive_file.lambda_api_gw_test.output_path}"
  function_name = "test_api_gw-lambda"
  role = "${aws_iam_role.lambda_exec.arn}"
  handler = "lambda_function.lambda_handler"
  runtime = "python3.6"
  source_code_hash = "${base64sha256(file(data.archive_file.lambda_api_gw_test.output_path))}"
}

resource "aws_api_gateway_rest_api" "rasterblaster" {
  name        = "RasterBlaster"
  description = "Allows REST based access on raster data"
}

resource "aws_api_gateway_resource" "proxy" {
  rest_api_id = "${aws_api_gateway_rest_api.rasterblaster.id}"
  parent_id   = "${aws_api_gateway_rest_api.rasterblaster.root_resource_id}"
  path_part   = "{proxy+}"
}

resource "aws_api_gateway_method" "proxy" {
  rest_api_id   = "${aws_api_gateway_rest_api.rasterblaster.id}"
  resource_id   = "${aws_api_gateway_resource.proxy.id}"
  http_method   = "ANY"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "lambda" {
  rest_api_id = "${aws_api_gateway_rest_api.rasterblaster.id}"
  resource_id = "${aws_api_gateway_method.proxy.resource_id}"
  http_method = "${aws_api_gateway_method.proxy.http_method}"

  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = "${aws_lambda_function.test_api_gw-lambda.invoke_arn}"
}

resource "aws_api_gateway_method" "proxy_root" {
  rest_api_id   = "${aws_api_gateway_rest_api.rasterblaster.id}"
  resource_id   = "${aws_api_gateway_rest_api.rasterblaster.root_resource_id}"
  http_method   = "ANY"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "lambda_root" {
  rest_api_id = "${aws_api_gateway_rest_api.rasterblaster.id}"
  resource_id = "${aws_api_gateway_method.proxy_root.resource_id}"
  http_method = "${aws_api_gateway_method.proxy_root.http_method}"

  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = "${aws_lambda_function.test_api_gw-lambda.invoke_arn}"
}

resource "aws_api_gateway_deployment" "rasterblaster_deployment" {
  depends_on = [
    "aws_api_gateway_integration.lambda",
    "aws_api_gateway_integration.lambda_root",
  ]

  rest_api_id = "${aws_api_gateway_rest_api.rasterblaster.id}"
  stage_name  = "test"
}

resource "aws_lambda_permission" "apigw" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = "${aws_lambda_function.test_api_gw-lambda.arn}"
  principal     = "apigateway.amazonaws.com"

  # The /*/* portion grants access from any method on any resource
  # within the API Gateway "REST API".
  source_arn = "${aws_api_gateway_deployment.rasterblaster_deployment.execution_arn}/*/*"
}

output "base_url" {
  value = "${aws_api_gateway_deployment.rasterblaster_deployment.invoke_url}"
}