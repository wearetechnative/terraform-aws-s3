terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.8.0"
    }
  }
}

provider "aws" {
  region = var.region
}

# KMS key for source bucket encryption
resource "aws_kms_key" "source" {
  description             = "KMS key for source S3 bucket encryption"
  deletion_window_in_days = 10
  enable_key_rotation     = true

  tags = {
    Name        = "${var.name_prefix}-source-key"
    Environment = var.environment
  }
}

resource "aws_kms_alias" "source" {
  name          = "alias/${var.name_prefix}-source-key"
  target_key_id = aws_kms_key.source.key_id
}

# KMS key for target bucket encryption
resource "aws_kms_key" "target" {
  description             = "KMS key for target S3 bucket encryption"
  deletion_window_in_days = 10
  enable_key_rotation     = true

  tags = {
    Name        = "${var.name_prefix}-target-key"
    Environment = var.environment
  }
}

resource "aws_kms_alias" "target" {
  name          = "alias/${var.name_prefix}-target-key"
  target_key_id = aws_kms_key.target.key_id
}

# Target bucket (must be created first for replication configuration)
module "target_bucket" {
  source = "../../"

  name        = "${var.name_prefix}-target"
  kms_key_arn = aws_kms_key.target.arn

  target_replication_configuration = {
    "from-source" = module.source_bucket.replication_target_bucket_arguments
  }

  additional_tags = {
    Name        = "${var.name_prefix}-target"
    Environment = var.environment
    Purpose     = "Replication target"
  }
}

# Source bucket with replication configuration
module "source_bucket" {
  source = "../../"

  name        = "${var.name_prefix}-source"
  kms_key_arn = aws_kms_key.source.arn

  source_replication_configuration = {
    "to-target" = module.target_bucket.replication_source_bucket_arguments["from-source"]
  }

  additional_tags = {
    Name        = "${var.name_prefix}-source"
    Environment = var.environment
    Purpose     = "Replication source"
  }
}
