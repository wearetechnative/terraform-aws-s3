data "aws_iam_policy_document" "this" {
  statement {
    sid = "s3_replication_${var.name}"

    principals {
      type        = "AWS"
      identifiers = [var.source_role_arn]
    }

    actions = [
      "s3:ReplicateDelete",
      "s3:PutBucketVersioning",
      "s3:List*",
      "s3:GetBucketVersioning",
      "s3:Replicate*"
    ]

    resources = ["${var.destination_bucket_arn}/*", var.destination_bucket_arn]
  }
}
