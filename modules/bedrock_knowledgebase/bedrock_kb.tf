# Knowledge base resource creation
resource "aws_bedrockagent_knowledge_base" "resource_kb" {
  name     = local.bedrock_kb_name
  role_arn = "arn:aws:iam::${data.aws_caller_identity.this.account_id}:role/${var.bedrock_iam_role_name}"
  knowledge_base_configuration {
    vector_knowledge_base_configuration {
      embedding_model_arn = local.bedrock_model_arn
    }
    type = "VECTOR"
  }
  storage_configuration {
    type = "OPENSEARCH_SERVERLESS"
    opensearch_serverless_configuration {
      collection_arn    = aws_opensearchserverless_collection.resource_kb.arn
      vector_index_name = var.vector_index_name
      field_mapping {
        vector_field   = "bedrock-knowledge-base-default-vector"
        text_field     = "AMAZON_BEDROCK_TEXT_CHUNK"
        metadata_field = "AMAZON_BEDROCK_METADATA"
      }
    }
  }
  depends_on = [
    opensearch_index.resource_kb,
    aws_opensearchserverless_access_policy.resource_kb,
    aws_opensearchserverless_security_policy.resource_kb_encryption,
    aws_opensearchserverless_security_policy.resource_kb_network
  ]
  tags = var.common_tags
}

#Bedrock Knowledgebase Data Source Creation
resource "aws_bedrockagent_data_source" "resource_kb" {
  knowledge_base_id = aws_bedrockagent_knowledge_base.resource_kb.id
  name              = "${local.bedrock_kb_name}-data-source"
  data_source_configuration {
    type = "S3"
    s3_configuration {
      bucket_arn         = data.aws_s3_bucket.resource_kb.arn
      inclusion_prefixes = var.s3_folder_prefix != "" ? [var.s3_folder_prefix] : null
    }
  }

  # Only include vector_ingestion_configuration if not using DEFAULT strategy
  dynamic "vector_ingestion_configuration" {
    for_each = var.chunking_strategy != "DEFAULT" ? [1] : []
    content {
      chunking_configuration {
        chunking_strategy = var.chunking_strategy

        dynamic "fixed_size_chunking_configuration" {
          for_each = var.chunking_strategy == "FIXED_SIZE" ? [1] : []
          content {
            max_tokens         = var.fixed_size_max_tokens
            overlap_percentage = var.fixed_size_overlap_percentage
          }
        }

        dynamic "hierarchical_chunking_configuration" {
          for_each = var.chunking_strategy == "HIERARCHICAL" ? [1] : []
          content {
            overlap_tokens = var.hierarchical_overlap_tokens
            level_configuration {
              max_tokens = var.hierarchical_parent_max_tokens
            }
            level_configuration {
              max_tokens = var.hierarchical_child_max_tokens
            }
          }
        }

        dynamic "semantic_chunking_configuration" {
          for_each = var.chunking_strategy == "SEMANTIC" ? [1] : []
          content {
            max_token                       = var.semantic_max_tokens
            buffer_size                     = var.semantic_buffer_size
            breakpoint_percentile_threshold = var.semantic_breakpoint_percentile_threshold
          }
        }
      }
    }
  }
}

# Trigger ingestion job to sync documents from S3 to Knowledge Base
resource "null_resource" "trigger_kb_ingestion" {
  triggers = {
    # Trigger when data source is created or updated
    data_source_id = aws_bedrockagent_data_source.resource_kb.id
    # Trigger when S3 files change (passed from s3_objects module)
    s3_files_hash = var.s3_objects_trigger != "" ? var.s3_objects_trigger : "initial"
  }

  provisioner "local-exec" {
    command = <<-EOT
      set -e
      echo "Starting ingestion job for Knowledge Base data source..."
      
      # Start ingestion job
      INGESTION_JOB_ID=$(aws bedrock-agent start-ingestion-job \
        --knowledge-base-id ${aws_bedrockagent_knowledge_base.resource_kb.id} \
        --data-source-id ${aws_bedrockagent_data_source.resource_kb.data_source_id} \
        --region ${data.aws_region.this.name} \
        --query 'ingestionJob.ingestionJobId' \
        --output text)
      
      if [ -z "$INGESTION_JOB_ID" ]; then
        echo "ERROR: Failed to start ingestion job"
        exit 1
      fi
      
      echo "Ingestion job started with ID: $INGESTION_JOB_ID"
      echo "Waiting for ingestion job to complete..."
      
      # Wait for ingestion job to complete (with timeout)
      MAX_WAIT_TIME=300  # 5 minutes
      ELAPSED_TIME=0
      SLEEP_INTERVAL=10
      
      while [ $ELAPSED_TIME -lt $MAX_WAIT_TIME ]; do
        STATUS=$(aws bedrock-agent get-ingestion-job \
          --knowledge-base-id ${aws_bedrockagent_knowledge_base.resource_kb.id} \
          --data-source-id ${aws_bedrockagent_data_source.resource_kb.data_source_id} \
          --ingestion-job-id $INGESTION_JOB_ID \
          --region ${data.aws_region.this.name} \
          --query 'ingestionJob.status' \
          --output text)
        
        echo "Current status: $STATUS"
        
        if [ "$STATUS" = "COMPLETE" ]; then
          echo "Ingestion job completed successfully!"
          
          # Get statistics
          STATS=$(aws bedrock-agent get-ingestion-job \
            --knowledge-base-id ${aws_bedrockagent_knowledge_base.resource_kb.id} \
            --data-source-id ${aws_bedrockagent_data_source.resource_kb.data_source_id} \
            --ingestion-job-id $INGESTION_JOB_ID \
            --region ${data.aws_region.this.name} \
            --query 'ingestionJob.statistics' \
            --output json)
          
          echo "Ingestion statistics: $STATS"
          exit 0
        elif [ "$STATUS" = "FAILED" ]; then
          echo "ERROR: Ingestion job failed"
          
          # Get failure reasons
          FAILURE_REASONS=$(aws bedrock-agent get-ingestion-job \
            --knowledge-base-id ${aws_bedrockagent_knowledge_base.resource_kb.id} \
            --data-source-id ${aws_bedrockagent_data_source.resource_kb.data_source_id} \
            --ingestion-job-id $INGESTION_JOB_ID \
            --region ${data.aws_region.this.name} \
            --query 'ingestionJob.failureReasons' \
            --output json)
          
          echo "Failure reasons: $FAILURE_REASONS"
          exit 1
        fi
        
        sleep $SLEEP_INTERVAL
        ELAPSED_TIME=$((ELAPSED_TIME + SLEEP_INTERVAL))
      done
      
      echo "WARNING: Ingestion job did not complete within $MAX_WAIT_TIME seconds"
      echo "Job is still running. Check AWS console for status."
      exit 0
    EOT

    environment = {
      AWS_REGION = data.aws_region.this.name
    }
  }

  depends_on = [aws_bedrockagent_data_source.resource_kb]
}
