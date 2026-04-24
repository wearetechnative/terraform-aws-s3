# Cross-Account S3 Replication Example

This example demonstrates how to set up S3 replication between two buckets in different AWS accounts using the terraform-aws-s3 module.

## Overview

This example creates:
- Source S3 bucket in the source AWS account
- Target S3 bucket in the target AWS account
- Separate KMS keys in each account for bucket encryption
- Cross-account replication configuration
- IAM roles and policies with cross-account trust relationships

## Prerequisites

### AWS Accounts
- **Two AWS accounts**: Source account and target account
- **AWS CLI** configured with credentials for the source account
- **IAM role** in target account that source account can assume

### Required Permissions

**Source Account** (where you run Terraform):
- Full permissions to create S3 buckets, KMS keys, IAM roles
- Permission to assume role in target account

**Target Account**:
- IAM role with trust relationship allowing source account to assume it
- Role must have permissions to create S3 buckets, KMS keys, IAM roles

### Software
- Terraform >= 1.0
- AWS provider >= 4.8.0

## Setup Prerequisites

### 1. Create Cross-Account IAM Role in Target Account

In the **target account**, create an IAM role that the source account can assume:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "AWS": "arn:aws:iam::<SOURCE_ACCOUNT_ID>:root"
      },
      "Action": "sts:AssumeRole",
      "Condition": {
        "StringEquals": {
          "sts:ExternalId": "terraform-cross-account"
        }
      }
    }
  ]
}
```

Attach policies to this role allowing it to create:
- S3 buckets and policies
- KMS keys
- IAM roles and policies
- SSM parameters

**Example role name**: `TerraformCrossAccountRole`

### 2. Configure AWS CLI Profiles (Optional)

You can configure named profiles for easier access:

```ini
# ~/.aws/credentials
[source-account]
aws_access_key_id = <source-account-key>
aws_secret_access_key = <source-account-secret>

[target-account]
role_arn = arn:aws:iam::<TARGET_ACCOUNT_ID>:role/TerraformCrossAccountRole
source_profile = source-account
```

## Architecture

```
┌──────────────────────────────────┐       ┌──────────────────────────────────┐
│      Source AWS Account          │       │       Target AWS Account         │
│      (111111111111)              │       │       (222222222222)             │
│                                  │       │                                  │
│  ┌────────────────────────────┐  │       │  ┌────────────────────────────┐  │
│  │   Source Bucket            │──┼──────>┼──│   Target Bucket            │  │
│  │                            │  │       │  │                            │  │
│  │   KMS Key (Source Acct)    │  │       │  │   KMS Key (Target Acct)    │  │
│  │   Versioning: ON           │  │       │  │   Versioning: ON           │  │
│  └────────────────────────────┘  │       │  └────────────────────────────┘  │
│                                  │       │                                  │
│  ┌────────────────────────────┐  │       │  ┌────────────────────────────┐  │
│  │  Replication IAM Role      │──┼──────>┼──│  Bucket Policy (allow      │  │
│  │  - Decrypt (source KMS)    │  │       │  │  replication role)         │  │
│  │  - Encrypt (target KMS)    │  │       │  └────────────────────────────┘  │
│  │  - PutObject (target)      │  │       │                                  │
│  └────────────────────────────┘  │       │                                  │
│                                  │       │                                  │
└──────────────────────────────────┘       └──────────────────────────────────┘
                     │                                        │
                     └──> Cross-Account Replication Trust ───>┘
```

## Setup Steps

### 1. Set Required Variables

Create a `terraform.tfvars` file:

```hcl
target_account_id           = "222222222222"  # Your target account ID
target_account_role_name    = "TerraformCrossAccountRole"
region                      = "eu-west-1"
name_prefix                 = "my-cross-account-test"
environment                 = "testing"
```

**Required**: You MUST set `target_account_id` to your actual target AWS account ID.

### 2. Initialize Terraform

```bash
cd examples/replication-cross-account
terraform init
```

### 3. Plan the Deployment

```bash
terraform plan
```

Review the plan to ensure resources will be created in both accounts:
- Source account: Source bucket, source KMS key, replication IAM role
- Target account: Target bucket, target KMS key, bucket policy

### 4. Apply the Configuration

```bash
terraform apply
```

Type `yes` when prompted to confirm.

Terraform will:
1. Create resources in source account using default credentials
2. Assume role in target account to create target resources
3. Configure cross-account replication

## Verification

### 1. Verify Cross-Account Setup

```bash
# Get outputs
SOURCE_BUCKET=$(terraform output -raw source_bucket_name)
TARGET_BUCKET=$(terraform output -raw target_bucket_name)
TARGET_ACCOUNT=$(terraform output -raw target_account_id)

# Check replication configuration
aws s3api get-bucket-replication --bucket $SOURCE_BUCKET
```

The destination bucket ARN should include the target account ID.

### 2. Test Cross-Account Replication

Upload a test file to the source bucket:

```bash
echo "Test cross-account replication" > test-file.txt
aws s3 cp test-file.txt s3://$SOURCE_BUCKET/
```

Wait a few moments, then check the target bucket using target account credentials:

```bash
# If using AWS CLI profiles
aws s3 ls s3://$TARGET_BUCKET/ --profile target-account

# Or assume the role manually
```

### 3. Verify Replication Status

```bash
# Check object in target bucket
aws s3api head-object \
  --bucket $TARGET_BUCKET \
  --key test-file.txt \
  --profile target-account
```

The `ReplicationStatus` field should show `REPLICA`.

## Cross-Account IAM Permissions

The terraform-aws-s3 module automatically creates the necessary IAM permissions for cross-account replication:

### Replication Role (Source Account)

The replication role in the source account needs:

1. **Source bucket permissions**:
   - `s3:GetReplicationConfiguration`
   - `s3:ListBucket`
   - `s3:GetObjectVersionForReplication`
   - `s3:GetObjectVersionAcl`

2. **Target bucket permissions** (cross-account):
   - `s3:ReplicateObject`
   - `s3:ReplicateDelete`
   - `s3:ReplicateTags`

3. **KMS permissions**:
   - `kms:Decrypt` on source KMS key
   - `kms:Encrypt` on target KMS key (cross-account)

### Target Bucket Policy

The target bucket policy allows the source account's replication role to:
- Put objects
- Put object ACLs
- Use the target account's KMS key

These policies are automatically configured by the module's replication sub-modules.

## Cleanup

### 1. Empty Both Buckets

**Source bucket** (using source account credentials):
```bash
aws s3 rm s3://$SOURCE_BUCKET --recursive
```

**Target bucket** (using target account credentials):
```bash
aws s3 rm s3://$TARGET_BUCKET --recursive --profile target-account
```

### 2. Destroy Infrastructure

```bash
terraform destroy
```

**Note**: The buckets have `prevent_destroy = true` in the module. You'll need to:
1. Empty the buckets manually (as shown above)
2. Remove the `prevent_destroy` lifecycle block from the module code, OR
3. Use `terraform state rm` to remove the buckets from state before destroying

## Troubleshooting

### Issue: Cannot assume role in target account

**Error**: `Error: error assuming role: AccessDenied`

**Solution**:
1. Verify the IAM role exists in the target account
2. Check the trust policy allows the source account to assume it
3. Verify your source account credentials have `sts:AssumeRole` permission
4. Ensure the role name matches `var.target_account_role_name`

### Issue: Replication fails with access denied

**Check**:
1. **Target bucket policy**: Must allow the replication role from source account
   ```bash
   aws s3api get-bucket-policy --bucket $TARGET_BUCKET --profile target-account
   ```

2. **KMS key policy**: Target KMS key must allow replication role to encrypt
   ```bash
   aws kms get-key-policy \
     --key-id <target-kms-key-id> \
     --policy-name default \
     --profile target-account
   ```

3. **Replication role**: Must have permissions to access target bucket
   ```bash
   aws s3api get-bucket-replication --bucket $SOURCE_BUCKET
   ```
   Check the Role ARN and verify it has necessary permissions.

### Issue: Target account resources not created

**Error**: Provider configuration errors or assume role failures

**Solution**:
1. Verify provider configuration in `main.tf`:
   ```hcl
   provider "aws" {
     alias = "target_account"
     assume_role {
       role_arn = "arn:aws:iam::${var.target_account_id}:role/..."
     }
   }
   ```

2. Test assume role manually:
   ```bash
   aws sts assume-role \
     --role-arn arn:aws:iam::<TARGET_ACCOUNT_ID>:role/TerraformCrossAccountRole \
     --role-session-name test-session
   ```

### Issue: KMS cross-account encryption fails

**Solution**: Ensure both KMS key policies allow cross-account access:

**Source KMS key**: Allow replication role to decrypt
**Target KMS key**: Allow replication role from source account to encrypt

The module configures this automatically through the replication sub-modules.

## Security Considerations

### Least Privilege Principle

1. **Replication role**: Should only have permissions necessary for replication
2. **Cross-account role**: Limit which principals in source account can assume it
3. **KMS keys**: Use separate keys per account for better security boundary

### Trust Relationships

The target account explicitly trusts the source account's replication role. Review:
- Which source account can replicate
- External ID conditions (add for extra security)
- Session duration limits

### Audit and Monitoring

Enable CloudTrail in both accounts to monitor:
- Cross-account role assumptions
- S3 replication API calls
- KMS key usage

## Cost Considerations

Cross-account replication incurs costs:
- **Data transfer**: Charges for data transferred between accounts
- **Storage**: Storage costs in both accounts
- **Replication requests**: S3 PUT requests in target account
- **KMS operations**: Encryption/decryption in both accounts

For production, review [AWS S3 Pricing](https://aws.amazon.com/s3/pricing/) for cross-account replication costs.

## Notes

- This is a demonstration example. For production use:
  - Use existing KMS keys with proper key policies
  - Implement proper lifecycle policies in both accounts
  - Add CloudWatch monitoring and alerting for both accounts
  - Consider using S3 Batch Replication for existing objects
  - Implement proper cost allocation tags
  - Review and adjust bucket policies for your security requirements
  - Use AWS Organizations for easier cross-account access management

- Replication only applies to new objects uploaded after replication is configured. To replicate existing objects, use [S3 Batch Replication](https://docs.aws.amazon.com/AmazonS3/latest/userguide/s3-batch-replication-batch.html).

- Both buckets will have auto-generated suffixes to ensure global uniqueness. Use the SSM parameters (`/s3/<name>/id`) to retrieve the actual bucket names programmatically.

- The example uses the same region for both accounts, but you can combine cross-account and cross-region by modifying the provider configurations.

## References

- [AWS S3 Cross-Account Replication](https://docs.aws.amazon.com/AmazonS3/latest/userguide/replication-walkthrough-2.html)
- [Cross-account IAM Roles](https://docs.aws.amazon.com/IAM/latest/UserGuide/tutorial_cross-account-with-roles.html)
- [Replicating encrypted objects (cross-account)](https://docs.aws.amazon.com/AmazonS3/latest/userguide/replication-config-for-kms-objects.html)
- [terraform-aws-s3 Module README](../../README.md)
