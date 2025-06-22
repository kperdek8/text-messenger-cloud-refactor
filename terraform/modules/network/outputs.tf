output "vpc_id" {
  value = data.aws_vpc.main.id
}

output "subnet_ids" {
  value = data.aws_subnets.main.ids
}

output "backend_security_group_id" {
  value = aws_security_group.backend_sg.id
}

output "db_security_group_id" {
  value = aws_security_group.db_sg.id
}