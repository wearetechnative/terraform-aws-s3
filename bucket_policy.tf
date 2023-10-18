resource "aws_s3_bucket_ownership_controls" "this" {
  bucket = aws_s3_bucket.this.id

  rule {
    object_ownership = var.enable_acl ? "BucketOwnerPreferred" : "BucketOwnerEnforced"
  }
}

resource "aws_s3_bucket_policy" "this" {
  bucket = aws_s3_bucket.this.id
  policy = data.aws_iam_policy_document.this.json

  depends_on = [
    aws_s3_bucket_public_access_block.this
  ]
}

data "aws_iam_policy_document" "this" {
  source_policy_documents = concat(data.aws_iam_policy_document.deny_unencrypted_kms[*].json
    , data.aws_iam_policy_document.deny_unencrypted_sse[*].json
    , var.bucket_policy_addition != null ? [jsonencode({
      "Statement" : [for v in var.bucket_policy_addition.Statement : merge(v, { "Resource" : [for s in flatten(concat([v.Resource], [])) : replace(s, "<bucket>", aws_s3_bucket.this.arn)] })]
      "Version" : lookup(var.bucket_policy_addition, "Version", null) != null ? var.bucket_policy_addition.Version : "2012-10-17"
    })] : []
    , [data.aws_iam_policy_document.deny_unencrypted_objectaccess.json]
    , data.aws_iam_policy_document.public_read_access[*].json
    , [data.aws_iam_policy_document.dummy_policy.json]
    , [data.aws_iam_policy_document.deny_obsolete_tls.json]
    , [for k, v in module.replication_target : v.resource_policy_addition]
  )
}

# dummy hack policy to workaround TerraForm limitations and keeping this module simple
# this policy has no effect, this is intended
# this dymmy policy is to always have a resource policy so Terraform will not complain if its existence is conditional on other resource outputs
data "aws_iam_policy_document" "dummy_policy" {
  statement {
    sid = "Dummy policy"

    effect = "Deny"

    actions = ["s3:AbortMultipartUpload"]

    principals {
      type        = "AWS"
      identifiers = [data.aws_caller_identity.current.account_id]
    }

    resources = ["${aws_s3_bucket.this.arn}/I_DO_NO_EXIST"]
  }
}

data "aws_iam_policy_document" "public_read_access" {
  count = var.enable_public_read_access ? 1 : 0

  statement {
    sid = "Allow read only world access"

    effect = "Allow"

    actions = [
      "s3:GetObject",
    ]

    principals {
      type        = "*"
      identifiers = ["*"]
    }

    resources = ["${aws_s3_bucket.this.arn}/*"]
  }
}

data "aws_iam_policy_document" "deny_unencrypted_objectaccess" {
  statement {
    sid = "Prevent always deny unencrypted object access if applicable"

    effect = "Deny"

    actions = [
      "s3:*",
    ]

    principals {
      type        = "*"
      identifiers = ["*"]
    }

    resources = ["${aws_s3_bucket.this.arn}/*"]

    # prevent insecure transports if set
    condition {
      test     = "Null"
      variable = "aws:SecureTransport"
      values   = [false]
    }

    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = [false]
    }
  }
}

data "aws_iam_policy_document" "deny_unencrypted_kms" {
  count = !var.disable_encryption_enforcement && !var.use_sse-s3_encryption_instead_of_sse-kms ? 1 : 0

  statement {
    sid = "Prevent different KMS key other than default if specified"

    effect = "Deny"

    actions = [
      "s3:*",
    ]

    principals {
      type        = "*"
      identifiers = ["*"]
    }

    resources = ["${aws_s3_bucket.this.arn}/*"]

    # prevent uploads from overriding the default encryption
    condition {
      test     = "Null"
      variable = "s3:x-amz-server-side-encryption-aws-kms-key-id"
      values   = [false]
    }

    condition {
      test     = "StringNotEquals"
      variable = "s3:x-amz-server-side-encryption-aws-kms-key-id"
      values   = [var.kms_key_arn]
    }
  }

  statement {
    sid = "Prevent different encryption method other than default if specified"

    effect = "Deny"

    actions = [
      "s3:*",
    ]

    principals {
      type        = "*"
      identifiers = ["*"]
    }

    resources = ["${aws_s3_bucket.this.arn}/*"]

    # prevent uploads from overriding the default encryption
    condition {
      test     = "Null"
      variable = "s3:x-amz-server-side-encryption"
      values   = [false]
    }

    condition {
      test     = "StringNotEquals"
      variable = "s3:x-amz-server-side-encryption"
      values   = ["aws:kms"]
    }
  }
}

data "aws_iam_policy_document" "deny_unencrypted_sse" {
  count = !var.disable_encryption_enforcement && var.use_sse-s3_encryption_instead_of_sse-kms ? 1 : 0

  # https://docs.aws.amazon.com/AmazonS3/latest/userguide/UsingServerSideEncryption.html
  statement {
    sid = "DenyIncorrectEncryptionHeader"

    effect = "Deny"

    actions = [
      "s3:*",
    ]

    principals {
      type        = "*"
      identifiers = ["*"]
    }

    resources = ["${aws_s3_bucket.this.arn}/*"]

    # prevent uploads from overriding the default encryption
    condition {
      test     = "Null"
      variable = "s3:x-amz-server-side-encryption"
      values   = [false]
    }

    condition {
      test     = "StringNotEquals"
      variable = "s3:x-amz-server-side-encryption"
      values   = ["AES256"]
    }
  }
}

# while old TLS is still possible, do a 'smoketest' to see if we run into trouble this will allow us to at least control the moment of enforcement and asses impact before AWS makes that decision
# https://repost.aws/knowledge-center/s3-enforce-modern-tls
data "aws_iam_policy_document" "deny_obsolete_tls" {
  statement {
    sid = "DenyObsoleteTLS"

    effect = "Deny"

    actions = [
      "s3:*",
    ]

    principals {
      type        = "*"
      identifiers = ["*"]
    }

    resources = ["${aws_s3_bucket.this.arn}/*", aws_s3_bucket.this.arn]

    condition {
      test     = "NumericLessThan"
      variable = "s3:TlsVersion"
      values   = ["1.2"]
    }
  }
}
