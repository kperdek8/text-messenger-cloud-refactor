output "backend_security_group_id" {
  value = aws_security_group.backend_sg.id
}

output "db_security_group_id" {
  value = aws_security_group.db_sg.id
}