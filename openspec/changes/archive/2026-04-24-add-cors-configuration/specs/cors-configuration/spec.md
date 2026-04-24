## ADDED Requirements

### Requirement: Accept CORS configuration variable
The module SHALL accept a `cors_rules` variable of type `list(object({...}))` containing CORS rule definitions.

#### Scenario: Empty list disables CORS
- **WHEN** `cors_rules = []` (default)
- **THEN** no `aws_s3_bucket_cors_configuration` resource SHALL be created

#### Scenario: One rule creates CORS configuration
- **WHEN** `cors_rules` contains one rule object
- **THEN** `aws_s3_bucket_cors_configuration` resource SHALL be created with that rule

#### Scenario: Multiple rules creates CORS configuration
- **WHEN** `cors_rules` contains multiple rule objects
- **THEN** `aws_s3_bucket_cors_configuration` resource SHALL be created with all rules in order

### Requirement: CORS rule object structure
Each CORS rule object MUST contain required fields and MAY contain optional fields per AWS S3 API.

#### Scenario: Required fields present
- **WHEN** rule object contains `allowed_methods`, `allowed_origins`, and `allowed_headers`
- **THEN** Terraform validation SHALL pass

#### Scenario: Optional fields included
- **WHEN** rule object contains `expose_headers` and/or `max_age_seconds`
- **THEN** these values SHALL be passed to AWS S3 CORS configuration

#### Scenario: Optional fields omitted
- **WHEN** rule object omits `expose_headers` and/or `max_age_seconds`
- **THEN** Terraform SHALL use null/undefined for these fields (AWS defaults apply)

### Requirement: Validate rule count limit
The module SHALL enforce AWS S3's limit of maximum 100 CORS rules per bucket.

#### Scenario: Rule count within limit
- **WHEN** `cors_rules` contains 100 or fewer rules
- **THEN** Terraform validation SHALL pass

#### Scenario: Rule count exceeds limit
- **WHEN** `cors_rules` contains more than 100 rules
- **THEN** Terraform validation SHALL fail with error message "AWS S3 supports a maximum of 100 CORS rules per bucket"

### Requirement: Validate allowed methods
The module SHALL validate that `allowed_methods` contains only HTTP methods supported by AWS S3.

#### Scenario: Valid HTTP methods
- **WHEN** `allowed_methods` contains only GET, PUT, POST, DELETE, and/or HEAD
- **THEN** Terraform validation SHALL pass

#### Scenario: Invalid HTTP method
- **WHEN** `allowed_methods` contains any value other than GET, PUT, POST, DELETE, HEAD
- **THEN** Terraform validation SHALL fail with error message listing valid methods

### Requirement: Create CORS configuration resource
The module SHALL create `aws_s3_bucket_cors_configuration` resource when `cors_rules` is non-empty.

#### Scenario: Resource not created when empty
- **WHEN** `cors_rules = []`
- **THEN** `aws_s3_bucket_cors_configuration` resource SHALL NOT exist

#### Scenario: Resource created when rules present
- **WHEN** `cors_rules` contains one or more rules
- **THEN** `aws_s3_bucket_cors_configuration` resource SHALL be created
- **THEN** resource SHALL reference `aws_s3_bucket.this.id` as bucket identifier

#### Scenario: Dynamic blocks for multiple rules
- **WHEN** `cors_rules` contains multiple rules
- **THEN** resource SHALL use `dynamic "cors_rule"` blocks to iterate over all rules
- **THEN** each rule SHALL map all fields (allowed_headers, allowed_methods, allowed_origins, expose_headers, max_age_seconds)

### Requirement: Follow module file organization pattern
CORS configuration SHALL follow the existing module pattern of one resource per file.

#### Scenario: Separate file for CORS resource
- **WHEN** CORS configuration is implemented
- **THEN** resource SHALL be defined in `cors.tf` file
- **THEN** file SHALL be at module root level (same directory as lifecycle.tf, versioning.tf, etc.)

### Requirement: Provide usage examples
The module SHALL provide comprehensive CORS usage examples in documentation.

#### Scenario: Examples file exists
- **WHEN** implementation is complete
- **THEN** file `examples/CORS.md` SHALL exist
- **THEN** file SHALL contain multiple example scenarios

#### Scenario: Simple read-only example
- **WHEN** user views examples
- **THEN** examples SHALL include a simple read-only scenario (GET/HEAD methods, specific origin)

#### Scenario: Multiple origins example
- **WHEN** user views examples
- **THEN** examples SHALL include scenario with multiple allowed origins (staging, production)

#### Scenario: File upload example
- **WHEN** user views examples
- **THEN** examples SHALL include scenario with PUT/POST methods for browser uploads

#### Scenario: Security guidance included
- **WHEN** user views examples
- **THEN** documentation SHALL include security considerations section
- **THEN** section SHALL cover wildcard origin risks and method permissiveness

#### Scenario: CloudFront integration notes
- **WHEN** user views examples
- **THEN** documentation SHALL explain CORS with CloudFront (both direct S3 CORS and CloudFront Response Headers Policy)

### Requirement: Update main documentation
The module's main README.md SHALL reference CORS configuration capability.

#### Scenario: README updated
- **WHEN** implementation is complete
- **THEN** README.md SHALL be updated to mention CORS support
- **THEN** README.md SHALL link to examples/CORS.md for detailed examples

#### Scenario: Terraform-docs integration
- **WHEN** terraform-docs regenerates documentation
- **THEN** `cors_rules` variable SHALL appear in variables table with description
