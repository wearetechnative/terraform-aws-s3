terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.8.0"
    }
  }
}

# Source account provider (where source bucket lives)
provider "aws" {
  alias  = "source_account"
  region = var.region
}

# Target account provider (where target bucket lives)
# This example assumes you use assume_role for cross-account access
provider "aws" {
  alias  = "target_account"
  region = var.region

  assume_role {
    role_arn = "arn:aws:iam::${var.target_account_id}:role/${var.target_account_role_name}"
  }
}

# KMS key for source bucket in source account
resource "aws_kms_key" "source" {
  provider = aws.source_account

  description             = "KMS key for source S3 bucket encryption"
  deletion_window_in_days = 10
  enable_key_rotation     = true

  tags = {
    Name        = "${var.name_prefix}-source-key"
    Environment = var.environment
    Account     = "source"
  }
}

resource "aws_kms_alias" "source" {
  provider = aws.source_account

  name          = "alias/${var.name_prefix}-source-key"
  target_key_id = aws_kms_key.source.key_id
}

# KMS key for target bucket in target account
resource "aws_kms_key" "target" {
  provider = aws.target_account

  description             = "KMS key for target S3 bucket encryption"
  deletion_window_in_days = 10
  enable_key_rotation     = true

  tags = {
    Name        = "${var.name_prefix}-target-key"
    Environment = var.environment
    Account     = "target"
  }
}

resource "aws_kms_alias" "target" {
  provider = aws.target_account

  name          = "alias/${var.name_prefix}-target-key"
  target_key_id = aws_kms_key.target.key_id
}

# Target bucket in target account (must be created first for replication configuration)
module "target_bucket" {
  source = "../../"

  providers = {
    aws = aws.target_account
  }

  name        = "${var.name_prefix}-target"
  kms_key_arn = aws_kms_key.target.arn

  target_replication_configuration = {
    "from-source" = module.source_bucket.replication_target_bucket_arguments
  }

  additional_tags = {
    Name        = "${var.name_prefix}-target"
    Environment = var.environment
    Account     = "target"
    Purpose     = "Cross-account replication target"
  }
}

# Source bucket in source account with replication configuration
module "source_bucket" {
  source = "../../"

  providers = {
    aws = aws.source_account
  }

  name        = "${var.name_prefix}-source"
  kms_key_arn = aws_kms_key.source.arn

  source_replication_configuration = {
    "to-target" = module.target_bucket.replication_source_bucket_arguments["from-source"]
  }

  additional_tags = {
    Name        = "${var.name_prefix}-source"
    Environment = var.environment
    Account     = "source"
    Purpose     = "Cross-account replication source"
  }
}
