output "bucket_id" {
  value = aws_s3_bucket.app_bucket.id
}

output "frontend_key" {
  value = aws_s3_object.frontend_dockerrun.key
}

output "backend_key" {
  value = aws_s3_object.backend_dockerrun.key
}