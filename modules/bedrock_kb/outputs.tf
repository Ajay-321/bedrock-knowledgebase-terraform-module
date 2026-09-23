output "knowledge_base_ids" {
  description = "Map of Bedrock Knowledge Base IDs by key"
  value       = { for k, v in aws_bedrockagent_knowledge_base.this : k => v.id }
}

output "knowledge_base_arns" {
  description = "Map of Bedrock Knowledge Base ARNs by key"
  value       = { for k, v in aws_bedrockagent_knowledge_base.this : k => v.arn }
}

output "data_source_ids" {
  description = "Map of Bedrock Data Source IDs by key"
  value       = { for k, v in aws_bedrockagent_data_source.this : k => v.data_source_id }
}
