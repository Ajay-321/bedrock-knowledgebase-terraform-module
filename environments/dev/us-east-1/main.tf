module "bedrock_knowledge_base" {
  source                   = "../../../modules/bedrock_knowledge_base"
  bedrock_knowledgebase_bucket = var.bedrock_knowledgebase_bucket
  s3_folder_prefix         = var.s3_folder_prefix
  chunking_strategy        = var.chunking_strategy
  kb_model_id              = var.kb_model_id
  kb_name                  = var.kb_name
  kb_oss_collection_name   = var.kb_oss_collection_name
  vector_dimension         = var.vector_dimension
  vector_index_name        = var.vector_index_name
  bedrock_iam_role_name    = var.bedrock_iam_role_name
  common_tags              = var.common_tags
  aws_region               = var.aws_region
  kms_key_id               = module.kms_key.key_id
  s3_objects_trigger       = module.s3_object.bedrock_knowledgebase_docs_hash
  # Note: depends_on removed because module has local provider configuration
  # Dependency is implicit through s3_objects_trigger parameter
}

# S3 Bucket Module 
module "s3_bucket" {
  source      = "../../../modules/s3_bucket"
  buckets     = var.buckets
  aws_region  = var.aws_region
  kms_key_id  = module.kms_key.key_id
  common_tags = var.common_tags
}

# S3 Objects Module
module "s3_object" {
  source                   = "../../../modules/s3_objects"
  lambda_bucket            = module.s3_bucket.bucket_ids["lambda_artifacts"]
  kb_s3_bucket_name_prefix = var.kb_s3_bucket_name_prefix
  depends_on               = [module.s3_bucket]
}