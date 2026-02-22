variable "collection_name" {
  description = "Name of the OpenSearch Serverless collection"
  type        = string
}

variable "index_name" {
  description = "Name of the OpenSearch index"
  type        = string
}

variable "vector_dimension" {
  description = "Dimension of the vector embeddings"
  type        = number
  default     = 1024
}

variable "kms_key_arn" {
  description = "ARN of the KMS key for encryption"
  type        = string
}

variable "principal_arns" {
  description = "List of principal ARNs that need access to the collection"
  type        = list(string)
}

variable "allow_public_access" {
  description = "Whether to allow public access to the collection"
  type        = bool
  default     = true
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}
