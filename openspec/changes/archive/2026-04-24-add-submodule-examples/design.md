## Context

The terraform-aws-s3 module currently has two sub-modules (`replication_source` and `replication_target`) that enable S3 replication, but there are no working examples demonstrating how to use them. Users need to understand the output-to-input pattern for configuring replication, as well as the differences between same-region, cross-region, and cross-account scenarios.

**Current State**:
- Replication sub-modules exist and are functional
- Main module outputs `replication_target_bucket_arguments` and `replication_source_bucket_arguments`
- No examples directory exists
- README.md mentions replication in passing but provides no guidance
- Users must reverse-engineer the replication setup from code

**Constraints**:
- Examples must be self-contained and runnable
- Must follow Terraform best practices
- Should demonstrate the output-to-input pattern clearly
- Cannot modify existing module code (documentation only)
- Must pass tflint and tfsec checks

## Goals / Non-Goals

**Goals**:
- Provide copy-paste ready examples for all three replication scenarios
- Demonstrate the output-to-input pattern for replication configuration
- Document prerequisites, setup steps, and verification methods
- Make replication feature discoverable via main README.md
- Follow existing Terraform example conventions

**Non-Goals**:
- Not changing any module code or variables
- Not adding new replication features
- Not providing examples for non-replication use cases (those can be added later)
- Not creating automated tests for examples (static analysis only)

## Decisions

### Decision 1: Example Directory Structure

**Choice**: Create `examples/` at repository root with subdirectories per scenario.

```
examples/
├── replication-same-region/
│   ├── main.tf
│   ├── variables.tf
│   ├── outputs.tf
│   └── README.md
├── replication-cross-region/
│   ├── main.tf
│   ├── variables.tf
│   ├── outputs.tf
│   └── README.md
└── replication-cross-account/
    ├── main.tf
    ├── variables.tf
    ├── outputs.tf
    └── README.md
```

**Rationale**:
- Standard Terraform module convention
- Each scenario is self-contained and independently runnable
- Clear separation makes it easy to find the relevant example

**Alternatives Considered**:
- Single example with conditional logic: Rejected because it would be harder to understand and copy-paste
- Examples within sub-module directories: Rejected because examples demonstrate the main module usage, not sub-modules in isolation

### Decision 2: Output-to-Input Pattern Demonstration

**Choice**: Each example will explicitly show how to use module outputs as inputs for replication configuration.

**Example pattern**:
```hcl
module "source_bucket" {
  source = "../../"  # Main module
  name   = "source"
  kms_key_arn = aws_kms_key.source.arn

  source_replication_configuration = {
    "to-target" = module.target_bucket.replication_source_bucket_arguments["from-source"]
  }
}

module "target_bucket" {
  source = "../../"  # Main module
  name   = "target"
  kms_key_arn = aws_kms_key.target.arn

  target_replication_configuration = {
    "from-source" = module.source_bucket.replication_target_bucket_arguments
  }
}
```

**Rationale**:
- Makes the bidirectional relationship clear
- Shows the exact variable structure users need
- Demonstrates the map key naming convention

**Alternatives Considered**:
- Abstract the pattern behind local variables: Rejected because it hides the important details
- Document in text only: Rejected because working code is more valuable than descriptions

### Decision 3: Provider Configuration Approach

**Choice**:
- Same-region: Single default provider
- Cross-region: Aliased providers for each region
- Cross-account: Separate provider configurations with role assumption

**Rationale**:
- Matches real-world usage patterns
- Shows the minimum required provider configuration
- Demonstrates AWS best practices for multi-region/account scenarios

**Cross-region example**:
```hcl
provider "aws" {
  alias  = "primary"
  region = "eu-west-1"
}

provider "aws" {
  alias  = "secondary"
  region = "eu-central-1"
}
```

**Cross-account example**:
```hcl
provider "aws" {
  alias = "source_account"
  # Source account credentials
}

provider "aws" {
  alias = "target_account"
  assume_role {
    role_arn = "arn:aws:iam::${var.target_account_id}:role/TerraformReplicationRole"
  }
}
```

### Decision 4: KMS Key Handling

**Choice**: Each example creates its own KMS keys for demonstration purposes.

**Rationale**:
- Self-contained examples that can run independently
- Demonstrates the KMS key requirement clearly
- For cross-region: shows that separate keys are needed per region
- Follows security best practices (SSE-KMS for replication)

**Note**: Examples will include comments suggesting users replace with existing KMS keys in production.

### Decision 5: README Documentation Structure

**Choice**: Each example README.md follows this structure:
1. Overview (what this example demonstrates)
2. Prerequisites (AWS accounts, permissions, regions)
3. Architecture diagram (ASCII art)
4. Setup steps (numbered instructions)
5. Verification (how to test replication is working)
6. Cleanup (terraform destroy guidance)
7. Troubleshooting (common issues)

**Rationale**:
- Consistent structure makes examples easy to follow
- Prerequisites prevent user frustration
- Verification steps ensure users can confirm success
- Troubleshooting reduces support burden

### Decision 6: Main README Integration

**Choice**: Add a new "Examples" section in the main README.md above the terraform-docs section.

**Content**:
```markdown
## Examples

This module includes several examples demonstrating different use cases:

### Replication Examples

- [Same-region replication](./examples/replication-same-region/) - Replicate between buckets in the same AWS region
- [Cross-region replication](./examples/replication-cross-region/) - Replicate between buckets in different AWS regions
- [Cross-account replication](./examples/replication-cross-account/) - Replicate between buckets in different AWS accounts

See the [examples/](./examples/) directory for complete, runnable Terraform configurations.
```

**Rationale**:
- Makes examples discoverable
- Provides context for each example type
- Links directly to example directories
- Placed before terraform-docs section so it's visible

## Risks / Trade-offs

### Risk: Examples become outdated
**Mitigation**:
- Examples use relative paths to reference the module (../../)
- CI could be extended to validate examples (future enhancement)
- Keep examples minimal to reduce maintenance burden

### Risk: Users copy examples into production without modification
**Mitigation**:
- Include prominent comments in examples about production considerations
- README files emphasize "this is a demonstration, adapt for production"
- Use placeholder values that must be replaced (e.g., var.target_account_id)

### Risk: Cross-account example requires two AWS accounts
**Limitation**: This is unavoidable for demonstrating cross-account replication
**Mitigation**:
- Clearly document the multi-account requirement in README
- Provide clear setup instructions for users who may not have multiple accounts
- Suggest using AWS Organizations for easier multi-account setup

### Trade-off: Self-contained vs. DRY examples
**Choice**: Prioritize self-contained over DRY
**Rationale**: Each example should be independently runnable without shared modules or complex dependencies. Some duplication is acceptable for clarity.

### Trade-off: Example complexity
**Choice**: Keep examples focused on replication configuration, avoid extras
**Rationale**: Examples should demonstrate the core feature (replication) without additional features that could obscure the pattern. Users can add complexity to their own implementations.

## Migration Plan

Not applicable - this is purely additive documentation. No migration needed.

**Deployment Steps**:
1. Create examples directory structure
2. Write and test each example (manual terraform apply/destroy)
3. Run tflint and tfsec on examples
4. Update main README.md
5. Update CHANGELOG.md
6. Commit all files

**Rollback**: Simple git revert if needed (no infrastructure impact).

## Open Questions

None - this is a straightforward documentation task with clear requirements.
