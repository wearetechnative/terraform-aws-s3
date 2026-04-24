variable "region" {
  description = "AWS region for both buckets (can be the same or different)"
  type        = string
  default     = "eu-west-1"
}

variable "target_account_id" {
  description = "AWS account ID for the target account (where target bucket will be created)"
  type        = string
}

variable "target_account_role_name" {
  description = "Name of the IAM role in target account that Terraform can assume for cross-account access"
  type        = string
  default     = "TerraformCrossAccountRole"
}

variable "name_prefix" {
  description = "Prefix for bucket names (will be combined with -source and -target suffixes)"
  type        = string
  default     = "cross-account-replication"
}

variable "environment" {
  description = "Environment tag for resources"
  type        = string
  default     = "development"
}
