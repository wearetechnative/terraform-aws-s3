## Why

The replication sub-modules (`replication_source` and `replication_target`) lack usage examples, making it difficult for users to understand how to implement S3 cross-region or cross-account replication. According to the OpenSpec guardrails, all sub-modules should have examples directories with usage examples. This change improves module usability and documentation completeness.

## What Changes

- Add `examples/` directory structure for replication use cases
- Create example for basic same-region replication
- Create example for cross-region replication
- Create example for cross-account replication
- Add README.md documentation for each example explaining the setup
- Update main README.md to reference the new examples
- Update CHANGELOG.md with documentation improvements

## Capabilities

### New Capabilities
- `replication-examples`: Complete working examples demonstrating S3 replication configurations using both source and target sub-modules

### Modified Capabilities
<!-- No existing capabilities are being modified, only documentation is being added -->

## Impact

**Documentation**:
- New `examples/` directory at repository root
- Updated main `README.md` with links to replication examples
- Updated `CHANGELOG.md` under "## NEXT VERSION" section

**User Experience**:
- Users can copy-paste working examples to implement replication
- Clear documentation of replication setup patterns (same-region, cross-region, cross-account)
- Demonstrates the output-to-input pattern for replication configuration

**No Breaking Changes**:
- This is purely additive documentation
- No changes to module code, variables, or outputs
- Existing users are unaffected
