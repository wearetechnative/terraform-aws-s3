# Same-Region S3 Replication Example

This example demonstrates how to set up S3 replication between two buckets in the same AWS region using the terraform-aws-s3 module.

## Overview

This example creates:
- Two S3 buckets (source and target) in the same region
- Separate KMS keys for each bucket
- Replication configuration from source to target bucket
- All necessary IAM roles and policies for replication

## Prerequisites

- AWS CLI configured with appropriate credentials
- Terraform >= 1.0
- AWS provider >= 4.8.0
- Permissions to create:
  - S3 buckets
  - KMS keys
  - IAM roles and policies
  - SSM parameters

## Architecture

```
┌─────────────────────────────────────────────────────┐
│                    AWS Region                        │
│                   (eu-west-1)                        │
│                                                      │
│  ┌──────────────────┐         ┌─────────────────┐  │
│  │  Source Bucket   │────────>│  Target Bucket  │  │
│  │                  │         │                 │  │
│  │  KMS Key A       │         │  KMS Key B      │  │
│  │  Versioning: ON  │         │  Versioning: ON │  │
│  └──────────────────┘         └─────────────────┘  │
│                                                      │
│         Replication                                  │
│         ───────────>                                 │
└─────────────────────────────────────────────────────┘
```

## Setup Steps

### 1. Initialize Terraform

```bash
cd examples/replication-same-region
terraform init
```

### 2. Review Variables

The example uses default values defined in `variables.tf`:
- `region`: eu-west-1 (change if needed)
- `name_prefix`: replication-example
- `environment`: development

To customize, create a `terraform.tfvars` file:

```hcl
region      = "eu-west-1"
name_prefix = "my-replication-test"
environment = "testing"
```

### 3. Plan the Deployment

```bash
terraform plan
```

Review the plan to ensure the following resources will be created:
- 2 KMS keys (source and target)
- 2 S3 buckets (source and target)
- IAM roles for replication
- Bucket policies
- SSM parameters

### 4. Apply the Configuration

```bash
terraform apply
```

Type `yes` when prompted to confirm.

## Verification

### 1. Check Replication Configuration

```bash
# Get bucket names from outputs
SOURCE_BUCKET=$(terraform output -raw source_bucket_name)
TARGET_BUCKET=$(terraform output -raw target_bucket_name)

# Verify replication configuration on source bucket
aws s3api get-bucket-replication --bucket $SOURCE_BUCKET
```

You should see a replication rule configured with the target bucket ARN.

### 2. Test Replication

Upload a test file to the source bucket:

```bash
echo "Test replication" > test-file.txt
aws s3 cp test-file.txt s3://$SOURCE_BUCKET/
```

Wait a few moments, then check if the file appears in the target bucket:

```bash
aws s3 ls s3://$TARGET_BUCKET/
```

You should see `test-file.txt` in the target bucket.

### 3. Verify Replication Status

```bash
aws s3api head-object --bucket $TARGET_BUCKET --key test-file.txt
```

Look for the `ReplicationStatus` field, which should show `REPLICA`.

## Cleanup

To destroy all resources created by this example:

```bash
# First, empty both buckets
aws s3 rm s3://$SOURCE_BUCKET --recursive
aws s3 rm s3://$TARGET_BUCKET --recursive

# Then destroy the infrastructure
terraform destroy
```

**Note**: The buckets have `prevent_destroy = true` in the module. You'll need to:
1. Empty the buckets manually (as shown above)
2. Remove the `prevent_destroy` lifecycle block from the module code, OR
3. Use `terraform state rm` to remove the buckets from state before destroying

## Troubleshooting

### Issue: Replication not working

**Check**:
1. Verify versioning is enabled on both buckets:
   ```bash
   aws s3api get-bucket-versioning --bucket $SOURCE_BUCKET
   aws s3api get-bucket-versioning --bucket $TARGET_BUCKET
   ```
   Both should show `"Status": "Enabled"`.

2. Verify the replication role has correct permissions:
   ```bash
   aws s3api get-bucket-replication --bucket $SOURCE_BUCKET
   ```
   Check the `Role` ARN and verify the IAM role exists.

3. Check CloudWatch Logs for replication errors (if logging is enabled).

### Issue: Access denied errors

**Solution**: Ensure your AWS credentials have permissions to:
- Create and manage S3 buckets
- Create and manage KMS keys
- Create and manage IAM roles/policies
- Create SSM parameters

### Issue: KMS key permissions

**Check**: Verify the replication role has permissions to use both KMS keys:
```bash
aws kms get-key-policy --key-id <source-key-id> --policy-name default
aws kms get-key-policy --key-id <target-key-id> --policy-name default
```

## Notes

- This is a demonstration example. For production use:
  - Use existing KMS keys instead of creating new ones
  - Implement proper lifecycle policies
  - Add CloudWatch monitoring and alerting
  - Consider using S3 Batch Replication for existing objects
  - Review and adjust bucket policies for your security requirements

- Replication only applies to new objects uploaded after replication is configured. To replicate existing objects, use [S3 Batch Replication](https://docs.aws.amazon.com/AmazonS3/latest/userguide/s3-batch-replication-batch.html).

- Both buckets will have auto-generated suffixes to ensure global uniqueness. Use the SSM parameters (`/s3/<name>/id`) to retrieve the actual bucket names programmatically.

## References

- [AWS S3 Replication Documentation](https://docs.aws.amazon.com/AmazonS3/latest/userguide/replication.html)
- [terraform-aws-s3 Module README](../../README.md)
