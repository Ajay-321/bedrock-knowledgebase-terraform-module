locals {
  bedrock_knowledgebase_docs_files = fileset("../../../${path.root}/bedrock_knowledgebase_docs", "**/*")
}

resource "aws_s3_object" "BedrockKnowledgebaseDocs" {
  for_each = local.bedrock_knowledgebase_docs_files

  bucket = var.bedrock_knowledgebase_bucket
  key    = "input/${each.value}"
  source = "../../../${path.root}/bedrock_knowledgebase_docs/${each.value}"
  etag   = filemd5("../../../${path.root}/bedrock_knowledgebase_docs/${each.value}")

  content_type = lookup(
    {
      "txt"  = "text/plain"
      "pdf"  = "application/pdf"
      "doc"  = "application/msword"
      "docx" = "application/vnd.openxmlformats-officedocument.wordprocessingml.document"
      "html" = "text/html"
      "md"   = "text/markdown"
      "json" = "application/json"
    },
    lower(split(".", each.value)[length(split(".", each.value)) - 1]),
    "application/octet-stream"
  )
}

