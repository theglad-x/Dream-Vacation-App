resource "aws_security_group" "postgres-sg" {
  name        = "rds-postgresdb-sg"
  description = "Allow TLS inbound traffic and all outbound traffic"
  vpc_id      = aws_vpc.vpc.id

  tags = {
    Name = "postgres-db-sg"
  }
}

resource "aws_vpc_security_group_ingress_rule" "postgresdb-ipv4" {
  security_group_id = aws_security_group.postgres-sg.id
  cidr_ipv4         = aws_vpc.vpc.cidr_block
  from_port         = 5432
  ip_protocol       = "tcp"
  to_port           = 5432
}

resource "aws_vpc_security_group_egress_rule" "postgres-allow-all-traffic-ipv4" {
  security_group_id = aws_security_group.postgres-sg.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}


# Set up RDS with Variables
resource "aws_db_instance" "postgresdb-instance" {
  allocated_storage      = 10
  storage_type           = "gp2"
  engine                 = "postgres"
  engine_version         = "16.3"
  instance_class         = "db.t3.micro"
  identifier             = var.postgres_identifier
  db_name                = var.postgres_db_name
  username               = var.postgres_db_user_name
  password               = var.postgres_db_password
  publicly_accessible    = true
  parameter_group_name   = "default.postgres16"
  vpc_security_group_ids = [aws_security_group.postgres-sg.id]
  skip_final_snapshot    = true


  db_subnet_group_name = aws_db_subnet_group.postgres_subnet_group.name

  backup_retention_period = 0
  multi_az                = false

}

resource "aws_db_subnet_group" "postgres_subnet_group" {
  name = "postgres-subnet-group"

  subnet_ids = [aws_subnet.public-us-east-1a.id, aws_subnet.public-us-east-1b.id]

  tags = {
    Name = "rds postgres subnet group"
  }
}
