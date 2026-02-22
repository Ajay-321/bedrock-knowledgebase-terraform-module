# OpenSearch Serverless Module

This module creates an AWS OpenSearch Serverless collection configured for vector search, making it suitable for use with Amazon Bedrock Knowledge Bases or other vector search applications.

## Features

- Creates an OpenSearch Serverless collection with VECTORSEARCH type
- Configures encryption using customer-managed KMS keys
- Sets up access policies for specified principals
- Creates a vector index with HNSW algorithm (FAISS engine)
- Supports customizable vector dimensions
- Configurable network access (public/private)

## Usage

### Basic Example

```hcl
module "opensearch_serverless" {
  source = "./modules/opensearch_serverless"

  collection_name = "my-vector-collection"
  index_name      = "my-vector-index"
  kms_key_arn     = "arn:aws:kms:us-east-1:123456789012:key/12345678-1234-1234-1234-123456789012"
  
  principal_arns = [
    "arn:aws:iam::123456789012:role/my-bedrock-role",
    "arn:aws:sts::123456789012:assumed-role/my-role/session"
  ]

  tags = {
    Environment = "dev"
    Project     = "my-project"
  }
}
```

### Integration with Bedrock Knowledge Base

```hcl
# Create IAM role for Bedrock
module "bedrock_iam_role" {
  source = "./modules/bedrock_iam_role"
  
  role_name = "bedrock-kb-role"
  # ... other configuration
}

# Create OpenSearch Serverless collection
module "opensearch_serverless" {
  source = "./modules/opensearch_serverless"

  collection_name = "bedrock-kb-collection"
  index_name      = "bedrock-kb-index"
  vector_dimension = 1024  # For amazon.titan-embed-text-v2:0
  kms_key_arn     = module.kms.key_arn
  
  principal_arns = [
    data.aws_caller_identity.current.arn,
    module.bedrock_iam_role.arn
  ]

  allow_public_access = true

  tags = {
    Environment = "production"
    ManagedBy   = "terraform"
  }
}

# Create Bedrock Knowledge Base using the collection
resource "aws_bedrockagent_knowledge_base" "this" {
  name     = "my-knowledge-base"
  role_arn = module.bedrock_iam_role.arn

  knowledge_base_configuration {
    vector_knowledge_base_configuration {
      embedding_model_arn = "arn:aws:bedrock:us-east-1::foundation-model/amazon.titan-embed-text-v2:0"
    }
    type = "VECTOR"
  }

  storage_configuration {
    type = "OPENSEARCH_SERVERLESS"
    opensearch_serverless_configuration {
      collection_arn    = module.opensearch_serverless.collection_arn
      vector_index_name = module.opensearch_serverless.index_name
      field_mapping {
        vector_field   = "bedrock-knowledge-base-default-vector"
        text_field     = "AMAZON_BEDROCK_TEXT_CHUNK"
        metadata_field = "AMAZON_BEDROCK_METADATA"
      }
    }
  }
}
```

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.0 |
| aws | >= 5.0 |
| opensearch | ~> 2.3.0 |
| time | >= 0.9 |

## Providers

| Name | Version |
|------|---------|
| aws | >= 5.0 |
| opensearch | ~> 2.3.0 |
| time | >= 0.9 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| collection_name | Name of the OpenSearch Serverless collection | `string` | n/a | yes |
| index_name | Name of the OpenSearch index | `string` | n/a | yes |
| kms_key_arn | ARN of the KMS key for encryption | `string` | n/a | yes |
| principal_arns | List of principal ARNs that need access to the collection | `list(string)` | n/a | yes |
| vector_dimension | Dimension of the vector embeddings | `number` | `1024` | no |
| allow_public_access | Whether to allow public access to the collection | `bool` | `true` | no |
| tags | Tags to apply to resources | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| collection_arn | ARN of the OpenSearch Serverless collection |
| collection_id | ID of the OpenSearch Serverless collection |
| collection_endpoint | Endpoint of the OpenSearch Serverless collection |
| dashboard_endpoint | Dashboard endpoint of the OpenSearch Serverless collection |
| index_name | Name of the created OpenSearch index |

## Vector Dimensions by Model

Different embedding models produce vectors of different dimensions. Configure `vector_dimension` based on your chosen model:

| Model | Dimension |
|-------|-----------|
| amazon.titan-embed-text-v1 | 1536 |
| amazon.titan-embed-text-v2:0 | 1024 |
| cohere.embed-english-v3 | 1024 |
| cohere.embed-multilingual-v3 | 1024 |

## Index Configuration

The module creates an index with the following configuration:

- **Algorithm**: HNSW (Hierarchical Navigable Small World)
- **Engine**: FAISS
- **Space Type**: L2 (Euclidean distance)
- **Shards**: 2
- **Replicas**: 0 (serverless manages replication)

### Index Fields

- `bedrock-knowledge-base-default-vector`: KNN vector field for embeddings
- `AMAZON_BEDROCK_TEXT_CHUNK`: Text field for document chunks
- `AMAZON_BEDROCK_METADATA`: Metadata field (not indexed)

## Security Considerations

1. **Encryption**: The module requires a KMS key ARN for encryption at rest
2. **Access Control**: Use `principal_arns` to grant access only to necessary IAM roles/users
3. **Network Access**: Set `allow_public_access = false` for private collections (requires VPC configuration)
4. **Policy Lifecycle**: Access policies use `ignore_changes` to prevent drift from external modifications

## Notes

- The module includes a 30-second wait after policy creation to ensure proper propagation
- The index uses `force_destroy = true` for easier cleanup during development
- Index lifecycle is set to `ignore_changes = all` to prevent recreation on minor changes
- Collection names must be unique within your AWS account and region

## License

This module is part of the Bedrock Knowledge Base Terraform Module project.
