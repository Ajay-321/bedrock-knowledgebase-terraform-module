locals {
  account_id            = data.aws_caller_identity.this.account_id
  partition             = data.aws_partition.this.partition
  region                = data.aws_region.this.id
  region_name_tokenized = split("-", local.region)
  region_short          = "${substr(local.region_name_tokenized[0], 0, 2)}${substr(local.region_name_tokenized[1], 0, 1)}${local.region_name_tokenized[2]}"
  bedrock_model_arn     = "arn:${local.partition}:bedrock:${local.region}::foundation-model/${coalesce(var.kb_model_id, "amazon.titan-embed-text-v2:0")}"
  bedrock_kb_name       = coalesce(var.kb_name, "dev-bedrock-knowledge-base")
  kms_key_arn           = "arn:aws:kms:${data.aws_region.this.id}:${data.aws_caller_identity.this.account_id}:key/${var.kms_key_id}"

  # Role input validation flags
  role_inputs_provided = [
    var.iam_role_arn != null,
    var.iam_role_reference != null,
    var.bedrock_iam_role_name != null
  ]

  role_input_count = length([for v in local.role_inputs_provided : v if v])

  # Resolved role ARN based on input method
  resolved_role_arn = (
    var.iam_role_arn != null ? var.iam_role_arn :
    var.iam_role_reference != null ? var.iam_role_reference.arn :
    var.bedrock_iam_role_name != null ? "arn:aws:iam::${local.account_id}:role/${var.bedrock_iam_role_name}" :
    null
  )

  # Deprecation warning
  deprecation_warning = var.bedrock_iam_role_name != null ? "WARNING: The bedrock_iam_role_name variable is deprecated. Please use iam_role_arn or iam_role_reference instead. This variable will be removed in a future version." : null
}