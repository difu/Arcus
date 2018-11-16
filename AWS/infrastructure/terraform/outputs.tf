output "efs_dns" {
  value       = "${aws_efs_file_system.arcus-efs.id}.efs.${var.aws_region}.amazonaws.com"
  description = "DNS name of Arcus EFS"
}
