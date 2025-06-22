resource "aws_elastic_beanstalk_application" "frontend" {
  name        = "frontend-app"
  description = "Chat application frontend"
}

resource "aws_elastic_beanstalk_application_version" "frontend_version" {
  name        = "frontend-v1"
  application = aws_elastic_beanstalk_application.frontend.name
  bucket      = var.app_bucket_id
  key         = var.frontend_key
}

resource "aws_elastic_beanstalk_environment" "frontend_env" {
  name                = "frontend-app-env"
  application         = aws_elastic_beanstalk_application.frontend.name
  solution_stack_name = "64bit Amazon Linux 2023 v4.4.4 running Docker"
  version_label       = aws_elastic_beanstalk_application_version.frontend_version.name

  setting {
    namespace = "aws:elasticbeanstalk:environment"
    name      = "EnvironmentType"
    value     = "SingleInstance"
  }
  setting {
    namespace = "aws:autoscaling:launchconfiguration"
    name      = "IamInstanceProfile"
    value     = "LabInstanceProfile"
  }
  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "API_URL"
    value     = "http://${var.backend_url}/api"
  }
  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "SOCKET_URL"
    value     = "ws://${var.backend_url}/socket/websocket"
  }
}