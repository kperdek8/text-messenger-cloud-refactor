resource "aws_db_instance" "db" {
  identifier             = var.db_identifier
  engine                 = "postgres"
  engine_version         = "17.4"
  instance_class         = "db.t3.micro"
  allocated_storage      = 20
  username               = var.db_username
  password               = var.db_password
  db_name                = var.db_name
  vpc_security_group_ids = [var.security_group_id]
  skip_final_snapshot    = true
}