## Why

Web applications using S3 for document storage (like Documenso) need CORS configuration to allow browsers to fetch resources from S3. Without CORS support in this module, users must manually configure CORS outside Terraform or create separate `aws_s3_bucket_cors_configuration` resources, breaking the module's encapsulation pattern.

## What Changes

- Add `cors_rules` variable to accept a list of CORS rule configurations
- Create `cors.tf` with `aws_s3_bucket_cors_configuration` resource
- Add variable validation to prevent AWS API errors (max 100 rules, valid HTTP methods)
- Create `examples/CORS.md` with usage examples for common scenarios
- Update `README.md` to reference CORS examples

This is a **non-breaking change** - CORS configuration is opt-in with `cors_rules` defaulting to empty list.

## Capabilities

### New Capabilities
- `cors-configuration`: Support for configuring CORS rules on S3 buckets to enable cross-origin browser access

### Modified Capabilities
<!-- No existing capabilities are being modified - this is purely additive -->

## Impact

**Affected Files:**
- `variables.tf` - new `cors_rules` variable
- `cors.tf` - new file (follows existing pattern: lifecycle.tf, versioning.tf, etc.)
- `examples/CORS.md` - new documentation
- `README.md` - updated to reference CORS examples

**Use Cases Enabled:**
- Direct S3 access from web applications (Documenso use case)
- CloudFront-backed S3 distributions (CORS headers from S3)
- Multi-origin web applications (staging, production environments)
- Browser-based file uploads to S3

**Security Considerations:**
- No security relaxation by default (empty list = no CORS)
- Validation prevents invalid configurations
- Documentation includes security best practices
- Aligns with module's "explicit opt-in" philosophy
