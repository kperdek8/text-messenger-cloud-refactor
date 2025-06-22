output "frontend_endpoint" {
  value = module.frontend.endpoint
}

output "backend_endpoint" {
  value = module.backend.endpoint
}

output "database_url" {
  value = module.database.endpoint
}