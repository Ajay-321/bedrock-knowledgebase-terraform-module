# KMS Module

This module creates and manages AWS KMS keys with appropriate policies for Bedrock Knowledge Base and OpenSearch Serverless encryption.

## Purpose

The KMS module provides encryption key management for S3 buckets, Bedrock Knowledge Base, and OpenSearch Serverless resources. It creates a KMS key with policies that allow:
- AWS account root user full permissions
- S3 service to use the key for bucket encryption
- Bedrock service to use the key for encryption/decryption
- OpenSearch Serverless service to use the key for encryption/decryption

## Usage

```hcl
module "kms_key" {
  source = "../modules/kms"
  
  key_alias       = "bedrock-kb-dev"
  key_description = "KMS key for Bedrock Knowledge Base in dev environment"
  
  enable_key_rotation     = true
  deletion_window_in_days = 30
  
  tags = {
    Environment = "dev"
    Project     = "bedrock-kb"
  }
}
```

## Input Variables

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| key_alias | Alias for the KMS key. Will be prefixed with 'alias/' automatically. | string | - | yes |
| key_description | Description for the KMS key | string | "KMS key for S3, Bedrock, and OpenSearch encryption" | no |
| enable_key_rotation | Whether to enable automatic key rotation | bool | true | no |
| deletion_window_in_days | Duration in days after which the key is deleted after destruction (7-30) | number | 30 | no |
| tags | Tags to apply to the KMS key | map(string) | {} | no |

## Outputs

| Name | Description |
|------|-------------|
| key_id | The globally unique identifier for the KMS key |
| key_arn | The Amazon Resource Name (ARN) of the KMS key |
| key_alias | The alias of the KMS key |

## Examples

### Basic Usage

```hcl
module "kms_key" {
  source = "../modules/kms"
  
  key_alias = "bedrock-kb-prod"
}
```

### With Custom Settings

```hcl
module "kms_key" {
  source = "../modules/kms"
  
  key_alias               = "bedrock-kb-staging"
  key_description         = "Staging environment KMS key"
  enable_key_rotation     = false
  deletion_window_in_days = 7
  
  tags = {
    Environment = "staging"
    ManagedBy   = "terraform"
  }
}
```

## KMS Key Policy

The module creates a KMS key with the following policy statements:

1. **Root Account Permissions**: Grants full KMS permissions to the AWS account root user
2. **Bedrock Service Permissions**: Allows bedrock.amazonaws.com to decrypt, describe, and create grants (with ViaService condition for S3 and OpenSearch)
3. **OpenSearch Serverless Permissions**: Allows aoss.amazonaws.com to decrypt, describe, and create grants
4. **S3 Service Permissions**: Allows s3.amazonaws.com to encrypt, decrypt, and generate data keys

## Notes

- The key alias is automatically prefixed with "alias/" - do not include this in the `key_alias` variable
- Key rotation is enabled by default for security best practices
- The deletion window must be between 7 and 30 days per AWS requirements
- The KMS key policy allows both Bedrock and OpenSearch Serverless services to use the key for encryption operations
