# AWS Client VPN Terraform Module

This Terraform module provisions an **AWS Client VPN** endpoint with integrated support for:

- IAM SAML (SSO) authentication
- Fine-grained access control using group-based authorization rules
- Logging and monitoring to Amazon CloudWatch
- Secure network configuration using Security Groups
- High availability through subnet associations across multiple AZs

---

## 📦 Components Deployed

| Component                          | Description                                                                 |
|------------------------------------|-----------------------------------------------------------------------------|
| `aws_security_group.client_vpn_sg` | Controls inbound/outbound VPN traffic                                      |
| `aws_iam_saml_provider.sso_provider` | Sets up SAML provider for federated SSO authentication                    |
| `aws_cloudwatch_log_group.vpn_logs` | Stores VPN connection logs                                                 |
| `aws_cloudwatch_log_stream.vpn_connection_logs` | Dedicated log stream for connection logs                          |
| `aws_ec2_client_vpn_endpoint.client_vpn` | Main Client VPN endpoint                                                   |
| `aws_ec2_client_vpn_authorization_rule.group_access` | Grants CIDR access to SSO groups                                  |
| `aws_ec2_client_vpn_network_association.private_subnets` | Associates the VPN with private subnets for access               |

---

## 🚀 Usage

```hcl
module "client_vpn" {
  source = "./path-to-module"

  environment              = "prod"
  vpc_id                   = "vpc-abc123"
  sg_allowed_egress_cidr   = "10.0.0.0/8"
  private_subnet_ids       = ["subnet-1111", "subnet-2222"]
  client_cidr_block        = "10.2.0.0/16"
  server_certificate_arn   = "arn:aws:acm:region:account:certificate/xxx"
  sso_metadata_file_path   = "sso_metadata.xml"
  sso_group_access_rules = [
    {
      group_id    = "GROUP-ID-1"
      target_cidr = "10.10.0.0/16"
      description = "Access to shared services"
    },
    {
      group_id    = "GROUP-ID-2"
      target_cidr = "10.20.0.0/16"
    }
  ]
  log_retention_days = 14
  logs_kms_key_arn   = "arn:aws:kms:region:account:key/xxx"
}
```
## 🔐 Inputs

| Name                     | Type           | Description                                            | Required        |
| ------------------------ | -------------- | ------------------------------------------------------ | --------------- |
| `environment`            | `string`       | Environment name (e.g., dev, prod)                     | ✅               |
| `vpc_id`                 | `string`       | ID of the VPC where the VPN is deployed                | ✅               |
| `sg_allowed_egress_cidr` | `string`       | CIDR allowed in SG egress (e.g., internal IP ranges)   | ✅               |
| `private_subnet_ids`     | `list(string)` | List of subnet IDs for VPN network association         | ✅               |
| `client_cidr_block`      | `string`       | CIDR block for VPN clients (must not overlap with VPC) | ✅               |
| `server_certificate_arn` | `string`       | ACM certificate ARN used by the VPN                    | ✅               |
| `sso_metadata_file_path` | `string`       | File path to SSO metadata XML file                     | ✅               |
| `sso_group_access_rules` | `list(object)` | List of SSO group access rules                         | ✅               |
| `log_retention_days`     | `number`       | CloudWatch log retention in days                       | ❌ (Default: 30) |
| `logs_kms_key_arn`       | `string`       | KMS key ARN for encrypting logs                        | ❌               |

## 📤 Outputs
| Name                    | Description                          |
| ----------------------- | ------------------------------------ |
| `vpn_endpoint_dns_name` | DNS name of the created VPN endpoint |

## License
This module is open-sourced under the MIT License.
