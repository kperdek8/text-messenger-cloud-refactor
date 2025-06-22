resource "aws_elastic_beanstalk_application" "backend" {
  name        = "backend-app"
  description = "Chat application backend"
}
resource "aws_elastic_beanstalk_application_version" "backend_version" {
  name        = "backend-v1"
  application = aws_elastic_beanstalk_application.backend.name
  bucket      = var.app_bucket_id
  key         = var.backend_key
}
resource "aws_elastic_beanstalk_environment" "backend_env" {
  name                = "backend-app-env"
  application         = aws_elastic_beanstalk_application.backend.name
  solution_stack_name = "64bit Amazon Linux 2023 v4.4.4 running Docker"
  version_label       = aws_elastic_beanstalk_application_version.backend_version.name
  setting {
    namespace = "aws:elasticbeanstalk:environment"
    name      = "EnvironmentType"
    value     = "SingleInstance"
  }
  setting {
    namespace = "aws:autoscaling:launchconfiguration"
    name      = "SecurityGroups"
    value     = var.security_group_name
  }
  setting {
    namespace = "aws:autoscaling:launchconfiguration"
    name      = "IamInstanceProfile"
    value     = "LabInstanceProfile"
  }
  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "DATABASE_URL"
    value     = "ecto://${var.db_username}:${var.db_password}@${var.db_endpoint}:${var.db_port}/${var.db_name}"
  }
  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "AWS_USER_POOL_ID"
    value     = var.user_pool_id
  }
  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "AWS_COGNITO_CLIENT_ID"
    value     = var.user_pool_client_id
  }
  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "AWS_ACCESS_KEY_ID"
    value     = var.aws_access_key_id
  }
  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "AWS_SECRET_ACCESS_KEY"
    value     = var.aws_secret_access_key
  }
  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "AWS_SESSION_TOKEN"
    value     = var.aws_session_token
  }
  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "AWS_REGION"
    value     = var.aws_region
  }
}