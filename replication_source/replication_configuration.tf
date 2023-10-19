data "aws_arn" "bucket" {
  arn = var.source_bucket_arn
}

resource "aws_s3_bucket_replication_configuration" "this" {
  role   = module.replication_role.role_arn
  bucket = data.aws_arn.bucket.resource

  dynamic "rule" {
    for_each = var.source_replication_configuration

    content {
      id = "replication_${rule.key}"

      source_selection_criteria {
        sse_kms_encrypted_objects {
          status = "Enabled"
        }
      }

      filter {}

      status = "Enabled"

      destination {
        account = rule.value.destination_aws_account
        bucket  = rule.value.destination_bucket_arn

        encryption_configuration {
          replica_kms_key_id = rule.value.destination_kms_key_arn
        }
        access_control_translation {
          owner = "Destination"
        }
        storage_class = "STANDARD"
      }

      delete_marker_replication {
        status = "Enabled"
      }
    }
  }
}
