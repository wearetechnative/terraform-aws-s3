resource "aws_ssm_parameter" "this" {
  name  = "/s3/${var.name}/id"
  type  = "String"
  value = aws_s3_bucket.this.id
}
