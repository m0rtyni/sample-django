####################
# DB Subnet Group  #
####################

resource "aws_db_subnet_group" "main" {
  name = "django-db-subnet-group"

  subnet_ids = [
    aws_subnet.private_a.id,
    aws_subnet.private_b.id
  ]

  tags = {
    Name = "django-db-subnet-group"
  }
}

##################
# PostgreSQL RDS #
##################

resource "aws_db_instance" "postgres" {
  identifier = "django-postgres"

  engine         = "postgres"
  instance_class = var.db_instance_class

  allocated_storage = var.db_allocated_storage

  db_name  = var.db_name
  username = var.db_username
  password = var.db_password
  port     = var.db_port

  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.rds.id]

  publicly_accessible = false
  skip_final_snapshot = true

  tags = {
    Name = "django-postgres"
  }
}

