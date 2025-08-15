# AWS Route Table Terraform Module

## Overview
This Terraform module creates and manages AWS Route Tables with dynamic routing configuration for both public and private subnets.

## Features
- **Flexible Routing**: Creates either public or private route tables based on configuration
- **Automatic Association**: Associates route tables with specified subnets
- **Tagging**: Automatic environment and tier tagging
- **Dynamic Gateway Selection**: Automatically uses correct gateway type (IGW for public, NAT GW for private)

## Requirements
- Terraform >= 1.12.1
- AWS Provider >= 5.0

## Usage
```hcl
module "public_route_table" {
  source = "./path/to/module"

  environment    = "production"
  vpc_id        = "vpc-12345678"
  subnet_ids    = ["subnet-123456", "subnet-234567"]
  is_public_route = true
  gateway_id    = "igw-12345678" # Internet Gateway ID
}

module "private_route_table" {
  source = "./path/to/module"

  environment    = "production"
  vpc_id        = "vpc-12345678"
  subnet_ids    = ["subnet-345678", "subnet-456789"]
  is_public_route = false
  gateway_id    = "nat-12345678" # NAT Gateway ID
}
```

## Input Variables

### Required Variables
| Name | Description | Type |
|------|-------------|------|
| environment | Deployment environment | string |
| vpc_id | VPC ID for route table | string |
| is_public_route | Whether to create public route table | bool |
| gateway_id | IGW ID for public or NAT GW ID for private | string |

### Optional Variables
| Name | Description | Type | Default |
|------|-------------|------|---------|
| subnet_ids | Subnet IDs to associate | list(string) | [] |

## Module Components

### 1. Route Table
- Creates either public or private route table based on `is_public_route`
- Automatically configures default route (0.0.0.0/0)
  - Public: Routes to Internet Gateway
  - Private: Routes to NAT Gateway
- Automatic tagging with environment and tier

### 2. Route Table Associations
- Automatically associates route table with all specified subnets
- Handles multiple subnet associations through count

## Best Practices
1. Always separate public and private route tables
2. Use consistent tagging for better resource management
3. Keep public and private subnets in separate modules
4. Review route table associations after creation

## Maintenance
To modify route table configuration:
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
To destroy the route table and associations:
```bash
terraform destroy
```
