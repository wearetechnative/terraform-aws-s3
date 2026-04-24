# Cross-Region S3 Replication Example

This example demonstrates how to set up S3 replication between two buckets in different AWS regions using the terraform-aws-s3 module.

## Overview

This example creates:
- Source S3 bucket in the primary region (default: eu-west-1)
- Target S3 bucket in the secondary region (default: eu-central-1)
- Separate KMS keys in each region for bucket encryption
- Cross-region replication configuration from source to target
- All necessary IAM roles and policies for cross-region replication

## Prerequisites

- AWS CLI configured with appropriate credentials
- Terraform >= 1.0
- AWS provider >= 4.8.0
- Permissions to create resources in **both regions**:
  - S3 buckets
  - KMS keys
  - IAM roles and policies
  - SSM parameters

## Architecture

```
┌──────────────────────────────┐         ┌──────────────────────────────┐
│     Primary Region           │         │    Secondary Region          │
│     (eu-west-1)              │         │    (eu-central-1)            │
│                              │         │                              │
│  ┌────────────────────────┐  │         │  ┌────────────────────────┐  │
│  │   Source Bucket        │──┼────────>┼──│   Target Bucket        │  │
│  │                        │  │         │  │                        │  │
│  │   KMS Key (Primary)    │  │         │  │   KMS Key (Secondary)  │  │
│  │   Versioning: ON       │  │         │  │   Versioning: ON       │  │
│  └────────────────────────┘  │         │  └────────────────────────┘  │
│                              │         │                              │
└──────────────────────────────┘         └──────────────────────────────┘
                  │                                     │
                  └─────> Cross-Region Replication ────>┘
```

## Setup Steps

### 1. Initialize Terraform

```bash
cd examples/replication-cross-region
terraform init
```

### 2. Review Variables

The example uses default values defined in `variables.tf`:
- `primary_region`: eu-west-1
- `secondary_region`: eu-central-1
- `name_prefix`: cross-region-replication
- `environment`: development

To customize, create a `terraform.tfvars` file:

```hcl
primary_region   = "us-east-1"
secondary_region = "us-west-2"
name_prefix      = "my-cross-region-test"
environment      = "testing"
```

**Important**: The two regions MUST be different. AWS does not support cross-region replication to the same region.

### 3. Plan the Deployment

```bash
terraform plan
```

Review the plan to ensure the following resources will be created:
- 2 KMS keys (one per region)
- 2 S3 buckets (one per region)
- IAM roles for cross-region replication
- Bucket policies
- SSM parameters

### 4. Apply the Configuration

```bash
terraform apply
```

Type `yes` when prompted to confirm.

**Note**: This will create resources in two different AWS regions. Ensure your AWS credentials have permissions in both regions.

## Verification

### 1. Check Replication Configuration

```bash
# Get bucket names and regions from outputs
SOURCE_BUCKET=$(terraform output -raw source_bucket_name)
TARGET_BUCKET=$(terraform output -raw target_bucket_name)
SOURCE_REGION=$(terraform output -raw source_bucket_region)
TARGET_REGION=$(terraform output -raw target_bucket_region)

# Verify replication configuration on source bucket
aws s3api get-bucket-replication --bucket $SOURCE_BUCKET --region $SOURCE_REGION
```

You should see a replication rule configured with the target bucket ARN in the secondary region.

### 2. Test Cross-Region Replication

Upload a test file to the source bucket:

```bash
echo "Test cross-region replication" > test-file.txt
aws s3 cp test-file.txt s3://$SOURCE_BUCKET/ --region $SOURCE_REGION
```

Wait a few moments (cross-region replication may take longer than same-region), then check if the file appears in the target bucket:

```bash
aws s3 ls s3://$TARGET_BUCKET/ --region $TARGET_REGION
```

You should see `test-file.txt` in the target bucket.

### 3. Verify Replication Status

```bash
aws s3api head-object --bucket $TARGET_BUCKET --key test-file.txt --region $TARGET_REGION
```

Look for the `ReplicationStatus` field, which should show `REPLICA`.

### 4. Check Both Buckets

```bash
# List objects in source bucket
echo "Source bucket ($SOURCE_REGION):"
aws s3 ls s3://$SOURCE_BUCKET/ --region $SOURCE_REGION

# List objects in target bucket
echo "Target bucket ($TARGET_REGION):"
aws s3 ls s3://$TARGET_BUCKET/ --region $TARGET_REGION
```

## KMS Key Considerations

Cross-region replication with KMS encryption requires:

1. **Separate KMS keys per region**: KMS keys are region-specific and cannot be used across regions.
2. **Replication role permissions**: The IAM replication role must have permission to:
   - Decrypt objects using the source region's KMS key
   - Encrypt objects using the target region's KMS key

This example automatically configures these permissions through the terraform-aws-s3 module's replication sub-modules.

## Cleanup

To destroy all resources created by this example:

```bash
# First, empty both buckets
aws s3 rm s3://$SOURCE_BUCKET --recursive --region $SOURCE_REGION
aws s3 rm s3://$TARGET_BUCKET --recursive --region $TARGET_REGION

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
   aws s3api get-bucket-versioning --bucket $SOURCE_BUCKET --region $SOURCE_REGION
   aws s3api get-bucket-versioning --bucket $TARGET_BUCKET --region $TARGET_REGION
   ```
   Both should show `"Status": "Enabled"`.

2. Verify the replication configuration specifies the correct destination region:
   ```bash
   aws s3api get-bucket-replication --bucket $SOURCE_BUCKET --region $SOURCE_REGION
   ```
   The destination bucket ARN should match your target region.

3. Check the replication role has permissions for both KMS keys:
   ```bash
   aws kms get-key-policy --key-id <source-key-id> --region $SOURCE_REGION --policy-name default
   aws kms get-key-policy --key-id <target-key-id> --region $TARGET_REGION --policy-name default
   ```

### Issue: KMS permission errors

**Solution**: Ensure the replication role has:
- `kms:Decrypt` on the source KMS key
- `kms:Encrypt` on the target KMS key

The module handles this automatically, but verify the role ARN in the replication configuration matches the created role.

### Issue: Cross-region latency

**Note**: Cross-region replication takes longer than same-region replication due to:
- Geographic distance between regions
- Data transfer across AWS backbone network

Typical replication time: seconds to minutes depending on object size and network conditions.

### Issue: Provider alias errors

If you see errors about provider configuration, ensure both provider aliases are configured:
```hcl
provider "aws" {
  alias  = "primary"
  region = var.primary_region
}

provider "aws" {
  alias  = "secondary"
  region = var.secondary_region
}
```

And that module calls specify the provider:
```hcl
module "source_bucket" {
  providers = {
    aws = aws.primary
  }
  # ...
}
```

## Cost Considerations

Cross-region replication incurs additional AWS costs:
- **Data transfer**: Charges for data transferred between regions
- **Storage**: Storage costs in both regions
- **Replication requests**: S3 PUT requests in the target region
- **KMS operations**: Encryption/decryption operations in both regions

For production use, review [AWS S3 Pricing](https://aws.amazon.com/s3/pricing/) for cross-region replication costs.

## Notes

- This is a demonstration example. For production use:
  - Use existing KMS keys instead of creating new ones
  - Implement proper lifecycle policies in both regions
  - Add CloudWatch monitoring and alerting
  - Consider using S3 Batch Replication for existing objects
  - Review and adjust bucket policies for your security requirements
  - Implement proper cost monitoring for cross-region data transfer

- Replication only applies to new objects uploaded after replication is configured. To replicate existing objects, use [S3 Batch Replication](https://docs.aws.amazon.com/AmazonS3/latest/userguide/s3-batch-replication-batch.html).

- Both buckets will have auto-generated suffixes to ensure global uniqueness. Use the SSM parameters (`/s3/<name>/id`) to retrieve the actual bucket names programmatically.

## References

- [AWS S3 Cross-Region Replication](https://docs.aws.amazon.com/AmazonS3/latest/userguide/replication.html#crr-scenario)
- [Replicating encrypted objects](https://docs.aws.amazon.com/AmazonS3/latest/userguide/replication-config-for-kms-objects.html)
- [terraform-aws-s3 Module README](../../README.md)
