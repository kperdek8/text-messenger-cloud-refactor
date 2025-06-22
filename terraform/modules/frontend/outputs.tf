output "endpoint" {
  value = aws_elastic_beanstalk_environment.frontend_env.cname
}