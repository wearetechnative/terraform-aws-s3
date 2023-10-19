resource "aws_s3_bucket_public_access_block" "this" {
  bucket = aws_s3_bucket.this.id

  block_public_acls       = true
  block_public_policy     = var.enable_public_read_access ? false : true
  ignore_public_acls      = true
  restrict_public_buckets = var.enable_public_read_access ? false : true
}
