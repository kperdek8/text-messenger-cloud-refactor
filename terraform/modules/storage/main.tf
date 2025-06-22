resource "aws_s3_bucket" "app_bucket" {
  bucket = var.bucket_name
}

resource "aws_s3_object" "frontend_dockerrun" {
  bucket = aws_s3_bucket.app_bucket.id
  key    = "beanstalk/frontend/Dockerrun.aws.json"
  content = jsonencode({
    "AWSEBDockerrunVersion" = "1"
    "Image" = {
      "Name" = "733338247552.dkr.ecr.us-east-1.amazonaws.com/264127/app:latest"
      "Update" = "true"
    }
    "Ports" = [
      { "ContainerPort" = "4000" }
    ]
  })
}

resource "aws_s3_object" "backend_dockerrun" {
  bucket = aws_s3_bucket.app_bucket.id
  key    = "beanstalk/backend/Dockerrun.aws.json"
  content = jsonencode({
    "AWSEBDockerrunVersion" = "1"
    "Image" = {
      "Name"   = "733338247552.dkr.ecr.us-east-1.amazonaws.com/264127/server:latest"
      "Update" = "true"
    }
    "Ports" = [
      { "ContainerPort" = "4000" }
    ]
  })
}