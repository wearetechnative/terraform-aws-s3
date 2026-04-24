## 1. Add CORS Variable to Module

- [x] 1.1 Add `cors_rules` variable to variables.tf with type definition
- [x] 1.2 Add variable description explaining CORS configuration purpose
- [x] 1.3 Set default value to empty list `[]`
- [x] 1.4 Add validation block to enforce max 100 rules limit
- [x] 1.5 Add validation block to enforce allowed_methods contains only GET, PUT, POST, DELETE, HEAD

## 2. Create CORS Resource

- [x] 2.1 Create new file `cors.tf` at module root level
- [x] 2.2 Add `aws_s3_bucket_cors_configuration` resource with conditional count based on cors_rules length
- [x] 2.3 Set bucket reference to `aws_s3_bucket.this.id`
- [x] 2.4 Implement `dynamic "cors_rule"` block to iterate over cors_rules variable
- [x] 2.5 Map all CORS rule fields (allowed_headers, allowed_methods, allowed_origins, expose_headers, max_age_seconds)

## 3. Create Examples Documentation

- [x] 3.1 Create new file `examples/CORS.md`
- [x] 3.2 Add example for simple read-only access (Documenso use case: GET/HEAD methods, specific origin)
- [x] 3.3 Add example for multiple origins (staging and production environments)
- [x] 3.4 Add example for file upload from browser (PUT/POST methods)
- [x] 3.5 Add example for multiple CORS rules on same bucket
- [x] 3.6 Add Security Considerations section covering wildcard origin risks and method permissiveness
- [x] 3.7 Add CloudFront integration notes explaining both direct S3 CORS and CloudFront Response Headers Policy approaches

## 4. Update Main Documentation

- [x] 4.1 Update README.md to add reference to CORS configuration support
- [x] 4.2 Update README.md to link to examples/CORS.md for detailed examples
- [x] 4.3 Run `terraform-docs` to regenerate auto-generated sections with new cors_rules variable

## 5. Quality Checks

- [x] 5.1 Run `terraform fmt` to format all modified files
- [x] 5.2 Run `terraform validate` to verify configuration syntax
- [x] 5.3 Verify tflint passes with no errors
- [x] 5.4 Verify tfsec passes with no new security issues

## 6. Update Changelog

- [x] 6.1 Update CHANGELOG.md under "## NEXT VERSION" section
- [x] 6.2 Add entry under "### Added" section: "**CORS Configuration**: Support for configuring CORS rules via `cors_rules` variable to enable cross-origin browser access to S3 buckets"
