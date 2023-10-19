variable "name" {
  description = "Prefix name for S3 bucket."
  type        = string
}

variable "use_fixed_name" {
  description = "Dont generate suffix after var.name to support already created S3 buckets. Not recommended to use this as this makes the S3 module non-portable."
  type        = bool
  default     = false
}

variable "kms_key_arn" {
  description = "KMS key to use for encrypting S3 bucket."
  type        = string
}

variable "bucket_policy_addition" {
  description = "Optional TF Object that converts to policy JSON with jsonencode() to append to current bucket policy which forbids non-encrypted uploads by default. Set an `<bucket>` resource attribute to have it replaced by this module for you."
  type        = any
  default     = null
}

variable "disable_encryption_enforcement" {
  description = "Internal use only. Buckets get a standard policy that prevents un-encrypted uploads or encryption schemes that are not the default encryption. Some services cannot work (Athena CUR) with this policy enabled."
  type        = bool
  default     = false
}

variable "use_sse-s3_encryption_instead_of_sse-kms" {
  description = "Internal use only unless var.enable_public_read_access is true. Enforce SSE-S3 encryption instead of SSE-KMS. This is required if external services only support SSE-S3. This is also a requirement for public buckets."
  type        = bool
  default     = false
}

variable "enable_public_read_access" {
  description = "Enable public read access."
  type        = bool
  default     = false
}

variable "enable_acl" {
  description = "Internal use only. Enable ACL which is disabled by default. This is required in order to use the bucket for CloudFront S3 logging."
  type        = bool
  default     = false
}

variable "additional_tags" {
  description = "Additional tags to be added to resources."
  type        = map(string)
  default     = {}
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

variable "target_replication_configuration" {
  description = "Replication configuration using this bucket as target. The key of the map is used for naming. Use output.replication_source_bucket_arguments from any source buckets you want to replicate to in order to fill this argument if available."
  type = map(object({
    source_role_arn = string
  }))
  default = {}
}

variable "lifecycle_configuration" {
  description = "Object Lifecycle rules configuration."
  type = map(object({
    status = string
    bucket_prefix = string
    transition = object({
      storage_class = string
      transition_days = number
    })
    expiration_days = number
    noncurrent_version_expiration = object({
        newer_noncurrent_versions = number
        noncurrent_days = number
    })
    noncurrent_version_transition = object({
        newer_noncurrent_versions = number
        noncurrent_days = number
        storage_class = string
    })
  }))
  default = {}
}
