variable "knowledge_bases" {
  description = "Map of Bedrock Knowledge Base configurations. Each entry creates one KB, its data source, and attaches the AOSS inline policy to the KB IAM role."
  type = map(object({
    kb_name           = string
    kb_model_id       = optional(string, "amazon.titan-embed-text-v2:0")
    collection_arn    = string
    vector_index_name = string
    kb_role_arn       = string
    s3_bucket_arn     = string
    s3_folder_prefix  = optional(string, "")
    chunking_strategy = optional(string, "DEFAULT")

    # Fixed-size chunking
    fixed_size_max_tokens         = optional(number, 1000)
    fixed_size_overlap_percentage = optional(number, 20)

    # Hierarchical chunking
    hierarchical_overlap_tokens    = optional(number, 70)
    hierarchical_parent_max_tokens = optional(number, 1000)
    hierarchical_child_max_tokens  = optional(number, 500)

    # Semantic chunking
    semantic_max_tokens                      = optional(number, 512)
    semantic_buffer_size                     = optional(number, 1)
    semantic_breakpoint_percentile_threshold = optional(number, 75)
  }))

  validation {
    condition = alltrue([
      for k, v in var.knowledge_bases :
      contains(["DEFAULT", "FIXED_SIZE", "HIERARCHICAL", "SEMANTIC", "NONE"], v.chunking_strategy)
    ])
    error_message = "chunking_strategy must be one of: DEFAULT, FIXED_SIZE, HIERARCHICAL, SEMANTIC, NONE"
  }
}

variable "common_tags" {
  description = "Tags applied to all resources"
  type        = map(string)
  default     = {}
}
