# Infrastructure Reusable Modules
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](./LICENSE)
[![Terraform & Trivy Scan](https://github.com/platform-crew/terraform-aws-modules/actions/workflows/terraform-trivy.yaml/badge.svg)](https://github.com/platform-crew/terraform-aws-modules/actions/workflows/terraform-trivy.yaml)

This repository contains reusable Terraform modules for provisioning AWS infrastructure components following best practices.

## Modules Overview

| Module | Description |
|--------|-------------|
| [EKS Cluster](/compute/eks-cluster) | Production-ready EKS cluster with ALB controller, autoscaler, and RBAC integration |
| [RDS PostgreSQL](/database/rds) | Managed PostgreSQL database with configurable security and maintenance settings |
| [Route Tables](/network/routetable) | Dynamic route table configuration for public/private subnets |
| [Subnets](/network/subnets) | Multi-AZ subnet provisioning with public/private configuration |
| [Client VPN](/network/vpn-client) | SSO-integrated AWS Client VPN endpoint with monitoring |
| [GitHub to ECR](/storage/ecr-git) | Secure image push from GitHub Actions to ECR using OIDC |
| [Static Website](/storage/s3-staticfiles) | CDN-fronted static hosting with GitHub Actions deployment |
| [Terraform Agent](/agents/tfc-agent) | Terraform agent to manage infrastructure in private networks |

## Getting Started

1. **Clone the repository**
   ```bash
   git clone https://github.com/platform-crew/terraform-aws-modules.git
   cd terraform-aws-modules
   ```

2. **Initialize Terraform**
   ```bash
   terraform init
   ```

3. **Use modules**
   ```hcl
   module "example" {
     source = "git::https://github.com/platform-crew/terraform-aws-modules.git//compute/eks-cluster"

     # Required variables...
   }
   ```

## Requirements

- Terraform >= 1.12.1
- AWS Provider >= 5.0
- AWS account with appropriate permissions

## Contributing

1. Fork the repository
2. Create a feature branch
3. Submit a pull request
