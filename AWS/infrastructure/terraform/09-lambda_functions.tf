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

data "archive_file" "val_at_coord_zip" {
  type = "zip"
  source_file = "../../lambda/get_value_at_coord/get_value_at_coord.py"
  output_path = "get_value_at_coord.zip"
}

data "archive_file" "get_time_series_zip" {
  type = "zip"
  source_file = "../../lambda/get_time_series/get_time_series.py"
  output_path = "get_time_series.zip"
}

resource "aws_lambda_function" "val_at_coord" {
  filename = "${data.archive_file.val_at_coord_zip.output_path}"
  function_name = "val_at_coord"
  role = "${aws_iam_role.lambda_exec.arn}"
  handler = "get_value_at_coord.lambda_handler"
  runtime = "python3.6"
  layers = [
    "${aws_lambda_layer_version.gdal_layer.id}"
  ]
  source_code_hash = "${base64sha256(file("../../lambda/get_value_at_coord/get_value_at_coord.py"))}"
}

resource "aws_lambda_function" "get_time_series" {
  filename = "${data.archive_file.get_time_series_zip.output_path}"
  function_name = "get_time_series"
  role = "${aws_iam_role.lambda_exec.arn}"
  handler = "get_time_series.lambda_handler"
  runtime = "python3.6"
  layers = [
    "${aws_lambda_layer_version.gdal_layer.id}"
  ]
  source_code_hash = "${base64sha256(file("../../lambda/get_time_series/get_time_series.py"))}"
}

resource "aws_lambda_layer_version" "gdal_layer" {
  s3_bucket = "${var.arcus_internal_bucket_name}"
  s3_key    = "lambda/gdal-layer.zip"
  layer_name = "gdal-layer"

  compatible_runtimes = ["python3.6"]
}

resource "aws_api_gateway_rest_api" "rasterblaster" {
  name        = "RasterBlaster"
  binary_media_types = ["*/*"]
  description = "Allows REST based access on raster data"
}

resource "aws_api_gateway_resource" "proxy" {
  rest_api_id = "${aws_api_gateway_rest_api.rasterblaster.id}"
  parent_id   = "${aws_api_gateway_rest_api.rasterblaster.root_resource_id}"
  path_part   = "get_value_at_coord"
}

resource "aws_api_gateway_resource" "gw_resource_get_time_series" {
  rest_api_id = "${aws_api_gateway_rest_api.rasterblaster.id}"
  parent_id   = "${aws_api_gateway_rest_api.rasterblaster.root_resource_id}"
  path_part   = "get_time_series"
}

resource "aws_api_gateway_method" "gw_method_get_time_series" {
  rest_api_id   = "${aws_api_gateway_rest_api.rasterblaster.id}"
  resource_id   = "${aws_api_gateway_resource.gw_resource_get_time_series.id}"
  http_method   = "ANY"
  authorization = "NONE"
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
  uri                     = "${aws_lambda_function.val_at_coord.invoke_arn}"
}

resource "aws_api_gateway_integration" "gw_integration_get_time_series" {
  rest_api_id = "${aws_api_gateway_rest_api.rasterblaster.id}"
  resource_id = "${aws_api_gateway_method.gw_method_get_time_series.resource_id}"
  http_method = "${aws_api_gateway_method.gw_method_get_time_series.http_method}"

  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = "${aws_lambda_function.get_time_series.invoke_arn}"
}

/*resource "aws_api_gateway_method" "proxy_root" {
  rest_api_id   = "${aws_api_gateway_rest_api.rasterblaster.id}"
  resource_id   = "${aws_api_gateway_rest_api.rasterblaster.root_resource_id}"
  http_method   = "ANY"
  authorization = "NONE"
}*/

/*resource "aws_api_gateway_integration" "lambda_root" {
  rest_api_id = "${aws_api_gateway_rest_api.rasterblaster.id}"
  resource_id = "${aws_api_gateway_method.proxy_root.resource_id}"
  http_method = "${aws_api_gateway_method.proxy_root.http_method}"

  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = "${aws_lambda_function.val_at_coord.invoke_arn}"
}*/

resource "aws_api_gateway_method_response" "200" {
  rest_api_id = "${aws_api_gateway_rest_api.rasterblaster.id}"
  resource_id = "${aws_api_gateway_resource.proxy.id}"
  http_method = "${aws_api_gateway_method.proxy.http_method}"
  status_code = "200"

  response_parameters {
    "method.response.header.Access-Control-Allow-Headers" = true
    "method.response.header.Access-Control-Allow-Methods" = true
    "method.response.header.Access-Control-Allow-Origin"  = true
  }

}

resource "aws_api_gateway_integration_response" "MyDemoIntegrationResponse" {
  rest_api_id = "${aws_api_gateway_rest_api.rasterblaster.id}"
  resource_id = "${aws_api_gateway_resource.proxy.id}"
  http_method = "${aws_api_gateway_method.proxy.http_method}"
  status_code = "${aws_api_gateway_method_response.200.status_code}"
  content_handling = "CONVERT_TO_BINARY"
}

resource "aws_api_gateway_deployment" "rasterblaster_deployment" {
  depends_on = [
    "aws_api_gateway_integration.lambda",
    "aws_api_gateway_integration.gw_integration_get_time_series",
  ]

  rest_api_id = "${aws_api_gateway_rest_api.rasterblaster.id}"
  stage_name  = "test"
}

resource "aws_lambda_permission" "apigw" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = "${aws_lambda_function.val_at_coord.arn}"
  principal     = "apigateway.amazonaws.com"

  # The /*/* portion grants access from any method on any resource
  # within the API Gateway "REST API".
  source_arn = "${aws_api_gateway_deployment.rasterblaster_deployment.execution_arn}/*/*"
}

resource "aws_lambda_permission" "lambda_permission" {
  statement_id  = "AllowMyDemoAPIInvoke"
  action        = "lambda:InvokeFunction"
  function_name = "${aws_lambda_function.get_time_series.arn}"
  principal     = "apigateway.amazonaws.com"

  # The /*/*/* part allows invocation from any stage, method and resource path
  # within API Gateway REST API.
  source_arn = "${aws_api_gateway_deployment.rasterblaster_deployment.execution_arn}/*/*"
}

output "base_url" {
  value = "${aws_api_gateway_deployment.rasterblaster_deployment.invoke_url}"
}