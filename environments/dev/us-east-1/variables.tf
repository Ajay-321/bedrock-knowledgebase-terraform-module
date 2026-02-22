variable "kb_model_id" {
  description = "The ID of the foundational model used by the knowledge base."
  type        = string
  default     = "amazon.titan-embed-text-v2:0"
}

variable "kb_name" {
  description = "The knowledge base name."
  type        = string
  default     = "resourceKB"
}

variable "bedrock_knowledgebase_bucket" {
  description = "The name prefix of the S3 bucket for the data source of the knowledge base."
  type        = string
}

variable "kb_oss_collection_name" {
  description = "The name of the OSS collection for the knowledge base."
  type        = string
  default     = "bedrock-resource-kb"
}

variable "vector_dimension" {
  description = "The dimension of the vectors produced by the model."
  type        = number
  default     = 1024
}

variable "chunking_strategy" {
  type        = string
  description = "Chunking strategy to use (DEFAULT, FIXED_SIZE, HIERARCHICAL, SEMANTIC)"
  default     = "FIXED_SIZE"
  validation {
    condition     = contains(["DEFAULT", "FIXED_SIZE", "HIERARCHICAL", "SEMANTIC", "NONE"], var.chunking_strategy)
    error_message = "Chunking strategy must be one of: DEFAULT, FIXED_SIZE, HIERARCHICAL, SEMANTIC, NONE"
  }
}

# Fixed Size Chunking Variables
variable "fixed_size_max_tokens" {
  type        = number
  description = "Maximum number of tokens for fixed-size chunking"
  default     = 1000
}

variable "fixed_size_overlap_percentage" {
  type        = number
  description = "Percentage of overlap between chunks"
  default     = 20
}

# Hierarchical Chunking Variables
variable "hierarchical_overlap_tokens" {
  type        = number
  description = "Number of tokens to overlap in hierarchical chunking"
  default     = 70
}

variable "hierarchical_parent_max_tokens" {
  type        = number
  description = "Maximum tokens for parent chunks"
  default     = 1000
}

variable "hierarchical_child_max_tokens" {
  type        = number
  description = "Maximum tokens for child chunks"
  default     = 500
}

# Semantic Chunking Variables
variable "semantic_max_tokens" {
  type        = number
  description = "Maximum tokens for semantic chunking"
  default     = 512
}

variable "semantic_buffer_size" {
  type        = number
  description = "Buffer size for semantic chunking"
  default     = 1
}

variable "semantic_breakpoint_percentile_threshold" {
  type        = number
  description = "Breakpoint percentile threshold for semantic chunking"
  default     = 75
}

variable "s3_folder_prefix" {
  description = "S3 folder prefix for knowledge base data source. Leave empty to process entire bucket."
  type        = string
  default     = ""
}

variable "common_tags" {
  type        = map(string)
  default     = {}
  description = "Common tags to apply to all AWS resources"
}

variable "aws_region" {
  type = string
}

variable "bedrock_iam_role_name" {
  type        = string
  description = "IAM Role Arn with Access of Bedrock and Opensearch Serverless"
}

variable "vector_index_name" {
  type        = string
  description = "Opensearch Serverless Index Name for Bedrock Knowledgebase"
}

variable "kms_key_id" {
  type        = string
  description = "Custom KMS Key Id for encryption"
}

variable "gha_role_name" {
  description = "Role Name of the GHA Role"
  type        = string
  default     = ""
}

variable "s3_objects_trigger" {
  description = "Trigger value from S3 objects module to force ingestion job when files change"
  type        = string
}

variable "buckets" {
  description = "Map of S3 buckets"
  type = map(object({
    bucket_name = string
    versioning  = optional(bool, false)
    use_kms     = optional(bool, false) # Simple flag
    tags        = optional(map(string), {})
  }))
}

variable "common_tags" {
  type        = map(string)
  default     = {}
  description = "Common tags to apply to all AWS resources"
}

variable "aws_region" {
  type = string
}

variable "kms_key_id" {
  type        = string
  description = "Custom KMS Key Id for encryption"
}
