output "bedrock_knowledgebase_docs_hash" {
  description = "Hash of all bedrock KB documents to trigger ingestion when files change"
  value       = md5(jsonencode([for file in local.bedrock_knowledgebase_docs_files : filemd5("../../../${path.root}/bedrock_knowledgebase_docs/${file}")]))
}
