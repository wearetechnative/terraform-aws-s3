variable "region" {
  description = "AWS region where buckets will be created"
  type        = string
  default     = "eu-west-1"
}

variable "name_prefix" {
  description = "Prefix for bucket names (will be combined with -source and -target suffixes)"
  type        = string
  default     = "replication-example"
}

variable "environment" {
  description = "Environment tag for resources"
  type        = string
  default     = "development"
}
