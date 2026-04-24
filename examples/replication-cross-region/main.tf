terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.8.0"
    }
  }
}

# Primary region provider (source bucket)
provider "aws" {
  alias  = "primary"
  region = var.primary_region
}

# Secondary region provider (target bucket)
provider "aws" {
  alias  = "secondary"
  region = var.secondary_region
}

# KMS key for source bucket in primary region
resource "aws_kms_key" "source" {
  provider = aws.primary

  description             = "KMS key for source S3 bucket encryption"
  deletion_window_in_days = 10
  enable_key_rotation     = true

  tags = {
    Name        = "${var.name_prefix}-source-key"
    Environment = var.environment
    Region      = var.primary_region
  }
}

resource "aws_kms_alias" "source" {
  provider = aws.primary

  name          = "alias/${var.name_prefix}-source-key"
  target_key_id = aws_kms_key.source.key_id
}

# KMS key for target bucket in secondary region
resource "aws_kms_key" "target" {
  provider = aws.secondary

  description             = "KMS key for target S3 bucket encryption"
  deletion_window_in_days = 10
  enable_key_rotation     = true

  tags = {
    Name        = "${var.name_prefix}-target-key"
    Environment = var.environment
    Region      = var.secondary_region
  }
}

resource "aws_kms_alias" "target" {
  provider = aws.secondary

  name          = "alias/${var.name_prefix}-target-key"
  target_key_id = aws_kms_key.target.key_id
}

# Target bucket in secondary region (must be created first for replication configuration)
module "target_bucket" {
  source = "../../"

  providers = {
    aws = aws.secondary
  }

  name        = "${var.name_prefix}-target"
  kms_key_arn = aws_kms_key.target.arn

  target_replication_configuration = {
    "from-source" = module.source_bucket.replication_target_bucket_arguments
  }

  additional_tags = {
    Name        = "${var.name_prefix}-target"
    Environment = var.environment
    Region      = var.secondary_region
    Purpose     = "Cross-region replication target"
  }
}

# Source bucket in primary region with replication configuration
module "source_bucket" {
  source = "../../"

  providers = {
    aws = aws.primary
  }

  name        = "${var.name_prefix}-source"
  kms_key_arn = aws_kms_key.source.arn

  source_replication_configuration = {
    "to-target" = module.target_bucket.replication_source_bucket_arguments["from-source"]
  }

  additional_tags = {
    Name        = "${var.name_prefix}-source"
    Environment = var.environment
    Region      = var.primary_region
    Purpose     = "Cross-region replication source"
  }
}
