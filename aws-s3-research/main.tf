resource "random_string" "bucket_suffix" {
  length  = 8
  special = false
  upper   = false
}

resource "aws_s3_bucket" "my_research_bucket" {
  bucket = "tf-research-bucket-sriede-${random_string.bucket_suffix.result}"

  tags = {
    Name        = "My Terraform Research Bucket"
    Environment = "Sandbox"
  }
}