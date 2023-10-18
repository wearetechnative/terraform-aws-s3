# S3 replication Role kms grant
# https://docs.aws.amazon.com/AmazonS3/latest/userguide/replication-config-for-kms-objects.html
resource "aws_kms_grant" "this" {
  name              = "replication_target_${var.name}"
  key_id            = var.destination_kms_key_arn
  grantee_principal = var.source_role_arn
  operations        = ["Encrypt", "GenerateDataKey"]
}
