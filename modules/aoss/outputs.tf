output "collection_arn" {
  description = "ARN of the OSS collection for this KB"
  value       = aws_opensearchserverless_collection.this.arn
}

output "collection_endpoint" {
  description = "Endpoint URL of the OSS collection for this KB"
  value       = aws_opensearchserverless_collection.this.collection_endpoint
}

output "collection_name" {
  description = "Name of the OSS collection for this KB"
  value       = aws_opensearchserverless_collection.this.name
}

output "indexes_ready" {
  description = "Signal that indexes have been created. Reference this in downstream modules to enforce ordering."
  value       = { for k, v in opensearch_index.this : k => v.id }
}