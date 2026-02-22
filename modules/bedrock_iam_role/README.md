# Bedrock IAM Role Module

This module creates IAM roles with trust policies and permissions specifically for AWS Bedrock Knowledge Base operations.

## Purpose

The Bedrock IAM Role module provides IAM role management for Bedrock Knowledge Base resources. It creates an IAM role with:
- Trust policy allowing bedrock.amazonaws.com service principal to assume the role
- Permissions for Bedrock model invocation
- Permissions for OpenSearch Serverless data access
- Permissions for S3 bucket access
- Permissions for KMS key usage

## Usage

```hcl
module "bedrock_iam_role" {
  source = "../modules/bedrock_iam_role"
  
  role_name                  = "bedrock-kb-role"
  s3_bucket_arn              = "arn:aws:s3:::my-kb-bucket"
  opensearch_collection_arn  = "arn:aws:aoss:us-east-1:123456789012:collection/my-collection"
  kms_key_arn                = module.kms_key.key_arn
  embedding_model_arn        = "arn:aws:bedrock:us-east-1::foundation-model/amazon.titan-embed-text-v2:0"
  
  tags = {
    Environment = "dev"
    Project     = "bedrock-kb"
  }
}
```

## Input Variables

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| role_name | Name for the IAM role | string | - | yes |
| s3_bucket_arn | ARN of the S3 bucket containing knowledge base data (format: `arn:aws:s3:::bucket-name`) | string | - | yes |
| opensearch_collection_arn | ARN of the OpenSearch Serverless collection (format: `arn:aws:aoss:region:account:collection/name`). If not provided, uses wildcard for all collections. | string | null | no |
| kms_key_arn | ARN of the KMS key for encryption (format: `arn:aws:kms:region:account:key/key-id`) | string | - | yes |
| embedding_model_arn | ARN of the Bedrock embedding model (format: `arn:aws:bedrock:region::foundation-model/model-id`) | string | - | yes |
| tags | Tags to apply to the IAM role | map(string) | {} | no |

## Outputs

| Name | Description |
|------|-------------|
| role_arn | ARN of the IAM role |
| role_name | Name of the IAM role |
| role_id | ID of the IAM role |

## Examples

### Basic Usage with KMS Module

```hcl
module "kms_key" {
  source = "../modules/kms"
  
  key_alias = "bedrock-kb-dev"
}

module "bedrock_iam_role" {
  source = "../modules/bedrock_iam_role"
  
  role_name                  = "bedrock-kb-dev-role"
  s3_bucket_arn              = "arn:aws:s3:::my-kb-bucket"
  opensearch_collection_arn  = "arn:aws:aoss:us-east-1:123456789012:collection/kb-collection"
  kms_key_arn                = module.kms_key.key_arn
  embedding_model_arn        = "arn:aws:bedrock:us-east-1::foundation-model/amazon.titan-embed-text-v2:0"
}
```

### With Custom Tags

```hcl
module "bedrock_iam_role" {
  source = "../modules/bedrock_iam_role"
  
  role_name                  = "bedrock-kb-prod-role"
  s3_bucket_arn              = "arn:aws:s3:::prod-kb-bucket"
  opensearch_collection_arn  = "arn:aws:aoss:us-east-1:123456789012:collection/prod-collection"
  kms_key_arn                = "arn:aws:kms:us-east-1:123456789012:key/12345678-1234-1234-1234-123456789012"
  embedding_model_arn        = "arn:aws:bedrock:us-east-1::foundation-model/amazon.titan-embed-text-v2:0"
  
  tags = {
    Environment = "production"
    ManagedBy   = "terraform"
    CostCenter  = "engineering"
  }
}
```

### Without OpenSearch ARN (Avoids Circular Dependency)

```hcl
# Create IAM role first without OpenSearch ARN
module "bedrock_iam_role" {
  source = "../modules/bedrock_iam_role"
  
  role_name           = "bedrock-kb-role"
  s3_bucket_arn       = "arn:aws:s3:::my-kb-bucket"
  # opensearch_collection_arn not provided - uses wildcard
  kms_key_arn         = module.kms_key.key_arn
  embedding_model_arn = "arn:aws:bedrock:us-east-1::foundation-model/amazon.titan-embed-text-v2:0"
}

# Then create Knowledge Base which creates OpenSearch collection
module "bedrock_knowledge_base" {
  source = "../modules/bedrock_knowledgebase"
  
  iam_role_reference = {
    arn  = module.bedrock_iam_role.role_arn
    name = module.bedrock_iam_role.role_name
    id   = module.bedrock_iam_role.role_id
  }
  # ... other variables
}
```

## IAM Permissions

The module creates an IAM role with the following permissions:

### Bedrock Permissions
- `bedrock:InvokeModel` - Allows invocation of the specified embedding model

### OpenSearch Serverless Permissions
- `aoss:APIAccessAll` - Allows full API access to the specified OpenSearch collection

### S3 Permissions
- `s3:GetObject` - Allows reading objects from the specified bucket
- `s3:ListBucket` - Allows listing objects in the specified bucket

### KMS Permissions
- `kms:Decrypt` - Allows decryption using the specified KMS key (with ViaService condition)
- `kms:DescribeKey` - Allows describing the specified KMS key (with ViaService condition)

## Trust Policy

The IAM role trust policy allows the Bedrock service to assume the role with the following conditions:
- Source account must match the current AWS account
- Source ARN must match the pattern for Bedrock Knowledge Base resources

## ARN Format Requirements

All ARN inputs are validated to ensure they match the expected format:

- **S3 Bucket ARN**: `arn:aws:s3:::bucket-name`
- **OpenSearch Collection ARN**: `arn:aws:aoss:region:account-id:collection/collection-name`
- **KMS Key ARN**: `arn:aws:kms:region:account-id:key/key-id`
- **Bedrock Model ARN**: `arn:aws:bedrock:region::foundation-model/model-id`

## Notes

- The IAM role is scoped to specific resources (no wildcard permissions except for OpenSearch when not provided)
- **OpenSearch ARN is optional**: If not provided, the module uses a wildcard (`collection/*`) to avoid circular dependency issues. You can provide the specific collection ARN later or use the wildcard for broader permissions.
- KMS permissions include a ViaService condition to ensure they're only used through S3 or OpenSearch
- The trust policy includes source account and source ARN conditions for security
- All permissions follow the principle of least privilege
