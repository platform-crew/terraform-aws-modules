variable "environment" {
  description = "Deployment environment (e.g., dev, staging, prod)"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID to deploy RDS in"
  type        = string
}

variable "rds_subnet_ids" {
  description = "Subnet IDs for RDS subnet group"
  type        = list(string)
}

variable "rds_requester_sg_id" {
  description = "Security group ID allowed to connect to RDS (e.g., from EKS)"
  type        = string
}

variable "rds_db_name" {
  description = "Database name"
  type        = string
}

variable "rds_db_username" {
  description = "Master DB username"
  type        = string
}

variable "rds_db_password" {
  description = "Master DB password"
  type        = string
  sensitive   = true
}

variable "rds_engine_version" {
  description = "PostgreSQL engine version"
  type        = string
  default     = "17.5"
}

variable "rds_instance_class" {
  description = "Instance type for RDS"
  type        = string
  default     = "db.t3.micro"
}

variable "rds_allocated_storage" {
  description = "Initial storage allocation (in GB)"
  type        = number
  default     = 20
}

variable "rds_max_allocated_storage" {
  description = "Maximum storage allocation (in GB)"
  type        = number
  default     = 100
}

variable "rds_backup_retention_period" {
  description = "Number of days to retain backups"
  type        = number
  default     = 7
}

variable "rds_backup_window" {
  description = "Daily backup window (UTC time)"
  type        = string
  default     = "01:00-02:00"
}

variable "rds_auto_minor_version_upgrade" {
  description = "Allow automatic minor version upgrades"
  type        = bool
  default     = true
}

variable "iam_database_authentication_enabled" {
  description = "Enable IAM authentication for the RDS instance"
  type        = bool
  default     = true
}

variable "rds_maintenance_window" {
  description = "The weekly time range (UTC) during which system maintenance can occur, in the format 'ddd:hh24:mi-ddd:hh24:mi'"
  type        = string
  default     = "Mon:04:00-Mon:05:00"
}

variable "rds_enable_delete_protection" {
  description = "Protection again deletion"
  type        = bool
  default     = true
}

variable "rds_kms_key_deletion_window_in_days" {
  description = "KMS key for RDS Performance Insights"
  type        = number
  default     = 7
}

variable "rds_performance_insights_retention_period" {
  description = "RDS Performance insights retention period"
  type        = number
  default     = 7
}
