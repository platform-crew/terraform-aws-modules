# ======================
# NETWORK CONFIGURATION
# ======================

variable "environment" {
  description = "Environment"
  type        = string
}

variable "vpc_id" {
  type        = string
  description = "The ID of the VPC where the Client VPN will be deployed"
}

variable "vpc_cidr_block" {
  type        = string
  description = "VPC CIDR block"
}

variable "private_subnet_ids" {
  type        = list(string)
  default     = []
  description = "List of private subnet IDs across multiple AZs for VPN high availability"
}

variable "client_cidr_block" {
  type        = string
  description = "The IPv4 CIDR range to assign VPN client addresses (e.g., '10.2.0.0/16')"
}

# ======================
# SECURITY CONFIGURATION
# ======================

variable "sso_group_access_rules" {
  type = list(object({
    group_id    = string
    target_cidr = string
    description = optional(string, "")
  }))
  default     = []
  description = <<-EOT
  List of SSO group access rules defining authorized network ranges. Each rule should contain:
  - group_id: The AWS SSO group identifier
  - target_cidr: The destination network range in CIDR notation
  - description: Optional rule description
  EOT
}

variable "server_certificate_arn" {
  type        = string
  description = "ACM certificate ARN for VPN client"
}

# ======================
# LOGGING & MONITORING
# ======================

variable "log_retention_days" {
  type        = number
  default     = 30
  description = "Number of days to retain VPN connection logs in CloudWatch"
}

variable "sso_metadata" {
  type        = string
  description = "SSO Metadata xml content"
  sensitive   = true
}

variable "dns_servers" {
  type        = list(string)
  description = "DNS servers list"
}
