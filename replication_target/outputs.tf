output "replication_source_arguments" {
  value = {
    destination_bucket_arn  = var.destination_bucket_arn
    destination_aws_account = data.aws_caller_identity.current.account_id
    destination_kms_key_arn = var.destination_kms_key_arn
  }
}

output "resource_policy_addition" {
  value = data.aws_iam_policy_document.this.json
}
