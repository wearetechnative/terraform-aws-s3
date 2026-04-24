## ADDED Requirements

### Requirement: Example directory structure
The module SHALL provide an `examples/` directory at the repository root containing subdirectories for each replication scenario.

#### Scenario: User navigates to examples
- **WHEN** user opens the repository
- **THEN** an `examples/` directory exists at the root level
- **THEN** subdirectories exist for each replication type (same-region, cross-region, cross-account)

### Requirement: Same-region replication example
The module SHALL provide a complete working example demonstrating same-region replication between two S3 buckets.

#### Scenario: User implements same-region replication
- **WHEN** user navigates to `examples/replication-same-region/`
- **THEN** a `main.tf` file exists showing source and target bucket configuration
- **THEN** a `README.md` file exists explaining the setup and prerequisites
- **THEN** the example uses the module's replication_source and replication_target outputs
- **THEN** all required variables are documented with example values

#### Scenario: User runs same-region example
- **WHEN** user runs `terraform apply` in the example directory
- **THEN** two S3 buckets are created in the same region
- **THEN** replication configuration is established from source to target
- **THEN** objects uploaded to source bucket replicate to target bucket

### Requirement: Cross-region replication example
The module SHALL provide a complete working example demonstrating cross-region replication between two S3 buckets in different AWS regions.

#### Scenario: User implements cross-region replication
- **WHEN** user navigates to `examples/replication-cross-region/`
- **THEN** a `main.tf` file exists showing multi-region provider configuration
- **THEN** a `README.md` file exists explaining region setup and KMS key requirements
- **THEN** the example demonstrates source bucket in one region and target in another
- **THEN** separate KMS keys are configured for each region
- **THEN** the output-to-input pattern for replication_target_bucket_arguments is demonstrated

#### Scenario: User runs cross-region example
- **WHEN** user runs `terraform apply` in the example directory
- **THEN** source bucket is created in the primary region
- **THEN** target bucket is created in the secondary region
- **THEN** replication configuration spans both regions
- **THEN** objects uploaded to source bucket replicate to target bucket in different region

### Requirement: Cross-account replication example
The module SHALL provide a complete working example demonstrating cross-account replication between S3 buckets owned by different AWS accounts.

#### Scenario: User implements cross-account replication
- **WHEN** user navigates to `examples/replication-cross-account/`
- **THEN** a `main.tf` file exists showing multi-account provider configuration
- **THEN** a `README.md` file exists explaining IAM role requirements and account setup
- **THEN** the example demonstrates source bucket in one account and target in another
- **THEN** IAM role trust relationships are documented
- **THEN** bucket policy configurations for cross-account access are shown

#### Scenario: User runs cross-account example
- **WHEN** user runs `terraform apply` in the example directory with proper credentials
- **THEN** source bucket is created in the source account
- **THEN** target bucket is created in the target account
- **THEN** replication role has permissions to write to target account bucket
- **THEN** objects uploaded to source bucket replicate to target bucket in different account

### Requirement: Example documentation
Each replication example SHALL include comprehensive README.md documentation.

#### Scenario: User reads example README
- **WHEN** user opens an example's README.md
- **THEN** prerequisites are clearly listed (AWS accounts, regions, permissions)
- **THEN** step-by-step setup instructions are provided
- **THEN** required variables are documented with descriptions
- **THEN** expected outputs are explained
- **THEN** how to verify replication is working is documented

### Requirement: Main README integration
The main module README.md SHALL reference the replication examples.

#### Scenario: User discovers examples from main README
- **WHEN** user reads the main README.md
- **THEN** a section exists linking to the examples directory
- **THEN** brief descriptions of each example type are provided
- **THEN** links to specific example directories are included

### Requirement: CHANGELOG documentation
The CHANGELOG.md SHALL document the addition of replication examples.

#### Scenario: User reads CHANGELOG
- **WHEN** user opens CHANGELOG.md
- **THEN** an entry exists under "## NEXT VERSION"
- **THEN** the entry is under "### Added" section
- **THEN** the addition of replication examples is clearly described
- **THEN** the types of examples (same-region, cross-region, cross-account) are listed
