# Configure lifecycle configuration to either change storage class, delete current version of objects and delete noncurrent version of objects.
resource "aws_s3_bucket_lifecycle_configuration" "this" {
  count = length([ for k, v in var.lifecycle_configuration : k ]) > 0 ? 1 : 0

  bucket = aws_s3_bucket.this.id

  dynamic "rule" {
    for_each = var.lifecycle_configuration
    content {
        id = rule.key

        filter {
            prefix = rule.value.bucket_prefix == "" ? null : rule.value.bucket_prefix
        }

        dynamic "transition" {
            for_each = rule.value.transition == null ? {} : rule.value.transition
            content {
                storage_class = rule.value.transition.storage_class
                days = rule.value.transition.transition_days
            }

        }

        noncurrent_version_expiration {
            newer_noncurrent_versions = rule.value.noncurrent_version_expiration.newer_noncurrent_versions == null ? null : rule.value.noncurrent_version_expiration.newer_noncurrent_versions
            noncurrent_days = rule.value.noncurrent_version_expiration.noncurrent_days == null ? null : rule.value.noncurrent_version_expiration.noncurrent_days
        }

        dynamic "noncurrent_version_transition" {
            for_each = rule.value.noncurrent_version_transition == null ? {} : rule.value.noncurrent_version_transition
            content {
                newer_noncurrent_versions = rule.value.noncurrent_version_transition.newer_noncurrent_versions
                noncurrent_days = rule.value.noncurrent_version_transition.noncurrent_days
                storage_class = rule.value.noncurrent_version_transition.storage_class
            }
        }

        expiration {
            days = rule.value.days == "0" ? null : rule.value.days # must be tested.
            expired_object_delete_marker = rule.value.expired_object_delete_marker == null ? null : rule.value.expired_object_delete_marker
        }

        dynamic "abort_incomplete_multipart_upload" {
            for_each = rule.value.abort_incomplete_multipart_upload == null ? {} : rule.value.abort_incomplete_multipart_upload
            content {
                days_after_initiation = rule.value.abort_incomplete_multipart_upload.days_after_initiation
            }
        }

        status = rule.value.status
    }
  }
}
