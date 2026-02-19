data "aws_region" "current" {}

resource "aws_vpc_endpoint" "sqs-ep" {
  ip_address_type     = "ipv4"
  private_dns_enabled = true
  security_group_ids  = [aws_security_group.sqs-sg.id]
  service_name        = "com.amazonaws.${data.aws_region.current.region}.sqs"
  subnet_ids          = [aws_subnet.billing-subnet-private1.id, aws_subnet.billing-subnet-private2.id]
  vpc_endpoint_type   = "Interface"
  vpc_id              = aws_vpc.billing-vpc.id
  dns_options {
    dns_record_ip_type = "ipv4"
  }
}

resource "aws_vpc_endpoint" "secret-ep" {
  ip_address_type     = "ipv4"
  private_dns_enabled = true
  security_group_ids  = [aws_security_group.secret-sg.id]
  service_name        = "com.amazonaws.${data.aws_region.current.region}.secretsmanager"
  subnet_ids          = [aws_subnet.billing-subnet-private1.id, aws_subnet.billing-subnet-private2.id]
  vpc_endpoint_type   = "Interface"
  vpc_id              = aws_vpc.billing-vpc.id
  dns_options {
    dns_record_ip_type = "ipv4"
  }
}