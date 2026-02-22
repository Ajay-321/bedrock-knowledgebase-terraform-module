# Validation using check blocks (Terraform 1.5+)
check "role_input_validation" {
  assert {
    condition     = local.role_input_count == 1
    error_message = <<-EOT
      Exactly one role input method must be provided. You have provided ${local.role_input_count}.
      Choose one of:
      - iam_role_arn = "arn:aws:iam::..." (to use an existing role ARN)
      - iam_role_reference = module.bedrock_iam_role (to reference a role module output)
      - bedrock_iam_role_name = "role-name" (deprecated, for backward compatibility)
      
      To create a new role, use the bedrock_iam_role module separately.
    EOT
  }

  assert {
    condition     = local.role_input_count > 0
    error_message = "At least one role input method must be provided. Provide iam_role_arn, iam_role_reference, or bedrock_iam_role_name."
  }
}
