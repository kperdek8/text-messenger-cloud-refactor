output "load_balancer_dns_name" {
  description = "The DNS name of the Application Load Balancer"
  value       = aws_lb.app.dns_name
}

output "load_balancer_zone_id" {
  description = "Zone ID of the Application Load Balancer"
  value       = aws_lb.app.zone_id
}

output "target_groups" {
  value = aws_lb_target_group.tg
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