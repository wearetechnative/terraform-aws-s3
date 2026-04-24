# OpenSpec Guardrails - Terraform AWS S3 Module

## Overview

This document defines the guardrails for the terraform-aws-s3 module. These guardrails ensure consistency, security, and maintainability across all changes.

**Guardrail Severity Levels**:
- 🔴 **CRITICAL**: Never violate (security, data safety)
- 🟡 **IMPORTANT**: Should follow (quality, compatibility)
- 🟢 **GUIDANCE**: Best practice (consistency, maintainability)

---

## 🔴 CRITICAL Guardrails

### Security Requirements

**Encryption Enforcement**
- ✅ All S3 buckets MUST have encryption enabled
- ✅ Default: SSE-KMS with provided `var.kms_key_arn`
- ✅ Fallback: SSE-S3 (only for public buckets or when `var.use_sse-s3_encryption_instead_of_sse-kms=true`)
- ❌ NEVER allow unencrypted buckets
- ❌ NEVER bypass encryption policies without explicit variable check

**Example violation**:
```hcl
# ❌ WRONG - removes encryption enforcement
resource "aws_s3_bucket" "this" {
  bucket = var.name
  # Missing encryption configuration
}
```

**TLS Requirements**
- ✅ TLS 1.2+ enforcement MUST be maintained
- ❌ NEVER weaken TLS version requirements
- See: `data.aws_iam_policy_document.deny_obsolete_tls` in `bucket_policy.tf`

**Data Protection**
- ✅ `prevent_destroy` lifecycle MUST remain enabled on `aws_s3_bucket.this`
- ❌ NEVER remove or disable prevent_destroy
- Rationale: Prevents accidental bucket deletion with data loss

**Public Access**
- ✅ Public access MUST be explicit opt-in via `var.enable_public_read_access`
- ❌ NEVER make public access the default
- ✅ Public buckets MUST use SSE-S3 (KMS not supported by AWS for public read)

### Backwards Compatibility

**API Stability**
- ❌ NEVER introduce breaking changes without explicit approval
- ❌ NEVER change variable types (string → list, object schema changes, etc.)
- ❌ NEVER remove outputs (downstream modules may depend on them)
- ❌ NEVER change resource identifiers (causes resource recreation)

**Breaking Change Examples**:
```hcl
# ❌ WRONG - changes variable type
variable "kms_key_arn" {
  type = list(string)  # Was: string
}

# ❌ WRONG - removes output
# output "s3_arn" { ... }  # Deleted

# ❌ WRONG - changes resource name
resource "aws_s3_bucket" "main" {  # Was: "this"
  # ...
}
```

---

## 🟡 IMPORTANT Guardrails

### Terraform Best Practices

**Provider Compatibility**
- Maintain AWS provider version constraint: `>= 4.8.0`
- Test against latest stable AWS provider before releasing
- Document provider version changes in CHANGELOG

**Resource Patterns**
- Use `count` for conditional resources (established pattern)
- Use `source_policy_documents` for merging IAM policies
- Keep resource names as `this` for single-instance resources
- Use descriptive names for multi-instance resources

**Code Organization**
- One resource type per file (follow existing structure)
- Data sources in dedicated files or `data.tf`
- Complex expressions in `locals` blocks
- Maximum 2 levels of nested conditionals

**Example good pattern**:
```hcl
# kms.tf
resource "aws_s3_bucket_server_side_encryption_configuration" "this" {
  bucket = aws_s3_bucket.this.bucket

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = !var.use_sse-s3_encryption_instead_of_sse-kms ? "aws:kms" : "AES256"
      kms_master_key_id = !var.use_sse-s3_encryption_instead_of_sse-kms ? var.kms_key_arn : null
    }
    bucket_key_enabled = true
  }
}
```

### Documentation Standards

**Variables**
- All variables MUST have `description` field
- Mark internal-only variables: `"Internal use only. ..."`
- Document security implications in descriptions
- Use clear, user-facing language

**Example**:
```hcl
variable "enable_public_read_access" {
  description = "Enable public read access."
  type        = bool
  default     = false
}

variable "disable_encryption_enforcement" {
  description = "Internal use only. Buckets get a standard policy that prevents un-encrypted uploads or encryption schemes that are not the default encryption. Some services cannot work (Athena CUR) with this policy enabled."
  type        = bool
  default     = false
}
```

**README.md**
- Keep `<!-- BEGIN_TF_DOCS -->` markers intact
- terraform-docs auto-generates this section
- Update manual sections above the markers
- Include usage examples for both workflows (private/public buckets)

**CHANGELOG.md**
- Update for all user-facing changes
- Use `## NEXT VERSION` as section header
- Follow Keep a Changelog format:
  - `### Added` - new features
  - `### Changed` - changes in existing functionality
  - `### Deprecated` - soon-to-be removed features
  - `### Removed` - removed features
  - `### Fixed` - bug fixes
  - `### Security` - security improvements

**Example CHANGELOG entry**:
```markdown
## NEXT VERSION

### Added
- **Lifecycle configuration support**: Added `var.lifecycle_configuration` to support custom object lifecycle rules
  - Supports transitions to different storage classes
  - Configurable expiration policies
  - Noncurrent version management

### Fixed
- Fixed bucket policy merge order to prevent policy conflicts
```

### Testing Requirements

**Static Analysis**
- `tflint` must pass (see `.github/workflows/tflint.yaml`)
- `tfsec` must pass (see `.github/workflows/tfsec-tfinit.yaml`)
- `terraform fmt -check` must pass
- No integration tests currently configured

**Pre-commit Checklist**:
```bash
# Format code
terraform fmt -recursive

# Validate syntax
terraform validate

# Run linter
tflint

# Run security scanner
tfsec .

# Update documentation
terraform-docs markdown table --output-file README.md --output-mode inject .
```

---

## 🟢 GUIDANCE Guardrails

### Code Quality

**Naming Conventions**
- Use `snake_case` for all identifiers
- Variable naming patterns:
  - `enable_*` for boolean feature flags
  - `use_*` for mode switches
  - `disable_*` for negative flags (use sparingly)
  - `*_configuration` for complex objects
  - `additional_*` for optional additive parameters

**IAM Policies**
- Use separate `data "aws_iam_policy_document"` resources
- Name policy documents descriptively (e.g., `deny_unencrypted_kms`)
- Use `source_policy_documents` for composition
- Add SID (statement ID) to all policy statements

**Example**:
```hcl
data "aws_iam_policy_document" "deny_obsolete_tls" {
  statement {
    sid    = "DenyObsoleteTLS"
    effect = "Deny"

    actions = ["s3:*"]

    principals {
      type        = "*"
      identifiers = ["*"]
    }

    resources = [
      "${aws_s3_bucket.this.arn}/*",
      aws_s3_bucket.this.arn
    ]

    condition {
      test     = "NumericLessThan"
      variable = "s3:TlsVersion"
      values   = ["1.2"]
    }
  }
}
```

**Comments**
- Explain "why" not "what"
- Add comments for complex logic or AWS-specific limitations
- Reference AWS documentation for non-obvious requirements

**Example**:
```hcl
# dummy hack policy to workaround Terraform limitations and keeping this module simple
# this policy has no effect, this is intended
# this dummy policy is to always have a resource policy so Terraform will not complain
# if its existence is conditional on other resource outputs
data "aws_iam_policy_document" "dummy_policy" {
  # ...
}
```

### Module Architecture

**Sub-modules**
- Sub-modules MUST be independent (no cross-dependencies)
- Use output-to-input pattern for configuration
- Each sub-module should have:
  - `variables.tf`, `outputs.tf`
  - Dedicated resource files
  - `examples/` directory with usage examples

**File Organization Pattern**:
```
terraform-aws-s3/
├── main.tf                    # Primary S3 bucket resource
├── variables.tf               # Module inputs
├── outputs.tf                 # Module outputs
├── versions.tf                # Provider constraints
├── data.tf                    # Data sources (shared)
├── kms.tf                     # Encryption config
├── bucket_policy.tf           # IAM policies
├── public_access_block.tf     # Public access settings
├── versioning.tf              # Versioning config
├── lifecycle.tf               # Lifecycle rules
├── replication.tf             # Module calls
├── ssm_parameter.tf           # SSM parameter
├── replication_source/        # Sub-module
│   ├── variables.tf
│   ├── outputs.tf
│   ├── role.tf
│   └── replication_configuration.tf
└── replication_target/        # Sub-module
    ├── variables.tf
    ├── outputs.tf
    ├── role.tf
    ├── data.tf
    └── bucket_policy.tf
```

**Module Outputs**
- Match AWS resource attributes when possible
- Provide replication configuration outputs for composition
- Include SSM parameter ARN for CICD discovery

**Bucket Naming**
- Default: prefix pattern with auto-generated suffix (`var.name-<random>`)
- Optional: fixed name via `var.use_fixed_name=true` (not recommended)
- Always replace underscores with hyphens
- Creates SSM parameter: `/s3/${var.name}/id` for discovery

---

## Workflow-Specific Guardrails

### Private Bucket Workflow (Default)

**Required Variables**:
- `var.name` - Bucket prefix name
- `var.kms_key_arn` - KMS key for SSE-KMS encryption

**Security Posture**:
- ✅ SSE-KMS encryption with provided key
- ✅ Full public access block (all 4 settings enabled)
- ✅ ACLs disabled (BucketOwnerEnforced)
- ✅ Versioning enabled
- ✅ TLS 1.2+ enforcement
- ✅ Encryption policy enforcement

**Example**:
```hcl
module "private_bucket" {
  source = "github.com/wearetechnative/terraform-aws-s3"

  name        = "my-private-data"
  kms_key_arn = aws_kms_key.my_key.arn

  additional_tags = {
    Environment = "production"
    Backup      = "daily"
  }
}
```

### Public Bucket Workflow

**Required Variables**:
- `var.name`
- `var.kms_key_arn` (still required for consistency)
- `var.enable_public_read_access = true`
- `var.use_sse-s3_encryption_instead_of_sse-kms = true`

**Security Posture**:
- ✅ SSE-S3 encryption (KMS not supported for public read)
- ⚠️ Public read access enabled
- ✅ Block public ACLs still enabled
- ✅ Versioning enabled
- ✅ TLS 1.2+ enforcement
- ⚠️ Encryption header enforcement (SSE-S3, not KMS)

**Example**:
```hcl
module "public_bucket" {
  source = "github.com/wearetechnative/terraform-aws-s3"

  name                                       = "my-public-assets"
  kms_key_arn                                = aws_kms_key.my_key.arn  # Required but not used
  enable_public_read_access                  = true
  use_sse-s3_encryption_instead_of_sse-kms   = true

  additional_tags = {
    Environment = "production"
    Public      = "true"
  }
}
```

---

## Common Violations and Fixes

### Violation: Weakening Security

❌ **Wrong**:
```hcl
resource "aws_s3_bucket_public_access_block" "this" {
  bucket = aws_s3_bucket.this.id

  block_public_acls       = false  # ❌ Weakens security
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}
```

✅ **Correct**:
```hcl
resource "aws_s3_bucket_public_access_block" "this" {
  bucket = aws_s3_bucket.this.id

  block_public_acls       = true
  block_public_policy     = var.enable_public_read_access ? false : true
  ignore_public_acls      = true
  restrict_public_buckets = var.enable_public_read_access ? false : true
}
```

### Violation: Breaking Changes

❌ **Wrong**:
```hcl
# Changed output name
output "bucket_arn" {  # Was: s3_arn
  value = aws_s3_bucket.this.arn
}
```

✅ **Correct**:
```hcl
# Keep existing output, add new one if needed
output "s3_arn" {
  value = aws_s3_bucket.this.arn
}

output "bucket_arn" {  # Alias for convenience
  value = aws_s3_bucket.this.arn
}
```

### Violation: Poor Variable Documentation

❌ **Wrong**:
```hcl
variable "disable_encryption_enforcement" {
  type    = bool
  default = false
}
```

✅ **Correct**:
```hcl
variable "disable_encryption_enforcement" {
  description = "Internal use only. Buckets get a standard policy that prevents un-encrypted uploads or encryption schemes that are not the default encryption. Some services cannot work (Athena CUR) with this policy enabled."
  type        = bool
  default     = false
}
```

---

## Decision Framework

When making changes, ask:

1. **Security Impact**:
   - Does this weaken encryption? ❌ Stop
   - Does this expose data publicly by default? ❌ Stop
   - Does this reduce TLS requirements? ❌ Stop

2. **Compatibility Impact**:
   - Does this break existing module usage? ⚠️ Requires approval
   - Does this change variable types? ⚠️ Requires approval
   - Does this remove outputs? ⚠️ Requires approval

3. **Quality Impact**:
   - Does this follow the file organization pattern? ✅
   - Are variables well-documented? ✅
   - Does this pass tflint/tfsec? ✅

4. **User Impact**:
   - Is this change documented in CHANGELOG? ✅
   - Are examples updated if needed? ✅
   - Is README.md updated? ✅

---

## Resources

**Internal Documentation**:
- `README.md` - Module usage and API
- `CHANGELOG.md` - Change history
- `examples/` - Usage examples (TBD for sub-modules)

**CI/CD**:
- `.github/workflows/tflint.yaml` - Linting
- `.github/workflows/tfsec-tfinit.yaml` - Security scanning

**AWS Documentation**:
- [S3 Encryption](https://docs.aws.amazon.com/AmazonS3/latest/userguide/UsingEncryption.html)
- [S3 Security Best Practices](https://docs.aws.amazon.com/AmazonS3/latest/userguide/security-best-practices.html)
- [S3 Replication](https://docs.aws.amazon.com/AmazonS3/latest/userguide/replication.html)

**Terraform Documentation**:
- [AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [S3 Bucket Resource](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket)
- [Module Development](https://www.terraform.io/docs/language/modules/develop/index.html)
