resource "aws_db_instance" "billing-db" {
  allocated_storage           = 20
  backup_retention_period     = 1
  backup_window               = "04:04-04:34"
  ca_cert_identifier          = "rds-ca-rsa2048-g1"
  db_subnet_group_name        = aws_db_subnet_group.billing-subnet-group.name
  engine                      = "postgres"
  engine_lifecycle_support    = "open-source-rds-extended-support-disabled"
  engine_version              = "17.6"
  identifier                  = "billing-db"
  instance_class              = "db.t4g.micro"
  license_model               = "postgresql-license"
  maintenance_window          = "thu:06:49-thu:07:19"
  manage_master_user_password = true
  max_allocated_storage       = 1000
  network_type                = "IPV4"
  option_group_name           = "default:postgres-17"
  parameter_group_name        = "default.postgres17"
  port                        = 5432
  skip_final_snapshot         = true
  storage_encrypted           = true
  storage_type                = "gp2"
  username                    = "postgres"
  vpc_security_group_ids      = [aws_security_group.rds-sg.id]
}

resource "aws_db_subnet_group" "billing-subnet-group" {
  name        = "billing-subnet-group"
  subnet_ids  = [aws_subnet.billing-subnet-private1.id, aws_subnet.billing-subnet-private2.id]
}
