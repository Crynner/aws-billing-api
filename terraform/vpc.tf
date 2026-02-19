resource "aws_vpc" "billing-vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
}

resource "aws_subnet" "billing-subnet-private1" {
  cidr_block = "10.0.128.0/20"
  vpc_id     = aws_vpc.billing-vpc.id
}

resource "aws_subnet" "billing-subnet-private2" {
  cidr_block = "10.0.144.0/20"
  vpc_id     = aws_vpc.billing-vpc.id
}

resource "aws_route_table" "billing-rtb-private2" {
  vpc_id = aws_vpc.billing-vpc.id
}

resource "aws_route_table_association" "billing-rtba-private2" {
  subnet_id      = aws_subnet.billing-subnet-private2.id
  route_table_id = aws_route_table.billing-rtb-private2.id
}

resource "aws_route_table" "billing-rtb-private1" {
  vpc_id = aws_vpc.billing-vpc.id
}

resource "aws_route_table_association" "billing-rtba-private1" {
  subnet_id      = aws_subnet.billing-subnet-private1.id
  route_table_id = aws_route_table.billing-rtb-private1.id
}


resource "aws_security_group" "lambda-sg" {
  description = "Lambda Access to SQS, Secrets Manager, RDS"
  name        = "lambda-sg"
  vpc_id      = aws_vpc.billing-vpc.id
}

resource "aws_security_group" "rds-sg" {
  description = "Allows RDS Access"
  name        = "rds-sg"
  vpc_id      = aws_vpc.billing-vpc.id
}

resource "aws_security_group" "sqs-sg" {
  description = "SQS for I/O Lambda interaction"
  name        = "sqs-sg"
  vpc_id      = aws_vpc.billing-vpc.id
}

resource "aws_security_group" "secret-sg" {
  description = "Allows Secrets Manager access"
  name        = "secret-sg"
  vpc_id      = aws_vpc.billing-vpc.id
}

resource "aws_vpc_security_group_ingress_rule" "secret_in_lambda" {
  security_group_id            = aws_security_group.secret-sg.id
  description                  = "Allows access from Lambda to Secrets Manager"
  referenced_security_group_id = aws_security_group.lambda-sg.id
  from_port                    = 443
  to_port                      = 443
  ip_protocol                  = "tcp"
}

resource "aws_vpc_security_group_ingress_rule" "sqs_in_lambda" {
  security_group_id            = aws_security_group.sqs-sg.id
  description                  = "Allows access from Lambda to SQS"
  referenced_security_group_id = aws_security_group.lambda-sg.id
  from_port                    = 443
  to_port                      = 443
  ip_protocol                  = "tcp"
}

resource "aws_vpc_security_group_egress_rule" "sqs_out_lambda" {
  security_group_id            = aws_security_group.sqs-sg.id
  description                  = "Allows access for SQS to trigger Lambda"
  referenced_security_group_id = aws_security_group.lambda-sg.id
  from_port                    = 443
  to_port                      = 443
  ip_protocol                  = "tcp"
}

resource "aws_vpc_security_group_ingress_rule" "rds_in_lambda" {
  security_group_id            = aws_security_group.rds-sg.id
  description                  = "Allows RDS to intake Lambda"
  referenced_security_group_id = aws_security_group.lambda-sg.id
  from_port                    = 5432
  to_port                      = 5432
  ip_protocol                  = "tcp"
}

resource "aws_vpc_security_group_egress_rule" "lambda_out_sqs" {
  security_group_id            = aws_security_group.lambda-sg.id
  description                  = "Allows access Lambda to SQS"
  referenced_security_group_id = aws_security_group.sqs-sg.id
  from_port                    = 443
  to_port                      = 443
  ip_protocol                  = "tcp"
}

resource "aws_vpc_security_group_egress_rule" "lambda_out_secret" {
  security_group_id            = aws_security_group.lambda-sg.id
  description                  = "Allows access Lambda to Secrets Manager"
  referenced_security_group_id = aws_security_group.secret-sg.id
  from_port                    = 443
  to_port                      = 443
  ip_protocol                  = "tcp"
}

resource "aws_vpc_security_group_egress_rule" "lambda_out_rds" {
  security_group_id            = aws_security_group.lambda-sg.id
  description                  = "Allows access Lambda to RDS"
  referenced_security_group_id = aws_security_group.rds-sg.id
  from_port                    = 5432
  to_port                      = 5432
  ip_protocol                  = "tcp"
}