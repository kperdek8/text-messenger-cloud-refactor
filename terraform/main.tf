module "network" {
  source = "./modules/network"
}

module "storage" {
  source      = "./modules/storage"
  bucket_name = "264127-app"
}

module "cognito" {
  source = "./modules/cognito"
}

module "chat_db" {
  source = "./modules/database"
  db_identifier		= "chat-service-db"
  db_name           = "chat_service"
  db_username       = var.global_db_username
  db_password       = var.global_db_password
  security_group_id = module.network.db_security_group_id
}

module "notification_db" {
  source = "./modules/dynamodb"
  table_name		= "notification-log"
}

module "notification_sns_topic" {
  source = "./modules/notifications"
  notification_topic = "email-notifications"
  notification_endpoint = "264127@student.pwr.edu.pl"
}

module "user_db" {
  source = "./modules/database"
  db_identifier		= "user-service-db"
  db_name           = "user_service"
  db_username       = var.global_db_username
  db_password       = var.global_db_password
  security_group_id = module.network.db_security_group_id
}

module "user_registered_queue" {
  source = "./modules/sqs"

  name = "user_registered_queue"
}

module "user_added_queue" {
  source = "./modules/sqs"

  name = "user_added_queue"
}

module "chat_created_queue" {
  source = "./modules/sqs"

  name = "chat_created_queue"
}

module "load_balancer" {
  source = "./modules/load-balancer"
  
  security_group = module.network.backend_security_group_id
}

module "lambda" {
  source = "./modules/lambda"

  execution_role_arn = "arn:aws:iam::733338247552:role/LabRole"

  vpc_subnet_ids         = module.network.subnet_ids
  vpc_security_group_ids = [module.network.backend_security_group_id]

  lambda_functions = [
    {
      name     = "GetChat"
      route    = "/api/chats/{id}"
      method   = "GET"
      handler  = "index.handler"
      runtime  = "nodejs18.x"
      zip_path = "${path.module}/modules/lambda/src/GetChat.zip"
      env_vars = {
        DB_HOST = module.chat_db.endpoint
        DB_NAME = module.chat_db.db_name
        DB_USER = var.global_db_username
        DB_PASSWORD = var.global_db_password
      }
    },
    {
      name     = "GetChats"
      route    = "/api/chats"
      method   = "GET"
      handler  = "index.handler"
      runtime  = "nodejs18.x"
      zip_path = "${path.module}/modules/lambda/src/GetChats.zip"
      env_vars = {
        DB_HOST = module.chat_db.endpoint
        DB_NAME = module.chat_db.db_name
        DB_USER = var.global_db_username
        DB_PASSWORD = var.global_db_password
      }
    },
    {
      name     = "CreateChat"
      route    = "/api/chats"
      method   = "POST"
      handler  = "index.handler"
      runtime  = "nodejs18.x"
      zip_path = "${path.module}/modules/lambda/src/CreateChat.zip"
      env_vars = {
        SQS_URL = module.chat_created_queue.queue_url
        DB_HOST = module.chat_db.endpoint
        DB_NAME = module.chat_db.db_name
        DB_USER = var.global_db_username
        DB_PASSWORD = var.global_db_password
      }
    },
    {
      name     = "GetChatMembers"
      route    = "/api/chats/{id}/users"
      method   = "GET"
      handler  = "index.handler"
      runtime  = "nodejs18.x"
      zip_path = "${path.module}/modules/lambda/src/GetChatMembers.zip"
      env_vars = {
        DB_HOST = module.chat_db.endpoint
        DB_NAME = module.chat_db.db_name
        DB_USER = var.global_db_username
        DB_PASSWORD = var.global_db_password
      }
    },
    {
      name     = "GetChatMessages"
      route    = "/api/chats/{id}/messages"
      method   = "GET"
      handler  = "index.handler"
      runtime  = "nodejs18.x"
      zip_path = "${path.module}/modules/lambda/src/GetChatMessages.zip"
      env_vars = {
        DB_HOST     = module.chat_db.endpoint
        DB_NAME     = module.chat_db.db_name
        DB_USER     = var.global_db_username
        DB_PASSWORD = var.global_db_password
      }
    }
  ]
}

module "api_gateway" {
  source = "./modules/api-gateway"

  alb_dns_name = module.load_balancer.load_balancer_dns_name
  cognito_app_client_id = module.cognito.user_pool_client_id
  cognito_user_pool_id = module.cognito.user_pool_id
  region = var.aws_region

  routes = module.lambda.lambda_routes
}

module "fargate" {
  source = "./modules/fargate"

  cluster_name   = "text-messenger"
  region         = var.aws_region
  security_group = module.network.backend_security_group_id

  apigw_dns_name = module.api_gateway.apigw_domain_name
  lb_dns_name    = module.load_balancer.load_balancer_dns_name
  target_groups = module.load_balancer.target_groups

  execution_role_arn = "arn:aws:iam::733338247552:role/LabRole"

  services = [
    {
      name           = "frontend"
      container_port = 8888
      image          = "733338247552.dkr.ecr.us-east-1.amazonaws.com/264127/frontend:latest"
	  count			 = 2
      env_vars = [
	  	{ name = "PHX_SERVER", value = "true"},
	  	{ name = "PORT", value = "8888"}
	  ]
	},
    {
      name           = "auth-service"
      container_port = 4000
      image          = "733338247552.dkr.ecr.us-east-1.amazonaws.com/264127/auth-service:latest"
	  count			 = 2
      env_vars = [
        { name = "MIX_ENV", value = "prod"},
        { name = "PHX_SERVER", value = "true"},
        { name = "PORT", value = "4000"},
        { name = "AWS_ACCESS_KEY_ID", value = var.aws_access_key_id},
        { name = "AWS_SECRET_ACCESS_KEY", value = var.aws_secret_access_key},
        { name = "AWS_SESSION_TOKEN", value = var.aws_session_token},
        { name = "AWS_REGION", value = var.aws_region},
        { name = "AWS_USER_POOL_ID", value = module.cognito.user_pool_id},
        { name = "AWS_COGNITO_CLIENT_ID", value = module.cognito.user_pool_client_id},
        { name = "AWS_SQS_QUEUE_URL", value = module.user_registered_queue.queue_url}
      ]
    },
    {
      name           = "user-service"
      container_port = 4001
      image          = "733338247552.dkr.ecr.us-east-1.amazonaws.com/264127/user-service:latest"
	  count			 = 2
      env_vars = [
        { name = "MIX_ENV", value = "prod"},
        { name = "PHX_SERVER", value = "true"},
        { name = "PORT", value = "4001"},
        { name = "AWS_ACCESS_KEY_ID", value = var.aws_access_key_id},
        { name = "AWS_SECRET_ACCESS_KEY", value = var.aws_secret_access_key},
        { name = "AWS_SESSION_TOKEN", value = var.aws_session_token},
        { name = "AWS_REGION", value = var.aws_region},
        { name = "AWS_USER_POOL_ID", value = module.cognito.user_pool_id},
        { name = "AWS_COGNITO_CLIENT_ID", value = module.cognito.user_pool_client_id},
        { name = "AWS_SQS_QUEUE_URL", value = module.user_registered_queue.queue_url},
        { name = "DATABASE_URL", value = "ecto://${module.user_db.username}:${module.user_db.password}@${module.user_db.endpoint}:${module.user_db.port}/${module.user_db.db_name}"},
      ]
    },
	{
      name           = "ws-service"
      container_port = 4002
      image          = "733338247552.dkr.ecr.us-east-1.amazonaws.com/264127/ws-service:latest"
	  count			 = 1
      env_vars = [
        { name = "MIX_ENV", value = "prod" },
        { name = "PHX_SERVER", value = "true"},
        { name = "PORT", value = "4002"},	
        { name = "AWS_ACCESS_KEY_ID", value = var.aws_access_key_id},
        { name = "AWS_SECRET_ACCESS_KEY", value = var.aws_secret_access_key},
        { name = "AWS_SESSION_TOKEN", value = var.aws_session_token},
        { name = "AWS_REGION", value = var.aws_region},
        { name = "AWS_USER_POOL_ID", value = module.cognito.user_pool_id},
        { name = "AWS_COGNITO_CLIENT_ID", value = module.cognito.user_pool_client_id},
        { name = "AWS_SQS_USER_ADDED_QUEUE_URL", value = module.user_added_queue.queue_url},
		{ name = "AWS_SQS_CHAT_CREATED_QUEUE_URL", value = module.chat_created_queue.queue_url},
        { name = "DATABASE_URL", value = "ecto://${module.chat_db.username}:${module.chat_db.password}@${module.chat_db.endpoint}:${module.chat_db.port}/${module.chat_db.db_name}"},
      ]
    },
	{
      name           = "file-service"
      container_port = 4003
      image          = "733338247552.dkr.ecr.us-east-1.amazonaws.com/264127/file-service:latest"
	  count			 = 2
      env_vars = [
        { name = "MIX_ENV", value = "prod" },
        { name = "PHX_SERVER", value = "true"},
        { name = "PORT", value = "4003"},	
        { name = "AWS_ACCESS_KEY_ID", value = var.aws_access_key_id},
        { name = "AWS_SECRET_ACCESS_KEY", value = var.aws_secret_access_key},
        { name = "AWS_SESSION_TOKEN", value = var.aws_session_token},
        { name = "AWS_REGION", value = var.aws_region},
        { name = "AWS_USER_POOL_ID", value = module.cognito.user_pool_id},
        { name = "AWS_COGNITO_CLIENT_ID", value = module.cognito.user_pool_client_id},
        { name = "AWS_BUCKET", value = module.storage.bucket_name}
      ]
    },
	{
      name           = "notification-service"
      container_port = 4004
      image          = "733338247552.dkr.ecr.us-east-1.amazonaws.com/264127/notification-service:latest"
	  count			 = 2
      env_vars = [
        { name = "MIX_ENV", value = "prod" },
        { name = "PHX_SERVER", value = "true"},
        { name = "PORT", value = "4004"},	
        { name = "AWS_ACCESS_KEY_ID", value = var.aws_access_key_id},
        { name = "AWS_SECRET_ACCESS_KEY", value = var.aws_secret_access_key},
        { name = "AWS_SESSION_TOKEN", value = var.aws_session_token},
        { name = "AWS_REGION", value = var.aws_region},
        { name = "AWS_SQS_QUEUE_URL", value = module.user_added_queue.queue_url},
        { name = "NOTIFICATION_LOG_TABLE", value = module.notification_db.notification_log_table},
        { name = "SNS_EMAIL_TOPIC_ARN", value = module.notification_sns_topic.sns_topic_arn},
      ]
    }
  ]
}
