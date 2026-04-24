## Context

The Terraform AWS S3 module follows a security-first design with explicit opt-in for features. Each S3 bucket configuration aspect (versioning, lifecycle, encryption, replication) gets its own Terraform file. CORS configuration fits naturally into this pattern.

**Current State:**
- Module README.md (line 11) previously stated users could "externally attach" CORS configuration
- However, lifecycle configuration is now wrapped in the module (lifecycle.tf), showing evolution toward more comprehensive feature coverage
- No CORS support means users must create separate `aws_s3_bucket_cors_configuration` resources outside the module

**Documenso Use Case:**
- Web application at https://app.example.com needs to fetch documents directly from S3
- Browser same-origin policy blocks this without CORS headers
- Requires S3 bucket to return appropriate `Access-Control-Allow-Origin` headers

## Goals / Non-Goals

**Goals:**
- Add CORS configuration support following existing module patterns
- Maximum flexibility: support 0 to 100 CORS rules per bucket
- Minimal validation: only prevent AWS API errors
- Support both direct S3 access and CloudFront-fronted architectures
- Provide comprehensive examples for common use cases
- Maintain security-first philosophy (opt-in, no insecure defaults)

**Non-Goals:**
- Opinionated security validations (e.g., blocking wildcard origins) - trust users
- CloudFront-specific CORS handling (that's CloudFront configuration, not S3)
- Automatic CORS configuration based on other variables (explicit is better)
- Backwards compatibility concerns (this is purely additive)

## Decisions

### Decision 1: Variable Structure - List of Objects

**Choice:** `cors_rules = list(object({...}))`

**Rationale:**
- Directly mirrors AWS API structure (one-to-one mapping)
- Supports multiple CORS rules (up to AWS limit of 100)
- Terraform's `dynamic` blocks make this clean to implement
- Matches pattern used by existing variables like `lifecycle_configuration`

**Alternatives Considered:**
- Single object (non-list): Too restrictive, some buckets need multiple rules for different origins
- Map with named rules: Adds unnecessary abstraction, keys would be arbitrary

### Decision 2: Optional Fields

**Choice:** Make `expose_headers` and `max_age_seconds` optional using Terraform's `optional()` type

**Rationale:**
- These are optional in AWS API
- Common case only needs `allowed_methods`, `allowed_origins`, `allowed_headers`
- Reduces boilerplate in simple configurations

**Required Fields:**
- `allowed_methods` - always required by AWS
- `allowed_origins` - always required by AWS
- `allowed_headers` - technically optional in AWS, but making required forces users to think about it

### Decision 3: Validation Strategy - Minimal

**Choice:** Only validate what would cause AWS API errors

Validations to include:
- Rule count ≤ 100 (AWS limit)
- `allowed_methods` contains only: GET, PUT, POST, DELETE, HEAD

Validations to skip:
- Wildcard origin warnings
- Method permissiveness checks
- Header validation beyond AWS requirements

**Rationale:**
- Aligns with module philosophy: trust users to understand security
- Terraform validation is binary (error or pass) - no warnings
- Security guidance belongs in documentation, not code enforcement

**Alternatives Considered:**
- Strict validation: Would block legitimate use cases and annoy experienced users
- No validation: Would lead to confusing AWS API errors during apply

### Decision 4: File Organization

**Choice:** Create `cors.tf` following existing pattern

**Rationale:**
- Consistent with module structure: lifecycle.tf, versioning.tf, kms.tf, etc.
- One resource per file makes code navigable
- Conditional resource creation using `count = length(var.cors_rules) > 0 ? 1 : 0`

### Decision 5: Documentation Structure

**Choice:** Create `examples/CORS.md` with multiple scenarios

**Sections:**
1. Simple read-only access (Documenso use case)
2. Multiple origins (staging + production)
3. File upload from browser (PUT/POST methods)
4. Multiple CORS rules on same bucket
5. CloudFront integration notes
6. Security considerations

**Rationale:**
- Matches existing pattern (examples/LIFECYCLE_RULE.md, examples/REPLICATION.md)
- Self-contained examples users can copy-paste
- Security guidance without code enforcement

## Risks / Trade-offs

### Risk: Users configure insecure CORS

**Mitigation:**
- Comprehensive security section in examples/CORS.md
- Clear examples showing secure patterns (specific origins, minimal methods)
- Document risks of wildcard origins with write methods

### Risk: CORS + public_read_access confusion

**Mitigation:**
- Document that CORS ≠ public access
- Explain: CORS controls browser behavior, bucket policy controls who can read
- Example showing private bucket + presigned URLs + CORS pattern

### Risk: CloudFront users expect different behavior

**Mitigation:**
- Dedicated section in examples/CORS.md explaining CloudFront scenarios
- Note that CloudFront can handle CORS via Response Headers Policy OR forward S3 CORS
- This module's CORS config works for both direct S3 and CloudFront-fronted buckets

### Trade-off: No validation warnings

**Accepted:** Terraform doesn't support warning-level validations (only errors)
- Could add opinionated error validations, but decided against it
- Better to document best practices than enforce opinions

### Trade-off: Allowed headers always required

**Accepted:** Making `allowed_headers` required (not optional) even though AWS allows omitting it
- Forces users to think about header filtering
- Common case is `["*"]` anyway (not much boilerplate)
- Prevents accidental misconfigurations
