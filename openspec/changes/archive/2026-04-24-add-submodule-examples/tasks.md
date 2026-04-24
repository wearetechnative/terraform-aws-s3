## 1. Directory Structure Setup

- [x] 1.1 Create `examples/` directory at repository root
- [x] 1.2 Create `examples/replication-same-region/` directory
- [x] 1.3 Create `examples/replication-cross-region/` directory
- [x] 1.4 Create `examples/replication-cross-account/` directory

## 2. Same-Region Replication Example

- [x] 2.1 Create `examples/replication-same-region/main.tf` with source and target bucket configuration
- [x] 2.2 Create `examples/replication-same-region/variables.tf` with required input variables
- [x] 2.3 Create `examples/replication-same-region/outputs.tf` with bucket ARNs and names
- [x] 2.4 Create `examples/replication-same-region/README.md` with prerequisites, setup steps, and verification
- [x] 2.5 Run `terraform fmt` on same-region example files
- [x] 2.6 Run `tflint` on same-region example
- [x] 2.7 Run `tfsec` on same-region example

## 3. Cross-Region Replication Example

- [x] 3.1 Create `examples/replication-cross-region/main.tf` with multi-region provider configuration
- [x] 3.2 Create `examples/replication-cross-region/variables.tf` with region variables
- [x] 3.3 Create `examples/replication-cross-region/outputs.tf` with regional bucket information
- [x] 3.4 Create `examples/replication-cross-region/README.md` with region setup and KMS key guidance
- [x] 3.5 Run `terraform fmt` on cross-region example files
- [x] 3.6 Run `tflint` on cross-region example
- [x] 3.7 Run `tfsec` on cross-region example

## 4. Cross-Account Replication Example

- [x] 4.1 Create `examples/replication-cross-account/main.tf` with multi-account provider configuration
- [x] 4.2 Create `examples/replication-cross-account/variables.tf` with account ID variables
- [x] 4.3 Create `examples/replication-cross-account/outputs.tf` with cross-account bucket information
- [x] 4.4 Create `examples/replication-cross-account/README.md` with IAM role and multi-account setup
- [x] 4.5 Run `terraform fmt` on cross-account example files
- [x] 4.6 Run `tflint` on cross-account example
- [x] 4.7 Run `tfsec` on cross-account example

## 5. Main README Updates

- [x] 5.1 Add "Examples" section to main README.md above terraform-docs section
- [x] 5.2 Add links to all three replication example directories
- [x] 5.3 Add brief descriptions of each example type
- [x] 5.4 Verify terraform-docs markers remain intact

## 6. CHANGELOG Updates

- [x] 6.1 Open CHANGELOG.md
- [x] 6.2 Add entry under "## NEXT VERSION" section
- [x] 6.3 Add "### Added" subsection if not present
- [x] 6.4 Document the addition of replication examples with all three types listed

## 7. Final Validation

- [x] 7.1 Verify all example directories have main.tf, variables.tf, outputs.tf, and README.md
- [x] 7.2 Verify all Terraform files are formatted (`terraform fmt -check -recursive examples/`)
- [x] 7.3 Verify main README.md contains Examples section with working links
- [x] 7.4 Verify CHANGELOG.md is updated under "## NEXT VERSION"
- [x] 7.5 Review all README.md files for clarity and completeness
