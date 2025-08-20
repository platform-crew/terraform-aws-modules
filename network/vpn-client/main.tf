# ======================
# SECURITY COMPONENTS
# ======================

resource "aws_security_group" "client_vpn_sg" {
  name        = "${var.environment}-client-vpn-sg"
  description = "Security group controlling inbound/outbound traffic for the Client VPN endpoint"
  vpc_id      = var.vpc_id

  # Work from anywhere
  ingress {
    description = "Allow inbound VPN client connections on TLS port"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # With the split tunnel, traffic should still route to the internet
  egress {
    description = "Allow outbound traffic internet"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [var.vpc_cidr_block]
  }

  tags = {
    Name        = "${var.environment}-client-vpn-sg"
    Environment = var.environment
    Category    = "vpn"
  }

  lifecycle {
    create_before_destroy = true
  }
}

# ======================
# AUTHENTICATION
# ======================

resource "aws_iam_saml_provider" "sso_provider" {
  name                   = "${var.environment}-aws-sso-provider"
  saml_metadata_document = var.sso_metadata

  tags = {
    Name        = "${var.environment}-aws-sso-provider"
    Environment = var.environment
    Category    = "vpn"
  }
}

# ======================
# VPN ENDPOINT
# ======================
# CloudWatch Log Group for VPN logs
# Ignoring AVD-AWS-0017: Using default AWS-managed encryption key instead of a CMK.
# Reason: Logs are forwarded to observability platform and using a CMK is unnecessary
# tfsec:ignore:AVD-AWS-0017
resource "aws_cloudwatch_log_group" "vpn_logs" {
  name              = "/aws/client-vpn/${var.environment}"
  retention_in_days = var.log_retention_days

  tags = {
    Name        = "${var.environment}-vpn-log-group"
    Environment = var.environment
    Category    = "vpn"
  }
}

# CloudWatch Log Stream for connection logs
resource "aws_cloudwatch_log_stream" "vpn_connection_logs" {
  name           = "connection-logs"
  log_group_name = aws_cloudwatch_log_group.vpn_logs.name
}

# Enable VPN logging
resource "aws_ec2_client_vpn_endpoint" "client_vpn" {
  description            = "AWS Client VPN endpoint for the ${var.environment} environment"
  server_certificate_arn = var.server_certificate_arn
  client_cidr_block      = var.client_cidr_block
  vpc_id                 = var.vpc_id
  security_group_ids     = [aws_security_group.client_vpn_sg.id]
  split_tunnel           = true
  dns_servers            = var.dns_servers

  authentication_options {
    type              = "federated-authentication"
    saml_provider_arn = aws_iam_saml_provider.sso_provider.arn
  }

  connection_log_options {
    enabled               = true
    cloudwatch_log_group  = aws_cloudwatch_log_group.vpn_logs.name
    cloudwatch_log_stream = aws_cloudwatch_log_stream.vpn_connection_logs.name
  }

  tags = {
    Name        = "${var.environment}-client-vpn-endpoint"
    Environment = var.environment
    Category    = "vpn"
  }
}

# ======================
# ACCESS CONTROL RULES
# ======================

resource "aws_ec2_client_vpn_authorization_rule" "group_access" {
  for_each = {
    for rule in var.sso_group_access_rules :
    "${rule.group_id}_${replace(rule.target_cidr, "/", "_")}" => rule
  }

  client_vpn_endpoint_id = aws_ec2_client_vpn_endpoint.client_vpn.id
  target_network_cidr    = each.value.target_cidr
  access_group_id        = each.value.group_id
  description            = each.value.description

  lifecycle {
    create_before_destroy = true
  }
}

# ======================
# NETWORK ASSOCIATIONS
# ======================

resource "aws_ec2_client_vpn_network_association" "private_subnets" {
  count = length(var.private_subnet_ids)

  client_vpn_endpoint_id = aws_ec2_client_vpn_endpoint.client_vpn.id
  subnet_id              = var.private_subnet_ids[count.index]

  lifecycle {
    create_before_destroy = true
  }
}
