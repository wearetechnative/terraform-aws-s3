variable "primary_region" {
  description = "AWS region for the source bucket"
  type        = string
  default     = "eu-west-1"
}

variable "secondary_region" {
  description = "AWS region for the target bucket (must be different from primary_region)"
  type        = string
  default     = "eu-central-1"
}

variable "name_prefix" {
  description = "Prefix for bucket names (will be combined with -source and -target suffixes)"
  type        = string
  default     = "cross-region-replication"
}

variable "environment" {
  description = "Environment tag for resources"
  type        = string
  default     = "development"
}
