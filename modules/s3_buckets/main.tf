data "aws_caller_identity" "current" {}

locals {
  # Build KMS ARN from key ID
  kms_key_arn = var.kms_key_id != null && var.kms_key_id != "" ? "arn:aws:kms:${var.aws_region}:${data.aws_caller_identity.current.account_id}:key/${var.kms_key_id}" : null
}

# S3 Buckets Resource
resource "aws_s3_bucket" "this" {
  for_each = var.buckets

  bucket = each.value.bucket_name

  tags = merge(
    var.common_tags,
    lookup(each.value, "tags", {})
  )
}

# Bucket Ownership Controls
resource "aws_s3_bucket_ownership_controls" "this" {
  for_each = aws_s3_bucket.this

  bucket = each.value.id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

# Block Public Access (PRIVATE)
resource "aws_s3_bucket_public_access_block" "this" {
  for_each = aws_s3_bucket.this

  bucket = each.value.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Versioning
resource "aws_s3_bucket_versioning" "this" {
  for_each = aws_s3_bucket.this

  bucket = each.value.id

  versioning_configuration {
    status = lookup(var.buckets[each.key], "versioning", false) ? "Enabled" : "Suspended"
  }
}

# Server Side Encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "this" {
  for_each = aws_s3_bucket.this
  bucket   = each.value.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = var.buckets[each.key].use_kms && local.kms_key_arn != null ? "aws:kms" : "AES256"
      kms_master_key_id = var.buckets[each.key].use_kms && local.kms_key_arn != null ? local.kms_key_arn : null
    }
    bucket_key_enabled = true
  }
}
