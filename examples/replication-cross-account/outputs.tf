output "source_bucket_name" {
  description = "Name of the source S3 bucket in the source account"
  value       = module.source_bucket.s3_bucket_name
}

output "source_bucket_arn" {
  description = "ARN of the source S3 bucket in the source account"
  value       = module.source_bucket.s3_arn
}

output "target_bucket_name" {
  description = "Name of the target S3 bucket in the target account"
  value       = module.target_bucket.s3_bucket_name
}

output "target_bucket_arn" {
  description = "ARN of the target S3 bucket in the target account"
  value       = module.target_bucket.s3_arn
}

output "source_kms_key_arn" {
  description = "ARN of the KMS key used for source bucket encryption"
  value       = aws_kms_key.source.arn
}

output "target_kms_key_arn" {
  description = "ARN of the KMS key used for target bucket encryption"
  value       = aws_kms_key.target.arn
}

output "target_account_id" {
  description = "AWS account ID of the target account"
  value       = var.target_account_id
}
