# AWS Client VPN Terraform Module

## Overview
This Terraform module deploys a complete AWS Client VPN solution with integrated SSO authentication, network access controls, and monitoring capabilities.

## Features
- **SSO Integration**: Federated authentication with SAML 2.0
- **High Availability**: Multi-subnet deployment across AZs
- **Security**: TLS encryption, security groups, and network access controls
- **Monitoring**: CloudWatch logging with configurable retention
- **Access Control**: Granular authorization by SSO groups
- **Split Tunneling**: Optimized network traffic routing

## Requirements
- Terraform >= 1.12.1
- AWS Provider >= 5.0
- Existing VPC with private subnets
- ACM certificate for VPN endpoint
- SAML metadata from identity provider

## Usage
```hcl
module "client_vpn" {
  source = "./path/to/module"

  environment        = "production"
  vpc_id            = "vpc-12345678"
  vpc_cidr_block    = "10.0.0.0/16"
  private_subnet_ids = ["subnet-123456", "subnet-234567"]

  client_cidr_block      = "10.2.0.0/16"
  server_certificate_arn = "arn:aws:acm:us-east-1:123456789012:certificate/abcd1234"
  sso_metadata           = file("sso_metadata.xml")
  dns_servers           = ["10.0.0.2", "8.8.8.8"]

  sso_group_access_rules = [
    {
      group_id    = "dev-group-id"
      target_cidr = "10.0.1.0/24"
      description = "Developer access to app servers"
    },
    {
      group_id    = "admin-group-id"
      target_cidr = "10.0.0.0/16"
    }
  ]

  log_retention_days = 90
  logs_kms_key_arn   = "arn:aws:kms:us-east-1:123456789012:key/abcd1234"
}
```

## Input Variables

### Core Configuration
| Name | Description | Type | Required |
|------|-------------|------|----------|
| environment | Deployment environment | string | Yes |
| vpc_id | Target VPC ID | string | Yes |
| vpc_cidr_block | VPC CIDR range | string | Yes |
| private_subnet_ids | Subnets for VPN HA | list(string) | Yes |
| client_cidr_block | VPN client IP range | string | Yes |
| server_certificate_arn | ACM cert ARN | string | Yes |
| sso_metadata | SAML metadata XML | string | Yes |
| dns_servers | DNS servers for clients | list(string) | Yes |

### Access Control
| Name | Description | Type | Default |
|------|-------------|------|---------|
| sso_group_access_rules | SSO group access rules | list(object) | [] |

### Monitoring
| Name | Description | Type | Default |
|------|-------------|------|---------|
| log_retention_days | CloudWatch log retention | number | 30 |
| logs_kms_key_arn | KMS key for log encryption | string | "" |

## Outputs
| Name | Description |
|------|-------------|
| vpn_endpoint_dns_name | DNS name for VPN connection |
| client_vpn_sg_id | VPN security group ID |

## Module Components

### 1. Security
- **Security Group**: Restricted access on port 443 (TLS)
- **IAM SAML Provider**: SSO integration setup
- **Access Rules**: Granular network access by SSO groups

### 2. Networking
- **VPN Endpoint**: Client VPN service endpoint
- **Subnet Associations**: HA across multiple private subnets
- **Split Tunnel**: Optimized routing configuration

### 3. Monitoring
- **CloudWatch Logs**: Connection logging
- **KMS Encryption**: Optional log encryption
- **Log Streams**: Dedicated connection log stream

## Best Practices
1. Use separate CIDR ranges for VPN clients and VPC resources
2. Implement least-privilege access with SSO group rules
3. Enable log encryption for sensitive environments
4. Monitor connection logs for security events
5. Regularly rotate server certificates
6. Use DNS servers that can resolve internal resources

## Maintenance
To update VPN configuration:
1. Modify the Terraform variables
2. Preview changes:
   ```bash
   terraform plan
   ```
3. Apply changes:
   ```bash
   terraform apply
   ```

Note: Some changes may cause temporary VPN disconnections.

## Cleanup
To decommission the VPN:
```bash
terraform destroy
```
