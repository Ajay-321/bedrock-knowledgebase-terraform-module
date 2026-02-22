common_tags = {
  Environment = "Dev"
  Project     = "Agentic AI"
}

 #KMS Key Configuration
# kms_alias_name  = "dev-us-east-1-kms-key"
# kms_description = "Key used for Encryption"

#S3 Bucket Variables
buckets = {
  "bedrock_knowledgebase_bucket" = {
    bucket_name = "bedrock-knowledgebase-bucket-dev-us-east-1"
    versioning  = false
    use_kms     = true
}
}

#Bedrock Knowledgebase and Opensearch Serverless vector variables
vector_index_name        = "dev-bedrock-knowledge-base-default-index"
kb_name                  = "dev-bedrock-knowledge-base"
chunking_strategy        = "DEFAULT"
kb_model_id              = "amazon.titan-embed-text-v2:0"
kb_oss_collection_name   = "dev-bedrock-kb-coll"
s3_folder_prefix         = "input"
bedrock_iam_role_name    = "Development-BedrockExecutionRole"
vector_dimension         = "1024"