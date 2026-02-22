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

variable "opensearch_collection_arn" {
  description = "ARN of the OpenSearch Serverless collection"
  type        = string
}

variable "opensearch_index_name" {
  description = "Name of the OpenSearch index"
  type        = string
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
  description = "DEPRECATED: Use iam_role_arn or iam_role_reference instead. IAM role name for backward compatibility. This will be removed in a future version."
  default     = null
}

variable "iam_role_arn" {
  description = "ARN of an existing IAM role to use for the Bedrock Knowledge Base. Mutually exclusive with iam_role_reference."
  type        = string
  default     = null

  validation {
    condition     = var.iam_role_arn == null || can(regex("^arn:aws:iam::[0-9]{12}:role/.+", var.iam_role_arn))
    error_message = "The iam_role_arn must be a valid IAM role ARN in the format: arn:aws:iam::ACCOUNT_ID:role/ROLE_NAME"
  }
}

variable "iam_role_reference" {
  description = "Reference to an existing IAM role resource. Mutually exclusive with iam_role_arn. Pass the role object (e.g., module.bedrock_iam_role)."
  type = object({
    arn  = string
    name = string
    id   = string
  })
  default = null
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