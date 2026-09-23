variable "role_name" {
  description = "Name for the IAM role"
  type        = string
}

variable "s3_bucket_arn" {
  description = "ARN of the S3 bucket containing knowledge base data"
  type        = string

  validation {
    condition     = can(regex("^arn:aws:s3:::[a-z0-9][a-z0-9.-]*[a-z0-9]$", var.s3_bucket_arn))
    error_message = "The s3_bucket_arn must be a valid S3 bucket ARN"
  }
}

variable "opensearch_collection_arn" {
  description = "ARN of the OpenSearch Serverless collection. If not provided, uses wildcard for all collections to avoid circular dependency."
  type        = string
  default     = null

  validation {
    condition     = var.opensearch_collection_arn == null || can(regex("^arn:aws:aoss:[a-z0-9-]+:[0-9]{12}:collection/[a-z0-9-]+$", var.opensearch_collection_arn))
    error_message = "The opensearch_collection_arn must be a valid OpenSearch Serverless collection ARN"
  }
}

variable "kms_key_arn" {
  description = "ARN of the KMS key for encryption"
  type        = string

  validation {
    condition     = can(regex("^arn:aws:kms:[a-z0-9-]+:[0-9]{12}:key/[a-f0-9-]+$", var.kms_key_arn))
    error_message = "The kms_key_arn must be a valid KMS key ARN"
  }
}

variable "embedding_model_arn" {
  description = "ARN of the Bedrock embedding model"
  type        = string

  validation {
    condition     = can(regex("^arn:aws:bedrock:[a-z0-9-]+::foundation-model/.+$", var.embedding_model_arn))
    error_message = "The embedding_model_arn must be a valid Bedrock model ARN"
  }
}

variable "tags" {
  description = "Tags to apply to the IAM role"
  type        = map(string)
  default     = {}
}
