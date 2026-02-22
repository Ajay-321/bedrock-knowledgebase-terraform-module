# Bedrock Knowledge Base Module

This module creates an AWS Bedrock Knowledge Base with S3 as the data source. It requires an existing OpenSearch Serverless collection to be provided as input.

## Prerequisites

- An OpenSearch Serverless collection must be created separately using the `opensearch_serverless` module
- An IAM role with appropriate permissions for Bedrock Knowledge Base
- An S3 bucket containing the documents to be indexed

## Usage

```hcl
module "bedrock_knowledgebase" {
  source = "./modules/bedrock_knowledgebase"

  # Knowledge Base Configuration
  kb_name                        = "my-knowledge-base"
  kb_model_id                    = "amazon.titan-embed-text-v2:0"
  bedrock_knowledgebase_bucket   = "my-documents-bucket"
  s3_folder_prefix               = "documents/"

  # OpenSearch Configuration (from opensearch_serverless module)
  opensearch_collection_arn      = module.opensearch_serverless.collection_arn
  opensearch_index_name          = module.opensearch_serverless.index_name

  # IAM Role Configuration
  iam_role_reference             = module.bedrock_iam_role

  # KMS Configuration
  kms_key_id                     = module.kms.key_id

  # Chunking Strategy
  chunking_strategy              = "FIXED_SIZE"
  fixed_size_max_tokens          = 1000
  fixed_size_overlap_percentage  = 20

  # Trigger for ingestion
  s3_objects_trigger             = module.s3_objects.trigger_value

  # Common Tags
  common_tags = {
    Environment = "dev"
    Project     = "bedrock-kb"
  }

  aws_region = "us-east-1"
}
```

## Important Changes

This module has been refactored to separate concerns:

- **OpenSearch resources are no longer created by this module**
- Use the `opensearch_serverless` module to create the OpenSearch collection first
- Pass the collection ARN and index name as inputs to this module

## Inputs

| Name | Description | Type | Required |
|------|-------------|------|----------|
| opensearch_collection_arn | ARN of the OpenSearch Serverless collection | string | Yes |
| opensearch_index_name | Name of the OpenSearch index | string | Yes |
| bedrock_knowledgebase_bucket | S3 bucket name containing documents | string | Yes |
| iam_role_reference | Reference to IAM role object | object | Yes* |
| iam_role_arn | ARN of existing IAM role | string | Yes* |
| kms_key_id | KMS key ID for encryption | string | Yes |
| s3_objects_trigger | Trigger value from S3 objects module | string | Yes |
| kb_name | Knowledge base name | string | No |
| kb_model_id | Bedrock embedding model ID | string | No |
| chunking_strategy | Chunking strategy (DEFAULT, FIXED_SIZE, HIERARCHICAL, SEMANTIC, NONE) | string | No |
| s3_folder_prefix | S3 folder prefix for data source | string | No |
| common_tags | Common tags for resources | map(string) | No |
| aws_region | AWS region | string | Yes |

*Either `iam_role_reference` or `iam_role_arn` must be provided

## Outputs

| Name | Description |
|------|-------------|
| kb_id | Knowledge Base ID |
| knowledge_base_ARN | Knowledge Base ARN |
| data_source_id | Data Source ID |
| iam_role_arn | IAM role ARN used by the Knowledge Base |

## Chunking Strategies

The module supports multiple chunking strategies:

- **DEFAULT**: Use Bedrock's default chunking
- **FIXED_SIZE**: Fixed-size chunks with configurable overlap
- **HIERARCHICAL**: Parent-child chunk hierarchy
- **SEMANTIC**: Semantic boundary-based chunking
- **NONE**: No chunking applied

## Dependencies

This module depends on:
- `opensearch_serverless` module (must be created first)
- `bedrock_iam_role` module or existing IAM role
- `kms` module or existing KMS key
- S3 bucket with documents

## Example with OpenSearch Serverless Module

```hcl
# Create OpenSearch collection first
module "opensearch_serverless" {
  source = "./modules/opensearch_serverless"

  collection_name   = "bedrock-kb-collection"
  vector_dimension  = 1024
  index_name        = "bedrock-kb-index"
  kms_key_id        = module.kms.key_id
  iam_role_arn      = module.bedrock_iam_role.arn
  
  common_tags = var.common_tags
  aws_region  = var.aws_region
}

# Then create the Knowledge Base
module "bedrock_knowledgebase" {
  source = "./modules/bedrock_knowledgebase"

  opensearch_collection_arn    = module.opensearch_serverless.collection_arn
  opensearch_index_name        = module.opensearch_serverless.index_name
  bedrock_knowledgebase_bucket = "my-documents-bucket"
  iam_role_reference           = module.bedrock_iam_role
  kms_key_id                   = module.kms.key_id
  s3_objects_trigger           = module.s3_objects.trigger_value
  
  common_tags = var.common_tags
  aws_region  = var.aws_region
}
```
