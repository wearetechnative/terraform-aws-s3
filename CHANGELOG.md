# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

## NEXT VERSION

### Added
- **CORS Configuration**: Support for configuring CORS rules via `cors_rules` variable to enable cross-origin browser access to S3 buckets
- **Replication Examples**: Complete working examples for S3 replication configurations
  - Same-region replication example with KMS encryption
  - Cross-region replication example with multi-region provider setup
  - Cross-account replication example with IAM role trust relationships
  - Each example includes comprehensive README with setup, verification, and troubleshooting guidance
