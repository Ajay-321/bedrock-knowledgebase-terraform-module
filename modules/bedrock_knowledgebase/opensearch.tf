# OpenSearch Serverless Collection Resource 
resource "aws_opensearchserverless_collection" "resource_kb" {
  name = local.kb_oss_collection_name
  type = "VECTORSEARCH"
  tags = var.common_tags

  depends_on = [
    aws_opensearchserverless_security_policy.resource_kb_encryption,
    aws_opensearchserverless_security_policy.resource_kb_network,
    time_sleep.wait_for_policies
  ]
}

# OpenSearch index creation
resource "opensearch_index" "resource_kb" {
  name                           = var.vector_index_name
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
    aws_opensearchserverless_collection.resource_kb,
    aws_opensearchserverless_access_policy.resource_kb,
    time_sleep.wait_for_policies
  ]
}