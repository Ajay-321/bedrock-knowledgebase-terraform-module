output "role_arn" {
  description = "ARN of the IAM role"
  value       = aws_iam_role.bedrock_kb.arn
}

output "role_name" {
  description = "Name of the IAM role"
  value       = aws_iam_role.bedrock_kb.name
}

output "role_id" {
  description = "ID of the IAM role"
  value       = aws_iam_role.bedrock_kb.id
}
