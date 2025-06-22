output "ecs_cluster_id" {
  value = aws_ecs_cluster.cluster.id
}

output "load_balancer_dns_name" {
  description = "The DNS name of the Application Load Balancer"
  value       = aws_lb.app.dns_name
}

output "auth_service_url" {
  value = "http://${aws_lb.app.dns_name}/api/auth/"
}

output "user_service_url" {
  value = "http://${aws_lb.app.dns_name}/api/users/"
}

output "chat_service_url" {
  value = "http://${aws_lb.app.dns_name}/api/chats/"
}