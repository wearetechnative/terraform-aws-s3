locals {
  s3_replication_role_name = "s3_replication_${var.name}"
  s3_replication_role_path = "/s3_replication/"
}

module "replication_source" {
  count = length([ for k, v in var.source_replication_configuration : k ]) > 0 ? 1 : 0
  source   = "./replication_source"

  name                    = var.name
  role_name = local.s3_replication_role_name
  role_path = local.s3_replication_role_path
  source_bucket_arn       = aws_s3_bucket.this.arn
  source_kms_key_arn      = var.kms_key_arn
  source_replication_configuration = var.source_replication_configuration
}

module "replication_target" {
  for_each = var.target_replication_configuration
  source   = "./replication_target"

  name                    = "${var.name}_${each.key}"
  destination_bucket_arn  = aws_s3_bucket.this.arn
  source_role_arn         = each.value.source_role_arn
  destination_kms_key_arn = var.kms_key_arn
}
