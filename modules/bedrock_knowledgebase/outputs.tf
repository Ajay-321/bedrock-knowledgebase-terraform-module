output "kb_id" {
  description = "Knowledgebase ID"
  value       = aws_bedrockagent_knowledge_base.resource_kb.id
}

output "data_source_id" {
  description = "Data Source ID"
  value       = aws_bedrockagent_data_source.resource_kb.data_source_id
}

output "account_id" {
  value = data.aws_caller_identity.this.account_id
}

output "partition" {
  value = data.aws_partition.this.partition
}

output "region" {
  value = local.region
}

output "region_short" {
  value = local.region_short
}

output "bedrockarn" {
  value = local.bedrock_model_arn
}

output "knowledge_base_id" {
  value       = aws_bedrockagent_knowledge_base.resource_kb.id
  description = "The ID of the Knowledge Base"
}

output "knowledge_base_ARN" {
  value       = aws_bedrockagent_knowledge_base.resource_kb.arn
  description = "The ARN of the Knowledge Base"
}

output "s3_bucket_name" {
  value = data.aws_s3_bucket.resource_kb.bucket
}
