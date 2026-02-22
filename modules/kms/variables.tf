variable "key_alias" {
  description = "Alias for the KMS key. Will be prefixed with 'alias/' automatically."
  type        = string
}

variable "key_description" {
  description = "Description for the KMS key"
  type        = string
  default     = "KMS key for S3, Bedrock, and OpenSearch encryption"
}

variable "enable_key_rotation" {
  description = "Whether to enable automatic key rotation"
  type        = bool
  default     = true
}

variable "deletion_window_in_days" {
  description = "Duration in days after which the key is deleted after destruction"
  type        = number
  default     = 30

  validation {
    condition     = var.deletion_window_in_days >= 7 && var.deletion_window_in_days <= 30
    error_message = "Deletion window must be between 7 and 30 days"
  }
}

variable "tags" {
  description = "Tags to apply to the KMS key"
  type        = map(string)
  default     = {}
}
