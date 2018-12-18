output "efs_dns" {
  value       = "${aws_efs_file_system.arcus-efs.id}.efs.${var.aws_region}.amazonaws.com"
  description = "DNS name of Arcus EFS"
}

output "api_gw_rasterblaster" {
  value = "${aws_api_gateway_deployment.rasterblaster_deployment.invoke_url}"
}
