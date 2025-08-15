# AWS RDS PostgreSQL Terraform Module

## Overview
This Terraform module provisions a production-ready AWS RDS PostgreSQL instance with security best practices and configurable parameters.

## Features
- **PostgreSQL Database**: Fully managed RDS instance
- **High Availability**: Multi-AZ deployment
- **Security**: VPC isolation, encrypted storage, configurable access
- **Scalability**: Configurable storage with auto-scaling
- **Maintenance**: Configurable backup and maintenance windows
- **Monitoring**: Enhanced monitoring (optional)

## Requirements
- Terraform >= 1.12.1
- AWS Provider >= 5.0
- AWS account with proper permissions

## Usage
```hcl
module "postgres_db" {
  source = "./path/to/module"

  environment        = "production"
  vpc_id            = "vpc-12345678"
  rds_subnet_ids    = ["subnet-123456", "subnet-234567"]
  rds_requester_sg_id = "sg-12345678"

  rds_db_name       = "appdb"
  rds_db_username   = "admin"
  rds_db_password   = "securepassword123"

  rds_instance_class = "db.t3.medium"
  rds_allocated_storage = 50
}
```

## Input Variables

### Required Variables
| Name | Description | Type |
|------|-------------|------|
| environment | Deployment environment (dev/staging/prod) | string |
| vpc_id | VPC ID for RDS deployment | string |
| rds_subnet_ids | Subnet IDs for RDS subnet group | list(string) |
| rds_requester_sg_id | Security group ID allowed to connect to RDS | string |
| rds_db_name | Database name | string |
| rds_db_username | Master username | string |
| rds_db_password | Master password | string |

### Optional Variables
| Name | Description | Type | Default |
|------|-------------|------|---------|
| rds_engine_version | PostgreSQL version | string | "17.5" |
| rds_instance_class | DB instance type | string | "db.t3.micro" |
| rds_allocated_storage | Initial storage (GB) | number | 20 |
| rds_max_allocated_storage | Max storage (GB) | number | 100 |
| rds_backup_retention_period | Backup retention days | number | 7 |
| rds_backup_window | Backup time window (UTC) | string | "01:00-02:00" |
| rds_auto_minor_version_upgrade | Auto minor version upgrades | bool | true |
| iam_database_authentication_enabled | IAM DB auth | bool | false |
| rds_maintenance_window | Maintenance window (UTC) | string | "Mon:04:00-Mon:05:00" |
| rds_enable_delete_protection | Deletion protection | bool | false |

## Outputs
| Name | Description |
|------|-------------|
| rds_endpoint | RDS connection endpoint |
| rds_resource_id | RDS resource identifier |

## Module Components

### 1. Networking
- **DB Subnet Group**: Spread across multiple AZs
- **Security Group**: Restricted access to specified security group only

### 2. Database Configuration
- PostgreSQL engine with configurable version
- Configurable instance class and storage
- Multi-AZ deployment for high availability
- Storage encryption enabled by default

### 3. Maintenance & Backup
- Configurable backup retention period
- Customizable backup window
- Maintenance window configuration
- Automatic minor version upgrades

### 4. Security
- VPC isolation
- Storage encryption
- IAM database authentication (optional)
- Deletion protection (optional)

## Security Best Practices
1. Always enable `deletion_protection` in production
2. Use IAM database authentication where possible
3. Keep `auto_minor_version_upgrade` enabled for security patches
4. Store database credentials in AWS Secrets Manager
5. Restrict access using security groups

## Maintenance
To modify database parameters:
1. Update the Terraform configuration
2. Review changes:
   ```bash
   terraform plan
   ```
3. Apply changes:
   ```bash
   terraform apply
   ```

Note: Some changes may require downtime.

## Cleanup
To destroy the database (ensure you have backups):
```bash
terraform destroy
```
