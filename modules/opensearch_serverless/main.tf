# OpenSearch Serverless Collection Module
# This module creates an OpenSearch Serverless collection with vector search capabilities

# OpenSearch collection access policy
resource "aws_opensearchserverless_access_policy" "this" {
  name = var.collection_name
  type = "data"
  policy = jsonencode([
    {
      Rules = [
        {
          ResourceType = "index"
          Resource = [
            "index/${var.collection_name}/*"
          ]
          Permission = [
            "aoss:CreateIndex",
            "aoss:DeleteIndex",
            "aoss:DescribeIndex",
            "aoss:ReadDocument",
            "aoss:UpdateIndex",
            "aoss:WriteDocument"
          ]
        },
        {
          ResourceType = "collection"
          Resource = [
            "collection/${var.collection_name}"
          ]
          Permission = [
            "aoss:CreateCollectionItems",
            "aoss:DescribeCollectionItems",
            "aoss:UpdateCollectionItems"
          ]
        }
      ],
      Principal = var.principal_arns
    }
  ])

  lifecycle {
    ignore_changes = [policy]
  }
}

# OpenSearch collection data encryption policy
resource "aws_opensearchserverless_security_policy" "encryption" {
  name = var.collection_name
  type = "encryption"
  policy = jsonencode({
    Rules = [
      {
        Resource = [
          "collection/${var.collection_name}"
        ]
        ResourceType = "collection"
      }
    ],
    KmsARN = var.kms_key_arn
  })
}

# OpenSearch collection network policy
resource "aws_opensearchserverless_security_policy" "network" {
  name = var.collection_name
  type = "network"
  policy = jsonencode([
    {
      Rules = [
        {
          ResourceType = "collection"
          Resource = [
            "collection/${var.collection_name}"
          ]
        },
        {
          ResourceType = "dashboard"
          Resource = [
            "collection/${var.collection_name}"
          ]
        }
      ]
      AllowFromPublic = var.allow_public_access
    }
  ])
}

# Wait for policies to propagate
resource "time_sleep" "wait_for_policies" {
  create_duration = "30s"

  depends_on = [
    aws_opensearchserverless_access_policy.this,
    aws_opensearchserverless_security_policy.encryption,
    aws_opensearchserverless_security_policy.network
  ]
}

# OpenSearch Serverless Collection Resource 
resource "aws_opensearchserverless_collection" "this" {
  name = var.collection_name
  type = "VECTORSEARCH"
  tags = var.tags

  depends_on = [
    aws_opensearchserverless_security_policy.encryption,
    aws_opensearchserverless_security_policy.network,
    time_sleep.wait_for_policies
  ]
}

# OpenSearch index creation
resource "opensearch_index" "this" {
  name                           = var.index_name
  number_of_shards               = "2"
  number_of_replicas             = "0"
  index_knn                      = true
  index_knn_algo_param_ef_search = "512"
  mappings = jsonencode(
    {
      "properties" : {
        "bedrock-knowledge-base-default-vector" : {
          "type" : "knn_vector",
          "dimension" : "${var.vector_dimension}",
          "method" : {
            "name" : "hnsw",
            "engine" : "faiss",
            "parameters" : {
              "m" : 16,
              "ef_construction" : 512
            },
            "space_type" : "l2"
          }
        },
        "AMAZON_BEDROCK_METADATA" : {
          "type" : "text",
          "index" : "false"
        },
        "AMAZON_BEDROCK_TEXT_CHUNK" : {
          "type" : "text",
          "index" : "true"
        }
      }
  })
  force_destroy = true
  lifecycle {
    ignore_changes = all
  }

  depends_on = [
    aws_opensearchserverless_collection.this,
    aws_opensearchserverless_access_policy.this,
    time_sleep.wait_for_policies
  ]
}
