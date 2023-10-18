variable "name" {
  description = "Replication name"
}

variable "source_bucket_arn" {
  description = "Full bucket name"
  type        = string
}

variable "source_kms_key_arn" {
  description = "Source KMS key ARN"
  type        = string
}

variable "role_name" {
  # Defined within s3 module so we can output without an active replication configuration, this makes the setup easier.
  description = "Role name for replication setup."
  type = string
}

variable "role_path" {
  # Defined within s3 module so we can output without an active replication configuration, this makes the setup easier.
  description = "Role name for replication setup."
  type = string
}

variable "source_replication_configuration" {
  description = "Replication configuration using this bucket as source. The key of the map is used for naming. Use output.replication_target_bucket_arguments from any source buckets you want to replicate to in order to fill this argument if available."
  type = map(object({
    destination_bucket_arn  = string
    destination_aws_account = string
    destination_kms_key_arn = string
  }))
  default = {}
}
