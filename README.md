# Infrastructure Reusable Modules
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](./LICENSE)

This repository contains reusable Terraform modules for provisioning AWS infrastructure components following best practices.

## Modules Overview

| Module | Description |
|--------|-------------|
| [EKS Cluster](/modules/eks-cluster) | Production-ready EKS cluster with ALB controller, autoscaler, and RBAC integration |
| [RDS PostgreSQL](/modules/rds-postgresql) | Managed PostgreSQL database with configurable security and maintenance settings |
| [Route Tables](/modules/route-tables) | Dynamic route table configuration for public/private subnets |
| [Subnets](/modules/subnets) | Multi-AZ subnet provisioning with public/private configuration |
| [Client VPN](/modules/client-vpn) | SSO-integrated AWS Client VPN endpoint with monitoring |
| [GitHub to ECR](/modules/github-ecr) | Secure image push from GitHub Actions to ECR using OIDC |
| [Static Website](/modules/static-website) | CDN-fronted static hosting with GitHub Actions deployment |

## Getting Started

1. **Clone the repository**
   ```bash
   git clone https://github.com/your-repo/aws-terraform-modules.git
   cd aws-terraform-modules
   ```

2. **Initialize Terraform**
   ```bash
   terraform init
   ```

3. **Use modules**
   ```hcl
   module "example" {
     source = "./modules/eks-cluster"
     # Required variables...
   }
   ```

## Requirements

- Terraform >= 1.12.1
- AWS Provider >= 5.0
- AWS account with appropriate permissions

## Structure

```
aws-terraform-modules/
├── modules/
│   ├── eks-cluster/          # EKS cluster components
│   ├── rds-postgresql/       # PostgreSQL database
│   ├── route-tables/         # Network routing
│   ├── subnets/              # Subnet configuration
│   ├── client-vpn/           # VPN infrastructure
│   ├── github-ecr/           # CI/CD integration
│   └── static-website/       # Static hosting
└── README.md                 # This file
```

## Contributing

1. Fork the repository
2. Create a feature branch
3. Submit a pull request
