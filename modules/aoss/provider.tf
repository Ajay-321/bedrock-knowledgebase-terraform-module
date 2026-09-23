terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.37"
    }
    time = {
      source  = "hashicorp/time"
      version = "~> 0.11"
    }
    opensearch = {
      source  = "opensearch-project/opensearch"
      version = "~> 2.3.0"
    }
  }
}

provider "opensearch" {
  url         = aws_opensearchserverless_collection.this.collection_endpoint
  healthcheck = false
}
