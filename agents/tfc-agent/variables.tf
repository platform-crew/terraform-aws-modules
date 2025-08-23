# --------------------
# General / Environment
# --------------------
variable "environment" {
  description = "Environment name (e.g., dev, staging, prod)"
  type        = string
}

variable "region" {
  description = "AWS region for the resources"
  type        = string
}

# --------------------
# Networking
# --------------------
variable "vpc_id" {
  description = "AWS VPC ID where Fargate tasks will run"
  type        = string
}

variable "private_subnets" {
  description = "List of private subnet IDs where Fargate tasks will run"
  type        = list(string)
}

# --------------------
# ECS / Fargate Task
# --------------------
variable "task_cpu" {
  description = "CPU units for Fargate task"
  type        = string
  default     = "512"
}

variable "task_memory" {
  description = "Memory for Fargate task (MiB)"
  type        = string
  default     = "1024"
}

variable "container_image" {
  description = "Container image for the Terraform agent"
  type        = string
  default     = "hashicorp/tfc-agent:latest"
}

variable "container_name" {
  description = "Name of the container in the ECS task"
  type        = string
  default     = "terraform"
}

# --------------------
# Security Group
# --------------------

variable "egress_cidr_blocks" {
  description = "List of CIDR blocks allowed for egress"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

# --------------------
# ECS Service
# --------------------
variable "desired_count" {
  description = "Number of Fargate tasks to run"
  type        = number
  default     = 1
}

variable "launch_type" {
  description = "Launch type for ECS service"
  type        = string
  default     = "FARGATE"
}

variable "min_task_count" {
  description = "Minimum number of tasks to run"
  type        = number
  default     = 1
}

variable "max_task_count" {
  description = "Maximum number of tasks to run"
  type        = number
  default     = 3
}

variable "cpu_target_value" {
  description = "Target CPU utilization percentage for scaling"
  type        = number
  default     = 70
}

variable "memory_target_value" {
  description = "Target Memory utilization percentage for scaling"
  type        = number
  default     = 70
}

# --------------------
# Terraform Cloud Agent
# --------------------

variable "tfc_agent_token" {
  description = "Terraform Cloud agent token for authenticating the remote agent"
  type        = string
  sensitive   = true
}
