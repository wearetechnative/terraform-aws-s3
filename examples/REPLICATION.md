# cross account replication

Probably also works for cross region without issues.

The output `replication_target_bucket_arguments` can be mapped to `var.target_replication_configuration` using e.g. Terraform backend remote state sharing.
The output `replication_source_bucket_arguments` can be mapped to `var.source_replication_configuration` using e.g. Terraform backend remote state sharing.

```hcl
module "s3_source" {
  source = "git@github.com:TechNative-B-V/terraform-aws-module-s3.git?ref=d23eda80e3de956f30f176fc1f2e0cdfa3ac3ae8"

  name                             = var.name
  kms_key_arn                      = var.kms_key_arn
  bucket_policy_addition           = jsondecode(data.aws_iam_policy_document.costandusagereport_s3_access.json)
  disable_encryption_enforcement   = true
  source_replication_configuration = {
    "cur" : {
        destination_bucket_arn  = var.finops_replication_bucket_configuration.destination_bucket_arn
        destination_aws_account = aws_organizations_account.finops.id
        destination_kms_key_arn = var.finops_replication_bucket_configuration.destination_kms_key_arn
    }
  }

  # or using backend sourcing
  source_replication_configuration = <remote_state_fetch>.module.s3_source.replication_source_bucket_arguments
}
```

In another account you could do:

```hcl
module "s3_target" {
  source = "git@github.com:TechNative-B-V/terraform-aws-module-s3.git?ref=d23eda80e3de956f30f176fc1f2e0cdfa3ac3ae8"

  name                             = var.name
  kms_key_arn                      = var.kms_key_arn
  bucket_policy_addition           = jsondecode(data.aws_iam_policy_document.costandusagereport_s3_access.json)
  disable_encryption_enforcement   = true
  target_replication_configuration = {
    "cur" : {
        source_role_arn: "arn:aws:iam::123123123123:role/s3_replication/s3_replication_costandusagereport-athena_csv_cur"
    }
  }

  # or using backend sourcing
  target_replication_configuration = { "cur": <remote_state_fetch>.module.s3_source.replication_target_bucket_arguments.source_role_arn }
}
```


