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
