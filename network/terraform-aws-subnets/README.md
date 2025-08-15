# AWS Subnets Terraform Module

## Overview
This Terraform module creates multiple AWS subnets across specified availability zones with configurable public/private settings.

## Features
- **Multi-AZ Deployment**: Creates subnets in all specified availability zones
- **Public/Private Configuration**: Single parameter controls public IP assignment
- **Flexible CIDR Allocation**: Assigns CIDRs from provided list to each AZ
- **Custom Tagging**: Supports both default and custom tags
- **Output Integration**: Provides subnet IDs for easy integration with other resources

## Requirements
- Terraform >= 1.12.1
- AWS Provider >= 5.0
- Existing VPC

## Usage
```hcl
module "public_subnets" {
  source = "./path/to/module"

  environment       = "production"
  vpc_id           = "vpc-12345678"
  availability_zones = ["us-east-1a", "us-east-1b", "us-east-1c"]
  subnet_cidrs      = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  is_subnets_public = true

  tags = {
    Project     = "my-app"
    ManagedBy   = "terraform"
  }
}

module "private_subnets" {
  source = "./path/to/module"

  environment       = "production"
  vpc_id           = "vpc-12345678"
  availability_zones = ["us-east-1a", "us-east-1b"]
  subnet_cidrs      = ["10.0.4.0/24", "10.0.5.0/24"]
  is_subnets_public = false
}
```

## Input Variables

### Required Variables
| Name | Description | Type |
|------|-------------|------|
| environment | Deployment environment | string |
| vpc_id | VPC ID for subnet creation | string |
| availability_zones | List of AZs for subnet placement | list(string) |
| subnet_cidrs | List of CIDR blocks for subnets | list(string) |
| is_subnets_public | Whether subnets should be public | bool |

### Optional Variables
| Name | Description | Type | Default |
|------|-------------|------|---------|
| tags | Additional tags for subnets | map(string) | {} |

## Outputs
| Name | Description |
|------|-------------|
| subnet_ids | List of created subnet IDs |

## Module Components

### 1. Local Transformations
- Creates AZ to CIDR mapping using `for` expression
- Ensures clean association between AZs and CIDR blocks

### 2. Subnet Creation
- Creates one subnet per availability zone
- Automatically assigns correct CIDR block to each AZ
- Configures public IP assignment based on `is_subnets_public`
- Applies consistent tagging with environment and tier information

### 3. Tagging Strategy
- Default tags include:
  - Environment
  - Name (public-subnet/private-subnet)
  - Tier (public/private)
- Merges with custom tags from `var.tags`

## Best Practices
1. Maintain equal length for `availability_zones` and `subnet_cidrs`
2. Use consistent naming conventions for public/private subnets
3. Reserve sufficient IP space in CIDR blocks for future growth
4. Document subnet purposes in tags
5. Separate public and private subnets into different module instances

## Maintenance
To modify subnet configuration:
1. Update the Terraform configuration
2. Review changes:
   ```bash
   terraform plan
   ```
3. Apply changes:
   ```bash
   terraform apply
   ```

## Cleanup
To destroy all created subnets:
```bash
terraform destroy
```
