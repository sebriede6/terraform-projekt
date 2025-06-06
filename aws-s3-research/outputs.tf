output "research_bucket_id" {
  description = "The ID (name) of the created S3 bucket."
  value       = aws_s3_bucket.my_research_bucket.id
}

output "research_bucket_arn" {
  description = "The ARN of the created S3 bucket."
  value       = aws_s3_bucket.my_research_bucket.arn
}

output "research_bucket_regional_domain_name" {
  description = "The regional domain name of the created S3 bucket."
  value       = aws_s3_bucket.my_research_bucket.bucket_regional_domain_name
}