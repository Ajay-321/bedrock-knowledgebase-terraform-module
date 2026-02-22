# OpenSearch collection access policy
resource "aws_opensearchserverless_access_policy" "resource_kb" {
  name = local.kb_oss_collection_name
  type = "data"
  policy = jsonencode([
    {
      Rules = [
        {
          ResourceType = "index"
          Resource = [
            "index/${local.kb_oss_collection_name}/*"
          ]
          Permission = [
            "aoss:CreateIndex",
            "aoss:DeleteIndex",
            "aoss:DescribeIndex",
            "aoss:ReadDocument",
            "aoss:UpdateIndex",
            "aoss:WriteDocument"
          ]
        },
        {
          ResourceType = "collection"
          Resource = [
            "collection/${local.kb_oss_collection_name}"
          ]
          Permission = [
            "aoss:CreateCollectionItems",
            "aoss:DescribeCollectionItems",
            "aoss:UpdateCollectionItems"
          ]
        }
      ],
      Principal = [
        data.aws_caller_identity.this.arn,
        "arn:aws:iam::${data.aws_caller_identity.this.account_id}:role/${var.bedrock_iam_role_name}"
      ]
    }
  ])

  lifecycle {
    ignore_changes = [policy]
  }
}

# OpenSearch collection data encryption policy
resource "aws_opensearchserverless_security_policy" "resource_kb_encryption" {
  name = local.kb_oss_collection_name
  type = "encryption"
  policy = jsonencode({
    Rules = [
      {
        Resource = [
          "collection/${local.kb_oss_collection_name}"
        ]
        ResourceType = "collection"
      }
    ],
    #AWSOwnedKey = true
    KmsARN = local.kms_key_arn
  })
}

# OpenSearch collection network policy
resource "aws_opensearchserverless_security_policy" "resource_kb_network" {
  name = local.kb_oss_collection_name
  type = "network"
  policy = jsonencode([
    {
      Rules = [
        {
          ResourceType = "collection"
          Resource = [
            "collection/${local.kb_oss_collection_name}"
          ]
        },
        {
          ResourceType = "dashboard"
          Resource = [
            "collection/${local.kb_oss_collection_name}"
          ]
        }
      ]
      AllowFromPublic = true
    }
  ])
}

resource "time_sleep" "wait_for_policies" {
  create_duration = "30s"

  depends_on = [
    aws_opensearchserverless_access_policy.resource_kb,
    aws_opensearchserverless_security_policy.resource_kb_encryption,
    aws_opensearchserverless_security_policy.resource_kb_network
  ]
}