output "vpn_endpoint_dns_name" {
  value = aws_ec2_client_vpn_endpoint.client_vpn.dns_name
}

output "client_vpn_sg_id" {
  description = "Security group ID for the Client VPN endpoint"
  value       = aws_security_group.client_vpn_sg.id
}
