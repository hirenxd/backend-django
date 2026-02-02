resource "random_password" "db" {
  length  = 16
  special = true
}

resource "aws_secretsmanager_secret" "db_secret" {
  name = "${var.env}-db-password"
}

resource "aws_secretsmanager_secret_version" "db_secret_version" {
  secret_id     = aws_secretsmanager_secret.db_secret.id
  secret_string = random_password.db.result
}

resource "aws_db_subnet_group" "db_subnet_group" {
  name       = "${var.env}-db-subnet-group"
  subnet_ids = var.private_subnet_ids
}

resource "aws_db_instance" "postgres" {
  identifier             = "${var.env}-postgres"
  engine                 = "postgres"
  engine_version         = "15"
  instance_class         = var.db_instance_class
  allocated_storage      = 20
  username               = var.db_username
  password               = random_password.db.result
  db_subnet_group_name   = aws_db_subnet_group.db_subnet_group.name
  vpc_security_group_ids = [var.db_sg_id]
  skip_final_snapshot    = true
  publicly_accessible    = false
  multi_az               = false
}
