variable "name" {
  description = "Replication name"
}

variable "destination_bucket_arn" {
  description = "Full bucket name"
  type        = string
}

variable "source_role_arn" {
  description = "Source replication role ARN."
  type        = string
}

variable "destination_kms_key_arn" {
  description = "Destination KMS key ARN"
  type        = string
}
