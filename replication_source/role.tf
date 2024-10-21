module "replication_role" {
  source = "git@github.com:wearetechnative/terraform-aws-iam-role?ref=0fe916c27097706237692122e09f323f55e8237e"

  role_name = var.role_name
  role_path = var.role_path

  customer_managed_policies = {
    for k, v in data.aws_iam_policy_document.cross_account_bucket_replication_policy : "${var.name}_${k}" => jsondecode(v.json)
  }

  trust_relationship = {
    "s3" : { "identifier" : "s3.amazonaws.com", "identifier_type" : "Service", "enforce_mfa" : false, "enforce_userprincipal" : false, "external_id" : null, "prevent_account_confuseddeputy" : false }
  }
}

data "aws_iam_policy_document" "cross_account_bucket_replication_policy" {
  for_each = var.source_replication_configuration

  statement {
    sid = "GetSourceBucketConfiguration"

    actions = [
      "s3:ListBucket",
      "s3:GetBucketLocation",
      "s3:GetBucketAcl",
      "s3:GetReplicationConfiguration",
      "s3:GetObjectVersionForReplication",
      "s3:GetObjectVersionAcl",
      "s3:GetObjectVersionTagging"
    ]

    effect = "Allow"

    resources = [
      var.source_bucket_arn,
      "${var.source_bucket_arn}/*"
    ]
  }

  statement {
    sid = "ReplicateToDestinationBucket"

    effect = "Allow"

    actions = [
      "s3:List*",
      "s3:*Object",
      "s3:ReplicateObject",
      "s3:ReplicateDelete",
      "s3:ReplicateTags"
    ]

    resources = [
      "${each.value.destination_bucket_arn}/*"
    ]
  }

  statement {
    sid = "PermissionToOverrideBucketOwner"

    effect = "Allow"

    actions = [
      "s3:ObjectOwnerOverrideToBucketOwner"
    ]

    resources = [
      "${each.value.destination_bucket_arn}/*"
    ]
  }
}

# S3 replication Role kms grant
# https://docs.aws.amazon.com/AmazonS3/latest/userguide/replication-config-for-kms-objects.html
resource "aws_kms_grant" "this" {
  name              = "replication_${var.name}"
  key_id            = var.source_kms_key_arn
  grantee_principal = module.replication_role.role_arn
  operations        = ["Decrypt"]
}
