output "s3_arn" {
  value = aws_s3_bucket.this.arn
}

output "s3_id" {
  value = aws_s3_bucket.this.id
}
output "s3_name_parameter_arn" {
  value = aws_ssm_parameter.this.arn
}

output "s3_bucket_name" {
  value = aws_s3_bucket.this.bucket
}

output "kms_key_arn" {
  value = var.kms_key_arn
}

# regional is better than global since global has redirects and is being deprecated
output "website_regional_domain" {
  value = aws_s3_bucket.this.bucket_regional_domain_name
}

output "replication_target_bucket_arguments" {
  value = {
    "source_role_arn": "arn:${data.aws_partition.current.partition}:iam::${data.aws_caller_identity.current.id}:role/${local.s3_replication_role_path}${local.s3_replication_role_name}"
  }
}

output "replication_source_bucket_arguments" {
  value = { for k, v in module.replication_target : k => v.replication_source_arguments }
}
