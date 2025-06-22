module "network" {
  source = "./modules/network"
}

module "storage" {
  source = "./modules/storage"
}

module "cognito" {
  source = "./modules/cognito"
}

module "user_events_queue" {
  source = "./modules/sqs"
  name   = "user_events"
}

module "database" {
  source            = "./modules/database"
  db_name           = var.global_db_name
  db_username       = var.global_db_username
  db_password       = var.global_db_password
  security_group_id = module.network.db_security_group_id
}

module "backend" {
  source                = "./modules/backend"
  app_bucket_id         = module.storage.bucket_id
  backend_key           = module.storage.backend_key
  db_endpoint           = module.database.endpoint
  db_port               = module.database.port
  security_group_name   = module.network.backend_security_group_name
  user_pool_id          = module.cognito.user_pool_id
  user_pool_client_id   = module.cognito.user_pool_client_id
  db_username           = var.global_db_username
  db_password           = var.global_db_password
  db_name               = var.global_db_name
  aws_region            = var.aws_region
  aws_access_key_id     = var.aws_access_key_id
  aws_secret_access_key = var.aws_secret_access_key
  aws_session_token     = var.aws_session_token
}

module "frontend" {
  source        = "./modules/frontend"
  app_bucket_id = module.storage.bucket_id
  frontend_key  = module.storage.frontend_key
  backend_url   = module.backend.endpoint
}