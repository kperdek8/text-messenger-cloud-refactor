output "endpoint" {
  value = aws_db_instance.db.address
}

output "port" {
  value = aws_db_instance.db.port
}

output "username" {
  value = aws_db_instance.db.username
  sensitive = true
}

output "password" {
  value = aws_db_instance.db.password
  sensitive = true
}

output "db_name" {
  value = aws_db_instance.db.db_name
}

