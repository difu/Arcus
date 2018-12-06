resource "aws_s3_bucket" "internal_bucket" {
  # (resource arguments)
}

# terraform import aws_s3_bucket.internal_bucket devel-arcus-internal
# terraform state rm aws_s3_bucket.internal_bucket