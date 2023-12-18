resource "aws_s3_bucket" "this" {
  bucket        = var.use_fixed_name ? replace(var.name, "_", "-") : null
  bucket_prefix = var.use_fixed_name ? null : "${replace(var.name, "_", "-")}-"
  force_destroy = false

  lifecycle {
    prevent_destroy = true
  }

  tags = merge(var.additional_tags,
    {
      Type          = "RDS",
      BackupEnabled = "${var.enable_backup}",
      BackupEnabled = locals.backup
  })
}
