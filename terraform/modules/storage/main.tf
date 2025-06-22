resource "aws_s3_bucket" "app-bucket" {
  bucket = var.bucket_name
}