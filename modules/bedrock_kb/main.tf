data "aws_caller_identity" "this" {}
data "aws_partition" "this" {}
data "aws_region" "this" {}

locals {
  region    = data.aws_region.this.id
  partition = data.aws_partition.this.partition
}

# ─── Attach inline AOSS policy to each KB IAM role ───────────────────────────
# Done here (not in aoss module) so it references the collection ARN
# which is only known after the AOSS module runs. This maintains the
# correct dependency: iam → aoss → bedrock_kb.
resource "aws_iam_role_policy" "aoss_access" {
  for_each = var.knowledge_bases

  name = "${each.key}-aoss-access"
  # aws_iam_role_policy.role accepts name or ARN; use the name extracted from ARN
  role = element(split("/", each.value.kb_role_arn), length(split("/", each.value.kb_role_arn)) - 1)
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["aoss:APIAccessAll"]
      Resource = [each.value.collection_arn]
    }]
  })
}

# ─── Bedrock Knowledge Base (one per entry in the map) ───────────────────────
resource "aws_bedrockagent_knowledge_base" "this" {
  for_each = var.knowledge_bases

  name     = each.value.kb_name
  role_arn = each.value.kb_role_arn

  knowledge_base_configuration {
    type = "VECTOR"
    vector_knowledge_base_configuration {
      embedding_model_arn = "arn:${local.partition}:bedrock:${local.region}::foundation-model/${coalesce(each.value.kb_model_id, "amazon.titan-embed-text-v2:0")}"
    }
  }

  storage_configuration {
    type = "OPENSEARCH_SERVERLESS"
    opensearch_serverless_configuration {
      collection_arn    = each.value.collection_arn
      vector_index_name = each.value.vector_index_name
      field_mapping {
        vector_field   = "bedrock-knowledge-base-default-vector"
        text_field     = "AMAZON_BEDROCK_TEXT_CHUNK"
        metadata_field = "AMAZON_BEDROCK_METADATA"
      }
    }
  }

  tags       = var.common_tags
  depends_on = [aws_iam_role_policy.aoss_access]

  lifecycle {
    ignore_changes = [knowledge_base_configuration, storage_configuration]
  }
}

# ─── Data Source per KB ───────────────────────────────────────────────────────
resource "aws_bedrockagent_data_source" "this" {
  for_each = var.knowledge_bases

  knowledge_base_id    = aws_bedrockagent_knowledge_base.this[each.key].id
  name                 = "${each.value.kb_name}-data-source"
  data_deletion_policy = "RETAIN"

  data_source_configuration {
    type = "S3"
    s3_configuration {
      bucket_arn         = each.value.s3_bucket_arn
      inclusion_prefixes = each.value.s3_folder_prefix != "" ? [each.value.s3_folder_prefix] : null
    }
  }

  dynamic "vector_ingestion_configuration" {
    for_each = each.value.chunking_strategy != "DEFAULT" ? [each.value] : []
    content {
      chunking_configuration {
        chunking_strategy = vector_ingestion_configuration.value.chunking_strategy

        dynamic "fixed_size_chunking_configuration" {
          for_each = vector_ingestion_configuration.value.chunking_strategy == "FIXED_SIZE" ? [1] : []
          content {
            max_tokens         = vector_ingestion_configuration.value.fixed_size_max_tokens
            overlap_percentage = vector_ingestion_configuration.value.fixed_size_overlap_percentage
          }
        }

        dynamic "hierarchical_chunking_configuration" {
          for_each = vector_ingestion_configuration.value.chunking_strategy == "HIERARCHICAL" ? [1] : []
          content {
            overlap_tokens = vector_ingestion_configuration.value.hierarchical_overlap_tokens
            level_configuration {
              max_tokens = vector_ingestion_configuration.value.hierarchical_parent_max_tokens
            }
            level_configuration {
              max_tokens = vector_ingestion_configuration.value.hierarchical_child_max_tokens
            }
          }
        }

        dynamic "semantic_chunking_configuration" {
          for_each = vector_ingestion_configuration.value.chunking_strategy == "SEMANTIC" ? [1] : []
          content {
            max_token                       = vector_ingestion_configuration.value.semantic_max_tokens
            buffer_size                     = vector_ingestion_configuration.value.semantic_buffer_size
            breakpoint_percentile_threshold = vector_ingestion_configuration.value.semantic_breakpoint_percentile_threshold
          }
        }
      }
    }
  }
}





