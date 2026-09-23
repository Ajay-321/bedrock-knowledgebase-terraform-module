variable "collection_name" {
  description = "Name for the shared OSS collection. Used across all AOSS policies."
  type        = string
}

variable "indexes" {
  description = "Map of vector indexes to create inside the collection. One entry per Bedrock KB. Key must match the bedrock_knowledge_bases map key."
  type = map(object({
    vector_index_name = string
    vector_dimension  = optional(number, 1024)
    kb_role_arn       = string
  }))
}

variable "allow_public" {
  description = "Whether the collection allows public network access. Set to false when using VPC endpoints."
  type        = bool
  default     = true
}

variable "vpc_endpoint_id" {
  description = "OSS VPC endpoint ID. Required when allow_public = false."
  type        = string
  default     = ""
  validation {
    condition     = var.allow_public || length(var.vpc_endpoint_id) > 0
    error_message = "vpc_endpoint_id must be set when allow_public is false."
  }
}

variable "additional_principals" {
  description = "Extra IAM ARNs to include in the OSS data access policy (e.g. SageMaker roles)."
  type        = list(string)
  default     = []
}

variable "kms_key_arn" {
  description = "KMS key ARN for OSS collection encryption."
  type        = string
}

variable "aws_region" {
  description = "AWS region (used by the opensearch provider for SigV4 signing)."
  type        = string
}

variable "common_tags" {
  description = "Tags applied to all resources."
  type        = map(string)
  default     = {}
}
