data "aws_region" "this" {}

# Note: Deployer roles are passed in via var.additional_principals (from tfvars).
# This avoids using data.aws_caller_identity, which returns a different ARN
# depending on who/what is running Terraform (developer vs CI/CD pipeline),
# causing the data-access policy to be mutated on every run and triggering
# unnecessary replacements of the collection and Bedrock KB.

# ─── Encryption policy ────────────────────────────────────────────────────────
resource "aws_opensearchserverless_security_policy" "encryption" {
  name = var.collection_name
  type = "encryption"
  policy = jsonencode({
    Rules  = [{ Resource = ["collection/${var.collection_name}"], ResourceType = "collection" }]
    KmsARN = var.kms_key_arn
  })
}

# ─── Network policy ───────────────────────────────────────────────────────────
# Public access: AllowFromPublic = true.
# Private access: AllowFromPublic = false + SourceVPCEs when vpc_endpoint_id is set.
resource "aws_opensearchserverless_security_policy" "network" {
  name = var.collection_name
  type = "network"
  policy = var.allow_public ? jsonencode([{
    Rules = [
      { ResourceType = "collection", Resource = ["collection/${var.collection_name}"] },
      { ResourceType = "dashboard", Resource = ["collection/${var.collection_name}"] }
    ]
    AllowFromPublic = true
    }]) : jsonencode([merge(
    {
      Rules = [
        { ResourceType = "collection", Resource = ["collection/${var.collection_name}"] },
        { ResourceType = "dashboard", Resource = ["collection/${var.collection_name}"] }
      ]
      AllowFromPublic = false
    },
    length(trimspace(var.vpc_endpoint_id)) > 0 ? { SourceVPCEs = [trimspace(var.vpc_endpoint_id)] } : {}
  )])
}

# ─── Data access policy — grants all KB roles access to the shared collection ─
resource "aws_opensearchserverless_access_policy" "this" {
  name = var.collection_name
  type = "data"
  policy = jsonencode([{
    Rules = [
      {
        ResourceType = "index"
        Resource     = ["index/${var.collection_name}/*"]
        Permission = ["aoss:CreateIndex", "aoss:DeleteIndex", "aoss:DescribeIndex",
        "aoss:ReadDocument", "aoss:UpdateIndex", "aoss:WriteDocument"]
      },
      {
        ResourceType = "collection"
        Resource     = ["collection/${var.collection_name}"]
        Permission   = ["aoss:CreateCollectionItems", "aoss:DescribeCollectionItems", "aoss:UpdateCollectionItems"]
      }
    ]
    Principal = distinct(concat(
      [for k, v in var.indexes : v.kb_role_arn],
      var.additional_principals
    ))
  }])
}

# ─── Wait for policies to propagate ──────────────────────────────────────────
resource "time_sleep" "wait_for_policies" {
  create_duration = "90s"
  depends_on = [
    aws_opensearchserverless_access_policy.this,
    aws_opensearchserverless_security_policy.encryption,
    aws_opensearchserverless_security_policy.network,
  ]
}

# ─── Dedicated OSS collection for this KB ─────────────────────────────────────
resource "aws_opensearchserverless_collection" "this" {
  name = var.collection_name
  type = "VECTORSEARCH"
  tags = var.common_tags

  depends_on = [time_sleep.wait_for_policies]
}

# ─── KNN vector index — one per KB, all in the shared collection ─────────────
resource "opensearch_index" "this" {
  for_each = var.indexes

  name                           = each.value.vector_index_name
  number_of_shards               = "2"
  number_of_replicas             = "0"
  index_knn                      = true
  index_knn_algo_param_ef_search = "512"
  mappings = jsonencode({
    properties = {
      "bedrock-knowledge-base-default-vector" = {
        type      = "knn_vector"
        dimension = each.value.vector_dimension
        method = {
          name       = "hnsw"
          engine     = "faiss"
          parameters = { m = 16, ef_construction = 512 }
          space_type = "l2"
        }
      }
      AMAZON_BEDROCK_METADATA   = { type = "text", index = false }
      AMAZON_BEDROCK_TEXT_CHUNK = { type = "text", index = true }
    }
  })
  force_destroy = true

  # All opensearch index settings (mappings, shard/replica counts, knn params)
  # are immutable after creation in AOSS — the API does not allow in-place updates.
  # The opensearch provider cannot round-trip these fields cleanly from the AOSS
  # read API (e.g. boolean `index` fields, ef_search not exposed), so every plan
  # shows false drift and would force a replacement. Matching the AWS reference
  # implementation: github.com/aws-samples/intelligent-rag-bedrockagent-iac
  # To change index settings, rename vector_index_name in tfvars — the name
  # change (a ForceNew field) will correctly trigger destroy+recreate.
  lifecycle {
    ignore_changes = all
  }

  depends_on = [
    aws_opensearchserverless_collection.this,
    aws_opensearchserverless_access_policy.this,
    aws_opensearchserverless_security_policy.network,
    time_sleep.wait_for_policies,
  ]
}

# ─── Wait for indexes to propagate before Bedrock validates them ──────────────
resource "time_sleep" "wait_for_index" {
  create_duration = "60s"
  triggers        = { collection_arn = aws_opensearchserverless_collection.this.arn }
  depends_on      = [opensearch_index.this]
}
