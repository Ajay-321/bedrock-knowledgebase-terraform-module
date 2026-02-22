output "bucket_ids" {
  description = "A map of S3 bucket IDs by their given key."
  value       = { for k, v in aws_s3_bucket.this : k => v.id }
}

output "bucket_arns" {
  description = "A map of S3 bucket ARNs by their given key."
  value       = { for k, v in aws_s3_bucket.this : k => v.arn }
}

output "bucket_names" {
  description = "A map of S3 bucket names by their given key."
  value       = { for k, v in aws_s3_bucket.this : k => v.bucket }
}
