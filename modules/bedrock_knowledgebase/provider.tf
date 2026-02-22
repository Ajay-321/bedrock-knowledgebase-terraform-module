terraform {
  required_providers {
    opensearch = {
      source  = "opensearch-project/opensearch"
      version = "~> 2.3.0"
    }
  }
}

provider "opensearch" {
  url         = aws_opensearchserverless_collection.resource_kb.collection_endpoint
  healthcheck = false
  aws_region  = var.aws_region
}
