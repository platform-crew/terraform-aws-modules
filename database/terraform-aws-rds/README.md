# Terraform AWS RDS Module

This Terraform module provisions an **Amazon RDS (PostgreSQL)** instance inside a private subnet with secure access from an application (e.g., EKS) via security group. It supports features like:

- Multi-AZ high availability
- Automatic backups
- IAM database authentication
- Controlled minor version upgrades
- Security group whitelisting

---

## 📦 Resources Created

- `aws_db_instance` — RDS instance (PostgreSQL)
- `aws_db_subnet_group` — Subnet group for RDS
- `aws_security_group` — Access control for RDS
- Terraform outputs:
  - `rds_endpoint`
  - `rds_resource_id`

---

## 🚀 Usage

```hcl
module "rds" {
  source = "./modules/rds"

  environment                     = "prod"
  vpc_id                          = "vpc-abc123"
  rds_subnet_ids                  = ["subnet-1", "subnet-2"]
  rds_requester_sg_id            = "sg-12345678"
  rds_db_name                     = "myapp"
  rds_db_username                 = "admin"
  rds_db_password                 = var.db_password
  iam_database_authentication_enabled = true
}
